-- ============================================
-- 医院信息管理系统 - 存储过程脚本
-- 作者: 袁子轩 (yuanzixuan)
-- 学号: 3123004721
-- 创建日期: 2025年12月
-- ============================================

USE hospital_3123004721_yuanzixuan;
GO

-- ============================================
-- 1. 存储过程: 统计指定日期范围内各科室问诊人数
-- 功能: 分组查询 + 日期范围过滤
-- ============================================
IF OBJECT_ID('sp_count_visits_by_dept_3123004721', 'P') IS NOT NULL
    DROP PROCEDURE sp_count_visits_by_dept_3123004721;
GO

CREATE PROCEDURE sp_count_visits_by_dept_3123004721
    @begin_date DATETIME,
    @end_date DATETIME
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        r_dept AS N'科室',
        COUNT(*) AS N'问诊人数',
        COUNT(DISTINCT r_patient_id) AS N'独立病人数'
    FROM register_3123004721_yuanzixuan
    WHERE create_time BETWEEN @begin_date AND @end_date
      AND is_delete = 0
    GROUP BY r_dept
    ORDER BY COUNT(*) DESC;
END;
GO

-- ============================================
-- 2. 存储过程: 完成处方结算（扣减库存+生成收费记录）
-- 功能: 事务处理 + 数据完整性保证
-- ============================================
IF OBJECT_ID('sp_settle_prescription_3123004721', 'P') IS NOT NULL
    DROP PROCEDURE sp_settle_prescription_3123004721;
GO

CREATE PROCEDURE sp_settle_prescription_3123004721
    @prescription_id INT,
    @toll_id VARCHAR(10),
    @toll_name NVARCHAR(10),
    @patient_id VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    
    BEGIN TRY
        DECLARE @drug_id VARCHAR(10), @quantity INT, @price DECIMAL(10,2), @current_stock BIGINT;
        DECLARE @total_amount DECIMAL(10,2) = 0;
        
        -- 游标遍历处方中的所有药品
        DECLARE drug_cursor CURSOR FOR
            SELECT pd.drug_id, pd.quantity, d.drug_price, d.drug_quantity
            FROM prescription_drug_3123004721_yuanzixuan pd
            JOIN drugs_3123004721_yuanzixuan d ON pd.drug_id = d.drug_id AND d.is_delete = 0
            WHERE pd.prescription_id = @prescription_id AND pd.is_delete = 0;
        
        OPEN drug_cursor;
        FETCH NEXT FROM drug_cursor INTO @drug_id, @quantity, @price, @current_stock;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- 检查库存是否充足
            IF @current_stock < @quantity
            BEGIN
                RAISERROR(N'药品库存不足，无法完成结算', 16, 1);
                ROLLBACK TRANSACTION;
                RETURN;
            END
            
            -- 扣减库存
            UPDATE drugs_3123004721_yuanzixuan
            SET drug_quantity = drug_quantity - @quantity,
                update_time = GETDATE()
            WHERE drug_id = @drug_id AND is_delete = 0;
            
            -- 计算金额
            DECLARE @item_amount DECIMAL(10,2) = @quantity * @price;
            SET @total_amount = @total_amount + @item_amount;
            
            -- 插入收费记录
            IF NOT EXISTS (SELECT 1 FROM charge_3123004721_yuanzixuan 
                           WHERE toll_id = @toll_id AND patient_id = @patient_id AND drug_id = @drug_id)
            BEGIN
                INSERT INTO charge_3123004721_yuanzixuan (toll_id, t_name, patient_id, drug_id, drug_quantity, amount)
                VALUES (@toll_id, @toll_name, @patient_id, @drug_id, @quantity, @item_amount);
            END
            
            FETCH NEXT FROM drug_cursor INTO @drug_id, @quantity, @price, @current_stock;
        END
        
        CLOSE drug_cursor;
        DEALLOCATE drug_cursor;
        
        COMMIT TRANSACTION;
        
        -- 返回结算结果
        SELECT N'结算成功' AS '状态', @total_amount AS '总金额';
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

-- ============================================
-- 3. 存储过程: 药品入库
-- 功能: 增加库存或新增药品
-- ============================================
IF OBJECT_ID('sp_drug_stock_in_3123004721', 'P') IS NOT NULL
    DROP PROCEDURE sp_drug_stock_in_3123004721;
GO

CREATE PROCEDURE sp_drug_stock_in_3123004721
    @drug_id VARCHAR(10),
    @drug_name NVARCHAR(50),
    @drug_price DECIMAL(10,2),
    @quantity BIGINT,
    @storage NVARCHAR(50),
    @produce_date DATETIME,
    @expire_date DATETIME
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (SELECT 1 FROM drugs_3123004721_yuanzixuan WHERE drug_id = @drug_id AND is_delete = 0)
    BEGIN
        -- 已存在，增加库存
        UPDATE drugs_3123004721_yuanzixuan
        SET drug_quantity = drug_quantity + @quantity,
            update_time = GETDATE()
        WHERE drug_id = @drug_id AND is_delete = 0;
        
        SELECT N'库存增加成功' AS '状态', @quantity AS '入库数量';
    END
    ELSE
    BEGIN
        -- 不存在，新增药品
        INSERT INTO drugs_3123004721_yuanzixuan 
            (drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life)
        VALUES 
            (@drug_id, @drug_name, @drug_price, @quantity, @storage, @produce_date, @expire_date);
        
        SELECT N'新药品入库成功' AS '状态', @quantity AS '入库数量';
    END
END;
GO

-- ============================================
-- 4. 存储过程: 生成病人账单汇总
-- 功能: 嵌套查询 + 聚合统计
-- ============================================
IF OBJECT_ID('sp_generate_patient_bill_3123004721', 'P') IS NOT NULL
    DROP PROCEDURE sp_generate_patient_bill_3123004721;
GO

CREATE PROCEDURE sp_generate_patient_bill_3123004721
    @patient_id VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- 输出病人基本信息
    SELECT 
        p_atient_id AS '身份证号',
        p_name AS '姓名',
        p_sex AS '性别',
        p_age AS '年龄',
        p_tel AS '联系电话'
    FROM patient_3123004721_yuanzixuan
    WHERE p_atient_id = @patient_id AND is_delete = 0;
    
    -- 输出消费明细
    SELECT 
        c.toll_id AS '收费单号',
        d.drug_name AS '药品名称',
        c.drug_quantity AS '数量',
        d.drug_price AS '单价',
        c.amount AS '金额',
        c.create_time AS '收费时间'
    FROM charge_3123004721_yuanzixuan c
    JOIN drugs_3123004721_yuanzixuan d ON c.drug_id = d.drug_id
    WHERE c.patient_id = @patient_id AND c.is_delete = 0
    ORDER BY c.create_time;
    
    -- 输出汇总信息
    SELECT 
        COUNT(*) AS '消费笔数',
        SUM(amount) AS '消费总额',
        (SELECT SUM(price) FROM pay_3123004721_yuanzixuan 
         WHERE patient_id = @patient_id AND is_delete = 0) AS '已支付金额'
    FROM charge_3123004721_yuanzixuan
    WHERE patient_id = @patient_id AND is_delete = 0;
END;
GO

PRINT N'存储过程创建完成！共创建4个存储过程。';
GO

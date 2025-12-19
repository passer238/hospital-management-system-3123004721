-- ============================================
-- 医院信息管理系统 - 存储过程
-- 作者: 袁子轩
-- 学号: 3123004721
-- 更新日期: 2025年12月
-- ============================================

USE hospital3123004721;
GO

-- ================ 1. 挂号管理 ================

-- 1.1 添加挂号
CREATE OR ALTER PROCEDURE sp_AddRegistration
    @patient_id VARCHAR(20),
    @patient_name NVARCHAR(20),
    @sex NVARCHAR(2),
    @dept NVARCHAR(20),
    @doctor_id INT,
    @doctor_name NVARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @next_id INT;
    
    -- 查找最小可用编号
    SELECT @next_id = MIN(t1.r_num + 1)
    FROM register t1
    LEFT JOIN register t2 ON t1.r_num + 1 = t2.r_num
    WHERE t2.r_num IS NULL;
    
    IF @next_id IS NULL SET @next_id = 1;
    
    -- 使用IDENTITY_INSERT插入
    SET IDENTITY_INSERT register ON;
    INSERT INTO register (r_num, r_patient_id, r_P_name, r_sex, r_dept, r_doctor_id, r_name)
    VALUES (@next_id, @patient_id, @patient_name, @sex, @dept, @doctor_id, @doctor_name);
    SET IDENTITY_INSERT register OFF;
    
    SELECT @next_id AS NewRegistrationId;
    PRINT '挂号成功，编号: ' + CAST(@next_id AS VARCHAR);
END
GO

-- 1.2 删除挂号（级联删除并恢复库存）
CREATE OR ALTER PROCEDURE sp_DeleteRegistration
    @r_num INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @patient_id VARCHAR(20);
    DECLARE @PrescriptionIds TABLE (id INT);
    
    -- 获取病人ID（用于后续可能的清理，但主要级联基于处方ID）
    SELECT @patient_id = r_patient_id FROM register WHERE r_num = @r_num;
    
    IF @patient_id IS NOT NULL
    BEGIN
        -- 1. 找到该挂号关联的所有处方ID
        INSERT INTO @PrescriptionIds (id)
        SELECT id FROM recipel WHERE registration_id = @r_num;
        
        -- 2. 恢复药品库存 (针对这些处方)
        UPDATE d
        SET d.drug_quantity = d.drug_quantity + pd.quantity
        FROM drugs d
        INNER JOIN prescription_drug pd ON d.drug_id = pd.drug_id
        WHERE pd.prescription_id IN (SELECT id FROM @PrescriptionIds);
        
        -- 3. 级联删除取药票单 (PGM.t_id = Charge.toll_id = Prescription.id)
        DELETE FROM PGM 
        WHERE t_id IN (SELECT CAST(id AS VARCHAR) FROM @PrescriptionIds);
        
        -- 4. 级联删除支付记录
        DELETE FROM pay 
        WHERE t_id IN (SELECT CAST(id AS VARCHAR) FROM @PrescriptionIds);
        
        -- 5. 级联删除收费记录
        DELETE FROM charge 
        WHERE toll_id IN (SELECT CAST(id AS VARCHAR) FROM @PrescriptionIds);
        
        -- 6. 级联删除处方药品详情
        DELETE FROM prescription_drug 
        WHERE prescription_id IN (SELECT id FROM @PrescriptionIds);
        
        -- 7. 删除处方
        DELETE FROM recipel 
        WHERE id IN (SELECT id FROM @PrescriptionIds);
        
        -- 8. 删除挂号
        DELETE FROM register WHERE r_num = @r_num;
        
        PRINT '挂号及其关联的处方、收费、支付、取药记录删除成功，库存已恢复。';
    END
END
GO


-- ================ 2. 医生管理 ================

-- 2.1 添加医生
CREATE OR ALTER PROCEDURE sp_AddDoctor
    @doctor_id INT,
    @name NVARCHAR(20),
    @sex NVARCHAR(2),
    @age TINYINT,
    @dept NVARCHAR(50),
    @tel VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO doctor (d_octor_id, d_name, d_sex, d_age, d_dept, d_tel)
    VALUES (@doctor_id, @name, @sex, @age, @dept, @tel);
    PRINT '医生添加成功';
END
GO

-- 2.2 编辑医生
CREATE OR ALTER PROCEDURE sp_EditDoctor
    @doctor_id INT,
    @name NVARCHAR(20),
    @sex NVARCHAR(2),
    @age TINYINT,
    @dept NVARCHAR(50),
    @tel VARCHAR(20)
AS
BEGIN
    UPDATE doctor SET 
        d_name = @name, d_sex = @sex, d_age = @age, 
        d_dept = @dept, d_tel = @tel, update_time = GETDATE()
    WHERE d_octor_id = @doctor_id;
    PRINT '医生信息更新成功';
END
GO

-- 2.3 删除医生
CREATE OR ALTER PROCEDURE sp_DeleteDoctor
    @doctor_id INT
AS
BEGIN
    DELETE FROM doctor WHERE d_octor_id = @doctor_id;
    PRINT '医生删除成功';
END
GO

-- ================ 3. 病人管理 ================

-- 3.1 添加病人
CREATE OR ALTER PROCEDURE sp_AddPatient
    @patient_id VARCHAR(20),
    @name NVARCHAR(20),
    @age TINYINT,
    @sex NVARCHAR(2),
    @tel VARCHAR(20),
    @info NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO patient (p_atient_id, p_name, p_age, p_sex, p_tel, p_inf)
    VALUES (@patient_id, @name, @age, @sex, @tel, @info);
    PRINT '病人添加成功';
END
GO

-- 3.2 编辑病人
CREATE OR ALTER PROCEDURE sp_EditPatient
    @patient_id VARCHAR(20),
    @name NVARCHAR(20),
    @age TINYINT,
    @sex NVARCHAR(2),
    @tel VARCHAR(20),
    @info NVARCHAR(200) = NULL
AS
BEGIN
    UPDATE patient SET 
        p_name = @name, p_age = @age, p_sex = @sex, 
        p_tel = @tel, p_inf = @info, update_time = GETDATE()
    WHERE p_atient_id = @patient_id;
    PRINT '病人信息更新成功';
END
GO

-- 3.3 删除病人
CREATE OR ALTER PROCEDURE sp_DeletePatient
    @patient_id VARCHAR(20)
AS
BEGIN
    DELETE FROM patient WHERE p_atient_id = @patient_id;
    PRINT '病人删除成功';
END
GO

-- ================ 4. 药品管理 ================

-- 4.1 添加药品
CREATE OR ALTER PROCEDURE sp_AddDrug
    @drug_id VARCHAR(10),
    @name NVARCHAR(100),
    @price DECIMAL(10,2),
    @quantity INT,
    @storage NVARCHAR(50),
    @drug_date DATE = NULL,
    @useful_life DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO drugs (drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life)
    VALUES (@drug_id, @name, @price, @quantity, @storage, @drug_date, @useful_life);
    PRINT '药品添加成功';
END
GO

-- 4.2 编辑药品
CREATE OR ALTER PROCEDURE sp_EditDrug
    @drug_id VARCHAR(10),
    @name NVARCHAR(100),
    @price DECIMAL(10,2),
    @quantity INT,
    @storage NVARCHAR(50)
AS
BEGIN
    UPDATE drugs SET 
        drug_name = @name, drug_price = @price, 
        drug_quantity = @quantity, drug_storage = @storage, update_time = GETDATE()
    WHERE drug_id = @drug_id;
    PRINT '药品信息更新成功';
END
GO

-- 4.3 删除药品
CREATE OR ALTER PROCEDURE sp_DeleteDrug
    @drug_id VARCHAR(10)
AS
BEGIN
    DELETE FROM drugs WHERE drug_id = @drug_id;
    PRINT '药品删除成功';
END
GO

-- ================ 5. 处方管理 ================

-- 5.1 开具处方
CREATE OR ALTER PROCEDURE sp_CreatePrescription
    @registration_id INT,
    @patient_name NVARCHAR(20),
    @prescription_id INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @next_id INT;
    DECLARE @doctor_id INT;
    
    -- 检查是否已有处方
    IF EXISTS (SELECT 1 FROM recipel WHERE registration_id = @registration_id)
    BEGIN
        RAISERROR('该挂号已有处方', 16, 1);
        RETURN;
    END
    
    -- 获取医生ID（从挂号记录）
    SELECT @doctor_id = r_doctor_id FROM register WHERE r_num = @registration_id;
    
    IF @doctor_id IS NULL
    BEGIN
        RAISERROR('找不到挂号记录', 16, 1);
        RETURN;
    END

    -- 查找最小可用编号
    SELECT @next_id = MIN(t1.id + 1)
    FROM recipel t1
    LEFT JOIN recipel t2 ON t1.id + 1 = t2.id
    WHERE t2.id IS NULL;
    
    IF @next_id IS NULL SET @next_id = 1;
    
    -- 使用IDENTITY_INSERT插入
    SET IDENTITY_INSERT recipel ON;
    INSERT INTO recipel (id, doctor_id, patient_name, registration_id)
    VALUES (@next_id, @doctor_id, @patient_name, @registration_id);
    SET IDENTITY_INSERT recipel OFF;
    
    SET @prescription_id = @next_id;
    PRINT '处方创建成功，编号: ' + CAST(@next_id AS VARCHAR);
END
GO

-- 5.2 添加处方药品
CREATE OR ALTER PROCEDURE sp_AddPrescriptionDrug
    @prescription_id INT,
    @drug_id VARCHAR(10),
    @quantity INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @stock INT, @drug_name NVARCHAR(100), @price DECIMAL(10,2);
    DECLARE @patient_name NVARCHAR(20), @patient_id VARCHAR(20), @toll_id VARCHAR(10);
    
    -- 检查库存
    SELECT @stock = drug_quantity, @drug_name = drug_name, @price = drug_price
    FROM drugs WHERE drug_id = @drug_id AND is_delete = 0;
    
    IF @stock IS NULL OR @stock < @quantity
    BEGIN
        RAISERROR('库存不足', 16, 1);
        RETURN;
    END
    
    -- 添加处方药品
    INSERT INTO prescription_drug (prescription_id, drug_id, quantity)
    VALUES (@prescription_id, @drug_id, @quantity);
    
    -- 扣减库存
    UPDATE drugs SET drug_quantity = drug_quantity - @quantity WHERE drug_id = @drug_id;
    
    -- 获取病人信息
    SELECT @patient_name = patient_name FROM recipel WHERE id = @prescription_id;
    SELECT @patient_id = r_patient_id FROM register WHERE r_P_name = @patient_name;
    
    --生成收费编号 (使用处方ID作为收费编号，以支持级联删除)
    SET @toll_id = CAST(@prescription_id AS VARCHAR(10));
    
    -- 生成收费记录
    INSERT INTO charge (toll_id, t_name, patient_id, drug_id, drug_quantity, amount)
    VALUES (@toll_id, N'系统', @patient_id, @drug_id, @quantity, @price * @quantity);
    
    PRINT '药品添加成功，已扣减库存并生成收费记录';
END
GO

-- 5.3 删除处方
CREATE OR ALTER PROCEDURE sp_DeletePrescription
    @prescription_id INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @patient_name NVARCHAR(20), @patient_id VARCHAR(20);
    
    SELECT @patient_name = patient_name FROM recipel WHERE id = @prescription_id;
    SELECT @patient_id = r_patient_id FROM register WHERE r_P_name = @patient_name;
    
    -- 1. 恢复库存
    UPDATE d
    SET d.drug_quantity = d.drug_quantity + pd.quantity
    FROM drugs d
    INNER JOIN prescription_drug pd ON d.drug_id = pd.drug_id
    WHERE pd.prescription_id = @prescription_id;
    
    -- 2. 删除取药票单
    DELETE FROM PGM WHERE t_id = CAST(@prescription_id AS VARCHAR);
    
    -- 3. 删除支付记录
    DELETE FROM pay WHERE t_id = CAST(@prescription_id AS VARCHAR);
    
    -- 4. 删除相关收费
    DELETE FROM charge WHERE toll_id = CAST(@prescription_id AS VARCHAR);
    
    -- 5. 删除处方药品
    DELETE FROM prescription_drug WHERE prescription_id = @prescription_id;
    
    -- 6. 删除处方
    DELETE FROM recipel WHERE id = @prescription_id;
    
    PRINT '处方删除成功，库存已恢复';
END
GO

-- ================ 6. 支付管理 ================

-- 6.1 支付
CREATE OR ALTER PROCEDURE sp_MakePayment
    @patient_id VARCHAR(20),
    @toll_id VARCHAR(10),
    @amount DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    -- 添加支付记录
    INSERT INTO pay (patient_id, t_id, price)
    VALUES (@patient_id, @toll_id, @amount);
    
    -- 生成取药票单
    INSERT INTO PGM (t_id, drug_id, quantity, price)
    SELECT @toll_id, drug_id, drug_quantity, amount
    FROM charge
    WHERE patient_id = @patient_id AND toll_id = @toll_id AND is_delete = 0;
    
    PRINT '支付成功，取药票单已生成';
END
GO

-- 6.2 删除支付
CREATE OR ALTER PROCEDURE sp_DeletePayment
    @patient_id VARCHAR(20),
    @t_id VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM PGM WHERE t_id = @t_id;
    DELETE FROM pay WHERE patient_id = @patient_id AND t_id = @t_id;
    PRINT '支付记录及取药票单删除成功';
END
GO

-- ================ 7. 取药管理 ================

-- 7.1 标记已取药
CREATE OR ALTER PROCEDURE sp_MarkPickup
    @t_id VARCHAR(10),
    @drug_id VARCHAR(10)
AS
BEGIN
    UPDATE PGM SET is_picked = 1, update_time = GETDATE()
    WHERE t_id = @t_id AND drug_id = @drug_id;
    PRINT '已标记为取药';
END
GO

-- 7.2 标记全部已取药
CREATE OR ALTER PROCEDURE sp_MarkAllPickup
    @t_id VARCHAR(10)
AS
BEGIN
    UPDATE PGM SET is_picked = 1, update_time = GETDATE()
    WHERE t_id = @t_id;
    PRINT '该收费编号下所有药品已标记为取药';
END
GO

PRINT '存储过程创建/更新完成！';
GO

-- ============================================
-- 医院信息管理系统 - 触发器脚本
-- 作者: 袁子轩 (yuanzixuan)
-- 学号: 3123004721
-- 创建日期: 2025年12月
-- ============================================

USE hospital_3123004721_yuanzixuan;
GO

-- ============================================
-- 1. 触发器: 取药时自动扣减库存
-- 功能: 当标记取药票单为已取药时，自动减少药品库存
-- ============================================
IF OBJECT_ID('tr_pickup_reduce_stock_3123004721', 'TR') IS NOT NULL
    DROP TRIGGER tr_pickup_reduce_stock_3123004721;
GO

CREATE TRIGGER tr_pickup_reduce_stock_3123004721
ON PGM_3123004721_yuanzixuan
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- 当is_picked从0变为1时，扣减库存
    IF EXISTS (SELECT 1 FROM inserted i JOIN deleted d 
               ON i.t_id = d.t_id AND i.drug_id = d.drug_id
               WHERE i.is_picked = 1 AND d.is_picked = 0)
    BEGIN
        UPDATE drugs_3123004721_yuanzixuan
        SET drug_quantity = drug_quantity - i.quantity,
            update_time = GETDATE()
        FROM drugs_3123004721_yuanzixuan d
        JOIN inserted i ON d.drug_id = i.drug_id
        JOIN deleted del ON i.t_id = del.t_id AND i.drug_id = del.drug_id
        WHERE i.is_picked = 1 AND del.is_picked = 0 AND d.is_delete = 0;
    END
END;
GO

-- ============================================
-- 2. 触发器: 挂号时检查医生是否在岗
-- 功能: 插入挂号记录前检查医生状态
-- ============================================
IF OBJECT_ID('tr_check_doctor_status_3123004721', 'TR') IS NOT NULL
    DROP TRIGGER tr_check_doctor_status_3123004721;
GO

CREATE TRIGGER tr_check_doctor_status_3123004721
ON register_3123004721_yuanzixuan
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @doctor_id INT, @is_jobing TINYINT;
    
    SELECT @doctor_id = r_doctor_id FROM inserted;
    SELECT @is_jobing = is_jobing FROM doctor_3123004721_yuanzixuan 
           WHERE d_octor_id = @doctor_id AND is_delete = 0;
    
    IF @is_jobing = 0 OR @is_jobing IS NULL
    BEGIN
        RAISERROR(N'该医生当前不在岗，无法挂号！', 16, 1);
        RETURN;
    END
    
    -- 医生在岗，允许插入
    INSERT INTO register_3123004721_yuanzixuan 
        (r_patient_id, r_P_name, r_sex, r_dept, r_doctor_id, r_name, is_delete, create_time, update_time)
    SELECT 
        r_patient_id, r_P_name, r_sex, r_dept, r_doctor_id, r_name, is_delete, 
        ISNULL(create_time, GETDATE()), ISNULL(update_time, GETDATE())
    FROM inserted;
END;
GO

-- ============================================
-- 3. 触发器: 处方药品添加时检查库存
-- 功能: 插入处方药品前检查库存是否充足
-- ============================================
IF OBJECT_ID('tr_check_drug_stock_3123004721', 'TR') IS NOT NULL
    DROP TRIGGER tr_check_drug_stock_3123004721;
GO

CREATE TRIGGER tr_check_drug_stock_3123004721
ON prescription_drug_3123004721_yuanzixuan
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- 检查每个药品的库存
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        JOIN drugs_3123004721_yuanzixuan d ON i.drug_id = d.drug_id AND d.is_delete = 0
        WHERE d.drug_quantity < i.quantity
    )
    BEGIN
        RAISERROR(N'部分药品库存不足，无法开具处方！', 16, 1);
        RETURN;
    END
    
    -- 检查药品是否过期
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        JOIN drugs_3123004721_yuanzixuan d ON i.drug_id = d.drug_id AND d.is_delete = 0
        WHERE d.usefull_life < GETDATE()
    )
    BEGIN
        RAISERROR(N'部分药品已过期，无法开具处方！', 16, 1);
        RETURN;
    END
    
    -- 库存充足且未过期，允许插入
    INSERT INTO prescription_drug_3123004721_yuanzixuan 
        (prescription_id, drug_id, quantity, is_delete, create_time, update_time)
    SELECT 
        prescription_id, drug_id, quantity, ISNULL(is_delete, 0), 
        ISNULL(create_time, GETDATE()), ISNULL(update_time, GETDATE())
    FROM inserted;
END;
GO

-- ============================================
-- 4. 触发器: 更新时间自动维护
-- 功能: 任何表更新时自动更新update_time字段
-- ============================================
IF OBJECT_ID('tr_auto_update_time_patient_3123004721', 'TR') IS NOT NULL
    DROP TRIGGER tr_auto_update_time_patient_3123004721;
GO

CREATE TRIGGER tr_auto_update_time_patient_3123004721
ON patient_3123004721_yuanzixuan
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE patient_3123004721_yuanzixuan
    SET update_time = GETDATE()
    FROM patient_3123004721_yuanzixuan p
    JOIN inserted i ON p.p_atient_id = i.p_atient_id;
END;
GO

PRINT N'触发器创建完成！共创建4个触发器。';
GO

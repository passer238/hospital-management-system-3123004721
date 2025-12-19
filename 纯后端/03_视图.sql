-- ============================================
-- 医院信息管理系统 - 视图
-- 作者: 袁子轩
-- 学号: 3123004721
-- 更新日期: 2025年12月
-- ============================================

USE hospital3123004721;
GO

-- ================ 1. 基础视图 ================

-- 1.1 有效挂号视图
CREATE OR ALTER VIEW v_Registrations AS
SELECT r_num, r_patient_id, r_P_name, r_sex, r_dept, r_name,
       CONVERT(VARCHAR, create_time, 120) as create_time
FROM register WHERE is_delete = 0;
GO

-- 1.2 在岗医生视图
CREATE OR ALTER VIEW v_Doctors AS
SELECT d_octor_id, d_name, d_sex, d_age, d_dept, d_tel, is_jobing
FROM doctor WHERE is_delete = 0;
GO

-- 1.3 有效病人视图
CREATE OR ALTER VIEW v_Patients AS
SELECT p_atient_id, p_name, p_age, p_sex, p_tel, p_inf
FROM patient WHERE is_delete = 0;
GO

-- 1.4 有效药品视图
CREATE OR ALTER VIEW v_Drugs AS
SELECT drug_id, drug_name, drug_price, drug_quantity, drug_storage, 
       CONVERT(VARCHAR, drug_date, 23) as drug_date, 
       CONVERT(VARCHAR, usefull_life, 23) as usefull_life
FROM drugs WHERE is_delete = 0;
GO

-- 1.5 库存预警视图（库存低于10）
CREATE OR ALTER VIEW v_LowStockDrugs AS
SELECT drug_id, drug_name, drug_quantity, drug_storage
FROM drugs 
WHERE is_delete = 0 AND drug_quantity < 10;
GO

-- ================ 2. 业务视图 ================

-- 2.1 处方详情视图
CREATE OR ALTER VIEW v_PrescriptionDetails AS
SELECT 
    r.id AS prescription_id,
    r.patient_name,
    r.registration_id,
    d.d_name AS doctor_name,
    pd.drug_id,
    dr.drug_name,
    pd.quantity,
    dr.drug_price,
    pd.quantity * dr.drug_price AS subtotal,
    CONVERT(VARCHAR, r.create_time, 120) as create_time
FROM recipel r
LEFT JOIN prescription_drug pd ON r.id = pd.prescription_id
LEFT JOIN drugs dr ON pd.drug_id = dr.drug_id
LEFT JOIN doctor d ON r.doctor_id = d.d_octor_id
WHERE r.is_delete = 0;
GO

-- 2.2 未开处方的挂号视图（按挂号编号和病人名字双重过滤）
CREATE OR ALTER VIEW v_UnprescribedRegistrations AS
SELECT r_num, r_patient_id, r_P_name, r_sex, r_dept, r_name
FROM register
WHERE is_delete = 0
AND r_num NOT IN (SELECT registration_id FROM recipel WHERE registration_id IS NOT NULL)
AND r_P_name NOT IN (SELECT patient_name FROM recipel WHERE registration_id IS NULL);
GO

-- 2.3 未支付收费视图
CREATE OR ALTER VIEW v_UnpaidCharges AS
SELECT 
    c.toll_id,
    c.patient_id,
    p.p_name AS patient_name,
    SUM(c.amount) AS total_amount
FROM charge c
LEFT JOIN patient p ON c.patient_id = p.p_atient_id
WHERE c.is_delete = 0
AND NOT EXISTS (SELECT 1 FROM pay WHERE patient_id = c.patient_id AND t_id = c.toll_id AND is_delete = 0)
GROUP BY c.toll_id, c.patient_id, p.p_name;
GO

-- 2.4 取药票单视图
CREATE OR ALTER VIEW v_Pickups AS
SELECT 
    pgm.t_id,
    pgm.drug_id,
    d.drug_name,
    pgm.quantity,
    pgm.price,
    pgm.is_picked,
    CASE WHEN pgm.is_picked = 1 THEN N'已取药' ELSE N'待取药' END AS status,
    CONVERT(VARCHAR, pgm.create_time, 120) as create_time
FROM PGM pgm
LEFT JOIN drugs d ON pgm.drug_id = d.drug_id
WHERE pgm.is_delete = 0;
GO

-- ================ 3. 统计视图 ================

-- 3.1 科室挂号统计视图
CREATE OR ALTER VIEW v_DeptRegistrationStats AS
SELECT 
    r_dept AS department,
    COUNT(*) AS registration_count
FROM register
WHERE is_delete = 0
GROUP BY r_dept;
GO

-- 3.2 医生工作量统计视图
CREATE OR ALTER VIEW v_DoctorWorkloadStats AS
SELECT 
    d.d_name AS doctor_name,
    d.d_dept AS department,
    COUNT(r.id) AS prescription_count
FROM doctor d
LEFT JOIN recipel r ON d.d_octor_id = r.doctor_id AND r.is_delete = 0
WHERE d.is_delete = 0
GROUP BY d.d_octor_id, d.d_name, d.d_dept;
GO

-- 3.3 热门药品统计视图
CREATE OR ALTER VIEW v_PopularDrugs AS
SELECT 
    d.drug_name,
    SUM(pd.quantity) AS total_quantity,
    SUM(pd.quantity * d.drug_price) AS total_amount
FROM prescription_drug pd
LEFT JOIN drugs d ON pd.drug_id = d.drug_id
WHERE pd.is_delete = 0
GROUP BY pd.drug_id, d.drug_name;
GO

-- 3.4 收入统计视图
CREATE OR ALTER VIEW v_RevenueStats AS
SELECT 
    CONVERT(DATE, create_time) AS date,
    SUM(price) AS daily_revenue
FROM pay
WHERE is_delete = 0
GROUP BY CONVERT(DATE, create_time);
GO

-- 3.5 取药完成率统计视图
CREATE OR ALTER VIEW v_PickupStats AS
SELECT 
    (SELECT COUNT(*) FROM PGM WHERE is_delete = 0) AS total_pickups,
    (SELECT COUNT(*) FROM PGM WHERE is_delete = 0 AND is_picked = 1) AS completed_pickups,
    (SELECT COUNT(*) FROM PGM WHERE is_delete = 0 AND (is_picked = 0 OR is_picked IS NULL)) AS pending_pickups;
GO

-- 3.6 待处理事项统计视图
CREATE OR ALTER VIEW v_PendingTasks AS
SELECT
    (SELECT COUNT(*) FROM register WHERE is_delete = 0 
        AND r_num NOT IN (SELECT registration_id FROM recipel WHERE registration_id IS NOT NULL)
        AND r_P_name NOT IN (SELECT patient_name FROM recipel WHERE registration_id IS NULL)
    ) AS pending_prescriptions,
    (SELECT COUNT(DISTINCT toll_id) FROM charge WHERE is_delete = 0
        AND NOT EXISTS (SELECT 1 FROM pay WHERE patient_id = charge.patient_id AND t_id = charge.toll_id AND is_delete = 0)
    ) AS pending_payments,
    (SELECT COUNT(*) FROM PGM WHERE is_delete = 0 AND (is_picked = 0 OR is_picked IS NULL)) AS pending_pickups,
    (SELECT COUNT(*) FROM drugs WHERE is_delete = 0 AND drug_quantity < 10) AS low_stock_count;
GO

PRINT '视图创建/更新完成！';
GO

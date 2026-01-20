-- ============================================
-- 医院信息管理系统 - 视图定义脚本
-- 作者: 袁子轩 (yuanzixuan)
-- 学号: 3123004721
-- 创建日期: 2025年12月
-- ============================================

USE hospital_3123004721_yuanzixuan;
GO

-- ============================================
-- 1. 病人就诊记录综合视图
-- 功能: 多表连接查询，展示病人完整就诊信息
-- ============================================
IF OBJECT_ID('v_patient_records_3123004721', 'V') IS NOT NULL
    DROP VIEW v_patient_records_3123004721;
GO

CREATE VIEW v_patient_records_3123004721 AS
SELECT 
    r.r_num AS '挂号编号',
    r.r_patient_id AS '病人身份证',
    r.r_P_name AS '病人姓名',
    r.r_sex AS '性别',
    r.r_dept AS '就诊科室',
    d.d_name AS '主治医生',
    d.d_tel AS '医生电话',
    p.p_inf AS '病例描述',
    p.p_tel AS '病人电话',
    r.create_time AS '挂号时间'
FROM register_3123004721_yuanzixuan r
LEFT JOIN doctor_3123004721_yuanzixuan d ON r.r_doctor_id = d.d_octor_id AND d.is_delete = 0
LEFT JOIN patient_3123004721_yuanzixuan p ON r.r_patient_id = p.p_atient_id AND p.is_delete = 0
WHERE r.is_delete = 0;
GO

-- ============================================
-- 2. 药品库存预警视图
-- 功能: 显示库存不足或即将过期的药品
-- ============================================
IF OBJECT_ID('v_drug_inventory_warning_3123004721', 'V') IS NOT NULL
    DROP VIEW v_drug_inventory_warning_3123004721;
GO

CREATE VIEW v_drug_inventory_warning_3123004721 AS
SELECT 
    drug_id AS '药品编号',
    drug_name AS '药品名称',
    drug_price AS '单价',
    drug_quantity AS '当前库存',
    drug_storage AS '存储位置',
    usefull_life AS '有效期',
    CASE 
        WHEN drug_quantity < 100 THEN N'库存不足'
        WHEN usefull_life < DATEADD(MONTH, 3, GETDATE()) THEN N'即将过期'
        ELSE N'正常'
    END AS '预警状态',
    DATEDIFF(DAY, GETDATE(), usefull_life) AS '距过期天数'
FROM drugs_3123004721_yuanzixuan
WHERE is_delete = 0
  AND (drug_quantity < 100 OR usefull_life < DATEADD(MONTH, 3, GETDATE()));
GO

-- ============================================
-- 3. 每日营收统计视图
-- 功能: 分组聚集统计每日收入
-- ============================================
IF OBJECT_ID('v_daily_revenue_3123004721', 'V') IS NOT NULL
    DROP VIEW v_daily_revenue_3123004721;
GO

CREATE VIEW v_daily_revenue_3123004721 AS
SELECT 
    CONVERT(DATE, create_time) AS '日期',
    COUNT(*) AS '收费笔数',
    SUM(amount) AS '当日营收',
    AVG(amount) AS '平均单笔金额',
    MAX(amount) AS '最大单笔',
    MIN(amount) AS '最小单笔'
FROM charge_3123004721_yuanzixuan
WHERE is_delete = 0
GROUP BY CONVERT(DATE, create_time);
GO

-- ============================================
-- 4. 科室工作量统计视图
-- 功能: 按科室分组统计挂号量
-- ============================================
IF OBJECT_ID('v_dept_workload_3123004721', 'V') IS NOT NULL
    DROP VIEW v_dept_workload_3123004721;
GO

CREATE VIEW v_dept_workload_3123004721 AS
SELECT 
    r_dept AS '科室名称',
    COUNT(*) AS '挂号总数',
    COUNT(DISTINCT r_doctor_id) AS '出诊医生数',
    COUNT(DISTINCT r_patient_id) AS '就诊病人数'
FROM register_3123004721_yuanzixuan
WHERE is_delete = 0
GROUP BY r_dept;
GO

-- ============================================
-- 5. 处方详情视图
-- 功能: 展示处方及其药品明细
-- ============================================
IF OBJECT_ID('v_prescription_detail_3123004721', 'V') IS NOT NULL
    DROP VIEW v_prescription_detail_3123004721;
GO

CREATE VIEW v_prescription_detail_3123004721 AS
SELECT 
    rec.id AS '处方编号',
    rec.patient_name AS '病人姓名',
    doc.d_name AS '开方医生',
    doc.d_dept AS '科室',
    drg.drug_name AS '药品名称',
    pd.quantity AS '数量',
    drg.drug_price AS '单价',
    (pd.quantity * drg.drug_price) AS '小计金额',
    rec.create_time AS '开方时间'
FROM recipel_3123004721_yuanzixuan rec
JOIN prescription_drug_3123004721_yuanzixuan pd ON rec.id = pd.prescription_id AND pd.is_delete = 0
JOIN drugs_3123004721_yuanzixuan drg ON pd.drug_id = drg.drug_id AND drg.is_delete = 0
JOIN doctor_3123004721_yuanzixuan doc ON rec.doctor_id = doc.d_octor_id AND doc.is_delete = 0
WHERE rec.is_delete = 0;
GO

PRINT N'视图创建完成！共创建5个视图。';
GO

-- ============================================
-- 医院信息管理系统数据库脚本
-- 作者: 袁子轩 (yuanzixuan)
-- 学号: 3123004721
-- 创建日期: 2024年12月
-- 命名规范: 数据库对象名_学号_姓名拼音
-- ============================================

-- 创建数据库
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'hospital_3123004721_yuanzixuan')
BEGIN
    CREATE DATABASE hospital_3123004721_yuanzixuan;
END
GO
USE hospital_3123004721_yuanzixuan;
GO

-- 按反向依赖顺序删除表以处理外键
IF OBJECT_ID('prescription_drug_3123004721_yuanzixuan', 'U') IS NOT NULL DROP TABLE prescription_drug_3123004721_yuanzixuan;
IF OBJECT_ID('recipel_3123004721_yuanzixuan', 'U') IS NOT NULL DROP TABLE recipel_3123004721_yuanzixuan;
IF OBJECT_ID('PGM_3123004721_yuanzixuan', 'U') IS NOT NULL DROP TABLE PGM_3123004721_yuanzixuan;
IF OBJECT_ID('charge_3123004721_yuanzixuan', 'U') IS NOT NULL DROP TABLE charge_3123004721_yuanzixuan;
IF OBJECT_ID('pay_3123004721_yuanzixuan', 'U') IS NOT NULL DROP TABLE pay_3123004721_yuanzixuan;
IF OBJECT_ID('register_3123004721_yuanzixuan', 'U') IS NOT NULL DROP TABLE register_3123004721_yuanzixuan;
IF OBJECT_ID('doctor_3123004721_yuanzixuan', 'U') IS NOT NULL DROP TABLE doctor_3123004721_yuanzixuan;
IF OBJECT_ID('patient_3123004721_yuanzixuan', 'U') IS NOT NULL DROP TABLE patient_3123004721_yuanzixuan;
IF OBJECT_ID('drugs_3123004721_yuanzixuan', 'U') IS NOT NULL DROP TABLE drugs_3123004721_yuanzixuan;
GO

-- 挂号表
CREATE TABLE register_3123004721_yuanzixuan (
    r_num INT IDENTITY(1,1) PRIMARY KEY, -- 挂号编号
    r_patient_id VARCHAR(20) NOT NULL, -- 病人身份证号
    r_P_name NVARCHAR(20) NOT NULL, -- 病人姓名
    r_sex NVARCHAR(2) NOT NULL, -- 性别
    r_dept NVARCHAR(20) NOT NULL, -- 挂号科室
    r_doctor_id INT NOT NULL, -- 医生ID
    r_name NVARCHAR(10) NOT NULL, -- 医生姓名
    is_delete TINYINT NOT NULL DEFAULT 0, -- 0为未删除 1为已删除
    create_time DATETIME DEFAULT GETDATE(), -- 创建字段的时间
    update_time DATETIME DEFAULT GETDATE() -- 修改字段的时间
);
GO

-- 医生表
CREATE TABLE doctor_3123004721_yuanzixuan (
    d_octor_id INT PRIMARY KEY, -- 医生编号
    d_name NVARCHAR(20) NOT NULL, -- 医生姓名
    d_sex NVARCHAR(2) NOT NULL, -- 医生性别
    d_age TINYINT NOT NULL, -- 医生年龄
    d_dept NVARCHAR(50) NOT NULL, -- 科室
    d_tel VARCHAR(20) NOT NULL, -- 电话
    is_jobing TINYINT DEFAULT 1 NOT NULL, -- 0为医生不在岗
    is_delete TINYINT NOT NULL DEFAULT 0,
    create_time DATETIME DEFAULT GETDATE(),
    update_time DATETIME DEFAULT GETDATE()
);
GO

-- 病人表
CREATE TABLE patient_3123004721_yuanzixuan (
    p_atient_id VARCHAR(20) PRIMARY KEY, -- 病人身份证号
    p_name NVARCHAR(20) NOT NULL, -- 病人姓名
    p_age TINYINT NOT NULL, -- 病人年龄
    p_sex NVARCHAR(2) NOT NULL, -- 病人性别
    p_tel VARCHAR(20) NOT NULL, -- 病人电话
    p_inf NVARCHAR(50) NOT NULL, -- 病例
    is_delete TINYINT NOT NULL DEFAULT 0, -- 0为未删除 1为已删除
    create_time DATETIME DEFAULT GETDATE(), -- 创建字段的时间
    update_time DATETIME DEFAULT GETDATE() -- 修改字段的时间
);
GO

-- 药品表
CREATE TABLE drugs_3123004721_yuanzixuan (
    drug_id VARCHAR(10) PRIMARY KEY, -- 药品编号
    drug_name NVARCHAR(50) NOT NULL, -- 药品名称
    drug_price DECIMAL(10, 2) NOT NULL, -- 药品价格
    drug_quantity BIGINT NOT NULL, -- 药品数量
    drug_storage NVARCHAR(50) NOT NULL, -- 存储位置
    drug_date DATETIME NOT NULL, -- 生产日期
    usefull_life DATETIME NOT NULL, -- 有效期
    is_delete TINYINT NOT NULL DEFAULT 0, -- 0为未删除 1为已删除
    create_time DATETIME DEFAULT GETDATE(), -- 创建字段的时间
    update_time DATETIME DEFAULT GETDATE() -- 修改字段的时间
);
GO

-- 收费表
CREATE TABLE charge_3123004721_yuanzixuan (
    toll_id VARCHAR(10), -- 收费员编号
    t_name NVARCHAR(10) NOT NULL, -- 收费员姓名
    patient_id VARCHAR(20), -- 病人编号
    drug_id VARCHAR(10), -- 药品编号
    drug_quantity INT NOT NULL, -- 药品数量
    amount DECIMAL(10, 2) NOT NULL, -- 金额
    is_delete TINYINT NOT NULL DEFAULT 0, -- 0为未删除 1为已删除
    create_time DATETIME DEFAULT GETDATE(), -- 创建字段的时间
    update_time DATETIME DEFAULT GETDATE(), -- 修改字段的时间
    PRIMARY KEY (toll_id, patient_id, drug_id)
);
GO

-- PGM 表（取药票单）
CREATE TABLE PGM_3123004721_yuanzixuan (
    t_id VARCHAR(10) NOT NULL, -- 收费编号
    drug_id VARCHAR(10) NOT NULL, -- 药品编号
    quantity INT NOT NULL, -- 数量
    price DECIMAL(10, 2) NOT NULL, -- 价格
    is_picked TINYINT NOT NULL DEFAULT 0, -- 0为未取药 1为已取药
    is_delete TINYINT NOT NULL DEFAULT 0,
    create_time DATETIME DEFAULT GETDATE(),
    update_time DATETIME DEFAULT GETDATE(),
    PRIMARY KEY (t_id, drug_id)
);
GO

-- 处方表
CREATE TABLE recipel_3123004721_yuanzixuan (
    id INT IDENTITY(1,1) PRIMARY KEY,
    doctor_id INT NOT NULL, -- 医生编号
    patient_name NVARCHAR(20) NOT NULL, -- 病人姓名
    registration_id INT, -- 挂号ID
    is_delete TINYINT NOT NULL DEFAULT 0,
    create_time DATETIME DEFAULT GETDATE(),
    update_time DATETIME DEFAULT GETDATE()
);
GO

-- 处方药品关联表
CREATE TABLE prescription_drug_3123004721_yuanzixuan (
    prescription_id INT NOT NULL, -- 处方ID
    drug_id VARCHAR(10) NOT NULL, -- 药品编号
    quantity INT NOT NULL, -- 数量
    is_delete TINYINT NOT NULL DEFAULT 0,
    create_time DATETIME DEFAULT GETDATE(),
    update_time DATETIME DEFAULT GETDATE(),
    PRIMARY KEY (prescription_id, drug_id),
    FOREIGN KEY (prescription_id) REFERENCES recipel_3123004721_yuanzixuan(id) ON DELETE CASCADE
);
GO

-- 支付表
CREATE TABLE pay_3123004721_yuanzixuan (
    patient_id VARCHAR(20), -- 病人编号
    t_id VARCHAR(10), -- 收费编号
    price DECIMAL(10, 2) NOT NULL, -- 价格
    is_delete TINYINT NOT NULL DEFAULT 0, -- 0为未删除 1为已删除
    create_time DATETIME DEFAULT GETDATE(), -- 创建字段的时间
    update_time DATETIME DEFAULT GETDATE(), -- 修改字段的时间
    PRIMARY KEY (patient_id, t_id)
);
GO

GO


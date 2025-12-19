-- ============================================
-- 医院信息管理系统 - SSMS纯后端版本
-- 作者: 袁子轩
-- 学号: 3123004721
-- 创建日期: 2025年12月
-- 说明: 此版本适用于SQL Server Management Studio直接管理
-- ============================================

-- ================ 1. 创建数据库 ================
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'hospital3123004721')
BEGIN
    CREATE DATABASE hospital3123004721;
END
GO

USE hospital3123004721;
GO

-- ================ 2. 创建表结构 ================

-- 2.1 挂号表
IF OBJECT_ID('register', 'U') IS NOT NULL DROP TABLE register;
CREATE TABLE register (
    r_num INT IDENTITY(1,1) PRIMARY KEY,        -- 挂号编号
    r_patient_id VARCHAR(20) NOT NULL,          -- 病人身份证号
    r_P_name NVARCHAR(20) NOT NULL,             -- 病人姓名
    r_sex NVARCHAR(2) NOT NULL,                 -- 性别
    r_dept NVARCHAR(20) NOT NULL,               -- 挂号科室
    r_doctor_id INT NOT NULL,                   -- 医生ID 
    r_name NVARCHAR(10) NOT NULL,               -- 医生姓名
    is_delete TINYINT NOT NULL DEFAULT 0,       -- 0未删除 1已删除
    create_time DATETIME DEFAULT GETDATE(),
    update_time DATETIME DEFAULT GETDATE()
);
GO

-- 2.2 医生表
IF OBJECT_ID('doctor', 'U') IS NOT NULL DROP TABLE doctor;
CREATE TABLE doctor (
    d_octor_id INT PRIMARY KEY,                 -- 医生编号
    d_name NVARCHAR(20) NOT NULL,               -- 医生姓名
    d_sex NVARCHAR(2) NOT NULL,                 -- 医生性别
    d_age TINYINT NOT NULL,                     -- 医生年龄
    d_dept NVARCHAR(50) NOT NULL,               -- 科室
    d_tel VARCHAR(20) NOT NULL,                 -- 电话
    is_jobing TINYINT DEFAULT 1 NOT NULL,       -- 0不在岗 1在岗
    is_delete TINYINT NOT NULL DEFAULT 0,
    create_time DATETIME DEFAULT GETDATE(),
    update_time DATETIME DEFAULT GETDATE()
);
GO

-- 2.3 病人表
IF OBJECT_ID('patient', 'U') IS NOT NULL DROP TABLE patient;
CREATE TABLE patient (
    p_atient_id VARCHAR(20) PRIMARY KEY,        -- 病人身份证号
    p_name NVARCHAR(20) NOT NULL,               -- 病人姓名
    p_age TINYINT NOT NULL,                     -- 病人年龄
    p_sex NVARCHAR(2) NOT NULL,                 -- 病人性别
    p_tel VARCHAR(20) NOT NULL,                 -- 病人电话
    p_inf NVARCHAR(200),                        -- 病例
    is_delete TINYINT NOT NULL DEFAULT 0,
    create_time DATETIME DEFAULT GETDATE(),
    update_time DATETIME DEFAULT GETDATE()
);
GO

-- 2.4 药品表
IF OBJECT_ID('drugs', 'U') IS NOT NULL DROP TABLE drugs;
CREATE TABLE drugs (
    drug_id VARCHAR(10) PRIMARY KEY,            -- 药品编号
    drug_name NVARCHAR(100) NOT NULL,           -- 药品名称
    drug_price DECIMAL(10,2) NOT NULL,          -- 药品价格
    drug_quantity INT NOT NULL,                 -- 药品数量
    drug_storage NVARCHAR(50) NOT NULL,         -- 存储位置
    drug_date DATE,                             -- 生产日期
    usefull_life DATE,                          -- 有效期
    is_delete TINYINT NOT NULL DEFAULT 0,
    create_time DATETIME DEFAULT GETDATE(),
    update_time DATETIME DEFAULT GETDATE()
);
GO

-- 2.5 处方表
IF OBJECT_ID('recipel', 'U') IS NOT NULL DROP TABLE recipel;
CREATE TABLE recipel (
    id INT IDENTITY(1,1) PRIMARY KEY,           -- 处方编号
    doctor_id INT NOT NULL,                     -- 医生编号
    patient_name NVARCHAR(20) NOT NULL,         -- 病人姓名
    registration_id INT,                        -- 关联挂号编号
    is_delete TINYINT NOT NULL DEFAULT 0,
    create_time DATETIME DEFAULT GETDATE(),
    update_time DATETIME DEFAULT GETDATE()
);
GO

-- 2.6 处方药品关联表
IF OBJECT_ID('prescription_drug', 'U') IS NOT NULL DROP TABLE prescription_drug;
CREATE TABLE prescription_drug (
    id INT IDENTITY(1,1) PRIMARY KEY,
    prescription_id INT NOT NULL,               -- 处方编号
    drug_id VARCHAR(10) NOT NULL,               -- 药品编号
    quantity INT NOT NULL,                      -- 数量
    is_delete TINYINT NOT NULL DEFAULT 0,
    create_time DATETIME DEFAULT GETDATE(),
    update_time DATETIME DEFAULT GETDATE()
);
GO

-- 2.7 收费表
IF OBJECT_ID('charge', 'U') IS NOT NULL DROP TABLE charge;
CREATE TABLE charge (
    id INT IDENTITY(1,1) PRIMARY KEY,
    toll_id VARCHAR(10),                        -- 收费编号
    t_name NVARCHAR(10) NOT NULL,               -- 收费员姓名
    patient_id VARCHAR(20),                     -- 病人编号
    drug_id VARCHAR(10),                        -- 药品编号
    drug_quantity INT NOT NULL,                 -- 药品数量
    amount DECIMAL(10,2) NOT NULL,              -- 金额
    is_delete TINYINT NOT NULL DEFAULT 0,
    create_time DATETIME DEFAULT GETDATE(),
    update_time DATETIME DEFAULT GETDATE()
);
GO

-- 2.8 支付表
IF OBJECT_ID('pay', 'U') IS NOT NULL DROP TABLE pay;
CREATE TABLE pay (
    id INT IDENTITY(1,1) PRIMARY KEY,
    patient_id VARCHAR(20),                     -- 病人编号
    t_id VARCHAR(10),                           -- 收费编号
    price DECIMAL(10,2) NOT NULL,               -- 价格
    is_delete TINYINT NOT NULL DEFAULT 0,
    create_time DATETIME DEFAULT GETDATE(),
    update_time DATETIME DEFAULT GETDATE()
);
GO

-- 2.9 取药票单表
IF OBJECT_ID('PGM', 'U') IS NOT NULL DROP TABLE PGM;
CREATE TABLE PGM (
    t_id VARCHAR(10) NOT NULL,                  -- 收费编号
    drug_id VARCHAR(10) NOT NULL,               -- 药品编号
    quantity INT NOT NULL,                      -- 数量
    price DECIMAL(10,2) NOT NULL,               -- 价格
    is_picked TINYINT NOT NULL DEFAULT 0,       -- 是否已取药 (0未取 1已取, 与主项目一致)
    is_delete TINYINT NOT NULL DEFAULT 0,
    create_time DATETIME DEFAULT GETDATE(),
    update_time DATETIME DEFAULT GETDATE(),
    PRIMARY KEY (t_id, drug_id)
);
GO

PRINT '表结构创建完成！';
GO

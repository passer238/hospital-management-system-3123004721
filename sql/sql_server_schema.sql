-- ============================================
-- 医院信息管理系统数据库脚本
-- 作者: 袁子轩
-- 学号: 3123004721
-- 创建日期: 2024年12月
-- ============================================

-- 创建数据库
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'hospital3123004721')
BEGIN
    CREATE DATABASE hospital3123004721;
END
GO
USE hospital3123004721;
GO

-- 按反向依赖顺序删除表以处理外键
IF OBJECT_ID('prescription_drug', 'U') IS NOT NULL DROP TABLE prescription_drug;
IF OBJECT_ID('recipel', 'U') IS NOT NULL DROP TABLE recipel;
IF OBJECT_ID('PGM', 'U') IS NOT NULL DROP TABLE PGM;
IF OBJECT_ID('charge', 'U') IS NOT NULL DROP TABLE charge;
IF OBJECT_ID('pay', 'U') IS NOT NULL DROP TABLE pay;
IF OBJECT_ID('register', 'U') IS NOT NULL DROP TABLE register;
IF OBJECT_ID('doctor', 'U') IS NOT NULL DROP TABLE doctor;
IF OBJECT_ID('patient', 'U') IS NOT NULL DROP TABLE patient;
IF OBJECT_ID('drugs', 'U') IS NOT NULL DROP TABLE drugs;
GO

-- 挂号表
IF OBJECT_ID('register', 'U') IS NOT NULL DROP TABLE register;
CREATE TABLE register (
    r_num INT IDENTITY(1,1) PRIMARY KEY, -- 挂号编号
    r_patient_id VARCHAR(20) NOT NULL, -- 病人身份证号
    r_P_name NVARCHAR(20) NOT NULL, -- 病人姓名
    r_sex NVARCHAR(2) NOT NULL, -- 性别
    r_dept NVARCHAR(20) NOT NULL, -- 挂号科室
    r_doctor_id INT NOT NULL, -- 医生ID (新增外键)
    r_name NVARCHAR(10) NOT NULL, -- 医生姓名 (保留冗余)
    is_delete TINYINT NOT NULL DEFAULT 0, -- 0为未删除 1为已删除
    create_time DATETIME DEFAULT GETDATE(), -- 创建字段的时间
    update_time DATETIME DEFAULT GETDATE() -- 修改字段的时间
);
GO

-- 医生表
IF OBJECT_ID('doctor', 'U') IS NOT NULL DROP TABLE doctor;
CREATE TABLE doctor (
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
IF OBJECT_ID('patient', 'U') IS NOT NULL DROP TABLE patient;
CREATE TABLE patient (
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
IF OBJECT_ID('drugs', 'U') IS NOT NULL DROP TABLE drugs;
CREATE TABLE drugs (
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
IF OBJECT_ID('charge', 'U') IS NOT NULL DROP TABLE charge;
CREATE TABLE charge (
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
IF OBJECT_ID('PGM', 'U') IS NOT NULL DROP TABLE PGM;
CREATE TABLE PGM (
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
IF OBJECT_ID('recipel', 'U') IS NOT NULL DROP TABLE recipel;
CREATE TABLE recipel (
    id INT IDENTITY(1,1) PRIMARY KEY,
    doctor_id INT NOT NULL, -- 医生编号 （已修复：更改为 INT）
    patient_name NVARCHAR(20) NOT NULL, -- 病人姓名
    registration_id INT, -- 挂号ID （确保存在这里，通常用于关联）
    is_delete TINYINT NOT NULL DEFAULT 0,
    create_time DATETIME DEFAULT GETDATE(),
    update_time DATETIME DEFAULT GETDATE()
);
GO

-- 处方药品关联表
IF OBJECT_ID('prescription_drug', 'U') IS NOT NULL DROP TABLE prescription_drug;
CREATE TABLE prescription_drug (
    prescription_id INT NOT NULL, -- 处方ID
    drug_id VARCHAR(10) NOT NULL, -- 药品编号
    quantity INT NOT NULL, -- 数量
    is_delete TINYINT NOT NULL DEFAULT 0,
    create_time DATETIME DEFAULT GETDATE(),
    update_time DATETIME DEFAULT GETDATE(),
    PRIMARY KEY (prescription_id, drug_id),
    FOREIGN KEY (prescription_id) REFERENCES recipel(id) ON DELETE CASCADE
);
GO

-- 支付表
IF OBJECT_ID('pay', 'U') IS NOT NULL DROP TABLE pay;
CREATE TABLE pay (
    patient_id VARCHAR(20), -- 病人编号
    t_id VARCHAR(10), -- 收费编号
    price DECIMAL(10, 2) NOT NULL, -- 价格
    is_delete TINYINT NOT NULL DEFAULT 0, -- 0为未删除 1为已删除
    create_time DATETIME DEFAULT GETDATE(), -- 创建字段的时间
    update_time DATETIME DEFAULT GETDATE(), -- 修改字段的时间
    PRIMARY KEY (patient_id, t_id)
);
GO

-- 初始数据插入（从 MySQL 转储转换）

-- 挂号数据
INSERT INTO register(r_patient_id, r_P_name, r_sex, r_dept, r_doctor_id, r_name) VALUES ('411282xxxxxxx1182', N'病人1', N'女', N'肛肠科', 3, N'尘思宇');
INSERT INTO register(r_patient_id, r_P_name, r_sex, r_dept, r_doctor_id, r_name) VALUES ('411282xxxxxxxx5555', N'病人1', N'男', N'牙科', 1, N'王渊洁');
INSERT INTO register(r_patient_id, r_P_name, r_sex, r_dept, r_doctor_id, r_name) VALUES ('421282xxxxxxxx5554', N'病人2', N'女', N'妇产科', 2, N'莫家里昂');
INSERT INTO register(r_patient_id, r_P_name, r_sex, r_dept, r_doctor_id, r_name) VALUES ('251381xxxxxxxx5553', N'病人3', N'男', N'肛肠科', 3, N'尘思语');
INSERT INTO register(r_patient_id, r_P_name, r_sex, r_dept, r_doctor_id, r_name) VALUES ('315213xxxxxxxx5552', N'病人4', N'女', N'呼吸道科', 4, N'杰瑞哲');

-- 医生数据
INSERT INTO doctor(d_octor_id, d_name, d_sex, d_age, d_dept, d_tel) VALUES (1, N'王渊洁', N'男', 30, N'牙科', '137xxxx321');
INSERT INTO doctor(d_octor_id, d_name, d_sex, d_age, d_dept, d_tel) VALUES (2, N'莫家里昂', N'男', 30, N'妇产科', '137xxxx111');
INSERT INTO doctor(d_octor_id, d_name, d_sex, d_age, d_dept, d_tel) VALUES (3, N'尘思语', N'男', 30, N'肛肠科', '137xxxx112');
INSERT INTO doctor(d_octor_id, d_name, d_sex, d_age, d_dept, d_tel) VALUES (4, N'杰瑞哲', N'男', 30, N'呼吸道科', '137xxxx113');
INSERT INTO doctor(d_octor_id, d_name, d_sex, d_age, d_dept, d_tel) VALUES (5, N'唐三', N'女', 30, N'肛肠科', '158xxxx113');
INSERT INTO doctor(d_octor_id, d_name, d_sex, d_age, d_dept, d_tel) VALUES (6, N'叶文洁', N'女', 30, N'骨科', '168xxxx113');
INSERT INTO doctor(d_octor_id, d_name, d_sex, d_age, d_dept, d_tel) VALUES (7, N'罗辑', N'男', 30, N'眼科', '133xxxx113');
INSERT INTO doctor(d_octor_id, d_name, d_sex, d_age, d_dept, d_tel) VALUES (8, N'尘心', N'女', 30, N'心理科', '155xxxx113');

-- 病人数据
INSERT INTO patient(p_atient_id, p_name, p_age, p_sex, p_tel, p_inf) VALUES ('411282xxxxxxxx5555', N'病人1', 24, N'男', '141xxxx532', N'牙疼');
INSERT INTO patient(p_atient_id, p_name, p_age, p_sex, p_tel, p_inf) VALUES ('421282xxxxxxxx5554', N'病人2', 24, N'女', '141xxxx532', N'生孩子');
INSERT INTO patient(p_atient_id, p_name, p_age, p_sex, p_tel, p_inf) VALUES ('251381xxxxxxxx5553', N'病人3', 40, N'男', '121xxxx532', N'胃疼腹泻');
INSERT INTO patient(p_atient_id, p_name, p_age, p_sex, p_tel, p_inf) VALUES ('315213xxxxxxxx5552', N'病人4', 40, N'女', '137xxxx532', N'肺炎');

-- 药品数据
INSERT INTO drugs(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('100023', N'感冒灵颗粒', 40.00, 821, 'A-2-302', '2021-09-01', '2022-09-01');
INSERT INTO drugs(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('100024', N'卡左双多巴缓释片', 56.00, 821, 'C-1-122', '2021-09-01', '2022-09-01');
INSERT INTO drugs(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('100025', N'拉莫三嗪片', 32.00, 821, 'C-2-102', '2021-09-01', '2022-09-01');
INSERT INTO drugs(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('100026', N'活血风湿膏', 28.00, 821, 'D-5-213', '2021-09-01', '2022-09-01');
INSERT INTO drugs(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('100027', N'龙穴羯', 63.00, 821, 'A-2-522', '2021-09-01', '2022-09-01');
INSERT INTO drugs(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('100028', N'龙胆泻肝片', 43.00, 821, 'B-2-302', '2021-09-01', '2022-09-01');
INSERT INTO drugs(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('100029', N'黑漆丹', 54.00, 821, 'B-3-101', '2021-09-01', '2022-09-01');
INSERT INTO drugs(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000210', N'黄连羊肝丸', 23.00, 821, 'A-1-002', '2021-09-01', '2022-09-01');
INSERT INTO drugs(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000211', N'黄连解毒丸', 31.00, 821, 'A-1-101', '2021-09-01', '2022-09-01');
INSERT INTO drugs(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000212', N'黄金波药酒', 43.00, 821, 'A-1-110', '2021-09-01', '2022-09-01');
INSERT INTO drugs(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000213', N'黄连上清片', 12.00, 821, 'A-1-111', '2021-09-01', '2022-09-01');
INSERT INTO drugs(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000214', N'维C银翘片', 8.00, 821, 'B-1-102', '2021-09-01', '2022-09-01');
INSERT INTO drugs(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000215', N'骨筋丸胶囊', 37.00, 821, 'C-2-302', '2021-09-01', '2022-09-01');
INSERT INTO drugs(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000216', N'除障泽海甫片', 14.00, 821, 'D-1-102', '2021-09-01', '2022-09-01');
INSERT INTO drugs(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000217', N'除脂生发片', 36.00, 821, 'C-1-102', '2021-09-01', '2022-09-01');
INSERT INTO drugs(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000218', N'远志糖浆', 43.00, 821, 'B-2-100', '2021-09-01', '2022-09-01');
INSERT INTO drugs(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000219', N'还少丹', 40.00, 821, 'C-3-001', '2021-09-01', '2022-09-01');
INSERT INTO drugs(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000220', N'当归补血丸', 20.00, 821, 'A-3-291', '2021-09-01', '2022-09-01');
INSERT INTO drugs(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000221', N'胃康灵胶囊', 50.00, 821, 'B-2-231', '2021-09-01', '2022-09-01');
INSERT INTO drugs(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000222', N'维生素B2注射液', 64.00, 821, 'C-1-213', '2021-09-01', '2022-09-01');
INSERT INTO drugs(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000223', N'磺胺甲噁唑', 56.00, 821, 'B-1-221', '2021-09-01', '2022-09-01');
INSERT INTO drugs(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000224', N'乙型肝炎病毒表面抗原检测试剂盒(化学发光法)', 240.00, 821, 'B-2-312', '2021-09-01', '2022-09-01');
INSERT INTO drugs(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000225', N'多糖止血修复生物胶液（生物多糖冲洗胶液）', 140.00, 821, 'C-2-011', '2021-09-01', '2022-09-01');
INSERT INTO drugs(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000226', N'D-二聚体试剂盒', 40.00, 821, 'C-5-190', '2021-09-01', '2022-09-01');
INSERT INTO drugs(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000227', N'Pholcodine', 340.00, 821, 'C-4-302', '2021-09-01', '2022-09-01');
INSERT INTO drugs(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000228', N'尼可待因', 221.00, 821, 'C-6-302', '2021-09-01', '2022-09-01');
INSERT INTO drugs(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000229', N'Ethylmorphine', 440.00, 821, 'C-4-202', '2021-09-01', '2022-09-01');
INSERT INTO drugs(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000230', N'Thiofentanyl', 540.00, 821, 'C-3-271', '2021-09-01', '2022-09-01');
INSERT INTO drugs(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000231', N'2-二甲氨基-1-[3,4-(亚甲二氧基)苯基]-1-丙酮', 740.00, 821, 'C-4-102', '2021-09-01', '2022-09-01');
INSERT INTO drugs(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000232', N'丹黄祛瘀胶囊', 40.00, 821, 'B-4-555', '2021-09-01', '2022-09-01');
INSERT INTO drugs(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000233', N'生血宁片', 20.00, 821, 'B-2-222', '2021-09-01', '2022-09-01');
INSERT INTO drugs(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000234', N'乌灵胶囊', 10.00, 821, 'A-3-231', '2021-09-01', '2022-09-01');
INSERT INTO drugs(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000235', N'清热止咳颗粒', 23.00, 821, 'B-7-456', '2021-09-01', '2022-09-01');
INSERT INTO drugs(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000236', N'杜仲补天素丸', 28.00, 821, 'A-6-291', '2021-09-01', '2022-09-01');

-- 收费数据
INSERT INTO charge(toll_id, t_name, patient_id, drug_id, drug_quantity, amount) VALUES ('001', N'收费员1', '411282xxxxxxxx5555', '100023', 2, 80.00);
INSERT INTO charge(toll_id, t_name, patient_id, drug_id, drug_quantity, amount) VALUES ('002', N'收费员1', '421282xxxxxxxx5554', '1000233', 1, 20.00);
INSERT INTO charge(toll_id, t_name, patient_id, drug_id, drug_quantity, amount) VALUES ('003', N'收费员1', '251381xxxxxxxx5553', '1000229', 1, 440.00);
INSERT INTO charge(toll_id, t_name, patient_id, drug_id, drug_quantity, amount) VALUES ('004', N'收费员1', '315213xxxxxxxx5552', '1000230', 2, 1080.00);

-- PGM数据
INSERT INTO PGM(t_id, drug_id, quantity, price) VALUES ('001', '100023', 2, 80.00);
INSERT INTO PGM(t_id, drug_id, quantity, price) VALUES ('002', '1000233', 1, 20.00);
INSERT INTO PGM(t_id, drug_id, quantity, price) VALUES ('003', '1000229', 1, 440.00);
INSERT INTO PGM(t_id, drug_id, quantity, price) VALUES ('004', '1000230', 2, 1080.00);

-- 处方数据
INSERT INTO recipel(doctor_id, patient_name, registration_id) VALUES (1, N'病人1', 2);
INSERT INTO recipel(doctor_id, patient_name, registration_id) VALUES (2, N'病人2', 3); 
INSERT INTO recipel(doctor_id, patient_name, registration_id) VALUES (3, N'病人3', 4);
INSERT INTO recipel(doctor_id, patient_name, registration_id) VALUES (4, N'病人4', 5);

-- 处方药品数据
-- 为处方1添加两种药品
INSERT INTO prescription_drug(prescription_id, drug_id, quantity) VALUES (1, '100023', 2);
INSERT INTO prescription_drug(prescription_id, drug_id, quantity) VALUES (1, '100024', 1);
-- 为处方2添加一种药品
INSERT INTO prescription_drug(prescription_id, drug_id, quantity) VALUES (2, '1000233', 1);
-- 为处方3添加三种药品
INSERT INTO prescription_drug(prescription_id, drug_id, quantity) VALUES (3, '1000229', 1);
INSERT INTO prescription_drug(prescription_id, drug_id, quantity) VALUES (3, '1000230', 1);
INSERT INTO prescription_drug(prescription_id, drug_id, quantity) VALUES (3, '1000231', 2);
-- 为处方4添加一种药品
INSERT INTO prescription_drug(prescription_id, drug_id, quantity) VALUES (4, '1000230', 2);

-- 支付数据
INSERT INTO pay(patient_id, t_id, price) VALUES ('411282xxxxxxxx5555', '001', 80.00);
INSERT INTO pay(patient_id, t_id, price) VALUES ('421282xxxxxxxx5554', '002', 20.00);
INSERT INTO pay(patient_id, t_id, price) VALUES ('251381xxxxxxxx5553', '003', 440.00);
INSERT INTO pay(patient_id, t_id, price) VALUES ('315213xxxxxxxx5552', '004', 1080.00);

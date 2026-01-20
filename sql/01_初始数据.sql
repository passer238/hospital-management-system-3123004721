-- ============================================
-- 医院信息管理系统 - 初始数据插入脚本
-- 作者: 袁子轩 (yuanzixuan)
-- 学号: 3123004721
-- ============================================

USE hospital_3123004721_yuanzixuan;
GO

-- 医生数据
INSERT INTO doctor_3123004721_yuanzixuan(d_octor_id, d_name, d_sex, d_age, d_dept, d_tel) VALUES (1, N'张三', N'男', 30, N'牙科', '137xxxx321');
INSERT INTO doctor_3123004721_yuanzixuan(d_octor_id, d_name, d_sex, d_age, d_dept, d_tel) VALUES (2, N'李四', N'男', 30, N'妇产科', '137xxxx111');
INSERT INTO doctor_3123004721_yuanzixuan(d_octor_id, d_name, d_sex, d_age, d_dept, d_tel) VALUES (3, N'王五', N'男', 30, N'肛肠科', '137xxxx112');
INSERT INTO doctor_3123004721_yuanzixuan(d_octor_id, d_name, d_sex, d_age, d_dept, d_tel) VALUES (4, N'钱六', N'男', 30, N'呼吸道科', '137xxxx113');
INSERT INTO doctor_3123004721_yuanzixuan(d_octor_id, d_name, d_sex, d_age, d_dept, d_tel) VALUES (5, N'孙七', N'女', 30, N'肛肠科', '158xxxx113');
INSERT INTO doctor_3123004721_yuanzixuan(d_octor_id, d_name, d_sex, d_age, d_dept, d_tel) VALUES (6, N'赵大', N'女', 30, N'骨科', '168xxxx113');
INSERT INTO doctor_3123004721_yuanzixuan(d_octor_id, d_name, d_sex, d_age, d_dept, d_tel) VALUES (7, N'李二', N'男', 30, N'眼科', '133xxxx113');
INSERT INTO doctor_3123004721_yuanzixuan(d_octor_id, d_name, d_sex, d_age, d_dept, d_tel) VALUES (8, N'唐八', N'女', 30, N'心理科', '155xxxx113');
GO

-- 病人数据
INSERT INTO patient_3123004721_yuanzixuan(p_atient_id, p_name, p_age, p_sex, p_tel, p_inf) VALUES ('1001', N'病人1', 24, N'男', '141xxxx532', N'牙疼');
INSERT INTO patient_3123004721_yuanzixuan(p_atient_id, p_name, p_age, p_sex, p_tel, p_inf) VALUES ('1002', N'病人2', 24, N'女', '141xxxx532', N'生孩子');
INSERT INTO patient_3123004721_yuanzixuan(p_atient_id, p_name, p_age, p_sex, p_tel, p_inf) VALUES ('1003', N'病人3', 40, N'男', '121xxxx532', N'胃疼腹泻');
INSERT INTO patient_3123004721_yuanzixuan(p_atient_id, p_name, p_age, p_sex, p_tel, p_inf) VALUES ('1004', N'病人4', 40, N'女', '137xxxx532', N'肺炎');
GO

-- 药品数据
INSERT INTO drugs_3123004721_yuanzixuan(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('100023', N'感冒灵颗粒', 40.00, 821, 'A-2-302', '2025-09-01', '2027-09-01');
INSERT INTO drugs_3123004721_yuanzixuan(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('100024', N'卡左双多巴缓释片', 56.00, 821, 'C-1-122', '2025-09-01', '2027-09-01');
INSERT INTO drugs_3123004721_yuanzixuan(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('100025', N'拉莫三嗪片', 32.00, 821, 'C-2-102', '2025-09-01', '2027-09-01');
INSERT INTO drugs_3123004721_yuanzixuan(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('100026', N'活血风湿膏', 28.00, 821, 'D-5-213', '2025-09-01', '2027-09-01');
INSERT INTO drugs_3123004721_yuanzixuan(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('100027', N'龙穴羯', 63.00, 821, 'A-2-522', '2025-09-01', '2027-09-01');
INSERT INTO drugs_3123004721_yuanzixuan(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('100028', N'龙胆泻肝片', 43.00, 821, 'B-2-302', '2025-09-01', '2027-09-01');
INSERT INTO drugs_3123004721_yuanzixuan(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('100029', N'黑漆丹', 54.00, 821, 'B-3-101', '2025-09-01', '2027-09-01');
INSERT INTO drugs_3123004721_yuanzixuan(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000210', N'黄连羊肝丸', 23.00, 821, 'A-1-002', '2025-09-01', '2027-09-01');
INSERT INTO drugs_3123004721_yuanzixuan(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000211', N'黄连解毒丸', 31.00, 821, 'A-1-101', '2025-09-01', '2027-09-01');
INSERT INTO drugs_3123004721_yuanzixuan(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000212', N'黄金波药酒', 43.00, 821, 'A-1-110', '2025-09-01', '2027-09-01');
INSERT INTO drugs_3123004721_yuanzixuan(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000213', N'黄连上清片', 12.00, 821, 'A-1-111', '2025-09-01', '2027-09-01');
INSERT INTO drugs_3123004721_yuanzixuan(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000214', N'维C银翘片', 8.00, 821, 'B-1-102', '2025-09-01', '2027-09-01');
INSERT INTO drugs_3123004721_yuanzixuan(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000215', N'骨筋丸胶囊', 37.00, 821, 'C-2-302', '2025-09-01', '2027-09-01');
INSERT INTO drugs_3123004721_yuanzixuan(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000216', N'除障泽海甫片', 14.00, 821, 'D-1-102', '2025-09-01', '2027-09-01');
INSERT INTO drugs_3123004721_yuanzixuan(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000217', N'除脂生发片', 36.00, 821, 'C-1-102', '2025-09-01', '2027-09-01');
INSERT INTO drugs_3123004721_yuanzixuan(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000218', N'远志糖浆', 43.00, 821, 'B-2-100', '2025-09-01', '2027-09-01');
INSERT INTO drugs_3123004721_yuanzixuan(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000219', N'还少丹', 40.00, 821, 'C-3-001', '2025-09-01', '2027-09-01');
INSERT INTO drugs_3123004721_yuanzixuan(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000220', N'当归补血丸', 20.00, 821, 'A-3-291', '2025-09-01', '2027-09-01');
INSERT INTO drugs_3123004721_yuanzixuan(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000221', N'胃康灵胶囊', 50.00, 821, 'B-2-231', '2025-09-01', '2027-09-01');
INSERT INTO drugs_3123004721_yuanzixuan(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000222', N'维生素B2注射液', 64.00, 821, 'C-1-213', '2025-09-01', '2027-09-01');
INSERT INTO drugs_3123004721_yuanzixuan(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000223', N'磺胺甲噁唑', 56.00, 821, 'B-1-221', '2025-09-01', '2027-09-01');
INSERT INTO drugs_3123004721_yuanzixuan(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000224', N'乙型肝炎病毒表面抗原检测试剂盒(化学发光法)', 240.00, 821, 'B-2-312', '2025-09-01', '2027-09-01');
INSERT INTO drugs_3123004721_yuanzixuan(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000225', N'多糖止血修复生物胶液（生物多糖冲洗胶液）', 140.00, 821, 'C-2-011', '2025-09-01', '2027-09-01');
INSERT INTO drugs_3123004721_yuanzixuan(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000226', N'D-二聚体试剂盒', 40.00, 821, 'C-5-190', '2025-09-01', '2027-09-01');
INSERT INTO drugs_3123004721_yuanzixuan(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000227', N'Pholcodine', 340.00, 821, 'C-4-302', '2025-09-01', '2027-09-01');
INSERT INTO drugs_3123004721_yuanzixuan(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000228', N'尼可待因', 221.00, 821, 'C-6-302', '2025-09-01', '2027-09-01');
INSERT INTO drugs_3123004721_yuanzixuan(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000229', N'Ethylmorphine', 440.00, 821, 'C-4-202', '2025-09-01', '2027-09-01');
INSERT INTO drugs_3123004721_yuanzixuan(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000230', N'Thiofentanyl', 540.00, 821, 'C-3-271', '2025-09-01', '2027-09-01');
INSERT INTO drugs_3123004721_yuanzixuan(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000231', N'2-二甲氨基-1-[3,4-(亚甲二氧基)苯基]-1-丙酮', 740.00, 821, 'C-4-102', '2025-09-01', '2027-09-01');
INSERT INTO drugs_3123004721_yuanzixuan(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000232', N'丹黄祛瘀胶囊', 40.00, 821, 'B-4-555', '2025-09-01', '2027-09-01');
INSERT INTO drugs_3123004721_yuanzixuan(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000233', N'生血宁片', 20.00, 821, 'B-2-222', '2025-09-01', '2027-09-01');
INSERT INTO drugs_3123004721_yuanzixuan(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000234', N'乌灵胶囊', 10.00, 821, 'A-3-231', '2025-09-01', '2027-09-01');
INSERT INTO drugs_3123004721_yuanzixuan(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000235', N'清热止咳颗粒', 23.00, 821, 'B-7-456', '2025-09-01', '2027-09-01');
INSERT INTO drugs_3123004721_yuanzixuan(drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES ('1000236', N'杜仲补天素丸', 28.00, 821, 'A-6-291', '2000-09-01', '2002-09-01');
GO

PRINT '数据库初始化完成！';
PRINT '数据库: hospital_3123004721_yuanzixuan';
PRINT '作者: 袁子轩 (学号: 3123004721)';
GO

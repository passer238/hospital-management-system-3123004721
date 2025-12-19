# 医院信息管理系统
> **作者**: 袁子轩  
> **学号**: 3123004721  
> **日期**: 2025年12月

---

## 目录结构

```
纯后端/
├── 01_建表脚本.sql      -- 数据库和表结构创建
├── 02_存储过程.sql      -- 所有业务逻辑存储过程
├── 03_视图.sql          -- 数据查询视图
├── 04_测试数据.sql      -- 测试数据
└── README.md            -- 本说明文件
```

---

## 使用说明

### 1. 初始化数据库

在 SSMS 中按顺序执行以下脚本：

1. `01_建表脚本.sql` - 创建数据库和所有表
2. `02_存储过程.sql` - 创建存储过程
3. `03_视图.sql` - 创建视图
4. `04_测试数据.sql` - 插入测试数据（可选）

### 2. 业务操作示例

#### 2.1 挂号管理

```sql
-- 添加挂号（自动使用最小可用编号）
EXEC sp_AddRegistration '身份证号', N'姓名', N'性别', N'科室', N'医生姓名';

-- 删除挂号（级联删除所有关联数据，恢复库存）
EXEC sp_DeleteRegistration 挂号编号;
```

#### 2.2 医生管理

```sql
-- 添加医生
EXEC sp_AddDoctor 医生编号, N'姓名', N'性别', 年龄, N'科室', '电话';

-- 编辑医生
EXEC sp_EditDoctor 医生编号, N'新姓名', N'新性别', 新年龄, N'新科室', '新电话';

-- 删除医生
EXEC sp_DeleteDoctor 医生编号;
```

#### 2.3 病人管理

```sql
-- 添加病人
EXEC sp_AddPatient '身份证号', N'姓名', 年龄, N'性别', '电话', N'病例信息';

-- 编辑病人
EXEC sp_EditPatient '身份证号', N'新姓名', 新年龄, N'新性别', '新电话', N'新病例';

-- 删除病人
EXEC sp_DeletePatient '身份证号';
```

#### 2.4 药品管理

```sql
-- 添加药品
EXEC sp_AddDrug '药品编号', N'药品名称', 价格, 数量, N'存储位置', '生产日期', '有效期';

-- 编辑药品
EXEC sp_EditDrug '药品编号', N'新名称', 新价格, 新数量, N'新存储位置';

-- 删除药品
EXEC sp_DeleteDrug '药品编号';
```

#### 2.5 处方管理

```sql
-- 创建处方（使用最小可用编号，关联挂号）
DECLARE @prescription_id INT;
EXEC sp_CreatePrescription 挂号编号, 医生编号, N'病人姓名', @prescription_id OUTPUT;
PRINT '处方编号: ' + CAST(@prescription_id AS VARCHAR);

-- 添加处方药品（自动扣库存、生成收费记录）
EXEC sp_AddPrescriptionDrug @prescription_id, '药品编号', 数量;

-- 删除处方（恢复库存）
EXEC sp_DeletePrescription 处方编号;
```

#### 2.6 支付管理

```sql
-- 支付（自动生成取药票单）
EXEC sp_MakePayment '病人身份证号', '收费编号', 金额;

-- 删除支付（级联删除取药票单）
EXEC sp_DeletePayment '病人身份证号', '收费编号';
```

#### 2.7 取药管理

```sql
-- 标记单个药品已取药
EXEC sp_MarkPickup '收费编号', '药品编号';

-- 标记全部已取药
EXEC sp_MarkAllPickup '收费编号';
```

## 数据库说明

本项目使用的数据库名为 **`hospital3123004721`**。

在执行 `01_建表脚本.sql` 时，脚本会自动创建该数据库。

---

## 常用查询

```sql
-- 查看所有挂号
SELECT * FROM v_Registrations;

-- 查看在岗医生
SELECT * FROM v_Doctors;

-- 查看病人信息
SELECT * FROM v_Patients;

-- 查看药品库存
SELECT * FROM v_Drugs;

-- 查看库存预警
SELECT * FROM v_LowStockDrugs;

-- 查看处方详情
SELECT * FROM v_PrescriptionDetails;

-- 查看未开处方的挂号
SELECT * FROM v_UnprescribedRegistrations;

-- 查看未支付收费
SELECT * FROM v_UnpaidCharges;

-- 查看取药票单（含状态）
SELECT * FROM v_Pickups;

-- 科室统计
SELECT * FROM v_DeptRegistrationStats;

-- 医生工作量
SELECT * FROM v_DoctorWorkloadStats;

-- 热门药品
SELECT * FROM v_PopularDrugs;

-- 收入统计
SELECT * FROM v_RevenueStats;

-- 取药完成率
SELECT * FROM v_PickupStats;

-- 待处理事项一览
SELECT * FROM v_PendingTasks;
```

---

## 级联删除说明

### 删除挂号时的级联顺序

```
恢复药品库存 → 取药票单(PGM) → 支付(pay) → 收费(charge) → 处方药品(prescription_drug) → 处方(recipel) → 挂号(register)
```

### 删除处方时的级联顺序

```
恢复库存 → 收费(charge) → 处方药品(prescription_drug) → 处方(recipel)
```

### 删除支付时的级联顺序

```
取药票单(PGM) → 支付(pay)
```

---

## 注意事项

1. 所有删除操作都是**硬删除**，数据不可恢复
2. 删除处方和挂号时会**自动恢复药品库存**
3. 同一挂号只能开具**一个处方**（按挂号编号关联）
4. 支付完成后会**自动生成取药票单**
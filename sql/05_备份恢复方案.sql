-- ============================================
-- 医院信息管理系统 - 数据库备份与恢复方案
-- 作者: 袁子轩 (yuanzixuan)
-- 学号: 3123004721
-- 创建日期: 2025年12月
-- ============================================

/*
===========================================
一、备份策略
===========================================

1. 完整备份 (Full Backup)
   - 频率: 每天凌晨2:00执行
   - 保留周期: 7天
   - 存储位置: D:\Backup\Hospital\Full\

2. 差异备份 (Differential Backup)
   - 频率: 每6小时执行一次
   - 保留周期: 3天
   - 存储位置: D:\Backup\Hospital\Diff\

3. 事务日志备份 (Transaction Log Backup)
   - 频率: 每15分钟执行一次
   - 保留周期: 1天
   - 存储位置: D:\Backup\Hospital\Log\
*/

-- ===========================================
-- 二、备份脚本示例
-- ===========================================

-- 1. 完整备份脚本
BACKUP DATABASE hospital_3123004721_yuanzixuan
TO DISK = 'D:\Backup\Hospital\Full\hospital_full_backup.bak'
WITH FORMAT, 
     MEDIANAME = 'HospitalFullBackup',
     NAME = N'医院数据库完整备份',
     COMPRESSION,
     STATS = 10;
GO

-- 2. 差异备份脚本
BACKUP DATABASE hospital_3123004721_yuanzixuan
TO DISK = 'D:\Backup\Hospital\Diff\hospital_diff_backup.bak'
WITH DIFFERENTIAL,
     NAME = N'医院数据库差异备份',
     COMPRESSION,
     STATS = 10;
GO

-- 3. 事务日志备份脚本
BACKUP LOG hospital_3123004721_yuanzixuan
TO DISK = 'D:\Backup\Hospital\Log\hospital_log_backup.trn'
WITH NAME = N'医院数据库日志备份',
     COMPRESSION,
     STATS = 10;
GO

-- ===========================================
-- 三、恢复脚本示例
-- ===========================================

-- 完整恢复流程（灾难恢复场景）
/*
步骤1: 恢复最近的完整备份（使用NORECOVERY保持恢复状态）
*/
RESTORE DATABASE hospital_3123004721_yuanzixuan
FROM DISK = 'D:\Backup\Hospital\Full\hospital_full_backup.bak'
WITH NORECOVERY,
     REPLACE,
     STATS = 10;
GO

/*
步骤2: 恢复最近的差异备份
*/
RESTORE DATABASE hospital_3123004721_yuanzixuan
FROM DISK = 'D:\Backup\Hospital\Diff\hospital_diff_backup.bak'
WITH NORECOVERY,
     STATS = 10;
GO

/*
步骤3: 按顺序恢复所有事务日志备份
*/
RESTORE LOG hospital_3123004721_yuanzixuan
FROM DISK = 'D:\Backup\Hospital\Log\hospital_log_backup.trn'
WITH RECOVERY,
     STATS = 10;
GO

-- ===========================================
-- 四、自动化备份作业（使用SQL Server Agent）
-- ===========================================

-- 创建完整备份作业
USE msdb;
GO

-- 注意：此脚本需要在SQL Server Agent中执行
-- 以下为创建完整备份作业的示例代码

/*
EXEC dbo.sp_add_job
    @job_name = N'Hospital_FullBackup_Daily',
    @enabled = 1,
    @description = N'每日完整备份医院数据库';

EXEC dbo.sp_add_jobstep
    @job_name = N'Hospital_FullBackup_Daily',
    @step_name = N'执行完整备份',
    @subsystem = N'TSQL',
    @command = N'BACKUP DATABASE hospital_3123004721_yuanzixuan 
                 TO DISK = ''D:\Backup\Hospital\Full\hospital_full_'' + 
                 CONVERT(VARCHAR(8), GETDATE(), 112) + ''.bak''
                 WITH COMPRESSION, STATS = 10',
    @database_name = N'hospital_3123004721_yuanzixuan';

EXEC dbo.sp_add_schedule
    @schedule_name = N'每日凌晨2点',
    @freq_type = 4,
    @freq_interval = 1,
    @active_start_time = 020000;

EXEC dbo.sp_attach_schedule
    @job_name = N'Hospital_FullBackup_Daily',
    @schedule_name = N'每日凌晨2点';
*/

PRINT N'备份与恢复方案脚本创建完成！';
GO

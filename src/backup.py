import pyodbc
import os
import datetime

# 配置
SERVER = 'localhost'
DATABASE = 'hospital_3123004721_yuanzixuan'
CONNECTION_STRING = f'DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={SERVER};DATABASE={DATABASE};Trusted_Connection=yes;AutoCommit=True'

# 备份目录 (根据 SQL 文件中的规划)
BASE_DIR = r"D:\Backup\Hospital"
DIRS = {
    "Full": os.path.join(BASE_DIR, "Full"),
    "Diff": os.path.join(BASE_DIR, "Diff"),
    "Log": os.path.join(BASE_DIR, "Log")
}

def ensure_directories():
    print(f"正在检查并创建备份目录: {BASE_DIR} ...")
    try:
        if not os.path.exists(BASE_DIR):
            os.makedirs(BASE_DIR)
        for _, path in DIRS.items():
            if not os.path.exists(path):
                os.makedirs(path)
                print(f"已创建目录: {path}")
            else:
                print(f"目录已存在: {path}")
    except Exception as e:
        print(f"无法创建目录 (可能是权限不足): {e}")
        return False
    return True

def perform_full_backup():
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_file = os.path.join(DIRS["Full"], f"hospital_full_{timestamp}.bak")
    
    # 构造 SQL 语句
    sql = f"""
    BACKUP DATABASE [{DATABASE}]
    TO DISK = '{backup_file}'
    WITH FORMAT, 
         MEDIANAME = 'HospitalFullBackup',
         NAME = N'医院数据库完整备份_{timestamp}',
         COMPRESSION,
         STATS = 10;
    """
    
    print(f"\n开始执行完整备份...")
    print(f"目标文件: {backup_file}")
    
    try:
        conn = pyodbc.connect(CONNECTION_STRING, autocommit=True)
        cursor = conn.cursor()
        
        # 必须先确保在 master 上下文或者当前数据库上下文都可以，BACKUP DATABASE 可以在任何地方运行
        # 但通常建议在 master 下
        cursor.execute("USE master") 
        
        # 执行备份过程中捕获消息
        cursor.execute(sql)
        
        # 处理结果消息
        while cursor.nextset(): 
            pass
            
        print("备份命令执行完成。")
        conn.close()
        
        if os.path.exists(backup_file):
            size_mb = os.path.getsize(backup_file) / (1024 * 1024)
            print(f"备份成功！文件大小: {size_mb:.2f} MB")
        else:
            print("警告: 命令执行未报错，但未找到备份文件。")
            
    except Exception as e:
        print(f"备份失败: {e}")

if __name__ == "__main__":
    print("=== 医院管理系统数据库备份演示程序 ===")
    if ensure_directories():
        perform_full_backup()
    else:
        print("由于目录创建失败，终止备份演示。请尝试以管理员身份运行。")

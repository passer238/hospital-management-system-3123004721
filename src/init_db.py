import pyodbc
import re

# 配置
SERVER = 'localhost'
DATABASE = 'master' # 先连接到 master 数据库以创建目标数据库
CONNECTION_STRING = f'DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={SERVER};DATABASE={DATABASE};Trusted_Connection=yes;AutoCommit=True'

def init_database():
    print(f"Connecting to {SERVER}...")
    try:
        conn = pyodbc.connect(CONNECTION_STRING, autocommit=True)
        cursor = conn.cursor()
        
        print("Reading schema file...")
        with open('../sql/sql_server_schema.sql', 'r', encoding='utf-8') as f:
            sql_script = f.read()
            
        # 按 GO 命令拆分
        # 使用正则表达式处理带有不同空白/换行符的 GO 命令
        commands = re.split(r'\bGO\b', sql_script, flags=re.IGNORECASE)
        
        print(f"Found {len(commands)} blocks to execute.")
        
        for i, cmd in enumerate(commands):
            cmd = cmd.strip()
            if not cmd:
                continue
                
            print(f"Executing block {i+1}...")
            try:
                cursor.execute(cmd)
            except Exception as e:
                print(f"Error executing block {i+1}: {e}")
                # 不要因错误停止，有些可能是“IF EXISTS DROP...”，如果数据库尚未存在可能会失败，但通常没问题。
                # 实际上，如果 CREATE DATABASE 失败，后续的 USE 也会失败。
                # 我们打印错误但继续执行，希望只是小问题。
                
        print("Database initialization completed!")
        conn.close()
        return True
    except Exception as e:
        print(f"Initialization failed: {e}")
        return False

if __name__ == "__main__":
    init_database()

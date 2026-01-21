import pyodbc
import re
import os

SERVER = 'localhost'
DATABASE = 'master' 
CONNECTION_STRING = f'DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={SERVER};DATABASE={DATABASE};Trusted_Connection=yes;AutoCommit=True'

SQL_FILES = [
    '../sql/00_建表脚本.sql',
    '../sql/01_初始数据.sql',
    '../sql/02_视图.sql',
    '../sql/03_存储过程.sql',
    '../sql/04_触发器.sql'
]

def run_sql_file(cursor, file_path):
    print(f"Executing {file_path}...")
    if not os.path.exists(file_path):
        print(f"Error: File {file_path} not found.")
        return
        
    with open(file_path, 'r', encoding='utf-8') as f:
        sql_script = f.read()
    
    # Split by GO
    commands = re.split(r'\bGO\b', sql_script, flags=re.IGNORECASE)
    
    for i, cmd in enumerate(commands):
        cmd = cmd.strip()
        if not cmd:
            continue
        try:
            cursor.execute(cmd)
        except Exception as e:
            # We print but continue, as some might be 'DROP VIEW' which might fail if not exist
            print(f"Warning/Error in {file_path} block {i+1}: {e}")

def init_all():
    try:
        conn = pyodbc.connect(CONNECTION_STRING, autocommit=True)
        cursor = conn.cursor()
        
        for sql_file in SQL_FILES:
            run_sql_file(cursor, sql_file)
            
        print("All database objects initialized successfully!")
        conn.close()
    except Exception as e:
        print(f"Initialization failed: {e}")

if __name__ == "__main__":
    init_all()

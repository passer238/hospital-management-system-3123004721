from flask import Flask, render_template, request, redirect, url_for, flash, jsonify
import pyodbc

app = Flask(__name__)
app.secret_key = 'your_secret_key'  # 请将此更改为随机密钥

# ============================================
# 数据库配置
# 作者: 袁子轩
# 学号: 3123004721
# 命名规范: 数据库对象名后加学号和姓名
# ============================================

SERVER = 'localhost'
DATABASE = 'hospital_3123004721_yuanzixuan'
# 使用Trusted_Connection=yes进行Windows身份验证
# 或使用UID=username;PWD=password进行SQL Server身份验证
CONNECTION_STRING = f'DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={SERVER};DATABASE={DATABASE};Trusted_Connection=yes;'

# 表名常量 - 数据库对象命名规范：对象名_学号_姓名拼音
TABLE_SUFFIX = '_3123004721_yuanzixuan'
T_REGISTER = f'register{TABLE_SUFFIX}'
T_DOCTOR = f'doctor{TABLE_SUFFIX}'
T_PATIENT = f'patient{TABLE_SUFFIX}'
T_DRUGS = f'drugs{TABLE_SUFFIX}'
T_RECIPEL = f'recipel{TABLE_SUFFIX}'
T_PRESCRIPTION_DRUG = f'prescription_drug{TABLE_SUFFIX}'
T_CHARGE = f'charge{TABLE_SUFFIX}'
T_PAY = f'pay{TABLE_SUFFIX}'
T_PGM = f'PGM{TABLE_SUFFIX}'

def get_db_connection():
    try:
        conn = pyodbc.connect(CONNECTION_STRING)
        return conn
    except Exception as e:
        print(f"Database connection error: {e}")
        return None

def get_next_available_id(cursor, table_name, id_column):
    """获取表中最小可用的ID编号"""
    # 查找从1开始的第一个空缺ID
    cursor.execute(f"""
        SELECT MIN(t1.{id_column} + 1) as next_id
        FROM {table_name} t1
        WHERE NOT EXISTS (
            SELECT 1 FROM {table_name} t2 
            WHERE t2.{id_column} = t1.{id_column} + 1
        )
    """)
    result = cursor.fetchone()
    if result and result[0]:
        # 检查是否1号可用
        cursor.execute(f"SELECT 1 FROM {table_name} WHERE {id_column} = 1")
        if not cursor.fetchone():
            return 1
        return result[0]
    else:
        return 1

@app.route('/')
def index():
    return render_template('index.html')

# --- API 路由与视图 ---

# 1. 挂号管理
@app.route('/registration', methods=['GET', 'POST'])
def registration():
    conn = get_db_connection()
    if not conn:
        return "数据库连接失败", 500
    cursor = conn.cursor()

    if request.method == 'POST':
        # 添加新挂号
        r_patient_id = request.form['r_patient_id']
        r_P_name = request.form['r_P_name']
        r_sex = request.form['r_sex']
        r_dept = request.form['r_dept']
        r_doctor_id = request.form['r_doctor_id']
        r_name = request.form['r_name'] # 保留用于冗余/显示，或直接插入
        
        try:
            # 获取最小可用编号
            next_id = get_next_available_id(cursor, T_REGISTER, 'r_num')
            # 开启IDENTITY_INSERT以允许显式插入ID
            cursor.execute(f"SET IDENTITY_INSERT {T_REGISTER} ON")
            cursor.execute(f"INSERT INTO {T_REGISTER} (r_num, r_patient_id, r_P_name, r_sex, r_dept, r_doctor_id, r_name) VALUES (?, ?, ?, ?, ?, ?, ?)",
                           (next_id, r_patient_id, r_P_name, r_sex, r_dept, r_doctor_id, r_name))
            cursor.execute(f"SET IDENTITY_INSERT {T_REGISTER} OFF")
            conn.commit()
            flash(f'挂号成功！挂号编号: {next_id}', 'success')
        except Exception as e:
            flash(f'挂号失败: {e}', 'danger')
        
        return redirect(url_for('registration'))

    # 获取所有挂号记录
    cursor.execute(f"""
        SELECT r_num, r_patient_id, r_P_name, r_sex, r_dept, r_name, is_delete,
               CONVERT(VARCHAR, create_time, 120) as create_time, update_time
        FROM {T_REGISTER} WHERE is_delete = 0 ORDER BY create_time DESC
    """)
    registrations = cursor.fetchall()
    
    # 获取科室列表（从医生表中去重）
    cursor.execute(f"SELECT DISTINCT d_dept FROM {T_DOCTOR} WHERE is_delete = 0 ORDER BY d_dept")
    departments = [row[0] for row in cursor.fetchall()]
    
    # 获取所有在岗医生
    cursor.execute(f"SELECT d_octor_id, d_name, d_dept FROM {T_DOCTOR} WHERE is_delete = 0 AND is_jobing = 1 ORDER BY d_dept, d_name")
    doctors = cursor.fetchall()
    
    conn.close()
    return render_template('registration.html', registrations=registrations, departments=departments, doctors=doctors)

@app.route('/registration/delete/<int:id>', methods=['POST'])
def delete_registration(id):
    """删除挂号记录，级联删除所有关联记录"""
    conn = get_db_connection()
    if not conn:
        return "Database connection failed", 500
    cursor = conn.cursor()
    try:
        # 1. 查找关联的处方 ID (通过 registration_id)
        cursor.execute(f"SELECT id FROM {T_RECIPEL} WHERE registration_id = ?", (id,))
        prescriptions = cursor.fetchall()
        
        presc_ids = [row[0] for row in prescriptions]
        
        if presc_ids:
            # 准备 IN 查询的占位符
            placeholders = ', '.join('?' * len(presc_ids))
            # 注意: toll_id 和 t_id 在数据库中是 VARCHAR，但存的是 prescription_id 的字符串形式
            # 建议全部转为字符串进行查询
            presc_ids_str = [str(pid) for pid in presc_ids]
            
            # 2. 级联删除取药票单
            cursor.execute(f"DELETE FROM {T_PGM} WHERE t_id IN ({placeholders})", presc_ids_str)
            
            # 3. 级联删除支付记录
            cursor.execute(f"DELETE FROM {T_PAY} WHERE t_id IN ({placeholders})", presc_ids_str)
            
            # 4. 级联删除收费记录
            cursor.execute(f"DELETE FROM {T_CHARGE} WHERE toll_id IN ({placeholders})", presc_ids_str)
            
            # 5. 恢复药品库存 & 删除处方药品记录
            for pid in presc_ids:
                # 恢复库存
                cursor.execute(f"SELECT drug_id, quantity FROM {T_PRESCRIPTION_DRUG} WHERE prescription_id = ?", (pid,))
                p_drugs = cursor.fetchall()
                for pd in p_drugs:
                     cursor.execute(f"UPDATE {T_DRUGS} SET drug_quantity = drug_quantity + ? WHERE drug_id = ?", (pd[1], pd[0]))
                
                # 删除处方药品
                cursor.execute(f"DELETE FROM {T_PRESCRIPTION_DRUG} WHERE prescription_id = ?", (pid,))

            # 6. 删除处方
            cursor.execute(f"DELETE FROM {T_RECIPEL} WHERE id IN ({placeholders})", presc_ids)
            
        # 7. 删除挂号记录
        cursor.execute(f"DELETE FROM {T_REGISTER} WHERE r_num = ?", (id,))
        
        conn.commit()
        flash('挂号及关联记录删除成功！', 'success')
    except Exception as e:
        conn.rollback()
        flash(f'删除失败: {e}', 'danger')
    conn.close()
    return redirect(url_for('registration'))

# API: 根据身份证号查询病人信息
@app.route('/api/patient/<string:patient_id>', methods=['GET'])
def get_patient_info(patient_id):
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': '数据库连接失败'}), 500
    cursor = conn.cursor()
    try:
        cursor.execute(f"SELECT p_atient_id, p_name, p_sex FROM {T_PATIENT} WHERE p_atient_id = ? AND is_delete = 0", (patient_id,))
        result = cursor.fetchone()
        conn.close()
        
        if result:
            return jsonify({
                'success': True,
                'patient_id': result[0],
                'name': result[1],
                'sex': result[2]
            })
        else:
            return jsonify({
                'success': False,
                'message': '未找到该病人信息，请先到病人管理模块添加病人'
            })
    except Exception as e:
        conn.close()
        return jsonify({'error': str(e)}), 500

# 2. 医生管理
@app.route('/doctors', methods=['GET', 'POST'])
def doctors():
    conn = get_db_connection()
    if not conn:
        return "Database connection failed", 500
    cursor = conn.cursor()

    if request.method == 'POST':
        d_octor_id = request.form['d_octor_id']
        d_name = request.form['d_name']
        d_sex = request.form['d_sex']
        d_age = request.form['d_age']
        d_dept = request.form['d_dept']
        d_tel = request.form['d_tel']
        
        try:
            cursor.execute(f"INSERT INTO {T_DOCTOR} (d_octor_id, d_name, d_sex, d_age, d_dept, d_tel) VALUES (?, ?, ?, ?, ?, ?)",
                           (d_octor_id, d_name, d_sex, d_age, d_dept, d_tel))
            conn.commit()
            flash('医生添加成功！', 'success')
        except Exception as e:
            flash(f'添加医生失败: {e}', 'danger')
        return redirect(url_for('doctors'))

    cursor.execute(f"SELECT * FROM {T_DOCTOR} WHERE is_delete = 0")
    doctors = cursor.fetchall()
    conn.close()
    return render_template('doctors.html', doctors=doctors)

@app.route('/doctors/delete/<int:id>', methods=['POST'])
def delete_doctor(id):
    conn = get_db_connection()
    if not conn:
        return "Database connection failed", 500
    cursor = conn.cursor()
    try:
        cursor.execute(f"DELETE FROM {T_DOCTOR} WHERE d_octor_id = ?", (id,))
        conn.commit()
        flash('医生删除成功！', 'success')
    except Exception as e:
        flash(f'删除失败: {e}', 'danger')
    conn.close()
    return redirect(url_for('doctors'))

@app.route('/doctors/edit', methods=['POST'])
def edit_doctor_submit():
    """编辑医生信息"""
    conn = get_db_connection()
    if not conn:
        return "Database connection failed", 500
    cursor = conn.cursor()
    try:
        d_octor_id = request.form['d_octor_id']
        d_name = request.form['d_name']
        d_sex = request.form['d_sex']
        d_age = request.form['d_age']
        d_dept = request.form['d_dept']
        d_tel = request.form['d_tel']
        
        cursor.execute(f"""
            UPDATE {T_DOCTOR} SET d_name = ?, d_sex = ?, d_age = ?, d_dept = ?, d_tel = ?, update_time = GETDATE()
            WHERE d_octor_id = ?
        """, (d_name, d_sex, d_age, d_dept, d_tel, d_octor_id))
        conn.commit()
        flash('医生信息更新成功！', 'success')
    except Exception as e:
        flash(f'更新失败: {e}', 'danger')
    conn.close()
    return redirect(url_for('doctors'))

# 3. 病人管理
@app.route('/patients', methods=['GET', 'POST'])
def patients():
    conn = get_db_connection()
    if not conn:
        return "Database connection failed", 500
    cursor = conn.cursor()

    if request.method == 'POST':
        p_atient_id = request.form['p_atient_id']
        p_name = request.form['p_name']
        p_age = request.form['p_age']
        p_sex = request.form['p_sex']
        p_tel = request.form['p_tel']
        p_inf = request.form['p_inf']
        
        try:
            cursor.execute(f"INSERT INTO {T_PATIENT} (p_atient_id, p_name, p_age, p_sex, p_tel, p_inf) VALUES (?, ?, ?, ?, ?, ?)",
                           (p_atient_id, p_name, p_age, p_sex, p_tel, p_inf))
            conn.commit()
            flash('病人添加成功！', 'success')
        except Exception as e:
            flash(f'添加病人失败: {e}', 'danger')
        return redirect(url_for('patients'))

    cursor.execute(f"SELECT * FROM {T_PATIENT} WHERE is_delete = 0")
    patients = cursor.fetchall()
    conn.close()
    return render_template('patients.html', patients=patients)

@app.route('/patients/delete/<string:id>', methods=['POST'])
def delete_patient(id):
    conn = get_db_connection()
    if not conn:
        return "Database connection failed", 500
    cursor = conn.cursor()
    try:
        # 获取病人姓名用于基于姓名的外键（例如处方表）
        cursor.execute(f"SELECT p_name FROM {T_PATIENT} WHERE p_atient_id = ?", (id,))
        res = cursor.fetchone()
        if not res:
            flash('病人不存在', 'danger')
            return redirect(url_for('patients'))
        p_name = res[0]

        # 1. 级联删除取药票单（通过 t_id 关联收费记录）
        # 在收费表中查找与该病人关联的所有 toll_id (t_id)
        cursor.execute(f"SELECT toll_id FROM {T_CHARGE} WHERE patient_id = ?", (id,))
        charges = cursor.fetchall()
        toll_ids = [row[0] for row in charges]
        
        if toll_ids:
            # 为 IN 子句创建参数化查询
            placeholders = ', '.join('?' * len(toll_ids))
            sql = f"DELETE FROM {T_PGM} WHERE t_id IN ({placeholders})"
            cursor.execute(sql, toll_ids)

        # 2. 级联删除支付记录
        cursor.execute(f"DELETE FROM {T_PAY} WHERE patient_id = ?", (id,))

        # 3. 级联删除收费记录
        cursor.execute(f"DELETE FROM {T_CHARGE} WHERE patient_id = ?", (id,))

        # 4. 处理处方（恢复库存 + 删除）
        # 按病人姓名查找处方（处方表使用病人姓名）
        cursor.execute(f"SELECT id FROM {T_RECIPEL} WHERE patient_name = ?", (p_name,))
        prescriptions = cursor.fetchall()
        
        for presc in prescriptions:
            presc_id = presc[0]
            # 恢复库存
            cursor.execute(f"SELECT drug_id, quantity FROM {T_PRESCRIPTION_DRUG} WHERE prescription_id = ?", (presc_id,))
            p_drugs = cursor.fetchall()
            for pd in p_drugs:
                cursor.execute(f"UPDATE {T_DRUGS} SET drug_quantity = drug_quantity + ? WHERE drug_id = ?", (pd[1], pd[0]))
            
            # 删除处方药品详情
            cursor.execute(f"DELETE FROM {T_PRESCRIPTION_DRUG} WHERE prescription_id = ?", (presc_id,))
        
        # 删除处方记录
        cursor.execute(f"DELETE FROM {T_RECIPEL} WHERE patient_name = ?", (p_name,))

        # 5. 删除挂号记录
        cursor.execute(f"DELETE FROM {T_REGISTER} WHERE r_patient_id = ?", (id,))

        # 6. 删除病人记录
        cursor.execute(f"DELETE FROM {T_PATIENT} WHERE p_atient_id = ?", (id,))

        conn.commit()
        flash('病人及所有关联记录（挂号、处方、收费、取药、支付）已删除成功！', 'success')
    except Exception as e:
        conn.rollback()
        flash(f'删除病人失败: {e}', 'danger')
    conn.close()
    return redirect(url_for('patients'))

@app.route('/patients/delete_medical_info/<string:id>', methods=['POST'])
def delete_patient_medical_info(id):
    """清除病人的病例信息"""
    conn = get_db_connection()
    if not conn:
        return "Database connection failed", 500
    cursor = conn.cursor()
    try:
        cursor.execute(f"UPDATE {T_PATIENT} SET p_inf = '' WHERE p_atient_id = ?", (id,))
        conn.commit()
        flash('病例信息已清除!', 'success')
    except Exception as e:
        flash(f'清除病例信息失败: {e}', 'danger')
    conn.close()
    return redirect(url_for('patients'))

@app.route('/patients/update_medical_info/<string:id>', methods=['POST'])
def update_patient_medical_info(id):
    """更新病人的病例信息"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'success': False, 'message': '数据库连接失败'}), 500
    cursor = conn.cursor()
    try:
        data = request.get_json()
        p_inf = data.get('p_inf', '')
        cursor.execute(f"UPDATE {T_PATIENT} SET p_inf = ? WHERE p_atient_id = ?", (p_inf, id))
        conn.commit()
        conn.close()
        return jsonify({'success': True, 'message': '病例信息更新成功'})
    except Exception as e:
        conn.close()
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/patients/edit', methods=['POST'])
def edit_patient_submit():
    """编辑病人信息"""
    conn = get_db_connection()
    if not conn:
        return "Database connection failed", 500
    cursor = conn.cursor()
    try:
        p_atient_id = request.form['p_atient_id']
        p_name = request.form['p_name']
        p_age = request.form['p_age']
        p_sex = request.form['p_sex']
        p_tel = request.form['p_tel']
        p_inf = request.form['p_inf']
        
        cursor.execute(f"""
            UPDATE {T_PATIENT} SET p_name = ?, p_age = ?, p_sex = ?, p_tel = ?, p_inf = ?, update_time = GETDATE()
            WHERE p_atient_id = ?
        """, (p_name, p_age, p_sex, p_tel, p_inf, p_atient_id))
        conn.commit()
        flash('病人信息更新成功！', 'success')
    except Exception as e:
        flash(f'更新失败: {e}', 'danger')
    conn.close()
    return redirect(url_for('patients'))

# 4. 药品管理
@app.route('/drugs', methods=['GET', 'POST'])
def drugs():
    conn = get_db_connection()
    if not conn:
        return "Database connection failed", 500
    cursor = conn.cursor()

    if request.method == 'POST':
        drug_id = request.form['drug_id']
        drug_name = request.form['drug_name']
        drug_price = request.form['drug_price']
        drug_quantity = request.form['drug_quantity']
        drug_storage = request.form['drug_storage']
        drug_date = request.form['drug_date']
        usefull_life = request.form['usefull_life']
        
        try:
            cursor.execute(f"INSERT INTO {T_DRUGS} (drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life) VALUES (?, ?, ?, ?, ?, ?, ?)",
                           (drug_id, drug_name, drug_price, drug_quantity, drug_storage, drug_date, usefull_life))
            conn.commit()
            flash('药品添加成功！', 'success')
        except Exception as e:
            flash(f'添加药品失败: {e}', 'danger')
        return redirect(url_for('drugs'))

    cursor.execute(f"""
        SELECT drug_id, drug_name, drug_price, drug_quantity, drug_storage, 
               CONVERT(VARCHAR, drug_date, 23) as drug_date, 
               CONVERT(VARCHAR, usefull_life, 23) as usefull_life,
               is_delete, create_time, update_time
        FROM {T_DRUGS} WHERE is_delete = 0
    """)
    drugs = cursor.fetchall()
    conn.close()
    return render_template('drugs.html', drugs=drugs)

@app.route('/drugs/delete/<string:id>', methods=['POST'])
def delete_drug(id):
    conn = get_db_connection()
    if not conn:
        return "Database connection failed", 500
    cursor = conn.cursor()
    try:
        cursor.execute(f"DELETE FROM {T_DRUGS} WHERE drug_id = ?", (id,))
        conn.commit()
        flash('药品删除成功！', 'success')
    except Exception as e:
        flash(f'删除失败: {e}', 'danger')
    conn.close()
    return redirect(url_for('drugs'))

@app.route('/drugs/edit', methods=['POST'])
def edit_drug_submit():
    """编辑药品信息"""
    conn = get_db_connection()
    if not conn:
        return "Database connection failed", 500
    cursor = conn.cursor()
    try:
        drug_id = request.form['drug_id']
        drug_name = request.form['drug_name']
        drug_price = request.form['drug_price']
        drug_quantity = request.form['drug_quantity']
        drug_storage = request.form['drug_storage']
        
        cursor.execute(f"""
            UPDATE {T_DRUGS} SET drug_name = ?, drug_price = ?, drug_quantity = ?, drug_storage = ?, update_time = GETDATE()
            WHERE drug_id = ?
        """, (drug_name, drug_price, drug_quantity, drug_storage, drug_id))
        conn.commit()
        flash('药品信息更新成功！', 'success')
    except Exception as e:
        flash(f'更新失败: {e}', 'danger')
    conn.close()
    return redirect(url_for('drugs'))

# 5. 收费管理
@app.route('/charges', methods=['GET'])
def charges():
    """收费管理 - 收费记录在开具处方时自动生成"""
    conn = get_db_connection()
    if not conn:
        return "Database connection failed", 500
    cursor = conn.cursor()

    # 获取收费列表（带详细信息）
    cursor.execute(f"""
        SELECT c.toll_id, c.t_name, c.patient_id, p.p_name, c.drug_id, d.drug_name, c.drug_quantity, c.amount, c.create_time
        FROM {T_CHARGE} c
        LEFT JOIN {T_PATIENT} p ON c.patient_id = p.p_atient_id
        LEFT JOIN {T_DRUGS} d ON c.drug_id = d.drug_id
        WHERE c.is_delete = 0
        ORDER BY c.create_time DESC
    """)
    charges = cursor.fetchall()
    
    conn.close()
    return render_template('charges.html', charges=charges)

# 6. 处方管理
@app.route('/prescriptions', methods=['GET', 'POST'])
def prescriptions():
    conn = get_db_connection()
    if not conn:
        return "Database connection failed", 500
    cursor = conn.cursor()

    if request.method == 'POST':
        # 从挂号信息获取医生和病人
        registration_id = request.form['registration_id']
        doctor_name = request.form['doctor_name']
        patient_name = request.form['patient_name']
        # 获取多个药品信息（数组）
        drug_ids = request.form.getlist('drug_ids[]')
        counts = request.form.getlist('counts[]')
        
        try:
            # 检查该挂号是否已有处方（同一挂号不能多次开具处方）
            cursor.execute(f"SELECT id FROM {T_RECIPEL} WHERE registration_id = ?", (registration_id,))
            existing_prescription = cursor.fetchone()
            if existing_prescription:
                flash(f'该挂号（编号: {registration_id}）已有处方，请先删除原有处方后再重新开具', 'danger')
                return redirect(url_for('prescriptions'))
            
            # 获取挂号信息中的医生ID (Using r_doctor_id from register table)
            cursor.execute(f"SELECT r_doctor_id FROM {T_REGISTER} WHERE r_num = ? AND is_delete = 0", (registration_id,))
            reg_result = cursor.fetchone()
            if not reg_result:
                 raise Exception(f'找不到挂号记录 {registration_id}')
            doctor_id = reg_result[0]

            # 获取最小可用的处方编号
            prescription_id = get_next_available_id(cursor, T_RECIPEL, 'id')
            
            # 插入处方主记录（包含挂号编号）
            cursor.execute(f"SET IDENTITY_INSERT {T_RECIPEL} ON")
            cursor.execute(f"INSERT INTO {T_RECIPEL} (id, doctor_id, patient_name, registration_id) VALUES (?, ?, ?, ?)",
                           (prescription_id, doctor_id, patient_name, registration_id))
            cursor.execute(f"SET IDENTITY_INSERT {T_RECIPEL} OFF")
            
            # 处理每个药品
            added_drugs = 0
            total_amount = 0
            for i, drug_id in enumerate(drug_ids):
                if drug_id and i < len(counts) and counts[i]:
                    quantity = int(counts[i])
                    
                    # 检查库存是否充足
                    cursor.execute(f"SELECT drug_quantity, drug_name, drug_price FROM {T_DRUGS} WHERE drug_id = ? AND is_delete = 0", (drug_id,))
                    stock_result = cursor.fetchone()
                    if not stock_result:
                        raise Exception(f'药品 {drug_id} 不存在')
                    current_stock = stock_result[0]
                    drug_name = stock_result[1]
                    drug_price = stock_result[2]
                    
                    if current_stock < quantity:
                        raise Exception(f'{drug_name} 库存不足！当前库存: {current_stock}, 需要: {quantity}')
                    
                    # 插入处方药品记录
                    cursor.execute(f"INSERT INTO {T_PRESCRIPTION_DRUG} (prescription_id, drug_id, quantity) VALUES (?, ?, ?)",
                                   (prescription_id, drug_id, quantity))
                    
                    # 扣减药品库存
                    cursor.execute(f"UPDATE {T_DRUGS} SET drug_quantity = drug_quantity - ? WHERE drug_id = ?",
                                   (quantity, drug_id))
                    
                    # 获取病人ID用于收费
                    cursor.execute(f"SELECT p_atient_id FROM {T_PATIENT} WHERE p_name = ? AND is_delete = 0", (patient_name,))
                    patient_result = cursor.fetchone()
                    patient_id = patient_result[0] if patient_result else patient_name
                    
                    # 自动生成收费记录
                    amount = quantity * drug_price
                    toll_id = str(prescription_id)  # 使用处方ID作为收费编号
                    cursor.execute(f"INSERT INTO {T_CHARGE} (toll_id, t_name, patient_id, drug_id, drug_quantity, amount) VALUES (?, ?, ?, ?, ?, ?)",
                                   (toll_id, '系统自动', patient_id, drug_id, quantity, amount))
                    
                    total_amount += amount
                    added_drugs += 1
            
            if added_drugs == 0:
                raise Exception('请至少添加一种药品')
            
            conn.commit()
            flash(f'处方开具成功！已添加 {added_drugs} 种药品，收费记录已自动生成，总金额: ￥{total_amount:.2f}', 'success')
        except Exception as e:
            conn.rollback()
            flash(f'处方添加失败: {e}', 'danger')
        return redirect(url_for('prescriptions'))

    # 获取处方列表（带医生和病人信息）
    cursor.execute(f"""
        SELECT r.id, r.doctor_id, d.d_name, r.patient_name, r.create_time
        FROM {T_RECIPEL} r
        LEFT JOIN {T_DOCTOR} d ON r.doctor_id = d.d_octor_id
        WHERE r.is_delete = 0
        ORDER BY r.create_time DESC
    """)
    prescription_list = cursor.fetchall()
    
    # 获取每个处方的药品信息
    prescriptions = []
    for prescription in prescription_list:
        prescription_id = prescription[0]
        cursor.execute(f"""
            SELECT pd.drug_id, dr.drug_name, pd.quantity, dr.drug_price
            FROM {T_PRESCRIPTION_DRUG} pd
            LEFT JOIN {T_DRUGS} dr ON pd.drug_id = dr.drug_id
            WHERE pd.prescription_id = ? AND pd.is_delete = 0
        """, (prescription_id,))
        drugs = cursor.fetchall()
        prescriptions.append((prescription, drugs))
    
    # 获取未开具处方的挂号列表
    # 排除条件：该挂号已关联处方（按registration_id），或者病人名字有旧处方（旧处方没有registration_id）
    cursor.execute(f"""
        SELECT r_num, r_patient_id, r_P_name, r_sex, r_dept, r_name 
        FROM {T_REGISTER} 
        WHERE is_delete = 0 
        AND r_num NOT IN (SELECT registration_id FROM {T_RECIPEL} WHERE registration_id IS NOT NULL)
        AND r_P_name NOT IN (SELECT patient_name FROM {T_RECIPEL} WHERE registration_id IS NULL)
        ORDER BY create_time DESC
    """)
    registrations = cursor.fetchall()
    
    # 获取药品列表（有库存的）
    cursor.execute(f"SELECT drug_id, drug_name, drug_price, drug_quantity FROM {T_DRUGS} WHERE is_delete = 0 AND drug_quantity > 0")
    drugs = cursor.fetchall()
    
    conn.close()
    return render_template('prescriptions.html', prescriptions=prescriptions, registrations=registrations, drugs=drugs)

@app.route('/prescriptions/delete/<int:id>', methods=['POST'])
def delete_prescription(id):
    """删除处方记录，恢复药品库存，级联删除处方药品记录"""
    conn = get_db_connection()
    if not conn:
        return "Database connection failed", 500
    cursor = conn.cursor()
    try:
        # 1. 查询处方中的药品信息，用于恢复库存
        cursor.execute(f"""
            SELECT drug_id, quantity 
            FROM {T_PRESCRIPTION_DRUG} 
            WHERE prescription_id = ?
        """, (id,))
        prescription_drugs = cursor.fetchall()
        
        # 2. 恢复药品库存
        for drug in prescription_drugs:
            drug_id = drug[0]
            quantity = drug[1]
            cursor.execute(f"UPDATE {T_DRUGS} SET drug_quantity = drug_quantity + ? WHERE drug_id = ?",
                          (quantity, drug_id))
        
        # 3. 删除关联的取药票单（如果有）
        cursor.execute(f"DELETE FROM {T_PGM} WHERE t_id = ?", (str(id),))

        # 4. 删除关联的支付记录（如果有）
        cursor.execute(f"DELETE FROM {T_PAY} WHERE t_id = ?", (str(id),))

        # 5. 删除关联的收费记录
        cursor.execute(f"DELETE FROM {T_CHARGE} WHERE toll_id = ?", (str(id),))
        
        # 6. 级联删除处方药品记录
        cursor.execute(f"DELETE FROM {T_PRESCRIPTION_DRUG} WHERE prescription_id = ?", (id,))
        
        # 7. 删除处方
        cursor.execute(f"DELETE FROM {T_RECIPEL} WHERE id = ?", (id,))
        
        conn.commit()
        flash('处方删除成功！药品库存已恢复', 'success')
    except Exception as e:
        conn.rollback()
        flash(f'处方删除失败: {e}', 'danger')
    conn.close()
    return redirect(url_for('prescriptions'))

# 7. 支付管理
@app.route('/payments', methods=['GET', 'POST'])
def payments():
    conn = get_db_connection()
    if not conn:
        return "Database connection failed", 500
    cursor = conn.cursor()

    if request.method == 'POST':
        patient_id = request.form['patient_id']
        t_id = request.form['t_id']
        price = request.form['price']
        
        try:
            # 插入支付记录
            cursor.execute(f"INSERT INTO {T_PAY} (patient_id, t_id, price) VALUES (?, ?, ?)",
                           (patient_id, t_id, price))
            
            # 自动生成取药票单
            cursor.execute(f"""
                SELECT drug_id, drug_quantity, amount
                FROM {T_CHARGE}
                WHERE patient_id = ? AND toll_id = ? AND is_delete = 0
            """, (patient_id, t_id))
            charge_items = cursor.fetchall()
            
            for item in charge_items:
                drug_id = item[0]
                quantity = item[1]
                amount = item[2]
                # 检查是否已存在取药票单
                cursor.execute(f"SELECT 1 FROM {T_PGM} WHERE t_id = ? AND drug_id = ?", (t_id, drug_id))
                if not cursor.fetchone():
                    cursor.execute(f"INSERT INTO {T_PGM} (t_id, drug_id, quantity, price) VALUES (?, ?, ?, ?)",
                                   (t_id, drug_id, quantity, amount))
            
            conn.commit()
            flash(f'支付成功！已自动生成取药票单（收费编号: {t_id}）', 'success')
        except Exception as e:
            conn.rollback()
            flash(f'支付失败: {e}', 'danger')
        return redirect(url_for('payments'))

    # 获取支付记录（带详细信息）
    cursor.execute(f"""
        SELECT p.patient_id, pt.p_name, p.t_id, p.price, p.create_time
        FROM {T_PAY} p
        LEFT JOIN {T_PATIENT} pt ON p.patient_id = pt.p_atient_id
        WHERE p.is_delete = 0
        ORDER BY p.create_time DESC
    """)
    payments = cursor.fetchall()
    
    # 获取未支付的收费记录（排除已支付且未删除的记录）
    cursor.execute(f"""
        SELECT c.toll_id, c.patient_id, p.p_name, SUM(c.amount) as total_amount
        FROM {T_CHARGE} c
        LEFT JOIN {T_PATIENT} p ON c.patient_id = p.p_atient_id
        WHERE c.is_delete = 0
        AND NOT EXISTS (SELECT 1 FROM {T_PAY} WHERE patient_id = c.patient_id AND t_id = c.toll_id AND is_delete = 0)
        GROUP BY c.toll_id, c.patient_id, p.p_name
        ORDER BY c.toll_id DESC
    """)
    unpaid_charges = cursor.fetchall()
    
    conn.close()
    return render_template('payments.html', payments=payments, unpaid_charges=unpaid_charges)

@app.route('/payments/delete/<string:patient_id>/<string:t_id>', methods=['POST'])
def delete_payment(patient_id, t_id):
    """删除支付记录，级联删除取药票单"""
    conn = get_db_connection()
    if not conn:
        return "Database connection failed", 500
    cursor = conn.cursor()
    try:
        # 级联删除取药票单
        cursor.execute(f"DELETE FROM {T_PGM} WHERE t_id = ?", (t_id,))
        # 删除支付记录
        cursor.execute(f"DELETE FROM {T_PAY} WHERE patient_id = ? AND t_id = ?", (patient_id, t_id))
        conn.commit()
        flash('支付记录及取药票单删除成功！', 'success')
    except Exception as e:
        conn.rollback()
        flash(f'支付记录删除失败: {e}', 'danger')
    conn.close()
    return redirect(url_for('payments'))

# 8. 取药管理
@app.route('/pickups', methods=['GET'])
def pickups():
    """取药票单管理 - 取药票单在支付完成后自动生成"""
    conn = get_db_connection()
    if not conn:
        return "Database connection failed", 500
    cursor = conn.cursor()

    cursor.execute(f"""
        SELECT t_id, drug_id, quantity, price, is_delete, 
               CONVERT(VARCHAR, create_time, 120) as create_time, update_time, is_picked 
        FROM {T_PGM} WHERE is_delete = 0 ORDER BY create_time DESC
    """)
    pickups = cursor.fetchall()
    conn.close()
    return render_template('pickups.html', pickups=pickups)

@app.route('/pickups/mark/<string:t_id>/<string:drug_id>', methods=['POST'])
def mark_pickup(t_id, drug_id):
    """标记取药票单为已取药"""
    conn = get_db_connection()
    if not conn:
        return "Database connection failed", 500
    cursor = conn.cursor()
    try:
        cursor.execute(f"UPDATE {T_PGM} SET is_picked = 1, update_time = GETDATE() WHERE t_id = ? AND drug_id = ?", (t_id, drug_id))
        conn.commit()
        flash('已成功标记为取药！', 'success')
    except Exception as e:
        flash(f'标记失败: {e}', 'danger')
    conn.close()
    return redirect(url_for('pickups'))

# 9. 数据统计
@app.route('/statistics')
def statistics():
    """数据统计分析页面"""
    conn = get_db_connection()
    if not conn:
        return "Database connection failed", 500
    cursor = conn.cursor()
    
    stats = {}
    
    try:
        # 基础统计
        cursor.execute(f"SELECT COUNT(*) FROM {T_PATIENT} WHERE is_delete = 0")
        stats['total_patients'] = cursor.fetchone()[0]
        
        cursor.execute(f"SELECT COUNT(*) FROM {T_DOCTOR} WHERE is_delete = 0 AND is_jobing = 1")
        stats['total_doctors'] = cursor.fetchone()[0]
        
        cursor.execute(f"SELECT COUNT(*) FROM {T_DRUGS} WHERE is_delete = 0")
        stats['total_drugs'] = cursor.fetchone()[0]
        
        # 挂号统计
        cursor.execute(f"SELECT COUNT(*) FROM {T_REGISTER} WHERE is_delete = 0")
        stats['total_registrations'] = cursor.fetchone()[0]
        
        cursor.execute(f"SELECT COUNT(*) FROM {T_REGISTER} WHERE is_delete = 0 AND CAST(create_time AS DATE) = CAST(GETDATE() AS DATE)")
        stats['today_registrations'] = cursor.fetchone()[0]
        
        cursor.execute(f"SELECT COUNT(*) FROM {T_REGISTER} WHERE is_delete = 0 AND create_time >= DATEADD(day, -7, GETDATE())")
        stats['week_registrations'] = cursor.fetchone()[0]
        
        cursor.execute(f"SELECT COUNT(*) FROM {T_REGISTER} WHERE is_delete = 0 AND MONTH(create_time) = MONTH(GETDATE()) AND YEAR(create_time) = YEAR(GETDATE())")
        stats['month_registrations'] = cursor.fetchone()[0]
        
        # 处方统计
        cursor.execute(f"SELECT COUNT(*) FROM {T_RECIPEL} WHERE is_delete = 0")
        stats['total_prescriptions'] = cursor.fetchone()[0]
        
        cursor.execute(f"SELECT COUNT(*) FROM {T_RECIPEL} WHERE is_delete = 0 AND CAST(create_time AS DATE) = CAST(GETDATE() AS DATE)")
        stats['today_prescriptions'] = cursor.fetchone()[0]
        
        cursor.execute(f"SELECT COUNT(*) FROM {T_RECIPEL} WHERE is_delete = 0 AND create_time >= DATEADD(day, -7, GETDATE())")
        stats['week_prescriptions'] = cursor.fetchone()[0]
        
        cursor.execute(f"SELECT COUNT(*) FROM {T_RECIPEL} WHERE is_delete = 0 AND MONTH(create_time) = MONTH(GETDATE()) AND YEAR(create_time) = YEAR(GETDATE())")
        stats['month_prescriptions'] = cursor.fetchone()[0]
        
        # 收入统计
        cursor.execute(f"SELECT ISNULL(SUM(price), 0) FROM {T_PAY} WHERE is_delete = 0")
        stats['total_revenue'] = cursor.fetchone()[0] or 0
        
        cursor.execute(f"SELECT ISNULL(SUM(price), 0) FROM {T_PAY} WHERE is_delete = 0 AND CAST(create_time AS DATE) = CAST(GETDATE() AS DATE)")
        stats['today_revenue'] = cursor.fetchone()[0] or 0
        
        cursor.execute(f"SELECT ISNULL(SUM(price), 0) FROM {T_PAY} WHERE is_delete = 0 AND create_time >= DATEADD(day, -7, GETDATE())")
        stats['week_revenue'] = cursor.fetchone()[0] or 0
        
        cursor.execute(f"SELECT ISNULL(SUM(price), 0) FROM {T_PAY} WHERE is_delete = 0 AND MONTH(create_time) = MONTH(GETDATE()) AND YEAR(create_time) = YEAR(GETDATE())")
        stats['month_revenue'] = cursor.fetchone()[0] or 0
        
        # 取药统计
        cursor.execute(f"SELECT COUNT(*) FROM {T_PGM} WHERE is_delete = 0")
        stats['total_pickups'] = cursor.fetchone()[0] or 0
        
        cursor.execute(f"SELECT COUNT(*) FROM {T_PGM} WHERE is_delete = 0 AND is_picked = 1")
        stats['completed_pickups'] = cursor.fetchone()[0] or 0
        
        cursor.execute(f"SELECT COUNT(*) FROM {T_PGM} WHERE is_delete = 0 AND (is_picked = 0 OR is_picked IS NULL)")
        stats['pending_pickups'] = cursor.fetchone()[0] or 0
        
        # 取药完成率
        stats['pickup_rate'] = (stats['completed_pickups'] * 100.0 / stats['total_pickups']) if stats['total_pickups'] > 0 else 0
        
        # 待处理事项统计
        cursor.execute(f"""
            SELECT COUNT(*) FROM {T_REGISTER} 
            WHERE is_delete = 0 
            AND r_num NOT IN (SELECT registration_id FROM {T_RECIPEL} WHERE registration_id IS NOT NULL)
            AND r_P_name NOT IN (SELECT patient_name FROM {T_RECIPEL} WHERE registration_id IS NULL)
        """)
        stats['pending_prescriptions'] = cursor.fetchone()[0] or 0
        
        cursor.execute(f"""
            SELECT COUNT(DISTINCT c.toll_id) FROM {T_CHARGE} c
            WHERE c.is_delete = 0
            AND NOT EXISTS (SELECT 1 FROM {T_PAY} WHERE patient_id = c.patient_id AND t_id = c.toll_id AND is_delete = 0)
        """)
        stats['pending_payments'] = cursor.fetchone()[0] or 0
        
        # 库存预警（低于10个）
        cursor.execute(f"SELECT drug_id, drug_name, drug_quantity FROM {T_DRUGS} WHERE is_delete = 0 AND drug_quantity < 10 ORDER BY drug_quantity ASC")
        low_stock_drugs = cursor.fetchall()
        
        # 科室统计
        cursor.execute(f"""
            SELECT r_dept, COUNT(*) as count 
            FROM {T_REGISTER} 
            WHERE is_delete = 0 
            GROUP BY r_dept 
            ORDER BY count DESC
        """)
        dept_data = cursor.fetchall()
        total_dept = sum(d[1] for d in dept_data) if dept_data else 1
        dept_stats = [(d[0], d[1], d[1] * 100.0 / total_dept) for d in dept_data]
        
        # 医生工作量排行（Top 10）
        cursor.execute(f"""
            SELECT d.d_name, d.d_dept, 
                   (SELECT COUNT(*) FROM {T_RECIPEL} r WHERE r.doctor_id = d.d_octor_id AND r.is_delete = 0) as prescription_count,
                   (SELECT COUNT(*) FROM {T_REGISTER} reg WHERE reg.r_name = d.d_name AND reg.is_delete = 0) as registration_count
            FROM {T_DOCTOR} d
            WHERE d.is_delete = 0 AND d.is_jobing = 1
            ORDER BY prescription_count DESC, registration_count DESC
        """)
        doctor_stats = cursor.fetchall()[:10]
        
        # 热门药品排行（Top 10）
        cursor.execute(f"""
            SELECT dr.drug_name, 
                   COUNT(pd.drug_id) as times,
                   SUM(pd.quantity) as total_quantity,
                   dr.drug_price,
                   SUM(pd.quantity * dr.drug_price) as total_amount
            FROM {T_PRESCRIPTION_DRUG} pd
            JOIN {T_DRUGS} dr ON pd.drug_id = dr.drug_id
            WHERE pd.is_delete = 0
            GROUP BY pd.drug_id, dr.drug_name, dr.drug_price
            ORDER BY times DESC, total_quantity DESC
        """)
        popular_drugs = cursor.fetchall()[:10]
        
    except Exception as e:
        conn.close()
        return f"统计数据查询失败: {e}", 500
    
    conn.close()
    return render_template('analysis.html', 
                           stats=stats, 
                           low_stock_drugs=low_stock_drugs,
                           dept_stats=dept_stats,
                           doctor_stats=doctor_stats,
                           popular_drugs=popular_drugs)

if __name__ == '__main__':
    app.run(debug=True)

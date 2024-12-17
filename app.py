import MySQLdb
from flask import Flask, request, jsonify
from flask_mysqldb import MySQL
from flask_cors import CORS
from datetime import datetime

app = Flask(__name__)
CORS(app)  # Enable CORS for cross-origin requests

# MySQL Configuration
app.config['MYSQL_HOST'] = '127.0.0.1'
app.config['MYSQL_PORT'] = 3306
app.config['MYSQL_USER'] = 'root'
app.config['MYSQL_PASSWORD'] = ''  # Update with your MySQL root password
app.config['MYSQL_DB'] = 'sample_cdr'

mysql = MySQL(app)

# Login API
@app.route('/login', methods=['POST'])
def login():
    data = request.json
    email = data['email']
    password = data['password']

    # Check credentials in the database
    cursor = mysql.connection.cursor()
    cursor.execute('SELECT * FROM users WHERE email = %s AND password = %s', (email, password))
    account = cursor.fetchone()
    cursor.close()

    if account:
        role = account[3]
        return jsonify({
            'status': 'success',
            'message': 'Login successful',
            'role': role,
            'user_id': account[0]
        })
    else:
        return jsonify({'status': 'failure', 'message': 'Invalid credentials'}), 401

# Create Requisition API
@app.route('/requisitions/create', methods=['POST'])
def create_requisition():
    data = request.json
    site_id = data.get('site_id')
    req_type = data.get('type', 'Plant/Tools')
    status = data.get('status', 'Pending')
    created_by = data.get('created_by')
    tools_required = data.get('toolsRequired', [])
    consumables_required = data.get('consumablesRequired', [])

    if not all([site_id, created_by]):
        return jsonify({'status': 'failure', 'message': 'Missing required fields'}), 400

    try:
        cursor = mysql.connection.cursor()

        # Insert into requisitions
        cursor.execute('''
            INSERT INTO requisitions (site_id, type, status, created_by, created_at, form_no, request_no, date_of_request)
            VALUES (%s, %s, %s, %s, NOW(), %s, %s, %s)
        ''', (site_id, req_type, status, created_by, 'FORM123', 'REQ123', datetime.now().strftime('%Y-%m-%d')))
        requisition_id = cursor.lastrowid  # Get inserted requisition ID

        # Insert tools
        for tool in tools_required:
            cursor.execute('''
                INSERT INTO plant_tools (requisition_id, name, quantity, date_required, duration)
                VALUES (%s, %s, %s, %s, %s)
            ''', (requisition_id, tool['name'], tool['quantity'], tool['dateRequired'], tool['duration']))

        # Insert consumables
        for consumable in consumables_required:
            cursor.execute('''
                INSERT INTO consumables (requisition_id, name, quantity, date_required)
                VALUES (%s, %s, %s, %s)
            ''', (requisition_id, consumable['name'], consumable['quantity'], consumable['dateRequired']))

        mysql.connection.commit()
        cursor.close()

        return jsonify({'status': 'success', 'message': 'Requisition created successfully'}), 201

    except Exception as e:
        mysql.connection.rollback()
        return jsonify({'status': 'failure', 'message': str(e)}), 500

# Fetch All Requisitions API
@app.route('/requisitions', methods=['GET'])
def get_requisitions():
    cursor = mysql.connection.cursor(MySQLdb.cursors.DictCursor)
    cursor.execute('SELECT id, site_id, type, status, created_by, created_at, form_no, request_no, date_of_request FROM requisitions')
    requisitions = cursor.fetchall()
    cursor.close()

    return jsonify({'status': 'success', 'data': requisitions}), 200

# Fetch Requisition Details API
@app.route('/requisitions/<int:requisition_id>', methods=['GET'])
def get_requisition_details(requisition_id):
    try:
        cursor = mysql.connection.cursor(MySQLdb.cursors.DictCursor)
        
        # Fetch requisition details
        cursor.execute('''
            SELECT r.id, r.site_id, r.type, r.status, r.created_by, r.created_at, r.form_no, r.request_no, r.date_of_request
            FROM requisitions r
            WHERE r.id = %s
        ''', (requisition_id,))
        requisition = cursor.fetchone()
        
        if not requisition:
            return jsonify({'status': 'failure', 'message': 'Requisition not found'}), 404
        
        # Fetch tools required
        cursor.execute('''
            SELECT id, name, quantity, date_required, duration
            FROM plant_tools
            WHERE requisition_id = %s
        ''', (requisition_id,))
        tools_required = cursor.fetchall()
        
        # Fetch consumables required
        cursor.execute('''
            SELECT id, name, quantity, date_required
            FROM consumables
            WHERE requisition_id = %s
        ''', (requisition_id,))
        consumables_required = cursor.fetchall()
        
        cursor.close()
        
        requisition['toolsRequired'] = tools_required
        requisition['consumablesRequired'] = consumables_required
        
        return jsonify({'status': 'success', 'data': requisition}), 200
    
    except Exception as e:
        return jsonify({'status': 'failure', 'message': str(e)}), 500

# Approve Requisition API
@app.route('/requisitions/approve', methods=['POST'])
def approve_requisition():
    data = request.json
    requisition_id = data.get('requisition_id')
    approved_by = data.get('approved_by')

    if not requisition_id or not approved_by:
        return jsonify({'status': 'failure', 'message': 'Missing required fields'}), 400

    try:
        cursor = mysql.connection.cursor()
        cursor.execute('''
            UPDATE requisitions
            SET status = 'Approved', approved_by = %s, approved_at = NOW()
            WHERE id = %s
        ''', (approved_by, requisition_id))
        mysql.connection.commit()
        cursor.close()

        return jsonify({'status': 'success', 'message': 'Requisition approved successfully'}), 200

    except Exception as e:
        mysql.connection.rollback()
        return jsonify({'status': 'failure', 'message': str(e)}), 500

# Reject Requisition API
@app.route('/requisitions/reject', methods=['POST'])
def reject_requisition():
    data = request.json
    requisition_id = data.get('requisition_id')
    rejected_by = data.get('rejected_by')

    if not requisition_id or not rejected_by:
        return jsonify({'status': 'failure', 'message': 'Missing required fields'}), 400

    try:
        cursor = mysql.connection.cursor()
        cursor.execute('''
            UPDATE requisitions
            SET status = 'Rejected', approved_by = %s, approved_at = NOW()
            WHERE id = %s
        ''', (rejected_by, requisition_id))
        mysql.connection.commit()
        cursor.close()

        return jsonify({'status': 'success', 'message': 'Requisition rejected successfully'}), 200

    except Exception as e:
        mysql.connection.rollback()
        return jsonify({'status': 'failure', 'message': str(e)}), 500

# Edit Requisition API
@app.route('/requisitions/edit', methods=['POST'])
def edit_requisition():
    data = request.json
    requisition_id = data.get('requisition_id')
    site_id = data.get('site_id')
    req_type = data.get('type')
    status = data.get('status')
    tools_required = data.get('toolsRequired', [])
    consumables_required = data.get('consumablesRequired', [])

    if not requisition_id:
        return jsonify({'status': 'failure', 'message': 'Missing requisition ID'}), 400

    try:
        cursor = mysql.connection.cursor()

        # Check if requisition exists
        cursor.execute('SELECT id FROM requisitions WHERE id = %s', (requisition_id,))
        if cursor.rowcount == 0:
            return jsonify({'status': 'failure', 'message': 'Requisition not found'}), 404

        # Update requisition
        cursor.execute('''
            UPDATE requisitions
            SET site_id = %s, type = %s, status = %s, updated_at = NOW()
            WHERE id = %s
        ''', (site_id, req_type, status, requisition_id))

        # Delete existing tools and consumables
        cursor.execute('DELETE FROM plant_tools WHERE requisition_id = %s', (requisition_id,))
        cursor.execute('DELETE FROM consumables WHERE requisition_id = %s', (requisition_id,))

        # Insert updated tools
        for tool in tools_required:
            cursor.execute('''
                INSERT INTO plant_tools (requisition_id, name, quantity, date_required, duration)
                VALUES (%s, %s, %s, %s, %s)
            ''', (requisition_id, tool['name'], tool['quantity'], tool['dateRequired'], tool['duration']))

        # Insert updated consumables
        for consumable in consumables_required:
            cursor.execute('''
                INSERT INTO consumables (requisition_id, name, quantity, date_required)
                VALUES (%s, %s, %s, %s)
            ''', (requisition_id, consumable['name'], consumable['quantity'], consumable['dateRequired']))

        mysql.connection.commit()
        cursor.close()

        return jsonify({'status': 'success', 'message': 'Requisition updated successfully'}), 200

    except Exception as e:
        mysql.connection.rollback()
        return jsonify({'status': 'failure', 'message': str(e)}), 500

# Fetch Deliveries API
@app.route('/deliveries', methods=['GET'])
def get_deliveries():
    role = request.args.get('role')
    user_id = request.args.get('user_id')

    if not role or not user_id:
        return jsonify({'status': 'failure', 'message': 'Missing required parameters'}), 400

    try:
        cursor = mysql.connection.cursor(MySQLdb.cursors.DictCursor)

        if role == 'delivery':
            cursor.execute('''
                SELECT d.id, d.requisition_id, d.delivery_address, d.delivery_status, d.created_at
                FROM deliveries d
                WHERE d.delivery_person_id = %s
            ''', (user_id,))
        else:
            return jsonify({'status': 'failure', 'message': 'Invalid role'}), 400

        deliveries = cursor.fetchall()
        cursor.close()

        return jsonify({'status': 'success', 'data': deliveries}), 200

    except Exception as e:
        return jsonify({'status': 'failure', 'message': str(e)}), 500

# Accept Item API
@app.route('/requisitions/accept_item', methods=['POST'])
def accept_item():
    data = request.json
    requisition_id = data.get('requisition_id')
    item_id = data.get('item_id')
    item_type = data.get('item_type')
    notes = data.get('notes')

    if not all([requisition_id, item_id, item_type, notes]):
        return jsonify({'status': 'failure', 'message': 'Missing required fields'}), 400

    try:
        cursor = mysql.connection.cursor()
        cursor.execute('''
            INSERT INTO accepted_items (requisition_id, item_id, item_type, notes, accepted_at)
            VALUES (%s, %s, %s, %s, NOW())
        ''', (requisition_id, item_id, item_type, notes))
        mysql.connection.commit()
        cursor.close()

        return jsonify({'status': 'success', 'message': 'Item accepted successfully'}), 201

    except Exception as e:
        mysql.connection.rollback()
        return jsonify({'status': 'failure', 'message': str(e)}), 500
    


    

# Reject Item API
@app.route('/requisitions/reject_item', methods=['POST'])
def reject_item():
    data = request.json
    requisition_id = data.get('requisition_id')
    item_id = data.get('item_id')
    item_type = data.get('item_type')
    notes = data.get('notes')

    if not all([requisition_id, item_id, item_type, notes]):
        return jsonify({'status': 'failure', 'message': 'Missing required fields'}), 400

    try:
        cursor = mysql.connection.cursor()
        cursor.execute('''
            INSERT INTO accepted_items (requisition_id, item_id, item_type, notes, accepted_at)
            VALUES (%s, %s, %s, %s, NOW())
        ''', (requisition_id, item_id, item_type, notes))
        mysql.connection.commit()
        cursor.close()

        return jsonify({'status': 'success', 'message': 'Item rejected successfully'}), 201

    except Exception as e:
        mysql.connection.rollback()
        return jsonify({'status': 'failure', 'message': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True)
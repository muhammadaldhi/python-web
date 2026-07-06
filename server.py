import os
import json
from flask import Flask, jsonify, request, render_template, send_file, make_response, flash

app = Flask(__name__)
app.secret_key = "NETRUNNER_SECRET_KEY_MATRIX" # Diperlukan untuk flash message pipeline

CONFIG_DIR = "saved_settings"
if not os.path.exists(CONFIG_DIR):
    os.makedirs(CONFIG_DIR)

ACTIVE_CONFIG_PATH = os.path.join(CONFIG_DIR, "active_settings.json")

# Database internal default (Syarat Avg Trailing Aktif SUDAH DIAPUS)
default_settings = {
    "InpLots": 0.01,
    "InpMaxOpenPositions": 1,
    "InpMinDistanceEntries": 1500,
    "InpMaxAllowedSpread": 500,
    "InpATRPeriod": 21,
    "InpATREntry": 3.5,
    "InmSinyalTren": 5.0,
    "InpAktifFilterGaris": True,  
    "InpEmergencyStop": False,
    "InpUseMartingale": False,
    "InpMartingaleMultiplier": 1.0,
    "InpMaxMartingaleLots": 0.01,
    "InpMartingaleTriggerPoints": 250,
    "InpSL": 300,
    "InpMaxLossCurrency": 25.0,        
    "InpAktifTrailing": True,
    "InpJarakTrailing": 40,
    "InpTrailingAktif": 80,
    "InpAktifAvgTrailing": True,       
    "InpJarakAvgTrailing": 50,         
    "InpMartingaleBEProfit": 1.00,    # PARAMETER BREAK EVEN MARTINGALE ($)        
    "InpAktifTPPartial": False,
    "InpJarakTPPartial": 150,
    "InpTargetProfitMataUang": 100.0   
}

dashboard_data = {
    "balance": 0.00,
    "equity": 0.00,
    "free_margin": 0.00,
    "profit": 0.00,
    "layers": 0,
    "pair_tf": "-- [--]",
    "signal": "WAITING_EA..."
}

if os.path.exists(ACTIVE_CONFIG_PATH):
    try:
        with open(ACTIVE_CONFIG_PATH, 'r') as f:
            ea_settings = json.load(f)
            if "InpAvgTrailingAktif" in ea_settings:
                del ea_settings["InpAvgTrailingAktif"]
            for key, val in default_settings.items():
                if key not in ea_settings:
                    ea_settings[key] = val
    except:
        ea_settings = default_settings.copy()
else:
    ea_settings = default_settings.copy()

def parse_and_save_json(data_dict):
    global ea_settings
    if "InpAvgTrailingAktif" in data_dict:
        del data_dict["InpAvgTrailingAktif"]
        
    for key in ea_settings.keys():
        if key in data_dict:
            if isinstance(ea_settings[key], bool):
                if isinstance(data_dict[key], str):
                    ea_settings[key] = data_dict[key].lower() == 'true'
                else:
                    ea_settings[key] = bool(data_dict[key])
            elif isinstance(ea_settings[key], int):
                ea_settings[key] = int(data_dict[key])
            elif isinstance(ea_settings[key], float):
                ea_settings[key] = float(data_dict[key])
            else:
                ea_settings[key] = data_dict[key]
                
    with open(ACTIVE_CONFIG_PATH, 'w') as f:
        json.dump(ea_settings, f, indent=4)

@app.route('/')
def index():
    response = make_response(render_template('cyberpunk_ui.html', settings=ea_settings, telemetry=dashboard_data))
    response.headers['Cache-Control'] = 'no-store, no-cache, must-revalidate, max-age=0'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = '0'
    return response

@app.route('/update', methods=['POST'])
def update():
    global ea_settings
    ea_settings['InpLots'] = float(request.form['InpLots'])
    ea_settings['InpMaxOpenPositions'] = int(request.form['InpMaxOpenPositions'])
    ea_settings['InpMinDistanceEntries'] = int(request.form['InpMinDistanceEntries'])
    ea_settings['InpMaxAllowedSpread'] = int(request.form['InpMaxAllowedSpread']) 
    ea_settings['InpATRPeriod'] = int(request.form['InpATRPeriod'])
    ea_settings['InpATREntry'] = float(request.form['InpATREntry'])
    ea_settings['InmSinyalTren'] = float(request.form['InmSinyalTren'])
    ea_settings['InpAktifFilterGaris'] = request.form['InpAktifFilterGaris'] == 'true'  
    ea_settings['InpUseMartingale'] = request.form['InpUseMartingale'] == 'true'
    ea_settings['InpMartingaleMultiplier'] = float(request.form['InpMartingaleMultiplier'])
    ea_settings['InpMaxMartingaleLots'] = float(request.form['InpMaxMartingaleLots'])
    ea_settings['InpMartingaleTriggerPoints'] = int(request.form['InpMartingaleTriggerPoints'])
    ea_settings['InpSL'] = int(request.form['InpSL'])
    ea_settings['InpMaxLossCurrency'] = float(request.form['InpMaxLossCurrency'])
    ea_settings['InpAktifTrailing'] = request.form['InpAktifTrailing'] == 'true'
    ea_settings['InpJarakTrailing'] = int(request.form['InpJarakTrailing'])
    ea_settings['InpTrailingAktif'] = int(request.form['InpTrailingAktif'])
    ea_settings['InpAktifAvgTrailing'] = request.form['InpAktifAvgTrailing'] == 'true'
    ea_settings['InpJarakAvgTrailing'] = int(request.form['InpJarakAvgTrailing'])
    ea_settings['InpMartingaleBEProfit'] = float(request.form['InpMartingaleBEProfit'])  
    ea_settings['InpAktifTPPartial'] = request.form['InpAktifTPPartial'] == 'true'
    ea_settings['InpJarakTPPartial'] = int(request.form['InpJarakTPPartial'])
    ea_settings['InpTargetProfitMataUang'] = float(request.form['InpTargetProfitMataUang'])
    
    with open(ACTIVE_CONFIG_PATH, 'w') as f:
        json.dump(ea_settings, f, indent=4)
        
    return jsonify({"status": "success", "message": "MATRIX OVERWRITE SUCCESSFUL!"}), 200

@app.route('/api/update_dashboard', methods=['POST'])
def update_dashboard():
    global dashboard_data
    data = request.json
    if not data:
        try:
            raw_text = request.get_data(as_text=True)
            data = json.loads(raw_text)
        except Exception as e:
            data = None
            
    if data:
        dashboard_data['balance'] = data.get('balance', 0.0)
        dashboard_data['equity'] = data.get('equity', 0.0)
        dashboard_data['free_margin'] = data.get('free_margin', 0.0)
        dashboard_data['profit'] = data.get('profit', 0.0)
        dashboard_data['layers'] = data.get('layers', 0)
        dashboard_data['pair_tf'] = data.get('pair_tf', '-- [--]')
        dashboard_data['signal'] = data.get('signal', 'WAIT...')
        return jsonify({"status": "success"}), 200
        
    return jsonify({"status": "corrupted_string_received"}), 200

@app.route('/api/live_telemetry_data', methods=['GET'])
def live_telemetry_data():
    return jsonify(dashboard_data), 200

@app.route('/emergency_stop', methods=['POST'])
def emergency_stop():
    global ea_settings
    ea_settings['InpEmergencyStop'] = True
    with open(ACTIVE_CONFIG_PATH, 'w') as f:
        json.dump(ea_settings, f, indent=4)
    flash("🚨 EMERGENCY SHUTDOWN MATRIX ACTIVE!")
    return make_response("<script>window.location.href='/';</script>")

@app.route('/emergency_reset', methods=['POST'])
def emergency_reset():
    global ea_settings
    ea_settings['InpEmergencyStop'] = False
    with open(ACTIVE_CONFIG_PATH, 'w') as f:
        json.dump(ea_settings, f, indent=4)
    flash("System Normalized. Emergency state cleared.")
    return make_response("<script>window.location.href='/';</script>")

@app.route('/api/get_settings', methods=['GET'])
def get_settings():
    return jsonify(ea_settings), 200

@app.route('/download_config', methods=['GET'])
def download_config():
    filename = request.args.get('filename', 'cyberpunk_config').strip()
    if not filename:
        filename = "cyberpunk_config"
    file_path = os.path.join(CONFIG_DIR, f"{filename}.json")
    with open(file_path, 'w') as f:
        json.dump(ea_settings, f, indent=4)
    return send_file(file_path, as_attachment=True)

# --- FUNGSI BARU UNTUK LIST & ARSIP CONFIG STORAGE MANAGEMENT ---

@app.route('/api/list_configs', methods=['GET'])
def list_configs():
    try:
        files = [f for f in os.listdir(CONFIG_DIR) if f.endswith('.json') and f != "active_settings.json"]
        return jsonify(files), 200
    except Exception as e:
        return jsonify([]), 500

@app.route('/api/get_config_file', methods=['GET'])
def get_config_file():
    filename = request.args.get('filename', '')
    safe_path = os.path.join(CONFIG_DIR, filename)
    if os.path.exists(safe_path) and filename.endswith('.json'):
        with open(safe_path, 'r') as f:
            return jsonify(json.load(f)), 200
    return jsonify({"error": "File not found"}), 404

@app.route('/api/delete_config', methods=['DELETE'])
def delete_config():
    filename = request.args.get('filename', '')
    safe_path = os.path.join(CONFIG_DIR, filename)
    if os.path.exists(safe_path) and filename.endswith('.json') and filename != "active_settings.json":
        os.remove(safe_path)
        return jsonify({"status": "success", "message": f"Arsip {filename} berhasil didelete!"}), 200
    return jsonify({"status": "error", "message": "File gagal dihapus atau tidak valid."}), 400

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True, threaded=True)

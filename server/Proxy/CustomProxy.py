from flask import Flask, request, jsonify
import mysql.connector
import subprocess
import json
import time

app = Flask(__name__)

# Dynamically fetch manager and worker IPs
def get_instance_ips():
    result = subprocess.run(
        ["terraform", "output", "-json"],
        capture_output=True,
        text=True
    )
    outputs = json.loads(result.stdout)
    manager_ip = outputs["manager_private_ip"]["value"]
    worker_ips = outputs["worker_private_ips"]["value"]
    return manager_ip, worker_ips

manager_ip, worker_ips = get_instance_ips()
manager_config = {"host": manager_ip, "user": "root", "password": "", "database": "sakila"}
worker_configs = [{"host": ip, "user": "root", "password": "", "database": "sakila"} for ip in worker_ips]

@app.route('/custom', methods=['POST'])
def custom_proxy():
    query = request.json.get("query")
    query_type = request.json.get("type")  # read or write

    def benchmark(config):
        conn = mysql.connector.connect(**config)
        cursor = conn.cursor()
        start_time = time.time()
        cursor.execute("SELECT 1;")
        cursor.fetchall()
        latency = time.time() - start_time
        conn.close()
        return latency

    if query_type == "read":
        all_configs = [manager_config] + worker_configs
        fastest_config = min(all_configs, key=benchmark)
        conn = mysql.connector.connect(**fastest_config)
    elif query_type == "write":
        conn = mysql.connector.connect(**manager_config)
    else:
        return jsonify({"error": "Invalid query type"}), 400

    cursor = conn.cursor()
    cursor.execute(query)
    result = cursor.fetchall()
    conn.commit()
    conn.close()
    return jsonify({"result": result})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5002)

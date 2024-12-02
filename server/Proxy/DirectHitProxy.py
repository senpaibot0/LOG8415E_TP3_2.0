from flask import Flask, request, jsonify
import mysql.connector
import subprocess
import json

app = Flask(__name__)

# Dynamically fetch the manager IP
def get_manager_ip():
    result = subprocess.run(
        ["terraform", "output", "-json"],
        capture_output=True,
        text=True
    )
    outputs = json.loads(result.stdout)
    return outputs["manager_private_ip"]["value"]

manager_ip = get_manager_ip()
manager_config = {"host": manager_ip, "user": "root", "password": "", "database": "sakila"}

@app.route('/direct_hit', methods=['POST'])
def direct_hit():
    query = request.json.get("query")
    conn = mysql.connector.connect(**manager_config)
    cursor = conn.cursor()
    cursor.execute(query)
    result = cursor.fetchall()
    conn.commit()
    conn.close()
    return jsonify({"result": result})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)

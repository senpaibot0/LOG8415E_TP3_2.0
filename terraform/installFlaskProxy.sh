#!/bin/bash

set -e

# Read arguments
MANAGER_IP=$1
WORKER_IPS=("${@:2}")

# Update the package list
echo "Updating package list..."
sudo apt-get update 
sudo apt update

# Install Python and pip
echo "Installing Python, pip, and venv..."
sudo apt-get install -y python3-pip python3-venv

# Create a virtual environment for Flask
if [ ! -d "/opt/proxy_env" ]; then
    echo "Creating a Python virtual environment..."
    sudo python3 -m venv /opt/proxy_env
fi

# Activate the virtual environment and install dependencies
echo "Installing Flask and Requests..."
source /opt/proxy_env/bin/activate
pip install --upgrade pip
pip install flask requests
deactivate

# Create a directory for the proxy app
echo "Setting up the proxy application directory..."
sudo mkdir -p /opt/proxy_app
sudo chown ubuntu:ubuntu /opt/proxy_app

# Generate the WORKERS_URLS list dynamically
WORKERS_URLS=$(printf ",\n" "${WORKER_IPS[@]/#/    \"http://}")
WORKERS_URLS=${WORKERS_URLS%,\n} 

# Create the proxy Flask application
echo "Creating the proxy Flask application..."
cat <<EOF | sudo tee /opt/proxy_app/proxy.py > /dev/null
from flask import Flask, request, jsonify
import requests
import random
import time

app = Flask(__name__)

# Backend URLs
MANAGER_URL = "http://${MANAGER_IP}:5000"
WORKERS_URLS = [
${WORKERS_URLS}
]

# Routing strategies
ROUTING_STRATEGY = "random"  # Options: "direct", "random", "fastest"

@app.route('/route', methods=['POST'])
def proxy():
    data = request.json
    if not data or "operation" not in data:
        return jsonify({"error": "Invalid request"}), 400

    # Determine operation type (read or write)
    operation = data["operation"].lower()

    try:
        if ROUTING_STRATEGY == "direct":
            if operation in ["read", "write"]:
                response = forward_request(MANAGER_URL, data)
                return response
        elif ROUTING_STRATEGY == "random":
            if operation == "write":
                response = forward_request(MANAGER_URL, data)
            elif operation == "read":
                worker_url = random.choice(WORKERS_URLS)
                response = forward_request(worker_url, data)
            else:
                return jsonify({"error": "Unknown operation"}), 400
            return response
        elif ROUTING_STRATEGY == "fastest":
            if operation == "write":
                response = forward_request(MANAGER_URL, data)
            elif operation == "read":
                fastest_worker = get_fastest_worker()
                response = forward_request(fastest_worker, data)
            else:
                return jsonify({"error": "Unknown operation"}), 400
            return response
        else:
            return jsonify({"error": "Invalid routing strategy"}), 400
    except requests.exceptions.RequestException as e:
        return jsonify({"error": "Failed to route request", "details": str(e)}), 500


def forward_request(url, data):
    try:
        response = requests.post(url, json=data)
        return jsonify(response.json()), response.status_code
    except requests.exceptions.RequestException as e:
        return jsonify({"error": f"Failed to reach {url}", "details": str(e)}), 500


def get_fastest_worker():
    ping_times = {}
    for worker_url in WORKERS_URLS:
        start = time.time()
        try:
            requests.get(worker_url, timeout=2)
            ping_times[worker_url] = time.time() - start
        except requests.exceptions.RequestException:
            ping_times[worker_url] = float('inf')
    fastest_worker = min(ping_times, key=ping_times.get)
    print(f"Fastest worker selected: {fastest_worker} with ping {ping_times[fastest_worker]} seconds")
    return fastest_worker


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

# Configure the proxy app to run as a systemd service
echo "Configuring the proxy Flask application as a systemd service..."
cat <<EOF | sudo tee /etc/systemd/system/proxy_app.service > /dev/null
[Unit]
Description=Flask Proxy Application
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/opt/proxy_app
ExecStart=/opt/proxy_env/bin/python /opt/proxy_app/proxy.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable, and start the proxy service
echo "Starting the proxy service..."
sudo systemctl daemon-reload
sudo systemctl enable proxy_app
sudo systemctl start proxy_app

# Check service status
sudo systemctl status proxy_app

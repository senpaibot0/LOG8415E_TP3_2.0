#!/bin/bash

set -e

# Ensure 'sudo' is available
if ! command -v sudo &> /dev/null; then
    echo "Installing sudo..."
    apt-get update
    apt-get install -y sudo
fi

# Update the package list
sudo apt-get update -y

# Install Python and pip
sudo apt-get install -y python3 python3-pip python3-venv

# Create a virtual environment for Flask
if [ ! -d "/opt/gatekeeper_env" ]; then
    echo "Creating a Python virtual environment..."
    sudo python3 -m venv /opt/gatekeeper_env
fi

# Activate the virtual environment and install dependencies
source /opt/gatekeeper_env/bin/activate
pip install --upgrade pip
pip install flask requests
deactivate

# Create a directory for the Gatekeeper app
sudo mkdir -p /opt/gatekeeper_app
sudo chown ubuntu:ubuntu /opt/gatekeeper_app

# Dynamically set the Proxy's public IP (to be replaced in the script)
PROXY_PUBLIC_IP="3.238.156.200"

# Create the Gatekeeper Flask application
cat <<EOF | sudo tee /opt/gatekeeper_app/gatekeeper.py > /dev/null
from flask import Flask, request, jsonify
import requests

app = Flask(__name__)

PROXY_URL = "http://$PROXY_PUBLIC_IP:5000"

@app.route('/validate', methods=['POST'])
def gatekeeper():
    auth_token = request.headers.get("Authorization")
    if not auth_token or auth_token != "valid_token":
        return jsonify({"error": "Unauthorized"}), 403

    try:
        response = requests.post(PROXY_URL, json=request.json)
        return response.json(), response.status_code
    except requests.exceptions.RequestException as e:
        return jsonify({"error": "Failed to forward request", "details": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

# Configure the Gatekeeper app to run as a systemd service
cat <<EOF | sudo tee /etc/systemd/system/gatekeeper_app.service > /dev/null
[Unit]
Description=Flask Gatekeeper Application
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/opt/gatekeeper_app
ExecStart=/opt/gatekeeper_env/bin/python /opt/gatekeeper_app/gatekeeper.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable, and start the Gatekeeper service
sudo systemctl daemon-reload
sudo systemctl enable gatekeeper_app
sudo systemctl start gatekeeper_app

# Check service status
sudo systemctl status gatekeeper_app

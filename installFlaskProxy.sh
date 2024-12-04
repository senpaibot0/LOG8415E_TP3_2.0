#!/bin/bash

set -e

# Update the package list
echo "Updating package list..."
sudo apt-get update -y 
sudo apt update -y

# Install Python and pip
echo "Installing Python, pip, and venv..."
sudo apt-get install -y python3 python3-pip python3-venv awscli

# Create a virtual environment for Flask
if [ ! -d "/opt/proxy_env" ]; then
    echo "Creating a Python virtual environment..."
    sudo python3 -m venv /opt/proxy_env
fi

# Activate the virtual environment and install dependencies
echo "Installing Flask, Requests, and Boto3..."
source /opt/proxy_env/bin/activate
pip install --upgrade pip
pip install flask requests boto3
deactivate

# Create a directory for the proxy app
echo "Setting up the proxy application directory..."
sudo mkdir -p /opt/proxy_app
sudo chown ubuntu:ubuntu /opt/proxy_app

# Create the proxy Flask application
echo "Creating the proxy Flask application..."
cat <<EOF | sudo tee /opt/proxy_app/proxy.py > /dev/null
from flask import Flask, request, jsonify
import requests
import random
import time
import boto3

app = Flask(__name__)

# Backend URLs (replace with private IPs of your instances)
MANAGER_URL = "http://<manager-private-ip>:5000"
WORKERS_URLS = [
    "http://<worker-1-private-ip>:5000",
    "http://<worker-2-private-ip>:5000"
]

# AWS region for CloudWatch
AWS_REGION = "us-east-1"

# Routing strategies
ROUTING_STRATEGY = "random"  # Options: "direct", "random", "fastest", "custom"

@app.route('/route', methods=['POST'])
def proxy():
    data = request.json
    if not data or "operation" not in data:
        return jsonify({"error": "Invalid request"}), 400

    operation = data["operation"].lower()

    try:
        if ROUTING_STRATEGY == "direct":
            response = forward_request(MANAGER_URL, data)
        elif ROUTING_STRATEGY == "random":
            target_url = random.choice(WORKERS_URLS if operation == "read" else [MANAGER_URL])
            response = forward_request(target_url, data)
        elif ROUTING_STRATEGY == "fastest":
            target_url = get_fastest_worker() if operation == "read" else MANAGER_URL
            response = forward_request(target_url, data)
        elif ROUTING_STRATEGY == "custom":
            target_url = get_less_busy_worker() if operation == "read" else MANAGER_URL
            response = forward_request(target_url, data)
        else:
            return jsonify({"error": "Invalid routing strategy"}), 400
        return response
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
        start_time = time.time()
        try:
            requests.get(worker_url, timeout=2)
            ping_times[worker_url] = time.time() - start_time
        except requests.exceptions.RequestException:
            ping_times[worker_url] = float('inf')
    return min(ping_times, key=ping_times.get)


def get_less_busy_worker():
    cloudwatch = boto3.client('cloudwatch', region_name=AWS_REGION)
    worker_loads = {}
    for worker_url in WORKERS_URLS:
        instance_id = get_instance_id_from_url(worker_url)
        try:
            response = cloudwatch.get_metric_statistics(
                Namespace='AWS/EC2',
                MetricName='CPUUtilization',
                Dimensions=[{'Name': 'InstanceId', 'Value': instance_id}],
                StartTime=time.time() - 300,
                EndTime=time.time(),
                Period=60,
                Statistics=['Average']
            )
            worker_loads[worker_url] = response['Datapoints'][0]['Average'] if response['Datapoints'] else float('inf')
        except Exception:
            worker_loads[worker_url] = float('inf')
    return min(worker_loads, key=worker_loads.get)


def get_instance_id_from_url(worker_url):
    # Replace this mapping logic with the correct worker URL-to-instance ID mapping
    return "<worker-instance-id>"

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

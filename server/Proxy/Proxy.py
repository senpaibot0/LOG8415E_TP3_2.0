from abc import ABC, abstractmethod

class Proxy(ABC):
    def __init__(self, instance_ip, port):
        """
        Base attributes for a Proxy class.
        :param instance_ip: IP address of the proxy server
        :param port: Port number for communication
        """
        self.instance_ip = instance_ip
        self.port = port

    @abstractmethod
    def configure(self):
        """Method to configure the proxy server"""
        pass

    @abstractmethod
    def forward_request(self, request):
        """Method to handle forwarding requests"""
        pass

    @abstractmethod
    def health_check(self):
        """Method to check the health of the proxy"""
        
        


from flask import Flask, request, jsonify
import requests
import random

app = Flask(__name__)

# Backend URLs (update these with actual private IPs or DNS names)
MANAGER_URL = "http://<manager-private-ip>:5000"
WORKERS_URLS = [
    "http://<worker-1-private-ip>:5000",
    "http://<worker-2-private-ip>:5000"
]

@app.route('/route', methods=['POST'])
def proxy():
    data = request.json
    if not data or "operation" not in data:
        return jsonify({"error": "Invalid request"}), 400

    # Determine operation type (read or write)
    operation = data["operation"].lower()
    try:
        if operation == "write":
            # Forward to Manager
            response = requests.post(MANAGER_URL, json=data)
        elif operation == "read":
            # Forward to a random Worker
            worker_url = random.choice(WORKERS_URLS)
            response = requests.post(worker_url, json=data)
        else:
            return jsonify({"error": "Unknown operation"}), 400

        return response.json(), response.status_code
    except requests.exceptions.RequestException as e:
        return jsonify({"error": "Failed to route request", "details": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)


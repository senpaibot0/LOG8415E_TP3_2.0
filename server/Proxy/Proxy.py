from flask import Flask, request, jsonify
import requests
import random
import time

app = Flask(__name__)

# Backend URLs (to be replaced dynamically via Terraform or script injection)
MANAGER_URL = "http://<manager-private-ip>:5000"
WORKERS_URLS = [
    "http://<worker-1-private-ip>:5000",
    "http://<worker-2-private-ip>:5000"
]

# Routing strategies
ROUTING_STRATEGIES = ["direct", "random", "fastest"]
ROUTING_STRATEGY = "direct"  

# Benchmark data placeholder
worker_loads = {url: 0 for url in WORKERS_URLS} 


@app.route('/route', methods=['POST'])
def proxy():
    data = request.json
    if not data or "operation" not in data:
        return jsonify({"error": "Invalid request"}), 400

    operation = data["operation"].lower()
    strategy = data.get("strategy", ROUTING_STRATEGY)

    if strategy not in ROUTING_STRATEGIES:
        return jsonify({"error": "Invalid routing strategy"}), 400

    try:
        if strategy == "direct":
            response = forward_request(MANAGER_URL, data)
        elif strategy == "random":
            target_url = random.choice(WORKERS_URLS if operation == "read" else [MANAGER_URL])
            response = forward_request(target_url, data)
        elif strategy == "fastest":
            if operation == "write":
                response = forward_request(MANAGER_URL, data)
            elif operation == "read":
                fastest_worker = get_fastest_worker()
                response = forward_request(fastest_worker, data)
        elif strategy == "custom":
            if operation == "write":
                response = forward_request(MANAGER_URL, data)
            elif operation == "read":
                less_busy_worker = get_less_busy_worker()
                response = forward_request(less_busy_worker, data)
        else:
            return jsonify({"error": "Unknown strategy"}), 400
        return response
    except Exception as e:
        return jsonify({"error": "Failed to process request", "details": str(e)}), 500


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
    fastest_worker = min(ping_times, key=ping_times.get)
    return fastest_worker


def get_less_busy_worker():
    # Replace with actual benchmarking logic, e.g., querying CloudWatch metrics
    # Example: worker_loads = {"http://worker-1": 5, "http://worker-2": 2}
    less_busy_worker = min(worker_loads, key=worker_loads.get)
    return less_busy_worker


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)

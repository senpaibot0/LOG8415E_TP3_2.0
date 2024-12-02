from flask import Flask, request, jsonify
import requests
import random
import time

app = Flask(__name__)

# Backend URLs (remplacez avec les IP privées de vos instances)
MANAGER_URL = "http://<manager-private-ip>:5000"
WORKERS_URLS = [
    "http://<worker-1-private-ip>:5000",
    "http://<worker-2-private-ip>:5000"
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
        # Strategy: Direct hit (all requests go to the Manager)
        if ROUTING_STRATEGY == "direct":
            if operation in ["read", "write"]:
                response = forward_request(MANAGER_URL, data)
                return response

        # Strategy: Random (READ requests go to random Worker)
        elif ROUTING_STRATEGY == "random":
            if operation == "write":
                response = forward_request(MANAGER_URL, data)
            elif operation == "read":
                worker_url = random.choice(WORKERS_URLS)
                response = forward_request(worker_url, data)
            else:
                return jsonify({"error": "Unknown operation"}), 400
            return response

        # Strategy: Fastest (READ requests go to Worker with lowest ping)
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
    """Forward the request to the given URL."""
    try:
        response = requests.post(url, json=data)
        return jsonify(response.json()), response.status_code
    except requests.exceptions.RequestException as e:
        return jsonify({"error": f"Failed to reach {url}", "details": str(e)}), 500


def get_fastest_worker():
    """Determine the worker with the lowest ping time."""
    ping_times = {}
    for worker_url in WORKERS_URLS:
        start = time.time()
        try:
            requests.get(worker_url, timeout=2)  # Send a lightweight GET request
            ping_times[worker_url] = time.time() - start
        except requests.exceptions.RequestException:
            ping_times[worker_url] = float('inf')  # Mark as unreachable

    fastest_worker = min(ping_times, key=ping_times.get)
    print(f"Fastest worker selected: {fastest_worker} with ping {ping_times[fastest_worker]} seconds")
    return fastest_worker


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)

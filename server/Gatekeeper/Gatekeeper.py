from flask import Flask, request, jsonify
import requests

app = Flask(__name__)

# Proxy URL (Adjust this to the Proxy instance's IP or DNS)
PROXY_URL = "http://<proxy-public-ip>:5000"

@app.route('/validate', methods=['POST'])
def gatekeeper():
    # Step 1: Validate the request
    auth_token = request.headers.get("Authorization")
    if not auth_token or auth_token != "valid_token":
        return jsonify({"error": "Unauthorized"}), 403

    # Step 2: Forward the request to the Proxy
    try:
        response = requests.post(PROXY_URL, json=request.json)
        return response.json(), response.status_code
    except requests.exceptions.RequestException as e:
        return jsonify({"error": "Failed to forward request"}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)

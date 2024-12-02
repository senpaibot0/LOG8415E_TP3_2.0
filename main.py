import subprocess
import json
import requests
import time

# Define paths for Terraform commands
TERRAFORM_PATH = "terraform"

# Functions for Terraform operations
def terraform_init():
    print("Initializing Terraform...")
    subprocess.run([TERRAFORM_PATH, "init"], check=True)
    print("Terraform initialized successfully.")

def terraform_apply():
    print("Applying Terraform to deploy instances...")
    subprocess.run([TERRAFORM_PATH, "apply", "-auto-approve"], check=True)
    print("Terraform applied successfully.")

def terraform_output():
    print("Retrieving Terraform outputs...")
    result = subprocess.run([TERRAFORM_PATH, "output", "-json"], capture_output=True, text=True, check=True)
    outputs = json.loads(result.stdout)
    return {
        "gatekeeper_ip": outputs["gatekeeper_public_ip"]["value"],
        "proxy_ip": outputs["proxy_public_ip"]["value"],
        "manager_ip": outputs["manager_public_ip"]["value"],
        "worker_ips": outputs["worker_public_ips"]["value"]
    }

# Functions to send requests
def send_requests(gatekeeper_ip, operation, count=1000):
    url = f"http://{gatekeeper_ip}:5000/validate"
    headers = {"Authorization": "valid_token"}
    payload = {"operation": operation}

    print(f"Sending {count} {operation.upper()} requests to Gatekeeper...")
    for i in range(count):
        try:
            response = requests.post(url, headers=headers, json=payload)
            print(f"[{i + 1}] Status: {response.status_code}, Response: {response.json()}")
        except requests.exceptions.RequestException as e:
            print(f"[{i + 1}] Failed to send request: {str(e)}")

def main():
    try:
        # Step 1: Initialize Terraform
        terraform_init()

        # Step 2: Apply Terraform to deploy instances
        terraform_apply()

        # Step 3: Retrieve Terraform outputs
        outputs = terraform_output()
        gatekeeper_ip = outputs["gatekeeper_ip"]

        print(f"Gatekeeper IP: {gatekeeper_ip}")
        print(f"Proxy IP: {outputs['proxy_ip']}")
        print(f"Manager IP: {outputs['manager_ip']}")
        print(f"Worker IPs: {outputs['worker_ips']}")

        # Step 4: Wait for instances to boot up
        print("Waiting for instances to boot up (30 seconds)...")
        time.sleep(30)

        # Step 5: Send requests via Gatekeeper
        send_requests(gatekeeper_ip, operation="read", count=500)
        send_requests(gatekeeper_ip, operation="write", count=500)

        print("Requests completed successfully.")

    except Exception as e:
        print(f"An error occurred: {str(e)}")

if __name__ == "__main__":
    main()

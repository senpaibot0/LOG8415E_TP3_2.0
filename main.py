import subprocess
import json
import requests
import time
import os

#paths for Terraform commands
TERRAFORM_PATH = "./terraform"

# Define the path to the Terraform directory
TERRAFORM_DIR = "./terraform"

# Terraform Operations
def terraform_init():
    print("Initializing Terraform...")
    subprocess.run(["terraform", "init"], cwd=TERRAFORM_DIR, check=True)
    print("Terraform initialized successfully.")

def terraform_plan():
    print("Planning Terraform...")
    subprocess.run(["terraform", "plan"], cwd=TERRAFORM_DIR, check=True)
    print("Terraform plan completed successfully.")

def terraform_apply():
    print("Applying Terraform...")
    subprocess.run(["terraform", "apply", "-auto-approve"], cwd=TERRAFORM_DIR, check=True)
    print("Terraform applied successfully.")

def terraform_destroy():
    print("Destroying Terraform resources...")
    subprocess.run(["terraform", "destroy", "-auto-approve"], cwd=TERRAFORM_DIR, check=True)
    print("Terraform destroyed successfully.")

def terraform_output():
    print("Retrieving Terraform outputs...")
    try:
        result = subprocess.run(
            ["terraform", "output", "-json"],
            cwd="./terraform",  # Adjust the path if needed
            capture_output=True,
            text=True,
            check=True
        )
        outputs = json.loads(result.stdout)
        
        # Parse outputs dynamically
        return {
            "gatekeeper_public_ip": outputs["gatekeeper_public_ip"]["value"],
            "proxy_public_ip": outputs["proxy_public_ip"]["value"],
            "manager_private_ip": outputs["manager_private_ip"]["value"],
            "worker_private_ips": outputs["worker_private_ips"]["value"]
        }
    except KeyError as e:
        print(f"KeyError: {e}. Please check the Terraform outputs for the correct key names.")
        raise
    except subprocess.CalledProcessError as e:
        print(f"Terraform command failed: {e}")
        raise
    except Exception as e:
        print(f"Unexpected error: {e}")
        raise

# Sending Requests to Gatekeeper
def send_requests(gatekeeper_ip, operation, count=100):
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

# Install to Instance
def install_to_instance(ip_address, script_name):
    ssh_key_path = r"C:/Users/hanna/Documents/TP/tp/anouar_Key.pem"
    script_path = f"./{script_name}"

    try:
        if not os.path.exists(script_path):
            raise FileNotFoundError(f"Script {script_name} not found at {script_path}")

        print(f"Uploading the script {script_name} to {ip_address}...")
        subprocess.run([
            "scp", "-i", ssh_key_path, "-o", "StrictHostKeyChecking=no", script_path,
            f"ubuntu@{ip_address}:/home/ubuntu/{script_name}"
        ], check=True)
        print(f"Script {script_name} uploaded successfully to {ip_address}.")

        print(f"Executing the script {script_name} on {ip_address}...")
        subprocess.run([
            "ssh", "-i", ssh_key_path, "-o", "StrictHostKeyChecking=no",
            f"ubuntu@{ip_address}", f"sudo bash /home/ubuntu/{script_name}"
        ], check=True)
        print(f"Setup complete on {ip_address}.")
    except FileNotFoundError as e:
        print(f"Error: {e}")
    except subprocess.CalledProcessError as e:
        print(f"Error executing {script_name} on {ip_address}: {e.stderr}")
    except Exception as e:
        print(f"Unexpected error: {e}")

def benchmark_database(instance_ips, instance_type):
    """
    Benchmark MySQL database on the given instances using sysbench.

    Args:
        instance_ips (list): List of instance IPs.
        instance_type (str): Type of instance (e.g., "Manager", "Worker").
    """
    print(f"Benchmarking MySQL database on {instance_type} instances...")
    ssh_key_path = r"C:/Users/hanna/Documents/TP/tp/anouar_Key.pem"
    benchmark_commands = """
        sysbench /usr/share/sysbench/oltp_read_write.lua --mysql-host=127.0.0.1 --mysql-user=root --mysql-password=root_password --mysql-db=sakila prepare;
        sysbench /usr/share/sysbench/oltp_read_write.lua --mysql-host=127.0.0.1 --mysql-user=root --mysql-password=root_password --mysql-db=sakila --threads=4 --time=60 run;
        sysbench /usr/share/sysbench/oltp_read_write.lua --mysql-host=127.0.0.1 --mysql-user=root --mysql-password=root_password --mysql-db=sakila cleanup;
    """

    for ip in instance_ips:
        try:
            print(f"Benchmarking on {instance_type} instance: {ip}...")
            result = subprocess.run(
                [
                    "ssh", "-i", ssh_key_path, "-o", "StrictHostKeyChecking=no",
                    f"ubuntu@{ip}", f"bash -c \"{benchmark_commands}\""
                ],
                capture_output=True,
                text=True,
                check=True
            )
            output_file = f"sysbench_results_{instance_type}_{ip.replace('.', '_')}.txt"
            with open(output_file, "w") as file:
                file.write(result.stdout)
            print(f"Benchmarking completed on {ip}. Results saved to {output_file}.")
        except subprocess.CalledProcessError as e:
            print(f"Error during benchmarking on {ip}: {e.stderr}")
        except Exception as e:
            print(f"Unexpected error during benchmarking on {ip}: {e}")

def main():
    try:
        # Step 1: Initialize Terraform
        terraform_init()

        # Step 2: Apply Terraform resources
        terraform_plan()
        terraform_apply()

        # Step 3: Retrieve Terraform outputs
        outputs = terraform_output()

        # Dynamic IP addresses
        gatekeeper_ip = outputs["gatekeeper_public_ip"]
        proxy_ip = outputs["proxy_public_ip"]
        manager_ip = [outputs["manager_private_ip"]]
        worker_ips = outputs["worker_private_ips"]

        print(f"Gatekeeper IP: {gatekeeper_ip}")
        print(f"Proxy IP: {proxy_ip}")
        print(f"Manager IP: {manager_ip}")
        print(f"Worker IPs: {worker_ips}")

        # Step 4: Wait for instances to boot up
        print("Waiting for instances to boot up...")
        time.sleep(15)

        # Step 5: Benchmark the database on the Manager
        benchmark_database(manager_ip, "Manager")

        # Step 6: Benchmark the database on Workers
        benchmark_database(worker_ips, "Worker")

        # Step 7: Install Flask on Gatekeeper
        install_to_instance(gatekeeper_ip, "installFlask.sh")

        # Step 8: Install Flask on Proxy
        install_to_instance(proxy_ip, "installFlaskProxy.sh")

        # Step 9: Send requests via the Gatekeeper
        send_requests(gatekeeper_ip, operation="read", count=10)
        send_requests(gatekeeper_ip, operation="write", count=10)

        print("Requests completed successfully.")

        # Optional Step: Destroy resources
        # terraform_destroy()

    except Exception as e:
        print(f"An error occurred: {str(e)}")


if __name__ == "__main__":
    main()

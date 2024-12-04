import requests

# Target URL
url = "http://3.239.51.177/validate"

try:
    # Perform the GET request
    response = requests.post(url)
    
    # Check the response status
    if response.status_code == 200:
        print("Request was successful!")
        print("Response:", response.json())
    else:
        print(f"Request failed with status code {response.status_code}")
        print("Response:", response.text)
except requests.exceptions.RequestException as e:
    print(f"An error occurred: {e}")

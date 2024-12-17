import requests

base_url = 'http://127.0.0.1:5000'

# Register a new user
def register_user(email, password, role):
    url = f'{base_url}/register'
    data = {"email": email, "password": password, "role": role}
    response = requests.post(url, json=data)
    print("Register Response:", response.json())

# Test Login
def test_login(email, password):
    url = f'{base_url}/login'
    data = {"email": email, "password": password}
    response = requests.post(url, json=data)
    print("Login Response:", response.json())
    return response.json().get('access_token')

# Test Get Deliveries
def get_deliveries(token, role, user_id=None):
    url = f'{base_url}/deliveries'
    headers = {'Authorization': f'Bearer {token}'}
    params = {'role': role, 'user_id': user_id}
    response = requests.get(url, headers=headers, params=params)
    print("Deliveries Response:", response.json())

# Testing the APIs
register_user("supervisor@example.com", "password123", "supervisor")
token = test_login("supervisor@example.com", "password123")
get_deliveries(token, "supervisor")

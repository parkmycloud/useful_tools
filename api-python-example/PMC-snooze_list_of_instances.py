import os
import requests

# Get the PMC API key from the OS environment variable
pmc_username = os.environ.get('PMC_USERNAME')
pmc_password = os.environ.get('PMC_PASSWORD')
pmc_api = os.environ.get('PMC_API_TOKEN')
base_url = "https://console.parkmycloud.com"

# Define the instances you want snoozed
snooze_these_instance_names = [
	"instance1",
	"instance2",
	"instance3"
]

# Authenticate to ParkMyCloud's API
def get_pmc_api_auth():
    url = base_url + '/auth'
    payload = { 
        "username": pmc_username,
        "password": pmc_password,
        "app_id": pmc_api 
    }
    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json"
    }
    auth_response = requests.post(url=url, json=payload, headers=headers)
    return auth_response.json()['token']

# Get a list of resources (instances and databases) from ParkMyCloud
def get_pmc_resources(auth_token):
    url = base_url + '/resources-simple'
    headers = {
        "Accept": "application/json",
        "X-Auth-Token": auth_token
    }
    resources_json = requests.get(url=url, headers=headers).json()
    return resources_json

# Snooze a schedule, which temporarily overrides it
def pmc_snooze_schedule(auth_token, item_ids, hours):
    url = base_url + '/resources/snooze'
    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-Auth-Token": auth_token
    }
    body = {
        "item_ids": item_ids,
        "snooze_period": hours,
        "timezone": "America/New_York"
    }
    snooze_response = requests.put(url=url, headers=headers, json=body)
    snooze_json = snooze_response.json()
    return snooze_json

if __name__ == "__main__":
	# 1. Login to the API to get an auth token (POST to /auth/login)
	auth_token = get_pmc_api_auth()

	# 2. Get a list of all resources in your account (GET to /resources-simple)
	resources_json = get_pmc_resources(auth_token)

	# 3. Find the instances you need and get their corresponding PMC IDs
	item_ids = []
	for item in resources_json['items']:
		if item['name'] in snooze_these_instance_names:
			print "Adding item to snooze list: "+str(item['name'])
			item_ids.append(int(item['id']))

	# 4. Use that list of instance IDs to snooze the schedules (PUT to /resources/snooze)
	hours = 2
	snooze_response = pmc_snooze_schedule(auth_token, item_ids, hours)
	if snooze_response.has_key('snooze_until'):
		print "Items will snooze until "+str(snooze_response['snooze_until'])
	else:
		print "No items found for snooze"

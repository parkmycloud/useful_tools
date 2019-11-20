import os
import json
import urllib.request

# Get the PMC API key from the OS environment variable
pmc_api_key_id = os.environ.get('PMC_API_KEY_ID')
pmc_api_key = os.environ.get('PMC_API_KEY')
base_url = "https://console.parkmycloud.com"

# Define the instances you want to override
override_these_instance_names = [
    "instance1",
    "instance2",
    "instance3"
]

# Generic function to make a web call, expecting a JSON response
#   method   Must be one of "GET", "PUT", "POST", "DELETE", "PATCH", etc.
#   url      Fully qualified URL to call. Ex: "https://console.parkmycloud.com/fun"
#   body     JSON body of the call, if any, in string form.  If none, use ""
#   headers  HTTP Headers in JSON format to use for the call, passed as a string
#
def request(method, url, body, headers):
    if body == "":
        request = urllib.request.Request(url, headers=headers)
    else:
        request = urllib.request.Request(
            url, json.dumps(body).encode("utf-8"), headers=headers)
    request.get_method = lambda: method
    response = urllib.request.urlopen(request)
    response_string = response.read().decode('utf-8')
    response_code = response.getcode()
    if (response_code < 200) or (response_code > 299):
        print("Request to", response.geturl(),
            "failed. Error details:", response_string)
    return json.loads(response_string)


# Authenticate to ParkMyCloud's API
def get_pmc_api_auth():
    url = base_url + '/v2/auth/login'
    payload = {
        "key_id": pmc_api_key_id,
        "key": pmc_api_key,
        "duration": 60, # duration in seconds - should be enough for this script
    }
    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json"
    }
    auth_dict = request("POST", url, payload, headers)
    auth_token = auth_dict['token']
    return auth_token

# Get a list of resources (instances and databases) from ParkMyCloud


def get_pmc_resources(auth_token):
    # this is a deprecated API...but it does provide all of the 
    # resources in one call. This will not scale well for large 
    # customers. Instead, use the /resources/paged API
    url = base_url + '/resources-simple'
    headers = {
        "Accept": "application/json",
        "X-Auth-Token": auth_token
    }
    return request("GET", url, "", headers)

# Override a schedule, which temporarily disables the schedule system,
# and allows you to start and stop it at will


def pmc_override_schedule(auth_token, item_ids, hours):
    url = base_url + '/v2/resource/override'
    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-Auth-Token": auth_token
    }
    body = {
        "item_ids": item_ids,
        "override_period": hours,
        "timezone": "America/New_York"
    }
    result = request("PUT", url, body, headers)
    return result

if __name__ == "__main__":
        # 1. Login to the API to get an auth token (POST to /auth/login)
    auth_token = get_pmc_api_auth()

    # 2. Get a list of all resources in your account (GET to /resources-simple)
    resources_json = get_pmc_resources(auth_token)

    # 3. Find the instances you need and get their corresponding PMC IDs
    item_ids = []
    found_names = []
    for item in resources_json['items']:
        if item['name'] in override_these_instance_names:
            print("Adding item to override list:", str(item['name']))
            item_ids.append(int(item['id']))
            found_names.append(item['name'])

    # 4. make sure we found them all
    if len(item_ids) != len(override_these_instance_names):
        print("Not all item names were found. Requested names:")
        for name in override_these_instance_names:
            print("  ", name)
        if len(item_ids) == 0:
            print("No resources matched these names - aborting")
            quit()
        else:
            print("Will attempt to override resources that were found:")
            for name in found_names:
                print("  ", name)

    # 5. Use that list of instance IDs to override the schedules (PUT to /resources/override)
    hours = 2
    override_response = pmc_override_schedule(auth_token, item_ids, hours)
    if 'override_until' in override_response:
        print("Item schedules will override until",
            str(override_response['override_until']))
    else:
        print("No items found for override")

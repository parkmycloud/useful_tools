import urllib.request
import json

pmc_console = "https://console.parkmycloud.com"

####################################################################################
####################################################################################
# TODO: Fill this next structure in with your ParkMyCloud API credentials
####################################################################################
####################################################################################
# Get these values from the ParkMyCloud console
# - Go to the Users left-menu item, and select the user to use for API access
# - On the Edit user screen, go to the Access Settings tab
# - Click the Enable API Access checkbox
# - Copy the Key and Key ID below 
# Protect these values in your environment as you would protect a username and password!
login_codes = {
  "key": "YOUR API PRIVATE KEY GOES HERE",
  "key_id": "YOUR API KEY ID GOES HERE",
  "duration": 60, # duration in seconds - should be enough for this script
}

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
    request = urllib.request.Request(url, json.dumps(body).encode("utf-8"), headers=headers)
  request.get_method = lambda: method
  response = urllib.request.urlopen(request)
  response_string = response.read().decode('utf-8')
  response_code = response.getcode()
  print(method, " response: ", response_code)
  if (response_code < 200) or (response_code > 299):
    print("Request to ", response.geturl(), " failed. Error details: ", response_string)
  return json.loads(response_string)

#####################
# Authenticate
#####################

auth_url = pmc_console + "/v2/auth/login"

headers = {
  "Content-Type": "application/json",
}

# Get the access token from ParkMyCloud
# This token is used to access other APIs
auth_dict = request("POST", auth_url, login_codes, headers)

print ("Auth response: \n", json.dumps(auth_dict, indent=2))

auth_token = auth_dict['token']

#####################
# Find a specific resource
#####################

####################################################################################
####################################################################################
# TODO: Fill this in with the name or unique identifier of the resource you want to find
# Ex: BillsVirtualMachine, i-34234255435433, ProductionAurora47
####################################################################################
####################################################################################

# Use the LIST API to find a certain resource
vm_name="MY_VM_NAME"

list_url = pmc_console + "/resources/paged?" + "search=" + vm_name

# New headers for subsequent calls
headers = {
  'Content-Type': 'application/json',
  'X-Auth-Token': auth_token,
}

list_dic = request("GET", list_url, "", headers)

print("List response: \n", json.dumps(list_dic, indent=2))


# This assumes there was only one resource returned in the previous call
# so use the resource unique ID or more search parameters to ensure you only
# get one result (or be prepared to deal with each of them...)
pmc_resource_id = list_dic['data'][0]['id']
print("Using ID: ", pmc_resource_id)

#####################
# Get the resource details
#####################

details_url = pmc_console + "/resources/detail/" + str(pmc_resource_id)

# Get the resource details
details_dic = request("GET", details_url, "", headers)

print ("Details response: \n", json.dumps(details_dic, indent=2))


#####################
# Override the resource schedule for 1/2 hour
#####################

override_url = pmc_console + "/v2/resource/override"

body = {
  "item_ids": [ pmc_resource_id ],
  "override_period": 0.5,
}

override_dic = request("PUT", override_url, body, headers)
print ("Override response: \n", json.dumps(override_dic, indent=2))


#####################
# Start the resource
#####################

toggle_url = pmc_console + "/resources/toggle"

body = {
  "item_ids": [ pmc_resource_id ],
  "action": "start",
}

override_dic = request("PUT", toggle_url, body, headers)
print ("Response: \n", json.dumps(override_dic, indent=2))


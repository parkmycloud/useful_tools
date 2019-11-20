# ParkMyCloud API Examples in Python

These examples have been tested with: Python 3.5.2

## Authentication in these examples

The Authentication in these programs uses our V2 Auth API, allowing for self-service generation of API Keys, and better management of access control.

Get these values from the ParkMyCloud console
- Go to the Users left-menu item, and select the user to use for API access
- On the Edit user screen, go to the Access Settings tab
- Click the Enable API Access checkbox
- Copy the Key and Key ID for use in the programs below

Note that users that authenticate to the APIs using this API key will appear in a distinct fashion in the ParkMyCloud Audit Log (Under Reports>Audit Log in our console). These logins will appear with the event code `apikey.login`.

## Example: PMC-auth-search-details-override-start.py

This example demonstrates the following API functions:
- Authentication
- Find a virtual machine by name
- Get the VM details (which will include tags)
- Override the resource schedule
- Start the resource
- Basic HTTP error handling

### Steps for running PMC-auth-search-details-override-start.py

1. Near the top of the file there is a list called `login_codes` that you must update with your API Key ID and API Key.

2. Around line 73, you must fill-in the name or unique identifier of the resource you want to find. Ex: BillsVirtualMachine, i-34234255435433, ProductionAurora47

3. Run the file by running the command:

```python3 PMC-auth-search-details-override-start.py```

## Example: PMC-override_list_of_instances.py

This example will take a list of instance names (or other unique identifiers) and override the schedules in ParkMyCloud for those instances for 2 hours. This could be used for temporarily turning on instances for patching or backups.

### Steps for running PMC-override_list_of_instances.py

1. Near the top of the file there is a list called `override_these_instance_names` that you can modify to have the list of things you want to override (or you could populate that some other way, like from the excel file).

2. The script pulls the user API Key information from environment variables, but you could modify that at the top to just hard-code that in if you want.

3. Run this by substituting your API Key ID and API Key in the command below, and executing it:

```PMC_API_KEY_ID=79a72b93-15ad-4548-b5ec-f95ec476bc6c PMC_API_KEY=0d4c9103a4dd351967c791daf958c6fc10b9546e0a1cd5a2abc8985fc56f python3 PMC-override_list_of_instances.py```


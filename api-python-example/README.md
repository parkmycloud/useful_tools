# ParkMyCloud API Examples in Python

### Purpose of PMC-snooze_list_of_instances.py

This example will take a list of instance names and override the schedules in ParkMyCloud for those instances for 2 hours.  This could be used for temporarily turning on instances for patching or backups.

### Steps for running PMC-snooze_list_of_instances.py

1. Near the top of the file there is a list called “snooze_these_instance_names” that you can modify to have the list of things you want to snooze (or you could populate that some other way, like from the excel file, but I kept this example simpler).

2. The script pulls the username, password, and API token from environment variables, but you could modify that at the top to just hard-code that in if you want.
 
3. Run this by doing:
 
PMC_USERNAME=email@email.com PMC_PASSWORD=PutPassHere PMC_API_TOKEN=1234567890abcdef1234567890abcdef python PMC-snooze_list_of_instances.py

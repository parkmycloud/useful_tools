"""
This Slackbot interacts with ParkMyCloud to provide an easy way to
schedule resources (instances, Auto Scaling Groups, and databases)
to turn off when you don't need them, such as nights and weekends.

The bot listens on the connected Slack channel
"""

import os
import time
from slackclient import SlackClient
import requests


# instantiate Slack client with the slack token
slack_client = SlackClient(os.environ.get('SLACK_BOT_TOKEN'))

# Get the PMC API key from the OS environment variable
pmc_username = os.environ.get('PMC_USERNAME')
pmc_password = os.environ.get('PMC_PASSWORD')
pmc_api = os.environ.get('PMC_API_TOKEN')
base_url = "https://console.parkmycloud.com"

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


# Get a list of schedules from ParkMyCloud
def get_pmc_schedules():
    auth_token = get_pmc_api_auth()
    url = base_url + '/schedules'
    headers = {
        "Accept": "application/json",
        "X-Auth-Token": auth_token
    }
    schedules_json = requests.get(url=url, headers=headers).json()
    return schedules_json
    

# Get a list of resources (instances and databases) from ParkMyCloud
def get_pmc_resources():
    auth_token = get_pmc_api_auth()
    url = base_url + '/resources-simple'
    headers = {
        "Accept": "application/json",
        "X-Auth-Token": auth_token
    }
    resources_json = requests.get(url=url, headers=headers).json()
    return resources_json


# Turn resources off or on
def pmc_toggle_resources(item_ids):
    auth_token = get_pmc_api_auth()
    url = base_url + '/resources/toggle'
    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-Auth-Token": auth_token
    }
    body = { "item_ids": item_ids }
    print body
    toggle_response = requests.put(url=url, headers=headers, json=body)
    print toggle_response.text
    toggle_json = toggle_response.json()
    return toggle_json


# Snooze a schedule, which temporarily overrides it
def pmc_snooze_schedule(item_ids, hours):
    auth_token = get_pmc_api_auth()
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


# Attach or Detach a schedule from a resource
def pmc_attach_schedule(item_ids, schedule_id):
    auth_token = get_pmc_api_auth()
    url = base_url + '/resources/attach-schedule'
    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-Auth-Token": auth_token
    }
    print schedule_id
    body = {
        "item_ids": item_ids,
        "schedule_id": schedule_id
    }
    attach_response = requests.put(url=url, headers=headers, json=body, verify=False)
    print attach_response.text
    #attach_json = attach_response.json()
    return attach_response


# All command parsing is done here.  Default response is an error.
def handle_command(command, channel):
    response = "ERROR: Command not recognized"
    if command.lower() == "get schedules":
        print "List of schedules requested"
        schedules_json = get_pmc_schedules()
        response = "Here's a list of available schedules:\n"
        for schedule in schedules_json:
            response += str(schedule['id'])+" - "+schedule['name']+"\n"
    elif command.lower() == "get resources":
        print "List of resources requested"
        resources_json = get_pmc_resources()
        response = "Here's a list of available resources:\n"
        for resource in resources_json['items']:
            response += str(resource['id']) + ' - ' + resource['name']+"\n"
    elif command.startswith("toggle"):
        toggle_command = command.partition(' ')[2].split(' ')
        item_ids = [int(item) for item in toggle_command]
        toggle_json = pmc_toggle_resources(item_ids=item_ids)
        response = "The following resources have been toggled:\n"
        for item in item_ids:
            response += str(item)+'\n'
    elif command.startswith("snooze"):
        snooze_command = command.split(' ')
        hours = int(snooze_command[1])
        item_ids = [int(snooze_command[2])]
        snooze_json = pmc_snooze_schedule(hours=hours, item_ids=item_ids)
        print snooze_json
        response = str(item_ids[0])+" will be snoozed until "+str(snooze_json['snooze_until'])
    elif command.startswith("attach"):
        print "Attach schedule requested"
        attach_command = command.split(' ')
        schedule_id = int(attach_command[1])
        item_ids = [int(attach_command[2])]
        attach_json = pmc_attach_schedule(schedule_id=schedule_id, item_ids=item_ids)
        print attach_json
        response = "Schedule attached"
    elif command.startswith("detach"):
        print "Detach schedule requested"
        attach_command = command.split(' ')
        item_ids = [int(attach_command[1])]
        attach_json = pmc_attach_schedule(schedule_id="null", item_ids=item_ids)
        print attach_json
        response = "Schedule detached"
    # Post the message to the slack channel
    slack_client.api_call("chat.postMessage", channel=channel,
                          text=response, as_user=True)


# Read each Slack message and parse it if the bot is mentioned
def parse_slack_output(slack_rtm_output, at_bot):
    output_list = slack_rtm_output
    if output_list and len(output_list) > 0:
        for output in output_list:
            if output and 'text' in output and at_bot in output['text']:
                # return text after the @ mention, whitespace removed
                return output['text'].split(at_bot)[1].strip().lower(), \
                       output['channel']
    return None, None


if __name__ == "__main__":
    # 1 second delay between reading from firehose
    READ_WEBSOCKET_DELAY = 1 
    
    # Get the bot's ID
    bot_id = None
    api_call = slack_client.api_call("users.list")
    if api_call.get('ok'):
        # retrieve all users so we can find our bot
        users = api_call.get('members')
        for user in users:
            if 'name' in user and user.get('name') == "pmc":
                print("Bot ID for '" + user['name'] + "' is " + user.get('id'))
                bot_id = user.get('id')
    if bot_id:
        at_bot = "<@" + bot_id + ">"
    else:
        print "ERROR: No bot_id found for @pmcbot"

    
    
    if slack_client.rtm_connect():
        print("PMCBot connected and running!")
        while True:
            command, channel = parse_slack_output(slack_client.rtm_read(), at_bot)
            if command and channel:
                handle_command(command, channel)
            time.sleep(READ_WEBSOCKET_DELAY)
    else:
        print("Connection failed. Invalid Slack token or bot ID?")

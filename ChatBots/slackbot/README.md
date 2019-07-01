# ParkMyCloud Slackbot


### Purpose

ParkMyCloud is SaaS application which allows users to schedule on/off times for their non-production cloud resources, without having to do scripting. For more details on the application and company, you can go here [http://www.parkmycloud.com].

The purpose of this bot is to allow users to interact with the ParkMyCloud API through chat commands in Slack.

### How to install

- Install slackclient library
- Add a new Slack app to your team
- Get ParkMyCloud API token from the ParkMyCloud support team
- Get Slack API token
- Run the slackbot on a server that will stay on

SLACK_BOT_TOKEN=xoxb-12345678901-abcdefghijklmnopqrstuvwxyz PMC_API_TOKEN=1234abcd5678efgh1234abcd5678efgh PMC_USERNAME=yourname@email.com PMC_PASSWORD=mypassword python pmc-command-slackbot.py

### Current commands
- get resources
- get schedules
- toggle <resource_id>
- snooze <hours> <resource_ids>
- attach <schedule_id> <resource_ids>
- detach <resource_ids>

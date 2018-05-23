* Push all your code to GitHub (you can also deploy from a local git repo or Visual Studio) and follow [these steps](https://docs.microsoft.com/en-us/bot-framework/deploy-bot-github)
* Set up an Azure account
* Create a web app on Azure
* [Register your bot](https://docs.microsoft.com/en-us/bot-framework/portal-register-bot)


When registering your bot, the HTTPS Message Endpoint is the URL from your Azure web app (found in the Web Apps Overview section). You will need to add /api/messages to the end of the URL.

You will also need to add the generated MICROSOFT_APP_ID and MICROSOFT_APP_PASSWORD to your Web App’s Application Settings. You can do this by going to the App settings section where the Key is MICROSOFT_APP_ID and Value is the generated ID. Repeat for MICROSOFT_APP_PASSWORD.
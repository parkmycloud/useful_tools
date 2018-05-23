var restify = require('restify'); 
var builder = require('botbuilder');  
// Setup Restify Server 
var server = restify.createServer(); 

var MICROSOFT_APP_ID = '';
var MICROSOFT_APP_PASSWORD = '';
var PMC_USERNAME = '';
var PMC_PASSWORD = '';
var PMC_APP_ID = '';

const axios = require('axios');
const instance = axios.create({
    baseURL: 'https://console.parkmycloud.com',
    headers: {"Content-Type": "application/json", "Accept": "application/json"}
})
server.listen(process.env.port || process.env.PORT || 3333, 
function () {    
    console.log('%s listening to %s', server.name, server.url);  
});  
// chat connector for communicating with the Bot Framework Service 
var connector = new builder.ChatConnector({     
    appId: MICROSOFT_APP_ID,     
    appPassword: MICROSOFT_APP_PASSWORD
});
// Listen for messages from users  
server.post('/api/messages', connector.listen());  
// Receive messages from the user and respond by echoing each message back (prefixed with 'You said:') 
var bot = new builder.UniversalBot(connector, function (session) {     
	//session.send("You said: %s", session.message.text); 
	if (session.message.text.indexOf("get resources") !=-1) { getResources(session) }
	if (session.message.text.indexOf("snooze") !=-1) { 
		var arr = session.message.text.split(" ");
		snoozeResources(session, arr[1], arr[2]);
	}
});

function getResources(session) {
    instance.post('/auth', {
            username: PMC_USERNAME,
            password: PMC_PASSWORD,
            app_id: PMC_APP_ID
        })
        .then(function(response) {
            instance({
                method:'get',
                url:'/resources-simple',
                headers: {'Accept':'application/json', 'X-Auth-Token':response.data.token}
            })
                .then(function(response){
                    response.data.items.forEach(function(item){
                    	session.send("%s - %s", item.id, item.name)
                    })
                })
        })
}

function snoozeResources(session, item_ids, snooze_period) {
    instance.post('/auth', {
            username: PMC_USERNAME,
            password: PMC_PASSWORD,
            app_id: PMC_APP_ID
        })
        .then(function(response) {
            instance({
                method:'put',
                url:'/resources/snooze',
                headers: {'Accept':'application/json', 'X-Auth-Token':response.data.token},
                data: { "item_ids": [ parseInt(item_ids) ], "snooze_period": parseInt(snooze_period) }
            })
                .then(function(response){
                    session.send("Instance will snooze until - %s", response.data.snooze_until)
                })
        })
}
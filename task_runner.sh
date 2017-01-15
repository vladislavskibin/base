#!/bin/bash

USER="test"
PASS="test"
SERVICE_ENDPOINT="10.0.0.255:9999"
API_TOKEN_VALID_TIME=300
SLEEP_TIME=60
CURL_PARAMETRS="-s --connect-timeout 10 --max-time 10" # These parameters are specific to the server
LOG_FILE="/var/log/task_control_log"

# INPUT:
# Service listens on the same host, public IP. Accepts params by GET/POST.
# API token expires in 5mins.
# If task is not started, returns 404 code with "Not found" message.
# When task completed successfully - returns 200 code with some log output containing "RESULT: INTEGER" line.
# Otherwise - 500 code with log output and "ERROR: STRING" line.
# We need to start task, control its result and restart if failed or every 60 seconds. 
# The process must work on permanent basis in background.

# OBJECTIVE:
# 1) Universalize;
# 2) Optimize;
# 3) Secure.

get_API_token () { #get token
 echo "New API_TOKEN was requested on `date '+%Y-%m-%d %H:%M:%S'`" >> $LOG_FILE
 API_TOKEN=`curl $CURL_PARAMETRS http://$SERVICE_ENDPOINT/apitoken?user=$USER\&pass=$PASS`
}

check_API_token () { # check existence of token and attempt to obtain tokens if it absence
while [ -z $API_TOKEN ]; do
       get_API_token
       echo "API_TOKEN was not received on `date '+%Y-%m-%d %H:%M:%S'`. Retry after 10 second" >> $LOG_FILE
       sleep 10
       done
}

task_restart_command (){
curl $CURL_PARAMETRS http://$SERVICE_ENDPOINT/task/start?api_token=$API_TOKEN
}

get_API_token
check_API_token
API_TOKEN_EXISTING_TIME=`date '+%s'`
CURRENT_TIME=`date '+%s'`

while true; do
CURRENT_TIME=`date '+%s'`
TIME_DIFF=$(($CURRENT_TIME-$API_TOKEN_EXISTING_TIME))


if [ $(($TIME_DIFF+$SLEEP_TIME)) -ge $API_TOKEN_VALID_TIME ] #add SLEEP_TIME to difference for opportunity restart task with valid token after 60 second 
 then
        API_TOKEN="" #delete value of expiring token
        get_API_token
        check_API_token
        API_TOKEN_EXISTING_TIME=`date '+%s'`
fi

RESULT=`curl -I $CURL_PARAMETRS http://${SERVICE_ENDPOINT} | head -1 | awk '{print $2}'` #use only HTTP codes

if [ "$RESULT" -eq "404" ] || [ "$RESULT" -eq "500" ]; then
        echo "Task error $RESULT was recieved on `date '+%Y-%m-%d %H:%M:%S'`" >> $LOG_FILE
        task_restart_command

elif [ "$RESULT" -eq "200" ]; then
        echo "Task is running. Wait ${SLEEP_TIME} sec" >> $LOG_FILE
        sleep ${SLEEP_TIME}
        task_restart_command
else
        echo "Unknown task error $RESULT was recieved on `date '+%Y-%m-%d %H:%M:%S'`" >> $LOG_FILE
        task_restart_command
fi
done


#!/bin/bash

USER="test"
PASS="test"
SERVICE_ENDPOINT="10.0.0.255:9999"

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

while true; do
curl http://$SERVICE_ENDPOINT/apitoken?user=$USER&pass=$PASS > api_token
API_TOKEN=`cat api_token`
curl http://$SERVICE_ENDPOINT/task?api_token=$API_TOKEN > task_exists_response
grep 404 task_exists_response && curl http://$SERVICE_ENDPOINT/task/start?api_token=$API_TOKEN > task_run_response
grep "Not found" task_exists_response && curl http://$SERVICE_ENDPOINT/task/start?api_token=$API_TOKEN > task_run_response
grep 200 task_run_response && sleep 60
grep "RESULT" task_run_response && sleep 60
grep 500 task_run_response && curl http://$SERVICE_ENDPOINT/task/start?api_token=$API_TOKEN > task_run_response
grep "ERROR" task_run_response && curl http://$SERVICE_ENDPOINT/task/start?api_token=$API_TOKEN > task_run_response
done
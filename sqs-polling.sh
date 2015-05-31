#!/bin/bash

set -e

# --------------------------------------------------------------------------------------------
# This script written by Neal Magee <neal.magee@aaec.net> - ver 1.2 4/10/2015
# --------------------------------------------------------------------------------------------
# Polling script using the AWS CLI to check for healthy nodes in an auto-scaling group,
# and then either verify that a healthy node has the elastic IP, or assign it to the first
# healthy node it finds.
# --------------------------------------------------------------------------------------------

# SET THE VARIABLES BELOW
sqsurl="https://sqs.us-east-1.amazonaws.com/1234567890/MY-QUEUE-NAME"    # The URL of your SQS queue
sqsqueue="MY-QUEUE-NAME"                                                 # The name of your SQS queue
awsprofile="default"                                                     # The AWS CLI profile to use
# --------------------------------------------------------------------------------------------

message=`/usr/bin/aws --profile $awsprofile sqs receive-message --queue-url $sqsurl --wait-time-seconds 20`
subject=`echo $message | jq -r .Messages[0].Body | jq -r .Subject`
receipthandle=`echo $message | jq -r .Messages[0].ReceiptHandle`

# If subject contains a termination, then process. If not, pass.
if [[ "$subject" == *"termination"* ]]
then
    if [ $verbose ]; then echo "Subject PASS - $subject"; fi
    # Depending upon where your scripts are installed, adjust below:
    /bin/bash /root/scripts/fixed-ip.sh
    /usr/bin/aws --profile $awsprofile sqs delete-message --queue-url $sqsurl --receipt-handle $receipthandle 
else
    # Do nothing, really
    if [ $verbose ]; then echo "Subject FAIL - $subject"; fi
fi

exit 0

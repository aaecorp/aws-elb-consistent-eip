# aws-elb-consistent-eip
Keep an elastic IP consistently attached to an ELB

## Requirements
- AWS-CLI - http://aws.amazon.com/cli/
- jq - http://stedolan.github.io/jq/
- Pushover API token/user (optional) - https://pushover.net/
- AWS SQS queue
- AWS EC2 autoscaling group
- AWS EC2 elastic IP

## Installation
Install both scripts in a directory such as /root/scripts/. (Search the scripts for this path and replace accordingly.)
Configure all static variables at the top of each script.
Create an SQS queue and enter the appropriate queue variables into your scripts.
After creating an auto-scaling group in EC2, create a notification to be sent to your SQS queue upon ASG terminations.
Set the SQS script to be executed by cron every N minutes. When the SQS polling script detects a message, it will trigger the second script.

If you don't want to implement Pushover notifications upon reattachment, remove or comment out all the 'curl' commands. Or adapt them to your own notifications.

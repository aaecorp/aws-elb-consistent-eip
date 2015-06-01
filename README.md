# aws-elb-consistent-eip
Keep an elastic IP consistently attached to an ELB

## Requirements
  - AWS-CLI - http://aws.amazon.com/cli/
  - jq - http://stedolan.github.io/jq/
  - Pushover API token/user (optional) - https://pushover.net/
  - AWS SQS queue
  - AWS EC2 autoscaling group
  - AWS EC2 elastic IP

## SQS Queue Setup
  - Create an SQS queue and set the `Default Visibility Timeout` to 30 seconds. This script uses SQS "long polling" which means it will continue to poll for a response for 20 seconds. That leaves only a possible 10-second window when a message will arrive before it is detected.
  - `Message Retention Period` can be set to something short, 15 mins will work well. These messages are designed to be picked up and acted upon within very short order, then deleted.
  - `Receive Message Wait Time` should be set to `0`

## EC2 Auto-Scaling Setup
  - Create your Launch Configuration and Auto-Scaling Group as you normally would.
  - In the `Notification` properties of your Auto-Scaling Group, create a notification to be sent whenever an instance is terminated. The notification should be pointed to the SQS queue you create above.

## Script Installation
  - Install both scripts in a directory such as `/root/scripts/`. (Search the scripts for this path and replace accordingly.)
  - Be sure your path to the 'aws' executable is used in the scripts. This is often `/usr/bin/aws`
  - If you use AWS CLI profiles, specify your profile as needed in the variable.
  - Configure all static variables at the top of each script.
  - Create an SQS queue and enter the appropriate queue variables into your scripts.
  - After creating an auto-scaling group in EC2, create a notification to be sent to your SQS queue upon ASG terminations.
  - Set the SQS script to be executed by cron every `N` minutes. When the SQS polling script detects a message, it will trigger the second script.

## Pushover Notifications
If you don't want to implement Pushover notifications upon reattachment, remove or comment out all the `curl` commands. Or adapt them to your own notifications.

## EIP Attachment Workflow
1. Upon a scale-out event of your ASG (Auto-Scaling Group) new instances are added as necessary. The EIP remains unaffected and in-use.
2. Upon a scale-in event of your ASG, when instances are terminated, the script will assist you by ensuring the EIP continues to be attached to a healthy, active EC2 instance. The `termination` ASG notification will create a message in the SQS queue.
3. The SQS polling script, which checks for messages every `N` seconds/minutes, when it discovers the message waiting for pickup, triggers the secondary script.
4. Finally, the fixed-ip script examines the ELB for healthy (remaining) instances and reattaches the EIP if necessary. After completion it both removes the SQS message and sends a Pushover notification via `curl`.

# aws-elb-consistent-eip
Keep an elastic IP consistently attached to a node within an auto-scaling group behind an ELB. 

A typical use-case for these scripts is a large, multi-site web deployment where many/most domains can be mapped to an ELB (using Route53 aliases to zone apexes), but where some domains still require DNS to point to a fixed public IP address. When deploying you should keep in mind that sites pointing directly to the EIP will put a specific EC2 instance under load and will not be sifted evenly across healthy nodes of your ELB/ASG.

## Requirements
Software:
  - AWS-CLI - http://aws.amazon.com/cli/
  - jq - http://stedolan.github.io/jq/
  - Pushover API token/user (optional) - https://pushover.net/

AWS Resources:
  - AWS EC2 autoscaling group (ASG)
  - AWS SQS queue
  - AWS EC2 elastic IP

## SQS Queue Setup
  - Create an SQS queue and set the `Default Visibility Timeout` to 30 seconds. This script uses SQS "long polling" which means it will continue to poll for a response for 20 seconds. That leaves a smaller window open to when a message will arrive before it is detected.
  - `Message Retention Period` can be set to something short, 15 mins will work well. These messages are designed to be picked up and acted upon within very short order, then deleted.
  - `Receive Message Wait Time` should be set to `0`

## EC2 Auto-Scaling Setup
  - Create your Launch Configuration and Auto-Scaling Group as you normally would.
  - In the `Notification` properties of your Auto-Scaling Group, create a notification to be sent whenever an instance is terminated. The notification should be pointed to the SQS queue you create above.

## Script Installation
  - Install both scripts on a separate, "neutral," server outside of your auto-scaling group. Install them into a directory such as `/root/scripts/`. (Search the scripts for this path and replace accordingly.)
  - Be sure your full path to the 'aws' executable is used in the scripts. This is often `/usr/bin/aws`
  - Also be sure that the `jq` binary is loaded. (`apt-get install jq` or `yum install jq`.)
  - If you use AWS CLI profiles, specify your profile as needed in the variable.
  - Configure all static variables at the top of each script.
  - Set the SQS script to be executed by cron every `N` minutes. When the SQS polling script detects a message, it will trigger the second script. `N` should be set according to the urgency/priority of your application. (Every 1 minute for production systems, higher for less-importance.)

## EIP Attachment Workflow
1. Upon a scale-out event of your ASG (Auto-Scaling Group) new instances are added as necessary. The EIP remains unaffected and in-use.
2. Upon a scale-in event of your ASG, when instances are terminated, the script will assist you by ensuring the EIP continues to be attached to a healthy, active EC2 instance. The `termination` ASG notification will create a message in the SQS queue.
3. The SQS polling script, which checks for messages every `N` seconds/minutes, when it discovers the message waiting for pickup, triggers the secondary script.
4. Finally, the fixed-ip script examines the ELB for healthy (remaining) instances and reattaches the EIP if necessary. After completion it both removes the SQS message and sends a Pushover notification via `curl`.

## Pushover Notifications
If you don't want to implement Pushover notifications upon reattachment, remove or comment out all the `curl` commands. Or adapt them to your own notifications.
For more information on Pushover, see https://pushover.net/

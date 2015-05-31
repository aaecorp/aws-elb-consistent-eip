#!/bin/bash

set -e

# --------------------------------------------------------------------------------------------
# This script written by Neal Magee <neal.magee@aaec.net> - ver 1.2 4/10/2015
# --------------------------------------------------------------------------------------------
# Polling script using the AWS CLI to check for healthy nodes in an auto-scaling group,
# and then either verify that a healthy node has the 1.2.3.4 elastic IP, or attach
# it to the first healthy node it finds.
# --------------------------------------------------------------------------------------------

# SET THE VARIABLES BELOW
eip="1.2.3.4"
eipallocation="eipalloc-12345678"
hostname=""
simpledate=`date +%Y%m%d`
awsprofile="default"
asgroup="MY-AS-GROUP"
pushovertoken=""
pushoveruser""
# --------------------------------------------------------------------------------------------

# Query for node 0 in the ASG and get its health status
node0health=`/usr/bin/aws --profile $awsprofile autoscaling describe-auto-scaling-groups --auto-scaling-group-names $asgroup | jq -r .AutoScalingGroups[0].Instances[0].HealthStatus`

# If Node0 is healthy then assess it's public IP
if [ "$node0health" == "Healthy" ]; then
    echo "Node0 is healthy."
    # Node0 is healthy. Check for IP attachment. Get the Instance ID from the autoscaling group, followed by it's public IP.
    node0id=`/usr/bin/aws --profile $awsprofile autoscaling describe-auto-scaling-groups --auto-scaling-group-names $asgroup | jq -r .AutoScalingGroups[0].Instances[0].InstanceId`
    node0ip=`/usr/bin/aws --profile $awsprofile ec2 describe-instances --instance-ids $node0id | jq -r .Reservations[0].Instances[0].PublicIpAddress`
    # Now compare for fixed EIP
    if [ "$node0ip" == "$eip" ]; then
        # Do something with a match
        echo "The IP of Node0 is $node0ip. Nothing else to do."
        exit 0
    else
        # Get the network interface ID for this instance. Next attach it to the public IP. Finally, notify Neal via Pushover alert.
        node0interface=`/usr/bin/aws --profile $awsprofile ec2 describe-instances --instance-ids $node0id | jq -r .Reservations[0].Instances[0].NetworkInterfaces[0].NetworkInterfaceId`
        /usr/bin/aws --profile $awsprofile ec2 associate-address --instance-id $node0id --allocation-id $eipallocation --network-interface-id $node0interface --allow-reassociation
        /usr/bin/aws --profile $awsprofile ec2 create-tags --resources $node0id --tags "Key=Name,Value=$hostname-$simpledate"
        curl -s -F "token=$pushovertoken" -F "user=$pushoveruser" -F "title=EIP reattached - `date`" -F "message=$eip has been attached to $node0id" -F "priority=1" https://api.pushover.net/1/messages
        exit 0
    fi
else
    echo "Node0 is unhealthy."
    # If Node0 is unhealthy, move on to Node1 and assess it's public IP
    node1id=`/usr/bin/aws --profile $awsprofile autoscaling describe-auto-scaling-groups --auto-scaling-group-names $asgroup | jq -r .AutoScalingGroups[0].Instances[1].InstanceId`
    node1ip=`/usr/bin/aws --profile $awsprofile ec2 describe-instances --instance-ids $node1id | jq -r .Reservations[0].Instances[0].PublicIpAddress`
    # Now compare for fixed IP
    if [ "$node1ip" == "$eip" ]; then
        # Do something with a match
        echo "The IP of Node1 is $node1ip. Nothing else to do."
        exit 0
    else
        node1interface=`/usr/bin/aws --profile $awsprofile ec2 describe-instances --instance-ids $node1id | jq -r .Reservations[0].Instances[0].NetworkInterfaces[0].NetworkInterfaceId`
        /usr/bin/aws --profile $awsprofile ec2 associate-address --instance-id $node1id --allocation-id $eipallocation --network-interface-id $node1interface --allow-reassociation
        /usr/bin/aws --profile $awsprofile ec2 create-tags --resources $node1id --tags "Key=Name,Value=$hostname-$simpledate"
        curl -s -F "token=$pushovertoken" -F "user=$pushoveruser" -F "title=EIP reattached - `date`" -F "message=$eip has been attached to $node1id" -F "priority=1" https://api.pushover.net/1/messages
    fi
fi

exit 0

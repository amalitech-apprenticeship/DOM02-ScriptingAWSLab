#!/usr/bin/env bash
umask 007

aws ec2 create-key-pair \
    --key-name amali-ec2-pair \
    --key-type rsa \
    --key-format pem \
    --query "KeyMaterial" \
    --output text > amali-ec2-pair.pem

INSTANCE_ID=$(aws ec2 run-instances \
    --image-id ami-0de30382cb1cd23c7 \
    --count 1 \
    --instance-type t2.micro \
    --key-name amali-ec2-pair \
    --query 'Instances[0].InstanceId' \
    --output text) || exit 1

aws ec2 create-tags \
    --resources "$INSTANCE_ID" \
    --tags Key=Project,Value=AutomationLab || exit 1

echo "Instance successfully tagged"

echo "Waiting for the instance to start ... "
aws ec2 wait instance-running \
    --instance-ids "$INSTANCE_ID" || exit 1

PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text) || exit 1

echo "Instance Up and Running!"
echo "Instance Id : $INSTANCE_ID"
echo "Public IP : $PUBLIC_IP"




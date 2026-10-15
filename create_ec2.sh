#!/usr/bin/env bash

if [[ ! -f .env ]]; then
    echo "[ERROR]: .env file not found"
    exit 1
fi

source .env


umask 007

aws ec2 create-key-pair \
    --key-name amali-ec2-pair \
    --key-type rsa \
    --key-format pem \
    --query "KeyMaterial" \
    --output text > amali-ec2-pair.pem

SUBNET_ID=$(aws ec2 create-subnet \
    --vpc-id "$VPC_ID" \
    --cidr-block 10.0.0.0/24 \
    --query 'Subnet.SubnetId' \
    --output text) || exit 1

echo "Subnet created with ID: $SUBNET_ID"

aws ec2 create-tags \
    --resources "$SUBNET_ID" \
    --tags Key=Project,Value=AutomationLab

aws ec2 associate-route-table \
    --subnet-id "$SUBNET_ID" \
    --route-table-id "$RT_ID"

INSTANCE_ID=$(aws ec2 run-instances \
    --image-id ami-0de30382cb1cd23c7 \
    --count 1 \
    --instance-type t3.micro \
    --subnet-id "$SUBNET_ID" \
    --key-name amali-ec2-pair \
    --associate-public-ip-address \
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
echo "INSTANCE_ID:$INSTANCE_ID"
echo "PUBLIC_IP:$PUBLIC_IP"




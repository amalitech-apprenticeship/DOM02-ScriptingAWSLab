#!/usr/bin/env bash

if [[ ! -f .env ]]; then
    echo "[ERROR]: .env file not found"
    exit 1
fi

source .env

SG_ID=$(aws ec2 create-security-group \
    --group-name scripting \
    --description "security group for the scripting lab" \
    --vpc-id "$VPC_ID" \
    --query 'GroupId' \
    --output text) || exit 1

echo "SG_ID:$SG_ID"

aws ec2 create-tags \
    --resources "$SG_ID" \
    --tags Key=Project,Value=AutomationLab

SG_RULES=$(aws ec2 authorize-security-group-ingress \
    --group-id "$SG_ID" \
    --ip-permissions 'IpProtocol=tcp,FromPort=80,ToPort=80,IpRanges=[{CidrIp=0.0.0.0/0}]' 'IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=0.0.0.0/0}]' \
    --query 'SecurityGroupRules' \
    --output text) || exit 1

echo "Security Group Rules Updated"
echo "SG_RULES:$SG_RULES"

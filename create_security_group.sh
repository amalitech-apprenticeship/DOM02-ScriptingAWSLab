#!/usr/bin/env bash

#Create a VPC Group for the Security group
VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/24 \
    --query 'Vpc.VpcId' \
    --output text) || exit 1

echo "VPC Created"

SG_ID=$(aws ec2 create-security-group \
    --group-name scripting \
    --description "security group for the scripting lab" \
    --vpc-id "$VPC_ID" \
    --query 'GroupId' \
    --output text) || exit 1

echo "Security Group Created $SG_ID"

SG_RULES=$(aws ec2 authorize-security-group-ingress \
    --group-id "$SG_ID" \
    --ip-permissions 'IpProtocol=tcp,FromPort=80,ToPort=80,IpRanges=[{CidrIp=0.0.0.0/0}]' 'IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=0.0.0.0/0}]' \
    --query 'SecurityGroupRules' \
    --output text) || exit 1

echo "Security Group Rules Updated"
echo "$SG_RULES"

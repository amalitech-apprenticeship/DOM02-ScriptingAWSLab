#!/usr/bin/env bash

VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 \
    --query 'Vpc.VpcId' \
    --output text) || exit 1

echo "VPC Created with ID: $VPC_ID"

aws ec2 create-tags \
    --resources "$VPC_ID" \
    --tags Key=Project,Value=AutomationLab

IGW_ID=$(aws ec2 create-internet-gateway \
    --query 'InternetGateway.InternetGatewayId' \
    --output text) || exit 1

aws ec2 attach-internet-gateway \
    --vpc-id "$VPC_ID" \
    --internet-gateway-id "$IGW_ID"

aws ec2 create-tags \
    --resources "$IGW_ID" \
    --tags Key=Project,Value=AutomationLab

RT_ID=$(aws ec2 create-route-table \
    --vpc-id "$VPC_ID" \
    --query 'RouteTable.RouteTableId' \
    --output text) || exit 1

aws ec2 create-route \
    --route-table-id "$RT_ID" \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id "$IGW_ID"

aws ec2 create-tags \
    --resources "$RT_ID" \
    --tags Key=Project,Value=AutomationLab

echo "Network Setup Completed!"
echo "Add these to your .env file:"
echo "VPC_ID=$VPC_ID"
echo "IGW_ID=$IGW_ID"
echo "RT_ID=$RT_ID"
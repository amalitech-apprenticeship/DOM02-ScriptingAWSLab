#!/usr/bin/env bash
set -euo pipefail
# 1. Source environment variables or set defaults
if [[ -f .env ]]; then
    source .env
fi

FILTER_KEY="tag:${T1_KEY}"
T1_VALUE="${T1_VALUE:-AutomationLab}"
KEY_NAME="${KEY_NAME:-amali-ec2-pair}"

echo "Using Tag Filter: Key=${FILTER_KEY}, Value=${T1_VALUE}"

#----------------------------------------------------------------------
INSTANCE_IDS=$(aws ec2 describe-instances \
    --filters "Name=$FILTER_KEY,Values=$T1_VALUE" \
              "Name=instance-state-name,Values=pending,running,stopping,stopped" \
    --query 'Reservations[].Instances[].InstanceId' \
    --output text)

VPC_IDS=$(aws ec2 describe-vpcs \
    --filters "Name=$FILTER_KEY,Values=$T1_VALUE" \
    --query 'Vpcs[].VpcId' \
    --output text)

SUBNET_IDS=$(aws ec2 describe-subnets \
    --filters "Name=$FILTER_KEY,Values=$T1_VALUE" \
    --query 'Subnets[].SubnetId' \
    --output text)

SG_IDS=$(aws ec2 describe-security-groups \
    --filters "Name=$FILTER_KEY,Values=$T1_VALUE" \
    --query 'SecurityGroups[].GroupId' \
    --output text)

RT_IDS=$(aws ec2 describe-route-tables \
    --filters "Name="$FILTER_KEY",Values=$T1_VALUE" \
    --query 'RouteTables[?Associations[0].Main!=`true`].RouteTableId' \
    --output text)

IGW_IDS=$(aws ec2 describe-internet-gateways \
    --filters "Name="$FILTER_KEY",Values=$T1_VALUE" \
    --query 'InternetGateways[].InternetGatewayId' \
    --output text)


echo "EC2 instances: $INSTANCE_IDS"
echo "VPCs:          $VPC_IDS"
echo "Subnets:       $SUBNET_IDS"
echo "Security Groups:   $SG_IDS"
echo "IGWs:          $IGW_IDS"
echo "RTs:           $RT_IDS"
#------------------------------------------------------------------------------

delete_s3_buckets() {
    local BUCKET_NAMES

    BUCKET_NAMES=$(aws s3api list-buckets --query 'Buckets[].Name' --output text) || return 1

    for BUCKET in $BUCKET_NAMES; do
        local TAG_VAL
        TAG_VAL=$(aws s3api get-bucket-tagging --bucket "$BUCKET" \
            --query "TagSet[?Key=='$T1_KEY'].Value | [0]" \
            --output text 2>/dev/null)

        if [[ "$TAG_VAL" == "$T1_VALUE" ]]; then
            echo "Emptying versioned bucket: $BUCKET"
            
            
            aws s3api delete-objects --bucket "$BUCKET" --delete \
                "$(aws s3api list-object-versions --bucket "$BUCKET" \
                   --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' --output json)" 2>/dev/null

            aws s3api delete-objects --bucket "$BUCKET" --delete \
                "$(aws s3api list-object-versions --bucket "$BUCKET" \
                   --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' --output json)" 2>/dev/null

            echo "Deleting bucket: $BUCKET"
            aws s3api delete-bucket --bucket "$BUCKET" && echo "Successfully deleted $BUCKET"
        fi
    done
}

terminate_all_resources() {

    if [[ -n "$INSTANCE_IDS" && "$INSTANCE_IDS" != "None" ]]; then
        echo "Terminating EC2 instances..."
        aws ec2 terminate-instances --instance-ids $INSTANCE_IDS
        aws ec2 wait instance-terminated --instance-ids $INSTANCE_IDS
        echo "EC2 instances terminated."
    fi

    aws ec2 delete-key-pair --key-name "$KEY_NAME" 2>/dev/null && rm -f "$KEY_NAME.pem"

    if [[ -n "$SUBNET_IDS" && "$SUBNET_IDS" != "None" ]]; then
        for id in $SUBNET_IDS; do
            aws ec2 delete-subnet --subnet-id "$id" && echo "Deleted subnet: $id"
        done
    fi

    if [[ -n "$SG_IDS" && "$SG_IDS" != "None" ]]; then
        for id in $SG_IDS; do
            aws ec2 delete-security-group --group-id "$id" && echo "Deleted security group: $id"
        done
    fi

    if [[ -n "$RT_IDS" && "$RT_IDS" != "None" ]]; then
        for rt in $RT_IDS; do
            aws ec2 delete-route-table --route-table-id "$rt" && echo "Deleted Route Table: $rt"
        done
    fi

    if [[ -n "$IGW_IDS" && "$IGW_IDS" != "None" ]]; then
        for igw in $IGW_IDS; do
            for vpc in $VPC_IDS; do
                aws ec2 detach-internet-gateway --internet-gateway-id "$igw" --vpc-id "$vpc" 2>/dev/null
            done
            sleep 5
            aws ec2 delete-internet-gateway --internet-gateway-id "$igw" && echo "Deleted IGW: $igw"
        done
    fi

    if [[ -n "$VPC_IDS" && "$VPC_IDS" != "None" ]]; then
        for id in $VPC_IDS; do
            aws ec2 delete-vpc --vpc-id "$id" && echo "Deleted VPC: $id"
        done
    fi

    delete_s3_buckets
}

terminate_all_resources
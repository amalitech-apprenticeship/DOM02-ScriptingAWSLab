#!/usr/bin/env bash

if [[ ! -f .env ]]; then
    echo "[ERROR]: .env file not found"
    exit 1
fi

source .env

BUCKET_ID="amali-aman-s3-$RANDOM"

S3_LOC=$(aws s3api create-bucket \
    --bucket "$BUCKET_ID" \
    --region "$REGION" \
    --create-bucket-configuration LocationConstraint="$REGION" \
    --query 'Location' ) || exit 1

aws s3api put-bucket-versioning \
    --bucket "$BUCKET_ID" \
    --versioning-configuration Status=Enabled

aws s3api put-bucket-tagging \
    --bucket "$BUCKET_ID" \
    --tagging 'TagSet=[{Key=Project,Value=AutomationLab}]'

cat <<EOF > welcome.txt
Hi! Welcome to the Automation Lab.
Have a great day! :)
EOF

aws s3 cp welcome.txt "s3://$BUCKET_ID/welcome.txt"

echo "S3 Bucket provisioned"
echo "BUCKET_ID:$BUCKET_ID"
echo "S3_LOC:$S3_LOC"
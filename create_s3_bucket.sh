#!/usr/bin/env bash

BUCKET_ID="amali-aman-s3-$RANDOM"

S3_LOC=$(aws s3api create-bucket \
    --bucket "$BUCKET_ID" \
    --region eu-west-1 \
    --create-bucket-configuration LocationConstraint=eu-west-1 \
    --query 'Location' \) || exit 1

aws s3api put-bucket-versioning \
    --bucket "$BUCKET_ID" \
    --versioning-configuration Status=Enabled

aws s3api put-bucket-tagging \
    --bucket "$BUCKET_ID" \
    --tagging 'TagSet=[{Key=Project=AutomationLab}]'

cat <<EOF > welcome.txt
Hi! Welcome to the Automation Lab.
Have a great day! :)
EOF

aws s3 cp welcome.txt "$S3_LOC"
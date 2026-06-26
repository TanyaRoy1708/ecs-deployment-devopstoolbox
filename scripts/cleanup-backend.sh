#!/bin/bash
REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="ecs-project-tfstate-${ACCOUNT_ID}"
TABLE_NAME="terraform-state-lock"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${SCRIPT_DIR}/../terraform"

echo "Cleaning up Terraform Remote State infrastructure..."

# 1. Delete DynamoDB table
if aws dynamodb describe-table --table-name "$TABLE_NAME" --region "$REGION" > /dev/null 2>&1; then
    echo "Deleting DynamoDB table: $TABLE_NAME..."
    aws dynamodb delete-table --table-name "$TABLE_NAME" --region "$REGION" > /dev/null
else
    echo "DynamoDB table $TABLE_NAME does not exist, skipping."
fi

# 2. Empty and delete S3 Bucket
if aws s3api head-bucket --bucket "$BUCKET_NAME" > /dev/null 2>&1; then
    echo "Emptying S3 bucket (including all versions and delete markers): $BUCKET_NAME..."
    
    # Delete all versions
    VERSIONS=$(aws s3api list-object-versions --bucket "$BUCKET_NAME" --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}' --output json)
    if [ "$VERSIONS" != "null" ] && [ "$VERSIONS" != "{}" ] && echo "$VERSIONS" | grep -q "Key"; then
        aws s3api delete-objects --bucket "$BUCKET_NAME" --delete "$VERSIONS" > /dev/null
    fi
    
    # Delete all delete markers
    MARKERS=$(aws s3api list-object-versions --bucket "$BUCKET_NAME" --query='{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' --output json)
    if [ "$MARKERS" != "null" ] && [ "$MARKERS" != "{}" ] && echo "$MARKERS" | grep -q "Key"; then
        aws s3api delete-objects --bucket "$BUCKET_NAME" --delete "$MARKERS" > /dev/null
    fi
    
    echo "Deleting S3 bucket: $BUCKET_NAME..."
    aws s3 rb "s3://$BUCKET_NAME" --force > /dev/null
else
    echo "S3 bucket $BUCKET_NAME does not exist, skipping."
fi

# 3. Remove local backend configuration and cache
if [ -f "${TERRAFORM_DIR}/backend.tf" ]; then
    echo "Removing generated ${TERRAFORM_DIR}/backend.tf..."
    rm "${TERRAFORM_DIR}/backend.tf"
fi

if [ -d "${TERRAFORM_DIR}/.terraform" ]; then
    echo "Removing local .terraform directory cache..."
    rm -rf "${TERRAFORM_DIR}/.terraform"
fi

echo ""
echo "Cleanup complete!"
echo "--------------------------------------------------------"
echo "Note: If you plan to deploy again, you will need to run:"
echo "./scripts/bootstrap-backend.sh"
echo "--------------------------------------------------------"

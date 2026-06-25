#!/bin/bash
set -e

REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="ecs-project-tfstate-${ACCOUNT_ID}"
TABLE_NAME="terraform-state-lock"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${SCRIPT_DIR}/../terraform"

echo "Bootstrapping Terraform Remote State..."

# 1. Create S3 Bucket (if it doesn't exist)
if ! aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo "Creating S3 bucket: $BUCKET_NAME..."
    aws s3 mb "s3://$BUCKET_NAME" --region "$REGION"
    aws s3api put-bucket-versioning --bucket "$BUCKET_NAME" --versioning-configuration Status=Enabled
else
    echo "S3 bucket $BUCKET_NAME already exists."
fi

# 2. Create DynamoDB Table (if it doesn't exist)
if ! aws dynamodb describe-table --table-name "$TABLE_NAME" --region "$REGION" 2>/dev/null; then
    echo "Creating DynamoDB table: $TABLE_NAME..."
    aws dynamodb create-table \
        --table-name "$TABLE_NAME" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "$REGION" > /dev/null
else
    echo "DynamoDB table $TABLE_NAME already exists."
fi

# 3. Generate terraform/backend.tf from template (backend.tf is gitignored)
TEMPLATE="${TERRAFORM_DIR}/backend.tf.example"
OUTPUT="${TERRAFORM_DIR}/backend.tf"

if [ ! -f "$TEMPLATE" ]; then
    echo "ERROR: $TEMPLATE not found. Cannot generate backend.tf."
    exit 1
fi

sed "s/<ACCOUNT_ID>/${ACCOUNT_ID}/g" "$TEMPLATE" > "$OUTPUT"
echo "Generated ${OUTPUT} with bucket: ${BUCKET_NAME}"
echo "Note: backend.tf is gitignored — your Account ID will not be committed."

echo ""
echo "Bootstrap complete!"
echo "--------------------------------------------------------"
echo "Next step: cd terraform && terraform init"
echo "--------------------------------------------------------"

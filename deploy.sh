#!/bin/bash
set -eo pipefail

# Configuration
PROJECT_NAME="fruit-disease-detection"
REGION="us-east-1" # IMPORTANT: Change this to your preferred AWS region where Bedrock is available
STAGE="dev"
# Ensure S3_BUCKET is globally unique if you don't use SAM managed default
# If you want SAM to create/use a default bucket, you can remove S3_BUCKET or it will be defined in samconfig.toml
# S3_BUCKET="your-unique-sam-deployment-bucket-name" # Replace with your S3 bucket for SAM artifacts
TIMESTAMP=$(date +%Y%m%d%H%M%S)
STACK_NAME="${PROJECT_NAME}-${STAGE}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Display banner
echo -e "${GREEN}===================================================${NC}"
echo -e "${GREEN}   Fruit Disease Detection Deployment Script       ${NC}"
echo -e "${GREEN}===================================================${NC}"

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"
command -v aws >/dev/null 2>&1 || { echo -e "${RED}AWS CLI not installed. Aborting.${NC}"; exit 1; }
command -v sam >/dev/null 2>&1 || { echo -e "${RED}SAM CLI not installed. Aborting.${NC}"; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo -e "${RED}Python 3 not installed. Aborting.${NC}"; exit 1; }
command -v docker >/dev/null 2>&1 || { echo -e "${RED}Docker not installed or not running. Aborting.${NC}"; exit 1; }
docker info >/dev/null 2>&1 || { echo -e "${RED}Docker daemon is not running. Please start Docker. Aborting.${NC}"; exit 1; }


# Check AWS credentials
echo -e "${YELLOW}Validating AWS credentials...${NC}"
aws sts get-caller-identity --query "Account" --output text > /dev/null || { echo -e "${RED}Invalid AWS credentials or insufficient permissions. Please run 'aws configure' or check your IAM user/role permissions.${NC}"; exit 1; }
echo -e "${GREEN}AWS credentials validated for account: $(aws sts get-caller-identity --query "Account" --output text)${NC}"


# Create boto3 layer
echo -e "${YELLOW}Creating boto3 layer for Bedrock compatibility...${NC}"
chmod +x ./create_boto3_layer.sh
./create_boto3_layer.sh || { echo -e "${RED}Boto3 layer creation failed. Aborting.${NC}"; exit 1; }

# Validate SAM template
echo -e "${YELLOW}Validating SAM template (template.yaml)...${NC}"
sam validate --template-file template.yaml --region ${REGION} || { echo -e "${RED}SAM template validation failed. Aborting.${NC}"; exit 1; }

# Build the application
echo -e "${YELLOW}Building the application using SAM...${NC}"
# --use-container is important to build in a Lambda-like environment
sam build --use-container || { echo -e "${RED}SAM build failed. Aborting.${NC}"; exit 1; }

# Deploy the application
echo -e "${YELLOW}Deploying the application using SAM...${NC}"
# Using samconfig.toml is preferred, but you can override here
sam deploy \
    --stack-name ${STACK_NAME} \
    --capabilities CAPABILITY_IAM \
    --resolve-s3 \
    --parameter-overrides \
        ProjectName=${PROJECT_NAME} \
        Stage=${STAGE} \
    --region ${REGION} \
    --no-fail-on-empty-changeset \
    --config-file samconfig.toml \
    --confirm-changeset # Remove --confirm-changeset for fully non-interactive, or use --no-confirm-changeset
    # If your samconfig.toml is well-defined, you might just need:
    # sam deploy --config-file samconfig.toml --region ${REGION}

# Get the API endpoint
echo -e "${YELLOW}Fetching API endpoint from CloudFormation stack outputs...${NC}"
API_ENDPOINT=$(aws cloudformation describe-stacks \
    --stack-name ${STACK_NAME} \
    --query "Stacks[0].Outputs[?OutputKey=='ApiEndpoint'].OutputValue" \
    --output text \
    --region ${REGION})

if [ -z "${API_ENDPOINT}" ] || [ "${API_ENDPOINT}" == "None" ]; then
    echo -e "${RED}Could not retrieve API Endpoint. Please check the CloudFormation stack outputs in the AWS console.${NC}"
else
    echo -e "${GREEN}===================================================${NC}"
    echo -e "${GREEN}Deployment completed successfully!${NC}"
    echo -e "${GREEN}API Endpoint: ${API_ENDPOINT}${NC}"
    echo -e "${GREEN}===================================================${NC}"

    # Create a sample test script
    echo -e "${YELLOW}Creating test script (test_api.sh)...${NC}"
cat > test_api.sh << EOF

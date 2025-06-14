# Fruit Disease Detection API using AWS Bedrock

This project implements a serverless API to detect diseases in fruits using AWS Bedrock and the Claude 3.5 Sonnet model.

## Prerequisites
- AWS CLI
- AWS SAM CLI
- Python 3.9+
- Docker
- Git

## Setup
1. Clone the repository.
2. Ensure prerequisites are installed and AWS CLI is configured.
3. Update `REGION` in `deploy.sh` and `samconfig.toml` if needed.
4. Update `MODEL_ID` in `template.yaml` and `src/lambda_function.py` to the desired Claude model available in your Bedrock.
5. Create an S3 bucket for SAM deployments and update `s3_bucket` in `samconfig.toml` or ensure SAM can create/use its default.

## Deployment
Make the deployment script executable and run it:
\`\`\`bash
chmod +x deploy.sh
./deploy.sh
\`\`\`

## Testing
After deployment, a `test_api.sh` script will be generated.
Make it executable and run it with an image file:
\`\`\`bash
chmod +x test_api.sh
./test_api.sh path/to/your/fruit_image.jpg
\`\`\`





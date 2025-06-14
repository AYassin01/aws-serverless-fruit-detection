import json
import base64
import boto3
import logging
import os

# Configure logging
logger = logging.getLogger()
logger.setLevel(os.environ.get('LOG_LEVEL', 'INFO'))

# Initialize Bedrock client
bedrock = boto3.client('bedrock-runtime')

# Use Claude 4 Sonnet
MODEL_ID = os.environ.get('MODEL_ID', 'anthropic.claude-4-sonnet-20240601-v1:0')

def lambda_handler(event, context):
    try:
        # Validate request body
        if 'body' not in event:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'No image provided'})
            }

        # Decode base64 image
        image_base64_string = event['body']
        image_data = base64.b64decode(image_base64_string)

        # Enhanced prompt focused on Oranges, Strawberries, and Mangoes
        prompt_text = """
You are a plant pathology expert. Analyze the attached fruit image and determine if there is a disease present.

Return a strictly formatted JSON response:
{
  "fruit_type": "orange/strawberry/mango",
  "disease_detected": true/false,
  "disease_name": "specific disease name or 'healthy'",
  "confidence": float between 0.0 and 1.0,
  "severity": "none/mild/moderate/severe",
  "treatment_recommendations": ["treatment 1", "treatment 2"]
}

Focus only on these fruits and associated diseases:

- **Oranges**
  - black spot
  - citrus canker
  - greening disease

- **Strawberries**
  - gray mold
  - leaf spot
  - powdery mildew

- **Mangoes**
  - anthracnose
  - powdery mildew

If the fruit is healthy, set:
  - "disease_detected": false
  - "disease_name": "healthy"
  - "severity": "none"
  - "treatment_recommendations": []

Respond in clear, compact JSON. No explanation or extra text.
"""

        # Call Claude 4 Sonnet model through Bedrock
        response = bedrock.invoke_model(
            modelId=MODEL_ID,
            body=json.dumps({
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": 1000,
                "messages": [{
                    "role": "user",
                    "content": [
                        {
                            "type": "image",
                            "source": {
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": base64.b64encode(image_data).decode('utf-8')
                            }
                        },
                        {
                            "type": "text",
                            "text": prompt_text
                        }
                    ]
                }]
            }),
            contentType='application/json',
            accept='application/json'
        )

        # Extract and return model's JSON response
        result = json.loads(response['body'].read())
        model_response_content = result['content'][0]['text']

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': model_response_content
        }

    except Exception as e:
        logger.error(f"Error processing image: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }

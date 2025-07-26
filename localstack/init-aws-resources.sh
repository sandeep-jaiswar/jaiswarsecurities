#!/bin/bash

# Initialize AWS resources in LocalStack using CloudFormation
echo "Initializing AWS resources in LocalStack using CloudFormation..."

# Set AWS CLI to use LocalStack
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
export AWS_ENDPOINT_URL=http://localhost:4566

# Wait for LocalStack to be ready
echo "Waiting for LocalStack to be ready..."
until curl -s http://localhost:4566/health | grep -q "running"; do
  echo "Waiting for LocalStack..."
  sleep 5
done

echo "LocalStack is ready!"

# Deploy CloudFormation stack
echo "Deploying CloudFormation stack..."
aws --endpoint-url=http://localhost:4566 cloudformation create-stack \
  --stack-name stock-screening-infrastructure \
  --template-body file:///etc/localstack/init/ready.d/../../../cloudformation/infrastructure.yaml \
  --parameters ParameterKey=Environment,ParameterValue=development \
  --capabilities CAPABILITY_NAMED_IAM

# Wait for stack creation
echo "Waiting for CloudFormation stack creation..."
aws --endpoint-url=http://localhost:4566 cloudformation wait stack-create-complete \
  --stack-name stock-screening-infrastructure

# Get stack outputs
echo "Getting stack outputs..."
aws --endpoint-url=http://localhost:4566 cloudformation describe-stacks \
  --stack-name stock-screening-infrastructure \
  --query 'Stacks[0].Outputs'

echo "AWS resources initialized successfully!"

#!/bin/bash

# Initialize AWS resources in LocalStack
echo "Initializing AWS resources in LocalStack..."

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

# Create S3 buckets
echo "Creating S3 buckets..."
aws --endpoint-url=http://localhost:4566 s3 mb s3://stock-data-bucket
aws --endpoint-url=http://localhost:4566 s3 mb s3://stock-backups-bucket

# Create SQS queues
echo "Creating SQS queues..."
aws --endpoint-url=http://localhost:4566 sqs create-queue --queue-name data-ingestion-queue
aws --endpoint-url=http://localhost:4566 sqs create-queue --queue-name data-ingestion-dlq
aws --endpoint-url=http://localhost:4566 sqs create-queue --queue-name backtesting-queue
aws --endpoint-url=http://localhost:4566 sqs create-queue --queue-name backtesting-dlq

# Create SNS topics
echo "Creating SNS topics..."
aws --endpoint-url=http://localhost:4566 sns create-topic --name stock-alerts

# Create CloudWatch log groups
echo "Creating CloudWatch log groups..."
aws --endpoint-url=http://localhost:4566 logs create-log-group --log-group-name /aws/application/stock-screening

# Deploy CloudFormation stack
echo "Deploying CloudFormation stack..."
aws --endpoint-url=http://localhost:4566 cloudformation create-stack \
  --stack-name stock-screening-infrastructure \
  --template-body file:///etc/localstack/init/ready.d/../../../cloudformation/infrastructure.yaml \
  --parameters ParameterKey=Environment,ParameterValue=development \
  --capabilities CAPABILITY_NAMED_IAM

echo "AWS resources initialized successfully!"
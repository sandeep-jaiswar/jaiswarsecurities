#!/bin/bash

set -e

echo "🚀 Deploying Stock Screening System to LocalStack..."

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '#' | xargs)
fi

# Wait for LocalStack to be ready
echo "⏳ Waiting for LocalStack to be ready..."
until curl -s http://localhost:4566/health | grep -q "running"; do
    echo "Waiting for LocalStack..."
    sleep 5
done

echo "✅ LocalStack is ready!"

# Set AWS CLI configuration for LocalStack
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
export AWS_ENDPOINT_URL=http://localhost:4566

# Create S3 buckets
echo "📦 Creating S3 buckets..."
aws --endpoint-url=http://localhost:4566 s3 mb s3://stock-data-bucket || true
aws --endpoint-url=http://localhost:4566 s3 mb s3://stock-backups-bucket || true

# Create SQS queues
echo "📨 Creating SQS queues..."
aws --endpoint-url=http://localhost:4566 sqs create-queue --queue-name data-ingestion-queue || true
aws --endpoint-url=http://localhost:4566 sqs create-queue --queue-name data-ingestion-dlq || true
aws --endpoint-url=http://localhost:4566 sqs create-queue --queue-name backtesting-queue || true
aws --endpoint-url=http://localhost:4566 sqs create-queue --queue-name backtesting-dlq || true

# Create SNS topics
echo "📢 Creating SNS topics..."
aws --endpoint-url=http://localhost:4566 sns create-topic --name stock-alerts || true

# Create CloudWatch log groups
echo "📊 Creating CloudWatch log groups..."
aws --endpoint-url=http://localhost:4566 logs create-log-group --log-group-name /aws/application/stock-screening || true

# Deploy CloudFormation stack
echo "☁️ Deploying CloudFormation stack..."
aws --endpoint-url=http://localhost:4566 cloudformation create-stack \
  --stack-name stock-screening-infrastructure \
  --template-body file://cloudformation/infrastructure.yaml \
  --parameters ParameterKey=Environment,ParameterValue=development \
  --capabilities CAPABILITY_NAMED_IAM || true

# Wait for stack creation
echo "⏳ Waiting for CloudFormation stack creation..."
aws --endpoint-url=http://localhost:4566 cloudformation wait stack-create-complete \
  --stack-name stock-screening-infrastructure || true

# Get stack outputs
echo "📋 Getting stack outputs..."
aws --endpoint-url=http://localhost:4566 cloudformation describe-stacks \
  --stack-name stock-screening-infrastructure \
  --query 'Stacks[0].Outputs' || true

echo "✅ Deployment to LocalStack completed successfully!"
echo ""
echo "🔗 Access Points:"
echo "  - LocalStack Dashboard: http://localhost:4566"
echo "  - S3 Buckets: stock-data-bucket, stock-backups-bucket"
echo "  - SQS Queues: data-ingestion-queue, backtesting-queue"
echo "  - SNS Topic: stock-alerts"
echo ""
echo "💡 Use AWS CLI with --endpoint-url=http://localhost:4566 to interact with LocalStack services"
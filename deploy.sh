#!/bin/bash
set -e

echo "🚀 Deploying Datadog Azure Monitoring Demo..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check prerequisites
echo -e "${BLUE}Checking prerequisites...${NC}"

if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ Terraform is required but not installed${NC}"
    exit 1
fi

if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Azure CLI is required but not installed${NC}"
    exit 1
fi

# Check if logged in to Azure
if ! az account show &> /dev/null; then
    echo -e "${RED}❌ Not logged in to Azure CLI. Run 'az login' first${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Prerequisites check passed${NC}"

# Deploy infrastructure
echo -e "${BLUE}🏗️  Deploying infrastructure...${NC}"
terraform init
terraform plan -out=tfplan
terraform apply tfplan

# Get outputs
echo -e "${BLUE}📋 Getting deployment outputs...${NC}"
APP_SERVICE_NAME=$(terraform output -raw app_service_name)
RESOURCE_GROUP_NAME=$(terraform output -raw resource_group_name)
APP_URL=$(terraform output -raw app_service_url)

echo -e "${GREEN}Infrastructure deployed successfully!${NC}"
echo -e "App Service: ${APP_SERVICE_NAME}"
echo -e "Resource Group: ${RESOURCE_GROUP_NAME}"
echo -e "App URL: ${APP_URL}"

# Package and deploy application
echo -e "${BLUE}📦 Packaging Flask application...${NC}"
cd app
zip -r ../app.zip . -x "*.pyc" "__pycache__/*" "*.git*"
cd ..

echo -e "${BLUE}🚀 Deploying application to App Service...${NC}"
az webapp deployment source config-zip \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$APP_SERVICE_NAME" \
    --src app.zip

# Wait for deployment to complete
echo -e "${BLUE}⏳ Waiting for application to start...${NC}"
sleep 30

# Test the application
echo -e "${BLUE}🧪 Testing application health...${NC}"
if curl -f -s "${APP_URL}/health" > /dev/null; then
    echo -e "${GREEN}✅ Application is healthy!${NC}"
else
    echo -e "${YELLOW}⚠️  Application might still be starting up. Check manually.${NC}"
fi

# Clean up
rm -f app.zip tfplan

echo ""
echo -e "${GREEN}🎉 Deployment Complete!${NC}"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "1. Visit your application: ${APP_URL}"
echo "2. Test endpoints:"
echo "   - Health check: ${APP_URL}/health"
echo "   - List users: ${APP_URL}/users"
echo "   - Generate load: ${APP_URL}/load"
echo "3. Set up Datadog monitoring (see README.md)"
echo ""
echo -e "${YELLOW}💡 Run './cleanup.sh' when done to avoid charges${NC}"
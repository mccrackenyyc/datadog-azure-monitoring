#!/bin/bash
set -e

echo "🧹 Cleaning up Datadog Azure Monitoring Demo..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Confirm destruction
echo -e "${YELLOW}⚠️  This will destroy ALL resources created by this demo.${NC}"
echo -e "${YELLOW}This action cannot be undone!${NC}"
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [[ $confirm != "yes" ]]; then
    echo -e "${BLUE}Cleanup cancelled.${NC}"
    exit 0
fi

# Check if Terraform state exists
if [[ ! -f "terraform.tfstate" ]]; then
    echo -e "${RED}❌ No Terraform state file found. Nothing to clean up.${NC}"
    exit 1
fi

# Show what will be destroyed
echo -e "${BLUE}📋 Resources to be destroyed:${NC}"
terraform plan -destroy

echo ""
read -p "Proceed with destruction? (yes/no): " final_confirm

if [[ $final_confirm != "yes" ]]; then
    echo -e "${BLUE}Cleanup cancelled.${NC}"
    exit 0
fi

# Destroy infrastructure
echo -e "${BLUE}💥 Destroying infrastructure...${NC}"
terraform destroy -auto-approve

# Clean up local files
echo -e "${BLUE}🗑️  Cleaning up local files...${NC}"
rm -f terraform.tfstate*
rm -f tfplan
rm -f app.zip
rm -rf .terraform

echo -e "${GREEN}✅ Cleanup complete!${NC}"
echo ""
echo -e "${BLUE}All Azure resources have been destroyed.${NC}"
echo -e "${BLUE}Local state files have been removed.${NC}"
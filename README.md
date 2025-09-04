# Datadog Azure Monitoring Demo

Quick learning project to explore Datadog monitoring capabilities with real Azure infrastructure and applications.

## 🎯 Purpose

- Learn Datadog fundamentals through hands-on experience
- Compare Datadog to Azure Monitor/Application Insights
- Generate realistic monitoring data from actual workloads
- Practice observability concepts in a realistic but minimal setup

## 🏗️ Infrastructure

**Azure Resources:**
- **App Service** (Linux, Python Flask app) - generates application metrics
- **Azure SQL Database** (serverless) - generates database metrics
- **Storage Account** - generates storage metrics
- **Application Insights** - for comparison with Datadog

**Flask Application Endpoints:**
- `GET /` - Basic service info
- `GET /health` - Health check with database connectivity
- `GET /users` - List all users (database read)
- `POST /users` - Create new user (database write)
- `GET /load` - Generate CPU/memory load for testing
- `GET /metrics` - Custom application metrics

## ⚡ Quick Start

### Prerequisites
- Azure CLI installed and logged in (`az login`)
- Terraform >= 1.12 installed
- Bash shell (WSL on Windows)

### Deploy
```bash
chmod +x deploy.sh cleanup.sh
./deploy.sh
```

The script will:
1. Deploy Azure infrastructure with Terraform
2. Package and deploy the Flask application
3. Initialize the database with sample data
4. Test application health
5. Provide next steps for Datadog setup

### Test Application
After deployment, test these endpoints:
```bash
# Get your app URL from deploy script output
APP_URL="https://dam-app-api.azurewebsites.net"

# Test health
curl $APP_URL/health

# List users  
curl $APP_URL/users

# Create a user
curl -X POST $APP_URL/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com"}'

# Generate load for monitoring
curl $APP_URL/load
```

## 📊 Datadog Setup

### 1. Create Datadog Account
- Sign up for free trial at [datadoghq.com](https://www.datadoghq.com/)
- Get your API key from the Datadog dashboard

### 2. Install Datadog Agent on App Service
Add these app settings to your App Service via Azure portal:

```bash
DD_API_KEY=your_datadog_api_key
DD_SITE=datadoghq.com
DD_SERVICE=dam-flask-app
DD_VERSION=1.0.0
DD_ENV=dev
```

Then add Datadog Python library to your application (manual step for learning).

### 3. Configure Azure Integration
In Datadog dashboard:
1. Go to **Integrations → Azure**
2. Add your Azure subscription
3. Configure resource collection for your resource group

### 4. Create Dashboards
Suggested dashboards to create:
- **Application Performance**: Request latency, throughput, errors
- **Infrastructure**: CPU, memory, network for App Service
- **Database**: SQL connection pool, query performance
- **Custom Metrics**: User creation rate, health check status

## 🧹 Cleanup

**Important**: Run cleanup daily to avoid charges!

```bash
./cleanup.sh
```

This removes all Azure resources and local state files.

## 💰 Cost Optimization

All resources use free/low-cost tiers:
- **App Service**: F1 (Free tier)
- **SQL Database**: Serverless with auto-pause
- **Storage Account**: LRS (cheapest replication)
- **Application Insights**: Pay-per-use

Estimated daily cost: ~$1-2 USD when active, nearly $0 when auto-paused.

## 🔍 Learning Objectives

### Datadog Concepts to Explore
- [ ] Agent installation and configuration
- [ ] Service mapping and dependency visualization
- [ ] Custom metrics and dashboards
- [ ] Alert configuration and notification channels
- [ ] Log aggregation and analysis
- [ ] APM (Application Performance Monitoring) traces
- [ ] Infrastructure monitoring and host maps
- [ ] Azure integration setup and configuration

### Comparison Points with Azure Monitor
- [ ] Dashboard creation and customization
- [ ] Query languages (Datadog vs KQL)
- [ ] Alert management and escalation
- [ ] Cost differences and pricing models
- [ ] Integration capabilities and ease of setup
- [ ] Data retention and export options

## 📝 Generated Data Types

This setup produces realistic monitoring data:

**Application Metrics:**
- HTTP request rates and response times
- Error rates and status codes
- Custom business metrics (user creation rate)
- Application performance traces

**Infrastructure Metrics:**
- CPU and memory utilization
- Network I/O and disk usage
- App Service platform metrics

**Database Metrics:**
- Connection pool statistics
- Query execution times
- Database resource utilization

**Storage Metrics:**
- Blob storage operations
- Storage account performance

## 🛠️ Next Steps After Setup

1. **Explore Datadog UI**: Navigate dashboards, metrics explorer, APM
2. **Create Custom Dashboards**: Build monitoring views for your use case
3. **Set Up Alerts**: Configure notifications for key metrics
4. **Compare with Azure Monitor**: Use both tools side-by-side
5. **Generate Load**: Use `/load` endpoint to see metrics in action
6. **Test Failure Scenarios**: Stop services to see alerting behavior

## 📚 Resources

- [Datadog Azure Integration Guide](https://docs.datadoghq.com/integrations/azure/)
- [Datadog Python APM Setup](https://docs.datadoghq.com/tracing/setup_overview/setup/python/)
- [Azure App Service Monitoring](https://docs.microsoft.com/en-us/azure/app-service/web-sites-monitor)

## 🔧 Troubleshooting

### Common Issues

**Database Connection Errors:**
- Check SQL Server firewall rules
- Verify connection string format
- Ensure serverless database isn't auto-paused

**App Service Deployment Issues:**
- Check App Service logs in Azure portal
- Verify Python requirements.txt dependencies
- Ensure startup.sh has correct permissions

**Datadog Agent Not Reporting:**
- Verify API key is correct
- Check App Service environment variables
- Review Datadog agent logs

### Useful Commands

```bash
# View Terraform state
terraform show

# Get specific output values
terraform output app_service_url
terraform output -raw sql_admin_password

# Check Azure resources
az webapp list --resource-group dam-rg-monitoring
az sql db list --server dam-sql-server --resource-group dam-rg-monitoring

# View App Service logs
az webapp log tail --name dam-app-api --resource-group dam-rg-monitoring
```

## ⚠️ Important Notes

- **Temporary Project**: This is a learning exercise, not production infrastructure
- **Daily Cleanup**: Always run `./cleanup.sh` to avoid unnecessary charges
- **Free Tiers**: Resources use free/low-cost options where possible
- **Security**: Uses basic authentication - don't store sensitive data
- **Monitoring Duration**: Datadog free trial provides full features for evaluation

## 🎓 Interview Preparation

After completing this project, you'll be able to discuss:
- Datadog vs Azure Monitor feature comparison
- Hands-on experience with Datadog setup and configuration
- Real-world monitoring scenarios and dashboard creation
- Integration challenges and solutions
- Cost considerations between monitoring platforms
- Practical observability implementation experience
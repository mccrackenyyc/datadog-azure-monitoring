#!/bin/bash

# App Service startup script for Python Flask application
echo "Starting Datadog Azure Monitoring Demo..."

# Install dependencies
echo "Installing Python dependencies..."
pip install -r requirements.txt

# Start the application with gunicorn
echo "Starting Flask application..."
gunicorn --bind 0.0.0.0:$PORT --workers 2 --timeout 120 app:app
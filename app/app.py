import os
import logging
import time
import json
from datetime import datetime
from flask import Flask, request, jsonify
import pyodbc
from urllib.parse import quote_plus

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Database configuration
DATABASE_URL = os.environ.get('DATABASE_URL')

def get_db_connection():
    """Get database connection with retry logic"""
    max_retries = 3
    for attempt in range(max_retries):
        try:
            # DATABASE_URL is now a direct ODBC connection string
            conn = pyodbc.connect(DATABASE_URL)
            logger.info(f"Database connection successful on attempt {attempt + 1}")
            return conn
            
        except Exception as e:
            logger.warning(f"Database connection attempt {attempt + 1} failed: {str(e)}")
            if attempt == max_retries - 1:
                raise
            time.sleep(2)

def init_database():
    """Initialize database tables"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Create users table if it doesn't exist
        cursor.execute("""
            IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='users' AND xtype='U')
            CREATE TABLE users (
                id INT IDENTITY(1,1) PRIMARY KEY,
                name NVARCHAR(100) NOT NULL,
                email NVARCHAR(255) NOT NULL UNIQUE,
                created_at DATETIME2 DEFAULT GETDATE()
            )
        """)
        
        # Insert some sample data if table is empty
        cursor.execute("SELECT COUNT(*) FROM users")
        count = cursor.fetchone()[0]
        
        if count == 0:
            sample_users = [
                ('Alice Johnson', 'alice@example.com'),
                ('Bob Smith', 'bob@example.com'),
                ('Charlie Brown', 'charlie@example.com')
            ]
            
            for name, email in sample_users:
                cursor.execute(
                    "INSERT INTO users (name, email) VALUES (?, ?)",
                    (name, email)
                )
        
        conn.commit()
        cursor.close()
        conn.close()
        logger.info("Database initialized successfully")
        
    except Exception as e:
        logger.error(f"Database initialization failed: {str(e)}")
        raise

@app.route('/')
def home():
    """Basic health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'service': 'Datadog Azure Monitoring Demo',
        'timestamp': datetime.utcnow().isoformat(),
        'endpoints': {
            'health': '/health',
            'users': '/users (GET/POST)',
            'load': '/load',
            'metrics': '/metrics'
        }
    })

@app.route('/health')
def health_check():
    """Comprehensive health check including database connectivity"""
    start_time = time.time()
    
    try:
        # Test database connection
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT 1")
        cursor.fetchone()
        cursor.close()
        conn.close()
        
        db_status = "healthy"
        db_response_time = round((time.time() - start_time) * 1000, 2)
        
    except Exception as e:
        db_status = "unhealthy"
        db_response_time = None
        logger.error(f"Database health check failed: {str(e)}")
    
    return jsonify({
        'status': 'healthy' if db_status == 'healthy' else 'degraded',
        'database': {
            'status': db_status,
            'response_time_ms': db_response_time
        },
        'timestamp': datetime.utcnow().isoformat()
    })

@app.route('/users', methods=['GET'])
def get_users():
    """Get all users from database"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("SELECT id, name, email, created_at FROM users ORDER BY created_at DESC")
        users = []
        
        for row in cursor.fetchall():
            users.append({
                'id': row[0],
                'name': row[1],
                'email': row[2],
                'created_at': row[3].isoformat() if row[3] else None
            })
        
        cursor.close()
        conn.close()
        
        logger.info(f"Retrieved {len(users)} users")
        return jsonify({'users': users, 'count': len(users)})
        
    except Exception as e:
        logger.error(f"Failed to retrieve users: {str(e)}")
        return jsonify({'error': 'Failed to retrieve users'}), 500

@app.route('/users', methods=['POST'])
def create_user():
    """Create a new user"""
    try:
        data = request.get_json()
        
        if not data or not data.get('name') or not data.get('email'):
            return jsonify({'error': 'Name and email are required'}), 400
        
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute(
            "INSERT INTO users (name, email) VALUES (?, ?)",
            (data['name'], data['email'])
        )
        
        # Get the ID of the newly created user
        cursor.execute("SELECT @@IDENTITY")
        user_id = cursor.fetchone()[0]
        
        conn.commit()
        cursor.close()
        conn.close()
        
        logger.info(f"Created user: {data['name']} ({data['email']})")
        return jsonify({
            'message': 'User created successfully',
            'user': {
                'id': int(user_id),
                'name': data['name'],
                'email': data['email']
            }
        }), 201
        
    except pyodbc.IntegrityError:
        return jsonify({'error': 'Email already exists'}), 409
    except Exception as e:
        logger.error(f"Failed to create user: {str(e)}")
        return jsonify({'error': 'Failed to create user'}), 500

@app.route('/load')
def generate_load():
    """Generate some CPU load for testing monitoring"""
    import random
    
    # Generate CPU load
    start_time = time.time()
    result = 0
    
    # Do some computation for 1-3 seconds
    duration = random.uniform(1, 3)
    while (time.time() - start_time) < duration:
        result += sum(range(1000))
    
    # Simulate memory allocation
    dummy_data = [random.random() for _ in range(10000)]
    
    elapsed = round(time.time() - start_time, 2)
    logger.info(f"Generated load for {elapsed} seconds")
    
    return jsonify({
        'message': f'Generated CPU/memory load for {elapsed} seconds',
        'computation_result': result,
        'memory_objects_created': len(dummy_data)
    })

@app.route('/metrics')
def get_metrics():
    """Return some custom metrics"""
    try:
        # Get user count
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM users")
        user_count = cursor.fetchone()[0]
        cursor.close()
        conn.close()
        
        # Get some system info
        metrics = {
            'timestamp': datetime.utcnow().isoformat(),
            'users_total': user_count,
            'database_queries_executed': 1,  # This query
            'uptime_check': 'healthy',
            'custom_metrics': {
                'requests_processed': 'tracked_by_flask',
                'database_connections': 'tracked_by_sql_server'
            }
        }
        
        return jsonify(metrics)
        
    except Exception as e:
        logger.error(f"Failed to get metrics: {str(e)}")
        return jsonify({'error': 'Failed to retrieve metrics'}), 500

@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Endpoint not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    logger.error(f"Internal server error: {str(error)}")
    return jsonify({'error': 'Internal server error'}), 500

if __name__ == '__main__':
    # Initialize database on startup
    try:
        logger.info("Initializing database...")
        init_database()
        logger.info("Database initialization complete")
    except Exception as e:
        logger.error(f"Failed to initialize database: {str(e)}")
        # Continue anyway - let health checks catch DB issues
    
    # Run the app
    port = int(os.environ.get('PORT', 8000))
    app.run(host='0.0.0.0', port=port, debug=False)
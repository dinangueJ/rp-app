#!/bin/bash
set -x


# =========================
# SYSTEM SETUP
# =========================
dnf update -y
dnf install -y python3 python3-pip nginx postgresql15 postgresql15-devel gcc git


# =========================
# SSM AGENT
# =========================
dnf install -y amazon-ssm-agent
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent


# =========================
# APP SETUP
# =========================
mkdir -p /opt/rp-app


cat > /opt/rp-app/app.py <<'PY'
import base64, os, uuid, socket
from datetime import datetime
from flask import Flask, request, jsonify
import boto3, psycopg2, json


app = Flask(__name__)
s3 = boto3.client('s3')
ses = boto3.client('ses', region_name=os.environ.get('AWS_REGION', 'us-east-1'))
secrets = boto3.client('secretsmanager', region_name=os.environ.get('AWS_REGION', 'us-east-1'))


RESUME_BUCKET = os.environ['RESUME_BUCKET']
DB_SECRET_NAME = os.environ['DB_SECRET_NAME']
SENDER_EMAIL = os.environ['SENDER_EMAIL']


def get_db_connection():
    secret = json.loads(secrets.get_secret_value(SecretId=DB_SECRET_NAME)['SecretString'])
    return psycopg2.connect(
        host=secret['host'],
        dbname=secret['dbname'],
        user=secret['username'],
        password=secret['password'],
        port=secret['port']
    )


@app.after_request
def add_cors_headers(response):
    response.headers['Access-Control-Allow-Origin'] = 'https://resume.dinangue.com'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type'
    response.headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
    return response


@app.route('/health')
def health():
    return jsonify({'status': 'healthy', 'instance': socket.gethostname()})


@app.route('/')
def index():
    return jsonify({'service': 'resume-portal', 'status': 'ok', 'instance': socket.gethostname()})


@app.route('/submit', methods=['POST', 'OPTIONS'])
def submit_application():
    if request.method == 'OPTIONS':
        return jsonify({})


    try:
        data = request.json
        now = datetime.utcnow()


        s3_key = f"resumes/{now.year}/{now.month:02d}/{str(uuid.uuid4())[:8]}_{data['fileName']}"


        s3.put_object(
            Bucket=RESUME_BUCKET,
            Key=s3_key,
            Body=base64.b64decode(data['resume']),
            ContentType='application/pdf'
        )


        conn = get_db_connection()
        cur = conn.cursor()


        cur.execute("""
            CREATE TABLE IF NOT EXISTS applications (
              id SERIAL PRIMARY KEY,
              full_name VARCHAR(200) NOT NULL,
              email VARCHAR(200) NOT NULL,
              phone VARCHAR(50),
              position VARCHAR(200),
              skills TEXT,
              resume_s3_key VARCHAR(500),
              submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)


        cur.execute("""
            INSERT INTO applications (full_name, email, phone, position, skills, resume_s3_key)
            VALUES (%s, %s, %s, %s, %s, %s) RETURNING id;
        """, (
            data['fullName'],
            data['email'],
            data['phone'],
            data['position'],
            data['skills'],
            s3_key
        ))


        app_id = cur.fetchone()[0]
        conn.commit()
        cur.close()
        conn.close()


        ses.send_email(
            Source=SENDER_EMAIL,
            Destination={'ToAddresses': [data['email']]},
            Message={
                'Subject': {'Data': f"Application Received - {data['position']}"},
                'Body': {'Text': {'Data': f"Hi {data['fullName']}, thanks for applying. Application ID: {app_id}"}}
            }
        )


        return jsonify({
            'message': 'Application submitted',
            'applicationId': app_id,
            'instance': socket.gethostname()
        })


    except Exception as e:
        return jsonify({'error': str(e)}), 500


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
PY


# =========================
# REQUIREMENTS
# =========================
cat > /opt/rp-app/requirements.txt <<'REQ'
flask
boto3
psycopg2-binary
REQ


python3 -m pip install --upgrade pip
python3 -m pip install -r /opt/rp-app/requirements.txt


# =========================
# SYSTEMD SERVICE
# =========================
cat > /etc/systemd/system/rp-app.service <<SERVICE
[Unit]
Description=Resume Portal Flask App
After=network.target


[Service]
WorkingDirectory=/opt/rp-app
Environment=RESUME_BUCKET=${resume_bucket}
Environment=DB_SECRET_NAME=${db_secret_name}
Environment=SENDER_EMAIL=${sender_email}
Environment=AWS_REGION=${aws_region}
ExecStart=/usr/bin/python3 /opt/rp-app/app.py
Restart=always
User=root
StandardOutput=journal
StandardError=journal


[Install]
WantedBy=multi-user.target
SERVICE


# =========================
# NGINX CONFIG
# =========================
cat > /etc/nginx/conf.d/rp.conf <<'NGINX'
server {
    listen 80;


    client_max_body_size 20M;


    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 120s;
        proxy_connect_timeout 120s;
        proxy_send_timeout 120s;
    }
}
NGINX


rm -f /etc/nginx/conf.d/default.conf || true


# =========================
# NGINX MAIN CONFIG
# =========================
tee /etc/nginx/nginx.conf > /dev/null <<'NGINXMAIN'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log notice;
pid /run/nginx.pid;
include /usr/share/nginx/modules/*.conf;


events {
    worker_connections 1024;
}


http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';
    access_log  /var/log/nginx/access.log  main;
    sendfile            on;
    tcp_nopush          on;
    keepalive_timeout   65;
    types_hash_max_size 4096;
    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;
    include /etc/nginx/conf.d/*.conf;
}
NGINXMAIN


# =========================
# START SERVICES
# =========================
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable rp-app nginx amazon-ssm-agent
systemctl restart rp-app nginx amazon-ssm-agent


# =========================
# VERIFY SSM AGENT
# =========================
for i in {1..6}; do
  if systemctl is-active --quiet amazon-ssm-agent; then
    echo "SSM agent active on attempt $i"
    break
  fi
  echo "SSM agent not ready, retrying in 10s... ($i/6)"
  sleep 10
done


# =========================
# UPLOAD BOOT LOG TO S3
# =========================
sleep 5
aws s3 cp /var/log/cloud-init-output.log s3://${resume_bucket}/logs/cloud-init-$(hostname).log || true

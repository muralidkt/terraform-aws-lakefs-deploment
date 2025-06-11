#!/bin/bash
set -e

# Install required packages
yum update -y
yum install -y docker jq aws-cli

# Start Docker service
systemctl start docker
systemctl enable docker

# Create LakeFS configuration directory
mkdir -p /etc/lakefs
mkdir -p /var/lib/lakefs

# Create log files with proper permissions
touch /var/lib/lakefs/lakefs.log /var/lib/lakefs/lakefs-stdout.log /var/lib/lakefs/lakefs-stderr.log
chmod 644 /var/lib/lakefs/lakefs.log /var/lib/lakefs/lakefs-stdout.log /var/lib/lakefs/lakefs-stderr.log
chmod 755 /var/lib/lakefs

# Fetch secrets from AWS Secrets Manager
SECRETS=$(aws secretsmanager get-secret-value \
  --secret-id "${project_name}-${environment}-lakefs-initial-secrets" \
  --region "${region}" \
  --query SecretString \
  --output text)

# Extract values from secrets
ENCRYPTION_SECRET_KEY=$(echo $SECRETS | jq -r .encryption_secret_key)
ACCESS_KEY_ID=$(echo $SECRETS | jq -r .access_key_id)
SECRET_ACCESS_KEY=$(echo $SECRETS | jq -r .secret_access_key)

# Create LakeFS configuration file
cat > /etc/lakefs/config.yaml <<EOF
---
database:
  type: dynamodb
  dynamodb:
    table_name: "${dynamodb_table_name}"
    aws_region: "${region}"

blockstore:
  type: s3
  s3:
    region: "${region}"
    force_path_style: false

auth:
  encrypt:
    secret_key: "$ENCRYPTION_SECRET_KEY"

logging:
  format: json
  level: DEBUG

installation:
  access_key_id: "$ACCESS_KEY_ID"
  secret_access_key: "$SECRET_ACCESS_KEY"
EOF

# Set proper permissions
chmod 644 /etc/lakefs/config.yaml
chown -R ec2-user:ec2-user /var/lib/lakefs

# Create systemd service file
cat > /etc/systemd/system/lakefs.service <<EOF
[Unit]
Description=LakeFS Service
After=docker.service
Requires=docker.service

[Service]
TimeoutStartSec=120
Restart=on-failure
RestartSec=10
StartLimitIntervalSec=600
StartLimitBurst=5
ExecStartPre=-/usr/bin/docker stop %n
ExecStartPre=-/usr/bin/docker rm %n
ExecStart=/usr/bin/docker run --name %n \
    -p 8000:8000 \
    -v /etc/lakefs:/etc/lakefs \
    -v /var/lib/lakefs:/var/lib/lakefs \
    --network host \
    treeverse/lakefs:${lakefs_version} \
    run --config /etc/lakefs/config.yaml
StandardOutput=append:/var/lib/lakefs/lakefs-stdout.log
StandardError=append:/var/lib/lakefs/lakefs-stderr.log

[Install]
WantedBy=multi-user.target
EOF

# Start LakeFS service
systemctl daemon-reload
systemctl enable lakefs
systemctl start lakefs

# Wait for LakeFS to be ready
echo "Waiting for LakeFS to start..."
for i in {1..30}; do
  if curl -s http://localhost:8000/api/v1/setup_lakefs > /dev/null 2>&1; then
    echo "LakeFS is ready!"
    break
  fi
  echo "Waiting for LakeFS... ($i/30)"
  sleep 10
done

# Check if LakeFS needs setup and run it if necessary
SETUP_STATE=$(curl -s http://localhost:8000/api/v1/setup_lakefs | jq -r '.state' 2>/dev/null || echo "not_initialized")

if [ "$SETUP_STATE" = "not_initialized" ]; then
  echo "Running LakeFS setup..."
  
  # Run setup using docker exec on the running container
  docker exec lakefs.service lakefs setup \
    --user-name admin \
    --access-key-id "$ACCESS_KEY_ID" \
    --secret-access-key "$SECRET_ACCESS_KEY"
    
  echo "LakeFS setup completed!"
else
  echo "LakeFS already initialized – skipping setup."
fi 
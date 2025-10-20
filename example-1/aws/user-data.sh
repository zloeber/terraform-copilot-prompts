#!/bin/bash

# Update system packages
apt-get update
apt-get upgrade -y

# Install required packages
apt-get install -y nginx awscli lvm2

# Configure the additional EBS volume for /opt
# Wait for the device to be available
while [ ! -e /dev/nvme1n1 ]; do
  sleep 1
done

# Create physical volume
pvcreate /dev/nvme1n1

# Create volume group
vgcreate opt-vg /dev/nvme1n1

# Create logical volume
lvcreate -l 100%FREE -n opt-lv opt-vg

# Format the logical volume
mkfs.ext4 /dev/opt-vg/opt-lv

# Create mount point
mkdir -p /opt

# Mount the volume
mount /dev/opt-vg/opt-lv /opt

# Add to fstab for persistent mounting
echo '/dev/opt-vg/opt-lv /opt ext4 defaults 0 0' >> /etc/fstab

# Set up nginx
systemctl enable nginx
systemctl start nginx

# Create a simple index page
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>WordPress Development Server</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 600px; margin: 0 auto; }
        .server-info { background: #f4f4f4; padding: 20px; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>WordPress Development Environment</h1>
        <div class="server-info">
            <h2>Server Information</h2>
            <p><strong>Hostname:</strong> $(hostname)</p>
            <p><strong>Instance ID:</strong> $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>
            <p><strong>Availability Zone:</strong> $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)</p>
            <p><strong>Local IP:</strong> $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)</p>
        </div>
        <p>This server is ready for WordPress development!</p>
    </div>
</body>
</html>
EOF

# Replace the placeholder variables in the HTML
sed -i "s/\$(hostname)/$(hostname)/g" /var/www/html/index.html
sed -i "s/\$(curl -s http:\/\/169.254.169.254\/latest\/meta-data\/instance-id)/$(curl -s http://169.254.169.254/latest/meta-data/instance-id)/g" /var/www/html/index.html
sed -i "s/\$(curl -s http:\/\/169.254.169.254\/latest\/meta-data\/placement\/availability-zone)/$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)/g" /var/www/html/index.html
sed -i "s/\$(curl -s http:\/\/169.254.169.254\/latest\/meta-data\/local-ipv4)/$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)/g" /var/www/html/index.html

# Configure nginx for health checks
cat > /etc/nginx/sites-available/default << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;

    server_name _;

    location / {
        try_files $uri $uri/ =404;
    }

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

# Test nginx configuration and reload
nginx -t && systemctl reload nginx

# Set up S3 access configuration
mkdir -p /opt/s3-config
echo "S3_BUCKET=${s3_bucket_name}" > /opt/s3-config/bucket-info

# Create a test script for S3 access
cat > /opt/s3-config/test-s3-access.sh << 'EOF'
#!/bin/bash
source /opt/s3-config/bucket-info
echo "Testing S3 access to bucket: $S3_BUCKET"
aws s3 ls s3://$S3_BUCKET/ && echo "S3 access successful" || echo "S3 access failed"
EOF
chmod +x /opt/s3-config/test-s3-access.sh

# Install CloudWatch agent for monitoring
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb

# Configure log forwarding to CloudWatch
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/nginx/access.log",
                        "log_group_name": "wordpress-dev-nginx",
                        "log_stream_name": "{instance_id}-access"
                    },
                    {
                        "file_path": "/var/log/nginx/error.log",
                        "log_group_name": "wordpress-dev-nginx",
                        "log_stream_name": "{instance_id}-error"
                    }
                ]
            }
        }
    }
}
EOF

# Signal that the instance is ready
/opt/aws/bin/cfn-signal -e $? --stack ${AWS::StackName} --resource AutoScalingGroup --region ${AWS::Region} 2>/dev/null || true

echo "User data script completed successfully" > /var/log/user-data-complete.log
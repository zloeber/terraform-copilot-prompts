# User data script for EC2 instances
locals {
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    s3_bucket_name = aws_s3_bucket.wordpress_storage.bucket
  }))
}

# EC2 Instances
resource "aws_instance" "web_servers" {
  count = length(var.availability_zones) * var.instance_count_per_az

  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  
  # Calculate subnet index based on instance count and AZ distribution
  subnet_id = aws_subnet.private[count.index % length(var.availability_zones)].id
  
  vpc_security_group_ids = [aws_security_group.web_servers.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data_base64                = local.user_data
  user_data_replace_on_change     = true
  associate_public_ip_address     = false

  # Root block device
  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    encrypted             = true
    delete_on_termination = true
    
    tags = merge(var.tags, {
      Name = "${var.project_name}-web-${count.index + 1}-root"
    })
  }

  # Additional data volume for /opt
  ebs_block_device {
    device_name           = "/dev/sdf"
    volume_type           = "gp3"
    volume_size           = var.data_volume_size
    encrypted             = true
    delete_on_termination = true
    
    tags = merge(var.tags, {
      Name = "${var.project_name}-web-${count.index + 1}-data"
    })
  }

  # Enhanced metadata options for security
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags = "enabled"
  }

  # Enable detailed monitoring
  monitoring = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-web-${count.index + 1}"
    Type = "WebServer"
    AZ   = aws_subnet.private[count.index % length(var.availability_zones)].availability_zone
  })

  lifecycle {
    create_before_destroy = true
  }
}
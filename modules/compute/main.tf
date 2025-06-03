################################
# 0. Inputs (variables)
################################

# Which public subnet (ID) to launch the EC2 into
variable "public_subnet" {
  description = "ID of the public subnet (from the network module)"
  type        = string
}

# Which security‐group ID to assign (must allow HTTP/80)
variable "sg_id" {
  description = "ID of the security group that permits HTTP from 0.0.0.0/0"
  type        = string
}

# Name of the existing EC2 key‐pair (created by root module or elsewhere)
variable "key_name" {
  description = "Name of the EC2 key pair to use for SSH"
  type        = string
}

# AMI ID (must exist in eu-west-3-WLZ)
variable "ami_id" {
  description = "AMI ID to use for the WLZ EC2 instance"
  type        = string
}

# EC2 instance type
variable "instance_type" {
  description = "EC2 instance type (e.g. t3.medium)"
  type        = string
}

# Tags: project name
variable "project" {
  description = "Project tag"
  type        = string
}

# Tags: environment
variable "env" {
  description = "Environment tag (e.g. prod, stage)"
  type        = string
}

# Tags: domain (for the EC2)
variable "domain" {
  description = "Domain name (e.g. stage-pfe.store) for tagging"
  type        = string
}

################################
# 1. Security Group (HTTP on 80)
################################
data "aws_subnet" "public" {
  id = var.public_subnet
}

resource "aws_security_group" "frontend_sg" {
  # Note: You can either pass sg_id in and omit this resource entirely,
  # or keep this resource and remove sg_id usage. Here we assume you passed sg_id,
  # so this block is just for reference. If you are re‐using var.sg_id, you can delete this block.
  # To avoid confusion, we won't use aws_security_group.frontend_sg. Instead, the root module
  # should pass the proper SG ID into var.sg_id.

  name   = "${var.project}-${var.env}-frontend"
  vpc_id = data.aws_subnet.public.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = var.project
    Env     = var.env
  }
}

################################
# 2. WLZ EC2 front‐end Instance
################################
resource "aws_instance" "web" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  availability_zone      = "euw3-cmn1-wlz1"  # Wavelength AZ
  subnet_id              = var.public_subnet # Passed in from root
  key_name               = var.key_name      # Passed in from root
  vpc_security_group_ids = [var.sg_id]       # Passed in from root

  tags = {
    Project = var.project
    Env     = var.env
    Domain  = var.domain
  }

  root_block_device {
    volume_type = "gp2" # WLZ‐compatible
    volume_size = 20
  }

  user_data = <<-EOF
    #!/bin/bash
    set -e
    exec > >(tee /var/log/user-data.log | logger -t user-data) 2>&1

    # Basic setup
    yum update -y
    yum install -y git

    # Install Docker & Docker Compose v2 plugin
    amazon-linux-extras install docker -y
    systemctl enable --now docker
    yum install -y docker-compose-plugin
    usermod -aG docker ec2-user

    # Clone & run the MERN app via Docker Compose
    cd /home/ec2-user
    if [ ! -d "mern-ecommerce" ]; then
      git clone https://github.com/mohamedsamara/mern-ecommerce.git
    fi
    cd mern-ecommerce

    # Expose React on port 80 instead of 3000
    sed -i 's/- "3000:3000"/- "80:3000"/' docker-compose.yml

    docker compose pull
    docker compose up -d --remove-orphans
  EOF
}

################################
# 3. Allocate a VPC Elastic IP
################################
resource "aws_eip" "web_eip" {
  # 'domain' is the newer name for 'vpc':
  domain = "vpc"

  tags = {
    Name    = "${var.project}-${var.env}-web-eip"
    Project = var.project
    Env     = var.env
  }
}

################################
# 4. Associate EIP → EC2
################################
resource "aws_eip_association" "web_assoc" {
  instance_id   = aws_instance.web.id
  allocation_id = aws_eip.web_eip.id
}

################################
# 5. Outputs
################################
output "frontend_public_ip" {
  description = "The public Elastic IP attached to the WLZ EC2 instance"
  value       = aws_eip.web_eip.public_ip
}

output "frontend_sg_id" {
  description = "ID of the security group that allows HTTP"
  value       = aws_security_group.frontend_sg.id
}
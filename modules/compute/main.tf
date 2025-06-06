################################
# 1. Security Group (HTTP on 80 + SSH on 22)
################################
data "aws_subnet" "public" {
  id = var.public_subnet
}

resource "aws_security_group" "frontend_sg" {
  name   = "${var.project}-${var.env}-frontend"
  vpc_id = data.aws_subnet.public.vpc_id

  ingress {
    description = "SSH for GitLab deploy"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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
  availability_zone      = "eu-west-3-cmn-wlz-1a"
  subnet_id              = var.public_subnet
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.frontend_sg.id]
  tags = {
    Project = var.project
    Env     = var.env
    Domain  = var.domain
  }

  root_block_device {
    volume_type = "gp2"
    volume_size = 20
  }

  user_data = <<-EOF
    #!/bin/bash
    set -e
    exec > >(tee /var/log/user-data.log | logger -t user-data) 2>&1

      yum update -y
    yum install -y git

      amazon-linux-extras install docker -y
    systemctl enable --now docker
    yum install -y docker-compose-plugin
    usermod -aG docker ec2-user
    
    cd /home/ec2-user
    if [ ! -d "mern-ecommerce" ]; then
      git clone https://github.com/mohamedsamara/mern-ecommerce.git
    fi
      cd mern-ecommerce
    sed -i 's/- "3000:3000"/- "80:3000"/' docker-compose.yml
      docker compose pull
    docker compose up -d --remove-orphans
  EOF
}

################################
# 3. Allocate a VPC Elastic IP
################################
resource "aws_eip" "web_eip" {
  domain               = "vpc"
  network_border_group = "eu-west-3-cmn-wlz-1"

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
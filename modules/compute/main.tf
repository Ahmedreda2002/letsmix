/* ---------- Data  ---------- */
data "aws_subnet" "public" {
  id = var.public_subnet
}

/* ---------- Security-group (HTTP on 80) ---------- */
resource "aws_security_group" "frontend_sg" {
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

/* ---------- WLZ EC2 front-end ---------- */
resource "aws_instance" "frontend" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.public_subnet
  vpc_security_group_ids = [aws_security_group.frontend_sg.id]

  tags = {
    Name    = "${var.project}-${var.env}-fe"
    Project = var.project
    Env     = var.env
  }

  root_block_device {
    volume_type = "gp2"   # WLZ-compatible
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

    # Docker Compose v2 plugin
    yum install -y docker-compose-plugin

    # Allow ec2-user to use docker later
    usermod -aG docker ec2-user

    cd /home/ec2-user
    if [ ! -d "mern-ecommerce" ]; then
      git clone https://github.com/mohamedsamara/mern-ecommerce.git
    fi
    cd mern-ecommerce

    # Publish React on host port 80 instead of 3000
    sed -i 's/- "3000:3000"/- "80:3000"/' docker-compose.yml

    docker compose pull
    docker compose up -d --remove-orphans
  EOF
}



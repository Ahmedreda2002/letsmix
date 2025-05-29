/* Resolve the WLZ AZ ID */
data "aws_availability_zone" "wlz" {
  name = var.wlz_name
}

resource "aws_vpc" "this" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

/* Public subnet routed to the carrier gateway */
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.0.1.0/28"
  availability_zone_id    = data.aws_availability_zone.wlz.zone_id
  map_public_ip_on_launch = false
}

resource "aws_ec2_carrier_gateway" "cg" {
  vpc_id = aws_vpc.this.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    carrier_gateway_id = aws_ec2_carrier_gateway.cg.id
    cidr_block         = "0.0.0.0/0"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

/* Private subnet */
resource "aws_subnet" "private" {
  vpc_id               = aws_vpc.this.id
  cidr_block           = "10.0.1.16/28"
  availability_zone_id = data.aws_availability_zone.wlz.zone_id
}

/* Outputs */
output "vpc_id"             { value = aws_vpc.this.id }
output "public_subnet_ids"  { value = [aws_subnet.public.id] }
output "private_subnet_ids" { value = [aws_subnet.private.id] }

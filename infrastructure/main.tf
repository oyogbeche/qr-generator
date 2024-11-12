resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true 
}

resource "aws_subnet" "subnet_1" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.0.0/20"
  availability_zone = "eu-west-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "subnet_2" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.16.0/20"
  availability_zone = "eu-west-1b"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "subnet_3" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.32.0/20"
  availability_zone = "eu-west-1a"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "vpc_igw" {
    vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "vpc_rtb" {
    vpc_id = aws_vpc.main.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.vpc_igw.id
    }

    route {
        cidr_block = "10.0.0.0/16"
        gateway_id = "local"
    }
}

resource "aws_route_table_association" "rtba_subnet_1" {
    route_table_id = aws_route_table.vpc_rtb.id
    subnet_id = aws_subnet.subnet_1.id
}

resource "aws_route_table_association" "rtba_subnet_2" {
  route_table_id = aws_route_table.vpc_rtb.id
  subnet_id = aws_subnet.subnet_2.id
}

resource "aws_route_table_association" "rtba_subnet_3" {
  route_table_id = aws_route_table.vpc_rtb.id
  subnet_id = aws_subnet.subnet_3.id
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "qrcode_cluster"
  cluster_version = "1.27"

  cluster_endpoint_public_access = true

  vpc_id                   = aws_vpc.main.id
  subnet_ids               = [aws_subnet.subnet_1.id, aws_subnet.subnet_2.id, aws_subnet.subnet_3.id]
  control_plane_subnet_ids = [aws_subnet.subnet_1.id, aws_subnet.subnet_2.id, aws_subnet.subnet_3.id]

  eks_managed_node_groups = {
    green = {
      min_size       = 1
      max_size       = 2
      desired_size   = 1
      instance_types = ["t3.medium"]
    }
  }
}

locals {
    region = "us-east-1"
    cidr = "10.0.0.0/16"
    vpc_name = "dev-vpc"
    private_subnet = ["10.0.1.0/24", "10.0.2.0/24"]
    public_subnet = ["10.0.4.0/24", "10.0.5.0/24"]
}

data "aws_availability_zones" "available" {}

module vpc {
    source = "terraform-aws-modules/vpc/aws"
    version = "3.2.0"
    name = local.vpc_name
    cidr = local.cidr
    azs = data.aws_availability_zones.available.names
    private_subnets = local.private_subnet
    public_subnets =  local.public_subnet
    enable_nat_gateway = true
    single_nat_gateway = true
    tags = {
        "Name" = local.vpc_name
    }
    public_subnet_tags = {
        "Name" = "dev-Public-Subnet"
    }
    private_subnet_tags = {
        "Name" = "dev-Private-Subnet"
    }
}
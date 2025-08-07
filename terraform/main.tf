terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data source to get our custom AMIs
data "aws_ami" "webserver" {
  most_recent = true
  owners      = ["self"]
  filter {
    name   = "name"
    values = ["custom-webserver-*"]
  }
}

data "aws_ami" "elasticsearch" {
  most_recent = true
  owners      = ["self"]
  filter {
    name   = "name"
    values = ["custom-elasticsearch-*"]
  }
}

data "aws_ami" "kibana" {
  most_recent = true
  owners      = ["self"]
  filter {
    name   = "name"
    values = ["custom-kibana-*"]
  }
}

data "aws_ami" "mysql_primary" {
  most_recent = true
  owners      = ["self"]
  filter {
    name   = "name"
    values = ["custom-mysql-primary-*"]
  }
}

data "aws_ami" "mysql_standby" {
  most_recent = true
  owners      = ["self"]
  filter {
    name   = "name"
    values = ["custom-mysql-standby-*"]
  }
}

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get default subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security Groups
resource "aws_security_group" "webserver" {
  name_prefix = "webserver-sg"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
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
    Name = "WebServer-SG"
    Environment = var.environment
  }
}

resource "aws_security_group" "elasticsearch" {
  name_prefix = "elasticsearch-sg"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 9200
    to_port     = 9200
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  ingress {
    from_port   = 9300
    to_port     = 9300
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  ingress {
    from_port   = 22
    to_port     = 22
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
    Name = "Elasticsearch-SG"
    Environment = var.environment
  }
}

resource "aws_security_group" "kibana" {
  name_prefix = "kibana-sg"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 5601
    to_port     = 5601
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
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
    Name = "Kibana-SG"
    Environment = var.environment
  }
}

resource "aws_security_group" "mysql" {
  name_prefix = "mysql-sg"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  ingress {
    from_port   = 22
    to_port     = 22
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
    Name = "MySQL-SG"
    Environment = var.environment
  }
}
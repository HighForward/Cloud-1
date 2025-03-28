terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-3"
  #  access_key = ""
  #  secret_key = "
}

# Create a VPC
resource "aws_vpc" "cloud1-vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_ecs_cluster" "cloud1-cluster" {
  name = "cloud1-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecr_repository" "wordpress" {
  name = "wordpress"
}

resource "aws_ecr_repository" "mysql" {
  name = "mysql"
}

resource "aws_ecr_repository" "phpmyadmin" {
  name = "phpmyadmin"
}
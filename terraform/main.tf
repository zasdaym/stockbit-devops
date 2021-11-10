provider "aws" {
  region = "ap-southeast-1"
}

module "test_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "test-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["ap-southeast-1a"]
  private_subnets = ["10.0.1.0/24"]
  public_subnets  = ["10.0.101.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {
    Terraform   = "true"
    Environment = "test"
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-*-x86_64-gp2"]
  }
}

module "test_asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 4.0"

  name = "test-asg"

  min_size            = 2
  max_size            = 5
  use_lt              = true
  vpc_zone_identifier = module.test_vpc.private_subnets

  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t2.medium"
}

resource "aws_autoscaling_policy" "test_asg_policy" {
  name                   = "test-asg-policy"
  autoscaling_group_name = module.test_asg.autoscaling_group_name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 45.0
  }
}

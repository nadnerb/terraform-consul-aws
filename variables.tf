variable "aws_access_key" {}
variable "aws_secret_key" {}

variable "ami" {
    default = {
        ap-southeast-2 = "ami-69631053"
    }
}

variable "key_name" {
    description = "SSH key name in your AWS account for AWS instances."
}

variable "key_path" {
    description = "Path to the private key specified by key_name."
}

variable "aws_region" {
    default = "ap-southeast-2"
    description = "The region of AWS, for AMI lookups."
}

variable "servers" {
    default = "3"
    description = "The number of Consul servers to launch."
}

variable "aws_vpcs" {
	default = {
		ap-southeast-2 = "vpc-f753bd92"
	}
}

variable "aws_subnets" {
	default = {
		ap-southeast-2 = "subnet-5fc53a3a"
	}
}

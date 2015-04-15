provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region = "${var.aws_region}"
}

resource "aws_security_group" "consul" {
  name = "consul"
  description = "Consul internal traffic, UI + maintenance."
  vpc_id = "${lookup(var.aws_vpcs, var.aws_region)}"

  // These are for internal traffic
  ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    self = true
  }

  ingress {
    from_port = 0
    to_port = 65535
    protocol = "udp"
    self = true
  }

  // These are for maintenance
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // consul ui
  ingress {
    from_port = 8500
    to_port = 8500
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "consul security group"
  }
}

# Create a new load balancer
resource "aws_elb" "consul" {
  name = "consul-elb"
  availability_zones = ["ap-southeast-2a"]

  listener {
    instance_port = 8500
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "TCP:8500"
    interval = 30
  }

  instances = ["${aws_instance.server.0.id}", "${aws_instance.server.1.id}"]
  cross_zone_load_balancing = true

  tags {
    Name = "consul elb"
  }
}

resource "aws_instance" "server" {

    ami = "${lookup(var.ami, var.aws_region)}"
    instance_type = "t2.small"
    key_name = "${var.key_name}"
    count = "${var.servers}"
    security_groups = ["${aws_security_group.consul.id}"]

    subnet_id = "${lookup(var.aws_subnets, var.aws_region)}"

    # fix this with a bastion
    associate_public_ip_address = "true"

    tags {
        Name = "consul-${count.index+1}"
    }

    connection {
        user = "ubuntu"
        key_file = "${var.key_path}"
    }

    # redo using ansible
    provisioner "file" {
        source = "${path.module}/scripts/upstart.conf"
        destination = "/tmp/upstart.conf"
    }

    provisioner "file" {
        source = "${path.module}/scripts/upstart-join.conf"
        destination = "/tmp/upstart-join.conf"
    }

    provisioner "file" {
        source = "${path.module}/scripts/consul.conf"
        destination = "/tmp/consul.conf"
    }

    provisioner "remote-exec" {
        inline = [
            "echo ${var.servers} > /tmp/consul-server-count",
            "echo ${aws_instance.server.0.private_dns} > /tmp/consul-server-addr",
        ]
    }

    provisioner "remote-exec" {
        scripts = [
            "${path.module}/scripts/install.sh",
            "${path.module}/scripts/server.sh",
            "${path.module}/scripts/service.sh",
        ]
    }
}

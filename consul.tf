provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "${var.aws_region}"
}

resource "aws_security_group" "consul_server" {
  name = "consul server"
  description = "Consul server UI and maintenance."
  vpc_id = "${lookup(var.aws_vpcs, var.aws_region)}"

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
    Name = "consul server security group"
    stream = "${var.stream_tag}"
  }
}

resource "aws_security_group" "consul_internal_traffic" {
  name = "consul internal traffic"
  description = "Consul server internal traffic."
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

  tags {
    Name = "consul internal traffic security group"
    stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "consul" {

    ami = "${lookup(var.ami, var.aws_region)}"
    instance_type = "t2.small"
    key_name = "${var.key_name}"
    count = "${var.servers}"
    security_groups = ["${aws_security_group.consul_server.id}", "${aws_security_group.consul_internal_traffic.id}"]

    subnet_id = "${lookup(var.aws_subnets, var.aws_region)}"

    associate_public_ip_address = "${var.public_ip}"

    tags {
      Name = "consul-${count.index+1}"
      stream = "${var.stream_tag}"
    }

    connection {
      user = "ubuntu"
      type = "ssh"
      /*change this to public if you don't have access via private ip's*/
      host = "${self.private_ip}"
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
        "echo ${aws_instance.consul.0.private_dns} > /tmp/consul-server-addr"
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

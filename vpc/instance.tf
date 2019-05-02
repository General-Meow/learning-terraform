provider "aws" {
//  shared_credentials_file = "/Users/paul/.aws/credentials"
  region     = "eu-west-2"
}

resource "aws_vpc" "terraform_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags {
    Name = "terraform_vpc"
    created_by = "terraform"
  }
}

resource "aws_internet_gateway" "terraform_internet_gateway" {
  vpc_id = "${aws_vpc.terraform_vpc.id}"
  tags {
    Name = "terraform_ig"
    created_by = "terraform"
  }
}

resource "aws_route_table" "terraform_route_table" {
  vpc_id = "${aws_vpc.terraform_vpc.id}"

  route {
    gateway_id = "${aws_internet_gateway.terraform_internet_gateway.id}"
    cidr_block = "0.0.0.0/0"
  }

  tags {
    Name = "terraform_route_table"
    created_by = "terraform"
  }
}

resource "aws_route_table_association" "terraform_route_table_assoc" {
  route_table_id = "${aws_route_table.terraform_route_table.id}"
  subnet_id = "${aws_subnet.terraform_subnet.id}"
}

resource "aws_security_group" "terraform-sg" {
  vpc_id = "${aws_vpc.terraform_vpc.id}"
  ingress {
    //from and to port must be 0 if you want ALL traffic
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    to_port = 0
    protocol = "ICMP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "terraform_sg"
  }
}

resource "aws_subnet" "terraform_subnet" {
  cidr_block = "10.0.1.1/24"
  vpc_id = "${aws_vpc.terraform_vpc.id}"
  tags {
    Name = "terraform_sg"
    created_by = "terraform"
  }
}

resource "aws_key_pair" "terraform_key" {
  key_name = "terraform_key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDdXWKMSJIOcXH6phzi1MkLPzgm9T04QmhUijwzoNE+DObhoXzRaf/quR+yEV6MvkyqjRg7Y23cft/aDOk6fXCw4FsSYbMFHDRuyTid5HLDDC+uhFTOWYmXDkCpxtDAlYI1rWXvj6fNfRfOUts0ty1zIAaA74/6kjKT6SnpL//PVt4QhPyHVEa/kPPzkfvcQnpxYBoxLIb5a/IKCdGcN3pgAxOgbOocN57FIgwaihjAF1dJMhftQ6jHwc3KHnxN9DkNh6YM0/JkcVNoeQyIQV2wjvhJn2JOUXNKh90ZmYG+WwOo+H+qsOaV5Yfz0XRktxzCB12U1wdjG+uSjYGMC2/N paul@Pauls-MacBook-Pro.local"
}


resource "aws_eip" "instance_public_ip" {
  instance = "${aws_instance.ec2-instance-demo.id}"

  tags {
    Name = "terraform_eip"
    created_by = "terraform"
  }
}

resource "aws_instance" "ec2-instance-demo" {
  ami = "ami-01419b804382064e4"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.terraform_subnet.id}"
  key_name = "${aws_key_pair.terraform_key.key_name}"
  vpc_security_group_ids = ["${aws_security_group.terraform-sg.id}"]
  tags {
    Name = "terraform_instance"
    created_by = "terraform"
  }

//  provi sioner "remote-exec" {
//    connection {
//      user = "${var.ec2_username}"
//      private_key = "${file("${var.private_key_path}")}"
//    }
//    inline = ["apt get update", "apt get install nginx"]
//  }
}
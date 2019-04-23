provider "aws" {
  access_key = "xxxx"
  secret_key = "xxxx"
  region     = "eu-west-2"
}

resource "aws_instance" "example" {
  ami           = "ami-021202ee82d116ad0"
  instance_type = "t2.micro"

  provisioner "local-exec" {
    command = ""
  }
}


data "aws_ip_ranges" "my_ips" {
  regions = [""]
  create_date = ""
}
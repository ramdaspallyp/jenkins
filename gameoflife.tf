variable "accesskey" {
    type = "string"
}
variable "secretkey" {
    type = "string"
}


provider "aws" {
  region     = "ap-south-1"
  access_key = "${var.accesskey}"
  secret_key = "${var.secretkey}"
}

resource "aws_vpc" "vpc_mumbai" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "vpc_mumbai"
  }
}

resource "aws_subnet" "pub_subnet_mumbai" {
  vpc_id            = "${aws_vpc.vpc_mumbai.id}"
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "pub_subnet_mumbai"
  }
}

resource "aws_subnet" "prt_subnet_mumbai" {
  vpc_id            = "${aws_vpc.vpc_mumbai.id}"
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "prt_subnet_mumbai"
  }
}
resource "aws_internet_gateway" "igw_mumbai" {
  vpc_id = "${aws_vpc.vpc_mumbai.id}"

  tags = {
    Name = "igw_mumbai"
  }
}

resource "aws_route_table" "pub_route_table" {
  vpc_id = "${aws_vpc.vpc_mumbai.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw_mumbai.id}"
  }
  tags = {
    Name = "pub_route_table"
  }
}

resource "aws_route_table" "prt_route_table" {
  vpc_id = "${aws_vpc.vpc_mumbai.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw_mumbai.id}"
  }
  tags = {
    Name = "prt_route_table"
  }
}
resource "aws_main_route_table_association" "rtassociation" {
  vpc_id         = "${aws_vpc.vpc_mumbai.id}"
  route_table_id = "${aws_route_table.pub_route_table.id}"
}

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = "${aws_vpc.vpc_mumbai.id}"

  ingress {
    # TLS (change to whatever ports you need)
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
}





resource "aws_instance" "instance_mumbai" {
  ami                         = "ami-03dcedc81ea3e7e27"
  instance_type               = "t2.micro"
  key_name                    = "mumbaikey"
  subnet_id                   = "${aws_subnet.pub_subnet_mumbai.id}"
  associate_public_ip_address = true
  vpc_security_group_ids      = ["${aws_security_group.allow_tls.id}"]


  tags = {
    Name = "instance_mumbai"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = "${file("mumbaikey.pem")}"
    host        = "${aws_instance.instance_mumbai.public_ip}"

  }
    provisioner "remote-exec" {
      inline = [
        "sudo apt-get update",
        "sudo apt-get install -f", # to verfy broken packages
        "sudo apt-get upgrade -y", # upgrade and update
        "sudo apt-get update",
        "sudo apt-get install openjdk-8-jdk -y",
        "sudo apt-get install tomcat8 -y",
        "sudo systemctl restart tomcat8",
        "wget https://qt-s3-new-testing.s3-us-west-2.amazonaws.com/gameoflife.war",
        "sudo cp /home/ubuntu/gameoflife.war /var/lib/tomcat8/webapps"
      ]
    }
    
  }

provider "aws"{
 region = "ap-south-1"
}

resource "aws_vpc" "main" {
  cidr_block       = "192.168.0.0/24"
  instance_tenancy = "default"

  tags = {
    Name = "vj_vpc"
  }
}

resource "aws_subnet" "s1" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "192.168.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public"
  }
}

resource "aws_subnet" "s2" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "192.168.1.0/24"
  availability_zone = "ap-south-1b"
  tags = {
    Name = "private"
  }
}
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name = "gw"
  }
}
resource "aws_route_table" "rt" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags = {
    Name = "rt"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.s1.id
  route_table_id = "${aws_route_table.rt.id}"
}

resource "tls_private_key" "xyz"{
 algorithm = "RSA"
  rsa_bits = 4096
}
 resource "local_file" "private_key"{
  content =  tls_private_key.xyz.private_key_pem
  filename = "mykey1.pem"
  file_permission = 0400

}
resource "aws_key_pair" "xy1"{
 key_name = "mykey1"
 public_key = tls_private_key.xyz.public_key_openssh
}

resource "aws_security_group" "sg1" {
  name        = "sg"
  description = "Allow ssh http nd icmpv4"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
ingress {
    description = "icmpv4"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg"
  }
}

resource "aws_security_group" "sg2" {
  name        = "sg2"
  description = "allow mysql"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    description = "mysql"
    security_groups = ["${aws_security_group.sg1.id}"]
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
  
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mysql"
  }
}


resource "aws_instance" "wordpress" {
  ami           = "ami-000cbce3e1b899ebd"
  instance_type = "t2.micro"
  key_name= "mykey1"
  availability_zone= "ap-south-1a"
  associate_public_ip_address = true
  subnet_id="${aws_subnet.s1.id}"
  security_groups = ["${aws_security_group.sg1.id}"]
  tags = {
    Name = "wordpress"
  }
}


resource "aws_instance" "mysql" {
  ami           = "ami-0019ac6129392a0f2"
  instance_type = "t2.micro"
  key_name="mykey1"
  availability_zone= "ap-south-1b"
  subnet_id="${aws_subnet.s2.id}"
  security_groups = ["${aws_security_group.sg2.id}" , "${aws_security_group.mysql_allow.id}"]
  tags = {
    Name = "mysql"
  }
}



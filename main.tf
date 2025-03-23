provider "aws" {
  region = "us-east-1"
  alias  = "east"
}

provider "aws" {
  region = "us-west-1"
  alias  = "west"
}

resource "aws_security_group" "sample-east-sg" {
  provider = aws.east
  name     = "sample-east"

  dynamic "ingress" {
    for_each = [80, 22]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sample-west-sg" {
  provider = aws.west
  name     = "sample-west"

  dynamic "ingress" {
    for_each = [80, 22]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "key-east" {
  provider   = aws.east
  key_name   = "key-east"
  public_key = file("~/.ssh/key-pair.pub")
}

resource "aws_key_pair" "key-west" {
  provider   = aws.west
  key_name   = "key-west"
  public_key = file("~/.ssh/key-pair.pub")
}

resource "aws_instance" "sample-east" {
  provider        = aws.east
  ami             = "ami-084568db4383264d4"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.sample-east-sg.name]
  key_name        = aws_key_pair.key-east.key_name

  tags = {
    Name = "sample-instance-east"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/key-pair")
    host        = "${aws_instance.sample-east.public_ip}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install -y nginx",
      "sudo systemctl restart nginx",
      "sudo systemctl enable nginx"
    ]
  }
  provisioner "local-exec" {
    command = "echo ${aws_instance.sample-east.public_ip}:80"   
  }
}

resource "aws_instance" "sample-west" {
  provider        = aws.west
  ami             = "ami-04f7a54071e74f488"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.sample-west-sg.name]
  key_name        = aws_key_pair.key-west.key_name

  tags = {
    Name = "sample-instance-west"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/key-pair")
    host        = "${aws_instance.sample-west.public_ip}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install -y nginx",
      "sudo systemctl restart nginx",
      "sudo systemctl enable nginx"
    ]
  }
  provisioner "local-exec" {
    command = "echo ${aws_instance.sample-west.public_ip}:80" 
  }
}

output "aws_instance_sample-east" {
  value = aws_instance.sample-east.public_ip
}

output "aws_instance_sample-west" {
  value = aws_instance.sample-west.public_ip
}

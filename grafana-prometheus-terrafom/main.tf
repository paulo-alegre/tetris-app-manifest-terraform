resource "aws_iam_role" "grafana_prom_terraform_role" {
  name = "Grafana-prom-terraform"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}


resource "aws_iam_instance_profile" "grafana_prom_terraform_profile" {
  name = "Grafana-prom-terraform"
  role = aws_iam_role.grafana_prom_terraform_role.name
}


resource "aws_security_group" "grafana-prom-sg" {
  name        = "Grafana-Prom-Security Group"
  description = "Open 22,443,80,9090,3000"

  # Define a single ingress rule to allow traffic on all specified ports
  ingress = [
    for port in [22, 80, 443, 9090, 3000] : {
      description      = "TLS from VPC"
      from_port        = port
      to_port          = port
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "grafana-prom-sg"
  }
}

resource "aws_instance" "grafana-prometheus" {
  ami                    = "ami-0fa377108253bf620"
  instance_type          = "t2.medium"
  key_name               = "ipau"
  vpc_security_group_ids = [aws_security_group.grafana-prom-sg.id]
  user_data              = templatefile("./install_jenkins.sh", {})
  iam_instance_profile   = aws_iam_instance_profile.grafana_prom_terraform_profile.name

  tags = {
    Name = "grafana-prometheus"
  }

  root_block_device {
    volume_size = 12
  }
}

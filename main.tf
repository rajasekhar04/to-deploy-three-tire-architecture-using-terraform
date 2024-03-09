resource "aws_vpc" "vpc1" {
    cidr_block = "10.0.0.0/16"
    instance_tenancy = "default"
    tags = {
      Name="vpc1"
    }
  
}
resource "aws_subnet" "public_1" {
    vpc_id = aws_vpc.vpc1.id
    map_public_ip_on_launch = true
    availability_zone = "ap-south-1a"
    cidr_block = "10.0.0.0/24"
    tags = {
      Name="public-1"
    }
  
}
resource "aws_subnet" "public_2" {
    vpc_id = aws_vpc.vpc1.id
    map_public_ip_on_launch = true
    availability_zone = "ap-south-1b"
    cidr_block = "10.0.1.0/24"
    tags = {
      Name="public-2"
    }
}
resource "aws_subnet" "private_1" {
    vpc_id = aws_vpc.vpc1.id
    map_public_ip_on_launch = true
    availability_zone = "ap-south-1b"
    cidr_block = "10.0.2.0/24"
    tags = {
      Name="private_1"
    }
}
resource "aws_subnet" "private_2" {
    vpc_id = aws_vpc.vpc1.id
    map_public_ip_on_launch = true
    availability_zone = "ap-south-1a"
    cidr_block = "10.0.3.0/24"
    tags = {
      Name="private_2"
    }
}
resource "aws_internet_gateway" "gw" {
    vpc_id = aws_vpc.vpc1.id
    tags = {
      Name="gw"
    }
  
}
resource "aws_route_table" "myroute" {
    vpc_id = aws_vpc.vpc1.id
    route{
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.gw.id
    }
    tags = {
      Name="myroute"
    }
}
resource "aws_route_table_association" "route-a" {
    subnet_id = aws_subnet.public_1.id
    route_table_id = aws_route_table.myroute.id
  
}
resource "aws_route_table_association" "route-b" {
    subnet_id = aws_subnet.private_1.id
    route_table_id = aws_route_table.myroute.id
  
}
resource "aws_instance" "terraform1" {
  ami = "ami-0ba259e664698cbfc"
  instance_type = "t2.micro"
  availability_zone = "ap-south-1a"
  key_name = "ram"
  vpc_security_group_ids = [aws_security_group.raja.id]
  subnet_id = aws_subnet.public_1.id
  associate_public_ip_address = true
  user_data = file("${path.module}/script/userdata.sh")



  tags={
    Name="terraform1"
  }
  
}
resource "aws_instance" "terraform2" {
  ami = "ami-0ba259e664698cbfc"
  instance_type = "t2.micro"
  availability_zone = "ap-south-1a"
  key_name = "ram"
  vpc_security_group_ids = [aws_security_group.raja.id]
  subnet_id = aws_subnet.public_1.id
  associate_public_ip_address = true
  user_data = file("${path.module}/script/userdata.sh")




  tags={
    Name="terraform2"
  }
  
}
resource "aws_security_group" "raja" {
  name="raja"
  vpc_id=aws_vpc.vpc1.id
  ingress{
    from_port=22
    to_port=22
    protocol="tcp"
    cidr_blocks=["0.0.0.0/0"]
  }
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags ={
    Name="raja"
  }
  
}
resource "aws_security_group" "raja2" {
  name="raja2"
  vpc_id=aws_vpc.vpc1.id
  description = "allow inbound traffic from application layer"
  ingress{
    description = "allow inbound traffic from application layer"
    from_port=3306
    to_port=3306
    protocol="tcp"
    cidr_blocks=["0.0.0.0/0"]
  }
  egress {
    from_port = 32768
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags ={
    Name="raja2"
  }

  
}
resource "aws_lb" "my_lb" {
  internal = false
  load_balancer_type = "application"
  subnets = [aws_subnet.public_1.id,aws_subnet.private_1.id]
  
}
resource "aws_lb_target_group" "my-tg" {
  name = "mytg"
  port=80
  protocol = "HTTP"
  vpc_id = aws_vpc.vpc1.id
}
resource "aws_lb_target_group_attachment" "attachment1" {
  target_group_arn = aws_lb_target_group.my-tg.arn
  target_id = aws_instance.terraform1.id
  port=80
  depends_on = [ aws_instance.terraform1 ]
  
}
resource "aws_lb_target_group_attachment" "attachment2" {
  target_group_arn = aws_lb_target_group.my-tg.arn
  target_id = aws_instance.terraform2.id
  port=80
  depends_on = [ aws_instance.terraform2 ]
  
}
resource "aws_lb_listener" "my_lis" {
  load_balancer_arn = aws_lb.my_lb.arn
  port=80
  protocol = "HTTP"
  default_action {
    target_group_arn = "${aws_lb_target_group.my-tg.id}"
    type = "forward"
  }
  
}

resource "aws_db_instance" "rds" {
  db_subnet_group_name = aws_db_subnet_group.rds-2.id 
  engine = "mysql"
  db_name = "rds"
  allocated_storage = 8
  engine_version = "8.0.28"
  instance_class = "db.t2.micro"
  multi_az = true
  username = "rajasekhar"
  password = "raja4567"
  parameter_group_name = "tfgrp"
  vpc_security_group_ids = [aws_security_group.raja2.id]
  skip_final_snapshot = true
}
resource "aws_db_subnet_group" "rds-2" {
  name="rds_1"
  subnet_ids=[aws_subnet.private_1.id,aws_subnet.public_1.id]
  tags={
    Name="rds_2"
  }
  
}
output "myout" {
  description = "arn:aws:elasticloadbalancing:ap-south-1:211125555582:loadbalancer/app/tf-lb-20240309095729053000000001/3fd321ba72ee1c6b"
  value = "tf-lb-20240309095729053000000001-903406924.ap-south-1.elb.amazonaws.com"
}


## VPC
resource "aws_vpc" "s3-test_vpc" {
    cidr_block = "10.0.0.0/16"
    instance_tenancy = "default"
    tags {
     Name = "s3-test_vpc"
   }
}
 
##subnet(1a)
resource "aws_subnet" "public-a" { 
    vpc_id = "${aws_vpc.s3-test_vpc.id}"
    cidr_block = "10.0.0.0/24"
    availability_zone = "ap-northeast-1a"
    tags {
     Name = "s3-test-web_1a"
   }
}
 
##subnet(1c)
resource "aws_subnet" "public-c" { 
    vpc_id = "${aws_vpc.s3-test_vpc.id}"
    cidr_block = "10.0.1.0/24"
    availability_zone = "ap-northeast-1c"
    tags {
     Name = "s3-test-web_1c"
   }
}
 
##route table(1a)
resource "aws_route_table_association" "puclic-a" {
    subnet_id = "${aws_subnet.public-a.id}" 
    route_table_id = "${aws_route_table.public-route.id}" 
}
 
##route table(1c)
resource "aws_route_table_association" "puclic-c" {
    subnet_id = "${aws_subnet.public-c.id}"
    route_table_id = "${aws_route_table.public-route.id}"
}
 
##gateway
resource "aws_internet_gateway" "s3-test-web_GW" {
    vpc_id = "${aws_vpc.s3-test_vpc.id}" 
}
 
##route table add(0.0.0.0/0)
resource "aws_route_table" "public-route" {
    vpc_id = "${aws_vpc.s3-test_vpc.id}"
    route {
      cidr_block = "0.0.0.0/0"
     gateway_id = "${aws_internet_gateway.s3-test-web_GW.id}"
   }
}
 
#security group
resource "aws_security_group" "s3-test-web" {
    name = "s3-test-web"
    description = "s3-test-web"
    vpc_id = "${aws_vpc.s3-test_vpc.id}"
    ingress {
      from_port = 80 
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
 }
    ingress {
      from_port = 443
      to_port = 443
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
 }

 # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
 }
    tags {
      Name = "s3-test-web"
   }
}
 
##EC2(s3-test-web01) ##key_nameの変更
resource "aws_instance" "s3-test-web01" {
    ami = "${var.ami}"
    instance_type = "${var.instance_type}"
    disable_api_termination = false #削除保護(destroyした時にエラー出るので一旦無効)
    key_name = "${aws_key_pair.auth.id}"
    vpc_security_group_ids = ["${aws_security_group.s3-test-web.id}"] 
    subnet_id = "${aws_subnet.public-a.id}" 
    ebs_block_device = {
      device_name = "/dev/sdf"
      volume_type = "gp2"
      volume_size = "30"
    }
    tags {
     Name = "s3-test-web01"
   }
}

##追加
resource "aws_key_pair" "auth" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}


 
##EIPの紐付け(s3-test-web01)
resource "aws_eip" "s3-test-web01" {
    instance = "${aws_instance.s3-test-web01.id}"
    vpc = true
}

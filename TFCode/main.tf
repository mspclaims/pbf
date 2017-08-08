//
module "vpc" {
  source                  = "github.com/paybyphone/terraform_aws_vpc"
  vpc_network_address     = "10.0.0.0/24"
  public_subnet_addresses = ["10.0.0.0/25", "10.0.0.128/25"]
  project_path            = ""
}

resource "aws_security_group" "vbdemo_security_group" {
  name = "vbdemo-sg"

  description = "VB demo security group."

  vpc_id = "${module.vpc.vpc_id}"
}

resource "aws_security_group_rule" "ssh_ingress_access" {
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = [ "0.0.0.0/0" ] 
  security_group_id = "${aws_security_group.vbdemo_security_group.id}"
}

resource "aws_security_group_rule" "http_8080_ingress_access" {
  type = "ingress"
  from_port = 8080
  to_port = 8080
  protocol = "tcp"
  cidr_blocks = [ "0.0.0.0/0" ] 
  security_group_id = "${aws_security_group.vbdemo_security_group.id}"
}

resource "aws_security_group_rule" "http_8000_ingress_access" {
  type = "ingress"
  from_port = 8000
  to_port = 8000
  protocol = "tcp"
  cidr_blocks = [ "0.0.0.0/0" ] 
  security_group_id = "${aws_security_group.vbdemo_security_group.id}"
}

resource "aws_security_group_rule" "pg_ingress_access" {
  type = "ingress"
  from_port = 5432
  to_port = 5432
  protocol = "tcp"
  cidr_blocks = [ "0.0.0.0/0" ] 
  security_group_id = "${aws_security_group.vbdemo_security_group.id}"
}

resource "aws_security_group_rule" "egress_access" {
  type = "egress"
  from_port = 0
  to_port = 65535
  protocol = "tcp"
  cidr_blocks = [ "0.0.0.0/0" ]
  security_group_id = "${aws_security_group.vbdemo_security_group.id}"
}
resource "aws_db_subnet_group" "main" {
  name       = "main"
  subnet_ids = ["${module.vpc.public_subnet_ids}"]
  tags {
    Name = "VB DB subnet group"
  }
}

resource "aws_db_instance" "todosdemo" {  
  allocated_storage        = 5 # gigabytes
  backup_retention_period  = 1   # in days
  db_subnet_group_name     = "${aws_db_subnet_group.main.name}"
  engine                   = "postgres"
  engine_version           = "9.5.4"
  identifier               = "todosdemo"
  instance_class           = "db.t2.micro"
  multi_az                 = false
  name                     = "todosdemo"
  # parameter_group_name     = "mydbparamgroup1" # if you have tuned it
  password                 = "${trimspace(file("${path.module}/shared/todosdemo-password.txt"))}"
  port                     = 5432
  publicly_accessible      = true
  storage_encrypted        = false # you should always do this
  storage_type             = "gp2"
  username                 = "todosdemo"
  vpc_security_group_ids   = ["${aws_security_group.vbdemo_security_group.id}"]
} 

resource "template_file" "client_cloud_config" {
    filename = "./shared/client_cloud_config.template"
    vars {
		db_address = "${aws_db_instance.todosdemo.address}"
    }
}

resource "aws_instance" "vbdemo1" {
  instance_type = "t2.micro"
  vpc_security_group_ids = [ "${aws_security_group.vbdemo_security_group.id}" ]
  associate_public_ip_address = true
  user_data = "${template_file.client_cloud_config.rendered}"
  tags {
    Name = "vbdemo1"
  }
  key_name = "vb_hyper"
  ami = "ami-1b72e37b" 
  # other linux nano hvm
  availability_zone = "us-west-2a"
  subnet_id = "${module.vpc.public_subnet_ids[0]}"
}

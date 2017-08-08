//
module "vpc" {
  source                  = "github.com/paybyphone/terraform_aws_vpc"
  vpc_network_address     = "10.0.0.0/24"
  public_subnet_addresses = ["10.0.0.0/25", "10.0.0.128/25"]
  project_path            = ""
}
module "alb" {
       source              = "github.com/paybyphone/terraform_aws_alb"
       listener_subnet_ids = ["${module.vpc.public_subnet_ids}"]
	   listener_port = "8000"
	   default_target_group_port = "8000"
       project_path        = ""
     }
     
module "autoscaling_group" {
   source             = "github.com/paybyphone/terraform_aws_asg"
   subnet_ids         = ["${module.vpc.public_subnet_ids}"]
   additional_security_group_ids = ["${aws_security_group.vbdemo_security_group.id}"]
   image_filter_type  = "image-id"
   image_filter_value = "ami-cd36d7b5"
   alb_service_port = "8000"
   alb_listener_arn   = "${module.alb.alb_listener_arn}"
   min_instance_count = "1"
   max_instance_count = "2"
   project_path       = ""
   enable_alb = "true"
   user_data = "${template_file.user_data.rendered}"
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

resource "aws_db_subnet_group" "mainasg" {
  name       = "mainasg"
  subnet_ids = ["${module.vpc.public_subnet_ids}"]
  tags {
    Name = "VB DB subnet group"
  }
}
resource "aws_db_instance" "todosasg" {  
  allocated_storage        = 5 # gigabytes
  backup_retention_period  = 1   # in days
  db_subnet_group_name     = "${aws_db_subnet_group.mainasg.name}"
  engine                   = "postgres"
  engine_version           = "9.5.4"
  identifier               = "todosasg"
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

resource "template_file" "user_data" {
  template = "${file("${path.module}/shared/client_cloud_config.template")}"
  vars {
		db_address = "${aws_db_instance.todosasg.address}"
    }
	lifecycle {
		create_before_destroy = true
	}
}

resource "aws_launch_configuration" "userdataidx" {
  name = "userdataidx"
  image_id = "ami-cd36d7b5"
  instance_type = "t2.nano"
  security_groups = ["${aws_security_group.vbdemo_security_group.id}"]
  vpc_classic_link_security_groups = []
  associate_public_ip_address = false
  ebs_optimized = false
  key_name = "vb_hyper"
  #iam_instance_profile = "${aws_iam_instance_profile.iam_profile.id}"
  lifecycle {
    create_before_destroy = true
  }
}

# pbf

Set of projects/Terraform scripts to provision environment for a sample node.js todo app which can be found at https://github.com/waiyaki/postgres-express-node-tutorial

Limitations:
- Implementation is using "free-tier" EC2 / RDS instances
- Terraform is used for bringing AWS components up
- Docker is used as a tool for provisioning the AMI  
- Following terraform modules are used:
	- https://github.com/paybyphone/terraform_aws_vpc
	- https://github.com/paybyphone/terraform_aws_alb
	- https://github.com/paybyphone/terraform_aws_asg
	- https://www.terraform.io/docs/providers/aws/r/db_instance.html
	
Notes:
Repository consists of three projects:
- sample node.js todo app (PEN) - cloned from https://github.com/waiyaki/postgres-express-node-tutorial and modified a bit:
	- read config variables from environment variables
	- expose Swagger API docs (only couple of endpoints annotated)
	- dockerizied
- terraform project (TFCode) to provision stand-alone EC2 instance (with PEN application deployed as docker container) and RDS DB 
	- needed to ensure that application works before creating an AMI image
- terraform project (TFASG) to provision "production ready" infrastructure which consist of autoscaling group and load balancer

How to make it work:
- download all projects locally
- open PEN folder
- run 'npm install'
- run 'npm install --save sequelize pg pg-hstore'
- run 'docker build todos --t <yourname_at_docker.io>/vbdemo'
- run 'docker login' and login to your docker hub account
- run 'docker push <yourname_at_docker.io>/vbdemo:latest'
- review and update /shared/client_cloud_config.template file in both TF projects to use your name in the line 'docker pull <yourname_at_docker.io>/vbdemo
- install terraform on EC2 instance in AWS [optional]
- open TFCode folder 
- run 'terraform plan'
- run 'terraform apply'
- confirm that EC2 was created properly (navigate to port 8000/api-docs) 
- create AMI out of the EC2 instance and take note of its image_id
- open TFASG folder
- update main.tf aws_launch_configuration to use new image_id  
- run 'terraform plan'
- run 'terraform apply'
- confirm that environment setup properly by checking <load balancer public URL>:8000/api-docs


	

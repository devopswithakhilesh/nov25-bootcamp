879381241087.dkr.ecr.ap-south-1.amazonaws.com/nov25-class5

<aws_account_id>.dkr.ecr.<aws_region>.amazonaws.com/<repo_name>


docker build -t 879381241087.dkr.ecr.ap-south-1.amazonaws.com/nov25-class5:1.0 .


# aws cli install
https://docs.aws.amazon.com/cli/v1/userguide/cli-chap-install.html

aws configure

code ~/.aws/config
code ~/.aws/credentials

aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin 879381241087.dkr.ecr.ap-south-1.amazonaws.com


# install docker on ec2


sudo dnf update -y 

sudo dnf install -y docker

sudo systemctl start docker

sudo systemctl enable docker

sudo usermod -aG docker ec2-user


# run docker container on ec2

docker run -td -p 5000:5000 879381241087.dkr.ecr.ap-south-1.amazonaws.com/nov25-class5:1.0

in ec2 -> you need a instace profile with EC2InstanceProfileForImageBuilderECRContainerBuilds policy
to pull the ecr image

- cretae an iam role , attach EC2InstanceProfileForImageBuilderECRContainerBuilds policy
and add that to ec2

- in ec2 to ecr login : aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin 879381241087.dkr.ecr.ap-south-1.amazonaws.com



docker build  --platform linux/amd64 -t 879381241087.dkr.ecr.ap-south-1.amazonaws.com/nov25-class5:2.0 .


# rds

user postgres
pass Admin123
host nov25-class5.cvik8accw2tk.ap-south-1.rds.amazonaws.com
port 5432

dbname: postgres


export DATABASE_URL=postgresql://postgres:Admin123@nov25-class5.cvik8accw2tk.ap-south-1.rds.amazonaws.com:5432/postgres


http://<PUBLIC_IP>:5000/

docker exec -it 9ea77ddc318c bash

psql -h nov25-class5.cvik8accw2tk.ap-south-1.rds.amazonaws.com -p 5432 -U postgres -d postgres


docker run -e DATABASE_URL=postgresql://postgres:Admin123@nov25-class5.cvik8accw2tk.ap-south-1.rds.amazonaws.com:5432/postgres  -td -p 5000:5000 879381241087.dkr.ecr.ap-south-1.amazonaws.com/nov25-class5:2.0




DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
mkdir -p $DOCKER_CONFIG/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v5.0.0/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose

chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
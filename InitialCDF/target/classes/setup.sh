#Spin - nifi large instance
aws ec2 run-instances --image-id ami-087c2c50437d0b80d --count 1 --instance-type t2.large --key-name ec2pem --user-data file:///Users/chaitanyachennur/Downloads/setup.sh --security-group-ids sg-088eaa2dd16ed7180

aws ec2 run-instances --image-id ami-087c2c50437d0b80d --count 1 --instance-type t2.micro --key-name ec2pem --user-data file:///Users/chaitanyachennur/Downloads/setup_postgres.sh --security-group-ids sg-0f76841fc8f7ecd7e

#!/bin/bash
sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf repolist -v
dnf list docker-ce --showduplicates | sort -r
sudo dnf -y  install docker-ce --nobest
sudo systemctl enable --now docker
sudo useradd nifi
echo 6 |sudo passwd --stdin nifi
sudo docker pull apache/nifi
sudo docker run --name nifi -p 8080:8080 -d apache/nifi:latest
until [ `sudo docker ps --filter status=running --format '{{.ID}}' | wc -l` -gt 1 ]; do
    sleep 10
    echo "Wait 10 sec"
done
curl https://jdbc.postgresql.org/download/postgresql-42.2.9.jar --output postgresql-42.2.9.jar
containerid=`sudo docker ps --format '{{.ID}}'`
sudo docker exec -d $containerid mkdir -p /opt/nifi/nifi-files/drivers/
sudo docker exec -d $containerid chown nifi:nifi /opt/nifi/nifi-files/drivers/
sudo docker cp /postgresql-42.2.9.jar $containerid:/opt/nifi/nifi-files/drivers/

#Spin - postgres micro instance
sudo yum install postgresql-server
systemctl enable postgresql.service
systemctl start postgresql.service
sudo su - postgres -c 'psql -c "create database cs_livy"'
sudo su - postgres -c 'psql -d cs_livy -c "create schema livy"'
sudo su - postgres -c 'psql -d cs_livy -c "CREATE TABLE livy.livy_pool(flowname character varying(100) COLLATE pg_catalog."default",pool_size integer,allocated integer,post_request character varying(10000000) COLLATE pg_catalog."default",enable character varying(10) COLLATE pg_catalog."default",pool_description character varying(4000) COLLATE pg_catalog."default")"'
sudo su - postgres -c 'psql -d cs_livy -c "CREATE TABLE livy.livy_sessions(flowname character varying(100) COLLATE pg_catalog."default",sessionid character varying(20) COLLATE pg_catalog."default",applicationid character varying(1000) COLLATE pg_catalog."default",last_updated timestamp without time zone,app_status character varying(50) COLLATE pg_catalog."default",create_ts timestamp without time zone,description character varying(10000) COLLATE pg_catalog."default",status character varying(100) COLLATE pg_catalog."default")"'
sudo su - postgres -c 'psql -d cs_livy -c "insert into livy.livy_pool(flowname,pool_size,post_request,enable,pool_description) values ('wetherforecast',2,'{"kind" : "spark","proxyUser" : "default","queue" : "default","numExecutors" : 3,“driverMemory”: “2G”,"executorMemory" : "2G",“jars”: [“hdfs:///codebase/InitialCDF-1.0-SNAPSHOT.jar","hdfs:///codebase/extra/redshift-jdbc42-1.2.1.1001.jar","hdfs:///codebase/extra/spark-avro_2.11-3.2.0.jar","hdfs:///codebase/extra/spark-redshift_2.11-2.0.1.jar","hdfs:///codebase/extra/netcdf-4.2.jar","hdfs:///codebase/extra/commons-configuration2-2.0.jar”],"conf" : {"spark.speculation" : "false"}}','Y','wetherforcast usecase')"'

#run from local
## upload template to nifi
curl -k -F template=@usecase.xml -X POST http://54.201.253.62:8080/nifi-api/process-groups/root/templates/upload
## change varibles



#EMR

scp -i ec2pem.pem /Users/chaitanyachennur/Downloads/commons-configuration2-2.0.jar hadoop@ec2-34-223-52-130.us-west-2.compute.amazonaws.com:/tmp
scp -i ec2pem.pem netcdf-4.2.jar hadoop@ec2-34-223-52-130.us-west-2.compute.amazonaws.com:/tmp
scp -i ec2pem.pem ./Workbench-personal/InitialCDF/target/InitialCDF-1.0-SNAPSHOT.jar hadoop@ec2-34-223-52-130.us-west-2.compute.amazonaws.com:/tmp
scp -i ec2pem.pem spark-redshift_2.11-2.0.1.jar hadoop@ec2-34-223-52-130.us-west-2.compute.amazonaws.com:/tmp
scp -i ec2pem.pem /Users/chaitanyachennur/Downloads/spark-avro_2.11-4.0.0.jar hadoop@ec2-34-223-52-130.us-west-2.compute.amazonaws.com:/tmp
scp -i ec2pem.pem /Users/chaitanyachennur/Downloads/redshift-jdbc42-1.2.1.1001.jar hadoop@ec2-34-223-52-130.us-west-2.compute.amazonaws.com:/tmp

hdfs dfs -copyFromLocal /tmp/*.jar /codebase/extra/

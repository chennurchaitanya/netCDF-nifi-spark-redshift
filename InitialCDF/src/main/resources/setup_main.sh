aws configure
Key Id =
Access key =


path="/Users/chaitanyachennur/Downloads/"
curl -o setup.sh  https://raw.githubusercontent.com/chaitanyaexplore/netCDF-nifi-spark-redshift/master/InitialCDF/src/main/resources/setup.sh
aws ec2 run-instances --image-id ami-087c2c50437d0b80d --count 1 --instance-type t2.large --key-name ec2pem --user-data file:///Users/chaitanyachennur/Downloads/setup.sh --security-group-ids sg-088eaa2dd16ed7180

curl -o $path/setup_postgres.sh  https://raw.githubusercontent.com/chaitanyaexplore/netCDF-nifi-spark-redshift/master/InitialCDF/src/main/resources/setup_postgres.sh
aws ec2 run-instances --image-id ami-087c2c50437d0b80d --count 1 --instance-type t2.micro --key-name ec2pem --user-data file://$path/setup_postgres.sh --security-group-ids sg-0f76841fc8f7ecd7e

curl -o $path/met_wf_nifi_flow_template.xml https://raw.githubusercontent.com/chaitanyaexplore/netCDF-nifi-spark-redshift/master/InitialCDF/src/main/resources/nifi/met_wf_nifi_flow_template.xml
curl -k -F template=@$path/met_wf_nifi_flow_template.xml -X POST http://54.201.253.62:8080/nifi-api/process-groups/root/templates/upload
## change varibles

#EMR
curl -o $path/emr-config.json https://raw.githubusercontent.com/chaitanyaexplore/netCDF-nifi-spark-redshift/master/InitialCDF/src/main/resources/nifi/met_wf_nifi_flow_template.xml
create asw EMR cluster with advanced options (services : hadoop,spark,livy)

scp -i ec2pem.pem /Users/chaitanyachennur/Downloads/commons-configuration2-2.0.jar hadoop@ec2-34-223-52-130.us-west-2.compute.amazonaws.com:/tmp
scp -i ec2pem.pem netcdf-4.2.jar hadoop@ec2-34-223-52-130.us-west-2.compute.amazonaws.com:/tmp
scp -i ec2pem.pem ./Workbench-personal/InitialCDF/target/InitialCDF-1.0-SNAPSHOT.jar hadoop@ec2-34-223-52-130.us-west-2.compute.amazonaws.com:/tmp
scp -i ec2pem.pem spark-redshift_2.11-2.0.1.jar hadoop@ec2-34-223-52-130.us-west-2.compute.amazonaws.com:/tmp
scp -i ec2pem.pem /Users/chaitanyachennur/Downloads/spark-avro_2.11-4.0.0.jar hadoop@ec2-34-223-52-130.us-west-2.compute.amazonaws.com:/tmp
scp -i ec2pem.pem /Users/chaitanyachennur/Downloads/redshift-jdbc42-1.2.1.1001.jar hadoop@ec2-34-223-52-130.us-west-2.compute.amazonaws.com:/tmp

hdfs dfs -copyFromLocal /tmp/*.jar /codebase/extra/

#3 - redshift
aws redshift create-cluster --node-type dc2.large --number-of-nodes 1 --master-username adminuser --master-user-password Santrotvs@123 --cluster-identifier redshift_cluster

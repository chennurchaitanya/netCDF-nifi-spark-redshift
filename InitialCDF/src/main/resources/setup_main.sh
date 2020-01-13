aws configure
Key Id =
Access key =


path="/Users/chaitanyachennur/Downloads"
curl -o $path/setup.sh  https://raw.githubusercontent.com/chaitanyaexplore/netCDF-nifi-spark-redshift/master/InitialCDF/src/main/resources/nifi/setup.sh
aws ec2 run-instances --image-id ami-087c2c50437d0b80d --count 1 --instance-type t2.large --key-name ec2pem --user-data file://$path/setup.sh --security-group-ids sg-088eaa2dd16ed7180

curl -o $path/setup_postgres.sh  https://raw.githubusercontent.com/chaitanyaexplore/netCDF-nifi-spark-redshift/master/InitialCDF/src/main/resources/postgres/setup_postgres.sh
aws ec2 run-instances --image-id ami-087c2c50437d0b80d --count 1 --instance-type t2.micro --key-name ec2pem --user-data file://$path/setup_postgres.sh --security-group-ids sg-0f76841fc8f7ecd7e

## wait for nifi ui to be up .. nifi public ip : 8080/nifi

## import nifi flow template
curl -o $path/met_wf_nifi_flow_template.xml https://raw.githubusercontent.com/chaitanyaexplore/netCDF-nifi-spark-redshift/master/InitialCDF/src/main/resources/nifi/met_wf_nifi_flow_template.xml
curl -k -F template=@$path/met_wf_nifi_flow_template.xml -X POST http://35.164.95.252:8080/nifi-api/process-groups/root/templates/upload
## create flow from template by drag into palette

## Postgres control service
## check for any failues with nifi instance @ /var/log/cloud-init-output.log
## run commands if anything failed.




#EMR
curl -o $path/emr-config.json https://raw.githubusercontent.com/chaitanyaexplore/netCDF-nifi-spark-redshift/master/InitialCDF/src/main/resources/nifi/met_wf_nifi_flow_template.xml
#Manually create EMR with advanced options (services : hadoop,spark,livy)
#Give permissions to security group master ports 8998

curl -o /tmp/commons-configuration2-2.0.jar https://repo1.maven.org/maven2/org/apache/commons/commons-configuration2/2.0/commons-configuration2-2.0.jar
curl -o /tmp/netcdf-4.2.jar https://repo1.maven.org/maven2/edu/ucar/netcdf/4.2/netcdf-4.2.jar
curl -o /tmp/spark-redshift_2.11-2.0.1.jar https://repo1.maven.org/maven2/com/databricks/spark-redshift_2.11/2.0.1/spark-redshift_2.11-2.0.1.jar
curl -o /tmp/spark-avro_2.11-4.0.0.jar https://repo1.maven.org/maven2/com/databricks/spark-avro_2.11/4.0.0/spark-avro_2.11-4.0.0.jar
curl -o /tmp/redshift-jdbc42-1.2.1.1001.jar https://repository.mulesoft.org/nexus/content/repositories/public/com/amazon/redshift/redshift-jdbc42/1.2.1.1001/redshift-jdbc42-1.2.1.1001.jar
curl -o /tmp/InitialCDF-1.0-SNAPSHOT.jar https://github.com/chaitanyaexplore/netCDF-nifi-spark-redshift/raw/master/InitialCDF/target/InitialCDF-1.0-SNAPSHOT.jar
hdfs dfs -mkdir -p /codebase/extra/
hdfs dfs -copyFromLocal /tmp/*.jar /codebase/extra/

#3 - redshift
aws redshift create-cluster --node-type dc2.large --cluster-type single-node --master-username adminuser --master-user-password Santrotvs#123 --cluster-identifier redshift-cluster

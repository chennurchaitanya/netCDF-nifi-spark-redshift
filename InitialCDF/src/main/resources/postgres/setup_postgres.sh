#!/bin/bash
sudo yum install -y postgresql-server
sudo service postgresql initdb
sudo systemctl enable postgresql.service
sudo sed -i 's/'localhost'/'*'/g' /var/lib/pgsql/data/postgresql.conf
sudo sed -i 's/'#listen_addresses'/'listen_addresses'/g' /var/lib/pgsql/data/postgresql.conf
sudo su - postgres -c "echo 'host    all             all             0.0.0.0/0               md5' >>  /var/lib/pgsql/data/pg_hba.conf"
sudo systemctl start postgresql.service
sudo su - postgres
sudo su - postgres -c 'psql -c "create database cs_livy"'
sudo su - postgres -c 'psql -c "create user cchennur with password 'santrotvs'"'
sudo su - postgres -c 'psql -c "alter user cchennur with SUPERUSER"'
sudo su - postgres -c 'psql -d cs_livy -c "create schema livy"'
sudo su - postgres -c 'psql -d cs_livy 'grant all on schema to cchennur'
sudo su - postgres -c 'psql -d cs_livy -c "CREATE TABLE livy.livy_pool(flowname character varying(100) COLLATE pg_catalog."default",pool_size integer,allocated integer,post_request character varying(10000000) COLLATE pg_catalog."default",enable character varying(10) COLLATE pg_catalog."default",pool_description character varying(4000) COLLATE pg_catalog."default")"'
sudo su - postgres -c 'psql -d cs_livy -c "CREATE TABLE livy.livy_sessions(flowname character varying(100) COLLATE pg_catalog."default",sessionid character varying(20) COLLATE pg_catalog."default",applicationid character varying(1000) COLLATE pg_catalog."default",last_updated timestamp without time zone,app_status character varying(50) COLLATE pg_catalog."default",create_ts timestamp without time zone,description character varying(10000) COLLATE pg_catalog."default",status character varying(100) COLLATE pg_catalog."default")"'
sudo su - postgres -c 'psql -d cs_livy -c "insert into livy.livy_pool(flowname,pool_size,post_request,enable,pool_description) values ('wetherforecast',2,'{"kind" : "spark","proxyUser" : "default","queue" : "default","numExecutors" : 3,“driverMemory”: “2G”,"executorMemory" : "2G",“jars”: [“hdfs:///codebase/InitialCDF-1.0-SNAPSHOT.jar","hdfs:///codebase/extra/redshift-jdbc42-1.2.1.1001.jar","hdfs:///codebase/extra/spark-avro_2.11-3.2.0.jar","hdfs:///codebase/extra/spark-redshift_2.11-2.0.1.jar","hdfs:///codebase/extra/netcdf-4.2.jar","hdfs:///codebase/extra/commons-configuration2-2.0.jar”],"conf" : {"spark.speculation" : "false"}}','Y','wetherforcast usecase')"'



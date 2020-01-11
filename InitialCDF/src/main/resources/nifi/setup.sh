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
until [ `sudo docker ps --filter status=running --format '{{.ID}}' | wc -l` -gt 0 ]; do
    sleep 10
    echo "Wait 10 sec"
done
curl https://jdbc.postgresql.org/download/postgresql-42.2.9.jar --output postgresql-42.2.9.jar
containerid=`sudo docker ps --format '{{.ID}}'`
sudo docker exec -it $containerid mkdir -p /opt/nifi/nifi-files/drivers/
sudo docker exec -it $containerid chown nifi:nifi /opt/nifi/nifi-files/drivers/
curl https://jdbc.postgresql.org/download/postgresql-42.2.9.jar --output postgresql-42.2.9.jar
sudo docker cp postgresql-42.2.9.jar $containerid:/opt/nifi/nifi-files/drivers/

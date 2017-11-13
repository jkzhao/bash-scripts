#!/bin/bash
# Jenkins机器：编译完成后，build生成一个新版本的镜像，push到远程docker仓库

# Variables
JENKINS_WAR_HOME='/home/jenkins/.jenkins/workspace/godseyeBranchForNov/godseye-container/target'
DOCKERFILE_HOME='/home/jenkins/docker-file/godseye_war'
HARBOR_IP='172.16.206.32'
REPOSITORIES='godseye_war/godseye'
HARBOR_USER='jkzhao'
HARBOR_USER_PASSWD='Wisedu123'
HARBOR_USER_EMAIL='01115004@wisedu.com'

# Copy the newest war to docker-file directory.
\cp -f ${JENKINS_WAR_HOME}/godseye-container-wisedu.war ${DOCKERFILE_HOME}/godseye.war 

# Delete image early version.
sudo docker login -u ${HARBOR_USER} -p ${HARBOR_USER_PASSWD} -e ${HARBOR_USER_EMAIL} ${HARBOR_IP}  
IMAGE_ID=`sudo docker images | grep ${REPOSITORIES} | awk '{print $3}'`
if [ -n "${IMAGE_ID}" ];then
    sudo docker rmi ${IMAGE_ID}
fi

# Build image.
cd ${DOCKERFILE_HOME}
TAG=`date +%Y%m%d-%H%M%S`
sudo docker build -t ${HARBOR_IP}/${REPOSITORIES}:${TAG} . &>/dev/null

# Push to the harbor registry.
sudo docker push ${HARBOR_IP}/${REPOSITORIES}:${TAG} &>/dev/null

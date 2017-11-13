#!/bin/bash
# 拉取镜像，发布
HARBOR_IP='172.16.206.32'
REPOSITORIES='godseye_war/godseye'
HARBOR_USER='jkzhao'
HARBOR_USER_PASSWD='Wisedu123'

# 登录harbor
#docker login -u ${HARBOR_USER} -p ${HARBOR_USER_PASSWD} ${HARBOR_IP}

# Stop container, and delete the container.
CONTAINER_ID=`docker ps | grep "godseye_web" | awk '{print $1}'`
if [ -n "$CONTAINER_ID" ]; then
    docker stop $CONTAINER_ID
    docker rm $CONTAINER_ID
else #如果容器启动时失败了，就需要docker ps -a才能找到那个容器
    CONTAINER_ID=`docker ps -a | grep "godseye_web" | awk '{print $1}'`
    if [ -n "$CONTAINER_ID" ]; then  # 如果是第一次在这台机器上拉取运行容器，那么docker ps -a也是找不到这个容器的
        docker rm $CONTAINER_ID
    fi
fi

# Delete godseye_web image early version.
IMAGE_ID=`sudo docker images | grep ${REPOSITORIES} | awk '{print $3}'`
if [ -n "${IMAGE_ID}" ];then
    docker rmi ${IMAGE_ID}
fi

# Pull image.
TAG=`curl -s http://${HARBOR_IP}/api/repositories/${REPOSITORIES}/tags | jq '.[-1]' | sed 's/\"//g'` #最后的sed是为了去掉tag前后的双引号
docker pull ${HARBOR_IP}/${REPOSITORIES}:${TAG} &>/dev/null

# Run.
docker run -d --name godseye_web -p 8080:8080 ${HARBOR_IP}/${REPOSITORIES}:${TAG}

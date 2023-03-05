
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
ARG java_image_tag=11-jre-slim

FROM openjdk:${java_image_tag}

ARG spark_uid=1000
ARG spark_gid=1000
#RUN groupadd -r spark && useradd -r -u ${spark_uid} -g ${spark_gid} -G spark spark
#RUN groupadd -g ${spark_gid} spark && useradd -u ${spark_uid} -g ${spark_gid} -m -s /bin/bash spark
#RUN chown -R spark:spark /opt
#    chown -R ${spark_uid}:${spark_gid} /opt
RUN groupadd --gid ${spark_gid} spark && \
    useradd --uid ${spark_uid} --gid ${spark_gid} -m spark
    #sudo chown -R spark:spark /opt


# Before building the docker image, first build and make a Spark distribution following
# the instructions in https://spark.apache.org/docs/latest/building-spark.html.
# If this docker file is being used in the context of building your images from a Spark
# distribution, the docker build command should be invoked from the top level directory
# of the Spark distribution. E.g.:
# docker build -t spark:latest -f kubernetes/dockerfiles/spark/Dockerfile .

RUN set -ex && \
    sed -i 's/http:\/\/deb.\(.*\)/https:\/\/deb.\1/g' /etc/apt/sources.list && \
    apt-get update && \
    ln -s /lib /lib64 && \
    apt-get install -y sudo && \
    touch /etc/sudoers.d/spark && \
    sudo chown -R spark:spark /opt && \
    apt install -y bash tini libc6 libpam-modules krb5-user libnss3 procps && \
    mkdir -p /opt/spark && \
    mkdir -p /opt/spark/examples && \
    mkdir -p /opt/spark/work-dir && \
    touch /opt/spark/RELEASE && \
    rm /bin/sh && \
    ln -sv /bin/bash /bin/sh && \
#    echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su && \
 #   chgrp spark /etc/passwd && chmod ug+rw /etc/passwd && \
    #echo "spark ALL=\(root\) NOPASSWD:ALL" > /etc/sudoers.d/spark && \
    echo 'spark ALL=(root) NOPASSWD:ALL' | sudo EDITOR='tee -a' visudo && \
    chmod 0440 /etc/sudoers.d/spark && \
    rm -rf /var/cache/apt/*

COPY jars /opt/spark/jars
COPY bin /opt/spark/bin
COPY sbin /opt/spark/sbin
COPY kubernetes/dockerfiles/spark/entrypoint.sh /opt
COPY kubernetes/dockerfiles/spark/decom.sh /opt
COPY examples /opt/spark/examples
COPY kubernetes/tests /opt/spark/tests
COPY data /opt/spark/data

ENV SPARK_HOME /opt/spark

WORKDIR /opt
RUN chmod g+w /opt/spark/work-dir
RUN chmod a+x /opt/decom.sh
RUN chmod 777 -R /opt
RUN chmod 777 -R /tmp
RUN sudo chown -R spark:spark /opt

ENTRYPOINT [ "/opt/entrypoint.sh" ]
EXPOSE 4040

# Specify the User that the actual main process will run as
USER spark

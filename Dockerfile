FROM ubuntu:22.04 AS hadoop_zoo

RUN apt update && apt install -y cron openjdk-8-jdk ssh sudo
RUN apt autoclean && apt autoremove
RUN addgroup hadoop
RUN adduser --disabled-password --ingroup hadoop hadoop

ENV HADOOP_HOME=/usr/local/hadoop ZOOKEEPER_HOME=/usr/local/zookeeper
ENV PATH=$PATH:$ZOOKEEPER_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin

ADD https://dlcdn.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz /tmp
RUN tar -xzf /tmp/hadoop-3.3.6.tar.gz -C /usr/local && \
    rm /tmp/hadoop-3.3.6.tar.gz && \
    mv /usr/local/hadoop-3.3.6 $HADOOP_HOME && \
    chown -R hadoop:hadoop $HADOOP_HOME

ADD https://dlcdn.apache.org/zookeeper/zookeeper-3.8.4/apache-zookeeper-3.8.4-bin.tar.gz /tmp
RUN tar -xzf /tmp/apache-zookeeper-3.8.4-bin.tar.gz -C /usr/local && \
    rm /tmp/apache-zookeeper-3.8.4-bin.tar.gz && \
    mv /usr/local/apache-zookeeper-3.8.4-bin $ZOOKEEPER_HOME && \
    chown -R hadoop:hadoop $ZOOKEEPER_HOME

RUN echo "root:123" | chpasswd && \
    echo 'hadoop ALL=(ALL:ALL) NOPASSWD:ALL' >> /etc/sudoers

USER hadoop:hadoop
RUN ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
    chmod og-wx ~/.ssh/authorized_keys

WORKDIR /home/hadoop
RUN sudo mkdir /home/shared && \
    mkdir /home/hadoop/codes && \
    sudo chown -R hadoop:hadoop /home/shared && \
    sudo chmod -R 777 /home/shared && \
    sudo chmod -R 777 /home/hadoop/codes
COPY --chown=hadoop:hadoop --chmod=777 start-script.sh .
VOLUME [ "$HADOOP_HOME/etc/hadoop/" ]
ENTRYPOINT [ "./start-script.sh" ]


FROM hadoop_zoo AS hbase

ENV HBASE_HOME=/usr/local/hbase PATH=$PATH:/usr/local/hbase/bin

ADD --chown=hadoop:hadoop https://dlcdn.apache.org/hbase/2.5.11/hbase-2.5.11-bin.tar.gz /usr/local
RUN sudo tar -xzf /usr/local/hbase-2.5.11-bin.tar.gz -C /usr/local && \
    sudo mv /usr/local/hbase-2.5.11 $HBASE_HOME && \
    sudo chown -R hadoop:hadoop $HBASE_HOME && \
    sudo rm /usr/local/hbase-2.5.11-bin.tar.gz

COPY --chown=hadoop:hadoop --chmod=777 hbase-script.sh .
ENTRYPOINT [ "./hbase-script.sh" ]

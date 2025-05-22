FROM ubuntu:22.04 AS hadoop

RUN apt update && apt install -y cron openjdk-8-jdk ssh sudo
RUN apt autoclean && apt autoremove
RUN addgroup hadoop
RUN adduser --disabled-password --ingroup hadoop hadoop

ENV HADOOP_HOME=/usr/local/hadoop
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin

ADD https://dlcdn.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz /tmp
RUN tar -xzf /tmp/hadoop-3.3.6.tar.gz -C /usr/local && \
    rm /tmp/hadoop-3.3.6.tar.gz && \
    mv /usr/local/hadoop-3.3.6 $HADOOP_HOME && \
    chown -R hadoop:hadoop $HADOOP_HOME

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

#!/usr/bin/bash
sudo service ssh start
if
    hostname | grep -q "master";
then
    zkServer.sh start
    if
        [ ! -f ~/.makCluster ];
    then
        ID=$(hostname | tail -c 2)
        echo $ID > $HADOOP_HOME/../zookeeper/data/myid;
        zkServer.sh restart;
        hdfs --daemon start journalnode;
        if
            [ "$ID" == "1" ];
        then
            echo '' > /usr/local/hadoop/etc/hadoop/workers;
            hdfs namenode -format;
            hdfs zkfc -formatZK;
        else
            until hdfs haadmin -checkHealth nn1
            do
                echo "Waiting for namenode to be up..."
                sleep 5;
            done

            hdfs namenode -bootstrapStandby;
        fi
        touch ~/.makCluster;
    fi
        hdfs --daemon start namenode;
        start-hbase.sh
        hbase-daemon.sh start thrift
else
    if
        [ ! -f ~/.makCluster ];
    then
    hostname >> /usr/local/hadoop/etc/hadoop/workers;
    touch ~/.makCluster;
    fi
    start-all.sh;
    hbase-daemon.sh start regionserver
fi

sleep infinity

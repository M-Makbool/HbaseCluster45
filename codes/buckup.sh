#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <HBase-table-name>"
    exit 1
fi

tablename="$1"

hbase org.apache.hadoop.hbase.mapreduce.Export "$tablename" /backup/"$tablename"

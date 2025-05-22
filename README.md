
# Scalable HBase Cluster with HA & WebTable Use Case  
**Highly Available HBase Cluster Integrated with Hadoop HA**  

---

## Table of Contents  
1. [Cluster Architecture](#cluster-architecture)  
2. [Prerequisites](#prerequisites)  
3. [Deployment Steps](#deployment-steps)  
4. [Failover Process](#failover-process)  
5. [Scaling Workers](#scaling-workers)  
6. [WebTable Use Case](#webtable-use-case)  
7. [Bonus Features](#bonus-features)  

---

## Cluster Architecture  
### Components:  
- **HBase Masters (3 Nodes):** Active/Standby configuration managed by ZooKeeper.  
- **RegionServers (scalable as you need):** Serve HBase regions.  
- **ZooKeeper Quorum (3 Nodes):** Coordinates leader election and cluster state.  
- **Hadoop HA Cluster:** Shared HDFS storage (3 NameNodes + DataNodes).  

### Key Features:  
- Automatic failover for HBase Masters and RegionServers.  
- Dockerized deployment with resource constraints.  
- Integrated security and health checks.  

---

## Prerequisites  
- Docker & Docker Compose installed.  
- 16GB+ RAM (Adjust `docker-compose.yml` resource limits if needed).  
- Clone this repository with all configuration files.  

---

## Deployment Steps  

### 1. Start the Cluster  
```bash
docker bake
docker compose up
```

### 2. Verify Components  
- **HBase Masters:** Access UIs at `http://localhost:16011` (Master1), `16012` (Master2), `16013` (Master3).  
- **HDFS UI:** `http://localhost:9871`.  
- **RegionServers:** Check logs with `docker logs HbaseCluster45-hadoop-worker1`.  

### 3. Initialize HA (Automated)  
- ZooKeeper ensemble starts automatically.  
- HDFS NameNodes format and bootstrap in HA mode.  
- HBase services (Master, RegionServer) start after Hadoop is healthy.  

---

## Failover Process  

### 1. HBase Master Failover  
- **Trigger:** Kill the active Master container:  
   kill the hmaster process

- **Recovery:**  
  - ZooKeeper elects the standby Master (`hadoop-master2`) within **10-30 seconds**.  
  - Verify new active Master via HBase UI (`http://localhost:16012`).  

### 2. RegionServer Failover  
- **Trigger:** Kill a RegionServer:  
  ```bash
  docker kill hadoop-worker
  ```
- **Recovery:**  
  - HBase automatically reassigns regions to other RegionServers.  

---

## Scaling Workers  

### Add More RegionServers  
1. Scale worker nodes:  
   ```bash
   docker-compose up -d --scale hadoop-worker=5
   ```
2. hostnames in `workers` file in `hadoopConf/` Update dinamicly.  

### Notes:  
- Resource limits in `docker-compose.yml` (4GB RAM per worker) must align with host capacity.  
- New workers auto-join the cluster via shared HDFS and ZooKeeper configurations.  

---

## WebTable Use Case  

### 1. Create the Table  
Run the HBase shell script:  
```bash
docker exec -it hadoop-master1 hbase shell tableCreation
```

### 2. Generate Sample Data  
Execute the Python script:  
```bash
docker exec -it hadoop-master1 python3 /home/hadoop/codes/dataGeneration.py
```

### 3. Run Queries  
Example: Find pages with HTTP 404 status:  
```bash
docker exec -it hadoop-master1 hbase shell
scan 'webtable', {FILTER => "SingleColumnValueFilter('metadata', 'status', =, 'binary:404')"}
```

---

## Bonus Features  

### 1. Backup & Recovery  
- **Export Data:**  
  ```bash
  docker exec -it hadoop-master1 ./codes/buckup.sh <tableName>
  ```
- **Restore Data:**  
  ```bash
  docker exec -it hadoop-master1 ./codes/import.sh <tableName>
  ```

**References:**  
- [HBase Official Documentation](https://hbase.apache.org/book.html)  
- [Docker Compose Scaling Guide](https://docs.docker.com/compose/reference/scale/)  


### **WebTable Use Case Design & Implementation Document**

---

#### **1. Table Design**

- **Structure:** `reversed_domain:original_path` (e.g., `com.example.www:/about` instead of `www.example.com/about`).  
- **Rationale:**  
  - Distributes writes/reads across regions by reversing domain (prevents hotspotting).  
  - Enables efficient domain-based scans (e.g., `com.example.www:*`).  

**Table Creation Script (HBase Shell)**  
```bash
create 'webtable', 
  {NAME => 'content', VERSIONS => 3, TTL => 7776000, COMPRESSION => 'GZIP'}, 
  {NAME => 'metadata', VERSIONS => 1}, 
  {NAME => 'outlinks', VERSIONS => 2, TTL => 15552000, COMPRESSION => 'SNAPPY'}, 
  {NAME => 'inlinks', VERSIONS => 2, TTL => 15552000, COMPRESSION => 'SNAPPY'}
```

---

#### **2. Data Generation**  
**Python Script (Using Faker)**  
```python
from faker import Faker
import happybase
import random

fake = Faker()
connection = happybase.Connection('hbase-master')
table = connection.table('webtable')

domains = ['example.com', 'test.org', 'demo.net', 'sample.co', 'web.app']

for _ in range(20):
    url = f"http://{fake.random_element(domains)}{fake.uri_path()}"
    reversed_domain = '.'.join(reversed(url.split('//')[1].split('/')[0].split('.')))
    row_key = f"{reversed_domain}:{url.split('//')[1].replace('/', ':')}"
    
    # Insert data
    table.put(row_key, {
        'content:html': fake.text(max_nb_chars=random.choice([500, 2000, 5000])),
        'metadata:status': str(random.choice([200, 404, 500])),
        'metadata:last_modified': fake.date_time_this_year().isoformat(),
        'outlinks:links': ','.join([fake.uri() for _ in range(3)]),
        'inlinks:links': ','.join([fake.uri() for _ in range(2)])
    })
```

---

#### **3. Query Implementation**  
**3.1 Basic Operations (HBase Shell)**  
- **Retrieve Latest Version by URL:**  
  ```bash
  get 'webtable', 'com.example.www:/about'
  ```
- **Update Content:**  
  ```bash
  put 'webtable', 'com.example.www:/about', 'content:html', '<new_html>'
  ```

**3.2 Filtering (Example: Pages with HTTP 404)**  
```bash
scan 'webtable', 
  {FILTER => "SingleColumnValueFilter('metadata', 'status', =, 'binary:404')"}
```

**3.3 Pagination (Scan in Batches of 5)**  
```bash
# First page
scan 'webtable', {LIMIT => 5, STARTROW => 'com.example.www'}
# Subsequent pages (use last row key from previous scan)
scan 'webtable', {LIMIT => 5, STARTROW => 'last_row_key'}
```

**3.4 Time-Based Operations**  
- **Retrieve All Versions of Content:**  
  ```bash
  get 'webtable', 'com.example.www:/about', {COLUMN => 'content:html', VERSIONS => 3}
  ```

---

- **Row Key Design:** Reversed domains for load balancing.  
- **TTL/Versioning:** Ensures automatic cleanup and auditability.  
- **Filters:** Used `SingleColumnValueFilter` for metadata queries.  
- **Pagination:** Leveraged `STARTROW` and `LIMIT` for efficient scans.  


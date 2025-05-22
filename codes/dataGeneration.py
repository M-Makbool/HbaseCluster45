from faker import Faker
import happybase
import random

"""
This script generates and inserts synthetic web page data into an HBase table named 'webtable' using the Faker library.
Functionality:
- Connects to an HBase instance via HappyBase.
- Randomly selects a domain from a predefined list and generates a fake URL path.
- Constructs a row key by reversing the domain and formatting the path to avoid slashes.
- For each row, inserts:
    - HTML content of variable length.
    - HTTP status code (200, 404, or 500).
    - Last modified timestamp within the current year.
    - Three randomly generated outlinks.
    - Two randomly generated inlinks.
Dependencies:
- Faker: For generating fake web data.
- happybase: For HBase connectivity.
- random: For random selection.
Intended for populating an HBase table with sample web crawl data for testing or development purposes.
"""

fake = Faker()
connection = happybase.Connection('localhost')
table = connection.table('webtable')

domains = ['example.com', 'test.org', 'demo.net', 'sample.co', 'web.app']

for _ in range(20):
    domain = random.choice(domains)
    path = fake.uri_path()
    url = f"http://{domain}{path}"
    reversed_domain = '.'.join(reversed(domain.split('.')))  # e.g., "com.example"
    row_key = f"{reversed_domain}:{path.replace('/', ':')}"  # Avoids '/' in row keys
    
    # Insert sample data
    table.put(row_key, {
        'content:html': fake.text(max_nb_chars=random.choice([500, 2000, 5000])),
        'metadata:status': str(random.choice([200, 404, 500])),
        'metadata:last_modified': fake.date_time_this_year().isoformat(),
        'outlinks:links': ','.join([fake.uri() for _ in range(3)]),
        'inlinks:links': ','.join([fake.uri() for _ in range(2)]),
    })
    
#!/bin/bash

exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "Starting Elasticsearch configuration..."

sudo systemctl start elasticsearch

echo "Waiting for Elasticsearch to start..."
for i in {1..30}; do
    if curl -s http://localhost:9200/_cluster/health | grep -q '"status":"\(green\|yellow\)"'; then
        echo "Elasticsearch is ready!"
        break
    fi
    echo "Waiting... ($i/30)"
    sleep 10
done

sudo systemctl status elasticsearch

# Create multiple indices with mappings

curl -X PUT "localhost:9200/logs" -H 'Content-Type: application/json' -d'
{
  "mappings": {
    "properties": {
      "@timestamp": { "type": "date" },
      "message": { "type": "text" },
      "level": { "type": "keyword" },
      "service": { "type": "keyword" }
    }
  }
}'

curl -X PUT "localhost:9200/metrics" -H 'Content-Type: application/json' -d'
{
  "mappings": {
    "properties": {
      "@timestamp": { "type": "date" },
      "cpu_usage": { "type": "float" },
      "memory_usage": { "type": "float" },
      "host": { "type": "keyword" }
    }
  }
}'

# Add some sample data to logs
curl -X POST "localhost:9200/logs/_doc" -H 'Content-Type: application/json' -d"
{
  \"@timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)\",
  \"message\": \"Elasticsearch cluster started successfully\",
  \"level\": \"INFO\",
  \"service\": \"elasticsearch\"
}"

echo "Elasticsearch configuration completed!"
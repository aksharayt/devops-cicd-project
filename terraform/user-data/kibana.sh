#!/bin/bash

# Log everything for debugging
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "Starting Kibana configuration..."

# Replace elasticsearch_ip variable in config
sudo sed -i "s/localhost/${elasticsearch_ip}/g" /etc/kibana/kibana.yml

# Start Kibana service
sudo systemctl start kibana

# Wait for Elasticsearch to be ready
echo "Waiting for Elasticsearch connection at ${elasticsearch_ip}:9200..."
until curl -s http://${elasticsearch_ip}:9200/_cluster/health > /dev/null; do
    echo "Elasticsearch not ready yet, waiting 10s..."
    sleep 10
done
echo "Elasticsearch is up!"

# Wait for Kibana to be ready
echo "Waiting for Kibana to start..."
for i in {1..60}; do
    if curl -s http://localhost:5601/api/status > /dev/null; then
        echo "Kibana is ready!"
        break
    fi
    echo "Waiting for Kibana... ($i/60)"
    sleep 10
done

# Check Kibana status
sudo systemctl status kibana

echo "Kibana configuration completed!"
echo "Access Kibana at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-hostname):5601"

echo "$(date): Kibana deployed and connected to Elasticsearch at ${elasticsearch_ip}" >> /var/log/deployment.log
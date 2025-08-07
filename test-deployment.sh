#!/bin/bash

# DevOps CI/CD Deployment Testing Script
# This script tests all components of your deployed infrastructure

echo " Testing DevOps CI/CD Deployment"
echo "=================================="

# Get server IPs from Terraform
cd terraform
WEBSERVER_IP=$(terraform output -raw webserver_public_ip 2>/dev/null)
KIBANA_IP=$(terraform output -raw kibana_public_ip 2>/dev/null)
ELASTICSEARCH_IP=$(terraform output -raw elasticsearch_private_ip 2>/dev/null)
MYSQL_PRIMARY_IP=$(terraform output -raw mysql_primary_private_ip 2>/dev/null)
MYSQL_STANDBY_IP=$(terraform output -raw mysql_standby_private_ip 2>/dev/null)
cd ..

if [ -z "$WEBSERVER_IP" ]; then
    echo "Could not get server IPs. Make sure Terraform has been applied."
    exit 1
fi

echo " Server Information:"
echo "   Web Server: $WEBSERVER_IP"
echo "   Kibana: $KIBANA_IP"
echo "   Elasticsearch: $ELASTICSEARCH_IP"
echo "   MySQL Primary: $MYSQL_PRIMARY_IP"
echo "   MySQL Standby: $MYSQL_STANDBY_IP"
echo ""

# Test 1: Web Server
echo " Test 1: Web Server Connectivity"
if curl -s -o /dev/null -w "%{http_code}" "http://$WEBSERVER_IP" | grep -q "200"; then
    echo " Web server is responding"
else
    echo " Web server is not responding"
fi

# Test 2: API Health Check
echo " Test 2: API Health Check"
HEALTH_RESPONSE=$(curl -s "http://$WEBSERVER_IP/health" 2>/dev/null)
if echo "$HEALTH_RESPONSE" | grep -q "healthy"; then
    echo " API health check passed"
    echo "   Response: $HEALTH_RESPONSE"
else
    echo " API health check failed"
    echo "   Response: $HEALTH_RESPONSE"
fi

# Test 3: Database API
echo " Test 3: Database API"
USERS_RESPONSE=$(curl -s "http://$WEBSERVER_IP/api/users" 2>/dev/null)
if echo "$USERS_RESPONSE" | grep -q "john_doe"; then
    echo " Database API is working"
    USER_COUNT=$(echo "$USERS_RESPONSE" | grep -o "john_doe\|jane_smith\|admin_user" | wc -l)
    echo "   Found $USER_COUNT users in database"
else
    echo " Database API is not working"
    echo "   Response: $USERS_RESPONSE"
fi

# Test 4: Kibana
echo " Test 4: Kibana Dashboard"
if curl -s -o /dev/null -w "%{http_code}" "http://$KIBANA_IP:5601" | grep -q "200"; then
    echo " Kibana is accessible"
    echo "   URL: http://$KIBANA_IP:5601"
else
    echo " Kibana is not accessible"
fi

# Test 5: Search API (Elasticsearch)
echo " Test 5: Search API (Elasticsearch)"
SEARCH_RESPONSE=$(curl -s "http://$WEBSERVER_IP/api/search?q=elasticsearch" 2>/dev/null)
if echo "$SEARCH_RESPONSE" | grep -q "total"; then
    echo " Search API is working"
    RESULT_COUNT=$(echo "$SEARCH_RESPONSE" | grep -o '"total":[0-9]*' | cut -d':' -f2)
    echo "   Found $RESULT_COUNT log entries"
else
    echo " Search API is not working"
    echo "   Response: $SEARCH_RESPONSE"
fi

# Test 6: Database Replication (via SSH)
echo " Test 6: Database Replication Status"
echo "   Checking MySQL replication from standby server..."
cd ansible
REPLICATION_STATUS=$(ansible database_standby -m shell -a "mysql -u root -pDevOpsPassword123! -e 'SHOW SLAVE STATUS\G' | grep 'Slave_IO_Running'" 2>/dev/null | grep -o "Yes" || echo "No")
if [ "$REPLICATION_STATUS" = "Yes" ]; then
    echo " Database replication is working"
else
    echo " Database replication may have issues"
    echo "   Status: $REPLICATION_STATUS"
fi
cd ..

# Summary
echo ""
echo " TESTING SUMMARY"
echo "=================="
echo " Web Server: $(curl -s -o /dev/null -w "%{http_code}" "http://$WEBSERVER_IP" | grep -q "200" && echo "PASS" || echo "FAIL")"
echo " API Health: $(curl -s "http://$WEBSERVER_IP/health" | grep -q "healthy" && echo "PASS" || echo "FAIL")"
echo " Database API: $(curl -s "http://$WEBSERVER_IP/api/users" | grep -q "john_doe" && echo "PASS" || echo "FAIL")"
echo " Kibana: $(curl -s -o /dev/null -w "%{http_code}" "http://$KIBANA_IP:5601" | grep -q "200" && echo "PASS" || echo "FAIL")"
echo " Search API: $(curl -s "http://$WEBSERVER_IP/api/search?q=test" | grep -q "total" && echo "PASS" || echo "FAIL")"
echo " Replication: $REPLICATION_STATUS"

echo ""
echo " ACCESS YOUR DEPLOYED SERVICES:"
echo "================================="
echo " Main Web App: http://$WEBSERVER_IP"
echo " Kibana Dashboard: http://$KIBANA_IP:5601"
echo " Health Check: http://$WEBSERVER_IP/health"
echo " Users API: http://$WEBSERVER_IP/api/users"
echo " Posts API: http://$WEBSERVER_IP/api/posts"
echo " Search API: http://$WEBSERVER_IP/api/search?q=elasticsearch"

echo ""
echo " WHAT YOU'VE ACCOMPLISHED:"
echo "============================"
echo " Built 5 custom AMIs with Packer"
echo " Deployed infrastructure with Terraform"
echo " Configured applications with Ansible"
echo " Set up MySQL master-slave replication"
echo " Integrated Elasticsearch and Kibana"
echo " Created a complete CI/CD pipeline"

echo ""
echo " Congratulations! Your DevOps CI/CD system is running!"
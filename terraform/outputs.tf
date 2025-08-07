output "webserver_public_ip" {
  description = "Public IP of the web server"
  value       = aws_instance.webserver.public_ip
}

output "webserver_public_dns" {
  description = "Public DNS of the web server"
  value       = aws_instance.webserver.public_dns
}

output "elasticsearch_private_ip" {
  description = "Private IP of Elasticsearch server"
  value       = aws_instance.elasticsearch.private_ip
}

output "kibana_public_ip" {
  description = "Public IP of Kibana server"
  value       = aws_instance.kibana.public_ip
}

output "kibana_public_dns" {
  description = "Public DNS of Kibana server"
  value       = aws_instance.kibana.public_dns
}

output "kibana_url" {
  description = "URL to access Kibana"
  value       = "http://${aws_instance.kibana.public_ip}:5601"
}

output "mysql_primary_private_ip" {
  description = "Private IP of MySQL primary server"
  value       = aws_instance.mysql_primary.private_ip
}

output "mysql_standby_private_ip" {
  description = "Private IP of MySQL standby server"
  value       = aws_instance.mysql_standby.private_ip
}

output "ansible_inventory" {
  description = "Ansible inventory information"
  value = {
    webserver = {
      public_ip  = aws_instance.webserver.public_ip
      private_ip = aws_instance.webserver.private_ip
    }
    elasticsearch = {
      public_ip  = aws_instance.elasticsearch.public_ip
      private_ip = aws_instance.elasticsearch.private_ip
    }
    kibana = {
      public_ip  = aws_instance.kibana.public_ip
      private_ip = aws_instance.kibana.private_ip
    }
    mysql_primary = {
      public_ip  = aws_instance.mysql_primary.public_ip
      private_ip = aws_instance.mysql_primary.private_ip
    }
    mysql_standby = {
      public_ip  = aws_instance.mysql_standby.public_ip
      private_ip = aws_instance.mysql_standby.private_ip
    }
  }
}

output "infrastructure_summary" {
  description = "Summary of deployed infrastructure"
  value = {
    webserver_url = "http://${aws_instance.webserver.public_dns}"
    kibana_url    = "http://${aws_instance.kibana.public_dns}:5601"
    elasticsearch_endpoint = "http://${aws_instance.elasticsearch.private_ip}:9200"
    mysql_primary_endpoint = "${aws_instance.mysql_primary.private_ip}:3306"
    mysql_standby_endpoint = "${aws_instance.mysql_standby.private_ip}:3306"
  }
}

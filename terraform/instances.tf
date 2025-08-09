# Web Server Instance
resource "aws_instance" "webserver" {
  ami           = data.aws_ami.webserver.id
  instance_type = var.webserver_instance_type
  subnet_id     = data.aws_subnets.default.ids[0]
  
  vpc_security_group_ids = [aws_security_group.webserver.id]
  
  user_data = base64encode(templatefile("${path.module}/user-data/webserver.sh", {
    elasticsearch_ip = aws_instance.elasticsearch.private_ip
    mysql_primary_ip = aws_instance.mysql_primary.private_ip
  }))

  tags = {
    Name        = "WebServer"
    Environment = var.environment
    Type        = "WebServer"
  }
}

# Elasticsearch Instance
resource "aws_instance" "elasticsearch" {
  ami           = data.aws_ami.elasticsearch.id
  instance_type = var.elasticsearch_instance_type
  subnet_id     = data.aws_subnets.default.ids[0]
  
  vpc_security_group_ids = [aws_security_group.elasticsearch.id]
  
  user_data = base64encode(file("${path.module}/user-data/elasticsearch.sh"))

  tags = {
    Name        = "Elasticsearch"
    Environment = var.environment
    Type        = "Elasticsearch"
  }
}

# Kibana Instance
resource "aws_instance" "kibana" {
  ami           = data.aws_ami.kibana.id
  instance_type = var.kibana_instance_type
  subnet_id     = data.aws_subnets.default.ids[0]
  
  vpc_security_group_ids = [aws_security_group.kibana.id]
  
  user_data = base64encode(templatefile("${path.module}/user-data/kibana.sh", {
    elasticsearch_ip = aws_instance.elasticsearch.private_ip
  }))

  tags = {
    Name        = "Kibana"
    Environment = var.environment
    Type        = "Kibana"
  }

  depends_on = [aws_instance.elasticsearch]
}

# MySQL Primary Instance
resource "aws_instance" "mysql_primary" {
  ami           = data.aws_ami.mysql_primary.id
  instance_type = var.mysql_instance_type
  subnet_id     = data.aws_subnets.default.ids[0]
  
  vpc_security_group_ids = [aws_security_group.mysql.id]
  
  user_data = base64encode(file("${path.module}/user-data/mysql-primary.sh"))

  tags = {
    Name        = "MySQL-Primary"
    Environment = var.environment
    Type        = "Database-Primary"
  }
}

# MySQL Standby Instance
resource "aws_instance" "mysql_standby" {
  ami           = data.aws_ami.mysql_standby.id
  instance_type = var.mysql_instance_type
  subnet_id     = data.aws_subnets.default.ids[0]
  
  vpc_security_group_ids = [aws_security_group.mysql.id]
  
  user_data = base64encode(templatefile("${path.module}/user-data/mysql-standby.sh", {
    mysql_primary_ip = aws_instance.mysql_primary.private_ip
  }))

  tags = {
    Name        = "MySQL-Standby"
    Environment = var.environment
    Type        = "Database-Standby"
  }

  depends_on = [aws_instance.mysql_primary]
}
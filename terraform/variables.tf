variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "development"
}

variable "webserver_instance_type" {
  description = "Instance type for web server"
  type        = string
  default     = "t2.micro"
}

variable "elasticsearch_instance_type" {
  description = "Instance type for Elasticsearch"
  type        = string
  default     = "t3.medium"
}

variable "kibana_instance_type" {
  description = "Instance type for Kibana"
  type        = string
  default     = "t3.medium"
}

variable "mysql_instance_type" {
  description = "Instance type for MySQL servers"
  type        = string
  default     = "t3.medium"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "devops-cicd"
}
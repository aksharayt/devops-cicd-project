source "amazon-ebs" "elasticsearch" {
  ami_name      = "custom-elasticsearch-{{timestamp}}"
  instance_type = "t3.medium"
  region        = "us-east-1"
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_username = "ubuntu"
  
  tags = {
    Name = "Elasticsearch-AMI"
    Environment = "Development"
  }
}

build {
  name = "elasticsearch-build"
  sources = [
    "source.amazon-ebs.elasticsearch"
  ]

  provisioner "shell" {
    script = "scripts/install-elasticsearch.sh"
  }

  provisioner "file" {
    source      = "files/elasticsearch.yml"
    destination = "/tmp/elasticsearch.yml"
  }

  provisioner "shell" {
    inline = [
      "sudo mv /tmp/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml",
      "sudo systemctl enable elasticsearch"
    ]
  }

}

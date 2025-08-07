source "amazon-ebs" "kibana" {
  ami_name      = "custom-kibana-{{timestamp}}"
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
    Name = "Kibana-AMI"
    Environment = "Development"
  }
}

build {
  name = "kibana-build"
  sources = [
    "source.amazon-ebs.kibana"
  ]

  provisioner "shell" {
    script = "scripts/install-kibana.sh"
  }

  provisioner "file" {
    source      = "files/kibana.yml"
    destination = "/tmp/kibana.yml"
  }

  provisioner "shell" {
    inline = [
      "sudo mv /tmp/kibana.yml /etc/kibana/kibana.yml",
      "sudo systemctl enable kibana"
    ]
  }

}

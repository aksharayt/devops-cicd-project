packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "mysql-standby" {
  ami_name      = "custom-mysql-standby-{{timestamp}}"
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
    Name = "MySQL-Standby-AMI"
    Environment = "Development"
  }
}

build {
  name = "mysql-standby-build"
  sources = [
    "source.amazon-ebs.mysql-standby"
  ]

  provisioner "shell" {
    script = "scripts/install-mysql-standby.sh"
  }

  provisioner "file" {
    source      = "files/mysql-standby.cnf"
    destination = "/tmp/mysql-standby.cnf"
  }

  provisioner "shell" {
    inline = [
      "sudo mv /tmp/mysql-standby.cnf /etc/mysql/mysql.conf.d/custom.cnf",
      "sudo systemctl enable mysql"
    ]
  }
}
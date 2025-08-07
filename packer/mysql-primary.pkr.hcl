source "amazon-ebs" "mysql-primary" {
  ami_name      = "custom-mysql-primary-{{timestamp}}"
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
    Name = "MySQL-Primary-AMI"
    Environment = "Development"
  }
}

build {
  name = "mysql-primary-build"
  sources = [
    "source.amazon-ebs.mysql-primary"
  ]

  provisioner "shell" {
    script = "scripts/install-mysql-primary.sh"
  }

  provisioner "file" {
    source      = "files/mysql-primary.cnf"
    destination = "/tmp/mysql-primary.cnf"
  }

  provisioner "shell" {
    inline = [
      "sudo mv /tmp/mysql-primary.cnf /etc/mysql/mysql.conf.d/custom.cnf",
      "sudo systemctl enable mysql"
    ]
  }

}

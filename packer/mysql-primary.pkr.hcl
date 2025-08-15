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
    Project = "MySQL-CICD"
    Type = "Database"
    Role = "Primary"
    Owner = "DevOps-Team"
  }
}

build {
  name = "mysql-primary-build"
  sources = [
    "source.amazon-ebs.mysql-primary"
  ]

  # Install MySQL and configure it
  provisioner "shell" {
    script = "scripts/install-mysql-primary.sh"
  }

  # Copy MySQL configuration file
  provisioner "file" {
    source      = "files/mysql-primary.cnf"
    destination = "/tmp/mysql-primary.cnf"
  }

  # Apply configuration and enable services
  provisioner "shell" {
    inline = [
      "sudo mv /tmp/mysql-primary.cnf /etc/mysql/mysql.conf.d/custom.cnf",
      "sudo chown mysql:mysql /etc/mysql/mysql.conf.d/custom.cnf",
      "sudo chmod 644 /etc/mysql/mysql.conf.d/custom.cnf",
      "sudo systemctl restart mysql",
      "sudo systemctl enable mysql",
      "echo 'MySQL configuration applied successfully'"
    ]
  }

  # Final verification
  provisioner "shell" {
    inline = [
      "sudo systemctl status mysql",
      "sudo mysql -u root -pDevOpsPassword123! -e 'SHOW DATABASES;'",
      "sudo mysql -u root -pDevOpsPassword123! -e 'SELECT User, Host FROM mysql.user;'",
      "echo 'MySQL setup verification complete'"
    ]
  }
}

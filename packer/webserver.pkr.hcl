packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "webserver" {
  ami_name      = "custom-webserver-{{timestamp}}"
  instance_type = "t2.micro"
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
    Name = "WebServer-AMI"
    Environment = "Development"
  }
}

build {
  name = "webserver-build"
  sources = [
    "source.amazon-ebs.webserver"
  ]

  provisioner "shell" {
    script = "scripts/install-webserver.sh"
  }

  provisioner "file" {
    source      = "files/nginx.conf"
    destination = "/tmp/nginx.conf"
  }

  provisioner "shell" {
    inline = [
      "sudo mv /tmp/nginx.conf /etc/nginx/nginx.conf",
      "sudo systemctl enable nginx",
      "sudo systemctl enable docker"
    ]
  }
}
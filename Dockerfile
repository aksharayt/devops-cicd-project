FROM jenkins/jenkins:lts

USER root

# Install system tools
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

# Install Terraform
RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
RUN apt-get update && apt-get install -y terraform

# Install Ansible
RUN apt-get update && apt-get install -y python3 python3-pip
RUN pip3 install ansible

# Install Packer
RUN wget https://releases.hashicorp.com/packer/1.9.4/packer_1.9.4_linux_amd64.zip
RUN unzip packer_1.9.4_linux_amd64.zip -d /usr/local/bin/
RUN chmod +x /usr/local/bin/packer

# Install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install

# Switch back to jenkins user
USER jenkins

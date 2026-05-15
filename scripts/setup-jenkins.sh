#!/bin/bash
# setup-jenkins.sh (Run this script on an Ubuntu 22.04 or 24.04 EC2 instance)
set -e

echo "🚀 Installing Jenkins, Docker, Trivy, and AWS CLI on Ubuntu..."

# 1. Update OS and install prerequisites (Java 21, unzip, git)
sudo apt-get update -y
sudo apt-get install -y fontconfig openjdk-21-jre curl unzip git software-properties-common

# 2. Add Jenkins Repo and install Jenkins
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y jenkins

# 3. Install latest Docker from official repository
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 4. Start and enable services
sudo systemctl enable --now jenkins docker

# 5. Give Jenkins & current user permissions to run docker commands
sudo usermod -aG docker jenkins
sudo usermod -aG docker ubuntu

# 6. Install Trivy for security scanning
echo "Installing Trivy..."
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin

# 7. Install AWS CLI v2
echo "Installing AWS CLI v2..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

echo "✅ Setup Complete!"
echo "--------------------------------------------------------"
echo "Jenkins Initial Admin Password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
echo "--------------------------------------------------------"
echo "Access Jenkins at: http://<your-ec2-public-ip>:8080"

#!/bin/bash
# setup-jenkins.sh (Designed for EC2 User Data / Automated Bootstrapping on Ubuntu 22.04 or 24.04)
set -e

# 1. Wait for standard background updates on boot
echo "Waiting 30 seconds for background updates to complete..."
sleep 30

# 2. Update OS and install prerequisites
sudo apt-get update -y
sudo apt-get install -y fontconfig openjdk-21-jre curl unzip git

# 3. Add Jenkins Repo and install Jenkins
sudo mkdir -p /etc/apt/keyrings
sudo wget -O /etc/apt/keyrings/jenkins.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key
echo "deb [signed-by=/etc/apt/keyrings/jenkins.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y jenkins

# 4. Install latest Docker from official repository
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

# 5. Start and enable services
sudo systemctl enable --now jenkins docker

# 6. Give Jenkins & default user permissions to run docker commands
sudo usermod -aG docker jenkins
if id "ubuntu" &>/dev/null; then
  sudo usermod -aG docker ubuntu
fi

# 7. Install Trivy for security scanning via APT repository
sudo apt-get install -y wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo gpg --dearmor -o /etc/apt/keyrings/trivy.gpg
echo "deb [signed-by=/etc/apt/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/trivy.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y trivy

# 8. Install AWS CLI v2
echo "Installing AWS CLI v2..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

# 9. Install Grafana
echo "Installing Grafana..."
sudo apt-get install -y apt-transport-https software-properties-common
sudo mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee /etc/apt/sources.list.d/grafana.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y grafana
sudo systemctl enable --now grafana-server

# 10. Print Setup Completion info
echo "==========================================================="
echo "🎉 Jenkins & DevOps Server Setup Complete!"
echo "==========================================================="
echo "Access URLs:"
echo "- Jenkins: http://<your-ec2-public-ip>:8080"
echo "- Grafana: http://<your-ec2-public-ip>:3000 (Default credentials: admin / admin)"
echo "-----------------------------------------------------------"
echo "To retrieve the Jenkins Initial Admin Password, SSH into the instance and run:"
echo "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
echo "==========================================================="
echo "✅ Automated Bootstrap Complete!"



#!/bin/bash

# Function to handle errors and display meaningful messages
handle_error() {
  echo "❌ Error: $1"
  exit 1
}

# 1. Update system packages
echo "Updating system packages..."
sudo apt update || handle_error "Failed to update system packages. Check your internet connection or repository sources."

# 2. Install Java OpenJDK 11
echo "Installing Java OpenJDK 11..."
sudo apt install openjdk-11-jdk -y || handle_error "Java installation failed. Ensure you have the correct permissions and package availability."

# 3. Check Java version
echo "Checking Java version..."
java -version || handle_error "Java is not installed correctly or not added to the PATH."

# 4. Download Apache Tomcat
echo "Downloading Apache Tomcat..."
cd /tmp || handle_error "Failed to navigate to the /tmp directory."
wget https://dlcdn.apache.org/tomcat/tomcat-10/v10.1.34/bin/apache-tomcat-10.1.34.tar.gz || handle_error "Failed to download Apache Tomcat. Verify the URL or your network connection."

# 5. Extract the downloaded file
echo "Extracting Apache Tomcat..."
sudo mkdir -p /opt/tomcat || handle_error "Failed to create /opt/tomcat directory."
sudo tar -xvf apache-tomcat-10.1.34.tar.gz -C /opt/tomcat --strip-components=1 || handle_error "Failed to extract Tomcat files."

# 6. Create a Tomcat user
echo "Creating Tomcat user..."
sudo useradd -r -m -U -d /opt/tomcat -s /bin/false tomcat || handle_error "Failed to create Tomcat user."

# 7. Assign permissions
echo "Assigning permissions to the Tomcat directory..."
sudo chown -R tomcat: /opt/tomcat || handle_error "Failed to change ownership of the Tomcat directory."
sudo chmod -R 755 /opt/tomcat || handle_error "Failed to set permissions for the Tomcat directory."

# 8. Create a systemd service file for Tomcat
echo "Creating systemd service file for Tomcat..."
cat <<EOL | sudo tee /etc/systemd/system/tomcat.service
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking
User=tomcat
Group=tomcat
Environment="JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64"
Environment="CATALINA_PID=/opt/tomcat/temp/tomcat.pid"
Environment="CATALINA_HOME=/opt/tomcat"
Environment="CATALINA_BASE=/opt/tomcat"
ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOL

# 9. Reload the systemd daemon
echo "Reloading systemd daemon..."
sudo systemctl daemon-reload || handle_error "Failed to reload systemd."

# 10. Start and enable Tomcat service
echo "Starting and enabling Tomcat service..."
sudo systemctl start tomcat || handle_error "Failed to start Tomcat service."
sudo systemctl enable tomcat || handle_error "Failed to enable Tomcat service."

# 11. Verify Tomcat is running
echo "Checking Tomcat status..."
sudo systemctl status tomcat || handle_error "Tomcat is not running. Check the logs for details."

# 12. Edit Tomcat user configuration
echo "Configuring Tomcat users for manager access..."
sudo sed -i 's/<!--\s*<user username="admin" password="." roles="manager-gui,admin-gui"\/>\s-->/<user username="admin" password="password" roles="manager-gui,admin-gui"\/>/' /opt/tomcat/conf/tomcat-users.xml || handle_error "Failed to edit tomcat-users.xml."

# 13. Restart Tomcat service
echo "Restarting Tomcat service..."
sudo systemctl restart tomcat || handle_error "Failed to restart Tomcat service."

# 14. Output success message
echo "✅ Apache Tomcat has been successfully installed and configured! Access it at http://<server-ip>:8080"

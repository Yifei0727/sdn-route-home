#!/bin/bash

# Set variables
NODE_EXPORTER_USER="node_exporter"
NODE_EXPORTER_GROUP="node_exporter"
NODE_EXPORTER_VERSION="$(curl -s  https://api.github.com/repos/prometheus/node_exporter/releases/latest|jq -r .tag_name)"
NODE_EXPORTER_FILE_VERSION="$(echo $NODE_EXPORTER_VERSION|cut -c2-)"

# Download node_exporter
echo "Downloading node_exporter..."
# The architecture (amd64) might need to be adjusted based on your system
wget "https://github.com/prometheus/node_exporter/releases/download/$NODE_EXPORTER_VERSION/node_exporter-$NODE_EXPORTER_FILE_VERSION.linux-amd64.tar.gz"

# Extract the archive
echo "Extracting node_exporter..."
tar -xvf "node_exporter-$NODE_EXPORTER_FILE_VERSION.linux-amd64.tar.gz"

# Move the binary to /usr/local/bin
echo "Moving binary to /usr/local/bin..."
sudo mv "node_exporter-$NODE_EXPORTER_FILE_VERSION.linux-amd64/node_exporter" /usr/local/bin/

# Create the user and group
echo "Creating user and group '$NODE_EXPORTER_USER'..."
sudo groupadd --system "$NODE_EXPORTER_GROUP"
sudo useradd -rs /bin/false --system -g "$NODE_EXPORTER_GROUP" "$NODE_EXPORTER_USER"

# Clean up
echo "Cleaning up..."
rm -rf "node_exporter-$NODE_EXPORTER_FILE_VERSION.linux-amd64"
rm "node_exporter-$NODE_EXPORTER_FILE_VERSION.linux-amd64.tar.gz"

# Create the systemd service file
echo "Creating systemd service file..."
sudo cat >/etc/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=$NODE_EXPORTER_USER
Group=$NODE_EXPORTER_GROUP
Type=simple
ExecStart=/usr/local/bin/node_exporter
ExecReload=/bin/kill -s HUP \$MAINPID
ExecStop=/bin/kill -s QUIT \$MAINPID
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Set permissions
echo "Setting permissions..."
sudo chown "$NODE_EXPORTER_USER":"$NODE_EXPORTER_GROUP" /usr/local/bin/node_exporter
sudo chmod 755 /usr/local/bin/node_exporter

# Enable and start the service
echo "Enabling and starting the service..."
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

echo "Node Exporter installed successfully!"

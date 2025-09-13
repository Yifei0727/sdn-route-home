#!/bin/bash

# Stop the service
echo "Stopping node_exporter service..."
sudo systemctl stop node_exporter

# Disable the service
echo "Disabling node_exporter service..."
sudo systemctl disable node_exporter

# Remove the service file
echo "Removing systemd service file..."
sudo rm /etc/systemd/system/node_exporter.service

# Remove the binary
echo "Removing node_exporter binary..."
sudo rm /usr/local/bin/node_exporter

# Remove the user and group
echo "Removing node_exporter user and group..."
sudo userdel node_exporter
sudo groupdel node_exporter

# Reload systemd daemon
echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

echo "Node Exporter uninstalled successfully!"

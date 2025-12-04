#!/bin/bash
set -e

# Create directories for Dockge
mkdir -p /opt/stacks
mkdir -p /workspaces/dockge-data

# Start Dockge
cd /opt/stacks
cat > docker-compose.yml << EOF
version: "3.8"
services:
  dockge:
    image: louislam/dockge:1
    restart: unless-stopped
    ports:
      - "5000:5001"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /workspaces/dockge-data:/app/data
      - /opt/stacks:/opt/stacks
    environment:
      - DOCKGE_STACKS_DIR=/opt/stacks
      - DOCKGE_ENABLE_CONSOLE=true
EOF

docker compose up -d

# Keep container running
tail -f /dev/null

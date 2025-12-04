FROM node:22-bookworm-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    gnupg \
    unzip \
    dumb-init \
    jq \
    pgrep \
    openssh-server \
    docker.io \
    docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

# Install Docker
RUN curl -fsSL https://get.docker.com -o get-docker.sh && \
    sh get-docker.sh && \
    rm get-docker.sh

# Install Node.js tools
RUN npm install -g tsx

# Create workspace directory
WORKDIR /workspaces

# Expose ports for Dockge
EXPOSE 5000

# Start script
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

CMD ["/usr/local/bin/start.sh"]

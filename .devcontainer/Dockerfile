FROM node:22-bookworm-slim

# Install system dependencies including Docker CLI and OpenSSH
RUN apt-get update && apt-get install --yes --no-install-recommends \
    curl \
    ca-certificates \
    gnupg \
    unzip \
    dumb-init \
    git \
    openssh-server \
    openssh-client \
    && install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && chmod a+r /etc/apt/keyrings/docker.gpg \
    && echo \
         "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
         "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
         tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install --yes --no-install-recommends \
         docker-ce-cli \
         docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

# Install global Node tools
RUN npm install -g tsx

# Set up working directory
WORKDIR /app

# Copy package files
COPY package.json package-lock.json ./

# Install dependencies
RUN npm ci

# Copy the rest of the application
COPY . .

# Create data directory
RUN mkdir -p ./data && chown node:node ./data

# Set up SSH for node user
RUN mkdir -p /home/node/.ssh && chmod 700 /home/node/.ssh

# Add authorized keys for SSH access if available
COPY .devcontainer/authorized_keys* /home/node/.ssh/
RUN if [ -f /home/node/.ssh/authorized_keys ]; then \
      chmod 600 /home/node/.ssh/authorized_keys && \
      chown -R node:node /home/node/.ssh; \
    fi

# Ensure node user can access /app
RUN chown -R node:node /app

# Configure SSH server
RUN mkdir -p /run/sshd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# Set environment variables
ENV UV_USE_IO_URING=0
ENV NODE_ENV=development

# Expose ports
EXPOSE 5001 22

# Start SSH server and keep container running
CMD ["/usr/sbin/sshd", "-D"]

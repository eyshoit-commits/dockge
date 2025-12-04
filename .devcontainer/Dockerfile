############################################
# Base Stage - Install Docker and dependencies
############################################
FROM node:22-bookworm-slim AS base

# Install system dependencies
RUN apt update && apt install --yes --no-install-recommends \
    curl \
    ca-certificates \
    gnupg \
    unzip \
    dumb-init \
    && install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && chmod a+r /etc/apt/keyrings/docker.gpg \
    && echo \
         "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
         "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
         tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt update \
    && apt --yes --no-install-recommends install \
         docker-ce-cli \
         docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g tsx

# Create node user
RUN useradd -m -s /bin/bash node

############################################
# Development Stage - Install local Dockge
############################################
FROM base AS development

# Set up working directory
WORKDIR /app

# Copy package files and install dependencies
COPY --chown=node:node ./package.json ./package.json
COPY --chown=node:node ./package-lock.json ./package-lock.json
RUN npm ci

# Copy application code
COPY --chown=node:node . .

# Create data directory
RUN mkdir -p ./data && chown node:node ./data

# Set environment variables
ENV UV_USE_IO_URING=0

# Switch to node user
USER node

# Expose port
EXPOSE 5001

# Set entrypoint to start Dockge
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["tsx", "./backend/index.ts"]

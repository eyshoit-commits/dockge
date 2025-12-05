############################################
# Base Stage - Install system dependencies
############################################
FROM node:22-bookworm-slim AS base

RUN apt-get update && apt-get install --yes --no-install-recommends \
    curl \
    ca-certificates \
    gnupg \
    unzip \
    dumb-init \
    git \
    openssh-server \
    openssh-client \
    golang \
    python3 \
    python3-pip \
    python3-venv \
    build-essential \
    gcc \
    g++ \
    make \
    cmake \
    pkg-config \
    libssl-dev \
    libffi-dev \
    libjpeg-dev \
    libpng-dev \
    libwebp-dev \
    zlib1g-dev \
    wget \
    vim \
    nano \
    htop \
    tree \
    jq \
    yq \
    sudo \
    net-tools \
    iputils-ping \
    telnet \
    ncurses-dev \
    libncurses5-dev \
    libreadline-dev \
    bison \
    flex \
    gdb \
    strace \
    ltrace \
    valgrind \
    zip \
    unzip \
    tar \
    gzip \
    p7zip \
    rsync \
    lsof \
    procps \
    psmisc \
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

RUN npm install -g --force tsx yarn pnpm typescript nodemon @types/node eslint prettier

RUN useradd -m -s /bin/bash node || true && \
    echo "node ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    mkdir -p /home/node/.local/bin && \
    mkdir -p /home/node/projects && \
    mkdir -p /home/node/.config && \
    chown -R node:node /home/node

############################################
# Healthcheck Binary
############################################
FROM base AS build_healthcheck
WORKDIR /app
COPY --chown=node:node ./extra/healthcheck.go ./extra/healthcheck.go
RUN go build -o ./extra/healthcheck ./extra/healthcheck.go

############################################
# Build Stage - Install dependencies
############################################
FROM base AS build
WORKDIR /app
COPY --chown=node:node ./package.json ./package.json
COPY --chown=node:node ./package-lock.json ./package-lock.json
RUN npm ci --include=dev

############################################
# Development Stage
############################################
FROM base AS development
WORKDIR /app
COPY --chown=node:node --from=build_healthcheck /app/extra/healthcheck /app/extra/healthcheck
COPY --from=build /app/node_modules /app/node_modules
COPY --chown=node:node ./package.json ./package.json
COPY --chown=node:node ./package-lock.json ./package-lock.json
COPY --chown=node:node . .
# Build frontend
RUN cd /app && npm build:frontend
# Set up directories for Dockge runtime
RUN mkdir -p /opt/stacks /opt/dockge && \
    cp -r /app/* /opt/dockge/ && \
    mkdir -p /opt/dockge/data

# Set up SSH for node user
RUN mkdir -p /home/node/.ssh && chmod 700 /home/node/.ssh

# Configure Python environment for node user
RUN python3 -m pip install --upgrade pip --break-system-packages && \
    python3 -m pip install uv virtualenv setuptools wheel pytest black flake8 mypy --break-system-packages && \
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> /home/node/.bashrc && \
    echo 'export PYTHONPATH="$HOME/.local/lib/python3.11/site-packages:$PYTHONPATH"' >> /home/node/.bashrc && \
    echo 'export EDITOR=vim' >> /home/node/.bashrc && \
    echo 'export PS1="\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "' >> /home/node/.bashrc && \
    echo "# Python environment configured" && \
    touch /tmp/python-env-configured

# Configure SSH server
RUN mkdir -p /run/sshd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# Create startup script for Dockge
RUN echo '#!/bin/bash' > /opt/dockge/start-dockge.sh && \
    echo 'cd /opt/dockge' >> /opt/dockge/start-dockge.sh && \
    echo 'mkdir -p /opt/stacks' >> /opt/dockge/start-dockge.sh && \
    echo 'mkdir -p /opt/dockge/data' >> /opt/dockge/start-dockge.sh && \
    echo 'npm start' >> /opt/dockge/start-dockge.sh && \
    chmod +x /opt/dockge/start-dockge.sh && \
    chown -R node:node /opt/dockge /opt/stacks

# It is just for safe, as by default, it is disabled in the latest Node.js now.
# Read more:
# - https://github.com/sagemathinc/cocalc/issues/6963
# - https://github.com/microsoft/node-pty/issues/630#issuecomment-1987212447
ENV UV_USE_IO_URING=0
ENV NODE_ENV=development
ENV PYTHONPATH=/app
ENV PATH=/home/node/.local/bin:$PATH
ENV PYTHON_VERSION=3.11
ENV GO_VERSION=1.21
ENV EDITOR=vim
ENV TERM=xterm-256color

VOLUME /app/data
VOLUME /home/node/.ssh
VOLUME /home/node/projects
VOLUME /opt/stacks
VOLUME /opt/dockge/data
EXPOSE 5001 22
HEALTHCHECK --interval=60s --timeout=30s --start-period=60s --retries=5 CMD extra/healthcheck
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/bin/bash", "-c", "/usr/sbin/sshd -D & /opt/dockge/start-dockge.sh"]

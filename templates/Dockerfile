FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# System packages
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    ca-certificates \
    tini \
    tmux \
    vim \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Create researcher user with host UID/GID
RUN groupadd -g __GID__ researcher && \
    useradd -m -u __UID__ -g __GID__ -s /bin/bash researcher

# Install uv and Claude CLI as researcher
USER researcher
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/home/researcher/.local/bin:${PATH}"
RUN curl -fsSL https://claude.ai/install.sh | bash

# Pre-create cache dirs
RUN mkdir -p /home/researcher/.cache/uv /home/researcher/.cache/huggingface

WORKDIR /workspace

STOPSIGNAL SIGTERM
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["sleep", "infinity"]

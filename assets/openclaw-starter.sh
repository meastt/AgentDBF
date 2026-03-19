#!/bin/bash
# =============================================================================
# OpenClaw Starter Kit — One-Command Setup Script
# Version: v2026.03.19
# Works on: Linux and macOS (Windows users: use WSL2)
# =============================================================================

set -e

VERSION="v2026.03.19"
CONTAINER_NAME="openclaw-sandbox"
IMAGE_NAME="nvidia/nemoclaw"

echo "=============================================="
echo "  OpenClaw Starter Kit — ${VERSION}"
echo "  One-command AI agent setup"
echo "=============================================="
echo ""

# -----------------------------------------------------------------------------
# Step 1: Check prerequisites
# -----------------------------------------------------------------------------

echo "[1/5] Checking prerequisites..."

# Node.js v22+
NODE_VERSION=$(node --version 2>/dev/null | sed 's/v//' | cut -d. -f1) || NODE_VERSION=0
if [ "$NODE_VERSION" -lt 22 ]; then
    echo ""
    echo "ERROR: Node.js v22+ is required."
    echo "  You have: $(node --version 2>/dev/null || echo 'not installed')"
    echo ""
    echo "Install it first:"
    echo "  macOS:  brew install node@22"
    echo "  Linux:  curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - && sudo apt-get install -y nodejs"
    echo "  Or via NVM:  nvm install 22"
    echo ""
    echo "Then run this script again."
    exit 1
fi
echo "  ✓ Node.js $(node --version)"

# Docker
if ! command -v docker &> /dev/null; then
    echo ""
    echo "ERROR: Docker is not installed."
    echo ""
    echo "Install Docker:"
    echo "  macOS:     https://docs.docker.com/desktop/install/mac-install/"
    echo "  Linux:     curl -fsSL https://get.docker.com | sh"
    echo "  Windows:   Enable WSL2, then install Docker Desktop"
    echo ""
    echo "Then run this script again."
    exit 1
fi
DOCKER_VERSION=$(docker --version)
echo "  ✓ Docker installed ($DOCKER_VERSION)"

# Docker Compose
if docker compose version &> /dev/null; then
    COMPOSE_VERSION=$(docker compose version 2>/dev/null)
    echo "  ✓ Docker Compose installed ($COMPOSE_VERSION)"
else
    echo ""
    echo "ERROR: Docker Compose is not installed."
    echo ""
    echo "Install Docker Compose:"
    echo "  Linux/macOS:  sudo apt-get install docker-compose-v"
    echo "  Or:           pip install docker-compose"
    echo ""
    echo "Then run this script again."
    exit 1
fi

# 5GB free disk space
AVAILABLE_KB=$(df -k "$HOME" 2>/dev/null | awk 'NR==2 {print $4}')
AVAILABLE_GB=$(echo "scale=1; $AVAILABLE_KB / 1024 / 1024" | bc 2>/dev/null || echo "unknown")
if [ "$AVAILABLE_KB" -lt 5242880 ]; then
    echo ""
    echo "WARNING: Less than 5GB free disk space detected."
    echo "  You have ~${AVAILABLE_GB}GB free."
    echo "  The container needs ~2GB. Proceeding anyway..."
else
    echo "  ✓ ${AVAILABLE_GB}GB free disk space"
fi

echo ""
echo "[2/5] All prerequisites met."
echo ""

# -----------------------------------------------------------------------------
# Step 2: Pull the NemoClaw Docker image
# -----------------------------------------------------------------------------

echo "[3/5] Pulling NemoClaw image (${IMAGE_NAME}:${VERSION})..."
echo "  This may take a few minutes on first run."

if docker pull "${IMAGE_NAME}:${VERSION}" 2>&1; then
    echo "  ✓ Image pulled successfully"
else
    echo ""
    echo "ERROR: Failed to pull the NemoClaw image."
    echo "  Check your internet connection and Docker daemon."
    echo "  You can also try: docker login"
    exit 1
fi

# -----------------------------------------------------------------------------
# Step 3: Create a working directory for the sandbox
# -----------------------------------------------------------------------------

SANDBOX_DIR="$HOME/openclaw-sandbox"
WORKSPACE_DIR="$SANDBOX_DIR/workspace"

if [ -d "$WORKSPACE_DIR" ]; then
    echo ""
    read -p "A workspace already exists at $WORKSPACE_DIR. Reuse it? [Y/n]: " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! -z "$REPLY" ]]; then
        echo "Aborted. Remove the directory manually if you want a fresh start."
        exit 1
    fi
else
    mkdir -p "$WORKSPACE_DIR"
    echo "[4/5] Created sandbox directory: $WORKSPACE_DIR"
fi

# -----------------------------------------------------------------------------
# Step 4: Spin up the container
# -----------------------------------------------------------------------------

echo ""
echo "[5/5] Starting OpenClaw sandbox container..."

# Stop existing container with same name if running
docker stop "$CONTAINER_NAME" &> /dev/null || true
docker rm "$CONTAINER_NAME" &> /dev/null || true

# Create .env file if it doesn't exist
ENV_FILE="$SANDBOX_DIR/.env"
if [ ! -f "$ENV_FILE" ]; then
    cat > "$ENV_FILE" << 'ENVVARS'
# OpenClaw Environment Variables
# Add your API keys here. Never commit this file to git.

# Choose one:
# OPENAI_API_KEY=sk-your-key-here
# ANTHROPIC_API_KEY=sk-ant-your-key-here
ENVVARS
    echo "  ✓ Created $ENV_FILE — add your API key there."
fi

# Launch the container
docker run -d \
    --name "$CONTAINER_NAME" \
    --restart unless-stopped \
    -p 18789:18789 \
    -p 2222:2222 \
    -v "$WORKSPACE_DIR:/workspace" \
    -v "$ENV_FILE:/workspace/.env:ro" \
    --cap-drop ALL \
    --security-opt no-new-privileges \
    "${IMAGE_NAME}:${VERSION}" \
    nemo run --sandbox

echo "  ✓ Container started: $CONTAINER_NAME"
echo ""

# -----------------------------------------------------------------------------
# Step 5: Wait for the gateway to be ready
# -----------------------------------------------------------------------------

echo "Waiting for OpenClaw gateway to start..."
MAX_WAIT=30
COUNTER=0
until curl -s http://localhost:18789/health &> /dev/null || [ $COUNTER -eq $MAX_WAIT ]; do
    sleep 1
    COUNTER=$((COUNTER+1))
    printf "."
done
echo ""

if [ $COUNTER -lt $MAX_WAIT ]; then
    echo "  ✓ Gateway is ready!"
else
    echo "  Note: Gateway may still be starting. Try 'openclaw gateway status' in a moment."
fi

# -----------------------------------------------------------------------------
# Done
# -----------------------------------------------------------------------------

echo ""
echo "=============================================="
echo "  OpenClaw is ready!"
echo "=============================================="
echo ""
echo "Next steps:"
echo ""
echo "  1. Add your API key to:"
echo "     $ENV_FILE"
echo ""
echo "  2. Open a terminal in the sandbox:"
echo "     docker exec -it $CONTAINER_NAME bash"
echo ""
echo "  3. Run your first agent:"
echo "     openclaw run --name my-first-agent"
echo ""
echo "  4. Or use OpenShell directly:"
echo "     docker exec -it $CONTAINER_NAME openshell"
echo ""
echo "Useful commands:"
echo "  docker stop $CONTAINER_NAME   — stop the sandbox"
echo "  docker start $CONTAINER_NAME   — restart it"
echo "  openclaw logs --last           — view recent agent logs"
echo "  openclaw permissions list      — check agent permissions"
echo ""
echo "For the full quick-start checklist and safety guide,"
echo "see the files in this kit."
echo ""
echo "Need help? https://discord.gg/openclaw"
echo ""

#!/bin/bash
# Setup script for local development
# Creates dokploy-network if it doesn't exist

set -e

NETWORK_NAME="dokploy-network"

# Check if network exists
if docker network inspect $NETWORK_NAME >/dev/null 2>&1; then
    echo "✓ Network '$NETWORK_NAME' already exists"
else
    echo "Creating network '$NETWORK_NAME'..."
    docker network create $NETWORK_NAME
    echo "✓ Network '$NETWORK_NAME' created"
fi

echo ""
echo "Ready! You can now run:"
echo "  docker-compose up --build"

#!/bin/bash

# Dynamically set base directory
BASE_DIR="$HOME"
PROJECT_DIR="$BASE_DIR/VCC-Assignment-3"
REPO_URL="https://github.com/akansha-gautam-m23csa506/VCC-Assignment-3.git"

echo "🛑 Stopping all running containers..."
docker stop $(docker ps -q) 2>/dev/null

echo "🧹 Cleaning up Docker system..."
sudo docker system prune -af

echo "🗑 Removing existing project folder: $PROJECT_DIR"
sudo rm -rf "$PROJECT_DIR"

echo "📥 Cloning the latest repository..."
git clone "$REPO_URL" "$PROJECT_DIR"

# Change to project directory
cd "$PROJECT_DIR"

echo "🌐 Creating shared Docker network..."
docker network create shared_network || echo "Network already exists, skipping..."

# Deploy each service

echo "🚀 Deploying Backend (Flask)..."
cd "$PROJECT_DIR/url_shortener_backend"
docker-compose up -d --build

echo "🌍 Deploying Frontend (React)..."
cd "$PROJECT_DIR/url_shortener_frontend"
docker-compose up -d --build

echo "🛡 Deploying Nginx..."
cd "$PROJECT_DIR/nginx"
docker-compose up -d --build

echo "✅ Deployment complete!"
docker ps
#!/bin/bash

cd /home/production/production-docker-setup/binaries/opensearch || {
  echo "Directory does not exist: /home/production/production-docker-setup/binaries/opensearch"
  exit 1
}

echo "Pulling Docker image: cr.searchunify.com/binaries/opensearch:2.8.0"
docker pull cr.searchunify.com/binaries/opensearch:2.8.0 || {
  echo "Failed to pull Docker image."
  exit 1
}

echo "Stopping existing OpenSearch containers..."
docker-compose down || {
  echo "Failed to bring down Docker containers."
  exit 1
}

echo "Starting OpenSearch containers in compatibility mode..."
docker-compose --compatibility up -d || {
  echo "Failed to start Docker containers."
  exit 1
}

echo "OpenSearch image updated successfully!"

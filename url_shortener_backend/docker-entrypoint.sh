#!/bin/bash

echo "Mounting GCS bucket..."
mkdir -p /mnt/shared_db
gcsfuse --implicit-dirs $GCS_BUCKET /mnt/shared_db

echo "Starting Flask app..."
exec python main.py

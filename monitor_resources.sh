#!/bin/bash

# Get CPU usage
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
echo "CPU Usage: $CPU_USAGE%"

# Function to update nginx back to local
function point_to_local() {
    echo "Switching Nginx back to local containers..."
    echo "set \$frontend frontend:80;" > ./frontend.conf
    echo "set \$flask flask:5000;" > ./flask.conf
    docker exec nginx_proxy nginx -s reload
}

# Check if CPU usage exceeds 75%
if awk "BEGIN {exit !($CPU_USAGE > 75)}"; then
    echo "CPU usage high. Scaling up..."

    # Check if GCP VM already exists (avoid unnecessary creation)
    EXISTING_VM=$(gcloud compute instances list --filter="labels.assignment=3 AND labels.autoscaled=true AND status=RUNNING" --format="value(name)")

    if [[ -z "$EXISTING_VM" ]]; then
        # Launch GCP VM
        VM_NAME="scaled-vm-$(date +%s)"
        gcloud compute instances create $VM_NAME   
        --zone=asia-south1-a   
        --source-instance-template=projects/utopian-calling-452413-n2/regions/asia-south1/instanceTemplates/vcc-instance-template-assignment-3   
        --labels=assignment=3,autoscaled=true

        # Get external IP
        echo "Fetching external IP..."
        sleep 60
        VM_IP=$(gcloud compute instances describe $VM_NAME --zone=us-central1-a --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

        # Update Nginx config
        echo "set \$frontend $VM_IP:80;" > ./frontend.conf
        echo "set \$flask $VM_IP:5000;" > ./flask.conf
        docker exec nginx_proxy nginx -s reload
        echo "Traffic redirected to GCP VM."
    else
        echo "GCP VM already exists: $EXISTING_VM"
    fi

# Downscale condition
elif awk "BEGIN {exit !($CPU_USAGE < 40)}"; then
    echo "CPU usage low. Considering downscale..."

    # Check if GCP VMs exist
    VMS=$(gcloud compute instances list --filter="labels.assignment=3 AND labels.autoscaled=true AND status=RUNNING" --format="value(name)")

    if [[ ! -z "$VMS" ]]; then
        echo "Deleting GCP VMs: $VMS"
        for vm in $VMS; do
            gcloud compute instances delete $vm --zone=us-central1-a --quiet
        done
        # Switch traffic back to local
        point_to_local
        echo "Traffic switched back to local VM."
    else
        echo "No GCP VMs running. No downscale needed."
    fi
else
    echo "CPU usage normal. No scaling action."
fi



VM_NAME="scaled-vm-$(date +%s)"
gcloud compute instances create $VM_NAME --zone=asia-south1 --source-instance-template=vcc-instance-template-assignment-3 --labels=assignment=3,autoscaled=true
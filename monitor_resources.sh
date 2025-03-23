#!/bin/bash

# Get CPU usage
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
echo "CPU Usage: $CPU_USAGE%"

# Function to point Nginx back to local containers
# Function to point Nginx back to local containers
function point_to_local() {
    echo "Switching Nginx back to local containers..."

    # Replace nginx.conf map block to point to local
    sed -i '/map \$host \$frontend {/,/}/{s/default.*/default frontend:80;/}' nginx.conf
    sed -i '/map \$host \$flask {/,/}/{s/default.*/default flask:5000;/}' nginx.conf

    docker exec nginx_proxy nginx -s reload
}

# Check if CPU usage exceeds 75%
if awk "BEGIN {exit !($CPU_USAGE > 75)}"; then
    echo "CPU usage high. Scaling up..."

    # Check if a matching GCP VM already exists
    EXISTING_VM=$(gcloud compute instances list --filter="labels.assignment=3 AND labels.autoscaled=true AND name~^autoscale-vm- AND status=RUNNING" --format="value(name)")

    if [[ -z "$EXISTING_VM" ]]; then
        # Launch GCP VM
        VM_NAME="autoscale-vm-$(date +%s)"
        gcloud compute instances create $VM_NAME   
        --zone=asia-south1-a   
        --source-instance-template=projects/utopian-calling-452413-n2/regions/asia-south1/instanceTemplates/vcc-assignment-3-instance-template 
        --labels=assignment=3,autoscaled=true

        # Wait and get the external IP
        echo "Fetching external IP..."
        sleep 60
        VM_IP=$(gcloud compute instances describe $VM_NAME --zone=us-central1-a --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

        echo "New GCP VM IP: $VM_IP"

        # Update Nginx config
        # Replace nginx.conf to point to GCP VM:
        sed -i "/map \$host \$frontend {/,/}/{s/default.*/default $VM_IP:80;/}" nginx.conf
        sed -i "/map \$host \$flask {/,/}/{s/default.*/default $VM_IP:5000;/}" nginx.conf
        docker exec nginx_proxy nginx -s reload
        echo "Traffic redirected to GCP VM."
    else
        echo "Autoscaled VM already exists: $EXISTING_VM"
    fi

# Downscale condition
elif awk "BEGIN {exit !($CPU_USAGE < 40)}"; then
    echo "CPU usage low. Considering downscale..."

    # List autoscaled VMs matching name pattern & labels
    VMS=$(gcloud compute instances list \
        --filter="labels.assignment=3 AND labels.autoscaled=true AND name~^autoscale-vm- AND status=RUNNING" \
        --format="value(name)")

    if [[ ! -z "$VMS" ]]; then
        echo "Deleting autoscaled GCP VMs: $VMS"
        for vm in $VMS; do
            gcloud compute instances delete $vm --zone=us-central1-a --quiet
        done
        # Switch traffic back to local
        point_to_local
        echo "Traffic switched back to local VM."
    else
        echo "No matching autoscaled VMs running. No downscale needed."
    fi
else
    echo "CPU usage normal. No scaling action."
fi

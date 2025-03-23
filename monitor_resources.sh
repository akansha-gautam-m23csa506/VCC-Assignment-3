#!/bin/bash

CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
echo "CPU Usage: $CPU_USAGE%"

if awk "BEGIN {exit !($CPU_USAGE > 75)}"; then
    echo "CPU usage high. Scaling up..."

    EXISTING_VM=$(gcloud compute instances list --filter="labels.assignment=3 AND labels.autoscaled=true AND name~^autoscale-vm- AND status=RUNNING" --format="value(name)")

    if [[ -z "$EXISTING_VM" ]]; then
        VM_NAME="autoscale-vm-$(date +%s)"
        gcloud compute instances create $VM_NAME \
        --zone=asia-south1-a \
        --source-instance-template=projects/utopian-calling-452413-n2/regions/asia-south1/instanceTemplates/vcc-assignment-3-instance-template \
        --labels=assignment=3,autoscaled=true

        echo "Fetching external IP..."
        sleep 60
        VM_IP=$(gcloud compute instances describe $VM_NAME --zone=us-central1-a --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

        echo "New GCP VM IP: $VM_IP"

        echo "Traffic redirected to GCP VM."
    else
        echo "Autoscaled VM already exists: $EXISTING_VM"
    fi

elif awk "BEGIN {exit !($CPU_USAGE < 40)}"; then
    echo "CPU usage low. Considering downscale..."

    VMS=$(gcloud compute instances list \
        --filter="labels.assignment=3 AND labels.autoscaled=true AND name~^autoscale-vm- AND status=RUNNING" \
        --format="value(name)")

    if [[ ! -z "$VMS" ]]; then
        echo "Deleting autoscaled GCP VMs: $VMS"
        for vm in $VMS; do
            gcloud compute instances delete $vm --zone=us-central1-a --quiet
        done
        echo "Traffic switched back to local VM."
    else
        echo "No matching autoscaled VMs running. No downscale needed."
    fi
else
    echo "CPU usage normal. No scaling action."
fi

#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-007348acaafd7df1b" #insert sg id
ZONE_ID="Z07634881IMZZFH5TBV0T" #insert zone id 
DOMAIN_NAME="devopspractice.shop"

for instance in $@
do
    INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type t3.micro --security-group-ids $SG_ID --tag-specifications "ResourceType=instance,tags=[{Key=Name,Value=$instance}]" --query 'Instance[0].InstanceId' --output text)

    #get private ip
    if [ $instance != "frontend" ]; then
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Instance[0].PrivateIpAddress' --output text)
        RECORD_NAME="$instance.$DOMAIN_NAME"
    else
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Instance[0].PublicIpAddress' --output text)
        RECORD_NAME="$DOMAIN_NAME"
    fi

    echo "$instance: $IP"



aws route53 change-resource-record-sets --hosted-zone-id $ZONE_ID --change-batch '{
    "Comment": "Updating record set",
    "Changes":[{
        "Action" : "UPSERT",
        "ResourceRecordSet" : {
            "Name" : "'$RECORD_NAME'",
            "Type" : "A",
            "TTL" : 1,
                "ResourceRecords" : [{
                "Value" : "'$IP'"
                 }]
            }
        }]
    }'

done

#create new repo in git shell=roboshop
#existing folder to repo --> git init
#to rename master git branch -M main
#git remote add origin git url
#!/bin/bash

set -euo pipefail
USERID=$(id -u)
R="e\[31m"
G="e\[32m"
Y="e\[33m"
N="e\[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
SCRIPT_DIR=$PWD
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
MONGODB_HOST=mongodb.devopspractice.shop
START_TIME=$(date +%s)

mkdir -p $LOGS_FOLDER
echo "Script started executed at:$(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then
    echo "ERROR:: Please run this script with root user"
    exit 1 #failure is other than 0
fi

dnf module disable nodejs -y &>>$LOG_FILE

dnf module enable nodejs:20 -y &>>$LOG_FILE

dnf install nodejs -y &>>$LOG_FILE

id roboshop
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
else
    echo -e "User already exist... $Y SKIPPING $N"
fi

mkdir -p /app 

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE

cd /app 

rm -rf /app/*

unzip /tmp/catalogue.zip &>>$LOG_FILE

npm install &>>$LOG_FILE

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service &>>$LOG_FILE

systemctl daemon-reload 
systemctl enable catalogue &>>$LOG_FILE

systemctl start catalogue &>>$LOG_FILE

cp mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOG_FILE

dnf install mongodb-mongosh -y &>>$LOG_FILE

INDEX=$(mongosh mongodb.devopspractice.shop --qyiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")
if [ $INDEX -le 0 ]; then
    mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
else
    echo -e "Products already loaded... $Y SKIPPING $N"

systemctl restart catalogue

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"
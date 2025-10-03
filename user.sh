#!/bin/bash

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

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$2... $R failure $N" | tee -a $LOG_FILE
        exit 1 
    else
        echo -e "$2...$G success $N" | tee -a $LOG_FILE
    fi
}

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling NodeJS"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling NodeJS:20"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installing NodeJS"

id roboshop
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating System User"
else
    echo -e "User already exist... $Y SKIPPING $N"
fi

mkdir -p /app 
VALIDATE $? "Creating Directory" 

curl -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading code"

cd /app 
VALIDATE $? "Changing to app directory"

rm -rf /app/*
VALIDATE $? "Removing Existing Code"

unzip /tmp/user.zip &>>$LOG_FILE
VALIDATE $? "Unzipping Code"

npm install &>>$LOG_FILE
VALIDATE $? "Installing Dependencies"

cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service &>>$LOG_FILE
VALIDATE $? "Copying user service"

systemctl daemon-reload 
systemctl enable user &>>$LOG_FILE
VALIDATE $? "Enable user"

systemctl start user &>>$LOG_FILE
VALIDATE $? "Start user"

systemctl restart user
VALIDATE $? "Restarting user service"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"
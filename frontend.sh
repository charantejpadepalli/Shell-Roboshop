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

dnf module disable nginx -y &>>$LOG_FILE
VALIDATE $? "Disabling Nginx"

dnf module enable nginx:1.24 -y &>>$LOG_FILE
VALIDATE $? "Enabling Nginx:1.24"

dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "Installing Nginx"

systemctl enable nginx &>>$LOG_FILE
VALIDATE $? "Enabling Nginx"

systemctl start nginx &>>$LOG_FILE
VALIDATE $? "Starting Nginx" 

rm -rf /usr/share/nginx/html/* &>>$LOG_FILE
VALIDATE $? "Removing default HTML file"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading code"

rm -rf /etc/nginx/nginx.conf &>>$LOG_FILE
VALIDATE $? "Removing default conf"

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf &>>$LOG_FILE
VALIDATE $? "Copying frontend"

cd /usr/share/nginx/html 
VALIDATE $? "Changing to html directory"

unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "Unzipping Code"

systemctl restart nginx &>>$LOG_FILE
VALIDATE $? "Restarting Nginx service"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"
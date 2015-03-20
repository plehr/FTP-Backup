#!/bin/sh
# Dies ist ein Backup-Script zu einem externen ftp-Server.
# der Lösch-Vorgang muss allerdings manuell vom Server aus passieren.!
#
#
# Bereiche, welche gesichert werden sollen:
#
# /home/*
# /root
# /var/www
# /etc
# /var/log
# /var/lib
# mysql-Datenbanken
# /usr/bin

#Log erstellen
DATE=`date +"%Y%m%d"`
LOG=`echo "Backup beginnt als $USER um $DATE"`

# Verzeichnisse sichern
cd /backup
DATE=`date +"%Y%m%d"`
mkdir backup_$DATE
cd /backup/backup_$DATE
tar -cvjf root.tar.bz2 /root >>$LOG
tar -cvjf home.tar.bz2 /home >>$LOG
tar -cvjf www.tar.bz2 /var/www >>$LOG
tar -cvjf etc.tar.bz2 /etc >>$LOG
tar -cvjf log.tar.bz2 /var/log >>$LOG
tar -cvjf lib.tar.bz2 /var/lib >>$LOG
tar -cvjf usr-bin.tar.bz2 /usr/bin >>$LOG

# Datenbanken
TARGET=/var/backup/mysql
IGNORE="phpmyadmin|mysql|information_schema|performance_schema|test"
CONF=/etc/mysql/debian.cnf
if [ ! -r $CONF ]; then echo "$0 - auf $CONF konnte nicht zugegriffen werden"; exit 1; fi

DBS="$(/usr/bin/mysql --defaults-extra-file=$CONF -Bse 'show databases' | /bin/grep -Ev $IGNORE)">>$LOG
NOW=$(date +"%Y-%m-%d")

for DB in $DBS; do
    /usr/bin/mysqldump --defaults-extra-file=$CONF --skip-extended-insert --skip-comments $DB >> DB.sql
done

# Alle Backups komprimieren
cd /backup
tar -cvjf backup_$DATE.tar.bz2 /backup/backup_$DATE >>$LOG
rm -r /backup/backup_$DATE
echo "Transfer startet -- $NOW" >>$LOG

# ÜBERTRAGUNG AUF EXTERNEN FTP-SERVER
ftp -n thisismyhiddenftp.domain.tld <<End-Of-Session


user thisismybackupuser "thisismyhiddenpasswd"
binary
put "backup_$DATE.tar.bz2"
bye
End-Of-Session
echo "Ihr Backup ist erfolgreich erstellt" $LOG | mail -s "Backup: erfolgreich" mail@domain.tld
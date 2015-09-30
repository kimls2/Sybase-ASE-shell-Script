#!/usr/bin/ksh

#
#  1. Backup SYSTEM infomation (system table & interfaces file & cfg file)
#

for table_name in sysdatabases sysdevices sysusages syslogins sysloginroles syscharsets
do
        bcp master..${table_name}  out  /DBbackup/SYSTEMDB/${table_name}_`date +%y%m%d`.bcp  -Usa -Pwhdk01 -c
done
cp $SYBASE/ASE-12_5/SIARS1.cfg /DBbackup/SYSTEMDB/SIARS1_`date +%y%m%d`.cfg
cp $SYBASE/interfaces          /DBbackup/SYSTEMDB/interfaces_`date +%y%m%d`

#
#  2. SYSTEM DATABASE FULL BACKUP
#     database name = master,sybsystemprocs,model
#

while  true
do
running=`ps -fu sybase |grep backupserver |grep -v grep|awk '{print $1}'`
# if not running , startserver -f RUN_SIARS1_back
if  [[ "${running}" = "" ]]
then
   $SYBASE/ASE-12_5/install/startserver -f $SYBASE/ASE-12_5/install/RUN_SIARS1_back
   sleep 3
else
   break
fi
done

isql -Usa -Pwhdk01 <<EOF
use master
go
exec sp_full_backup  master
go
exec sp_full_backup  model
go
exec sp_full_backup  sybsystemprocs
go
EOF


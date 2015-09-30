#!/bin/sh
#
#  [ Usage : sys_backup sa_password ]
#
mkdir `date +%y%m%d`
cd `date +%y%m%d`

echo "\n ********* (1) Dump master database ****** \n\n"
isql -Usa -P$1 <<EOF
dump database master to '$SYBASE/NO_DEL/`date +%y%m%d`/mast_dump_`date +%y%m%d`'
go
EOF

echo "\n ********* (2) BCP OUT system tables   ****** \n\n"
for table_name in sysdatabases sysdevices sysusages syslogins sysloginroles syscharsets
do
        echo "\n\n -------> BCP OUT (master..${table_name}) <-----\n"
        bcp master..${table_name}  out  ${table_name}.bcp  -Usa -P$1 -c
done

echo "\n\n ********** (3)  .cfg file copy  *************\n"
cp $SYBASE/*.cfg $SYBASE/NO_DEL/`date +%y%m%d`

echo "\n\n ********** (4)  interfaces file copy  *************\n"
cp $SYBASE/interfaces $SYBASE/NO_DEL/`date +%y%m%d`/interfaces_`date +%y%m%d`

#!/bin/ksh
#
#  [ Usage : update_stat_gen_sampling.sh sa_password ]
#
if  [ $# -lt 2 ]
then
	echo ''
	echo "Usage : update_stat_gen_sampling.sh 'x' sa_password [DB_name] "
	echo "                                    'N' : No sampling "
	echo "                                    'S' : sampling "
	echo ''
	exit
fi

if  [ $1 != "N" ] && [ $1 != "S" ]
then
	echo ''
	echo "Usage : update_stat_gen_sampling.sh 'x' sa_password [DB_name] "
	echo "                                    'N' : No sampling "
	echo "                                    'S' : sampling "
	echo ''
	exit
fi
S_FLAG=$1

if  [ $# -eq 3 ]
then
	P_DB=$3
fi

# define variables
WORK_DIR="/sybase/mig/update_stat/gen"
STAT_DIR="/sybase/mig/update_stat/"
RCNT1=1000000
RCNT2=10000000
RCNT3=50000000
WORK_SERVER=NCS
USER=sa
PASSWD=$2

if [ -z $P_DB ]
then
	check_flag="T"
else
	check_flag="F"
fi
#
# User define Function (UDF)
#
# Get DB name from ASE
get_DBname(){
isql -U$USER -P$PASSWD -S$WORK_SERVER -b <<_EOF > tmp_DB
set nocount on
go
select name,dbid from master..sysdatabases
where dbid > 3 and dbid < 31000
and status & 256 != 256 and status3 & 256 != 256
order by dbid
go
_EOF
}

# Get Table name from DB
get_Tablesize(){
isql -U$USER -P$PASSWD -S$WORK_SERVER -w3000 -b <<_EOF > tmp_1
set nocount on
go
use $DB_name
go
select ltrim(rtrim(u.name))+'.'+ltrim(rtrim(o.name)) as tablename, convert(int,b.rowcnt) as rcount
into #t1
from $DB_name..sysobjects o, $DB_name..sysusers u, systabstats b
where o.type='U' and b.leafcnt =0 and o.uid = u.uid and o.id=b.id
order by o.name
go
exec sp_autoformat #t1
go
_EOF
sed '/return status = 0/d' tmp_1 > tmp_Tablesize
rm tmp_1
}

# Get a word from line
processLine(){
  line="$@" # get all args
  #  just echo them, but you may need to customize it according to your need
  # for example, F1 will store first field of $line, see readline2 script
  # for more examples
  F1=`echo $line | awk '{ print $1 }'`
  F2=`echo $line | awk '{ print $2 }'`
  #echo $F1
}

#Update statistics directory check
if [ ! -d $STAT_DIR ]
then
	mkdir $STAT_DIR
fi

get_DBname

cat tmp_DB  | \
while read line
do
        processLine "$line"
	DB_name=$F1


	# only a DB gen if have dbname parameter 
	if [[ $check_flag == "F" && $DB_name != $P_DB ]]
	then
		continue
	fi

	echo "--- update stat gen for $F1  ----"

	#update statistics file check
	if [  -f $STAT_DIR/update_stat_$DB_name.sh ]
	then
		rm $STAT_DIR/update_stat_$DB_name.sh
	fi

	#header gen for each DB
	echo "isql -U$USER -P$PASSWD -S$WORK_SERVER -b <<_EOF > update_stat_$DB_name.log " >> $STAT_DIR/update_stat_$DB_name.sh
	echo "set nocount on" >> $STAT_DIR/update_stat_$DB_name.sh
	echo "go" >> $STAT_DIR/update_stat_$DB_name.sh
	echo "use $DB_name" >> $STAT_DIR/update_stat_$DB_name.sh
	echo "go" >> $STAT_DIR/update_stat_$DB_name.sh

	get_Tablesize "$DB_name"
	cat tmp_Tablesize | \
	while read line1
	do
		processLine "$line1"	
		TABLE_name=$F1
		ROW_CNT=$F2

		#Table name print
		echo "print '' " >> $STAT_DIR/update_stat_$DB_name.sh
		echo "print '-- Table: $TABLE_name  Row_count: $ROW_CNT --' " >> $STAT_DIR/update_stat_$DB_name.sh
		echo "go" >> $STAT_DIR/update_stat_$DB_name.sh


		# start time log
		echo "select 'Start Time : '+ convert(varchar(30), getdate(),121)" >> $STAT_DIR/update_stat_$DB_name.sh
		echo "go" >> $STAT_DIR/update_stat_$DB_name.sh

		# update statistics gen  script
		if  [ $S_FLAG = "N" ]
		then
			echo "update index statistics $TABLE_name with hashing" >> $STAT_DIR/update_stat_$DB_name.sh
		elif [ $ROW_CNT -lt $RCNT1 ]
		then
			echo "update index statistics $TABLE_name with hashing" >> $STAT_DIR/update_stat_$DB_name.sh
		elif [ $ROW_CNT -ge $RCNT1 ] && [ $ROW_CNT -lt $RCNT2 ]
		then
			echo "update index statistics $TABLE_name with sampling = 10 percent" >> $STAT_DIR/update_stat_$DB_name.sh
		elif [ $ROW_CNT -ge $RCNT2 ] && [ $ROW_CNT -lt $RCNT3 ]
		then
			echo "update index statistics $TABLE_name with sampling = 5 percent" >> $STAT_DIR/update_stat_$DB_name.sh
		elif [ $ROW_CNT -ge $RCNT3 ]
		then
			echo "update index statistics $TABLE_name using 200 values with sampling = 2 percent" >> $STAT_DIR/update_stat_$DB_name.sh
		fi

		echo "go" >> $STAT_DIR/update_stat_$DB_name.sh

		# end time log
		echo "select 'End Time : '+ convert(varchar(30), getdate(),121)" >> $STAT_DIR/update_stat_$DB_name.sh
		echo "go" >> $STAT_DIR/update_stat_$DB_name.sh

	done
	echo "_EOF" >> $STAT_DIR/update_stat_$DB_name.sh
done

rm tmp_DB
rm tmp_Tablesize


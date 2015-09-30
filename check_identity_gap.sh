# Get DB name from ASE
get_DBname(){
isql -Usa -Psybase -SNCS -b <<_EOF > tmp_DB
set nocount on
go
select name from master..sysdatabases
where dbid > 3 and dbid < 23
and status & 256 != 256 and status3 & 256 != 256
order by dbid
go
_EOF
}

processLine(){
  line="$@" # get all args
  F1=`echo $line | awk '{ print $1 }'`
  F2=`echo $line | awk '{ print $2 }'`
}


get_DBname
cat tmp_DB  | \
while read line
do
        processLine "$line"
        DB_name=$F1

isql -Usa -Psybase -w3000 -SNCS -b <<_EOF > $F1.log
set nocount on
go
use $DB_name
go
select ltrim(rtrim(u.name))+'.'+ltrim(rtrim(o.name)) tablename , identitygap
into #$F1
from sysobjects o, syscolumns c, sysindexes i, sysusers u
where o.type = 'U' and o.id=c.id and c.status&128=128 and i.name=o.name and o.uid=u.uid
go
exec sp_autoformat #$F1
go
_EOF
sed '/return status = 0/d' $F1.log >> check_idgap.log
rm $F1.log
done

get_DBname
cat check_idgap.log  | \
while read line
do
        processLine "$line"
        tablename=$F1
	idgap=$F2

echo "exec sp_chgattribute '$tablename','identity_gap','$idgap'" >> check.sh
echo "go" >> check.sh
done
rm tmp_DB

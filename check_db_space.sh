isql -Usa -P$1 -w 200 <<EOF>check_db_space.sql
set nocount on
go
select 'exec sp_helpdb '+name + char(10)+'go'
from sysdatabases
go
select 'EOF'
go
EOF
isql -Usa -P$1 < check_db_space.sql > space_`date +%y%m%d`

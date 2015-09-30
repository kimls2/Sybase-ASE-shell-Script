/**
*** Usage : exec sp_log_backup  db_name
**/
use sybsystemprocs
go

if exists (select * from sysobjects
           where name = 'sp_log_backup' )
   drop proc sp_log_backup
go

create proc sp_log_backup  (@db_name varchar(30))
as

if (@db_name = 'master' or @db_name = 'model' or @db_name='sybsystemprocs')
begin
        print "[Message from sp_log_backup] "
        print "Executing sp_log_bacup is not allowed "
        print "for this system database  (%1!) ",@db_name
        return
end

if not exists ( select * from master.dbo.sysdatabases
                where name = ltrim(rtrim(@db_name)) )
begin
        print "[Message from sp_log_backup] "
        print "database %1! does not exists...",@db_name
        return
end

/*
**  Error 4208  ---> do nothing
**  DUMP TRANsaction to a dump device is not allowed
**  while the trunc. log on chkpt.  option is enabled.
**  Disable the option with sp_dboption,
**  then use DUMP DATABASE, before trying again.
*/
if exists (select *  from master..sysdatabases
           where name = ltrim(rtrim(@db_name)) and (status & 8 ) = 8)
begin
        print "[Message from sp_log_backup] "
        print "DUMP TRAN to a dump device is not allowed  "
        print "while the trunc. log on chkpt.  option is enabled.  "
        print "...Use DUMP DATABASE instead."
        return
end


declare @cur datetime
declare @yyyymmdd   char(8)
declare @cur_108    char(5)
declare @hhmm       char(4)
declare @dir        varchar(50)
declare @backupfile varchar(100)

select  @cur      = getdate()
select  @yyyymmdd = convert(char(8), @cur,112)
select  @cur_108  = convert(char(5), @cur,108)
select  @hhmm     = substring(@cur_108,1,2)+substring(@cur_108,4,2)

select  @dir      = '/DBbackup/' + ltrim(rtrim(@db_name)) + '/'

select  @backupfile = "compress::" + @dir +
                       + ltrim(rtrim(@db_name)) + '_' +@yyyymmdd + '_' + @hhmm
                       + '.logdump'

dump tran @db_name to @backupfile

/*
**  Error 4221  ---> exec sp_full_backup
**  DUMP TRANsaction to a dump device is not allowed where a truncate-only
**  transaction dump has been performed after the last DUMP DATABASE.  Use
**  DUMP DATABASE instead.
**
*/

/*
**  Error 4207  ---> exec sp_full_backup
**  Dump transaction is not allowed because a non-logged operation was  
**  performed on the database. Dump your database or use dump transaction with
**  truncate_only until you can dump your database.
**
*/

declare @err int
select @err = @@error

if (@err = 4221)
begin
        print "[Message from sp_log_backup] "
        print "DUMP TRAN to a dump device is not allowed  where a truncate_only"
        print "transaction dump has been performed after the last DUMP DATABASE."
        print ".... Now execute DUMP DATABASE."

        exec sp_full_backup @db_name
end
else if (@err = 4207)
begin
        print "[Message from sp_log_backup] "
        print "Dump transaction is not allowed because a non-logged operation was "
        print "performed on the database. Dump your database or use dump transaction with"
        print "truncate_only until you can dump your database."
        print ".... Now execute DUMP DATABASE."

        exec sp_full_backup @db_name
end

return
go


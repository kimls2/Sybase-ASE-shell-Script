/**
*** Usage : sp_full_backup db_name
**/
use sybsystemprocs
go

if exists (select * from sysobjects where name = 'sp_full_backup' )
        drop proc sp_full_backup
go

create proc sp_full_backup  (@db_name varchar(30))
as

if not exists ( select * from master.dbo.sysdatabases
                where name = ltrim(rtrim(@db_name)) )
begin
        print "[Message from sp_full_backup] "
        print "database %1! does not exists...",@db_name
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

if (@db_name = 'master' or @db_name = 'model' or @db_name ='sybsystemprocs' )
 begin
	select  @dir      = '/DBbackup/SYSTEMDB/'
	select  @backupfile = 'compress::' + @dir
                      + ltrim(rtrim(@db_name)) + '_' + @yyyymmdd + '_' + @hhmm
                      + '.dbdump'
        dump database @db_name to @backupfile
 end
else
 begin
	select  @dir      = '/DBbackup/' + ltrim(rtrim(@db_name)) + '/'

	select  @backupfile = 'compress::' + @dir
                      + ltrim(rtrim(@db_name)) + '_' + @yyyymmdd + '_' + @hhmm
                      + '.dbdump'
	declare @backupfile1  varchar(100) 
	declare @backupfile2  varchar(100) 
	declare @backupfile3  varchar(100) 
	declare @backupfile4  varchar(100) 
	select @backupfile1=@backupfile + '_1'
	select @backupfile2=@backupfile + '_2'
	select @backupfile3=@backupfile + '_3'
	select @backupfile4=@backupfile + '_4'

	dump database @db_name to @backupfile1 
                        stripe on @backupfile2
                        stripe on @backupfile3
                        stripe on @backupfile4

 end


return
go


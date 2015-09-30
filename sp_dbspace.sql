
-----------------------------------------------------------------------------
-- DDL for Stored Procedure 'sybsystemprocs.dbo.sp_dbspace;1'
-----------------------------------------------------------------------------

print '<<<<< CREATING Stored Procedure - "sybsystemprocs.dbo.sp_dbspace;1" >>>>>'
go 

use sybsystemprocs
go

IF EXISTS (SELECT 1 FROM sysobjects o, sysusers u WHERE o.uid=u.uid AND o.name = 'sp_dbspace' AND u.name = 'dbo' AND o.type = 'P')
BEGIN
	setuser 'dbo'
	drop procedure sp_dbspace

END
go 

IF (@@error != 0)
BEGIN
	PRINT 'Error CREATING Stored Procedure sybsystemprocs.dbo.sp_dbspace;1'
	SELECT syb_quit()
END
go

setuser 'dbo'
go 

CREATE PROCEDURE dbo.sp_dbspace
@persize varchar(2) = 'M'
as
begin
        declare @persizenum int
        declare @perstring varchar(10)
        set @persizenum = 1024*1024 
        set @perstring = 'MB'


        if @persize='K' or  @persize='KB' or  @persize='k' or  @persize='kb' 
        begin
          set @persizenum=1024 
          set @perstring = 'KB'
        end
        if @persize='M' or  @persize='MB' or @persize='m' or  @persize='mb'
        begin
          set @persizenum=1024*1024 
          set @perstring = 'MB'
        end
        if @persize='G' or  @persize='GB' or @persize='g' or  @persize='gb'
        begin
          set @persizenum=1024*1024*1024 
          set @perstring = 'GB'
        end

        create table #dbspace(
            DBName varchar(15),
            TotalMB varchar(11),
            LogMB varchar(11),
            DataMB varchar(11),
            UseMB varchar(11),
            "Usage" varchar(5),
            FreeMB varchar(11)
        )
  
			  select
			        convert(varchar(15), db_name(dbid)) as 'dbname' 
			        , convert(numeric(16,3),(convert(float,sum(size))*@@maxpagesize)/@persizenum) as  'datasize'
			         ,convert(numeric(16,3),(convert(float,isnull((select sum(size)*@@maxpagesize  from master..sysusages where segmap=4 and dbid=a.dbid),0)/@persizenum)))   as  'logsize'
			         ,convert(numeric(16,3),(convert(float,sum(curunreservedpgs(dbid, lstart, unreservedpgs))*@@maxpagesize)/@persizenum))   as 'freesize'
			         into #tmp_dbspace
			from master..sysusages as a
			where segmap<>4
			group by dbid 
			
            insert into #dbspace
			select convert(varchar(15),dbname ) 'DB Name'
						, convert(varchar(9), case when (datasize + logsize)>0 and (datasize + logsize)<1 then 
										convert(varchar(8),(datasize + logsize))+' '+@perstring 
							else 
										convert(varchar(8),convert(numeric(16,0),(datasize + logsize)))	+' '+@perstring 
							end)  as 'TotalSize'
			 			, convert(varchar(9), case when  logsize >0 and logsize <1 then 
										convert(varchar(8),logsize)	+' '+@perstring 
							else 
										convert(varchar(8),convert(numeric(16,0),logsize))	+' '+@perstring 
							end)  as 'LogSize'
			  			, convert(varchar(9), case when  datasize >0 and datasize <1 then 
			  						convert(varchar(8),datasize)	+' '+@perstring 
							else 
										convert(varchar(8),convert(numeric(16,0),datasize))	+' '+@perstring 
							end)  as 'DataSize'
				  		, convert(varchar(9), case when  (datasize-freesize) >0 and (datasize-freesize) <1 then 
										convert(varchar(8),(datasize-freesize))	+' '+@perstring 
							else 
										convert(varchar(8),convert(numeric(16,0),(datasize-freesize)))	+' '+@perstring 
							end)  as 'UseSize'	
                            , case when (datasize-freesize)>0 and (datasize-freesize) >0  then 
					 				convert(varchar(3),convert(int,round((datasize-freesize)/datasize*100,0)))+' %'
					 		 else  
					 				'0 %'
					 		 end  as 'UseSize(%)'
					 		, convert(varchar(9), case when  freesize >0 and freesize <1 then 
										convert(varchar(8),freesize)	+' '+@perstring 
							else 
										convert(varchar(8),convert(numeric(16,0),freesize))	+' '+@perstring 
							end)  as 'FreeSize'	
			 FROM #tmp_dbspace

             exec sp_autoformat #dbspace
			 
			 drop table #tmp_dbspace
            drop table #dbspace
end
go 


sp_procxmode 'sp_dbspace', unchained
go 

setuser
go 


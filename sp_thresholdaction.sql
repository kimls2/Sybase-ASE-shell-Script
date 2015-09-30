use sybsystemprocs
go

if exists ( select * from sysobjects where name = 'sp_thresholdaction' and type = 'P' )
        drop procedure sp_thresholdaction
go

create procedure sp_thresholdaction
                ( @dbname       varchar(30),
                  @segmentname  varchar(30),
                  @space_left   int,
                  @status       int)
as
        exec sp_log_backup @dbname
        print "LOG DUMP : logsegment space left : %1! pages ",@space_left
        print "LOG DUMP : execute sp_log_backup  %1! ",@dbname

return
go


grant exec on sp_thresholdaction to public
go

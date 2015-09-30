use master
go
sp_addlogin 'TEST', 'TEST', 'pubs2'
go
use pubs2
go
sp_adduser 'TEST'
go
create procedure limit_TEST_sessions
as
declare @loginname varchar(32)
select @loginname = name
from master.dbo.syslogins
where suid = suser_id()
/* check the limit */
if @loginname = 'TEST'
begin
print "Aborting login [%1!]",@loginname
/* abort this session */
select syb_quit()
end
go
grant exec on limit_TEST_sessions to public
go
use master
go
alter login TEST modify login script
"limit_TEST_sessions"
go

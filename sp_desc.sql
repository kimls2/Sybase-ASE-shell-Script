use sybsystemprocs
go
IF EXISTS (SELECT 1 FROM sysobjects           WHERE name = 'sp_desc' AND id = object_id('sp_desc') AND type = 'P')
	DROP PROCEDURE sp_desc
go
 
create procedure sp_desc
@objname varchar(767) = NULL			/* object name we're after */
as
if @objname is not null 
begin
		Select 
			 [column_name]  =   isnull(c.name, 'NULL'),
       [column_type] = isnull(convert(char(30), x.xtname),	isnull(convert(char(30),get_xtypename(c.xtype, c.xdbid)),t.name)), 
       [column_len] = c.length,
 	     [nulls] =   case when convert(bit, (c.status & 8))= 0 then 'NO' else 'YES' end   ,
       [keyinfo] =  	(select status from sysindexes where id=c.id and indid= c.colid and status2 & 2 = 2 ),
       [keyinfo2] =  	(select status2 from sysindexes where id=c.id and indid= c.colid and status2 & 2 = 2 ), 
			 [keyinfo3] =   ( select  'PK'  from syskeys k, master.dbo.spt_values v  where k.type = v.number and v.type = 'K'  and  k.id = object_id(@objname) and v.name='primary' and (key1 =c.colid or key2 =c.colid or key3 =c.colid or key4 =c.colid or key5 =c.colid or key6 =c.colid or key7 =c.colid or key8 =c.colid )) , 
			 [keyinfo4] =   ( select  'FK'   from syskeys k, master.dbo.spt_values v  where k.type = v.number and v.type = 'K'  and  k.id = object_id(@objname) and v.name='foreign' and (key1 =c.colid or key2 =c.colid or key3 =c.colid or key4 =c.colid or key5 =c.colid or key6 =c.colid or key7 =c.colid or key8 =c.colid )) , 
       [Df] =   (select convert(varchar(250), text) from syscomments where id= c.cdefault)   ,
      [Ident] =   convert(bit, (c.status & 0x80))  ,
      [colid] = c.colid
    into #ttableinfo  
		from syscolumns c, systypes t, sysxtypes x
		where c.id = object_id(@objname)
		and c.usertype *= t.usertype
		and c.xtype *= x.xtid 

		select 
			convert(varchar(26),column_name) as [Name],
			convert(varchar(22), column_type+'('+convert(varchar(10),column_len)+')')  as [Type],
			convert(varchar(6),nulls) as [Null] ,
			convert(varchar(12), case when keyinfo3=null and keyinfo4=null then 
																(case when  (keyinfo is not null) then  case when (keyinfo & 2048)=2048 then 'PK' end 	else ''	end)+ (case when (keyinfo2& 1)=1 then 'FK' else '' end )
														else 
																case when keyinfo3='PK' or keyinfo4='FK' then  keyinfo3+keyinfo4 else '' end 
														end ) as [Key],
		 	convert(varchar(25), case when charindex('DEFAULT',Df)>0 then 	
		 												substring(Df,10,len(Df)) 
		 											else 
		 													case when charindex('as ',Df)>0 then 	substring(Df,charindex('as ',Df)+3,len(Df)-(charindex('as ',Df)+3))	else 	Df  end
		 											end) as [Default],
	  	convert(varchar(20),(case when Ident=1 then 'Identity' else '' end) + (case when  (keyinfo is not null) and  (keyinfo & 2048)<>2048  then  'UNIQUE' end  )) as Etc 
		from #ttableinfo  ORDER BY colid ASC
		drop table #ttableinfo 
	end 
return(0)
go	

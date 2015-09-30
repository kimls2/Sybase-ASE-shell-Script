select
substring(db_name(u.dbid),1,20)  "dbname" ,
substring(d.name,1,20) "device",

size_PG=sum(u.size  ),
freespace_PG = sum(curunreservedpgs(dbid, lstart, unreservedpgs) ),

size_MB=sum(u.size  /(1024/(@@maxpagesize/1024))),
freespace_MB= sum(curunreservedpgs(dbid, lstart, unreservedpgs)) /(1024/(@@maxpagesize/1024))

from sysusages u,
     sysdevices d
where u.vstart between  d.low  and  d.high
and  d.cntrltype=0
group by u.dbid,d.name
order by u.dbid,d.name

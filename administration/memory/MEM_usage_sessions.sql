select sid, name, value 
from v$statname n, v$sesstat s
where n.statistic# = s.statistic#
  and name like 'session%memory%'
order by 3 asc
/

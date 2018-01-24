select
    2048576+Sum(value) as pga_size
from v$parameter
where name IN ('sort_area_size','hash_area_size')
/
select RPAD(name,36,' ')||value as param from v$parameter where Upper(name) like Upper('%pga%') order by name
/

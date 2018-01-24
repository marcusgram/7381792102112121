select owner, 
table_name, 
partitioning_type, 
partition_count
from dba_part_tables
where owner not in ('SYS','SYSTEM')
/

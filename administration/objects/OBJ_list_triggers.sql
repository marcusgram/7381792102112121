select owner, trigger_name, status, table_owner||'.'||table_name as table_name
from dba_triggers
order by 1,4,2,3
/

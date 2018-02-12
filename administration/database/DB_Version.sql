col banner           format a100 
col action           format a15
col namespace        format a15
col version          format a15
col bundle_series    format a15
col comments         format a35   

select banner
from   v$version;

select to_char(action_time, 'YYYY-MM-DD HH24:MI:SS') as action_time,
       action,
       namespace,
       version,
       id,
       bundle_series,
       comments
from   dba_registry_history
order by action_time;

col banner           clear
col action           clear
col namespace        clear
col version          clear
col bundle_series    clear
col comments         clear

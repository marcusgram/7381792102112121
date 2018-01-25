-- Produce a list of SQL Profiles
-- Optional filter by either SQL text or profile name
--

set lines 1000
set pages 1000
col category for a15
col sql_text for a70 trunc
col signature for 999999999999999999999999999999
col force_matching for a5

select name, category, status, signature, force_matching, sql_text
from dba_sql_profiles
where sql_text like nvl('&sql_text',sql_text)
and name like nvl('&name',name)
order by last_modified
/

undef sql_text
undef name


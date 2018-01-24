


select sum(bytes)/1048576 as MB FROM (
select bytes from v$sgastat
union
select value as bytes from v$sesstat s, v$statname n
  where n.statistic#=s.statistic# 
  and n.name = 'session pga memory' )
/



-------------------------------
--PL/SQL
--Get Memory detailled usages
-------------------------------

declare
 object_mem           number;
 shared_sql           number;
 cursor_mem           number;
 mts_mem              number;
 used_pool_size       number;
 free_mem             number;
 pool_size            varchar2(512);
begin
  -- Stored objects (packages, views)
  SELECT sum(sharable_mem) INTO object_mem FROM v$db_object_cache;
  -- Shared SQL -- need to have additional memory if dynamic SQL used
  SELECT sum(sharable_mem) INTO shared_sql FROM v$sqlarea;
  -- User Cursor Usage -- run this during peak usage.
  -- assumes 250 bytes per open cursor, for each concurrent user.
  SELECT sum(250*users_opening) INTO cursor_mem FROM v$sqlarea;
  -- For a test system -- get usage for one user, multiply by # users
  -- SELECT (250 * value) bytes_per_user
  -- FROM v$sesstat s, v$statname n
  -- WHERE s.statistic# = n.statistic#
  -- and n.name = 'opened cursors current'
  -- and s.sid = 25; -- WHERE 25 is the sid of the process
  -- MTS memory needed to hold session information for shared server users
  -- This query computes a total for all currently logged on users (run
  -- during peak period). Alternatively calculate for a single user and
  -- multiply by # users.
  SELECT sum(value) INTO mts_mem FROM v$sesstat s, v$statname n
    WHERE s.statistic#=n.statistic#
      and n.name='session uga memory max';
  -- Free (unused) memory in the SGA: gives an indication of how much memory
  -- is being wasted out of the total allocated.
  SELECT sum(bytes) INTO free_mem FROM v$sgastat
     WHERE name = 'free memory';
  -- For non-MTS add up object, shared sql, cursors and 30% overhead.
  used_pool_size := round(1.3*(object_mem+shared_sql+cursor_mem));
  -- For MTS add mts contribution also.
  -- used_pool_size := round(1.3*(object_mem+shared_sql+cursor_mem+mts_mem));
  SELECT value INTO pool_size FROM v$parameter WHERE name='shared_pool_size';
  -- Display results
  dbms_output.put_line ('Obj mem........................ :'||LPAD(To_Char (object_mem),20,' ')||' bytes');
  dbms_output.put_line ('Shared sql..................... :'||LPAD(To_Char (shared_sql),20,' ')||' bytes');
  dbms_output.put_line ('Cursors........................ :'||LPAD(To_Char (cursor_mem),20,' ')||' bytes');
  dbms_output.put_line ('MTS session.................... :'||LPAD(To_Char (mts_mem),20,' ')   ||' bytes');
  dbms_output.put_line ('Free memory.................... :'||LPAD(To_Char (free_mem),20,' ')  ||' bytes '||'('||To_Char(round(free_mem/1024/1024,2))||'M)');
  dbms_output.put_line ('Shared pool utilization (total) :'||LPAD(To_Char(used_pool_size),20,' ')||' bytes '||'(' ||To_Char(round(used_pool_size/1024/1024,2))||'M)');
  dbms_output.put_line ('Shared pool allocation (actual) :'||LPAD(pool_size,20,' ')||' bytes '||'('||To_Char(round(pool_size/1024/1024,2))||'M)');
  dbms_output.put_line ('Percentage Utilized............ :'||LPAD(To_Char(round(used_pool_size/pool_size*100)),20,' ')|| '%');
end;
/

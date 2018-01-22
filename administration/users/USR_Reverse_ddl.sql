


set long 20000 longchunksize 20000 pagesize 0 linesize 1000 feedback off verify off trimspool on
column ddl format a1000

begin
   dbms_metadata.set_transform_param (dbms_metadata.session_transform, 'SQLTERMINATOR', true);
   dbms_metadata.set_transform_param (dbms_metadata.session_transform, 'PRETTY', true);
end;
/


variable v_username VARCHAR2(30);

exec:v_username := upper('&1');

select dbms_metadata.get_ddl('USER', u.username) AS ddl
from   dba_users u
where  u.username = :v_username
union all
select dbms_metadata.get_granted_ddl('TABLESPACE_QUOTA', tq.username) AS ddl
from   dba_ts_quotas tq
where  tq.username = :v_username
and    rownum = 1
union all
select dbms_metadata.get_granted_ddl('ROLE_GRANT', rp.grantee) AS ddl
from   dba_role_privs rp
where  rp.grantee = :v_username
and    rownum = 1
union all
select dbms_metadata.get_granted_ddl('SYSTEM_GRANT', sp.grantee) AS ddl
from   dba_sys_privs sp
where  sp.grantee = :v_username
and    rownum = 1
union all
select dbms_metadata.get_granted_ddl('OBJECT_GRANT', tp.grantee) AS ddl
from   dba_tab_privs tp
where  tp.grantee = :v_username
and    rownum = 1
union all
select dbms_metadata.get_granted_ddl('DEFAULT_ROLE', rp.grantee) AS ddl
from   dba_role_privs rp
where  rp.grantee = :v_username
and    rp.default_role = 'YES'
and    rownum = 1
union all
select to_clob('/* Start profile creation script in case they are missing') AS ddl
from   dba_users u
where  u.username = :v_username
and    u.profile <> 'DEFAULT'
and    rownum = 1
union all
select dbms_metadata.get_ddl('PROFILE', u.profile) AS ddl
from   dba_users u
where  u.username = :v_username
and    u.profile <> 'DEFAULT'
union all
select to_clob('End profile creation script */') AS ddl
from   dba_users u
where  u.username = :v_username
and    u.profile <> 'DEFAULT'
and    rownum = 1
/

set linesize 80 pagesize 14 feedback on trimspool on verify on



-- -----------------------------------------------------------------------------------
-- Description  : Displays the DDL for a specific user.
-- Call Syntax  : @user_ddl (username)
-- Require username
-- -----------------------------------------------------------------------------------

ACCEPT OWNER PROMPT "Enter username (you can use 'USER1'):"

set long 20000 longchunksize 20000 pagesize 0 linesize 1000 feedback off verify off trimspool on
column ddl format a1000

DEFINE LOGNAME=date
COLUMN clogname new_value logname

SELECT 'GET_ALL_DLL_'||to_char(sysdate, 'yyyymmdd') clogname from dual;
SPOOL &OWNER._&logname..out

begin
   dbms_metadata.set_transform_param (dbms_metadata.session_transform, 'SQLTERMINATOR', true);
   dbms_metadata.set_transform_param (dbms_metadata.session_transform, 'PRETTY', true);
end;
/

select dbms_metadata.get_ddl('USER', u.username) AS ddl
from   dba_users u
where  (u.username = '&OWNER')
union all
select dbms_metadata.get_granted_ddl('TABLESPACE_QUOTA', tq.username) AS ddl
from   dba_ts_quotas tq
where  (tq.username = '&OWNER')
and    rownum = 1
union all
select dbms_metadata.get_granted_ddl('ROLE_GRANT', rp.grantee) AS ddl
from   dba_role_privs rp
where  (rp.grantee = '&OWNER')
and    rownum = 1
union all
select dbms_metadata.get_granted_ddl('SYSTEM_GRANT', sp.grantee) AS ddl
from   dba_sys_privs sp
where  (sp.grantee = '&OWNER')
and    rownum = 1
union all
select dbms_metadata.get_granted_ddl('OBJECT_GRANT', tp.grantee) AS ddl
from   dba_tab_privs tp
where  (tp.grantee = '&OWNER')
and    rownum = 1
union all
select dbms_metadata.get_granted_ddl('DEFAULT_ROLE', rp.grantee) AS ddl
from   dba_role_privs rp
where  (rp.grantee = '&OWNER')
and    rp.default_role = 'YES'
and    rownum = 1
union all
select to_clob('/* Start profile creation script in case they are missing') AS ddl
from   dba_users u
where  (u.username = '&OWNER')
and    u.profile <> 'DEFAULT'
and    rownum = 1
union all
select dbms_metadata.get_ddl('PROFILE', u.profile) AS ddl
from   dba_users u
where  (u.username = '&OWNER')
and    u.profile <> 'DEFAULT'
union all
select to_clob('End profile creation script */') AS ddl
from   dba_users u
where  (u.username = '&OWNER')
and    u.profile <> 'DEFAULT'
and    rownum = 1
/

SPOOL OFF
set linesize 80 pagesize 14 feedback on trimspool on verify on





-- -----------------------------------------------------------------------------------
-- Description  : Displays the DDL for a specific user.
-- Call Syntax  : @logon_as_user (username)
-- Return alter with the original password
-- -----------------------------------------------------------------------------------

set serveroutput on verify off
declare
  l_username VARCHAR2(30) :=  upper('&1');
  l_orig_pwd VARCHAR2(32767);
begin 
  select password
  into   l_orig_pwd
  from   sys.user$
  where  name = l_username;

  dbms_output.put_line('--');
  dbms_output.put_line('alter user ' || l_username || ' identified by DummyPassword1;');
  dbms_output.put_line('conn ' || l_username || '/DummyPassword1');

  dbms_output.put_line('--');
  dbms_output.put_line('-- Do something here.');
  dbms_output.put_line('--');

  dbms_output.put_line('conn / as sysdba');
  dbms_output.put_line('alter user ' || l_username || ' identified by values '''||l_orig_pwd||''';');
end;
/

--
alter user OEMPF identified by DummyPassword1;
conn OEMPF/DummyPassword1
--
-- Do something here.
--
conn / as sysdba
alter user OEMPF identified by values 'EB080FDE315654CD';
--







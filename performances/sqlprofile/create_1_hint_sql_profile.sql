----------------------------------------------------------------------------------------
--
-- File name:   create_1_hint_sql_profile.sql
--
-- Purpose:     Prompts for a hint and makes a profile out of it.
-
-- Usage:       This scripts prompts for four values.
--
--              profile_name: the name of the profile to be attached to a new statement
--
--              sql_id: the sql_id of the statement to attach the profile to (must be in theshared pool)
--
--              category: the category to assign to the new profile 
--
--              force_macthing: a toggle to turn on or off the force_matching feature
--
-- Description: This script prompt for a hint. It does not validate the hint. It creates a 
--              SQL Profile with the single hint and attaches it to the provided sql_id.
--              This script should now work with all flavors of 10g and 11g.
--              
----------------------------------------------------------------------------------------- 

accept sql_id -
       prompt 'Enter value for sql_id: ' -
       default 'X0X0X0X0'
accept profile_name -
       prompt 'Enter value for profile_name (PROFILE_sqlid_MANUAL): ' -
       default 'X0X0X0X0'
accept category -
       prompt 'Enter value for category (DEFAULT): ' -
       default 'DEFAULT'
accept force_matching -
       prompt 'Enter value for force_matching (false): ' -
       default 'false'


set feedback off
set sqlblanklines on

declare
l_profile_name varchar2(30);
cl_sql_text clob;
l_category varchar2(30);
l_force_matching varchar2(3);
b_force_matching boolean;
begin

select
sql_fulltext
into
cl_sql_text
from
v$sqlarea
where
sql_id = '&&sql_id';

select decode('&&profile_name','X0X0X0X0','PROFILE_'||'&&sql_id'||'_MANUAL','&&profile_name')
into l_profile_name
from dual;

/*
don't forget to use Query Block name: "full(tab@sel$1)" for example
and aliases if in use
also, you can specify more than one hint: "full(tab@sel$1) first_rows_1" for example

comma separated hints also work in a direct call
profile  => sqlprof_attr(‘ALL_ROWS’,'IGNORE_OPTIM_EMBEDDED_HINTS’)
*/

dbms_sqltune.import_sql_profile(
sql_text => cl_sql_text, 
profile => sqlprof_attr('&hint'),
category => '&&category',
name => l_profile_name,
-- use force_match => true
-- to use CURSOR_SHARING=SIMILAR
-- behaviour, i.e. match even with
-- differing literals
force_match => &&force_matching
);

dbms_output.put_line(' ');
dbms_output.put_line('Profile '||l_profile_name||' created.');
dbms_output.put_line(' ');

end;
/

undef profile_name
undef sql_id
undef category
undef force_matching

set sqlblanklines off
set feedback on

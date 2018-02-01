-- ********************************************************************
-- * Copyright Notice   : (c)1998 OraPub, Inc.
-- * Filename		: users.sql - Version 1.0
-- * Author		: Craig A. Shallahamer
-- * Original		: 17-AUG-98
-- * Last Update	: 17-AUG-98
-- * Description	: Basic Oracle user information
-- * Usage		: start users.sql
-- ********************************************************************

def osm_prog	= 'users.sql'
def osm_title	= 'Basic Oracle Database User Information'

col username format a12 heading 'Username'             justify c
col role     format a21 heading 'Role (admin,grant)'   justify c
col dts      format a12 heading 'Default|Tablespace'   justify c
col tts      format a12 heading 'Temporary|Tablespace' justify c
col prof     format a18 heading 'Profile' 	       justify c

break on username on role on dts on tts

select
  username,
  default_tablespace    dts,
  temporary_tablespace  tts,
  profile			prof,
  granted_role || '-' ||
  decode(admin_option,'YES','Y','N') ||
  decode(granted_role,'YES','Y','N') role
from
  dba_users,
  dba_role_privs
where
  dba_users.username = dba_role_privs.grantee and
  username != 'PUBLIC'
order by
  1,2,3,4
/

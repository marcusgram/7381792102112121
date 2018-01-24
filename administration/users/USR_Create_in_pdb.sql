
-- >---
-- >title: Oracle 12c create user
-- >metadata:
-- >    description: 'Oracle create a user in oracle 12c'
-- >    keywords: 'Oracle create user, local user, common user, oracle 12c, example code, tutorials'
-- >author: Venkata Bhattaram / tinitiate.com
-- >code-alias: create-user
-- >slug: oracle/admin/create-user
-- >---

-- ># Users in Oracle
-- >* There are two types of users in Oracle 12c
-- >* **Common Use** The user is present in all containers databases (root and all PDBs).
-- >* **Local User** The user is only present in a specific PDB. The same username can be present in multiple PDBs, but they are unrelated.

-- >```sql
-- Login as SYSDBA and run the following

-- Step 1.
-- Get the name of the current PDB
select    name, PDB
from      V$SERVICES
order by  name;

-- Set the current PDB, on this installation there is only pdborcl
alter session set container = pdborcl;

-- Open the database
alter database open;

-- Create a Local user
create user tinitiate identified by tinitiate;
grant connect, resource to tinitiate;


-- Assign the user a tablespace

-- Check the available tablespaces
select *
from   dba_tablespaces;

-- Assign tablespaces to the user
alter user tinitiate quota unlimited on ti_user_data;
alter user tinitiate quota unlimited on ti_user_indx;

-- Assign a default tablespace to the user
alter user tinitiate default tablespace ti_user_data;
-- >```

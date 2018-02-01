1. Set init parameter "CONTROL_MANAGEMENT_PACK_ACCESS" to NONE

2. Recreate AWR by using the following procedure
 
SQL> shutdown immediate  
SQL> startup restrict  

-- On both 10g and 11g   
SQL> @?/rdbms/admin/catnoawr.sql  
SQL> alter system flush shared_pool;  
SQL> @?/rdbms/admin/catawrtb.sql  
SQL> @?/rdbms/admin/utlrp.sql  

--On 11g it is necessary to also run:  
SQL> @?/rdbms/admin/execsvrm.sql  
SQL> exec dbms_workload_repository.modify_snapshot_settings(interval=>0);  
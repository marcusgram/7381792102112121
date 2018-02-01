
============================================
Disabling Diagnostic and Tuning Pack and AWR
============================================

For Oracle 11g,by default diagnostic & tuning package and AWR are enabled and use of this feature needs
additional licencing.  We can disable them and save the extra licence cost. We can set the init
parameter CONTROL_MANAGEMENT_PACK_ACCESS to NONE and Install the Oracle package to disable AWR snapshots.
 
Example AWR report for TEST db on HOST01 in Oracle 11g,
 SQL> @awrrpt
 Instance DB Name Snap Id Snap Started Level
 ———— ———— ——— —————— —–
 TEST TEST 3829 11 Mar 2013 08:00 1
 3830 11 Mar 2013 09:00 1
 3831 11 Mar 2013 10:00 1
 3832 11 Mar 2013 11:00 1
 3833 11 Mar 2013 12:00 1
 3834 11 Mar 2013 13:00 1
 3835 11 Mar 2013 14:00 1
 Specify the Begin and End Snapshot Ids
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 Enter value for begin_snap:

This parameter is dynamic; so to change the parameter from default to none, the following command can be used:
 
1.To Check current parameter
 SQL> show parameter control_management_pack_access
 NAME TYPE VALUE
 ———————————— ———– ——————————
 control_management_pack_access string DIAGNOSTIC+TUNING
 
2.Adjust parameter to disabling AWR
 SQL> ALTER SYSTEM SET control_management_pack_access=NONE scope=both;
 System altered.
 
3.Verify parameter again after disabled
 SQL> show parameter control_management_pack_access
 NAME TYPE VALUE
 ———————————— ———– ——————————
 control_management_pack_access string NONE
 
4.To Install the Package and Disable AWR snapshots, download the package from MOS 1909073.1, install it
  as SUSDBA, then run it as SYS from SQL*Plus:
 
SQL> @dbmsnoawr.plb
 Package created.
 Package body created.
 
SQL> begin dbms_awr.disable_awr();
 2 end;
 3 /
 PL/SQL procedure successfully completed.
 
5.Verify AWR again after disabled
 So the last snapshot of CMWHTST still @14:00…So AWR snapshots will not be taken anymore in DB level (as no data for snapshot 15:00)
 SQL> @awrrpt
 3834 11 Mar 2013 13:00 1
 3835 11 Mar 2013 14:00 1
 
Specify the Begin and End Snapshot Ids
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 
6.Optional - Execute ~/rdbms/admin/catnoawr.sql to remove all the AWR repository objects to free up space in SYSAUX


10G for “Controlling Diagnostic and Tuning Pack Usage and Disabling AWR”
 
1.No need to change any init parameter. Just perform the process under step 4 above
from SQL*Plus to disable AWR:
 
SQL> @dbmsnoawr.plb
 Package created.
 Package body created.
 
SQL> begin dbms_awr.disable_awr();
 2 end;
 3 /
 PL/SQL procedure successfully completed.
 
2.Verify AWR again after disabled
 So the last snapshot of TEST still @14:00…So AWR snapshots will not be taken anymore in DB level (as no data for snapshot 15:00)
 SQL> @awrrpt
 3834 11 Mar 2013 13:00 1
 3835 11 Mar 2013 14:00 1
 
Specify the Begin and End Snapshot Ids
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

3.Optional - Execute ~/rdbms/admin/catnoawr.sql to remove all the AWR repository objects to free up space in SYSAUX


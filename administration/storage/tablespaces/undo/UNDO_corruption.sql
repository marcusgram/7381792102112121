

Unable to drop undo tablespace due to ORA-01548: active rollback segment
------------------------------------------------------------------------

Problem:

– create a new undo tablespace and set it to undo tablespace of instance
sys@ora11gr2> alter system set undo_tablespace=undotbs2;

– but we can not drop the original one

sys@ora11gr2> drop tablespace undotbs1 including contents and datafiles;
drop tablespace undotbs1 including contents and datafiles
*
ERROR at line 1:
ORA-01548: active rollback segment ‘_SYSSMU2_6654314$’ found, terminate dropping tablespace

Cause of the problem

An attempt was made to drop a tablespace that contains active rollback segments

Solution:

1) find all active rollback segment in the undo tablespace to be dropped.

sys@ora11gr2> select segment_name, tablespace_name, status from dba_rollback_segs where tablespace_name=’UNDOTBS1'

SEGMENT_NAME TABLESPACE_NAME STATUS
—————————— —————————— —————-
_SYSSMU10_820739558$ UNDOTBS1 OFFLINE
_SYSSMU9_2448906239$ UNDOTBS1 OFFLINE
_SYSSMU8_3066916762$ UNDOTBS1 OFFLINE
_SYSSMU7_892861194$ UNDOTBS1 OFFLINE
_SYSSMU6_1956589931$ UNDOTBS1 OFFLINE
_SYSSMU5_2919322705$ UNDOTBS1 OFFLINE
_SYSSMU4_3876247569$ UNDOTBS1 OFFLINE
_SYSSMU3_4245574747$ UNDOTBS1 OFFLINE
_SYSSMU2_6654314$ UNDOTBS1 PARTLY AVAILABLE

2) set a parameter including all active rollback segments in init.ora file

create pfile='/tmp/rescue.ora' from spfile;

_offline_rollback_segments=(_SYSSMU2_6654314$,…..)

3) shutdown database 

4) Mount the database using pfile
sys@ora11gr2> startup mount pfile='/tmp/rescue.ora'

5) offline undo datafile for drop

sys@ora11gr2> alter database datafile ‘/app/oracle/oradata/ORA11GR2/undotbs1.dbf’ offline drop;

6) open database
sys@ora11gr2> alter database open;

7)drop the undo segment

sys@ora11gr2> drop rollback segment “_SYSSMU2_6654314$”;

8)Add a new undo tablespace and set it as instance’s undo tablespace
…
sys@ora11gr2> alter system set undo_tablespace=undotbs2;

9) drop original undo tablespace
sql>Drop Tablespace undotbs1 including contents and datafiles;

10) remove the _offline_rollback_segments parameter fron pfile

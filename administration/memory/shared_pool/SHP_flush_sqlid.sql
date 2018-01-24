---------------------------------------------------------------------------
--https://blogs.oracle.com/mandalika/entry/oracle_rdbms_flushing_a_single
---------------------------------------------------------------------------

select ADDRESS, HASH_VALUE from V$SQLAREA where SQL_ID like '7yc%';

ADDRESS      HASH_VALUE
---------------- ----------
000000085FD77CF0  808321886

exec DBMS_SHARED_POOL.PURGE ('000000085FD77CF0, 808321886', 'C');

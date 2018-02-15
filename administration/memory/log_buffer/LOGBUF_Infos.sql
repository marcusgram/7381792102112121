

show sga

Total System Global Area   3053453312 bytes      
Fixed Size                    2929064 bytes      
Variable Size              2281705048 bytes      
Database Buffers            754974720 bytes      
Redo Buffers                 13844480 bytes      


select * from v$sgainfo;

NAME                                  BYTES RES     CON_ID
-------------------------------- ---------- --- ----------
Fixed SGA Size                      2929064 No           0
Redo Buffers                       13844480 No           0
Buffer Cache Size                 754974720 Yes          0
In-Memory Area Size                       0 No           0
Shared Pool Size                 1174405120 Yes          0
Large Pool Size                    16777216 Yes          0
Java Pool Size                     16777216 Yes          0
Streams Pool Size                  16777216 Yes          0
Shared IO Pool Size               100663296 Yes          0
Data Transfer Cache Size                  0 Yes          0
Granule Size                       16777216 No           0
Maximum SGA Size                 3053453312 No           0
Startup overhead in Shared Pool   267176776 No           0
Free SGA Memory Available        1056964608              0




select name, bytes from v$sgastat where name = 'log_buffer';

NAME                            BYTES
-------------------------- ----------
log_buffer                   13844480



select name, value from v$sga where name = 'Redo Buffers';


NAME                      VALUE
-------------------- ----------
Redo Buffers           13844480



How to set the log Buffer size?
Log buffer size is control internal by oracle from 10g and later. 
Per Meta link note 351857.1, Oracle automatically size the log_buffer. 
Also, if we use AMM, the log buffer size is part of memory_target algorithm. 
If you really need to change the log_buffer, you can still use alter system to change it. 
The parameter is not dynamic, so we need to set the scope to spfile and bounce the instance to make it effective.


Read more at http://www.sqlpanda.com/2012/10/redo-log-buffer.html#RtIVZBLq90MlkFsr.99



##### Decreasing log file sync waits
Oracle Database Tips by Donald Burleson

*Question: I have "log file sync waits" in my top-5 timed events.  How do I tune to reduce the log file sync wait events?*

 

Answer:The log file sync wait occurs at the end of a transaction (COMMIT or EOJ)
and the database writer (DBWR) process must wait for the log file to synchronize with the database.  
Oracle guru Steve Adams notes details on how Oracle processes log file sync waits:

"Before writing a batch of database blocks, DBWn finds the highest high redo block address that needs to be synced before the batch can be written.

 

DBWn then takes the redo allocation latch to ensure that the required redo block address has already been written by LGWR, and if not, it posts LGWR and sleeps on a log file sync wait."

Log file sync waits occur when the LGWR process is unable to complete writes fast enough  Redo log activity increases as a function of system activity, and high log file sync waits may occur during periods of high DML activity. 

Some solutions to log file sync waits include:
```- Slow disk I/O:  Segregating the redo log file onto separate disk spindles can reduce log file sync waits. 
Moving the online redo logs to fast SSD storage and increasing the log_buffer size above 10 megabytes (It is automatically set in 11g and beyond).```

If I/O is slow (timings in AWR or STATSPACK reports > 15 ms), then the only solution for log file sync waits is to improve I/O bandwidth.

- LGWR is not getting enough CPU:  If the vmstat runqueue column is greater than cpu_count, then the instance is CPU-bound and this can manifest itself in high log file sync waits.  
The solution is to tune SQL (to reduce CPU overhead), to add processors, or to 'nice' the dispatching priority of the LGWR process. 

- High COMMIT activity:  A poorly-written application is issuing COMMIT s too frequently, causing high LGWR activity and high log file sync waits.  
The solution would be to reduce the frequency of COMMIT statements in the application.

- LGWR is paged out: & Check the server for RAM swapping, and add RAM if the instance processes are getting paged-out.

There is also the possibility that bugs can cause high log file sync waits. 
In sum, high log file sync waits can be caused either by too-high COMMIT frequency in the application, 
or by exhausted CPU, disk or RAM resources.

-- ******************************************************
-- * Copyright Notice   : (c)1999 OraPub, Inc.
-- * Filename		: rdohist.sql
-- * Author		: Craig A. Shallahamer
-- * Original		: 10-dec-99 (based upon Otto Pinter's loghist.sql report)
-- * Last Modified	: 16-fev-2018 / by me
-- * Description	: Show redo log switching details
-- * Usage		: start rdohist.sql
-- ******************************************************

def osm_prog	= 'rdohist.sql'
def osm_title	= 'Redo Log Switching History Details'

select to_date(to_char(first_time,'DD-MM-YYYY')) day,
to_char(sum(decode(to_char(first_time,'hh24'),'00',1,0)),'99') "00",
to_char(sum(decode(to_char(first_time,'hh24'),'01',1,0)),'99') "01",
to_char(sum(decode(to_char(first_time,'hh24'),'02',1,0)),'99') "02",
to_char(sum(decode(to_char(first_time,'hh24'),'03',1,0)),'99') "03",
to_char(sum(decode(to_char(first_time,'hh24'),'04',1,0)),'99') "04",
to_char(sum(decode(to_char(first_time,'hh24'),'05',1,0)),'99') "05",
to_char(sum(decode(to_char(first_time,'hh24'),'06',1,0)),'99') "06",
to_char(sum(decode(to_char(first_time,'hh24'),'07',1,0)),'99') "07",
to_char(sum(decode(to_char(first_time,'hh24'),'08',1,0)),'99') "08",
to_char(sum(decode(to_char(first_time,'hh24'),'09',1,0)),'99') "09",
to_char(sum(decode(to_char(first_time,'hh24'),'10',1,0)),'99') "10",
to_char(sum(decode(to_char(first_time,'hh24'),'11',1,0)),'99') "11",
to_char(sum(decode(to_char(first_time,'hh24'),'12',1,0)),'99') "12",
to_char(sum(decode(to_char(first_time,'hh24'),'13',1,0)),'99') "13",
to_char(sum(decode(to_char(first_time,'hh24'),'14',1,0)),'99') "14",
to_char(sum(decode(to_char(first_time,'hh24'),'15',1,0)),'99') "15",
to_char(sum(decode(to_char(first_time,'hh24'),'16',1,0)),'99') "16",
to_char(sum(decode(to_char(first_time,'hh24'),'17',1,0)),'99') "17",
to_char(sum(decode(to_char(first_time,'hh24'),'18',1,0)),'99') "18",
to_char(sum(decode(to_char(first_time,'hh24'),'19',1,0)),'99') "19",
to_char(sum(decode(to_char(first_time,'hh24'),'20',1,0)),'99') "20",
to_char(sum(decode(to_char(first_time,'hh24'),'21',1,0)),'99') "21",
to_char(sum(decode(to_char(first_time,'hh24'),'22',1,0)),'99') "22",
to_char(sum(decode(to_char(first_time,'hh24'),'23',1,0)),'99') "23"
from v$log_history
group by to_date(to_char(first_time,'DD-MM-YYYY'))
order by to_date(to_char(first_time,'DD-MM-YYYY'));







SET PAUSE ON
SET PAUSE 'Press Return to Continue'
SET PAGESIZE 60
SET LINESIZE 300
 
SELECT to_char(first_time, 'yyyy - mm - dd') aday,
           to_char(first_time, 'hh24') hour,
           count(*) total
FROM   v$log_history
WHERE  thread#=&EnterThreadId
GROUP BY to_char(first_time, 'yyyy - mm - dd'),
              to_char(first_time, 'hh24')
ORDER BY to_char(first_time, 'yyyy - mm - dd'),
              to_char(first_time, 'hh24') asc
/

ADAY           HO      TOTAL
-------------- -- ----------
2018 - 02 - 01 04          2
2018 - 02 - 01 05          2
2018 - 02 - 01 06          2
2018 - 02 - 01 07          2
2018 - 02 - 01 08          2
2018 - 02 - 01 09          2
2018 - 02 - 01 10          2
2018 - 02 - 01 11          2
2018 - 02 - 01 12          2
2018 - 02 - 01 13          2
2018 - 02 - 01 14          2
2018 - 02 - 01 15          2
2018 - 02 - 01 16          2
2018 - 02 - 01 17          2
2018 - 02 - 01 18          2
2018 - 02 - 01 19          2
2018 - 02 - 01 20          2
2018 - 02 - 01 21          2
2018 - 02 - 01 22          3
2018 - 02 - 01 23          2
2018 - 02 - 02 00          2
2018 - 02 - 02 01          2
2018 - 02 - 02 02          2
2018 - 02 - 02 03          2
2018 - 02 - 02 04          2
2018 - 02 - 02 05          2
2018 - 02 - 02 06          2
2018 - 02 - 02 07          2
2018 - 02 - 02 08          2
2018 - 02 - 02 09          2
2018 - 02 - 02 10          2
2018 - 02 - 02 11          2
2018 - 02 - 02 12          2
2018 - 02 - 02 13          2
2018 - 02 - 02 14          2
2018 - 02 - 02 15          2
2018 - 02 - 02 16          2
2018 - 02 - 02 17          2
2018 - 02 - 02 18          2
2018 - 02 - 02 19          2
2018 - 02 - 02 20          2
2018 - 02 - 02 21          2
2018 - 02 - 02 22          3
2018 - 02 - 02 23          2
2018 - 02 - 03 00          2
2018 - 02 - 03 01          2
2018 - 02 - 03 02          2
2018 - 02 - 03 03          2
2018 - 02 - 03 04          2
2018 - 02 - 03 05          2
2018 - 02 - 03 06          2
2018 - 02 - 03 07          2
2018 - 02 - 03 08          2
2018 - 02 - 03 09          2
2018 - 02 - 03 10          2
2018 - 02 - 03 11          2
2018 - 02 - 03 12          2

-- ******************************************************
-- * Copyright Notice   : (c)1999 OraPub, Inc.
-- * Filename		: rdohist.sql
-- * Author		: Craig A. Shallahamer
-- * Original		: 10-dec-99 (based upon Otto Pinter's loghist.sql report)
-- * Last Modified	: 10-dec-99
-- * Description	: Show redo log switching details
-- * Usage		: start rdohist.sql
-- ******************************************************

def osm_prog	= 'rdohist.sql'
def osm_title	= 'Redo Log Switching History Details'

select to_char(first_time,'MM-DD') day,
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
group by to_char(first_time,'MM-DD');


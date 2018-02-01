

-- ********************************************************************
-- * Copyright Notice	: (c)2015 OraPub, Inc.
-- * Filename			: as.sql - active session/sql_id script
-- * Author				: Craig A. Shallahamer
-- * Original			: 23-jul-2015
-- * Last Update		: 29-jul-2015
-- * Description		: show specific sid activity
-- * Usage				: @as.sql
-- ********************************************************************

set feedback off head on echo off

accept ENTERsid   prompt "ENTER sid    (default: %) : " default "%"
accept ENTERsqlid prompt "ENTER sql_id (default: %) : " default "%"

col inst_id		format 99		heading "Inst#"
col sid			format 999999	heading "SID"
col serial		format 999999	heading "Ser"
col statex		format a7		heading "State"
col eventx		format a40		heading "Wait Event Name" trunc
col params		format a20		heading	"Wait Event Parameters"
col p1text		format a10		heading "P1 Text" trunc
col objnum		format 9999999999		heading "Row Wait Obj #"
col bs			format 999999	heading "Blking Sess"
col ci			format a15		heading "Client ID Info" trunc
col modulex		format a20		heading "Module" trunc
col sql_idx		format a20		heading "SQL ID" trunc
col tot_cpu_s	format 99990.0 heading "Total|CPU sec"
col tot_wait_s	format 99990.0 heading "Total|Wait sec"

set verify off
set linesize 220
set heading on

select	t3.inst_id,
		t3.sid,
		t3.serial# serial,
		round(t1.tot_cpu_s,1) tot_cpu_s,
		round(t2.tot_dbtime_s-t1.tot_cpu_s,1) tot_wait_s,
		t3.statex,
		t3.eventx,
		t3.params,
		t3.p1text,
		t3.objnum,
		t3.sql_idx,
		t3.bs,
		t3.ci,
		t3.modulex
from	
	    (
			select
				inst_id, sid, serial#,
				decode(state,'WAITING',decode(wait_class,'Idle','IDLE','WAITING'),'ON CPU') statex,
				decode(state,'WAITING',decode(wait_class,'Idle','-',event),'-') eventx,
				decode(state,'WAITING',decode(wait_class,'Idle','-',p1||':'||p2||':'||p3),'-') params,
				decode(state,'WAITING',decode(wait_class,'Idle','-',p1text),'-') p1text,
				decode(state,'WAITING',decode(wait_class,'Idle',-999,ROW_WAIT_OBJ#),-999) objnum,
				decode(state,'WAITING',decode(wait_class,'Idle','-',sql_id),sql_id) sql_idx,
				decode(wait_class,'Idle',-999,blocking_session) bs,
				decode(wait_class,'Idle','-',CLIENT_IDENTIFIER) ci,
				module modulex
			from gv$session
  			where	to_char(sid) like '&ENTERsid%'	
  		) t3,  
	    (
	    	select	inst_id, sid, sum(value/1000000) tot_cpu_s
	    	from	gv$sess_time_model
  			where	to_char(sid) like '&ENTERsid%'
	    	  and	stat_name = 'DB CPU'
	    	group by inst_id, sid
	    ) t1,
	    (
	    	select	inst_id, sid, sum(value/1000000) tot_dbtime_s
	    	from	gv$sess_time_model
  			where	to_char(sid) like '&ENTERsid%'
	    	  and	stat_name = 'DB time'
	    	group by inst_id, sid
	    ) t2
where	t3.inst_id = t1.inst_id
  and	t3.inst_id = t2.inst_id
  and	t3.sid = t1.sid
  and	t3.sid = t2.sid
  and	to_char(t3.sid) like '&ENTERsid%'
  and	t3.sql_idx like '&ENTERsqlid%'
order by 1,2,3
/




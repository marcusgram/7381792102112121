 select ash.SQL_ID ,      
 sum(decode(ash.session_state,'ON CPU',1,0)) "CPU",      
 sum(decode(ash.session_state,'WAITING',1,0)) - sum(decode(ash.session_state,'WAITING', 
 decode(en.wait_class, 'User I/O',1,0),0)) "WAIT" ,      
 sum(decode(ash.session_state,'WAITING', decode(en.wait_class, 'User I/O',1,0),0))    "IO" ,      
 sum(decode(ash.session_state,'ON CPU',1,1)) "TOTAL" 
 from v$active_session_history ash,        
 v$event_name en 
 where SQL_ID is not NULL   
 and en.event#=ash.event# 
 group by sql_id 
 order by sum(decode(session_state,'ON CPU',1,1)) desc 
/


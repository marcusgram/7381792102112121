-- Identify hot blocks using AWR

--------------------------------------------------------
--First set the start and end snapshot ID as variables. 
--Use this script if you want; http://bluefrog-oracle.blogspot.com/2011/11/set-start-and-end-snapshot-id-for-awr.html

--To get a general idea of where the majority of WAITS's occur,
--run the following SQL statement to view the counts of wait classes
--in descending order;
---------------------------------------------------------

select   d.wait_class_id                as Wait_Class_ID
        ,d.wait_class                   as Wait_Class
        ,count(*)                       as Cnt
from     dba_hist_active_sess_history   d
where    d.nap_id between :p_Start_Snap_ID and :p_End_Snap_ID
group by d.wait_class_id
        ,d.wait_class
order by 3 desc;




-------------------------------------------------------------
--Next, List a breakdown of Events per Wait class identified
--in the previous result set;
-------------------------------------------------------------
select   d.wait_class_id                as Wait_Class_id
        ,d.wait_class                   as Wait_Class_Name
        ,e.Name                         as Event_Name
        ,count(*)                       as Cnt
from     dba_hist_active_sess_history   d
        ,v$Event_Name                   e
where    d.snap_id between :p_Start_Snap_ID and :p_End_Snap_ID
and      d.Event_ID                     = e.Event_ID
group by d.wait_class_id
        ,d.wait_class
        ,e.Name
order by 4 desc;





------------------------------------------------------------
--Now attempt to identify which users are responsible for the
--waits (broken down per event type).
------------------------------------------------------------

select   d.wait_class_id                as Wait_Class_ID
        ,d.wait_class                   as Wait_Class_Name
        ,u.Username                     as User_Name
        ,e.Name                         as Event_Name
        ,count(*)                       as Cnt
from     dba_hist_active_sess_history   d
        ,v$Event_Name                   e
        ,all_users                      u
where    d.snap_id between :p_Start_Snap_ID and :p_End_Snap_ID
and      d.Event_ID         = e.Event_ID
and      d.User_id          = u.User_ID
group by u.Username
        ,d.wait_class_id
        ,d.wait_class
        ,e.Name
order by 4, 5 desc;





---------------------------------------------------------------
--You may want to exclude WAITS's for SYS and focus only on the
--application specific schemas, in which case, add
--the additional predicate "u.Username != 'SYS'"

--Also, you would probably want to exclude SQL*Net related WAIT's,
--therefore add "e.Name not like 'SQL*Net%'" as a predicate.
---------------------------------------------------------------

select   d.wait_class                   as Wait_Class_Name
        ,u.Username                     as User_Name
        ,e.Name                         as Event_Name
        ,count(*)                       as Cnt
from     dba_hist_active_sess_history   d
        ,v$Event_Name                   e
        ,all_users                      u
where    d.snap_id between  :p_Start_Snap_ID and :p_End_Snap_ID
and      d.Event_ID         =     e.Event_ID
and      d.User_id          =     u.User_ID
and      u.Username         !=    'SYS'
and      e.Name not         like  'SQL*Net%'
group by u.Username
        ,d.wait_class
        ,e.Name
order by 4, 5 desc;




----------------------------------------------------------------
--To drill down on hot blocks, the WAIT class to target would be;
--"User I/O".
--Therefore add an additional predicate;
--      "d.Wait_Class       like  'User I/O'".
-----------------------------------------------------------------

select   d.wait_class                   as Wait_Class_Name
        ,u.Username                     as User_Name
        ,e.Name                         as Event_Name
        ,count(*)                       as Cnt
from     dba_hist_active_sess_history   d
        ,v$Event_Name                   e
        ,all_users                      u
where    d.snap_id between  :p_Start_Snap_ID and :p_End_Snap_ID
and      d.Event_ID         =     e.Event_ID
and      d.User_id          =     u.User_ID
and      u.Username         !=    'SYS'
and      e.Name not         like  'SQL*Net%'
and      d.Wait_Class       like  'User I/O'
group by u.Username
        ,d.wait_class
        ,e.Name
order by 1, 4 desc;




-------------------------------------------------------
--To drill down on which Objects the hot blocks occur in,
--join to the all_Objects dictionary view.

--Remove the Event Name from the grouping and select list
--since we know longer want to focus on individual reasons
--for the general "User I/O" (of which there are several).
-----------------------------------------------------------
select   d.wait_class                   as Wait_Class_Name
        ,u.Username                     as User_Name
        ,a.Object_Name                  as Object_Name
        ,count(*)                       as Cnt
from     dba_hist_active_sess_history   d
        ,all_users                      u
        ,all_objects                    a
        ,v$Event_Name                   e
where    d.snap_id between  :p_Start_Snap_ID and :p_End_Snap_ID
and      d.Event_ID         =     e.Event_ID
and      d.User_id          =     u.User_ID
and      u.Username         !=    'SYS'
and      e.Name not         like  'SQL*Net%'
and      d.Wait_Class       like  'User I/O'
and      d.Current_Obj#     =     a.Object_ID
and      a.Object_Type      =     'TABLE'
group by u.Username
        ,d.wait_class
        ,a.Object_Name
order by 4 desc,  2, 3;





-----------------------------------------------------------------
--And finally, to identify the most read ROWs relative to a Top-N
--number passed in as a parameter.
----------------------------------------------------------------
select User_Name
      ,Object_Name
      ,Hot_Row_ID
      ,Cnt
from
  (
  select   u.Username                     as User_Name
          ,a.Object_Name                  as Object_Name
          ,dbms_rowid.rowid_create(1, d.Current_Obj#
                                     ,d.Current_File#
                                     ,d.Current_Block#
                                     ,d.Current_Row#) as Hot_Row_ID
          ,count(*)                       as Cnt
  from     dba_hist_active_sess_history   d
          ,all_users                      u
          ,all_objects                    a
          ,v$Event_Name                   e
  where    d.snap_id between  :p_Start_Snap_ID and :p_End_Snap_ID
  and      d.Event_ID         =     e.Event_ID
  and      d.User_id          =     u.User_ID
  and      u.Username         !=    'SYS'
  and      e.Name not         like  'SQL*Net%'
  and      d.Wait_Class       like  'User I/O'
  and      d.Current_Obj#     =     a.Object_ID
  and      a.Object_Type      =     'TABLE'
  group by u.Username
          ,a.Object_Name
          ,dbms_rowid.rowid_create(1, d.Current_Obj#
                                     ,d.Current_File#
                                     ,d.Current_Block#
                                     ,d.Current_Row#)
  order by 4 desc,  2
  )
where rownum < &top_n;



-------------------------------------------------
--Here are a couple of examplesof Date Expression
-------------------------------------------------
Description				 Date Expression

Now					 SYSDATE
Tomorow/ next day			 SYSDATE + 1
Seven days from now			 SYSDATE + 7
One hour from now			 SYSDATE + 1/24
Three hours from now			 SYSDATE + 3/24
An half hour from now		 SYSDATE + 1/48
10 minutes from now			 SYSDATE + 10/1440
30 seconds from now			 SYSDATE + 30/86400
Tomorrow at 12 midnight		 TRUNC(SYSDATE + 1)
Tomorrow at 8 AM			 TRUNC(SYSDATE + 1) + 8/24
Yesterday at 8 AM 			 TRUNC(SYSDATE - 1) + 8/24
Next Monday at 12:00 noon		 NEXT_DAY(TRUNC(SYSDATE), 'MONDAY') + 12/24

First day of the month 
at 12 midnight			 TRUNC(LAST_DAY(SYSDATE ) + 1)

The next Monday, 
Wednesday 
or Friday at 9 a.m			 TRUNC(LEAST(NEXT_DAY(sysdate,''MONDAY' ' ),NEXT_DAY(sysdate,''WEDNESDAY''), NEXT_DAY(sysdate,''FRIDAY'' ))) + (9/24)




ALTER SESSION SET NLS_DATE_FORMAT = 'DD-MM-YYYY HH24:MI:SS';

-----------
-- LAST_DAY
-----------
SELECT SYSDATE,
       LAST_DAY(SYSDATE) "FIN DU MOIS",
       LAST_DAY(SYSDATE) - SYSDATE "JOURS RESTANT",
       LAST_DAY(SYSDATE)+1 "DEBUT MOIS SUIVANT"
  FROM dual; 


SYSDATE   FIN DU MO JOURS RESTANT DEBUT MOI
--------- --------- ------------- ---------
04-FEB-14 28-FEB-14            24 01-MAR-14



-----------------
-- MONTHS_BETWEEN
-----------------
SELECT MONTHS_BETWEEN('22-08-2011','22-12-2012') ||' Mois' "MONTHS BETWEEN"
       FROM dual;  2

MONTHS BETWEEN
--------------
-16 Mois


SELECT MONTHS_BETWEEN('28/02/2011','31/03/2011') ||' Mois' "MONTHS BETWEEN 1",
            MONTHS_BETWEEN('28/02/2011','31/01/2011') ||' Mois' "MONTHS BETWEEN 2"
       FROM dual;  2    3

MONTHS BETWEEN 1                              MONTHS BETWEEN 2
--------------------------------------------- ---------------------------------------------
-1 Mois                                       1 Mois



 
select 
  sysdate, 
  sysdate+1/24, 
  sysdate +1/1440, 
  sysdate + 1/86400 
from dual;

SYSDATE             SYSDATE+1/24        SYSDATE+1/1440      SYSDATE+1/86400
------------------- ------------------- ------------------- -------------------
04-02-2014 11:46:49 04-02-2014 12:46:49 04-02-2014 11:47:49 04-02-2014 11:46:50




--------------
-- ADD SECONDS
--------------
select 
  sysdate NOW, 
  sysdate+30/(24*60*60) NOW_PLUS_30_SECS 
from dual;

NOW                 NOW_PLUS_30_SECS
------------------- -------------------
04-02-2014 11:48:49 04-02-2014 11:49:19



select sysdate NOW, TRUNC(SYSDATE + 1) + 8/24,  TRUNC(SYSDATE + 1) +12/24 from dual;

NOW                 TRUNC(SYSDATE+1)+8/ TRUNC(SYSDATE+1)+12
------------------- ------------------- -------------------
04-02-2014 12:25:00 05-02-2014 08:00:00 05-02-2014 12:00:00





------------------------------------
-- NUIT BATCH (à lancer le matin 8h)
------------------------------------
select sysdate NOW, TRUNC(SYSDATE - 1) + 20/24,  TRUNC(SYSDATE) +8/24 from dual;

NOW                 TRUNC(SYSDATE-1)+20 TRUNC(SYSDATE)+8/24
------------------- ------------------- -------------------
04-02-2014 12:35:45 03-02-2014 20:00:00 04-02-2014 08:00:00





------------------------
-- OLTP (à lancer à 20h)
------------------------
select TRUNC(SYSDATE) +8/24 "DEBUT", TRUNC(SYSDATE) + 20/24 "FIN" from dual;

TRUNC(SYSDATE)+8/24 TRUNC(SYSDATE)+20/2
------------------- -------------------
04-02-2014 08:00:00 04-02-2014 20:00:00


----------------------
Gestion des autotasks
----------------------

Some important views used to collect information through the Autotask configuration are explained here:

# dba_autotask_task: 
=> This view shows information about task execution time, current status, priority and historical data like last and best times

# dba_autotask_window_clients:  
=> This view displays information about current windows available in the database belonging to maintenance_window_group

# dba_autotask_client_history:  
=> View used to show historical information for each job execution

# dba_autotask_operation:  
=> View used to display operation information for each client, such as attributes and status

# dba_autotask_job_history: 
=> This view provides information about job runs after each execution

# dba_autotask_client:  
=> View used to display statistical data for each task for the last seven days. 
=> It also shows an evaluation for the last 30 days.

# dba_autotask_window_history:  
=> Shows historical information for each maintenance task window


--Check dba_autotask_operation view to see what automatic tasks are scheduled:

 SELECT client_name, status FROM dba_autotask_operation;

CLIENT_NAME                                                      STATUS
---------------------------------------------------------------- --------
auto optimizer stats collection                                  ENABLED
auto space advisor                                               ENABLED
sql tuning advisor                                               ENABLED


--Get information the percent of resources used by each Autotask that is in high priority group

declare 
v_stats_group_pct number;
v_seq_group_pct number;
v_tune_group_pct number;
v_health_group_pct number;
begin
dbms_auto_task_admin.get_p1_resources(v_stats_group_pct,v_seq_group_pct,v_tu
ne_group_pct,v_health_group_pct);
dbms_output.put_line(a => 
   'Percentage of resources for Statistics Gathering: '||v_stats_group_pct||chr(10)||
   'Percentage of resources for Space Management: '||v_seq_group_pct||chr(10)||
   'Percentage of resources for SQL Tuning: '||v_tune_group_pct||chr(10)||
   'Percentage of resources for Health Checks: '||v_health_group_pct);
end;
/





--Désactiver les Jobs « Advisor » de la tache de maintenance en favorisant une utilisation ponctuelle en cas de besoin avéré (lancement manuellement).


BEGIN DBMS_AUTO_TASK_ADMIN.DISABLE(client_name => 'sql tuning advisor',operation => NULL, window_name => NULL); END; /

BEGIN DBMS_AUTO_TASK_ADMIN.DISABLE(client_name => 'auto space advisor',operation => NULL, window_name => NULL); END; /


select client_name,status from Dba_Autotask_Client;

CLIENT_NAME                         STATUS 
----------------------------------- --------------
auto optimizer stats collection     ENABLED
auto space advisor                  DISABLED
sql tuning advisor                  DISABLED


Il est conseillé de laisser la tâche de calcul des statistques 
mais de la limiter au calcul des statistiques du dictionnaire de données seulement.

Il est à noter que lors de la plage de maintenance, DBRM (Database Resource Manager) est activé pour donner la priorité aux jobs SYSTEM
et brider les ressources au reste des utilisateurs afin de prioriser le calcul des statistiques, les sauvegardes ou autres, 
cela peut impacter le temps de traitement des baches applicatifs


NB : si le choix est de positionner le calcul des statistiques à la valeur Oracle ce qui signifie que la tache de maintenance calculera les statistqiues du dictionnaire Oracle seulement, 
implique que les objets applicatifs seront gérés autrement

Dans ce cas : 

If you choose to switch off the automatic statistics gathering job for your main application schema consider leaving it on for the dictionary tables. 
You can do this by changing the value of AUTOSTATS_TARGET to ORACLE instead of AUTO using the procedure DBMS_STATS.SET_GLOBAL_PREF.

EXEC DBMS_STATS.SET_GLOBAL_PREFS(AUTOSTATS_TARGET,'ORACLE');


Pour verifier :

select dbms_stats.get_param ('AUTOSTATS_TARGET') from dual;


-----------------------------------------------------------
Pour une gestion exclusivement manuelle des stats du dico :
-----------------------------------------------------------

Scheduler Maintenance Tasks or Autotasks : La note Oracle ID 756734.

--Voir les tasks:
select client_name, status from DBA_AUTOTASK_CLIENT ;

--Passer ‘disable’ toutes les tasks :
execute DBMS_AUTO_TASK_ADMIN.DISABLE;

CLIENT_NAME                         STATUS 
----------------------------------- --------------
auto optimizer stats collection     DISABLED
auto space advisor                  DISABLED
sql tuning advisor                  DISABLED

Ref: FAQ: Automatic Statistics Collection: La note Oracle 1233203.1

--Passer disable la task de calcul de stats :
exec DBMS_AUTO_TASK_ADMIN.DISABLE(client_name => 'auto optimizer stats collection', operation => NULL, window_name => NULL);

--Arrêter la task et prendre le contrôle pour le calcul des statistiques du dictionnaire (calcul sans histogramme) :

-- interompre l'execution de la task :
exec DBMS_AUTO_TASK_ADMIN.DISABLE('auto optimizer stats collection', NULL, NULL);

-- calculer les statistiques dictionaire manuellement :
exec dbms_stats.GATHER_DICTIONARY_STATS(ownname=>'OUTLN',options=>'GATHER', estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE, method_opt => 'FOR ALL COLUMNS SIZE 1', cascade => TRUE);
exec dbms_stats.GATHER_DICTIONARY_STATS(ownname=>'DBSNMP',options=>'GATHER', estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE, method_opt => 'FOR ALL COLUMNS SIZE 1', cascade => TRUE);
exec dbms_stats.GATHER_DICTIONARY_STATS(ownname=>'SYSTEM',options=>'GATHER', estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE, method_opt => 'FOR ALL COLUMNS SIZE 1', cascade => TRUE);
exec dbms_stats.GATHER_DICTIONARY_STATS(ownname=>'SYS',OPTIONS=>'GATHER', estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE, method_opt => 'FOR ALL COLUMNS SIZE 1', cascade => TRUE);





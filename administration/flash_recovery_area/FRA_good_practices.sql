

1. Sizing de la FRA
--------------------
La FRA doit être suffisamment grande pour pouvoir contenir les éléments suivants :
 Deux sauvegardes full
 Deux journées de sauvegarde des archives log
 1h de fichiers journaux flash
 Trois journées des archives log (prendre la plus grande taille)
 Les fichiers de control
 Les fichiers de control en autobackup (avec une copie des fichiers de control et du spfile)
 25% de marge
 
 
2. Calcul du sizing de la FRA
-----------------------------
---- Estimation de la taille de fichier redo log sur une journée (prendre la plus grande taille) :

SELECT trunc(first_time) DAY,
        count(*) NB_SWITCHS,
        trunc(count(*)*log_size/1024/1024/1024) TOTAL_SIZE_GB,
        to_char(count(*)/24,'9999.9') AVG_SWITCHS_PER_HOUR
FROM v$loghist,
(select avg(bytes) log_size from v$log) GROUP BY trunc(first_time),
log_size
ORDER BY TOTAL_SIZE_GB ASC;


---- Estimation de la taille des fichiers de control :
select sum((block_size * file_size_blks)/1024/1024/1024) SIZE_IN_GB from v$controlfile;


---- Estimation de la taille des sauvegardes :
select ctime
, decode(backup_type, 'L', 'Archive Log', 'D', 'Full', 'Incremental') backup_type
, bsize
from (
select trunc(bp.completion_time) ctime
, backup_type
, round(sum(bp.bytes/1024/1024/1024),2) bsize
from v$backup_set bs, v$backup_piece bp
where bs.set_stamp = bp.set_stamp
and bs.set_count = bp.set_count
and device_type='DISK'
group by trunc(bp.completion_time), backup_type
)
order by 1 desc, 2 ;


---- Estimation de la taille du flashback :
Select max(ESTIMATED_FLASHBACK_SIZE)/1024/1024/1024 SIZE_IN_GB from v$FLASHBACK_DATABASE_STAT;


4. Support de stockage de la FRA
--------------------------------
 Le support de stockage de la FRA est soit un filesystem, soit un disque groupe.
 La taille du support de stockage doit être augmentée de 25% de la taille de la FRA (Exemple : Taille FS FRA = Taille de la FRA * 1,25)
 Pour les bases de données de grosse volumétrie (Taille de la base de données supérieure à 1To), la taille du FS doit être optimisée selon l’appréciation du DBA.

5. Paramétrage de la taille de la FRA
-------------------------------------
La taille de la FRA est définie dans la base de données via le paramètre DB_RECOVERY_FILE_DEST_SIZE.


6. Définition de la rétention des données dans la FRA
------------------------------------------------------
 La rétention doit être définie à 1 occurrence dans la FRA pour les sauvegardes et les archives log.
 La rétention doit être définie 30 jours par défaut sur TSM pour les sauvegardes et les archives log.
 
 
 

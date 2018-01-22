select count(*) as "Nombre_Objets", owner from dba_objects group by owner;

Nombre_Objets OWNER                                                             
------------- ------------------------------                                    
        23872 PUBLIC                                                            
          540 SYSTEM                                                            
            5 APPQOSSYS                                                         
          800 XDB                                                               
           16 STEPH_DEV_SCH2_ORA                                                
        31169 SYS                                                               
           13 STEPH_DEV_SCH1                                                    
           13 STEPH_REC_SCH1                                                    
            3 TSMSYS                                                            
        29497 SIEBEL                                                            
          310 EXFSYS                             

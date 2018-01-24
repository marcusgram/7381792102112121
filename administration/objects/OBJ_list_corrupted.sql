select segment_name, segment_type, owner, tablespace_name
  from dba_extents
where file_id = &fileid
  and &blocknum between block_id 
  and block_id + blocks - 1
/




create or replace
procedure show_space
( p_segname in varchar2,
  p_owner   in varchar2 default user,
  p_type    in varchar2 default 'TABLE',
  p_partition in varchar2 default NULL )
authid current_user
as
    l_free_blks                 number;

    l_total_blocks              number;
    l_total_bytes               number;
    l_unused_blocks             number;
    l_unused_bytes              number;
    l_LastUsedExtFileId         number;
    l_LastUsedExtBlockId        number;
    l_LAST_USED_BLOCK           number;

    procedure p( p_label in varchar2, p_num in number )
    is
    begin
        dbms_output.put_line( rpad(p_label,40,'.') ||
                              p_num );
    end;

begin
    for x in ( select tablespace_name
                 from dba_tablespaces
                where tablespace_name = ( select tablespace_name
                                            from dba_segments
                                           where segment_type = p_type
                                             and segment_name = p_segname
                                  and SEGMENT_SPACE_MANAGEMENT <> 'AUTO' )
             )
    loop
    dbms_space.free_blocks
    ( segment_owner     => p_owner,
      segment_name      => p_segname,
      segment_type      => p_type,
      partition_name    => p_partition,
      freelist_group_id => 0,
      free_blks         => l_free_blks );
    end loop;

    dbms_space.unused_space
    ( segment_owner     => p_owner,
      segment_name      => p_segname,
      segment_type      => p_type,
          partition_name    => p_partition,
      total_blocks      => l_total_blocks,
      total_bytes       => l_total_bytes,
      unused_blocks     => l_unused_blocks,
      unused_bytes      => l_unused_bytes,
      LAST_USED_EXTENT_FILE_ID => l_LastUsedExtFileId,
      LAST_USED_EXTENT_BLOCK_ID => l_LastUsedExtBlockId,
      LAST_USED_BLOCK => l_LAST_USED_BLOCK );

    p( 'Free Blocks', l_free_blks );
    p( 'Total Blocks', l_total_blocks );
    p( 'Total Bytes', l_total_bytes );
    p( 'Total MBytes', trunc(l_total_bytes/1024/1024) );
    p( 'Unused Blocks', l_unused_blocks );
    p( 'Unused Bytes', l_unused_bytes );
    p( 'Last Used Ext FileId', l_LastUsedExtFileId );
    p( 'Last Used Ext BlockId', l_LastUsedExtBlockId );
    p( 'Last Used Block', l_LAST_USED_BLOCK );
end;
/




EXEC SHOW_SPACE('S_PARTY','SIBIL');

Free Blocks.............................
Total Blocks............................661184
Total Bytes.............................5416419328
Total MBytes............................5165
Unused Blocks...........................0
Unused Bytes............................0
Last Used Ext FileId....................76
Last Used Ext BlockId...................671872
Last Used Block.........................3136


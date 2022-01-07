declare
  --
  l_ref_cotiza          em_k_ws_auto_inspeccion.gc_ref_cursor;
  l_reg_info_cotiza     em_k_ws_auto_inspeccion.typ_reg_info_cotizacion;
  l_msg                 varchar2(512);
  l_parametros          clob;
  --
  p_hay_error   BOOLEAN;
  p_cod_error   VARCHAR2(4000);
  p_msg_error   VARCHAR2(4000);
  p_sql_error   VARCHAR2(4000);  
  --
begin
    --
    l_parametros := '{ "access_token":"1493667939HDKOKIAI", "numeroCotizacion": "2130190001206" }';
    --
    em_k_ws_auto_inspeccion.p_informacion_cotizacion(  p_parametros => l_parametros,
                                            p_cotizacion => l_ref_cotiza,
                                            p_errores    => l_msg
                                         );
    --
    dbms_output.put_line(l_msg);
    em_k_ws_auto_inspeccion.p_devuelve_error( p_hay_error, p_cod_error, p_msg_error, p_sql_error );
    if p_hay_error then
        dbms_output.put_line(p_sql_error);
        dbms_output.put_line(p_msg_error);
    end if; 
    --
    IF l_ref_cotiza%ISOPEN then
        dbms_output.put_line( '-> Info' );
        LOOP
            FETCH l_ref_cotiza INTO l_reg_info_cotiza;
            EXIT WHEN l_ref_cotiza%NOTFOUND;
            dbms_output.put_line( l_reg_info_cotiza.numDocumento );
        END LOOP;
    END IF;
    --
end;
declare
  --
  l_ref_datos           em_k_ws_auto_inspeccion.gc_ref_cursor;
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
    dbms_output.put_line('PRUEBA DE ROTURAS');
    --
    
    l_parametros := '{'||
        '"access_token": "1493667939HDKOKIAI",'||
        '"detalles":['||
        '{"numeroCotizacion":"2130190001205",' ||
        '"pieza": "Amortiguador delantero",'||
        '"nivelDano": "leve",'||
        '"valor":"124.98",'||
        '"byteFoto":"12123131123"'||
        '},'||
        '{"numeroCotizacion":"2130190001205",' ||
        '"pieza": "Faro delatero derecho",'||
        '"nivelDano": "Grave",'||
        '"valor":"56.98",'||
        '"byteFoto":"5555"'||
        '}'||
        ']}';

    --
    em_k_ws_auto_inspeccion.p_graba_rotura_vehiculo( p_parametros   => l_parametros,
                                            p_errores    => l_msg
                                         );
    dbms_output.put_line(l_msg);
    em_k_ws_auto_inspeccion.p_devuelve_error( p_hay_error, p_cod_error, p_msg_error, p_sql_error );
    if p_hay_error then
        dbms_output.put_line(p_sql_error);
        dbms_output.put_line(p_msg_error);
    end if; 
    --
end;
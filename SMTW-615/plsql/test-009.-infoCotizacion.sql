declare
  --
  l_ref_datos           em_k_ws_auto_inspeccion.gc_ref_cursor;
  l_reg_datos           em_k_ws_auto_inspeccion.typ_reg_info_cotizacion;
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
    l_parametros := '{ "access_token":"-224819472TKSZHHUD","numeroCotizacion":"3011001976603" }';
    --
    em_k_ws_auto_inspeccion.p_informacion_cotizacion( p_parametros   => l_parametros,
                                            p_cotizacion       => l_ref_datos,
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
    IF l_ref_datos%ISOPEN then
        LOOP
            FETCH l_ref_datos INTO l_reg_datos;
            EXIT WHEN l_ref_datos%NOTFOUND;
            dbms_output.put_line( l_reg_datos.numDocumento );
            dbms_output.put_line( l_reg_datos.nombres );
            dbms_output.put_line( l_reg_datos.modelo );
            dbms_output.put_line( l_reg_datos.direccion );
            dbms_output.put_line( l_reg_datos.ciudad );
        END LOOP;
    END IF;
    --
end;
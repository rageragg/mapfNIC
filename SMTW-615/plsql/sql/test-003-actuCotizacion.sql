declare
  --
  l_ref_cotiza          em_k_ws_auto_inspeccion.gc_ref_cursor;
  l_reg_cotiza          em_k_ws_auto_inspeccion.typ_reg_cotizacion;
  l_msg                 varchar2(512);
  l_parametros          clob;
  --
begin
    --
    l_parametros := '{ "numeroCotiacion": "123456" }';
    --
    em_k_ws_auto_inspeccion.p_actualiza_cotizacion(  p_parametros => l_parametros,
                                            p_cotizacion => l_ref_cotiza,
                                            p_errores    => l_msg
                                         );
    --
    IF l_ref_cotiza%ISOPEN then
        dbms_output.put_line( '-> Info' );
        LOOP
            FETCH l_ref_cotiza INTO l_reg_cotiza;
            EXIT WHEN l_ref_cotiza%NOTFOUND;
            dbms_output.put_line( l_reg_cotiza.numeroCotizacion );
        END LOOP;
    END IF;
    --
end;
declare
  --
  l_ref_dpto           em_k_ws_auto_inspeccion.gc_ref_cursor;
  l_reg_dpto           em_k_ws_auto_inspeccion.typ_reg_lista_simple;
  l_msg                 varchar2(512);
  l_parametros          clob;
  --
begin
    --
    l_parametros := '{ "numeroCotiacion": "123456" }';
    --
    em_k_ws_auto_inspeccion.p_lista_dpto( p_parametros => l_parametros,
                                            p_departaemtno     => l_ref_dpto,
                                            p_errores    => l_msg
                                         );
    --
    IF l_ref_dpto%ISOPEN then
        dbms_output.put_line( '-> Info' );
        LOOP
            FETCH l_ref_dpto INTO l_reg_dpto;
            EXIT WHEN l_ref_dpto%NOTFOUND;
            dbms_output.put_line( l_reg_dpto.descripcion );
        END LOOP;
    END IF;
    --
end;

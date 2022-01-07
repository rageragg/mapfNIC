declare
  --
  l_ref_ctrl           em_k_ws_auto_inspeccion.gc_ref_cursor;
  l_reg_ctrl           em_k_ws_auto_inspeccion.typ_reg_ctrl_tecnico;
  l_msg                 varchar2(512);
  l_parametros          clob;
  --
begin
    --
    l_parametros := '{ "numeroCotiacion": "123456" }';
    --
    em_k_ws_auto_inspeccion.p_lista_ctrl_tecnico( p_parametros => l_parametros,
                                            p_ctrl_tec     => l_ref_ctrl,
                                            p_errores    => l_msg
                                         );
    --
    IF l_ref_ctrl%ISOPEN then
        dbms_output.put_line( '-> Info' );
        LOOP
            FETCH l_ref_ctrl INTO l_reg_ctrl;
            EXIT WHEN l_ref_ctrl%NOTFOUND;
            dbms_output.put_line( l_reg_ctrl.nombreControl );
        END LOOP;
    END IF;
    --
end;
declare
  --
  l_ref_pieza           em_k_ws_auto_inspeccion.gc_ref_cursor;
  l_reg_pieza          em_k_ws_auto_inspeccion.typ_reg_prieza;
  l_msg                 varchar2(512);
  l_parametros          clob;
  --
begin
    --
    l_parametros := '{ "numeroCotiacion": "123456" }';
    --
    em_k_ws_auto_inspeccion.p_lista_piezas( p_parametros => l_parametros,
                                            p_piezas     => l_ref_pieza,
                                            p_errores    => l_msg
                                         );
    --
    IF l_ref_pieza%ISOPEN then
        dbms_output.put_line( '-> Info' );
        LOOP
            FETCH l_ref_pieza INTO l_reg_pieza;
            EXIT WHEN l_ref_pieza%NOTFOUND;
            dbms_output.put_line( l_reg_pieza.nombrePieza );
        END LOOP;
    END IF;
    --
end;
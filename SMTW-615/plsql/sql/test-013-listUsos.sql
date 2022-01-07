declare
  --
  l_ref_pieza           em_k_ws_auto_inspeccion.gc_ref_cursor;
  l_reg_pieza           em_k_ws_auto_inspeccion.typ_reg_lista_simple;
  l_msg                 varchar2(512);
  l_parametros          clob;
  --
begin
    --
    l_parametros := '{ "access_token":"1622805804VZYPWQPZ" }';
    --
    em_k_ws_auto_inspeccion.p_lista_usos( p_parametros => l_parametros,
                                            p_usos     => l_ref_pieza,
                                            p_errores    => l_msg
                                         );
    --
    IF l_ref_pieza%ISOPEN then
        dbms_output.put_line( '-> Info' );
        LOOP
            FETCH l_ref_pieza INTO l_reg_pieza;
            EXIT WHEN l_ref_pieza%NOTFOUND;
            dbms_output.put_line( l_reg_pieza.descripcion );
        END LOOP;
    END IF;
    --
end;
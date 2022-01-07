declare
  --
  l_ref_token           em_k_ws_auto_inspeccion.gc_ref_cursor;
  l_reg_token           em_k_ws_auto_inspeccion.typ_reg_token;
  l_ref_cotiza          em_k_ws_auto_inspeccion.gc_ref_cursor;
  l_reg_cotiza          em_k_ws_auto_inspeccion.typ_reg_cliente_cotizacion;
  l_msg                 varchar2(512);
  l_parametros          clob;
  --
begin
    --
    l_parametros := '{ "username":"cso_sa07@yahoo.com", "password":"542823a4e9acbac64ec21659c5a7c415", "grant_type":"password" }';
    --
    em_k_ws_auto_inspeccion.p_login_ws( p_parametros => l_parametros,
                                        p_token      => l_ref_token 
                                      );  
    --
    commit;
    --
    IF l_ref_token%ISOPEN then
        LOOP
            FETCH l_ref_token INTO l_reg_token;
            EXIT WHEN l_ref_token%NOTFOUND;
            dbms_output.put_line('Token! '|| l_reg_token.access_token); 
        END LOOP;
    END IF;
    --
end;
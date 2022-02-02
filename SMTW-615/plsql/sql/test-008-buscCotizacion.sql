declare
  --
  l_ref_datos           em_k_ws_auto_inspeccion.gc_ref_cursor;
  l_reg_datos           em_k_ws_auto_inspeccion.typ_reg_cliente_cotizacion;
  l_msg                 varchar2(512);
  l_parametros          clob;
  --
begin
    --
    l_parametros := '{ "usuario":"mapfre.nicaragua@gmail.com",' ||
                    ' "access_token":"1346990130WINLMOII",'||
                    ' "tipUsuario":"Perito", '|| 
                    ' "identificacion": "999999",'||
                    ' "placa": "S",' ||
                    ' "numeroCotizacion": "2130100000028" }';
    --
    em_k_ws_auto_inspeccion.p_buscar_cotizacion_cliente( p_parametros   => l_parametros,
                                            p_cotizacion       => l_ref_datos,
                                            p_errores    => l_msg
                                         );
    --
    dbms_output.put_line(l_msg);
    --
    IF l_ref_datos%ISOPEN then
        dbms_output.put_line( 'Identificacion  Placa           Cotizacion Fec' );
        LOOP
            FETCH l_ref_datos INTO l_reg_datos;
            EXIT WHEN l_ref_datos%NOTFOUND;
            dbms_output.put_line( l_reg_datos.identificacion ||' '|| 
                                  l_reg_datos.placa ||' '|| 
                                  l_reg_datos.numeroCotizacion ||' ' || 
                                  l_reg_datos.fechaEfectoPoliza );
        END LOOP;
    END IF;
    --
end;
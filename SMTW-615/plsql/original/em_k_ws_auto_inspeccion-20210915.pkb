create or replace package body em_k_ws_auto_inspeccion AS
    /* -------------------------------------------------------------------
    || Procedimientos y funciones para Web Services Cotizador VIDA
    */
    /* -------------------- VERSION = 1.00 -------------------------------
    || CARRIERHOUSE - 18/08/2021
    || CONSTRUCCION
    /* -------------------- MODIFICACIONES -------------------------------
    ||
    */
    --
    -- constantes
    g_cod_cia CONSTANT x2000000_web.val_campo%TYPE := 4;
    --
    -- globales internas
    g_access_token              VARCHAR2(128);
    g_usuario                   VARCHAR2(128);
    g_expires_in                NUMBER;
    g_password                  VARCHAR2(128);
    g_tip_usuario               VARCHAR2(128);
    g_usuario_nombre            portal_web.t_usuario.usuario_nombre%TYPE;
    g_bloqueado                 portal_web.t_usuario.bloqueado%TYPE;
    g_numero_cotiacion          VARCHAR2(128);
    g_nom_archivo               VARCHAR2(100) := 'ws_auto_inspeccion';
    g_session_id                VARCHAR2(128);
    g_process_id                VARCHAR2(32);
    g_cod_modulo                g2000906_web.cod_modulo%TYPE := 'WS_AUTO_INSPECCION';
    g_cod_usr                   CONSTANT x2000001_web.cod_usr%TYPE := 'USER_WEB';
    g_cod_agt                   VARCHAR2(20);
    --
    -- errores
    g_hay_error                 BOOLEAN;
    g_cod_error                 VARCHAR2(3);
    g_msg_error                 VARCHAR2(4000);
    -- 
    -- registros de entradas
    g_typ_reg_b_cot_001         typ_reg_b_cot_001           := NULL;    -- parametro buscar Cotizacion
    g_typ_reg_i_cot_001         typ_reg_i_cot_001           := NULL;    -- parametro informacion Cotizacion
    g_typ_reg_a_cot_001         typ_reg_a_cot_001           := NULL;    -- parametro actualizar Cotizacion
    g_typ_reg_a_fot_001         typ_reg_a_fot_001           := NULL;    -- parametro actualizar fotos
    -- registros de salidas
    g_reg_cliente_cotizacion    typ_reg_cliente_cotizacion  := NULL;
    g_reg_info_cotizacion       typ_reg_info_cotizacion     := NULL;
    g_reg_cotizacion            typ_reg_cotizacion          := NULL;
    g_reg_prieza                typ_reg_prieza              := NULL;
    g_reg_ctrl_tecnico          typ_reg_ctrl_tecnico        := NULL;
    g_reg_lista_simple          typ_reg_lista_simple        := NULL;
    -- tablas de salidas
    g_tab_busqueda_cotizacion   typ_tab_cliente_cotizacion  := typ_tab_cliente_cotizacion();
    g_tab_info_cotizacion       typ_tab_info_cotizacion     := typ_tab_info_cotizacion();
    g_tab_reg_cotizacion        typ_tab_reg_cotizacion      := typ_tab_reg_cotizacion();
    g_tab_reg_pieza             typ_tab_reg_pieza           := typ_tab_reg_pieza();
    g_tab_reg_ctrl_tecnico      typ_tab_reg_ctrl_tecnico    := typ_tab_reg_ctrl_tecnico();
    g_tab_lista_dpto            typ_tab_reg_simple          := typ_tab_reg_simple();
    g_tab_lista_mpio            typ_tab_reg_simple          := typ_tab_reg_simple();
    g_tab_lista_marca           typ_tab_reg_simple          := typ_tab_reg_simple();
    g_tab_lista_lineas          typ_tab_reg_simple          := typ_tab_reg_simple();
    g_tab_lista_usos            typ_tab_reg_simple          := typ_tab_reg_simple();
    g_tab_lista_colores         typ_tab_reg_simple          := typ_tab_reg_simple();
    --
    -- Utilidades
    --
    -- actualiza tabla de log de requerimientos x2000008_web_mni
    PROCEDURE  p_actualiza_x2000008_web_mni(  p_cod_cia       IN x2000008_web_mni.cod_cia%TYPE,
                                              p_mca_valido    IN VARCHAR2,
                                              p_txt_resultado IN VARCHAR2,
                                              p_resultado     OUT BOOLEAN,    
                                              p_respuesta     OUT VARCHAR2 
                                        )  IS
    BEGIN 
        --
        UPDATE X2000008_WEB_MNI 
           SET mca_valido    = p_mca_valido,
               txt_resultado = p_txt_resultado, 
               session_id    = nvl( g_session_id, session_id )
         WHERE process_id = g_process_id;        
        --
        p_resultado := TRUE;   
        p_respuesta := '';                               
        --
        EXCEPTION 
            WHEN OTHERS THEN 
                p_resultado := FALSE;   
                p_respuesta := SQLERRM;  
                --
                g_hay_error    := TRUE;
                g_cod_error    := '500';
                g_msg_error    := 'No es posible actualiza a X2000008_WEB_MNI';
        --
    END p_actualiza_x2000008_web_mni;
    --
    -- verificacion de token
    FUNCTION f_verificar_token( p_dato_json     CLOB,
                                p_respuesta     OUT VARCHAR2  
                              ) RETURN BOOLEAN IS 
        --
        l_expire        NUMBER  := nvl( g_expires_in, 24*60*60 );
        l_segundos_dia  NUMBER  := 24*60*60;  
        l_ok            BOOLEAN := FALSE;
        l_estado        VARCHAR2(20);
        l_access_token  VARCHAR2(128); 
        l_session_id    VARCHAR2(128);       
        --
        CURSOR c_token IS 
            SELECT sessionid,
                   CASE 
                       WHEN CAST( login + round(l_expire/l_segundos_dia ) AS timestamp ) > sysdate 
                           THEN 'VIGENTE'
                           ELSE 'VENCIDO'
                   END estado       
              FROM portal_web.t_usuario_ws 
             WHERE sessionid = l_access_token 
               AND logout IS NULL;
        --
        -- dato de solicitud de 
        CURSOR c_datos IS 
            SELECT json_value( p_dato_json, '$.access_token' ) 
              FROM dual;
        --
    BEGIN
        --
        -- verificamos el valor del parametro
        OPEN c_datos;
        FETCH c_datos INTO l_access_token;
        l_ok := c_datos%FOUND;
        CLOSE c_datos;
        --
        IF l_ok THEN
            --
            -- verificamos el token
            OPEN c_token;
            FETCH c_token INTO l_session_id, l_estado;
            l_ok := c_token%FOUND;
            CLOSE c_token;
            --
            IF l_ok THEN
                IF l_estado = 'VENCIDO' THEN 
                p_respuesta    := 'Token no es valido!, (VENCIDO)'; 
                l_ok := FALSE;
                ELSE
                    g_session_id := l_session_id;
                    p_respuesta := '';
                    l_ok := TRUE;
                END IF;  
            ELSE
                p_respuesta    := 'Token no es valido!, (NO REGISTRADO)';
                l_ok := FALSE;
            END IF;
        ELSE
            p_respuesta    := 'Token no es valido!, (NO ESTA PRESENTE EN LOS PARAMETROS)';
            l_ok := FALSE;
        END IF;    
        --
        RETURN l_ok;
        --
        EXCEPTION 
            WHEN OTHERS THEN 
                --
                p_respuesta    := 'No es posible validar la estructura token!';
                g_hay_error    := TRUE;
                g_cod_error    := '500';
                g_msg_error    := p_respuesta;
                --
                dbms_output.put_line(sqlerrm);
                RETURN FALSE;
        --        
    END f_verificar_token;
    --
    -- inserta en tabla de tratamiento JSON
    PROCEDURE  p_inserta_x2000008_web_mni(  p_cod_cia       IN x2000008_web_mni.cod_cia%TYPE,
                                            p_session_id    IN x2000008_web_mni.session_id%TYPE,
                                            p_url           IN x2000008_web_mni.url%TYPE,
                                            p_tip_json      IN x2000008_web_mni.tip_json%TYPE,
                                            p_dato_json     IN CLOB,
                                            p_resultado     OUT BOOLEAN,    
                                            p_respuesta     OUT VARCHAR2 
                                        )  IS
    BEGIN 
        --
        g_process_id := sys_guid();
        --
        INSERT INTO X2000008_WEB_MNI(   cod_cia,
                                        process_id,
                                        session_id,
                                        fec_transaccion,
                                        url,
                                        tip_json,
                                        dato_json,
                                        mca_valido,
                                        txt_resultado   
                                    )
                             VALUES(    p_cod_cia,
                                        g_process_id,
                                        p_session_id,
                                        trunc(sysdate),
                                        p_url,
                                        p_tip_json,
                                        p_dato_json,
                                        'N',
                                        'Sin Procesar'
                                    );  
        --
        p_resultado := TRUE;   
        p_respuesta := '';                               
        --
        EXCEPTION 
            WHEN OTHERS THEN 
                p_resultado := FALSE;   
                p_respuesta := SQLERRM;  
                --
                g_hay_error    := TRUE;
                g_cod_error    := '400';
                g_msg_error    := 'No es posible validar la estructura JSON';
        --
    END p_inserta_x2000008_web_mni;
    --
    -- procesamos el tipo de JSON 'I-COT-001'
    PROCEDURE p_b_cot_001( p_resultado OUT BOOLEAN, p_respuesta OUT VARCHAR2 ) IS
        --
        l_ok            BOOLEAN := FALSE;
        l_respuesta     VARCHAR2(4000);
        --
        -- dato de solicitud de 
        CURSOR c_datos IS 
            SELECT doc.dato_json.access_token,
                   doc.dato_json.usuario,
                   doc.dato_json.tipUsuario,
                   doc.dato_json.identificacion,
                   doc.dato_json.placa,
                   doc.dato_json.numeroCotizacion
              FROM x2000008_web_mni doc 
             WHERE doc.process_id = g_process_id;
        --     
    BEGIN 
        --
        OPEN c_datos;
        FETCH c_datos INTO  g_typ_reg_b_cot_001.access_token,
                            g_typ_reg_b_cot_001.usuario,
                            g_typ_reg_b_cot_001.tipusuario,
                            g_typ_reg_b_cot_001.identificacion,
                            g_typ_reg_b_cot_001.placa,
                            g_typ_reg_b_cot_001.numeroCotizacion;
        l_ok :=  c_datos%FOUND;
        CLOSE c_datos;    
        --
        p_resultado := l_ok;
        IF NOT l_ok THEN 
            p_respuesta := 'NO HAY DATOS QUE PROCESAR!';
        ELSE    
            --
            -- validamos que los datos tengan valores
            l_ok := g_typ_reg_b_cot_001.access_token IS NOT NULL;
            --
            l_ok :=  ( g_typ_reg_b_cot_001.identificacion IS NOT NULL OR g_typ_reg_b_cot_001.placa IS NOT NULL ) AND l_ok;
            --
            p_resultado := l_ok; 
            --
            IF l_ok THEN
                p_respuesta := NULL;
            ELSE
                p_respuesta := 'Datos Incompletos o nulos en JSON';    
            END IF;
            --
        END IF;                              
        --
        EXCEPTION 
            WHEN OTHERS THEN 
                p_resultado := FALSE;   
                p_respuesta := SQLERRM;  
                --
                g_hay_error    := TRUE;
                g_cod_error    := '500';
                g_msg_error    := 'No es posible Obtener los datos del tipo de JSON (' || 
                                  em_k_ws_auto_inspeccion.K_TIP_BUSCAR_COTIZACION ||')';
        --
    END p_b_cot_001;
    --
    -- procesamos el tipo de JSON 'B-COT-001'
    PROCEDURE p_i_cot_001( p_resultado OUT BOOLEAN, p_respuesta OUT VARCHAR2 ) IS
        --
        l_ok            BOOLEAN := FALSE;
        l_respuesta     VARCHAR2(4000);
        --
        -- dato de solicitud de 
        CURSOR c_datos IS 
            SELECT doc.dato_json.access_token,
                   doc.dato_json.numeroCotizacion
              FROM x2000008_web_mni doc 
             WHERE doc.process_id = g_process_id;
        --     
    BEGIN 
        --
        OPEN c_datos;
        FETCH c_datos INTO  g_typ_reg_i_cot_001.access_token,
                            g_typ_reg_i_cot_001.numeroCotizacion;
        l_ok :=  c_datos%FOUND;
        CLOSE c_datos;    
        --
        p_resultado := l_ok;
        IF NOT l_ok THEN 
            p_respuesta := 'NO HAY DATOS QUE PROCESAR!';
        ELSE    
            --
            -- validamos que los datos tengan valores
            l_ok := g_typ_reg_i_cot_001.access_token IS NOT NULL;
            l_ok := g_typ_reg_i_cot_001.numeroCotizacion IS NOT NULL AND l_ok;
            p_resultado := l_ok;
            --
            IF l_ok THEN
                p_respuesta := NULL;
            ELSE
                p_respuesta := 'Datos Incompletos o nulos en JSON';   
            END IF;
            --
        END IF;                              
        --
        EXCEPTION 
            WHEN OTHERS THEN 
                p_resultado := FALSE;   
                p_respuesta := SQLERRM;  
                --
                g_hay_error    := TRUE;
                g_cod_error    := '500';
                g_msg_error    := 'No es posible Obtener los datos del tipo de JSON (' || 
                                  em_k_ws_auto_inspeccion.K_TIP_LEER_COTIZACION ||')';
        --
    END p_i_cot_001;   
    --
    -- procesamos el tipo de JSON 'A-COT-001'
    PROCEDURE p_a_cot_001( p_resultado OUT BOOLEAN, p_respuesta OUT VARCHAR2 ) IS
        --
        l_ok            BOOLEAN := FALSE;
        l_respuesta     VARCHAR2(4000);
        --
        -- dato de solicitud de 
        CURSOR c_datos IS 
            SELECT doc.dato_json.access_token,
                   doc.dato_json.numeroCotizacion,
                   doc.dato_json.placa,
                   doc.dato_json.marca,
                   doc.dato_json.linea,
                   doc.dato_json.version,
                   doc.dato_json.modelo,
                   doc.dato_json.codFase,
                   doc.dato_json.motor,
                   doc.dato_json.chasis,
                   doc.dato_json.serie, 
                   doc.dato_json.uso,
                   doc.dato_json.color
              FROM x2000008_web_mni doc 
             WHERE doc.process_id = g_process_id;
        --
    BEGIN 
        --
        OPEN c_datos;
        FETCH c_datos INTO  g_typ_reg_a_cot_001.access_token,
                            g_typ_reg_a_cot_001.numeroCotizacion,
                            g_typ_reg_a_cot_001.placa,
                            g_typ_reg_a_cot_001.marca,
                            g_typ_reg_a_cot_001.linea,
                            g_typ_reg_a_cot_001.version,
                            g_typ_reg_a_cot_001.modelo,
                            g_typ_reg_a_cot_001.codFase,
                            g_typ_reg_a_cot_001.motor,
                            g_typ_reg_a_cot_001.chasis,
                            g_typ_reg_a_cot_001.serie, 
                            g_typ_reg_a_cot_001.uso,
                            g_typ_reg_a_cot_001.color;
        l_ok :=  c_datos%FOUND;
        CLOSE c_datos;    
        --
        p_resultado := l_ok;
        IF NOT l_ok THEN 
            p_respuesta := 'NO HAY DATOS QUE PROCESAR!';
        ELSE    
            --
            -- validamos que los datos tengan valores
            l_ok := g_typ_reg_a_cot_001.access_token IS NOT NULL;
            l_ok := g_typ_reg_a_cot_001.placa IS NOT NULL AND l_ok;
            p_resultado := l_ok;
            --
            IF l_ok THEN
                p_respuesta := NULL;
            ELSE
                p_respuesta := 'Datos Incompletos o nulos en JSON';   
            END IF;
            --
        END IF;                              
        --
        EXCEPTION 
            WHEN OTHERS THEN 
                p_resultado := FALSE;   
                p_respuesta := SQLERRM;  
                --
                g_hay_error    := TRUE;
                g_cod_error    := '500';
                g_msg_error    := 'No es posible Obtener los datos del tipo de JSON (' || 
                                  em_k_ws_auto_inspeccion.K_TIP_ACTUALIZAR_COTIZACION ||')';
        --
    END p_a_cot_001; 
    --
    -- procesamos el tipo de JSON 'A-FOT-001'
    PROCEDURE p_a_fot_001( p_resultado OUT BOOLEAN, p_respuesta OUT VARCHAR2 ) IS
        --
        l_ok            BOOLEAN := FALSE;
        l_respuesta     VARCHAR2(4000);
        --
        -- dato de solicitud de 
        CURSOR c_datos IS 
            select fot.num_cotizacion, fot.tip_foto, fot.byte_foto, doc.dato_json.access_token
              from x2000008_web_mni doc,
                   json_table( dato_json, 
                    '$.fotos[*]'
                    COLUMNS( num_cotizacion VARCHAR2(128) PATH '$.numeroCotizacion',
                                tip_foto    VARCHAR2(128) PATH '$.tipoFoto',
                                byte_foto   CLOB          PATH '$.byteFoto'
                           ) ) as fot
            where doc.process_id = g_process_id
              and doc.tip_json   = em_k_ws_auto_inspeccion.K_TIP_ACTUALIZAR_FOTOS;
        --
    BEGIN 
        --
        g_typ_reg_a_fot_001 := NULL;
        FOR v IN c_datos LOOP 
            --
            g_typ_reg_a_fot_001.numeroCotizacion    := v.num_cotizacion;
            g_typ_reg_a_fot_001.tipoFoto            := v.tip_foto;
            g_typ_reg_a_fot_001.byteFoto            := v.byte_foto;
            g_typ_reg_a_fot_001.access_token        := v.access_token;
            l_ok := TRUE;
            --
        END LOOP;    
        --
        p_resultado := l_ok;
        IF NOT l_ok THEN 
            p_respuesta := 'NO HAY DATOS QUE PROCESAR!';
        END IF;                              
        --
        EXCEPTION 
            WHEN OTHERS THEN 
                p_resultado := FALSE;   
                p_respuesta := SQLERRM;  
                --
                g_hay_error    := TRUE;
                g_cod_error    := '500';
                g_msg_error    := 'No es posible Obtener los datos del tipo de JSON (' || 
                                  em_k_ws_auto_inspeccion.K_TIP_ACTUALIZAR_FOTOS ||')';
        --
    END p_a_fot_001;       
    --
    -- procesa el JSON
    PROCEDURE p_procesa_json( p_resultado OUT BOOLEAN, p_respuesta OUT VARCHAR2 ) IS 
        --
        l_session_id    x2000008_web_mni.session_id%TYPE;
        l_tip_json      x2000008_web_mni.tip_json%TYPE;
        l_dato_json      x2000008_web_mni.dato_json%TYPE;
        l_ok            BOOLEAN := FALSE;
        l_respuesta     VARCHAR2(4000);
        --
        -- datos almacenados
        CURSOR c_datos IS 
            SELECT session_id, tip_json, dato_json
              FROM x2000008_web_mni
             WHERE process_id = g_process_id; 
        --
    BEGIN 
        --
        -- recuperamos los datos
        OPEN c_datos;
        FETCH c_datos INTO l_session_id, l_tip_json, l_dato_json;
        l_ok := c_datos%FOUND;
        CLOSE c_datos;                    
        --
        -- comparamos los tipos de datos
        IF l_ok THEN
            --
            -- se valida el token
            l_ok := f_verificar_token( p_dato_json => l_dato_json,
                                       p_respuesta => l_respuesta  
                                     );
            --
            IF l_ok THEN
                IF l_tip_json = em_k_ws_auto_inspeccion.K_TIP_BUSCAR_COTIZACION THEN
                    --
                    -- buscar cotizacion
                    p_b_cot_001( l_ok, l_respuesta );
                    p_resultado := l_ok;
                    --
                    IF NOT l_ok THEN 
                        p_respuesta := l_respuesta;
                    ELSE
                        p_respuesta := NULL; 
                    END IF;
                    --
                ELSIF l_tip_json = em_k_ws_auto_inspeccion.K_TIP_LEER_COTIZACION THEN    
                    --
                    -- informacion cotizacion
                    p_i_cot_001( l_ok, l_respuesta );
                    p_resultado := l_ok;
                    --
                    IF NOT l_ok THEN 
                        p_respuesta := l_respuesta;
                    ELSE
                        p_respuesta := NULL; 
                    END IF;
                    --
                ELSIF  l_tip_json = em_k_ws_auto_inspeccion.K_TIP_ACTUALIZAR_COTIZACION THEN        
                    --
                    -- actualiza cotizacion
                    p_a_cot_001( l_ok, l_respuesta );
                    p_resultado := l_ok;
                    --
                    IF NOT l_ok THEN 
                        p_respuesta := l_respuesta;
                    ELSE
                        p_respuesta := NULL; 
                    END IF;
                    --
                ELSIF  l_tip_json = em_k_ws_auto_inspeccion.K_TIP_ACTUALIZAR_FOTOS THEN   
                    --
                    -- procesamos los datos de la fotografias
                    p_a_fot_001( l_ok, l_respuesta );
                    p_resultado := l_ok; 
                    IF NOT l_ok THEN 
                        p_respuesta := l_respuesta;
                    ELSE
                        p_respuesta := NULL; 
                    END IF; 
                END IF;
            END IF;    
            --
        ELSE
            --
            l_respuesta := 'NO HAY DATOS JSON QUE PROCESAR!';
            --
        END IF;
        --
        p_resultado := l_ok;
        p_respuesta := l_respuesta;
        --
        EXCEPTION
            WHEN OTHERS THEN 
                p_resultado := FALSE;
                p_respuesta := SQLERRM;  
                --
                g_hay_error    := TRUE;
                g_cod_error    := '500';
                g_msg_error    := 'Error al procesar el JSON';
        --  
    END p_procesa_json;
    --
    -- procesar JSON
    FUNCTION f_valida_json( p_cod_cia       IN x2000008_web_mni.cod_cia%TYPE,
                            p_session_id    IN x2000008_web_mni.session_id%TYPE,
                            p_url           IN x2000008_web_mni.url%TYPE,
                            p_tip_json      IN x2000008_web_mni.tip_json%TYPE,
                            p_dato_json     IN CLOB,   
                            p_respuesta     OUT VARCHAR2  
                          ) RETURN BOOLEAN IS 
        --
        l_ok            BOOLEAN := FALSE;
        l_respuesta     VARCHAR2(4000);
        --
    BEGIN 

        dbms_output.put_line(p_dato_json);  
        --
        IF p_dato_json IS NOT NULL THEN
            --
            -- se inserta los datos en la tabla de tratamiento JSON
            p_inserta_x2000008_web_mni( p_cod_cia       => p_cod_cia,
                                        p_session_id    => p_session_id,
                                        p_url           => p_url,
                                        p_tip_json      => p_tip_json,
                                        p_dato_json     => p_dato_json,
                                        p_resultado     => l_ok,    
                                        p_respuesta     => l_respuesta
                                    );
            --
            IF NOT l_ok THEN
                p_respuesta  := l_respuesta;
            END IF;                      
            RETURN l_ok;   
            --                         
        ELSE
            p_respuesta := 'Datos de la solicitud vacio!';
            RETURN FALSE;
        END IF;
        --    
        RETURN TRUE;
        --
        EXCEPTION
            WHEN OTHERS THEN 
                g_hay_error    := TRUE;
                g_cod_error    := '500';
                g_msg_error    := 'Imposible validar los datos JSON';
                RETURN FALSE;
        --        
    END f_valida_json;
    --
    -- agregar busqueda cotizacion cliente
    PROCEDURE p_agrega_busqueda_cotizacion( p_reg_cliente_cotizacion typ_reg_cliente_cotizacion ) IS 
    BEGIN 
        --
        g_tab_busqueda_cotizacion.extend;
        g_tab_busqueda_cotizacion( g_tab_busqueda_cotizacion.count) := p_reg_cliente_cotizacion;
        --
    END p_agrega_busqueda_cotizacion;
    --
    -- selecciona el resultado de la busqueda
    PROCEDURE p_seleccion_cotizacion IS 
        --
        l_registro NUMBER(1) := 2;
        --
    BEGIN 
        --
        g_reg_cliente_cotizacion.access_token        := g_access_token;
	    g_reg_cliente_cotizacion.usuario             := g_usuario;
	    g_reg_cliente_cotizacion.tip_usuario         := g_tip_usuario;
	    g_reg_cliente_cotizacion.identificacion      := NULL;
        --
        LOOP
	        SELECT (1+ABS(MOD(dbms_random.random,999999))) INTO g_reg_cliente_cotizacion.placa FROM dual;
            SELECT (1+ABS(MOD(dbms_random.random,1000000))) INTO g_reg_cliente_cotizacion.numeroCotizacion FROM dual;
            SELECT (1+ABS(MOD(dbms_random.random,1000000))) INTO g_reg_cliente_cotizacion.poliza FROM dual;
            l_registro := l_registro - 1;
            p_agrega_busqueda_cotizacion(g_reg_cliente_cotizacion); 
            EXIT WHEN l_registro <= 0;
        END LOOP;    
        --
        --
    END p_seleccion_cotizacion;
    --
    -- agregar informacion cotizacion cliente
    PROCEDURE p_agrega_info_cotizacion( p_reg_info_cotizacion typ_reg_info_cotizacion ) IS 
    BEGIN 
        --
        g_tab_info_cotizacion.extend;
        g_tab_info_cotizacion( g_tab_info_cotizacion.count) := p_reg_info_cotizacion;
        --
    END p_agrega_info_cotizacion;
    --
    -- selecciona el resultado de la busqueda de la informacion
    PROCEDURE p_seleccion_info_cotizacion IS 
    BEGIN 
        --
        g_reg_info_cotizacion.tipoDocumento   := 'IdentificaciÃ?Â³n';
        g_reg_info_cotizacion.numDocumento    := '123456';
        g_reg_info_cotizacion.nombres         := 'Alejandra';
        g_reg_info_cotizacion.apellidoPaterno := 'Pietrini';
        g_reg_info_cotizacion.apellidoMaterno := 'Apeliido';
        g_reg_info_cotizacion.telefono        := '236-5555';
        g_reg_info_cotizacion.email           := 'info@mapfre.com.pa';
        g_reg_info_cotizacion.ciudad          := 'PanamÃ?Â¡';
        g_reg_info_cotizacion.direccion       := 'Ave de los Poetas.';
        g_reg_info_cotizacion.placa           := '654321';
        g_reg_info_cotizacion.marca           := 'Nissan';
        g_reg_info_cotizacion.linea           := '';
        g_reg_info_cotizacion.version         := '';
        g_reg_info_cotizacion.modelo          := '';
        g_reg_info_cotizacion.codFase         := '';
        g_reg_info_cotizacion.motor           := '';
        g_reg_info_cotizacion.chasis          := '1452';
        g_reg_info_cotizacion.serie           := '';
        g_reg_info_cotizacion.uso             := 'Particular';
        g_reg_info_cotizacion.color           := 'NEGRO';
        --
        p_agrega_info_cotizacion(g_reg_info_cotizacion);
        --
    END p_seleccion_info_cotizacion;
    --
    -- agregar informacion cotizacion cliente
    PROCEDURE p_agrega_reg_cotizacion( p_reg_cotizacion typ_reg_cotizacion ) IS 
    BEGIN 
        --
        g_tab_reg_cotizacion.extend;
        g_tab_reg_cotizacion( g_tab_reg_cotizacion.count) := p_reg_cotizacion;
        --
    END p_agrega_reg_cotizacion;
    --
    -- proceso para actualizar la BD del registro de cotizacion
    PROCEDURE p_actualiza_reg_cotizacion IS 
    BEGIN 
        --
        g_reg_cotizacion.numeroCotizacion   := '654321';
        g_reg_cotizacion.placa              := '654321';
        g_reg_cotizacion.marca              := 'FORD';
        g_reg_cotizacion.linea              := 'PICKUP';
        g_reg_cotizacion.version            := 'VERSION';
        g_reg_cotizacion.modelo             := 'MODELO';
        g_reg_cotizacion.codFase            := 'codFase';
        g_reg_cotizacion.motor              := 'motor';
        g_reg_cotizacion.chasis             := 'chasis';
        g_reg_cotizacion.serie              := 'serie';
        g_reg_cotizacion.uso                := 'uso';       
        g_reg_cotizacion.color              := 'color';
        --
        p_agrega_reg_cotizacion( g_reg_cotizacion );
        --
    END p_actualiza_reg_cotizacion;
    --
    -- agregar pieza a la lista
    PROCEDURE p_agrega_reg_pieza( p_reg_prieza typ_reg_prieza ) IS 
    BEGIN 
        --
        g_tab_reg_pieza.extend;
        g_tab_reg_pieza( g_tab_reg_pieza.count) := p_reg_prieza;
        --
    END p_agrega_reg_pieza;
    --
    -- selecciona el resultado de la busqueda de las pienzas
    PROCEDURE p_selecciona_piezas_vehiculo IS 
    BEGIN 
        --
        g_reg_prieza.nombrePieza := 'AMORTIGUADOR TRACERO';
        p_agrega_reg_pieza( g_reg_prieza );
        g_reg_prieza.nombrePieza := 'AMORTIGUADOR DELANTERO';
        p_agrega_reg_pieza( g_reg_prieza );
        g_reg_prieza.nombrePieza := 'PARABRISA FORD';
        p_agrega_reg_pieza( g_reg_prieza );
        --
    END p_selecciona_piezas_vehiculo;
    --
    -- agregar control tecnico a la lista
    PROCEDURE p_agrega_reg_ctrl_tecnico( p_reg_ctrl typ_reg_ctrl_tecnico ) IS 
    BEGIN 
        --
        g_tab_reg_ctrl_tecnico.extend;
        g_tab_reg_ctrl_tecnico( g_tab_reg_ctrl_tecnico.count) := p_reg_ctrl;
        --
    END p_agrega_reg_ctrl_tecnico;
    --
    -- selecciona el resultado de la busqueda de las control tecnico
    PROCEDURE p_selecciona_ctrl_tecnico IS 
    BEGIN 
        --
        g_reg_ctrl_tecnico.nombreControl := 'CONTROL TECNICO 1';
        p_agrega_reg_ctrl_tecnico( g_reg_ctrl_tecnico );
        g_reg_ctrl_tecnico.nombreControl := 'CONTROL TECNICO 2';
        p_agrega_reg_ctrl_tecnico( g_reg_ctrl_tecnico );
        g_reg_ctrl_tecnico.nombreControl := 'CONTROL TECNICO 3';
        p_agrega_reg_ctrl_tecnico( g_reg_ctrl_tecnico );
        --
    END p_selecciona_ctrl_tecnico;    
    --
    -- agregar reg simple
    PROCEDURE p_agrega_reg_simple( p_reg_simple typ_reg_lista_simple, p_tab_lsta_simple IN OUT typ_tab_reg_simple ) IS 
    BEGIN 
        --
        p_tab_lsta_simple.extend;
        p_tab_lsta_simple( p_tab_lsta_simple.count) := p_reg_simple;
        --
    END p_agrega_reg_simple;   
    --
    -- selecciona el resultado de la busqueda de las departamento
    PROCEDURE p_selecciona_lst_dpto IS 
    BEGIN 
        --
        g_reg_lista_simple              := NULL;
        g_reg_lista_simple.codigo         := '1';
        g_reg_lista_simple.descripcion    := 'DEPARTAMENTO #1';
        p_agrega_reg_simple( g_reg_lista_simple, g_tab_lista_dpto );
        g_reg_lista_simple.codigo         := '2';
        g_reg_lista_simple.descripcion    := 'DEPARTAMENTO #2';
        p_agrega_reg_simple( g_reg_lista_simple, g_tab_lista_dpto );
        --
    END p_selecciona_lst_dpto;   
    --
    -- selecciona el resultado de la busqueda de las municipio
    PROCEDURE p_selecciona_lst_mpio IS 
    BEGIN 
        --
         g_reg_lista_simple             := NULL;
        g_reg_lista_simple.codigo         := '1';
        g_reg_lista_simple.descripcion    := 'MUNICIPIO #1';
        p_agrega_reg_simple( g_reg_lista_simple, g_tab_lista_mpio );
        g_reg_lista_simple.codigo         := '2';
        g_reg_lista_simple.descripcion    := 'MUNICIPIO #2';
        p_agrega_reg_simple( g_reg_lista_simple, g_tab_lista_mpio );
        --
    END p_selecciona_lst_mpio;    
    --
    -- selecciona el resultado de la busqueda de las marcas
    PROCEDURE p_selecciona_lst_marca IS 
    BEGIN 
        --
        g_reg_lista_simple                := NULL;
        g_reg_lista_simple.codigo         := '1';
        g_reg_lista_simple.descripcion    := 'MARCA #1';
        p_agrega_reg_simple( g_reg_lista_simple, g_tab_lista_marca );
        g_reg_lista_simple.codigo         := '2';
        g_reg_lista_simple.descripcion    := 'MARCA #2';
        p_agrega_reg_simple( g_reg_lista_simple, g_tab_lista_marca );
        --
    END p_selecciona_lst_marca;      
    --
    -- selecciona el resultado de la busqueda de las lineas
    PROCEDURE p_selecciona_lst_lineas IS 
    BEGIN 
        --
        g_reg_lista_simple                := NULL;
        g_reg_lista_simple.codigo         := '1';
        g_reg_lista_simple.descripcion    := 'LINEA #1';
        p_agrega_reg_simple( g_reg_lista_simple, g_tab_lista_lineas );
        g_reg_lista_simple.codigo         := '2';
        g_reg_lista_simple.descripcion    := 'LINEA #2';
        p_agrega_reg_simple( g_reg_lista_simple, g_tab_lista_lineas );
        --
    END p_selecciona_lst_lineas;    
    --
    -- selecciona el resultado de la busqueda de las usos
    PROCEDURE p_selecciona_lst_usos IS 
    BEGIN 
        --
        g_reg_lista_simple                := NULL;
        g_reg_lista_simple.codigo         := '1';
        g_reg_lista_simple.descripcion    := 'USOS #1';
        p_agrega_reg_simple( g_reg_lista_simple, g_tab_lista_usos );
        g_reg_lista_simple.codigo         := '2';
        g_reg_lista_simple.descripcion    := 'USOS #2';
        p_agrega_reg_simple( g_reg_lista_simple, g_tab_lista_usos );
        --
    END p_selecciona_lst_usos;   
        --
    -- selecciona el resultado de la busqueda de las colores
    PROCEDURE p_selecciona_lst_colores IS 
    BEGIN 
        --
        g_reg_lista_simple                := NULL;
        g_reg_lista_simple.codigo         := '1';
        g_reg_lista_simple.descripcion    := 'COLOR #1';
        p_agrega_reg_simple( g_reg_lista_simple, g_tab_lista_colores );
        g_reg_lista_simple.codigo         := '2';
        g_reg_lista_simple.descripcion    := 'COLOR #2';
        p_agrega_reg_simple( g_reg_lista_simple, g_tab_lista_colores );
        --
    END p_selecciona_lst_colores;       
    --
    -- URLS   
    --
    -- login
    PROCEDURE p_login_ws(   p_parametros IN CLOB,
                            p_token      OUT gc_ref_cursor,
                            p_mensaje    OUT VARCHAR2
                        ) IS 
        --
        l_token     typ_reg_token;
        l_mensaje   typ_reg_mensaje;
        --                
    BEGIN 
        --
        g_access_token := SYS_GUID();
        g_usuario      := 'USUARIO';
        g_tip_usuario  := 'PERITO';
        --
        OPEN p_token FOR
            SELECT g_access_token access_token,
                   g_tip_usuario token_type,
                   cast( (24*60*60) AS NUMBER(8) ) expires_in,
                   cast( 'OK' AS VARCHAR2(512)) txt_mensaje
              FROM dual;
        --
        p_mensaje :='OK';
        --      
    END p_login_ws;  
    -- 
    -- login
    PROCEDURE p_login_ws(   p_parametros IN CLOB,
                            p_token      OUT gc_ref_cursor
                        ) IS 
        --
        l_token             typ_reg_token;
        l_txt_mensaje       VARCHAR2(512);
        --
        -- usuarios
        CURSOR c_usuario IS
            SELECT usuario_nombre, bloqueado
              FROM portal_web.t_usuario
             WHERE email            = g_usuario
               AND upper(paswd_aut) = g_password
               AND mca_tipo_autenticacion = 'L'
               AND bloqueado = trn.NO;
        --
        -- descomponiendo usuarios
        CURSOR c_descompone_cod_usr IS
            SELECT rownum, token dato
              FROM (SELECT TRIM(substr(txt,
                                instr(txt, '_', 1, LEVEL) + 1,
                                instr(txt, '_', 1, LEVEL + 1) -
                                instr(txt, '_', 1, LEVEL) - 1)) AS token
                      FROM (SELECT '_' || g_usuario_nombre || '_' AS txt FROM dual)
                     CONNECT BY LEVEL <= length(txt) - length(REPLACE(txt, '_', '')) - 1
                   );           
        --
        -- procedimiento para obtener usuario y clave
        FUNCTION fp_toma_usuario( pp_parametro CLOB ) RETURN BOOLEAN IS 
        BEGIN 
            -- 
            dc_k_util_json_web.p_lee(   json(pp_parametro)  );
            --
            g_usuario       := dc_k_util_json_web.f_get_value('Username');
            g_password      := dc_k_util_json_web.f_get_value('Password');
            g_tip_usuario   := dc_k_util_json_web.f_get_value('grant_type');
            --
            RETURN ( g_usuario IS NOT NULL AND g_password IS NOT NULL AND g_tip_usuario IS NOT NULL );
            --
            EXCEPTION
                WHEN OTHERS THEN
                    --
                    dbms_output.put_line(sqlerrm);
                    RETURN FALSE;
                    --
        END fp_toma_usuario;
        --
        -- verificamos si el usuario existe
        FUNCTION fp_existe_usuario  RETURN BOOLEAN IS 
            --
            l_existe BOOLEAN := FALSE;
            --
        BEGIN 
            --
            -- encriptamos la clave
            -- g_password := dbms_obfuscation_toolkit.md5(input => UTL_RAW.cast_to_raw(g_password));
            g_password := upper(g_password);

            --
            OPEN c_usuario;
            FETCH c_usuario INTO g_usuario_nombre, g_bloqueado;
            l_existe := c_usuario%FOUND;
            CLOSE c_usuario;
            --
            RETURN ( l_existe AND g_bloqueado = trn.NO );
            --
            EXCEPTION 
                WHEN OTHERS THEN 
                    dbms_output.put_line(sqlerrm);
                    RETURN FALSE;
            --        
        END fp_existe_usuario;
        --
        -- registrar del usuario
        FUNCTION fp_registrar_usuario RETURN BOOLEAN IS 
            --
            l_cantidad  NUMBER;
            l_mca       NUMBER;
            l_mcantlm   CHAR(1) := 'N';
            l_dato_1    VARCHAR(200);
            l_dato_2    VARCHAR2(200);
            l_dato_3    VARCHAR2(200);
            --
            CURSOR c_cont_descomposicion IS
                SELECT COUNT(*)
                  FROM (SELECT TRIM(substr(txt,
                                       instr(txt, '_', 1, LEVEL) + 1,
                                       instr(txt, '_', 1, LEVEL + 1) -
                                       instr(txt, '_', 1, LEVEL) - 1)) AS token
                          FROM (SELECT '_' || g_usuario_nombre || '_' AS txt FROM dual)
                         CONNECT BY LEVEL <= length(txt) - length(REPLACE(txt, '_', '')) - 1
                       );
            --
            --
            CURSOR c_agt_valido(    pc_cod_cia a1001332.cod_cia%TYPE, 
                                    pc_tip_docum a1001332.tip_docum%TYPE, 
                                    pc_cod_docum a1001332.cod_docum%TYPE
                                ) IS
                SELECT cod_agt
                  FROM a1001332 a, a1001390 b, a1001399 c
                 WHERE a.cod_cia = pc_cod_cia
                   AND nvl(a.mca_inh, 'N') = 'N'
                   AND a.fec_validez = (SELECT MAX(b.fec_validez)
                                          FROM a1001332 b
                                         WHERE b.cod_cia = pc_cod_cia
                                           AND b.cod_agt = a.cod_agt
                                       )
                    AND b.cod_cia   = c.cod_cia
                    AND b.tip_docum = c.tip_docum
                    AND b.cod_docum = c.cod_docum
                    AND b.cod_cia   = a.cod_cia
                    AND b.cod_act_tercero = 2
                    AND b.cod_tercero = a.cod_agt
                    AND a.tip_docum = pc_tip_docum
                    AND a.cod_docum = pc_cod_docum; 
            --
            --         
            CURSOR c_sub_agt_valido(    pc_cod_cia a1001332.cod_cia%TYPE, 
                                        pc_tip_docum a1001332.tip_docum%TYPE, 
                                        pc_cod_docum a1001332.cod_docum%TYPE
                                    ) IS
                SELECT cod_agt
                  FROM a1001337 a, a1001390 b, a1001399 c
                 WHERE a.cod_cia = pc_cod_cia
                   AND nvl(a.mca_inh, 'N') = 'N'
                   AND a.fec_validez = ( SELECT MAX(b.fec_validez)
                                           FROM a1001337 b
                                          WHERE b.cod_cia = pc_cod_cia
                                            AND b.cod_emp_agt = a.cod_emp_agt
                                       )
                   AND b.cod_cia = c.cod_cia
                   AND b.tip_docum = c.tip_docum
                   AND b.cod_docum = c.cod_docum
                   AND b.cod_cia = a.cod_cia
                   AND b.cod_act_tercero = 2
                   AND b.cod_tercero = a.cod_agt
                   AND a.tip_docum = pc_tip_docum
                   AND a.cod_docum = pc_cod_docum;        
            --         
        BEGIN 
            --
            OPEN c_cont_descomposicion;
            FETCH c_cont_descomposicion INTO l_cantidad;
            CLOSE c_cont_descomposicion;
            --
            l_mca := instr(g_usuario_nombre, '1_');
            --
            IF l_mca > 0 THEN
              l_mcantlm := 'C';
            END IF;
            --
            FOR reg_c IN c_descompone_cod_usr LOOP
                --
                dbms_output.put_line('Datos -> ('||reg_c.rownum ||') '||reg_c.dato);
                --
                IF reg_c.dato != ' ' THEN
                    --
                    IF (reg_c.rownum = 1 AND l_cantidad >= reg_c.rownum) THEN
                        --
                        l_dato_1 := reg_c.dato;
                        --
                    ELSIF (reg_c.rownum = 2 AND l_cantidad >= reg_c.rownum) THEN
                        --
                        l_dato_2 := reg_c.dato;
                        --
                    ELSIF (reg_c.rownum = 3 AND l_cantidad >= reg_c.rownum) THEN
                        --
                        l_dato_3 := reg_c.dato;
                        --
                    END IF;
                    --
                END IF;
                --
            END LOOP;
            --
            IF l_dato_1 = '2' THEN
                --
                BEGIN
                    --
                    OPEN c_agt_valido( g_cod_cia, l_dato_2, l_dato_3);
                    FETCH c_agt_valido INTO g_cod_agt;
                    CLOSE c_agt_valido;
                    --
                    EXCEPTION
                    WHEN OTHERS THEN
                        g_cod_agt := NULL;
                        dbms_output.put_line('Agente no fue encontrado: ' || l_dato_2 ||', '||l_dato_3 );
                        RETURN FALSE;
                        --
                END;
                --
            ELSIF l_dato_1 = '37' THEN
                --
                BEGIN
                    --
                    OPEN c_sub_agt_valido(g_cod_cia, l_dato_2, l_dato_3);
                    FETCH c_sub_agt_valido INTO g_cod_agt;
                    CLOSE c_sub_agt_valido;
                    --
                    EXCEPTION
                    WHEN OTHERS THEN
                        g_cod_agt := NULL;
                        dbms_output.put_line('Agente no fue encontrado: ' || l_dato_2 ||', '||l_dato_3 );
                        RETURN FALSE;
                END;
                --
            END IF;
            --
            -- creamos el token
            SELECT dbms_random.random || dbms_random.STRING('K', 8)
              INTO g_access_token
              FROM dual;
            --
            g_session_id := g_access_token;
            --
            -- registramos el usuario
            BEGIN
                INSERT INTO portal_web.t_usuario_ws(
                    cod_cia,
                    usuario_nombre,
                    login,
                    logout,
                    sessionid,
                    mca_activa,
                    cod_producto,
                    cod_mon,
                    fec_actu
                )
                VALUES(
                    g_cod_cia,
                    g_cod_agt,
                    SYSDATE,
                    NULL,
                    g_access_token,
                    trn.SI,
                    NULL,
                    NULL,
                    SYSDATE
                );
                --
                IF SQL%ROWCOUNT = 1 THEN
                    --
                    -- Inactiva token anteriores
                    UPDATE portal_web.t_usuario_ws
                        SET mca_activa = 'N', logout = SYSDATE
                    WHERE cod_cia          = g_cod_cia
                        AND usuario_nombre = g_cod_agt
                        AND sessionid      != g_access_token;
                    --
                    IF SQL%ROWCOUNT <> 0 THEN
                        dbms_output.put_line('Se Actualizaron los registros Anteriores');
                    END IF;
                --
                END IF;
                --
                RETURN TRUE;
                --
                EXCEPTION
                    WHEN OTHERS THEN
                        dbms_output.put_line(sqlerrm);
                        RETURN FALSE;
                --        
            END;  
            --
        END fp_registrar_usuario;
        --                
    BEGIN 
        --
        l_txt_mensaje  := '500';
        --
        -- validamos la entrada
        IF p_parametros IS NOT NULL THEN 
            --
            -- determinamos usuario y contrasena en los parametros JSON
            IF fp_toma_usuario( p_parametros ) THEN 
                --
                -- verificamos si el usuario existe
                IF fp_existe_usuario THEN
                    --
                    IF fp_registrar_usuario THEN
                        l_txt_mensaje := 'OK';
                    ELSE
                        l_txt_mensaje := '500 No se Registro el usuario!';
                    END IF;
                    --
                ELSE 
                    l_txt_mensaje := '402 Usuario no existe o esta bloqueado!';
                END IF;
            ELSE
                l_txt_mensaje := '400 Usuario o clave no fue suministrada!';
            END IF;
            --
        ELSE
            l_txt_mensaje := '400 Solicitud Incorrecta!';
        END IF;
        --
        SELECT cast( (24*60*60) AS NUMBER(8) ) 
          INTO g_expires_in 
          FROM DUAL;
        --
        OPEN p_token FOR
            SELECT g_access_token access_token,
                   g_tip_usuario token_type,
                   g_expires_in expires_in,
                   cast( l_txt_mensaje AS VARCHAR2(512)) txt_mensaje
              FROM dual;       
        --      
    END p_login_ws;                      
    --
    -- buscar cotizacion   
    PROCEDURE p_buscar_cotizacion_cliente(  p_parametros IN CLOB,
                                            p_cotizacion OUT gc_ref_cursor,
                                            p_errores    OUT VARCHAR2
                                         ) IS  
        --
        l_ok        BOOLEAN := FALSE;
        l_respuesta VARCHAR2(4000);
        --                                   
    BEGIN 
        --
        -- validamos el parametro de la solicitud
        l_ok := f_valida_json(  p_cod_cia       => g_cod_cia,
                                p_session_id    => g_session_id,
                                p_url           => '/api/apiexterno/autoinsp/buscarCotizacionesCliente',
                                p_tip_json      => em_k_ws_auto_inspeccion.K_TIP_BUSCAR_COTIZACION,
                                p_dato_json     => p_parametros,   
                                p_respuesta     => l_respuesta 
                            );
        --                    
        -- verificamos el resultado
        IF l_ok THEN 
            --
            p_procesa_json(l_ok,l_respuesta );
            --
            IF l_ok THEN
                g_tab_busqueda_cotizacion.delete;
                p_seleccion_cotizacion;
                --
                p_actualiza_x2000008_web_mni( p_cod_cia       => g_cod_cia,
                                              p_mca_valido    => 'S',
                                              p_txt_resultado => 'Proceso Exitoso!',
                                              p_resultado     => l_ok,    
                                              p_respuesta     => l_respuesta );
                IF l_ok THEN                              
                    --
                    OPEN p_cotizacion FOR
                        SELECT * FROM TABLE( g_tab_busqueda_cotizacion );
                    --
                    p_errores := 'OK';
                    --
                ELSE
                    p_errores := '500';
                END IF;   
                -- 
            ELSE 
                p_errores := '500'; 
            END IF;    
        ELSE
            p_errores := '500';
        END IF;    
        --     
        EXCEPTION 
            WHEN OTHERS THEN
                dbms_output.put_line(sqlerrm);
        --        
    END  p_buscar_cotizacion_cliente; 
    --  
    -- devolvemos la informacion de la cotizacion (DETALLE)
    PROCEDURE p_informacion_cotizacion( p_parametros IN CLOB, 
                                        p_cotizacion OUT gc_ref_cursor,
                                        p_errores    OUT VARCHAR2
                                      ) IS 
        --
        l_ok        BOOLEAN := FALSE;
        l_respuesta VARCHAR2(4000);
        --                                                
    BEGIN 
        --
        -- validamos el parametro de la solicitud
        l_ok := f_valida_json(  p_cod_cia       => g_cod_cia,
                                p_session_id    => g_session_id,
                                p_url           => '/api/apiexterno/autoinsp/informacionCotizacion',
                                p_tip_json      => em_k_ws_auto_inspeccion.K_TIP_LEER_COTIZACION,
                                p_dato_json     => p_parametros,   
                                p_respuesta     => l_respuesta 
                            );
        --                    
        -- verificamos el resultado
        IF l_ok THEN   
            --
            p_procesa_json( l_ok, l_respuesta );   
            --
            IF l_ok THEN             
                --
                g_tab_info_cotizacion.delete;
                p_seleccion_info_cotizacion;
                --
                p_actualiza_x2000008_web_mni( p_cod_cia       => g_cod_cia,
                                              p_mca_valido    => 'S',
                                              p_txt_resultado => 'Proceso Exitoso!',
                                              p_resultado     => l_ok,    
                                              p_respuesta     => l_respuesta );
                -- 
                IF l_ok THEN                              
                    OPEN p_cotizacion FOR
                        SELECT * FROM TABLE( g_tab_info_cotizacion );
                    --
                    p_errores := 'OK';
                    --
                ELSE
                    p_errores := '500';
                END IF;  
                --    
            ELSE
                p_errores := '400';
            END IF;
            --      
        ELSE
            p_errores := '500';
        END IF;   
        --     
        EXCEPTION 
            WHEN OTHERS THEN
                dbms_output.put_line(sqlerrm);
        --  
    END  p_informacion_cotizacion;  
    --  
    -- actualizar datos
    PROCEDURE p_actualiza_cotizacion(  p_parametros IN CLOB, 
                                       p_errores    OUT VARCHAR2
                                    ) IS 
        --
        l_ok        BOOLEAN := FALSE;
        l_respuesta VARCHAR2(4000);
        --                              
    BEGIN 
        --
        -- validamos el parametro de la solicitud
        l_ok := f_valida_json(  p_cod_cia       => g_cod_cia,
                                p_session_id    => g_session_id,
                                p_url           => '/api/apiexterno/autoinsp/actualizarDatos',
                                p_tip_json      => em_k_ws_auto_inspeccion.K_TIP_ACTUALIZAR_COTIZACION,
                                p_dato_json     => p_parametros,   
                                p_respuesta     => l_respuesta 
                            );
        --                    
        -- verificamos el resultado
        IF l_ok THEN      
            --
            p_procesa_json( l_ok, l_respuesta );   
            --   
            IF l_ok THEN             
                --                    
                g_tab_reg_cotizacion.delete;
                p_actualiza_reg_cotizacion;    
                --
                p_actualiza_x2000008_web_mni( p_cod_cia       => g_cod_cia,
                                              p_mca_valido    => 'S',
                                              p_txt_resultado => 'Proceso Exitoso!',
                                              p_resultado     => l_ok,    
                                              p_respuesta     => l_respuesta );
                --
                IF l_ok THEN                              
                    p_errores := 'OK';
                ELSE
                    p_errores := '500';
                END IF;     
                --
            ELSE
                p_errores := '400';
            END IF;
        ELSE
            p_errores := '500';
        END IF;
        --        
        EXCEPTION 
            WHEN OTHERS THEN 
                p_errores := '500';
        --
    END p_actualiza_cotizacion;   
    --
    -- incluir foto del vehiculo      
    PROCEDURE p_graba_foto_vehiculo(  p_parametros IN CLOB, 
                                      p_errores    OUT VARCHAR2
                                    ) IS
        --
        l_ok        BOOLEAN := FALSE;
        l_respuesta VARCHAR2(4000);
        --                                     
    BEGIN
        --
        -- validamos el parametro de la solicitud
        l_ok := f_valida_json(  p_cod_cia       => g_cod_cia,
                                p_session_id    => g_session_id,
                                p_url           => '/api/apiexterno/autoinsp/fotosVehiculo ',
                                p_tip_json      => em_k_ws_auto_inspeccion.K_TIP_ACTUALIZAR_FOTOS,
                                p_dato_json     => '{ "fotos":' || p_parametros ||'}',   
                                p_respuesta     => l_respuesta 
                            );

        --                    
        -- verificamos el resultado
        IF l_ok THEN 
            --
            p_procesa_json( l_ok, l_respuesta );   
            --  
        END IF;                    
        --                    
        p_errores := 'OK';
        --
    END p_graba_foto_vehiculo;                                                                                           
    --    
    --  lista piezas  
    PROCEDURE p_lista_piezas(   p_parametros IN CLOB, 
                                p_piezas     OUT gc_ref_cursor,
                                p_errores    OUT VARCHAR2
                            ) IS
    BEGIN 
        --
        g_tab_reg_pieza.delete;
        p_selecciona_piezas_vehiculo;
        --
        OPEN p_piezas FOR
            SELECT * FROM TABLE( g_tab_reg_pieza );
        --
        p_errores := 'OK';
        --
    END p_lista_piezas;
    --
    -- incluir danios a vehiculos      
    PROCEDURE p_graba_rotura_vehiculo(  p_parametros IN CLOB, 
                                        p_errores    OUT VARCHAR2
                                     ) IS 
    BEGIN 
        --
        p_errores := 'OK';
        --
    END p_graba_rotura_vehiculo;   
    --
    -- incluir accesorios a vehiculos           
    PROCEDURE p_graba_accesorio_vehiculo(  p_parametros IN CLOB, 
                                        p_errores    OUT VARCHAR2
                                     ) IS 
    BEGIN 
        --
        p_errores := 'OK';
        --
    END p_graba_accesorio_vehiculo; 
    --
    -- incluir documentos asociados a vehiculos      
    PROCEDURE p_graba_documento_vehiculo(  p_parametros IN CLOB, 
                                           p_errores    OUT VARCHAR2
                                        ) IS 
    BEGIN 
        --
        p_errores := 'OK';
        --
    END p_graba_documento_vehiculo;     
    --
    --  lista controles tecnicos  
    PROCEDURE p_lista_ctrl_tecnico(   p_parametros IN CLOB, 
                                p_ctrl_tec   OUT gc_ref_cursor,
                                p_errores    OUT VARCHAR2
                            ) IS 
    BEGIN 
        --
        g_tab_reg_ctrl_tecnico.delete;
        p_selecciona_ctrl_tecnico;
        --
        OPEN p_ctrl_tec FOR
            SELECT * FROM TABLE( g_tab_reg_ctrl_tecnico );
        --
        p_errores := 'OK';
        --
    END p_lista_ctrl_tecnico;
    --  
    -- envio Respuesta
    PROCEDURE p_envio_respuesta(    p_parametros        IN CLOB, 
                                    p_errores           OUT VARCHAR2
                                ) IS
    BEGIN 
        --
        p_errores := 'OK';
        --
    END p_envio_respuesta;    
    --
    --  lista listaDepartamentos  
    PROCEDURE p_lista_dpto(     p_parametros    IN CLOB, 
                                p_departaemtno  OUT gc_ref_cursor,
                                p_errores       OUT VARCHAR2
                          ) IS
    BEGIN 
        --
        g_tab_lista_dpto.delete;
        p_selecciona_lst_dpto;
        --
        OPEN p_departaemtno FOR
            SELECT * FROM TABLE( g_tab_lista_dpto );
        --
        p_errores := 'OK';

    END p_lista_dpto;     
    --       
    --  lista Municipios  
    PROCEDURE p_lista_mpio(     p_parametros    IN CLOB, 
                                p_mpio          OUT gc_ref_cursor,
                                p_errores       OUT VARCHAR2
                          ) IS 
    BEGIN 
        --
        g_tab_lista_mpio.delete;
        p_selecciona_lst_mpio;
        --
        OPEN p_mpio FOR
            SELECT * FROM TABLE( g_tab_lista_mpio );
        --
        p_errores := 'OK';
        --
    END p_lista_mpio; 
    --       
    --  lista Marcas  
    PROCEDURE p_lista_marcas(   p_parametros    IN CLOB, 
                                p_marcas        OUT gc_ref_cursor,
                                p_errores       OUT VARCHAR2
                          ) IS 
    BEGIN 
        --
        g_tab_lista_marca.delete;
        p_selecciona_lst_marca;
        --
        OPEN p_marcas FOR
            SELECT * FROM TABLE( g_tab_lista_marca );
        --
        p_errores := 'OK';
        --
    END p_lista_marcas;                                                                                                                                                                                   
    --          
    --  lista Lineas  
    PROCEDURE p_lista_lineas(   p_parametros    IN CLOB, 
                                p_lineas        OUT gc_ref_cursor,
                                p_errores       OUT VARCHAR2
                          ) IS 
    BEGIN 
        --
        g_tab_lista_lineas.delete;
        p_selecciona_lst_lineas;
        --
        OPEN p_lineas FOR
            SELECT * FROM TABLE( g_tab_lista_lineas );
        --
        p_errores := 'OK';
        --
    END p_lista_lineas;    
    --       
    --  lista usos  
    PROCEDURE p_lista_usos(     p_parametros    IN CLOB, 
                                p_usos          OUT gc_ref_cursor,
                                p_errores       OUT VARCHAR2
                          ) IS 
    BEGIN 
        --
        g_tab_lista_usos.delete;
        p_selecciona_lst_usos;
        --
        OPEN p_usos FOR
            SELECT * FROM TABLE( g_tab_lista_usos );
        --
        p_errores := 'OK';
        --    
    END p_lista_usos;    
    --       
    --  lista colores 
    PROCEDURE p_lista_colores(  p_parametros    IN CLOB, 
                                p_colores       OUT gc_ref_cursor,
                                p_errores       OUT VARCHAR2
                          ) IS
    BEGIN 
        --
        g_tab_lista_colores.delete;
        p_selecciona_lst_colores;
        --
        OPEN p_colores FOR
            SELECT * FROM TABLE( g_tab_lista_colores );
        --
        p_errores := 'OK';
        --        
    END p_lista_colores;                                                               
    --                                                                         
end em_k_ws_auto_inspeccion;
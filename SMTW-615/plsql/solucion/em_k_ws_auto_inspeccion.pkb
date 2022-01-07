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
  g_cod_cia  CONSTANT x2000000_web.val_campo%TYPE := 4;
  g_cod_ramo CONSTANT a1001800.cod_ramo%TYPE := 301;
  g_cod_pais CONSTANT a1000101.cod_pais%TYPE := 'NIC';
  --
  -- globales internas
  g_access_token     VARCHAR2(128);
  g_usuario          VARCHAR2(128);
  g_expires_in       NUMBER;
  g_password         VARCHAR2(128);
  g_tip_usuario      VARCHAR2(128);
  g_usuario_nombre   portal_web.t_usuario.usuario_nombre%TYPE;
  g_bloqueado        portal_web.t_usuario.bloqueado%TYPE;
  g_numero_cotiacion VARCHAR2(128);
  g_nom_archivo      VARCHAR2(100) := 'ws_auto_inspeccion';
  g_session_id       VARCHAR2(128);
  g_process_id       VARCHAR2(32);
  g_cod_modulo       g2000906_web.cod_modulo%TYPE := 'WS_AUTO_INSPECCION';
  g_cod_usr CONSTANT x2000001_web.cod_usr%TYPE := 'USER_WEB';
  g_cod_agt VARCHAR2(20);
  --
  -- errores
  g_hay_error BOOLEAN;
  g_cod_error VARCHAR2(3);
  g_msg_error VARCHAR2(4000);
  g_sql_error VARCHAR2(4000);
  -- 
  -- registros de entradas
  g_typ_reg_b_cot_001 typ_reg_b_cot_001 := NULL; -- parametro buscar Cotizacion
  g_typ_reg_i_cot_001 typ_reg_i_cot_001 := NULL; -- parametro informacion Cotizacion
  g_typ_reg_a_cot_001 typ_reg_a_cot_001 := NULL; -- parametro actualizar Cotizacion
  g_typ_reg_a_fot_001 typ_reg_a_fot_001 := NULL; -- parametro actualizar fotos
  g_typ_reg_l_mcp_001 typ_reg_l_mcp_001 := NULL; -- parametros de lista de municipios
  g_typ_reg_a_doc_001 typ_reg_a_doc_001 := NULL; -- parametro actualizar documentos
  g_typ_reg_a_res_001 typ_reg_a_res_001 := NULL; -- parametro actualizar respuestas
  g_typ_reg_a_res_002 typ_reg_a_res_002 := NULL; -- parametro actualizar respuestas ctrl
  g_typ_reg_a_rot_002 typ_reg_a_rot_002 := NULL; -- parametros de roturas de vehiculos
  g_typ_reg_a_acc_002 typ_reg_a_acc_002 := NULL; -- parametros de accesotios
  -- registros de salidas
  g_reg_cliente_cotizacion typ_reg_cliente_cotizacion := NULL;
  g_reg_info_cotizacion    typ_reg_info_cotizacion := NULL;
  g_reg_cotizacion         typ_reg_cotizacion := NULL;
  g_reg_ctrl_tecnico       typ_reg_ctrl_tecnico := NULL;
  g_reg_lista_simple       typ_reg_lista_simple := NULL;
  -- tablas de salidas
  g_tab_busqueda_cotizacion typ_tab_cliente_cotizacion := typ_tab_cliente_cotizacion();
  g_tab_info_cotizacion     typ_tab_info_cotizacion := typ_tab_info_cotizacion();
  g_tab_reg_cotizacion      typ_tab_reg_cotizacion := typ_tab_reg_cotizacion();
  g_tab_reg_foto            typ_tab_reg_fotos := typ_tab_reg_fotos();
  g_tab_reg_documentos      typ_tab_reg_documentos := typ_tab_reg_documentos();
  g_tab_reg_respuestas      typ_tab_reg_respuestas := typ_tab_reg_respuestas();
  g_tab_reg_respuestas_ctrl typ_tab_reg_respuestas_ctrl := typ_tab_reg_respuestas_ctrl();
  g_tab_reg_ctrl_tecnico    typ_tab_reg_ctrl_tecnico := typ_tab_reg_ctrl_tecnico();
  g_tab_reg_roturas_det     typ_tab_reg_rotura_det := typ_tab_reg_rotura_det();
  g_tab_reg_accesorios_det  typ_tab_reg_accesorio_det := typ_tab_reg_accesorio_det();
  g_tab_reg_pieza           typ_tab_reg_simple := typ_tab_reg_simple();
  g_tab_lista_dpto          typ_tab_reg_simple := typ_tab_reg_simple();
  g_tab_lista_mpio          typ_tab_reg_simple := typ_tab_reg_simple();
  g_tab_lista_marca         typ_tab_reg_simple := typ_tab_reg_simple();
  g_tab_lista_lineas        typ_tab_reg_simple := typ_tab_reg_simple();
  g_tab_lista_usos          typ_tab_reg_simple := typ_tab_reg_simple();
  g_tab_lista_colores       typ_tab_reg_simple := typ_tab_reg_simple();
  --
  -- Utilidades
  --
  -- devuelve el error
  PROCEDURE p_devuelve_error(p_hay_error OUT BOOLEAN,
                             p_cod_error OUT VARCHAR2,
                             p_msg_error OUT VARCHAR2,
                             p_sql_error OUT VARCHAR2) IS
  BEGIN
    --
    p_hay_error := g_hay_error;
    p_cod_error := g_cod_error;
    p_msg_error := g_msg_error;
    p_sql_error := g_sql_error;
    --
  END p_devuelve_error;
  --
  -- valida la cotizacion (POLIZA) en la tabla de presupuesto
  FUNCTION f_valida_cotizacion(p_num_cotizacion VARCHAR2,
                               p_respuesta      OUT VARCHAR2,
                               p_resultado      OUT BOOLEAN) RETURN BOOLEAN IS
    --
    l_cant NUMBER := 0;
    --
  BEGIN
    --
    SELECT count(distinct num_poliza)
      INTO l_cant
      FROM p2000030
     WHERE cod_cia = g_cod_cia
       AND num_poliza = p_num_cotizacion;
    --
    p_resultado := l_cant > 0;
    IF p_resultado THEN
      p_respuesta := NULL;
    ELSE
      --
      p_respuesta := 'No existe la cotizacion!';
      --
    END IF;
    --  
    RETURN l_cant > 0;
    --
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      p_resultado := FALSE;
      g_sql_error := SQLERRM;
      p_respuesta := SQLERRM;
      --
      g_hay_error := TRUE;
      g_cod_error := '400';
      g_msg_error := 'No se ha encontrado la cotizacion!';
      --
      RETURN FALSE;
    WHEN OTHERS THEN
      p_resultado := FALSE;
      g_sql_error := SQLERRM;
      p_respuesta := SQLERRM;
      --
      g_hay_error := TRUE;
      g_cod_error := '500';
      g_msg_error := 'No es posible validar la Cotizacion!';
      --
      RETURN FALSE;
      --
  END f_valida_cotizacion;
  --
  -- actualiza tabla de log de requerimientos x2000008_web
  PROCEDURE p_actualiza_x2000008_web(p_cod_cia       IN x2000008_web.cod_cia%TYPE,
                                     p_mca_valido    IN VARCHAR2,
                                     p_txt_resultado IN VARCHAR2,
                                     p_resultado     OUT BOOLEAN,
                                     p_respuesta     OUT VARCHAR2) IS
  BEGIN
    --
    UPDATE x2000008_web
       SET mca_valido    = p_mca_valido,
           txt_resultado = p_txt_resultado,
           session_id    = nvl(g_session_id, session_id)
     WHERE process_id = g_process_id;
    --
    p_resultado := TRUE;
    p_respuesta := '';
    --
  EXCEPTION
    WHEN OTHERS THEN
      p_resultado := FALSE;
      g_sql_error := SQLERRM;
      p_respuesta := SQLERRM;
      --
      g_hay_error := TRUE;
      g_cod_error := '500';
      g_msg_error := 'No es posible actualiza a x2000008_web';
      --
  END p_actualiza_x2000008_web;
  --
  -- verificacion de token
  FUNCTION f_verificar_token(p_dato_json CLOB, p_respuesta OUT VARCHAR2)
    RETURN BOOLEAN IS
    --
    l_expire       NUMBER := nvl(g_expires_in, 10);
    l_segundos_dia NUMBER := 24;
    l_ok           BOOLEAN := FALSE;
    l_estado       VARCHAR2(20);
    l_access_token VARCHAR2(128);
    l_session_id   VARCHAR2(128);
    --
    CURSOR c_token IS
      SELECT sessionid,
             CASE
               WHEN CAST(login + round(l_expire / l_segundos_dia, 3) AS timestamp) > sysdate THEN
                'VIGENTE'
               ELSE
                'VENCIDO'
             END estado
        FROM portal_web.t_usuario_ws
       WHERE sessionid = l_access_token;
    --
    -- dato de solicitud de 
    CURSOR c_datos IS
      SELECT json_value(p_dato_json, '$.access_token') FROM dual;
    --
  BEGIN
    --
    -- verificamos el valor del parametro
    OPEN c_datos;
    FETCH c_datos
      INTO l_access_token;
    l_ok := c_datos%FOUND;
    CLOSE c_datos;
    --
    IF l_ok THEN
      --
      -- verificamos el token
      OPEN c_token;
      FETCH c_token
        INTO l_session_id, l_estado;
      l_ok := c_token%FOUND;
      CLOSE c_token;
      --
      IF l_ok THEN
        IF l_estado = 'VENCIDO' THEN
          p_respuesta := 'Token no es valido!, (VENCIDO)';
          l_ok        := FALSE;
        ELSE
          g_access_token := l_access_token;
          g_session_id   := l_session_id;
          p_respuesta    := '';
          l_ok           := TRUE;
        END IF;
      ELSE
        p_respuesta := 'Token no es valido!, (NO REGISTRADO)';
        l_ok        := FALSE;
      END IF;
    ELSE
      p_respuesta := 'Token no es valido!, (NO ESTA PRESENTE EN LOS PARAMETROS)';
      l_ok        := FALSE;
    END IF;
    --
    RETURN l_ok;
    --
  EXCEPTION
    WHEN OTHERS THEN
      --
      p_respuesta := 'No es posible validar la estructura token!';
      g_hay_error := TRUE;
      g_cod_error := '500';
      g_msg_error := p_respuesta;
      g_sql_error := SQLERRM;
      --
      RETURN FALSE;
      --        
  END f_verificar_token;
  --
  -- inserta en tabla de tratamiento JSON
  PROCEDURE p_inserta_x2000008_web(p_cod_cia    IN x2000008_web.cod_cia%TYPE,
                                   p_session_id IN x2000008_web.session_id%TYPE,
                                   p_url        IN x2000008_web.url%TYPE,
                                   p_tip_json   IN x2000008_web.tip_json%TYPE,
                                   p_dato_json  IN CLOB,
                                   p_resultado  OUT BOOLEAN,
                                   p_respuesta  OUT VARCHAR2) IS
  BEGIN
    --
    g_process_id := sys_guid();
    --
    INSERT INTO x2000008_web
      (cod_cia,
       process_id,
       session_id,
       fec_transaccion,
       url,
       tip_json,
       dato_json,
       mca_valido,
       txt_resultado)
    VALUES
      (p_cod_cia,
       g_process_id,
       p_session_id,
       trunc(sysdate),
       p_url,
       p_tip_json,
       p_dato_json,
       'N',
       'Sin Procesar');
    --
    p_resultado := TRUE;
    p_respuesta := '';
    --
  EXCEPTION
    WHEN OTHERS THEN
      p_resultado := FALSE;
      p_respuesta := SQLERRM;
      g_sql_error := SQLERRM;
      --
      g_hay_error := TRUE;
      g_cod_error := '400';
      g_msg_error := 'No es posible validar la estructura JSON';
      --
  END p_inserta_x2000008_web;
  --
  -- procesamos el tipo de JSON 'B-COT-001'
  PROCEDURE p_b_cot_001(p_resultado OUT BOOLEAN, p_respuesta OUT VARCHAR2) IS
    --
    l_ok        BOOLEAN := FALSE;
    l_respuesta VARCHAR2(4000);
    --
    -- dato de solicitud de 
    CURSOR c_datos IS
      SELECT doc.dato_json.access_token,
             doc.dato_json.usuario,
             doc.dato_json.tipUsuario,
             doc.dato_json.identificacion,
             doc.dato_json.placa,
             doc.dato_json.numeroCotizacion
        FROM x2000008_web doc
       WHERE doc.process_id = g_process_id;
    --     
  BEGIN
    --
    OPEN c_datos;
    FETCH c_datos
      INTO g_typ_reg_b_cot_001.access_token, g_typ_reg_b_cot_001.usuario, g_typ_reg_b_cot_001.tipusuario, g_typ_reg_b_cot_001.identificacion, g_typ_reg_b_cot_001.placa, g_typ_reg_b_cot_001.numeroCotizacion;
    l_ok := c_datos%FOUND;
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
      l_ok := (g_typ_reg_b_cot_001.identificacion IS NOT NULL OR
              g_typ_reg_b_cot_001.placa IS NOT NULL OR
              g_typ_reg_b_cot_001.numeroCotizacion IS NOT NULL) AND l_ok;
      --
      IF g_typ_reg_b_cot_001.numeroCotizacion IS NOT NULL THEN
        l_ok := f_valida_cotizacion(p_num_cotizacion => g_typ_reg_b_cot_001.numeroCotizacion,
                                    p_respuesta      => p_respuesta,
                                    p_resultado      => p_resultado);
      END IF;
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
      g_sql_error := SQLERRM;
      --
      g_hay_error := TRUE;
      g_cod_error := '500';
      g_msg_error := 'No es posible Obtener los datos del tipo de JSON (' ||
                     em_k_ws_auto_inspeccion.K_TIP_BUSCAR_COTIZACION || ')';
      --
  END p_b_cot_001;
  --
  -- procesamos el tipo de JSON 'I-COT-001', Informacion de la Cotizacion
  PROCEDURE p_i_cot_001(p_resultado OUT BOOLEAN, p_respuesta OUT VARCHAR2) IS
    --
    l_ok        BOOLEAN := FALSE;
    l_respuesta VARCHAR2(4000);
    --
    -- dato de solicitud de 
    CURSOR c_datos IS
      SELECT doc.dato_json.access_token, doc.dato_json.numeroCotizacion
        FROM x2000008_web doc
       WHERE doc.process_id = g_process_id;
    --     
  BEGIN
    --
    OPEN c_datos;
    FETCH c_datos
      INTO g_typ_reg_i_cot_001.access_token, g_typ_reg_i_cot_001.numeroCotizacion;
    l_ok := c_datos%FOUND;
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
      --
      IF l_ok THEN
        l_ok        := f_valida_cotizacion(p_num_cotizacion => g_typ_reg_i_cot_001.numeroCotizacion,
                                           p_respuesta      => p_respuesta,
                                           p_resultado      => p_resultado);
        p_respuesta := 'X';
      END IF;
      --                                
      p_resultado := l_ok;
      --
      IF l_ok THEN
        p_respuesta := NULL;
      ELSE
        IF p_respuesta = 'X' THEN
          p_respuesta := 'Poliza no fue Encontrada!';
        ELSE
          p_respuesta := 'Datos Incompletos o nulos en JSON';
        END IF;
      END IF;
      --
    END IF;
    --
  EXCEPTION
    WHEN OTHERS THEN
      p_resultado := FALSE;
      p_respuesta := SQLERRM;
      g_sql_error := SQLERRM;
      --
      g_hay_error := TRUE;
      g_cod_error := '500';
      g_msg_error := 'No es posible Obtener los datos del tipo de JSON (' ||
                     em_k_ws_auto_inspeccion.K_TIP_LEER_COTIZACION || ')';
      --
  END p_i_cot_001;
  --
  -- procesamos el tipo de JSON 'A-COT-001', Actualizacion de la Cotizacion
  PROCEDURE p_a_cot_001(p_resultado OUT BOOLEAN, p_respuesta OUT VARCHAR2) IS
    --
    l_ok        BOOLEAN := FALSE;
    l_respuesta VARCHAR2(4000);
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
        FROM x2000008_web doc
       WHERE doc.process_id = g_process_id;
    --
  BEGIN
    --
    OPEN c_datos;
    FETCH c_datos
      INTO g_typ_reg_a_cot_001.access_token, g_typ_reg_a_cot_001.numeroCotizacion, g_typ_reg_a_cot_001.placa, g_typ_reg_a_cot_001.marca, g_typ_reg_a_cot_001.linea, g_typ_reg_a_cot_001.version, g_typ_reg_a_cot_001.modelo, g_typ_reg_a_cot_001.codFase, g_typ_reg_a_cot_001.motor, g_typ_reg_a_cot_001.chasis, g_typ_reg_a_cot_001.serie, g_typ_reg_a_cot_001.uso, g_typ_reg_a_cot_001.color;
    l_ok := c_datos%FOUND;
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
      l_ok := g_typ_reg_a_cot_001.numeroCotizacion IS NOT NULL AND l_ok;
      --
      IF l_ok THEN
        l_ok        := f_valida_cotizacion(p_num_cotizacion => g_typ_reg_a_cot_001.numeroCotizacion,
                                           p_respuesta      => p_respuesta,
                                           p_resultado      => p_resultado);
        p_respuesta := 'X';
      END IF;
      --
      p_resultado := l_ok;
      --
      IF l_ok THEN
        p_respuesta := NULL;
      ELSE
        IF p_respuesta = 'X' THEN
          p_respuesta := 'Poliza no fue Encontrada!';
        ELSE
          p_respuesta := 'Datos Incompletos o nulos en JSON';
        END IF;
      END IF;
      --
    END IF;
    --
  EXCEPTION
    WHEN OTHERS THEN
      p_resultado := FALSE;
      p_respuesta := SQLERRM;
      g_sql_error := SQLERRM;
      --
      g_hay_error := TRUE;
      g_cod_error := '500';
      g_msg_error := 'No es posible Obtener los datos del tipo de JSON (' ||
                     em_k_ws_auto_inspeccion.K_TIP_ACTUALIZAR_COTIZACION || ')';
      --
  END p_a_cot_001;
  --
  -- procesamos el tipo de JSON 'A-FOT-001', Grabar fotos
  PROCEDURE p_a_fot_001(p_resultado OUT BOOLEAN, p_respuesta OUT VARCHAR2) IS
    --
    l_ok        BOOLEAN := FALSE;
    l_respuesta VARCHAR2(4000);
    --
    -- dato de solicitud de 
    CURSOR c_datos IS
      select fot.num_cotizacion,
             fot.tip_foto,
             fot.byte_foto,
             doc.dato_json.access_token
        from x2000008_web doc,
             json_table(dato_json,
                        '$.fotos[*]'
                        COLUMNS(num_cotizacion VARCHAR2(128) PATH
                                '$.numeroCotizacion',
                                tip_foto VARCHAR2(80) PATH '$.tipoFoto',
                                byte_foto VARCHAR2(80) PATH '$.byteFoto')) as fot
       where doc.process_id = g_process_id
         and doc.tip_json = em_k_ws_auto_inspeccion.K_TIP_ACTUALIZAR_FOTOS;
    --
  BEGIN
    --
    g_typ_reg_a_fot_001 := NULL;
    FOR v IN c_datos LOOP
      --
      g_typ_reg_a_fot_001.numeroCotizacion := v.num_cotizacion;
    
      l_ok        := f_valida_cotizacion(p_num_cotizacion => g_typ_reg_a_fot_001.numeroCotizacion,
                                         p_respuesta      => p_respuesta,
                                         p_resultado      => p_resultado);
      p_respuesta := 'X';
      EXIT WHEN NOT l_ok;
      p_respuesta := NULL;
      --
      g_typ_reg_a_fot_001.tipoFoto     := v.tip_foto;
      g_typ_reg_a_fot_001.byteFoto     := v.byte_foto;
      g_typ_reg_a_fot_001.access_token := v.access_token;
      --
      g_tab_reg_foto.extend;
      g_tab_reg_foto(g_tab_reg_foto.count) := g_typ_reg_a_fot_001;
      g_typ_reg_a_fot_001 := NULL;
      --
      l_ok := TRUE;
      --
    END LOOP;
    --
    p_resultado := l_ok;
    IF NOT l_ok THEN
      IF p_respuesta = 'X' THEN
        p_respuesta := 'Poliza no fue Encontrada!';
      ELSE
        p_respuesta := 'NO HAY DATOS QUE PROCESAR!';
      END IF;
    END IF;
    --
  EXCEPTION
    WHEN OTHERS THEN
      p_resultado := FALSE;
      p_respuesta := SQLERRM;
      g_sql_error := SQLERRM;
      --
      g_hay_error := TRUE;
      g_cod_error := '500';
      g_msg_error := 'No es posible Obtener los datos del tipo de JSON (' ||
                     em_k_ws_auto_inspeccion.K_TIP_ACTUALIZAR_FOTOS || ')';
      --
  END p_a_fot_001;
  --
  -- procesamos el tipo de JSON 'A-TIP-D01', Actualizar Documentos
  PROCEDURE p_a_doc_001(p_resultado OUT BOOLEAN, p_respuesta OUT VARCHAR2) IS
    --
    l_ok        BOOLEAN := FALSE;
    l_respuesta VARCHAR2(4000);
    --
    -- dato de solicitud de 
    CURSOR c_datos IS
      select fot.num_cotizacion,
             fot.tip_documento,
             fot.byte_foto,
             doc.dato_json.access_token
        from x2000008_web doc,
             json_table(dato_json,
                        '$.documentos[*]'
                        COLUMNS(num_cotizacion VARCHAR2(128) PATH
                                '$.numeroCotizacion',
                                tip_documento VARCHAR2(128) PATH
                                '$.tipoDocumento',
                                byte_foto VARCHAR2(80) PATH '$.byteFoto')) as fot
       where doc.process_id = g_process_id
         and doc.tip_json = em_k_ws_auto_inspeccion.K_TIP_DOCUMENTO;
    --
  BEGIN
    --
    g_typ_reg_a_doc_001 := NULL;
    FOR v IN c_datos LOOP
      --
      l_ok := v.access_token IS NOT NULL;
      l_ok := v.num_cotizacion IS NOT NULL AND l_ok;
      l_ok := v.tip_documento IS NOT NULL AND l_ok;
      l_ok := v.byte_foto IS NOT NULL AND l_ok;
      --
      EXIT WHEN NOT l_ok;
      --
      IF v.num_cotizacion IS NOT NULL THEN
        l_ok        := f_valida_cotizacion(p_num_cotizacion => v.num_cotizacion,
                                           p_respuesta      => p_respuesta,
                                           p_resultado      => p_resultado);
        p_respuesta := 'X';
        EXIT WHEN NOT l_ok;
        p_respuesta := NULL;
      END IF;
      --
      g_typ_reg_a_doc_001.numeroCotizacion := v.num_cotizacion;
      g_typ_reg_a_doc_001.tipoDocumento    := v.tip_documento;
      g_typ_reg_a_doc_001.byteFoto         := v.byte_foto;
      g_typ_reg_a_doc_001.access_token     := v.access_token;
      --
      g_tab_reg_documentos.extend;
      g_tab_reg_documentos(g_tab_reg_documentos.count) := g_typ_reg_a_doc_001;
      g_typ_reg_a_doc_001 := NULL;
      l_ok := TRUE;
      --
    END LOOP;
    --
    p_resultado := l_ok;
    IF NOT l_ok THEN
      IF p_respuesta = 'X' THEN
        p_respuesta := 'Poliza no fue Encontrada!';
      ELSE
        p_respuesta := 'NO HAY DATOS QUE PROCESAR! o DATOS INCORRECTOS';
      END IF;
      g_cod_error := 400;
      g_hay_error := TRUE;
    ELSE
      p_respuesta := NULL;
    END IF;
    --
  EXCEPTION
    WHEN OTHERS THEN
      p_resultado := FALSE;
      p_respuesta := SQLERRM;
      g_sql_error := SQLERRM;
      --
      g_hay_error := TRUE;
      g_cod_error := '500';
      g_msg_error := 'No es posible Obtener los datos del tipo de JSON (' ||
                     em_k_ws_auto_inspeccion.K_TIP_DOCUMENTO || ')';
      --
  END p_a_doc_001;
  --
  -- procesamos el tipo JSON L-MCP-001, Lista de Municipios
  PROCEDURE p_l_mcp_001(p_resultado OUT BOOLEAN, p_respuesta OUT VARCHAR2) IS
    --
    l_ok        BOOLEAN := FALSE;
    l_respuesta VARCHAR2(4000);
    --
    -- dato de solicitud de 
    CURSOR c_datos IS
      SELECT doc.dato_json.access_token, doc.dato_json.codigo
        FROM x2000008_web doc
       WHERE doc.process_id = g_process_id;
    -- 
  BEGIN
    --
    --
    OPEN c_datos;
    FETCH c_datos
      INTO g_typ_reg_l_mcp_001.access_token, g_typ_reg_l_mcp_001.codigo;
    l_ok := c_datos%FOUND;
    CLOSE c_datos;
    --
    p_resultado := l_ok;
    IF NOT l_ok THEN
      p_respuesta := 'NO HAY DATOS QUE PROCESAR!';
    ELSE
      --
      -- validamos que los datos tengan valores
      l_ok := (g_typ_reg_l_mcp_001.access_token IS NOT NULL AND
              g_typ_reg_l_mcp_001.codigo IS NOT NULL);
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
      g_sql_error := SQLERRM;
      --
      g_hay_error := TRUE;
      g_cod_error := '500';
      g_msg_error := 'No es posible Obtener los datos del tipo de JSON (' ||
                     em_k_ws_auto_inspeccion.K_TIP_LIST_MUNICIPIO || ')';
      --
  END p_l_mcp_001;
  --
  -- procesamos el tipo de JSON 'A-TIP-R01'
  PROCEDURE p_a_res_001(p_resultado OUT BOOLEAN, p_respuesta OUT VARCHAR2) IS
    --
    l_ok        BOOLEAN := FALSE;
    l_respuesta VARCHAR2(4000);
    --
    -- dato de comentarios 
    CURSOR c_datos_1 IS
      SELECT doc.dato_json.access_token,
             doc.dato_json.numeroCotizacion,
             doc.dato_json.resultado,
             doc.dato_json.comentarios
        FROM x2000008_web doc
       WHERE doc.process_id = g_process_id
         AND doc.tip_json = em_k_ws_auto_inspeccion.K_TIP_RESPUESTA;
    -- 
    -- dato de control          
    CURSOR c_datos_2 IS
      SELECT doc.dato_json.access_token,
             doc.dato_json.numeroCotizacion,
             ctrl.control
        FROM x2000008_web doc,
             json_table(dato_json,
                        '$.controlesTecnicos[*]'
                        COLUMNS(control VARCHAR2(80) PATH '$.control')) as ctrl
       WHERE doc.process_id = g_process_id
         AND doc.tip_json = em_k_ws_auto_inspeccion.K_TIP_RESPUESTA;
    --
  BEGIN
    --
    -- seccion de comentarios
    g_typ_reg_a_res_001 := NULL;
    FOR v IN c_datos_1 LOOP
      --
      l_ok := v.access_token IS NOT NULL;
      l_ok := v.numeroCotizacion IS NOT NULL AND l_ok;
      --
      EXIT WHEN NOT l_ok;
      --
      IF v.numeroCotizacion IS NOT NULL THEN
        l_ok := f_valida_cotizacion(p_num_cotizacion => v.numeroCotizacion,
                                    p_respuesta      => p_respuesta,
                                    p_resultado      => p_resultado);
        EXIT WHEN NOT l_ok;
      END IF;
      --
      g_typ_reg_a_res_001.access_token     := v.access_token;
      g_typ_reg_a_res_001.numeroCotizacion := v.numeroCotizacion;
      g_typ_reg_a_res_001.resultado        := v.resultado;
      g_typ_reg_a_res_001.comentarios      := v.comentarios;
      --
      g_tab_reg_respuestas.extend;
      g_tab_reg_respuestas(g_tab_reg_respuestas.count) := g_typ_reg_a_res_001;
      g_typ_reg_a_res_001 := NULL;
      l_ok := TRUE;
      --
    END LOOP;
    --
    IF l_ok THEN
      --
      -- seccion de control
      g_typ_reg_a_res_002 := NULL;
      FOR v IN c_datos_2 LOOP
        --
        g_typ_reg_a_res_002.access_token     := v.access_token;
        g_typ_reg_a_res_002.numeroCotizacion := v.numeroCotizacion;
        g_typ_reg_a_res_002.control          := v.control;
        --
        g_tab_reg_respuestas_ctrl.extend;
        g_tab_reg_respuestas_ctrl(g_tab_reg_respuestas_ctrl.count) := g_typ_reg_a_res_002;
        g_typ_reg_a_res_002 := NULL;
        l_ok := TRUE;
        --
      END LOOP;
    END IF;
    --
    p_resultado := l_ok;
    IF NOT l_ok THEN
      p_respuesta := 'NO HAY DATOS QUE PROCESAR! o DATOS INCORRECTOS';
      g_cod_error := 400;
      g_hay_error := TRUE;
    END IF;
    --
  EXCEPTION
    WHEN OTHERS THEN
      p_resultado := FALSE;
      p_respuesta := SQLERRM;
      g_sql_error := SQLERRM;
      --
      g_hay_error := TRUE;
      g_cod_error := '500';
      g_msg_error := 'No es posible Obtener los datos del tipo de JSON (' ||
                     em_k_ws_auto_inspeccion.K_TIP_RESPUESTA || ')';
      --
  END p_a_res_001;
  --
  -- procesamos el tipo de JSON 'A-ROT-001', Grabar roturas
  PROCEDURE p_a_rot_001(p_resultado OUT BOOLEAN, p_respuesta OUT VARCHAR2) IS
    --
    l_ok        BOOLEAN := FALSE;
    l_respuesta VARCHAR2(4000);
    -- 
    -- dato de detalles          
    CURSOR c_datos_2 IS
      SELECT doc.dato_json.access_token,
             det.numeroCotizacion,
             det.pieza,
             det.nivel_rotura,
             det.valor,
             det.byte_foto
        FROM x2000008_web doc,
             json_table(dato_json,
                        '$.detalles[*]'
                        COLUMNS(numeroCotizacion VARCHAR2(80) PATH
                                '$.numeroCotizacion',
                                pieza VARCHAR2(80) PATH '$.pieza',
                                nivel_rotura VARCHAR2(80) PATH '$.nivelDano',
                                valor VARCHAR2(80) PATH '$.valor',
                                byte_foto VARCHAR2(80) PATH '$.byteFoto')) AS det
       WHERE doc.process_id = g_process_id
         AND doc.tip_json = em_k_ws_auto_inspeccion.K_TIP_ACTUALIZAR_ROTURA;
    --
    --
  BEGIN
    --
    -- seccion de control
    g_typ_reg_a_rot_002 := NULL;
    FOR v IN c_datos_2 LOOP
      --
      IF v.numeroCotizacion IS NOT NULL THEN
        l_ok        := f_valida_cotizacion(p_num_cotizacion => v.numeroCotizacion,
                                           p_respuesta      => p_respuesta,
                                           p_resultado      => p_resultado);
        p_respuesta := 'X';
        EXIT WHEN NOT l_ok;
        p_respuesta := NULL;
      END IF;
      --
      g_typ_reg_a_rot_002.access_token     := v.access_token;
      g_typ_reg_a_rot_002.numeroCotizacion := v.numeroCotizacion;
      g_typ_reg_a_rot_002.nivelRotuta      := v.nivel_rotura;
      g_typ_reg_a_rot_002.pieza            := v.pieza;
      g_typ_reg_a_rot_002.valorRotura      := v.valor;
      g_typ_reg_a_rot_002.byteFoto         := v.byte_foto;
      --
      g_tab_reg_roturas_det.extend;
      g_tab_reg_roturas_det(g_tab_reg_roturas_det.count) := g_typ_reg_a_rot_002;
      g_typ_reg_a_rot_002 := NULL;
      l_ok := TRUE;
      --
    END LOOP;
    --
    p_resultado := l_ok;
    IF NOT l_ok THEN
      IF p_respuesta = 'X' THEN
        p_respuesta := 'Poliza no fue Encontrada!';
      ELSE
        p_respuesta := 'NO HAY DATOS QUE PROCESAR!';
      END IF;
    END IF;
    --
  EXCEPTION
    WHEN OTHERS THEN
      p_resultado := FALSE;
      p_respuesta := SQLERRM;
      g_sql_error := SQLERRM;
      --
      g_hay_error := TRUE;
      g_cod_error := '500';
      g_msg_error := 'No es posible Obtener los datos del tipo de JSON (' ||
                     em_k_ws_auto_inspeccion.K_TIP_ACTUALIZAR_ROTURA || ')';
      --
  END p_a_rot_001;
  --
  -- procesamos el tipo de JSON 'A-ACC-001', Grabar accesorios
  PROCEDURE p_a_acc_001(p_resultado OUT BOOLEAN, p_respuesta OUT VARCHAR2) IS
    --
    l_ok        BOOLEAN := FALSE;
    l_respuesta VARCHAR2(4000);
    -- 
    -- dato de detalles          
    CURSOR c_datos_2 IS
      SELECT doc.dato_json.access_token,
             det.numeroCotizacion,
             det.marca,
             det.referencia,
             det.valor_accesorio,
             det.byte_foto
        FROM x2000008_web doc,
             json_table(dato_json,
                        '$.detalles[*]'
                        COLUMNS(numeroCotizacion VARCHAR2(80) PATH
                                '$.numeroCotizacion',
                                marca VARCHAR2(80) PATH '$.marca',
                                referencia VARCHAR2(80) PATH '$.referencia',
                                valor_accesorio VARCHAR2(80) PATH '$.valor',
                                byte_foto VARCHAR2(80) PATH '$.byteFoto')) AS det
       WHERE doc.process_id = g_process_id
         AND doc.tip_json =
             em_k_ws_auto_inspeccion.K_TIP_ACTUALIZAR_ACCESORIOS;
    --
    --
  BEGIN
    --
    -- seccion de control
    g_typ_reg_a_acc_002 := NULL;
    FOR v IN c_datos_2 LOOP
      --
      IF v.numeroCotizacion IS NOT NULL THEN
        l_ok        := f_valida_cotizacion(p_num_cotizacion => v.numeroCotizacion,
                                           p_respuesta      => p_respuesta,
                                           p_resultado      => p_resultado);
        p_respuesta := 'X';
        EXIT WHEN NOT l_ok;
        p_respuesta := NULL;
      END IF;
      --
      g_typ_reg_a_acc_002.access_token     := v.access_token;
      g_typ_reg_a_acc_002.numeroCotizacion := v.numeroCotizacion;
      g_typ_reg_a_acc_002.marca            := v.marca;
      g_typ_reg_a_acc_002.referencia       := v.referencia;
      g_typ_reg_a_acc_002.valorAccesorio   := v.valor_accesorio;
      g_typ_reg_a_acc_002.byteFoto         := v.byte_foto;
      --
      g_tab_reg_accesorios_det.extend;
      g_tab_reg_accesorios_det(g_tab_reg_accesorios_det.count) := g_typ_reg_a_acc_002;
      g_typ_reg_a_acc_002 := NULL;
      l_ok := TRUE;
      --
    END LOOP;
    --
    p_resultado := l_ok;
    IF NOT l_ok THEN
      IF p_respuesta = 'X' THEN
        p_respuesta := 'Poliza no fue Encontrada!';
      ELSE
        p_respuesta := 'NO HAY DATOS QUE PROCESAR!';
      END IF;
    END IF;
    --
  EXCEPTION
    WHEN OTHERS THEN
      p_resultado := FALSE;
      p_respuesta := SQLERRM;
      g_sql_error := SQLERRM;
      --
      g_hay_error := TRUE;
      g_cod_error := '500';
      g_msg_error := 'No es posible Obtener los datos del tipo de JSON (' ||
                     em_k_ws_auto_inspeccion.K_TIP_ACTUALIZAR_ACCESORIOS || ')';
      --
  END p_a_acc_001;
  --
  -- procesa el JSON
  PROCEDURE p_procesa_json(p_resultado OUT BOOLEAN,
                           p_respuesta OUT VARCHAR2) IS
    --
    l_session_id x2000008_web.session_id%TYPE;
    l_tip_json   x2000008_web.tip_json%TYPE;
    l_dato_json  x2000008_web.dato_json%TYPE;
    l_ok         BOOLEAN := FALSE;
    l_respuesta  VARCHAR2(4000);
    --
    -- datos almacenados
    CURSOR c_datos IS
      SELECT session_id, tip_json, dato_json
        FROM x2000008_web
       WHERE process_id = g_process_id;
    --
  BEGIN
    --
    -- recuperamos los datos
    OPEN c_datos;
    FETCH c_datos
      INTO l_session_id, l_tip_json, l_dato_json;
    l_ok := c_datos%FOUND;
    CLOSE c_datos;
    --
    -- comparamos los tipos de datos
    IF l_ok THEN
      --
      -- se valida el token
      l_ok := f_verificar_token(p_dato_json => l_dato_json,
                                p_respuesta => l_respuesta);
      --
      IF l_ok THEN
        IF l_tip_json = em_k_ws_auto_inspeccion.K_TIP_BUSCAR_COTIZACION THEN
          --
          -- buscar cotizacion
          p_b_cot_001(l_ok, l_respuesta);
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
          p_i_cot_001(l_ok, l_respuesta);
          p_resultado := l_ok;
          --
          IF NOT l_ok THEN
            p_respuesta := l_respuesta;
          ELSE
            p_respuesta := NULL;
          END IF;
          --
        ELSIF l_tip_json =
              em_k_ws_auto_inspeccion.K_TIP_ACTUALIZAR_COTIZACION THEN
          --
          -- actualiza cotizacion
          p_a_cot_001(l_ok, l_respuesta);
          p_resultado := l_ok;
          --
          IF NOT l_ok THEN
            p_respuesta := l_respuesta;
          ELSE
            p_respuesta := NULL;
          END IF;
          --
        ELSIF l_tip_json = em_k_ws_auto_inspeccion.K_TIP_ACTUALIZAR_FOTOS THEN
          --
          -- procesamos los datos de la fotografias
          p_a_fot_001(l_ok, l_respuesta);
          p_resultado := l_ok;
          IF NOT l_ok THEN
            p_respuesta := l_respuesta;
          ELSE
            p_respuesta := NULL;
          END IF;
          --
        ELSIF l_tip_json = em_k_ws_auto_inspeccion.K_TIP_LIST_MUNICIPIO THEN
          --
          -- lista municipio L-MCP-001
          p_l_mcp_001(l_ok, l_respuesta);
          p_resultado := l_ok;
          --
          IF NOT l_ok THEN
            p_respuesta := l_respuesta;
          ELSE
            p_respuesta := NULL;
          END IF;
          --  
        ELSIF l_tip_json =
              em_k_ws_auto_inspeccion.K_TIP_LIST_MARCA_VEHICULO THEN
          --
          -- lista de marcas
          p_resultado := TRUE;
          p_respuesta := NULL;
          --
        ELSIF l_tip_json = em_k_ws_auto_inspeccion.K_TIP_LIST_USO_VEHICULO THEN
          --
          -- lista de usos de vehiculos
          p_resultado := TRUE;
          p_respuesta := NULL;
          --  
        ELSIF l_tip_json = em_k_ws_auto_inspeccion.K_TIP_LIST_COLOR THEN
          --
          -- lista de colores
          p_resultado := TRUE;
          p_respuesta := NULL;
          -- 
        ELSIF l_tip_json = em_k_ws_auto_inspeccion.K_TIP_DOCUMENTO THEN
          --
          -- procesamos los datos de los documentos
          p_a_doc_001(l_ok, l_respuesta);
          p_resultado := l_ok;
          IF NOT l_ok THEN
            p_respuesta := l_respuesta;
          ELSE
            p_respuesta := NULL;
          END IF;
          --  
        ELSIF l_tip_json = em_k_ws_auto_inspeccion.K_TIP_RESPUESTA THEN
          --
          -- procesamos los datos de las respuestas
          p_a_res_001(l_ok, l_respuesta);
          p_resultado := l_ok;
          IF NOT l_ok THEN
            p_respuesta := l_respuesta;
          ELSE
            p_respuesta := NULL;
          END IF;
          -- 
        ELSIF l_tip_json = em_k_ws_auto_inspeccion.K_TIP_LIST_PIEZAS THEN
          -- 
          p_resultado := TRUE;
          p_respuesta := NULL;
          --
        ELSIF l_tip_json = em_k_ws_auto_inspeccion.K_TIP_LIST_DEPARTAMENTOS THEN
          -- 
          p_resultado := TRUE;
          p_respuesta := NULL;
          --
        ELSIF l_tip_json = em_k_ws_auto_inspeccion.K_TIP_LIST_LINEAS THEN
          -- 
          p_resultado := TRUE;
          p_respuesta := NULL;
          --
        ELSIF l_tip_json = em_k_ws_auto_inspeccion.K_TIP_ACTUALIZAR_ROTURA THEN
          --
          -- procesamos los datos de la roturas (danos)
          p_a_rot_001(l_ok, l_respuesta);
          p_resultado := l_ok;
          IF NOT l_ok THEN
            p_respuesta := l_respuesta;
          ELSE
            p_respuesta := NULL;
          END IF;
          --
        ELSIF l_tip_json =
              em_k_ws_auto_inspeccion.K_TIP_ACTUALIZAR_ACCESORIOS THEN
          --
          -- procesamos los datos de la accesorios
          p_a_acc_001(l_ok, l_respuesta);
          p_resultado := l_ok;
          IF NOT l_ok THEN
            p_respuesta := l_respuesta;
          ELSE
            p_respuesta := NULL;
          END IF;
        END IF;
      ELSE
        p_resultado := l_ok;
        p_respuesta := l_respuesta;
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
      g_sql_error := SQLERRM;
      --
      g_hay_error := TRUE;
      g_cod_error := '500';
      g_msg_error := 'Error al procesar el JSON';
      --  
  END p_procesa_json;
  --
  -- procesar JSON
  FUNCTION f_valida_json(p_cod_cia    IN x2000008_web.cod_cia%TYPE,
                         p_session_id IN x2000008_web.session_id%TYPE,
                         p_url        IN x2000008_web.url%TYPE,
                         p_tip_json   IN x2000008_web.tip_json%TYPE,
                         p_dato_json  IN CLOB,
                         p_respuesta  OUT VARCHAR2) RETURN BOOLEAN IS
    --
    l_ok        BOOLEAN := FALSE;
    l_respuesta VARCHAR2(4000);
    --
  BEGIN
  
    dbms_output.put_line(p_dato_json);
    --
    IF p_dato_json IS NOT NULL THEN
      --
      -- se inserta los datos en la tabla de tratamiento JSON
      p_inserta_x2000008_web(p_cod_cia    => p_cod_cia,
                             p_session_id => p_session_id,
                             p_url        => p_url,
                             p_tip_json   => p_tip_json,
                             p_dato_json  => p_dato_json,
                             p_resultado  => l_ok,
                             p_respuesta  => l_respuesta);
      --
      IF NOT l_ok THEN
        p_respuesta := l_respuesta;
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
      g_hay_error := TRUE;
      g_cod_error := '500';
      g_msg_error := 'Imposible validar los datos JSON';
      g_sql_error := SQLERRM;
      RETURN FALSE;
      --        
  END f_valida_json;
  --
  -- agregar busqueda cotizacion cliente
  PROCEDURE p_agrega_busqueda_cotizacion(p_reg_cliente_cotizacion typ_reg_cliente_cotizacion) IS
  BEGIN
    --
    g_tab_busqueda_cotizacion.extend;
    g_tab_busqueda_cotizacion(g_tab_busqueda_cotizacion.count) := p_reg_cliente_cotizacion;
    --
  END p_agrega_busqueda_cotizacion;
  --
  -- selecciona el resultado de la busqueda
  PROCEDURE p_seleccion_cotizacion IS
    --
    c_datos gc_ref_cursor;
    --
    l_num_cotizacion  p2000030.num_poliza%TYPE;
    l_fec_validez     p2000030.fec_validez%TYPE;
    l_fec_efec_poliza p2000030.fec_efec_poliza%TYPE;
    l_fec_vcto_poliza p2000030.fec_vcto_poliza%TYPE;
    l_tip_docum       p2000030.tip_docum%TYPE;
    l_cod_docum       p2000030.cod_docum%TYPE;
    l_num_placa       p2000020.val_campo%TYPE;
    --
    l_stm        VARCHAR2(4000);
    l_stm_select VARCHAR2(256)  := 'SELECT a.num_poliza num_cotizacion, a.fec_validez, a.fec_efec_poliza, a.fec_vcto_poliza, a.tip_docum, a.cod_docum, b.val_campo num_placa';
    l_stm_fromA   VARCHAR2(100) := 'FROM p2000030 a, p2000020 b';
    l_stm_fromB   VARCHAR2(100) := 'FROM a2000030 a, a2000020 b';
    l_stm_where  VARCHAR2(128)  := 'WHERE a.cod_cia = ' || g_cod_cia ||
                                   ' and a.cod_ramo = ' || g_cod_ramo ||
                                   ' and b.cod_cia = a.cod_cia AND b.cod_ramo = a.cod_ramo AND b.num_poliza = a.num_poliza';
    l_stm_order  VARCHAR2(16) := 'ORDER BY 3 DESC';
    --
    l_encontrado BOOLEAN := FALSE;
    --
    PROCEDURE pp_obtener_datos IS 
    BEGIN 
        --
        -- se apertura el cursor para seleccionar los datos
        IF c_datos%ISOPEN THEN
          LOOP
            --
            FETCH c_datos
              INTO l_num_cotizacion, l_fec_validez, l_fec_efec_poliza, l_fec_vcto_poliza, l_tip_docum, l_cod_docum, l_num_placa;
            EXIT WHEN c_datos%NOTFOUND;
            g_reg_cliente_cotizacion.placa             := l_num_placa;
            g_reg_cliente_cotizacion.numeroCotizacion  := l_num_cotizacion;
            g_reg_cliente_cotizacion.poliza            := l_num_cotizacion;
            g_reg_cliente_cotizacion.identificacion    := l_cod_docum;
            g_reg_cliente_cotizacion.fechaEfectoPoliza := l_fec_efec_poliza;
            g_reg_cliente_cotizacion.fechaVctoPoliza   := l_fec_vcto_poliza;
            g_reg_cliente_cotizacion.TipDocum          := l_tip_docum;
            -- se agrega a la lista de datos
            p_agrega_busqueda_cotizacion(g_reg_cliente_cotizacion);
            l_encontrado := TRUE;
            --
          END LOOP;
          CLOSE c_datos;
          --
      END IF;
    END pp_obtener_datos;
    --
  BEGIN
    --
    l_stm := l_stm_select || ' ' || l_stm_fromA || ' ' || l_stm_where;
    --
    g_reg_cliente_cotizacion.access_token := g_access_token;
    g_reg_cliente_cotizacion.usuario      := g_usuario;
    g_reg_cliente_cotizacion.tip_usuario  := g_tip_usuario;
    --
    -- priva el numero de corizacion
    IF g_typ_reg_b_cot_001.identificacion IS NOT NULL AND
       g_typ_reg_b_cot_001.placa IS NOT NULL AND
       g_typ_reg_b_cot_001.numeroCotizacion IS NOT NULL THEN
      -- se busca por identificacion y placa y numero de cotizacion
      l_stm := l_stm ||
               ' AND b.cod_campo like :A AND a.cod_docum = :B AND b.val_campo = :C AND a.num_poliza = :D' || ' ' ||
               l_stm_order;
      OPEN c_datos FOR l_stm
        USING 'NUM_PLACA', g_typ_reg_b_cot_001.identificacion, g_typ_reg_b_cot_001.placa, g_typ_reg_b_cot_001.numeroCotizacion;
      --
    ELSIF g_typ_reg_b_cot_001.identificacion IS NOT NULL AND
          g_typ_reg_b_cot_001.placa IS NOT NULL THEN
      -- se busca por identificacion y placa
      l_stm := l_stm ||
               ' AND b.cod_campo like :A AND a.cod_docum = :B AND b.val_campo = :C' || ' ' ||
               l_stm_order;
      OPEN c_datos FOR l_stm
        USING 'NUM_PLACA', g_typ_reg_b_cot_001.identificacion, g_typ_reg_b_cot_001.placa;
      --
    ELSIF g_typ_reg_b_cot_001.numeroCotizacion IS NOT NULL THEN
      -- se busca por cotizacion
      l_stm := l_stm || ' AND b.cod_campo LIKE :A AND a.num_poliza = :B' || ' ' ||
               l_stm_order;
      OPEN c_datos FOR l_stm
        USING 'NUM_PLACA', g_typ_reg_b_cot_001.numeroCotizacion;
      --
    ELSIF g_typ_reg_b_cot_001.placa IS NOT NULL THEN
      -- se busca por placa
      l_stm := l_stm || ' AND b.cod_campo LIKE :A AND b.val_campo  = :B' || ' ' ||
               l_stm_order;
      OPEN c_datos FOR l_stm
        USING 'NUM_PLACA', g_typ_reg_b_cot_001.placa;
      --   
    ELSIF g_typ_reg_b_cot_001.identificacion IS NOT NULL THEN
      -- se busca por identificacion
      l_stm := l_stm || ' AND b.cod_campo LIKE :A AND a.cod_docum  = :B' || ' ' ||
               l_stm_order;
      OPEN c_datos FOR l_stm
        USING 'NUM_PLACA', g_typ_reg_b_cot_001.identificacion;
      --  
    END IF;
    --
    -- se apertura el cursor para seleccionar los datos
    pp_obtener_datos;
    --
    IF NOT l_encontrado AND g_typ_reg_b_cot_001.numeroCotizacion IS NULL THEN
        l_stm := l_stm_select || ' ' || l_stm_fromB || ' ' || l_stm_where;
        --
        IF g_typ_reg_b_cot_001.identificacion IS NOT NULL AND
          g_typ_reg_b_cot_001.placa IS NOT NULL THEN
          -- se busca por identificacion y placa
          l_stm := l_stm ||
                   ' AND b.cod_campo like :A AND a.cod_docum = :B AND b.val_campo = :C' || ' ' ||
                   l_stm_order;
          OPEN c_datos FOR l_stm
            USING 'NUM_PLACA', g_typ_reg_b_cot_001.identificacion, g_typ_reg_b_cot_001.placa;
          -- 
          pp_obtener_datos;
          --
        ELSIF g_typ_reg_b_cot_001.placa IS NOT NULL THEN
          -- se busca por placa
          l_stm := l_stm || ' AND b.cod_campo LIKE :A AND b.val_campo  = :B' || ' ' ||
                   l_stm_order;
          OPEN c_datos FOR l_stm
               USING 'NUM_PLACA', g_typ_reg_b_cot_001.placa;
          --
          pp_obtener_datos;
          -- 
        END IF;
        --
    END IF;
    --
  EXCEPTION
    WHEN OTHERS THEN
      g_hay_error := TRUE;
      g_cod_error := '500';
      g_msg_error := 'Error en la Seleccion de Cotizacion';
      g_sql_error := SQLERRM;
      --        
  END p_seleccion_cotizacion;
  --
  -- agregar informacion cotizacion cliente
  PROCEDURE p_agrega_info_cotizacion(p_reg_info_cotizacion typ_reg_info_cotizacion) IS
  BEGIN
    --
    g_tab_info_cotizacion.extend;
    g_tab_info_cotizacion(g_tab_info_cotizacion.count) := p_reg_info_cotizacion;
    --
  END p_agrega_info_cotizacion;
  --
  -- selecciona el resultado de la busqueda de la informacion
  PROCEDURE p_seleccion_info_cotizacion IS
    -- 
    l_k_origen CHAR(1);
    --
    CURSOR c_datos IS
      SELECT a.num_poliza num_cotizacion,
             a.fec_validez,
             a.fec_efec_poliza,
             a.fec_vcto_poliza,
             a.tip_docum,
             a.cod_docum,
             b.val_campo num_placa,
             c.val_campo || '-' || d.nom_marca marca,
             j.val_campo || '-' || j1.nom_modelo modelo,
             e.val_campo version,
             f.val_campo motor,
             g.val_campo chasis,
             h.val_campo || '-' || h1.nom_uso_vehi uso_vehiculo,
             i.val_campo || '-' || i1.nom_color color
        FROM p2000030 a,
             p2000020 b,
             p2000020 c,
             a2100400 d, -- marcas de vehiculos
             p2000020 e,
             p2000020 f,
             p2000020 g,
             p2000020 h,
             a2100200 h1, -- uso de vehiculos 
             p2000020 i,
             a2100800 i1, -- colores
             p2000020 j,
             a2100410 j1 -- modelos de vehiculos
       WHERE a.cod_cia = g_cod_cia
         AND a.cod_ramo = g_cod_ramo
         AND a.num_poliza = g_typ_reg_i_cot_001.numeroCotizacion
         AND b.cod_cia = a.cod_cia
         AND b.cod_ramo = a.cod_ramo
         AND b.num_poliza = a.num_poliza
         AND b.cod_campo = 'NUM_PLACA'
         AND c.cod_cia = a.cod_cia
         AND c.cod_ramo = a.cod_ramo
         AND c.num_poliza = a.num_poliza
         AND c.cod_campo = 'COD_MARCA'
         AND d.cod_cia = a.cod_cia
         AND d.cod_marca = c.val_campo
         AND e.cod_cia = a.cod_cia
         AND e.cod_ramo = a.cod_ramo
         AND e.num_poliza = a.num_poliza
         AND e.cod_campo = 'COD_ANO'
         AND f.cod_cia = a.cod_cia
         AND f.cod_ramo = a.cod_ramo
         AND f.num_poliza = a.num_poliza
         AND f.cod_campo = 'DES_MOTOR'
         AND g.cod_cia = a.cod_cia
         AND g.cod_ramo = a.cod_ramo
         AND g.num_poliza = a.num_poliza
         AND g.cod_campo = 'DES_CHASIS'
         AND h.cod_cia = a.cod_cia
         AND h.cod_ramo = a.cod_ramo
         AND h.num_poliza = a.num_poliza
         AND h.cod_campo = 'COD_USO'
         AND h1.cod_cia = h.cod_cia
         AND h1.cod_uso_vehi = h.val_campo
         AND i.cod_cia = a.cod_cia
         AND i.cod_ramo = a.cod_ramo
         AND i.num_poliza = a.num_poliza
         AND i.cod_campo = 'COD_COLOR'
         AND i1.cod_color = i.val_campo
         AND j.cod_cia = a.cod_cia
         AND j.cod_ramo = a.cod_ramo
         AND j.num_poliza = a.num_poliza
         AND j.cod_campo = 'COD_MODELO'
         AND j1.cod_cia = j.cod_cia
         AND j1.cod_marca = c.val_campo
         AND j1.cod_modelo = j.val_campo
       ORDER BY 3 DESC;
    --
    CURSOR c_info_tercero IS
      SELECT 'P' k_origen,
             a.nom_tercero nombres,
             a.ape1_tercero apellidoPaterno,
             a.ape2_tercero apellidoMaterno,
             a.tlf_numero telefono,
             a.email email,
             (SELECT c.nom_prov
                FROM a1000100 c
               WHERE c.cod_pais = a.cod_pais
                 AND c.cod_prov = a.cod_prov) ciudad,
             a.nom_domicilio1 || ' ' || nvl(a.nom_domicilio2, '') direccion
        FROM p1001331 a
       WHERE a.cod_cia = g_cod_cia
         AND a.tip_docum = g_reg_info_cotizacion.tipoDocumento
         AND a.cod_docum = g_reg_info_cotizacion.numDocumento
      UNION
      SELECT 'A' k_origen,
             a.nom_tercero nombres,
             a.ape1_tercero apellidoPaterno,
             a.ape2_tercero apellidoMaterno,
             b.tlf_numero telefono,
             b.email email,
             (SELECT c.nom_prov
                FROM a1000100 c
               WHERE c.cod_pais = b.cod_pais
                 AND c.cod_prov = b.cod_prov) ciudad,
             b.nom_domicilio1 || ' ' || nvl(b.nom_domicilio2, '') direccion
        FROM a1001399 a, a1001331 b
       WHERE a.cod_cia = b.cod_cia
         AND a.tip_docum = b.tip_docum
         AND a.cod_docum = b.cod_docum
         AND a.cod_cia = g_cod_cia
         AND a.tip_docum = g_reg_info_cotizacion.tipoDocumento
         AND a.cod_docum = g_reg_info_cotizacion.numDocumento;
    --
  BEGIN
    --
    FOR v IN c_datos LOOP
      --
      g_reg_info_cotizacion.tipoDocumento := v.tip_docum;
      g_reg_info_cotizacion.numDocumento  := v.cod_docum;
      --
      -- informacion del tercero
      OPEN c_info_tercero;
      FETCH c_info_tercero
        INTO l_k_origen, g_reg_info_cotizacion.nombres, g_reg_info_cotizacion.apellidoPaterno, g_reg_info_cotizacion.apellidoMaterno, g_reg_info_cotizacion.telefono, g_reg_info_cotizacion.email, g_reg_info_cotizacion.ciudad, g_reg_info_cotizacion.direccion;
      IF c_info_tercero%NOTFOUND THEN
        g_reg_info_cotizacion.nombres         := '';
        g_reg_info_cotizacion.apellidoPaterno := '';
        g_reg_info_cotizacion.apellidoMaterno := '';
        g_reg_info_cotizacion.telefono        := '';
        g_reg_info_cotizacion.email           := '';
        g_reg_info_cotizacion.ciudad          := '';
        g_reg_info_cotizacion.direccion       := '';
      END IF;
      CLOSE c_info_tercero;
      --    
      g_reg_info_cotizacion.placa   := v.num_placa;
      g_reg_info_cotizacion.marca   := v.marca;
      g_reg_info_cotizacion.linea   := '';
      g_reg_info_cotizacion.version := v.version;
      g_reg_info_cotizacion.modelo  := v.modelo;
      g_reg_info_cotizacion.codFase := '';
      g_reg_info_cotizacion.motor   := v.motor;
      g_reg_info_cotizacion.chasis  := v.chasis;
      g_reg_info_cotizacion.serie   := '';
      g_reg_info_cotizacion.uso     := v.uso_vehiculo;
      g_reg_info_cotizacion.color   := v.color;
      --
      p_agrega_info_cotizacion(g_reg_info_cotizacion);
      --
    END LOOP;
    -- 
  EXCEPTION
    WHEN OTHERS THEN
      g_hay_error := TRUE;
      g_cod_error := '500';
      g_msg_error := 'Error en la Seleccion de Informacion Cotizacion';
      g_sql_error := SQLERRM;
      --    
  END p_seleccion_info_cotizacion;
  --
  -- agregar informacion cotizacion cliente
  PROCEDURE p_agrega_reg_cotizacion(p_reg_cotizacion typ_reg_cotizacion) IS
  BEGIN
    --
    g_tab_reg_cotizacion.extend;
    g_tab_reg_cotizacion(g_tab_reg_cotizacion.count) := p_reg_cotizacion;
    --
  END p_agrega_reg_cotizacion;
  --
  -- proceso para actualizar la BD del registro de cotizacion
  PROCEDURE p_actualiza_reg_cotizacion IS
    -- 
    tabDatos typ_tab := typ_tab();
    v_index  VARCHAR2(20);
    --
    PROCEDURE pp_mapa_datos(p_registro typ_reg_a_cot_001) IS
    BEGIN
      --
      tabDatos('NUM_PLACA') := p_registro.placa;
      tabDatos('COD_MARCA') := p_registro.marca;
      tabDatos('COD_ANO') := p_registro.version;
      tabDatos('COD_MODELO') := p_registro.modelo;
      tabDatos('DES_MOTOR') := p_registro.motor;
      tabDatos('DES_CHASIS') := p_registro.chasis;
      tabDatos('COD_USO') := p_registro.uso;
      tabDatos('COD_COLOR') := p_registro.color;
      --
    END pp_mapa_datos;
    --
    PROCEDURE pp_inserta_p2000020_pwa(p_registro     typ_reg_a_cot_001,
                                      p_cod_campo    VARCHAR2,
                                      p_val_campo    VARCHAR2,
                                      p_tip_registro CHAR) IS
    BEGIN
      --
      INSERT INTO p2000020_PWA
        (cod_cia,
         num_poliza,
         num_spto,
         num_apli,
         num_spto_apli,
         num_riesgo,
         num_periodo,
         tip_nivel,
         cod_campo,
         val_campo,
         val_cor_campo,
         val_ant_campo,
         num_secu,
         txt_campo,
         mca_baja_riesgo,
         mca_vigente,
         mca_vigente_apli,
         cod_ramo,
         tip_subnivel,
         process_id,
         session_id,
         fec_transaccion,
         tip_registro)
        SELECT cod_cia,
               num_poliza,
               num_spto,
               num_apli,
               num_spto_apli,
               num_riesgo,
               num_periodo,
               tip_nivel,
               p_cod_campo,
               p_val_campo,
               NULL,
               val_campo,
               num_secu,
               txt_campo,
               mca_baja_riesgo,
               mca_vigente,
               mca_vigente_apli,
               cod_ramo,
               tip_subnivel,
               g_process_id,
               g_session_id,
               sysdate,
               p_tip_registro
          FROM p2000020
         WHERE cod_cia = g_cod_cia
           AND cod_ramo = g_cod_ramo
           AND num_poliza = p_registro.numeroCotizacion
           AND cod_campo = p_cod_campo;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
      WHEN OTHERS THEN
        g_hay_error := TRUE;
        g_msg_error := SQLERRM;
        --            
    END pp_inserta_p2000020_pwa;
    --
    PROCEDURE pp_actualiza_p2000020_pwa(p_registro typ_reg_a_cot_001) IS
      --
      CURSOR c_datos IS
        SELECT cod_cia,
               num_poliza,
               num_spto,
               num_apli,
               num_spto_apli,
               cod_campo,
               val_campo,
               val_ant_campo,
               tip_nivel,
               cod_ramo,
               val_cor_campo
          FROM p2000020_pwa
         WHERE cod_cia = g_cod_cia
           AND num_poliza = p_registro.numeroCotizacion
           AND process_id = g_process_id
           AND session_id = g_session_id;
    BEGIN
      --
      FOR v in c_datos LOOP
        --
        UPDATE p2000020
           SET val_campo = v.val_campo, val_cor_campo = v.val_cor_campo
         WHERE cod_cia = v.cod_cia
           AND cod_ramo = v.cod_ramo
           AND num_poliza = v.num_poliza
           AND num_spto = v.num_spto
           AND cod_campo = v.cod_campo
           AND val_Campo = v.val_ant_campo
           AND tip_nivel = v.tip_nivel;
        --
      END LOOP;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
      WHEN OTHERS THEN
        g_hay_error := TRUE;
        g_msg_error := SQLERRM;
        --            
    END pp_actualiza_p2000020_pwa;
    --                               
  BEGIN
    -- 
    -- mapeamos los datos para simplificar el proceso
    pp_mapa_datos(p_registro => g_typ_reg_a_cot_001);
    --
    -- copiamos el registro entrante en la tabla (p2000020_pwa)
    v_index := tabDatos.FIRST;
    WHILE (v_index IS NOT NULL) LOOP
      pp_inserta_p2000020_pwa(p_registro     => g_typ_reg_a_cot_001,
                              p_cod_campo    => v_index,
                              p_val_campo    => tabDatos(v_index),
                              p_tip_registro => 'N');
      v_index := tabDatos.NEXT(v_index);
    END LOOP;
    --
    pp_actualiza_p2000020_pwa(p_registro => g_typ_reg_a_cot_001);
    --
    -- copiamos el registro actual en (p2000020) y lo respaldamos en la tabla (p2000020_pwa)
  
    g_reg_cotizacion.numeroCotizacion := g_typ_reg_a_cot_001.numeroCotizacion;
    g_reg_cotizacion.placa            := g_typ_reg_a_cot_001.placa;
    g_reg_cotizacion.marca            := g_typ_reg_a_cot_001.marca;
    g_reg_cotizacion.linea            := g_typ_reg_a_cot_001.linea;
    g_reg_cotizacion.version          := g_typ_reg_a_cot_001.version;
    g_reg_cotizacion.modelo           := g_typ_reg_a_cot_001.modelo;
    g_reg_cotizacion.codFase          := g_typ_reg_a_cot_001.codFase;
    g_reg_cotizacion.motor            := g_typ_reg_a_cot_001.motor;
    g_reg_cotizacion.chasis           := g_typ_reg_a_cot_001.chasis;
    g_reg_cotizacion.serie            := g_typ_reg_a_cot_001.serie;
    g_reg_cotizacion.uso              := g_typ_reg_a_cot_001.uso;
    g_reg_cotizacion.color            := g_typ_reg_a_cot_001.color;
    --
    p_agrega_reg_cotizacion(g_reg_cotizacion);
    --
  END p_actualiza_reg_cotizacion;
  --
  -- proceso que guarda datos de las fotografias
  PROCEDURE p_inseta_reg_foto IS
    -- 
    tabDatos typ_tab := typ_tab();
    v_index  VARCHAR2(20);
    i        NUMBER := 0;
    --
    CURSOR c_datos IS
      SELECT * FROM TABLE(g_tab_reg_foto);
    --
    PROCEDURE pp_mapa_datos(p_registro typ_reg_a_fot_001) IS
    BEGIN
      --
      i := i + 1;
      tabDatos('TIPO_FOTO' || i) := p_registro.tipoFoto;
      tabDatos('BYTE_FOTO' || i) := substr(p_registro.byteFoto, 1, 80);
      --
    END pp_mapa_datos;
    --
    PROCEDURE pp_inserta_p2000020_pwa(p_registro     typ_reg_a_fot_001,
                                      p_cod_campo    VARCHAR2,
                                      p_val_campo    VARCHAR2,
                                      p_tip_registro CHAR,
                                      p_secuencia    NUMBER) IS
    BEGIN
      --
      INSERT INTO p2000020_PWA
        (cod_cia,
         num_poliza,
         num_spto,
         num_apli,
         num_spto_apli,
         num_riesgo,
         num_periodo,
         tip_nivel,
         cod_campo,
         val_campo,
         val_cor_campo,
         val_ant_campo,
         num_secu,
         txt_campo,
         mca_baja_riesgo,
         mca_vigente,
         mca_vigente_apli,
         cod_ramo,
         tip_subnivel,
         process_id,
         session_id,
         fec_transaccion,
         tip_registro)
        SELECT cod_cia,
               num_poliza,
               num_spto,
               num_apli,
               num_spto_apli,
               num_riesgo,
               num_periodo,
               tip_nivel,
               p_cod_campo,
               p_val_campo,
               NULL,
               val_campo,
               p_secuencia,
               txt_campo,
               mca_baja_riesgo,
               mca_vigente,
               mca_vigente_apli,
               cod_ramo,
               tip_subnivel,
               g_process_id,
               g_session_id,
               sysdate,
               p_tip_registro
          FROM p2000020
         WHERE cod_cia = g_cod_cia
           AND cod_ramo = g_cod_ramo
           AND num_poliza = p_registro.numeroCotizacion
           AND ROWNUM = 1;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
      WHEN OTHERS THEN
        g_hay_error := TRUE;
        g_msg_error := SQLERRM;
        --            
    END pp_inserta_p2000020_pwa;
    --      
  BEGIN
    --
    -- procesamos los datos de las fotos
    FOR v IN c_datos LOOP
      -- mapeamos los datos para simplificar el proceso
      tabDatos.delete;
      pp_mapa_datos(p_registro => v);
      --
      v_index := tabDatos.FIRST;
      WHILE (v_index IS NOT NULL) LOOP
        pp_inserta_p2000020_pwa(p_registro     => v,
                                p_cod_campo    => v_index,
                                p_val_campo    => tabDatos(v_index),
                                p_tip_registro => 'N',
                                p_secuencia    => i);
        v_index := tabDatos.NEXT(v_index);
      END LOOP;
    END LOOP;
    --
  END p_inseta_reg_foto;
  --
  -- proceso que guarda datos de los documentos
  PROCEDURE p_inseta_reg_documentos IS
    -- 
    tabDatos typ_tab := typ_tab();
    v_index  VARCHAR2(20);
    i        NUMBER := 0;
    --
    CURSOR c_datos IS
      SELECT * FROM TABLE(g_tab_reg_documentos);
    --
    PROCEDURE pp_mapa_datos(p_registro typ_reg_a_doc_001) IS
    BEGIN
      --
      i := i + 1;
      tabDatos('TIPO_DOCUMENTO' || i) := p_registro.tipoDocumento;
      tabDatos('BYTE_DOCFOTO' || i) := substr(p_registro.byteFoto, 1, 80);
      --
    END pp_mapa_datos;
    --
    PROCEDURE pp_inserta_p2000020_pwa(p_registro     typ_reg_a_fot_001,
                                      p_cod_campo    VARCHAR2,
                                      p_val_campo    VARCHAR2,
                                      p_tip_registro CHAR,
                                      p_secuencia    NUMBER) IS
    BEGIN
      --
      INSERT INTO p2000020_pwa
        (cod_cia,
         num_poliza,
         num_spto,
         num_apli,
         num_spto_apli,
         num_riesgo,
         num_periodo,
         tip_nivel,
         cod_campo,
         val_campo,
         val_cor_campo,
         val_ant_campo,
         num_secu,
         txt_campo,
         mca_baja_riesgo,
         mca_vigente,
         mca_vigente_apli,
         cod_ramo,
         tip_subnivel,
         process_id,
         session_id,
         fec_transaccion,
         tip_registro)
        SELECT cod_cia,
               num_poliza,
               num_spto,
               num_apli,
               num_spto_apli,
               num_riesgo,
               num_periodo,
               tip_nivel,
               p_cod_campo,
               p_val_campo,
               NULL,
               val_campo,
               p_secuencia,
               txt_campo,
               mca_baja_riesgo,
               mca_vigente,
               mca_vigente_apli,
               cod_ramo,
               tip_subnivel,
               g_process_id,
               g_session_id,
               sysdate,
               p_tip_registro
          FROM p2000020
         WHERE cod_cia = g_cod_cia
           AND cod_ramo = g_cod_ramo
           AND num_poliza = p_registro.numeroCotizacion
           AND ROWNUM = 1;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
      WHEN OTHERS THEN
        g_hay_error := TRUE;
        g_msg_error := SQLERRM;
        --            
    END pp_inserta_p2000020_pwa;
    --      
  BEGIN
    --
    -- procesamos los datos de las fotos
    FOR v IN c_datos LOOP
      -- mapeamos los datos para simplificar el proceso
      tabDatos.delete;
      pp_mapa_datos(p_registro => v);
      --
      v_index := tabDatos.FIRST;
      WHILE (v_index IS NOT NULL) LOOP
        pp_inserta_p2000020_pwa(p_registro     => v,
                                p_cod_campo    => v_index,
                                p_val_campo    => tabDatos(v_index),
                                p_tip_registro => 'N',
                                p_secuencia    => i);
        v_index := tabDatos.NEXT(v_index);
      END LOOP;
    END LOOP;
    --
  END p_inseta_reg_documentos;
  --
  -- proceso que guarda datos de los respuestas
  PROCEDURE p_inseta_reg_respuestas IS
    -- 
    tabDatos typ_tab := typ_tab();
    v_index  VARCHAR2(20);
    i        NUMBER := 0;
    --
    CURSOR c_datos_1 IS
      SELECT * FROM TABLE(g_tab_reg_respuestas);
    --
    CURSOR c_datos_2 IS
      SELECT * FROM TABLE(g_tab_reg_respuestas_ctrl);
    --
    PROCEDURE pp_mapa_datos_1(p_registro typ_reg_a_res_001) IS
    BEGIN
      --
      tabDatos('RESULTADO') := p_registro.resultado;
      tabDatos('COMENTARIOS') := substr(p_registro.comentarios, 1, 80);
      --
    END pp_mapa_datos_1;
    --
    PROCEDURE pp_mapa_datos_2(p_registro typ_reg_a_res_002) IS
    BEGIN
      --
      i := i + 1;
      tabDatos('CONTROL' || i) := substr(p_registro.control, 1, 80);
      --
    END pp_mapa_datos_2;
    --
    PROCEDURE pp_inserta_p2000020_pwa(p_nro_cotizacion VARCHAR2,
                                      p_cod_campo      VARCHAR2,
                                      p_val_campo      VARCHAR2,
                                      p_tip_registro   CHAR,
                                      p_secuencia      NUMBER) IS
    BEGIN
      --
      INSERT INTO p2000020_pwa
        (cod_cia,
         num_poliza,
         num_spto,
         num_apli,
         num_spto_apli,
         num_riesgo,
         num_periodo,
         tip_nivel,
         cod_campo,
         val_campo,
         val_cor_campo,
         val_ant_campo,
         num_secu,
         txt_campo,
         mca_baja_riesgo,
         mca_vigente,
         mca_vigente_apli,
         cod_ramo,
         tip_subnivel,
         process_id,
         session_id,
         fec_transaccion,
         tip_registro)
        SELECT cod_cia,
               num_poliza,
               num_spto,
               num_apli,
               num_spto_apli,
               num_riesgo,
               num_periodo,
               tip_nivel,
               p_cod_campo,
               p_val_campo,
               NULL,
               val_campo,
               p_secuencia,
               txt_campo,
               mca_baja_riesgo,
               mca_vigente,
               mca_vigente_apli,
               cod_ramo,
               tip_subnivel,
               g_process_id,
               g_session_id,
               sysdate,
               p_tip_registro
          FROM p2000020
         WHERE cod_cia = g_cod_cia
           AND cod_ramo = g_cod_ramo
           AND num_poliza = p_nro_cotizacion
           AND ROWNUM = 1;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
      WHEN OTHERS THEN
        g_hay_error := TRUE;
        g_msg_error := SQLERRM;
        --            
    END pp_inserta_p2000020_pwa;
    --      
  BEGIN
    --
    -- procesamos los datos de las respuestas
    FOR v IN c_datos_1 LOOP
      -- mapeamos los datos para simplificar el proceso
      tabDatos.delete;
      pp_mapa_datos_1(p_registro => v);
      --
      v_index := tabDatos.FIRST;
      WHILE (v_index IS NOT NULL) LOOP
        pp_inserta_p2000020_pwa(p_nro_cotizacion => v.numeroCotizacion,
                                p_cod_campo      => v_index,
                                p_val_campo      => tabDatos(v_index),
                                p_tip_registro   => 'N',
                                p_secuencia      => i);
        v_index := tabDatos.NEXT(v_index);
      END LOOP;
    END LOOP;
    --
    -- procesamos los datos de las respuestas/control
    i := 0;
    FOR v IN c_datos_2 LOOP
      -- mapeamos los datos para simplificar el proceso
      tabDatos.delete;
      pp_mapa_datos_2(p_registro => v);
      --
      v_index := tabDatos.FIRST;
      WHILE (v_index IS NOT NULL) LOOP
        pp_inserta_p2000020_pwa(p_nro_cotizacion => v.numeroCotizacion,
                                p_cod_campo      => v_index,
                                p_val_campo      => tabDatos(v_index),
                                p_tip_registro   => 'N',
                                p_secuencia      => i);
        v_index := tabDatos.NEXT(v_index);
      END LOOP;
    END LOOP;
    --
  END p_inseta_reg_respuestas;
  --
  -- proceso que guarda datos de las roturas de vehiculos
  PROCEDURE p_inseta_reg_rotura IS
    -- 
    tabDatos typ_tab := typ_tab();
    v_index  VARCHAR2(20);
    i        NUMBER := 0;
    --
    CURSOR c_datos_2 IS
      SELECT * FROM TABLE(g_tab_reg_roturas_det);
    --
    PROCEDURE pp_mapa_datos_2(p_registro typ_reg_a_rot_002) IS
    BEGIN
      --
      i := i + 1;
      tabDatos('PIEZA' || i) := substr(p_registro.pieza, 1, 80);
      tabDatos('NIVEL_ROTURA' || i) := substr(p_registro.nivelRotuta, 1, 80);
      tabDatos('VALOR_ROTURA' || i) := substr(p_registro.valorRotura, 1, 80);
      tabDatos('BYTE_FOTO' || i) := substr(p_registro.byteFoto, 1, 80);
      --
    END pp_mapa_datos_2;
    --
    PROCEDURE pp_inserta_p2000020_pwa(p_nro_cotizacion VARCHAR2,
                                      p_cod_campo      VARCHAR2,
                                      p_val_campo      VARCHAR2,
                                      p_tip_registro   CHAR,
                                      p_secuencia      NUMBER) IS
    BEGIN
      --
      INSERT INTO p2000020_pwa
        (cod_cia,
         num_poliza,
         num_spto,
         num_apli,
         num_spto_apli,
         num_riesgo,
         num_periodo,
         tip_nivel,
         cod_campo,
         val_campo,
         val_cor_campo,
         val_ant_campo,
         num_secu,
         txt_campo,
         mca_baja_riesgo,
         mca_vigente,
         mca_vigente_apli,
         cod_ramo,
         tip_subnivel,
         process_id,
         session_id,
         fec_transaccion,
         tip_registro)
        SELECT cod_cia,
               num_poliza,
               num_spto,
               num_apli,
               num_spto_apli,
               num_riesgo,
               num_periodo,
               tip_nivel,
               p_cod_campo,
               p_val_campo,
               NULL,
               val_campo,
               p_secuencia,
               txt_campo,
               mca_baja_riesgo,
               mca_vigente,
               mca_vigente_apli,
               cod_ramo,
               tip_subnivel,
               g_process_id,
               g_session_id,
               sysdate,
               p_tip_registro
          FROM p2000020
         WHERE cod_cia = g_cod_cia
           AND cod_ramo = g_cod_ramo
           AND num_poliza = p_nro_cotizacion
           AND ROWNUM = 1;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
      WHEN OTHERS THEN
        g_hay_error := TRUE;
        g_msg_error := SQLERRM;
        --            
    END pp_inserta_p2000020_pwa;
    --      
  BEGIN
    --
    -- procesamos los datos de las roturas/detalle
    FOR v IN c_datos_2 LOOP
      -- mapeamos los datos para simplificar el proceso
      tabDatos.delete;
      pp_mapa_datos_2(p_registro => v);
      --
      v_index := tabDatos.FIRST;
      WHILE (v_index IS NOT NULL) LOOP
        pp_inserta_p2000020_pwa(p_nro_cotizacion => v.numeroCotizacion,
                                p_cod_campo      => v_index,
                                p_val_campo      => tabDatos(v_index),
                                p_tip_registro   => 'N',
                                p_secuencia      => i);
        v_index := tabDatos.NEXT(v_index);
      END LOOP;
    END LOOP;
    --
  END p_inseta_reg_rotura;
  --
  -- proceso que guarda datos de los accesorios
  PROCEDURE p_inseta_reg_accesorios IS
    -- 
    tabDatos typ_tab := typ_tab();
    v_index  VARCHAR2(20);
    i        NUMBER := 0;
    --
    CURSOR c_datos_2 IS
      SELECT * FROM TABLE(g_tab_reg_accesorios_det);
    --
    PROCEDURE pp_mapa_datos_2(p_registro typ_reg_a_acc_002) IS
    BEGIN
      --
      i := i + 1;
      tabDatos('MARCA' || i) := substr(p_registro.marca, 1, 80);
      tabDatos('REFERENCIA' || i) := substr(p_registro.referencia, 1, 80);
      tabDatos('VALOR_ACCESORIO' || i) := substr(p_registro.valorAccesorio,
                                                 1,
                                                 80);
      tabDatos('BYTE_FOTO' || i) := substr(p_registro.byteFoto, 1, 80);
      --
    END pp_mapa_datos_2;
    --
    PROCEDURE pp_inserta_p2000020_pwa(p_nro_cotizacion VARCHAR2,
                                      p_cod_campo      VARCHAR2,
                                      p_val_campo      VARCHAR2,
                                      p_tip_registro   CHAR,
                                      p_secuencia      NUMBER) IS
    BEGIN
      --
      INSERT INTO p2000020_pwa
        (cod_cia,
         num_poliza,
         num_spto,
         num_apli,
         num_spto_apli,
         num_riesgo,
         num_periodo,
         tip_nivel,
         cod_campo,
         val_campo,
         val_cor_campo,
         val_ant_campo,
         num_secu,
         txt_campo,
         mca_baja_riesgo,
         mca_vigente,
         mca_vigente_apli,
         cod_ramo,
         tip_subnivel,
         process_id,
         session_id,
         fec_transaccion,
         tip_registro)
        SELECT cod_cia,
               num_poliza,
               num_spto,
               num_apli,
               num_spto_apli,
               num_riesgo,
               num_periodo,
               tip_nivel,
               p_cod_campo,
               p_val_campo,
               NULL,
               val_campo,
               p_secuencia,
               txt_campo,
               mca_baja_riesgo,
               mca_vigente,
               mca_vigente_apli,
               cod_ramo,
               tip_subnivel,
               g_process_id,
               g_session_id,
               sysdate,
               p_tip_registro
          FROM p2000020
         WHERE cod_cia = g_cod_cia
           AND cod_ramo = g_cod_ramo
           AND num_poliza = p_nro_cotizacion
           AND ROWNUM = 1;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
      WHEN OTHERS THEN
        g_hay_error := TRUE;
        g_msg_error := SQLERRM;
        --            
    END pp_inserta_p2000020_pwa;
    --      
  BEGIN
    --
    -- procesamos los datos de las roturas/detalle
    FOR v IN c_datos_2 LOOP
      -- mapeamos los datos para simplificar el proceso
      tabDatos.delete;
      pp_mapa_datos_2(p_registro => v);
      --
      v_index := tabDatos.FIRST;
      WHILE (v_index IS NOT NULL) LOOP
        pp_inserta_p2000020_pwa(p_nro_cotizacion => v.numeroCotizacion,
                                p_cod_campo      => v_index,
                                p_val_campo      => tabDatos(v_index),
                                p_tip_registro   => 'N',
                                p_secuencia      => i);
        v_index := tabDatos.NEXT(v_index);
      END LOOP;
    END LOOP;
    --
  END p_inseta_reg_accesorios;
  --
  -- agregar pieza a la lista
  PROCEDURE p_agrega_reg_pieza(p_reg_pieza typ_reg_lista_simple) IS
  BEGIN
    --
    g_tab_reg_pieza.extend;
    g_tab_reg_pieza(g_tab_reg_pieza.count) := p_reg_pieza;
    --
  END p_agrega_reg_pieza;
  --
  -- selecciona el resultado de la busqueda de las pienzas
  PROCEDURE p_selecciona_piezas_vehiculo IS
    --
    -- DATOS DE PRUEBAS
    CURSOR c_datos IS
      SELECT cod_sub_parte, nom_sub_parte
        FROM g7000605
       WHERE cod_cia = g_cod_cia
         AND tip_propiedad = 1
         AND cod_sub_parte BETWEEN 1700 AND 1800;
  BEGIN
    --
    FOR v IN c_datos LOOP
      g_reg_lista_simple.codigo      := v.cod_sub_parte;
      g_reg_lista_simple.descripcion := v.nom_sub_parte;
      p_agrega_reg_pieza(g_reg_lista_simple);
    END LOOP;
    --
  END p_selecciona_piezas_vehiculo;
  --
  -- agregar control tecnico a la lista
  PROCEDURE p_agrega_reg_ctrl_tecnico(p_reg_ctrl typ_reg_ctrl_tecnico) IS
  BEGIN
    --
    g_tab_reg_ctrl_tecnico.extend;
    g_tab_reg_ctrl_tecnico(g_tab_reg_ctrl_tecnico.count) := p_reg_ctrl;
    --
  END p_agrega_reg_ctrl_tecnico;
  --
  -- selecciona el resultado de la busqueda de las control tecnico
  PROCEDURE p_selecciona_ctrl_tecnico IS
  BEGIN
    --
    g_reg_ctrl_tecnico.nombreControl := 'CONTROL TECNICO 1';
    p_agrega_reg_ctrl_tecnico(g_reg_ctrl_tecnico);
    g_reg_ctrl_tecnico.nombreControl := 'CONTROL TECNICO 2';
    p_agrega_reg_ctrl_tecnico(g_reg_ctrl_tecnico);
    g_reg_ctrl_tecnico.nombreControl := 'CONTROL TECNICO 3';
    p_agrega_reg_ctrl_tecnico(g_reg_ctrl_tecnico);
    --
  END p_selecciona_ctrl_tecnico;
  --
  -- agregar reg simple
  PROCEDURE p_agrega_reg_simple(p_reg_simple      typ_reg_lista_simple,
                                p_tab_lsta_simple IN OUT typ_tab_reg_simple) IS
  BEGIN
    --
    p_tab_lsta_simple.extend;
    p_tab_lsta_simple(p_tab_lsta_simple.count) := p_reg_simple;
    --
  END p_agrega_reg_simple;
  --
  -- selecciona el resultado de la busqueda de las departamento
  PROCEDURE p_selecciona_lst_dpto IS
    --
    CURSOR c_datos IS
      SELECT cast(cod_estado AS VARCHAR2(128)) codigo,
             cast(nom_estado AS VARCHAR2(128)) descripcion
        FROM a1000104
       WHERE cod_pais = g_cod_pais;
    --
  BEGIN
    --
    g_reg_lista_simple := NULL;
    --
    FOR v IN c_datos LOOP
      --
      g_reg_lista_simple.codigo      := v.codigo;
      g_reg_lista_simple.descripcion := v.descripcion;
      --
      p_agrega_reg_simple(g_reg_lista_simple, g_tab_lista_dpto);
      --
    END LOOP;
    -- 
  EXCEPTION
    WHEN OTHERS THEN
      g_hay_error := TRUE;
      g_cod_error := '500';
      g_msg_error := 'Error en la Seleccion de Departamentos';
      g_sql_error := SQLERRM;
      -- 
  END p_selecciona_lst_dpto;
  --
  -- selecciona el resultado de la busqueda de las municipio
  PROCEDURE p_selecciona_lst_mpio IS
    --
    CURSOR c_datos IS
      SELECT cast(cod_prov AS VARCHAR2(128)) codigo,
             cast(nom_prov AS Varchar2(128)) descripcion
        FROM a1000100
       WHERE cod_pais = 'NIC'
         AND cod_estado = 1;--g_typ_reg_l_mcp_001.codigo;
    --
  BEGIN
    --
    g_reg_lista_simple := NULL;
  
    FOR v IN c_datos LOOP
      g_reg_lista_simple.codigo      := v.codigo;
      g_reg_lista_simple.descripcion := v.descripcion;
      p_agrega_reg_simple(g_reg_lista_simple, g_tab_lista_mpio);
    END LOOP;
    -- 
  EXCEPTION
    WHEN OTHERS THEN
      g_hay_error := TRUE;
      g_cod_error := '500';
      g_msg_error := 'Error en la Seleccion de Municipios';
      g_sql_error := SQLERRM;
      -- 
  END p_selecciona_lst_mpio;
  --
  -- selecciona el resultado de la busqueda de las marcas
  PROCEDURE p_selecciona_lst_marca IS
    --
    CURSOR c_datos IS
      SELECT cast(cod_marca AS VARCHAR2(128)) codigo,
             cast(nom_marca AS Varchar2(128)) descripcion
        FROM a2100400
       WHERE cod_cia = g_cod_cia
         AND mca_inh = 'N';
  BEGIN
    --
    g_reg_lista_simple := NULL;
    FOR v IN c_datos LOOP
      g_reg_lista_simple.codigo      := v.codigo;
      g_reg_lista_simple.descripcion := v.descripcion;
      p_agrega_reg_simple(g_reg_lista_simple, g_tab_lista_marca);
    END LOOP;
    -- 
  EXCEPTION
    WHEN OTHERS THEN
      g_hay_error := TRUE;
      g_cod_error := '500';
      g_msg_error := 'Error en la Seleccion de Marcas';
      g_sql_error := SQLERRM;
      --
  END p_selecciona_lst_marca;
  --
  -- selecciona el resultado de la busqueda de las lineas
  PROCEDURE p_selecciona_lst_lineas IS
  BEGIN
    --
    g_reg_lista_simple             := NULL;
    g_reg_lista_simple.codigo      := '1';
    g_reg_lista_simple.descripcion := 'LINEA #1';
    p_agrega_reg_simple(g_reg_lista_simple, g_tab_lista_lineas);
    g_reg_lista_simple.codigo      := '2';
    g_reg_lista_simple.descripcion := 'LINEA #2';
    p_agrega_reg_simple(g_reg_lista_simple, g_tab_lista_lineas);
    --
  END p_selecciona_lst_lineas;
  --
  -- selecciona el resultado de la busqueda de las usos
  PROCEDURE p_selecciona_lst_usos IS
    --
    CURSOR c_datos IS
      SELECT cast(cod_uso_vehi AS VARCHAR2(128)) codigo,
             cast(nom_uso_vehi AS Varchar2(128)) descripcion
        FROM a2100200
       WHERE cod_cia = g_cod_cia
         AND mca_inh = 'N';
  BEGIN
    --
    g_reg_lista_simple := NULL;
    FOR v IN c_datos LOOP
      g_reg_lista_simple.codigo      := v.codigo;
      g_reg_lista_simple.descripcion := v.descripcion;
      p_agrega_reg_simple(g_reg_lista_simple, g_tab_lista_usos);
    END LOOP;
    -- 
  EXCEPTION
    WHEN OTHERS THEN
      g_hay_error := TRUE;
      g_cod_error := '500';
      g_msg_error := 'Error en la Seleccion de Uso de Vehiculos';
      g_sql_error := SQLERRM;
      --
  END p_selecciona_lst_usos;
  --
  -- selecciona el resultado de la busqueda de las colores
  PROCEDURE p_selecciona_lst_colores IS
    --
    CURSOR c_datos IS
      SELECT cast(cod_color AS VARCHAR2(128)) codigo,
             cast(nom_color AS Varchar2(128)) descripcion
        FROM a2100800;
  BEGIN
    --
    g_reg_lista_simple := NULL;
    FOR v IN c_datos LOOP
      g_reg_lista_simple.codigo      := v.codigo;
      g_reg_lista_simple.descripcion := v.descripcion;
      p_agrega_reg_simple(g_reg_lista_simple, g_tab_lista_colores);
    END LOOP;
    -- 
  EXCEPTION
    WHEN OTHERS THEN
      g_hay_error := TRUE;
      g_cod_error := '500';
      g_msg_error := 'Error en la Seleccion de Colores';
      g_sql_error := SQLERRM;
      --
  END p_selecciona_lst_colores;
  --
  -- URLS   
  --
  -- login
  PROCEDURE p_login_ws(p_parametros IN CLOB,
                       p_token      OUT gc_ref_cursor,
                       p_mensaje    OUT VARCHAR2) IS
    --
    l_token   typ_reg_token;
    l_mensaje typ_reg_mensaje;
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
             cast((24 * 60 * 60) AS NUMBER(8)) expires_in,
             cast('OK' AS VARCHAR2(512)) txt_mensaje
        FROM dual;
    --
    p_mensaje := 'OK';
    --      
  END p_login_ws;
  -- 
  -- login
  PROCEDURE p_login_ws(p_parametros IN CLOB, p_token OUT gc_ref_cursor) IS
    --
    l_token       typ_reg_token;
    l_txt_mensaje VARCHAR2(512);
    --
    -- usuarios
    CURSOR c_usuario IS
      SELECT usuario_nombre, bloqueado
        FROM portal_web.t_usuario
       WHERE email = g_usuario
         AND upper(paswd_aut) = upper(g_password)
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
              CONNECT BY LEVEL <=
                         length(txt) - length(REPLACE(txt, '_', '')) - 1);
    --
    -- procedimiento para obtener usuario y clave
    FUNCTION fp_toma_usuario(pp_parametro CLOB) RETURN BOOLEAN IS
    BEGIN
      -- 
      dc_k_util_json_web.p_lee(json(pp_parametro));
      --
      g_usuario     := dc_k_util_json_web.f_get_value('Username');
      g_password    := dc_k_util_json_web.f_get_value('Password');
      g_tip_usuario := dc_k_util_json_web.f_get_value('grant_type');
      --
      RETURN(g_usuario IS NOT NULL AND g_password IS NOT NULL AND
             g_tip_usuario IS NOT NULL);
      --
    EXCEPTION
      WHEN OTHERS THEN
        --
        g_hay_error := TRUE;
        g_sql_error := SQLERRM;
        RETURN FALSE;
        --
    END fp_toma_usuario;
    --
    -- verificamos si el usuario existe
    FUNCTION fp_existe_usuario RETURN BOOLEAN IS
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
      FETCH c_usuario
        INTO g_usuario_nombre, g_bloqueado;
      l_existe := c_usuario%FOUND;
      CLOSE c_usuario;
      --
      RETURN(l_existe AND g_bloqueado = trn.NO);
      --
    EXCEPTION
      WHEN OTHERS THEN
        g_sql_error := SQLERRM;
        g_hay_error := TRUE;
        RETURN FALSE;
        --        
    END fp_existe_usuario;
    --
    -- registrar del usuario
    FUNCTION fp_registrar_usuario RETURN BOOLEAN IS
      --
      l_cantidad NUMBER;
      l_mca      NUMBER;
      l_mcantlm  CHAR(1) := 'N';
      l_dato_1   VARCHAR(200);
      l_dato_2   VARCHAR2(200);
      l_dato_3   VARCHAR2(200);
      --
      CURSOR c_cont_descomposicion IS
        SELECT COUNT(*)
          FROM (SELECT TRIM(substr(txt,
                                   instr(txt, '_', 1, LEVEL) + 1,
                                   instr(txt, '_', 1, LEVEL + 1) -
                                   instr(txt, '_', 1, LEVEL) - 1)) AS token
                  FROM (SELECT '_' || g_usuario_nombre || '_' AS txt
                          FROM dual)
                CONNECT BY LEVEL <=
                           length(txt) - length(REPLACE(txt, '_', '')) - 1);
      --
      --
      CURSOR c_agt_valido(pc_cod_cia a1001332.cod_cia%TYPE, pc_tip_docum a1001332.tip_docum%TYPE, pc_cod_docum a1001332.cod_docum%TYPE) IS
        SELECT cod_agt
          FROM a1001332 a, a1001390 b, a1001399 c
         WHERE a.cod_cia = pc_cod_cia
           AND nvl(a.mca_inh, 'N') = 'N'
           AND a.fec_validez =
               (SELECT MAX(b.fec_validez)
                  FROM a1001332 b
                 WHERE b.cod_cia = pc_cod_cia
                   AND b.cod_agt = a.cod_agt)
           AND b.cod_cia = c.cod_cia
           AND b.tip_docum = c.tip_docum
           AND b.cod_docum = c.cod_docum
           AND b.cod_cia = a.cod_cia
           AND b.cod_act_tercero = 2
           AND b.cod_tercero = a.cod_agt
           AND a.tip_docum = pc_tip_docum
           AND a.cod_docum = pc_cod_docum;
      --
      --         
      CURSOR c_sub_agt_valido(pc_cod_cia a1001332.cod_cia%TYPE, pc_tip_docum a1001332.tip_docum%TYPE, pc_cod_docum a1001332.cod_docum%TYPE) IS
        SELECT cod_agt
          FROM a1001337 a, a1001390 b, a1001399 c
         WHERE a.cod_cia = pc_cod_cia
           AND nvl(a.mca_inh, 'N') = 'N'
           AND a.fec_validez =
               (SELECT MAX(b.fec_validez)
                  FROM a1001337 b
                 WHERE b.cod_cia = pc_cod_cia
                   AND b.cod_emp_agt = a.cod_emp_agt)
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
      FETCH c_cont_descomposicion
        INTO l_cantidad;
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
        dbms_output.put_line('Datos -> (' || reg_c.rownum || ') ' ||
                             reg_c.dato);
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
          OPEN c_agt_valido(g_cod_cia, l_dato_2, l_dato_3);
          FETCH c_agt_valido
            INTO g_cod_agt;
          CLOSE c_agt_valido;
          --
        EXCEPTION
          WHEN OTHERS THEN
            g_cod_agt := NULL;
            dbms_output.put_line('Agente no fue encontrado: ' || l_dato_2 || ', ' ||
                                 l_dato_3);
            g_sql_error := SQLERRM;
            g_hay_error := TRUE;
            RETURN FALSE;
            --
        END;
        --
      ELSIF l_dato_1 = '37' THEN
        --
        BEGIN
          --
          OPEN c_sub_agt_valido(g_cod_cia, l_dato_2, l_dato_3);
          FETCH c_sub_agt_valido
            INTO g_cod_agt;
          CLOSE c_sub_agt_valido;
          --
        EXCEPTION
          WHEN OTHERS THEN
            g_cod_agt := NULL;
            dbms_output.put_line('Agente no fue encontrado: ' || l_dato_2 || ', ' ||
                                 l_dato_3);
            g_sql_error := SQLERRM;
            g_hay_error := TRUE;
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
        INSERT INTO portal_web.t_usuario_ws
          (cod_cia,
           usuario_nombre,
           login,
           logout,
           sessionid,
           mca_activa,
           cod_producto,
           cod_mon,
           fec_actu)
        VALUES
          (g_cod_cia,
           g_cod_agt,
           SYSDATE,
           NULL,
           g_access_token,
           trn.SI,
           NULL,
           NULL,
           SYSDATE);
        --
        IF SQL%ROWCOUNT = 1 THEN
          --
          -- Inactiva token anteriores
          UPDATE portal_web.t_usuario_ws
             SET mca_activa = 'N', logout = SYSDATE
           WHERE cod_cia = g_cod_cia
             AND usuario_nombre = g_cod_agt
             AND sessionid != g_access_token;
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
          g_sql_error := SQLERRM;
          g_hay_error := TRUE;
          RETURN FALSE;
          --        
      END;
      --
    END fp_registrar_usuario;
    --                
  BEGIN
    --
    l_txt_mensaje := '500';
    --
    -- validamos la entrada
    IF p_parametros IS NOT NULL THEN
      --
      -- determinamos usuario y contrasena en los parametros JSON
      IF fp_toma_usuario(p_parametros) THEN
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
    SELECT cast((24 * 60 * 60) AS NUMBER(8)) INTO g_expires_in FROM DUAL;
    --
    IF l_txt_mensaje = 'OK' THEN
      OPEN p_token FOR
        SELECT g_access_token access_token,
               g_tip_usuario token_type,
               g_expires_in expires_in,
               'OK' txt_mensaje
          FROM dual;
    ELSE
      OPEN p_token FOR
        SELECT NULL access_token,
               NULL token_type,
               NULL expires_in,
               cast(l_txt_mensaje AS VARCHAR2(512)) txt_mensaje
          FROM dual;
    END IF;
    --      
  END p_login_ws;
  --
  -- buscar cotizacion   
  PROCEDURE p_buscar_cotizacion_cliente(p_parametros IN CLOB,
                                        p_cotizacion OUT gc_ref_cursor,
                                        p_errores    OUT VARCHAR2) IS
    --
    l_ok        BOOLEAN := FALSE;
    l_respuesta VARCHAR2(4000);
    --                                   
  BEGIN
    --
    -- validamos el parametro de la solicitud
    l_ok := f_valida_json(p_cod_cia    => g_cod_cia,
                          p_session_id => g_session_id,
                          p_url        => '/api/apiexterno/autoinsp/buscarCotizacionesCliente',
                          p_tip_json   => em_k_ws_auto_inspeccion.K_TIP_BUSCAR_COTIZACION,
                          p_dato_json  => p_parametros,
                          p_respuesta  => l_respuesta);
    --                    
    -- verificamos el resultado
    IF l_ok THEN
      --
      p_procesa_json(l_ok, l_respuesta);
      --
      IF l_ok THEN
        --
        g_tab_busqueda_cotizacion.delete;
        p_seleccion_cotizacion;
        --
        p_actualiza_x2000008_web(p_cod_cia       => g_cod_cia,
                                 p_mca_valido    => 'S',
                                 p_txt_resultado => 'Proceso Exitoso!',
                                 p_resultado     => l_ok,
                                 p_respuesta     => l_respuesta);
        IF l_ok THEN
          --
          OPEN p_cotizacion FOR
            SELECT * FROM TABLE(g_tab_busqueda_cotizacion);
          --
          p_errores := 'OK';
          --
        ELSE
          p_errores := '500';
        END IF;
        -- 
      ELSE
        p_errores := '500';
        p_actualiza_x2000008_web(p_cod_cia       => g_cod_cia,
                                 p_mca_valido    => 'N',
                                 p_txt_resultado => l_respuesta,
                                 p_resultado     => l_ok,
                                 p_respuesta     => l_respuesta);
      END IF;
    ELSE
      p_errores := '500';
    END IF;
    --     
  EXCEPTION
    WHEN OTHERS THEN
      g_sql_error := SQLERRM;
      g_hay_error := TRUE;
      --        
  END p_buscar_cotizacion_cliente;
  --  
  -- devolvemos la informacion de la cotizacion (DETALLE)
  PROCEDURE p_informacion_cotizacion(p_parametros IN CLOB,
                                     p_cotizacion OUT gc_ref_cursor,
                                     p_errores    OUT VARCHAR2) IS
    --
    l_ok        BOOLEAN := FALSE;
    l_respuesta VARCHAR2(4000);
    --                                                
  BEGIN
    --
    -- validamos el parametro de la solicitud
    l_ok := f_valida_json(p_cod_cia    => g_cod_cia,
                          p_session_id => g_session_id,
                          p_url        => '/api/apiexterno/autoinsp/informacionCotizacion',
                          p_tip_json   => em_k_ws_auto_inspeccion.K_TIP_LEER_COTIZACION,
                          p_dato_json  => p_parametros,
                          p_respuesta  => l_respuesta);
    --                    
    -- verificamos el resultado
    IF l_ok THEN
      --
      p_procesa_json(l_ok, l_respuesta);
      --
      IF l_ok THEN
        --
        g_tab_info_cotizacion.delete;
        p_seleccion_info_cotizacion;
        --
        p_actualiza_x2000008_web(p_cod_cia       => g_cod_cia,
                                 p_mca_valido    => 'S',
                                 p_txt_resultado => 'Proceso Exitoso!',
                                 p_resultado     => l_ok,
                                 p_respuesta     => l_respuesta);
        -- 
        IF l_ok THEN
          OPEN p_cotizacion FOR
            SELECT * FROM TABLE(g_tab_info_cotizacion);
          --
          p_errores := 'OK';
          --
        ELSE
          p_errores := '500';
        END IF;
        --    
      ELSE
        p_errores := '400';
        p_actualiza_x2000008_web(p_cod_cia       => g_cod_cia,
                                 p_mca_valido    => 'N',
                                 p_txt_resultado => l_respuesta,
                                 p_resultado     => l_ok,
                                 p_respuesta     => l_respuesta);
      END IF;
      --      
    ELSE
      p_errores := '500';
    END IF;
    --     
  EXCEPTION
    WHEN OTHERS THEN
      g_sql_error := SQLERRM;
      g_hay_error := TRUE;
      --  
  END p_informacion_cotizacion;
  --  
  -- actualizar datos
  PROCEDURE p_actualiza_cotizacion(p_parametros IN CLOB,
                                   p_errores    OUT VARCHAR2) IS
    --
    l_ok        BOOLEAN := FALSE;
    l_respuesta VARCHAR2(4000);
    --                              
  BEGIN
    --
    -- validamos el parametro de la solicitud
    l_ok := f_valida_json(p_cod_cia    => g_cod_cia,
                          p_session_id => g_session_id,
                          p_url        => '/api/apiexterno/autoinsp/actualizarDatos',
                          p_tip_json   => em_k_ws_auto_inspeccion.K_TIP_ACTUALIZAR_COTIZACION,
                          p_dato_json  => p_parametros,
                          p_respuesta  => l_respuesta);
    --                    
    -- verificamos el resultado
    IF l_ok THEN
      --
      p_procesa_json(l_ok, l_respuesta);
      --   
      IF l_ok THEN
        --                    
        g_tab_reg_cotizacion.delete;
        p_actualiza_reg_cotizacion;
        --
        p_actualiza_x2000008_web(p_cod_cia       => g_cod_cia,
                                 p_mca_valido    => 'S',
                                 p_txt_resultado => 'Proceso Exitoso!',
                                 p_resultado     => l_ok,
                                 p_respuesta     => l_respuesta);
        --
        IF l_ok THEN
          p_errores := 'OK';
        ELSE
          p_errores := '500';
        END IF;
        --
      ELSE
        p_errores := '400';
        p_actualiza_x2000008_web(p_cod_cia       => g_cod_cia,
                                 p_mca_valido    => 'N',
                                 p_txt_resultado => l_respuesta,
                                 p_resultado     => l_ok,
                                 p_respuesta     => l_respuesta);
      END IF;
    ELSE
      p_errores := '500';
    END IF;
    --        
  EXCEPTION
    WHEN OTHERS THEN
      p_errores   := '500';
      g_sql_error := SQLERRM;
      g_hay_error := TRUE;
      --
  END p_actualiza_cotizacion;
  --
  -- incluir foto del vehiculo      
  PROCEDURE p_graba_foto_vehiculo(p_parametros IN CLOB,
                                  p_errores    OUT VARCHAR2) IS
    --
    l_ok        BOOLEAN := FALSE;
    l_respuesta VARCHAR2(4000);
    --                                     
  BEGIN
    --
    -- validamos el parametro de la solicitud
    l_ok := f_valida_json(p_cod_cia    => g_cod_cia,
                          p_session_id => g_session_id,
                          p_url        => '/api/apiexterno/autoinsp/fotosVehiculo ',
                          p_tip_json   => em_k_ws_auto_inspeccion.K_TIP_ACTUALIZAR_FOTOS,
                          p_dato_json  => p_parametros,
                          p_respuesta  => l_respuesta);
  
    --                    
    -- verificamos el resultado
    IF l_ok THEN
      --
      p_procesa_json(l_ok, l_respuesta);
      --
      IF l_ok THEN
        --
        p_inseta_reg_foto;
        --
        p_actualiza_x2000008_web(p_cod_cia       => g_cod_cia,
                                 p_mca_valido    => 'S',
                                 p_txt_resultado => 'Proceso Exitoso!',
                                 p_resultado     => l_ok,
                                 p_respuesta     => l_respuesta);
        --
        IF l_ok THEN
          p_errores := 'OK';
        ELSE
          p_errores := '500';
        END IF;
        --   
      ELSE
        p_errores := '400';
        p_actualiza_x2000008_web(p_cod_cia       => g_cod_cia,
                                 p_mca_valido    => 'S',
                                 p_txt_resultado => l_respuesta,
                                 p_resultado     => l_ok,
                                 p_respuesta     => l_respuesta);
      END IF;
      --  
    ELSE
      p_errores := '400';
      p_actualiza_x2000008_web(p_cod_cia       => g_cod_cia,
                               p_mca_valido    => 'S',
                               p_txt_resultado => l_respuesta,
                               p_resultado     => l_ok,
                               p_respuesta     => l_respuesta);
    END IF;
    --
  END p_graba_foto_vehiculo;
  --
  --  lista piezas  
  PROCEDURE p_lista_piezas(p_parametros IN CLOB,
                           p_piezas     OUT gc_ref_cursor,
                           p_errores    OUT VARCHAR2) IS
    --
    l_ok        BOOLEAN := FALSE;
    l_respuesta VARCHAR2(4000);
    --                                
  BEGIN
    --
    ptraza('p_lista_piezas','w','INICIO');
    -- validamos el parametro de la solicitud
    l_ok := f_valida_json(p_cod_cia    => g_cod_cia,
                          p_session_id => g_session_id,
                          p_url        => '/api/apiexterno/autoinsp/listaPiezas ',
                          p_tip_json   => em_k_ws_auto_inspeccion.K_TIP_LIST_PIEZAS,
                          p_dato_json  => p_parametros,
                          p_respuesta  => l_respuesta);
    -- verificamos el resultado
    ptraza('p_lista_piezas','a','l_respuesta '||l_respuesta);
    l_ok := TRUE;
    --
    IF l_ok THEN
      --
      ptraza('p_lista_piezas','a','OK 1');
      p_procesa_json(l_ok, l_respuesta);
      --
      l_ok := TRUE;
      --
      IF l_ok THEN
        ptraza('p_lista_piezas','a','OK 2');
        g_tab_reg_pieza.delete;
        p_selecciona_piezas_vehiculo;
        --
        OPEN p_piezas FOR
          SELECT * FROM TABLE(g_tab_reg_pieza);
        --
        ptraza('p_lista_piezas','a','p_actualiza_x2000008_web');
        p_actualiza_x2000008_web(p_cod_cia       => g_cod_cia,
                                 p_mca_valido    => 'S',
                                 p_txt_resultado => 'Proceso Exitoso!',
                                 p_resultado     => l_ok,
                                 p_respuesta     => l_respuesta);
        --
        p_errores := 'OK';
        --
      ELSE
        ptraza('p_lista_piezas','a','Error 400');
        p_errores := '400';
        p_actualiza_x2000008_web(p_cod_cia       => g_cod_cia,
                                 p_mca_valido    => 'S',
                                 p_txt_resultado => l_respuesta,
                                 p_resultado     => l_ok,
                                 p_respuesta     => l_respuesta);
      END IF;
      --  
    ELSE
      --
      ptraza('p_lista_piezas','a','Error 500');
      p_errores := '500';
      --      
    END IF;
    --  
    ptraza('p_lista_piezas','a','FIN');  
    --
  END p_lista_piezas;
  --
  -- incluir danios a vehiculos      
  PROCEDURE p_graba_rotura_vehiculo(p_parametros IN CLOB,
                                    p_errores    OUT VARCHAR2) IS
    --
    l_ok        BOOLEAN := FALSE;
    l_respuesta VARCHAR2(4000);
    --                              
  BEGIN
    --
    -- validamos el parametro de la solicitud
    l_ok := f_valida_json(p_cod_cia    => g_cod_cia,
                          p_session_id => g_session_id,
                          p_url        => '/api/apiexterno/autoinsp/danosVehiculo ',
                          p_tip_json   => em_k_ws_auto_inspeccion.K_TIP_ACTUALIZAR_ROTURA,
                          p_dato_json  => p_parametros,
                          p_respuesta  => l_respuesta);
    --                    
    -- verificamos el resultado
    IF l_ok THEN
      --
      p_procesa_json(l_ok, l_respuesta);
      --
      IF l_ok THEN
        --
        p_inseta_reg_rotura;
        --
        p_actualiza_x2000008_web(p_cod_cia       => g_cod_cia,
                                 p_mca_valido    => 'S',
                                 p_txt_resultado => 'Proceso Exitoso!',
                                 p_resultado     => l_ok,
                                 p_respuesta     => l_respuesta);
        --
        IF l_ok THEN
          p_errores := 'OK';
        ELSE
          p_errores := '500';
        END IF;
        --
      ELSE
        p_errores := '400';
        p_actualiza_x2000008_web(p_cod_cia       => g_cod_cia,
                                 p_mca_valido    => 'S',
                                 p_txt_resultado => l_respuesta,
                                 p_resultado     => l_ok,
                                 p_respuesta     => l_respuesta);
      
      END IF;
    ELSE
      p_errores := '400';
      p_actualiza_x2000008_web(p_cod_cia       => g_cod_cia,
                               p_mca_valido    => 'S',
                               p_txt_resultado => l_respuesta,
                               p_resultado     => l_ok,
                               p_respuesta     => l_respuesta);
    END IF;
    --   
  END p_graba_rotura_vehiculo;
  --
  -- incluir accesorios a vehiculos           
  PROCEDURE p_graba_accesorio_vehiculo(p_parametros IN CLOB,
                                       p_errores    OUT VARCHAR2) IS
    --
    l_ok        BOOLEAN := FALSE;
    l_respuesta VARCHAR2(4000);
    --                              
  BEGIN
    --
    -- validamos el parametro de la solicitud
    l_ok := f_valida_json(p_cod_cia    => g_cod_cia,
                          p_session_id => g_session_id,
                          p_url        => '/api/apiexterno/autoinsp/accesoriosVehiculo ',
                          p_tip_json   => em_k_ws_auto_inspeccion.K_TIP_ACTUALIZAR_ACCESORIOS,
                          p_dato_json  => p_parametros,
                          p_respuesta  => l_respuesta);
    --                    
    -- verificamos el resultado
    IF l_ok THEN
      --
      p_procesa_json(l_ok, l_respuesta);
      --
      IF l_ok THEN
        --
        p_inseta_reg_accesorios;
        --
        p_actualiza_x2000008_web(p_cod_cia       => g_cod_cia,
                                 p_mca_valido    => 'S',
                                 p_txt_resultado => 'Proceso Exitoso!',
                                 p_resultado     => l_ok,
                                 p_respuesta     => l_respuesta);
        --
        IF l_ok THEN
          p_errores := 'OK';
        ELSE
          p_errores := '500';
        END IF;
        --
      ELSE
        p_errores := '400';
        p_actualiza_x2000008_web(p_cod_cia       => g_cod_cia,
                                 p_mca_valido    => 'S',
                                 p_txt_resultado => l_respuesta,
                                 p_resultado     => l_ok,
                                 p_respuesta     => l_respuesta);
      
      END IF;
    ELSE
      p_errores := '400';
      p_actualiza_x2000008_web(p_cod_cia       => g_cod_cia,
                               p_mca_valido    => 'S',
                               p_txt_resultado => l_respuesta,
                               p_resultado     => l_ok,
                               p_respuesta     => l_respuesta);
    END IF;
    --  
  END p_graba_accesorio_vehiculo;
  --
  -- incluir documentos asociados a vehiculos      
  PROCEDURE p_graba_documento_vehiculo(p_parametros IN CLOB,
                                       p_errores    OUT VARCHAR2) IS
    --
    l_ok        BOOLEAN := FALSE;
    l_respuesta VARCHAR2(4000);
    --                                  
  BEGIN
    --
    -- validamos el parametro de la solicitud
    l_ok := f_valida_json(p_cod_cia    => g_cod_cia,
                          p_session_id => g_session_id,
                          p_url        => '/api/apiexterno/autoinsp/documentacion ',
                          p_tip_json   => em_k_ws_auto_inspeccion.K_TIP_DOCUMENTO,
                          p_dato_json  => p_parametros,
                          p_respuesta  => l_respuesta);
    --                   
    -- verificamos el resultado
    IF l_ok THEN
      --
      p_procesa_json(l_ok, l_respuesta);
      --
      IF l_ok THEN
        --
        p_inseta_reg_documentos;
        --
        p_actualiza_x2000008_web(p_cod_cia       => g_cod_cia,
                                 p_mca_valido    => 'S',
                                 p_txt_resultado => 'Proceso Exitoso!',
                                 p_resultado     => l_ok,
                                 p_respuesta     => l_respuesta);
        --
        IF l_ok THEN
          p_errores := 'OK';
        ELSE
          p_errores := '500';
        END IF;
        --     
      ELSE
        p_errores := '400';
        p_actualiza_x2000008_web(p_cod_cia       => g_cod_cia,
                                 p_mca_valido    => 'S',
                                 p_txt_resultado => l_respuesta,
                                 p_resultado     => l_ok,
                                 p_respuesta     => l_respuesta);
      END IF;
      --  
    ELSE
      p_errores := '400';
      p_actualiza_x2000008_web(p_cod_cia       => g_cod_cia,
                               p_mca_valido    => 'S',
                               p_txt_resultado => l_respuesta,
                               p_resultado     => l_ok,
                               p_respuesta     => l_respuesta);
    END IF;
    --    
  END p_graba_documento_vehiculo;
  --
  --  lista controles tecnicos  
  PROCEDURE p_lista_ctrl_tecnico(p_parametros IN CLOB,
                                 p_ctrl_tec   OUT gc_ref_cursor,
                                 p_errores    OUT VARCHAR2) IS
  BEGIN
    --
    g_tab_reg_ctrl_tecnico.delete;
    p_selecciona_ctrl_tecnico;
    --
    OPEN p_ctrl_tec FOR
      SELECT * FROM TABLE(g_tab_reg_ctrl_tecnico);
    --
    p_errores := 'OK';
    --
  END p_lista_ctrl_tecnico;
  --  
  -- envio Respuesta
  PROCEDURE p_envio_respuesta(p_parametros IN CLOB, p_errores OUT VARCHAR2) IS
    --
    l_ok        BOOLEAN := FALSE;
    l_respuesta VARCHAR2(4000);
    --                                
  BEGIN
    --
    -- validamos el parametro de la solicitud
    l_ok := f_valida_json(p_cod_cia    => g_cod_cia,
                          p_session_id => g_session_id,
                          p_url        => '/api/apiexterno/autoinsp/envioRespuesta ',
                          p_tip_json   => em_k_ws_auto_inspeccion.K_TIP_RESPUESTA,
                          p_dato_json  => p_parametros,
                          p_respuesta  => l_respuesta);
    --                   
    -- verificamos el resultado
    IF l_ok THEN
      --
      p_procesa_json(l_ok, l_respuesta);
      --          
      IF l_ok THEN
        --       
        p_inseta_reg_respuestas;
        --
        p_actualiza_x2000008_web(p_cod_cia       => g_cod_cia,
                                 p_mca_valido    => 'S',
                                 p_txt_resultado => 'Proceso Exitoso!',
                                 p_resultado     => l_ok,
                                 p_respuesta     => l_respuesta);
        --
        IF l_ok THEN
          p_errores := 'OK';
        ELSE
          p_errores := '500';
        END IF;
        --     
        --
      ELSE
        p_errores := '400';
        p_actualiza_x2000008_web(p_cod_cia       => g_cod_cia,
                                 p_mca_valido    => 'S',
                                 p_txt_resultado => l_respuesta,
                                 p_resultado     => l_ok,
                                 p_respuesta     => l_respuesta);
      END IF;
      --
    ELSE
      p_errores := '400';
      p_actualiza_x2000008_web(p_cod_cia       => g_cod_cia,
                               p_mca_valido    => 'N',
                               p_txt_resultado => l_respuesta,
                               p_resultado     => l_ok,
                               p_respuesta     => l_respuesta);
    END IF;
    --
  END p_envio_respuesta;
  --
  --  lista listaDepartamentos  
  PROCEDURE p_lista_dpto(p_parametros   IN CLOB,
                         p_departaemtno OUT gc_ref_cursor,
                         p_errores      OUT VARCHAR2) IS
    --
    l_ok        BOOLEAN := FALSE;
    l_respuesta VARCHAR2(4000);
    --                   
  BEGIN
    --
    --
    -- validamos el parametro de la solicitud
    l_ok := f_valida_json(p_cod_cia    => g_cod_cia,
                          p_session_id => g_session_id,
                          p_url        => '/api/apiexterno/autoinsp/listaDepartamentos ',
                          p_tip_json   => em_k_ws_auto_inspeccion.K_TIP_LIST_DEPARTAMENTOS,
                          p_dato_json  => p_parametros,
                          p_respuesta  => l_respuesta);
    --  
    l_ok := TRUE;                  
    -- verificamos el resultado
    IF l_ok THEN
      --
      p_procesa_json(l_ok, l_respuesta);
      --  
      l_ok := TRUE;
      --   
      IF l_ok THEN
        g_tab_lista_dpto.delete;
        p_selecciona_lst_dpto;
        --
        p_actualiza_x2000008_web(p_cod_cia       => g_cod_cia,
                                 p_mca_valido    => 'S',
                                 p_txt_resultado => 'Proceso Exitoso!',
                                 p_resultado     => l_ok,
                                 p_respuesta     => l_respuesta);
        --
        l_ok := TRUE;
        IF l_ok THEN
          OPEN p_departaemtno FOR
            SELECT * FROM TABLE(g_tab_lista_dpto);
          --
          p_errores := 'OK';
        ELSE
          p_errores := '500';
        END IF;
      ELSE
        p_errores := '400';
      END IF;
    ELSE
      p_errores := '500';
    END IF;
    --
  END p_lista_dpto;
  --       
  --  lista Municipios  
  PROCEDURE p_lista_mpio(p_parametros IN CLOB,
                         p_mpio       OUT gc_ref_cursor,
                         p_errores    OUT VARCHAR2) IS
    --
    l_ok        BOOLEAN := FALSE;
    l_respuesta VARCHAR2(4000);
    --                
  BEGIN
    --
    ptraza('p_lista_mpio','w','INICIO');
    -- validamos el parametro de la solicitud
    l_ok := f_valida_json(p_cod_cia    => g_cod_cia,
                          p_session_id => g_session_id,
                          p_url        => '/api/apiexterno/autoinsp/listaMunicipios ',
                          p_tip_json   => em_k_ws_auto_inspeccion.K_TIP_LIST_MUNICIPIO,
                          p_dato_json  => p_parametros,
                          p_respuesta  => l_respuesta);
    --  
    ptraza('p_lista_mpio','a','l_respuesta '||l_respuesta);
    l_ok := TRUE;                  
    -- verificamos el resultado
    IF l_ok THEN
      --
      ptraza('p_lista_mpio','a','OK 1');
      p_procesa_json(l_ok, l_respuesta);
      l_ok := TRUE;
      --     
      IF l_ok THEN
        --
        ptraza('p_lista_mpio','a','OK 2');
        l_ok := TRUE;
        g_tab_lista_mpio.delete;
        p_selecciona_lst_mpio;
        --
        ptraza('p_lista_mpio','a','p_actualiza_x2000008_web');
        p_actualiza_x2000008_web(p_cod_cia       => g_cod_cia,
                                 p_mca_valido    => 'S',
                                 p_txt_resultado => 'Proceso Exitoso!',
                                 p_resultado     => l_ok,
                                 p_respuesta     => l_respuesta);
        --
        l_ok := TRUE;
        --
        IF l_ok THEN
          --
          OPEN p_mpio FOR
            SELECT * FROM TABLE(g_tab_lista_mpio);
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
    ptraza('p_lista_mpio','a','FIN');
  EXCEPTION
    WHEN OTHERS THEN
      ptraza('p_lista_mpio','a','Error '||sqlerrm);
      g_sql_error := SQLERRM;
      g_hay_error := TRUE;
      -- 
  END p_lista_mpio;
  --       
  --  lista Marcas  
  PROCEDURE p_lista_marcas(p_parametros IN CLOB,
                           p_marcas     OUT gc_ref_cursor,
                           p_errores    OUT VARCHAR2) IS
    --
    l_ok        BOOLEAN := FALSE;
    l_respuesta VARCHAR2(4000);
    --                  
  BEGIN
    --
    ptraza('p_lista_marcas','w','INICIO');
    -- validamos el parametro de la solicitud
    l_ok := f_valida_json(p_cod_cia    => g_cod_cia,
                          p_session_id => g_session_id,
                          p_url        => '/api/apiexterno/autoinsp/listaMarcas ',
                          p_tip_json   => em_k_ws_auto_inspeccion.K_TIP_LIST_MARCA_VEHICULO,
                          p_dato_json  => p_parametros,
                          p_respuesta  => l_respuesta);
    -- 
    l_ok := TRUE; 
    ptraza('p_lista_marcas','a','l_respuesta '||l_respuesta);                 
    -- verificamos el resultado
    IF l_ok THEN
      --
      ptraza('p_lista_marcas','a','OK 1');      
      p_procesa_json(l_ok, l_respuesta);
      -- 
      l_ok := TRUE;
      --
      IF l_ok THEN
        --
        ptraza('p_lista_marcas','a','OK 2');     
        g_tab_lista_marca.delete;
        p_selecciona_lst_marca;
        --
        ptraza('p_lista_marcas','a','p_actualiza_x2000008_web');     
        p_actualiza_x2000008_web(p_cod_cia       => g_cod_cia,
                                 p_mca_valido    => 'S',
                                 p_txt_resultado => 'Proceso Exitoso!',
                                 p_resultado     => l_ok,
                                 p_respuesta     => l_respuesta);
        --
        l_ok := TRUE;
        --
        IF l_ok THEN
          --
          OPEN p_marcas FOR
            SELECT * FROM TABLE(g_tab_lista_marca);
          --
          p_errores := 'OK';
          --
        ELSE
          ptraza('p_lista_marcas','a','errores 500');     
          p_errores := '500';
        END IF;
        -- 
      ELSE
        ptraza('p_lista_marcas','a','errores 400');     
        p_errores := '400';
      END IF;
      -- 
    ELSE
      ptraza('p_lista_marcas','a','errores 500');     
      p_errores := '500';
    END IF;
    --  
    ptraza('p_lista_marcas','a','FIN');     
    --   
  EXCEPTION
    WHEN OTHERS THEN
      ptraza('p_lista_marcas','a','Error '||sqlerrm);     
      g_sql_error := SQLERRM;
      g_hay_error := TRUE;
      --           
  END p_lista_marcas;
  --          
  --  lista Lineas  
  PROCEDURE p_lista_lineas(p_parametros IN CLOB,
                           p_lineas     OUT gc_ref_cursor,
                           p_errores    OUT VARCHAR2) IS
    --
    l_ok        BOOLEAN := FALSE;
    l_respuesta VARCHAR2(4000);
    --                    
  BEGIN
    --
    ptraza('p_lista_lineas','w','INICIO');
    -- validamos el parametro de la solicitud
    l_ok := f_valida_json(p_cod_cia    => g_cod_cia,
                          p_session_id => g_session_id,
                          p_url        => '/api/apiexterno/autoinsp/listaLineas ',
                          p_tip_json   => em_k_ws_auto_inspeccion.K_TIP_LIST_LINEAS,
                          p_dato_json  => p_parametros,
                          p_respuesta  => l_respuesta);
    -- verificamos el resultado
    ptraza('p_lista_lineas','a','l_respuesta '||l_respuesta);
    l_ok := TRUE;
    IF l_ok THEN
      --
      p_procesa_json(l_ok, l_respuesta);
      -- 
      l_ok := TRUE;
      --
      IF l_ok THEN
        l_ok := TRUE;
        g_tab_lista_lineas.delete;
        p_selecciona_lst_lineas;
        --
        ptraza('p_lista_lineas','a','p_actualiza_x2000008_web');
        p_actualiza_x2000008_web(p_cod_cia       => g_cod_cia,
                                 p_mca_valido    => 'S',
                                 p_txt_resultado => 'Proceso Exitoso!',
                                 p_resultado     => l_ok,
                                 p_respuesta     => l_respuesta);
        --
        l_ok := TRUE;
        --
        IF l_ok THEN
          OPEN p_lineas FOR
            SELECT * FROM TABLE(g_tab_lista_lineas);
          --
          p_errores := 'OK';
        ELSE
          ptraza('p_lista_lineas','a','500');
          p_errores := '500';
        END IF;
      ELSE
        ptraza('p_lista_lineas','a','400');
        p_errores := '400';
      END IF;
    ELSE
      ptraza('p_lista_lineas','a','500');
      p_errores := '500';
    END IF;
    --
    ptraza('p_lista_lineas','a','FIN');
    --
  END p_lista_lineas;
  --       
  --  lista usos  
  PROCEDURE p_lista_usos(p_parametros IN CLOB,
                         p_usos       OUT gc_ref_cursor,
                         p_errores    OUT VARCHAR2) IS
    --
    l_ok        BOOLEAN := FALSE;
    l_respuesta VARCHAR2(4000);
    -- 
  BEGIN
    --
    ptraza('p_lista_usos',
           'w',
           'INICIO g_cod_cia ' || g_cod_cia || ' g_session_id ' ||
           g_session_id);
    -- validamos el parametro de la solicitud
    l_ok := f_valida_json(p_cod_cia    => g_cod_cia,
                          p_session_id => g_session_id,
                          p_url        => '/api/apiexterno/autoinsp/listaUsos ',
                          p_tip_json   => em_k_ws_auto_inspeccion.K_TIP_LIST_USO_VEHICULO,
                          p_dato_json  => p_parametros,
                          p_respuesta  => l_respuesta);
    --
    ptraza('p_lista_usos', 'a', 'l_respuesta ' || l_respuesta);
    l_ok := TRUE;
    -- verificamos el resultado
    IF l_ok THEN
      --
      ptraza('p_lista_usos', 'a', 'OK 1');
      --                  
      p_procesa_json(l_ok, l_respuesta);
      --
      ptraza('p_lista_usos', 'a', '1');
      l_ok := TRUE;
      IF l_ok THEN
        --
        ptraza('p_lista_usos', 'a', 'OK 2');
        --
        g_tab_lista_usos.delete;
        p_selecciona_lst_usos;
        --
        ptraza('p_lista_usos', 'a', 'p_actualiza_x2000008_web');
        p_actualiza_x2000008_web(p_cod_cia       => g_cod_cia,
                                 p_mca_valido    => 'S',
                                 p_txt_resultado => 'Proceso Exitoso!',
                                 p_resultado     => l_ok,
                                 p_respuesta     => l_respuesta);
        --
        IF l_ok THEN
          ptraza('p_lista_usos', 'a', 'OK 3');
          --
          OPEN p_usos FOR
            SELECT * FROM TABLE(g_tab_lista_usos);
          --
          p_errores := 'OK';
          -- 
        ELSE
          ptraza('p_lista_usos', 'a', 'Errores 500');
          p_errores := '500';
        END IF;
        -- 
      ELSE
        ptraza('p_lista_usos', 'a', 'Errores 400');
        p_errores := '400';
      END IF;
      -- 
    ELSE
      ptraza('p_lista_usos', 'a', 'Errores 500 1');
      p_errores := '500';
    END IF;
    --     
    ptraza('p_lista_usos', 'a', 'FIN');
    --
  EXCEPTION
    WHEN OTHERS THEN
      ptraza('p_lista_usos', 'a', 'Error general ' || sqlerrm);
      g_sql_error := SQLERRM;
      g_hay_error := TRUE;
      --       
  END p_lista_usos;
  --       
  --  lista colores 
  PROCEDURE p_lista_colores(p_parametros IN CLOB,
                            p_colores    OUT gc_ref_cursor,
                            p_errores    OUT VARCHAR2) IS
    --
    l_ok        BOOLEAN := FALSE;
    l_respuesta VARCHAR2(4000);
    --                   
  BEGIN
    --
    ptraza('p_lista_colores',
           'w',
           'INICIO g_cod_cia ' || g_cod_cia || ' g_session_id ' ||
           g_session_id);
    -- validamos el parametro de la solicitud
    l_ok := f_valida_json(p_cod_cia    => g_cod_cia,
                          p_session_id => g_session_id,
                          p_url        => '/api/apiexterno/autoinsp/listaColores ',
                          p_tip_json   => em_k_ws_auto_inspeccion.K_TIP_LIST_COLOR,
                          p_dato_json  => p_parametros,
                          p_respuesta  => l_respuesta);
    -- 
    ptraza('p_lista_colores', 'a', 'l_respuesta ' || l_respuesta);
    -- verificamos el resultado
    IF l_ok THEN
      --
      ptraza('p_lista_colores', 'a', 'OK 1 ');
      p_procesa_json(l_ok, l_respuesta);
      --
      IF l_ok THEN
        --
        ptraza('p_lista_colores', 'a', 'OK 2 ');
        g_tab_lista_colores.delete;
        p_selecciona_lst_colores;
        --
        ptraza('p_lista_colores', 'a', 'p_actualiza_x2000008_web ');
        p_actualiza_x2000008_web(p_cod_cia       => g_cod_cia,
                                 p_mca_valido    => 'S',
                                 p_txt_resultado => 'Proceso Exitoso!',
                                 p_resultado     => l_ok,
                                 p_respuesta     => l_respuesta);
        --
        l_ok := TRUE;
        --
        IF l_ok THEN
          ptraza('p_lista_colores', 'a', 'OK 3 ');
          OPEN p_colores FOR
            SELECT * FROM TABLE(g_tab_lista_colores);
          --
          p_errores := 'OK';
          --  
        ELSE
          ptraza('p_lista_colores', 'a', 'Errores 500 ');
          p_errores := '500';
          p_actualiza_x2000008_web(p_cod_cia       => g_cod_cia,
                                   p_mca_valido    => 'S',
                                   p_txt_resultado => l_respuesta,
                                   p_resultado     => l_ok,
                                   p_respuesta     => l_respuesta);
        END IF;
        -- 
      ELSE
        ptraza('p_lista_colores', 'a', 'Errores 400 ');
        p_errores := '400';
        p_actualiza_x2000008_web(p_cod_cia       => g_cod_cia,
                                 p_mca_valido    => 'S',
                                 p_txt_resultado => l_respuesta,
                                 p_resultado     => l_ok,
                                 p_respuesta     => l_respuesta);
      END IF;
      -- 
    ELSE
      ptraza('p_lista_colores', 'a', 'OK 2 ');
      p_errores := '500';
      p_actualiza_x2000008_web(p_cod_cia       => g_cod_cia,
                               p_mca_valido    => 'N',
                               p_txt_resultado => l_respuesta,
                               p_resultado     => l_ok,
                               p_respuesta     => l_respuesta);
    END IF;
    --     
    ptraza('p_lista_colores', 'a', 'FIN');
    --
  EXCEPTION
    WHEN OTHERS THEN
      ptraza('p_lista_colores', 'a', 'Error ' || sqlerrm);
      g_sql_error := SQLERRM;
      g_hay_error := TRUE;
      --                  
  END p_lista_colores;
  --                                                                         
end em_k_ws_auto_inspeccion;
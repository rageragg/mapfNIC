create or replace PACKAGE BODY em_k_ws_microseguros_web IS

  /* -------------------------------------------------------------------
  -- Procedimientos y funciones para Web Services Cotizador Accidentes Personales
  */
  /* -------------------- VERSION = 1.00 -------------------------------
  -- CARRIERHOUSE - 01/09/2020
  -- CONSTRUCCION
  /* -------------------- MODIFICACIONES -------------------------------
  --
  --
  */ -------------------------------------------------------------------
  --
  g_k_producto_ap   CONSTANT VARCHAR2(2) := '1';
  g_k_producto_soa  CONSTANT VARCHAR2(2) := '2';
  g_k_producto_vida CONSTANT VARCHAR2(2) := '3';

  g_cod_idioma VARCHAR2(4) := 'ES';

  g_nom_archivo VARCHAR2(100) := 'ws_cotiza_acc_web';

  g_session_id VARCHAR2(100);

  g_cod_modulo g2000906_web.cod_modulo%TYPE := 'WS_COTIZADOR_ACC';

  g_cod_cia CONSTANT x2000000_web.val_campo%TYPE := 4;

  g_estatus_pendiente CONSTANT x2000001_web.cod_estatus%TYPE := 2;

  g_cod_usr CONSTANT x2000001_web.cod_usr%TYPE := 'USER_WEB';

  g_fec_actu CONSTANT x2000001_web.fec_actu%TYPE := TRUNC(SYSDATE);

  g_cod_agt VARCHAR2(20);
  g_cod_modalidad_soa  g2990004.cod_modalidad%TYPE := 8;
  g_cod_modalidad_acc  g2990004.cod_modalidad%TYPE := 71001;
  g_cod_modalidad_vida g2990004.cod_modalidad%TYPE := 13001;
  --
  g_num_duracion_poliza NUMBER := 12;
  g_tip_docum_aseg      a1001331.tip_docum%TYPE;
  g_tip_benef_aseg      a2000060.tip_benef%TYPE := 2;

  g_cod_docum_aseg a1001331.cod_docum%TYPE;

  g_cod_ramo_acc  a1001800.cod_ramo%TYPE := 710;
  g_cod_ramo_vida a1001800.cod_ramo%TYPE := 130;
  g_cod_ramo_soa  a1001800.cod_ramo%TYPE := 301;

  g_tab_mensajes table_mensajes := table_mensajes();

  g_fila INT := 0;

  g_reg_x2000001_web x2000001_web%ROWTYPE;

  g_mensaje_error_general VARCHAR2(200) := 'Servicio No Disponible. Favor comuniquese con una Oficina Comercial o entre a nuestr WEB para cotizar www.mapfre.com.ni';
  --
  g_dv_tercero strarray;
  --
  FUNCTION fl_eliminar_espacios(p_string IN CLOB, p_referencia IN VARCHAR2)
    RETURN CLOB IS
    --
    l_string  CLOB := p_string;
    l_ini_chr INTEGER := 0;
    --
  BEGIN
    --
    l_ini_chr := instr(l_string, p_referencia);
    --
    WHILE (l_ini_chr > 0) LOOP
      --
      l_string := REPLACE(l_string, p_referencia, TRIM(p_referencia));
      --
      l_ini_chr := instr(l_string, p_referencia);
      --
    END LOOP;
    --
    RETURN l_string;
    --
  END fl_eliminar_espacios;
  --
  FUNCTION fl_limpiar_json(p_json IN CLOB) RETURN CLOB IS
    --
    l_json CLOB := p_json;
    --
  BEGIN
    --
    l_json := REPLACE(REPLACE(REPLACE(REPLACE(l_json, chr(10), ''),
                                      chr(13),
                                      ''),
                              chr(9),
                              ''),
                      chr(27),
                      '');
    --
    l_json := fl_eliminar_espacios(l_json, '{ ');
    l_json := fl_eliminar_espacios(l_json, ' {');
    --
    l_json := fl_eliminar_espacios(l_json, '} ');
    l_json := fl_eliminar_espacios(l_json, ' }');
    --
    l_json := fl_eliminar_espacios(l_json, '[ ');
    l_json := fl_eliminar_espacios(l_json, ' [');
    --
    l_json := fl_eliminar_espacios(l_json, '] ');
    l_json := fl_eliminar_espacios(l_json, ' ]');
    --
    l_json := fl_eliminar_espacios(l_json, ' :');
    l_json := fl_eliminar_espacios(l_json, ': ');
    --
    l_json := fl_eliminar_espacios(l_json, ' ,');
    l_json := fl_eliminar_espacios(l_json, ', ');
    --
    RETURN l_json;
    --
  END fl_limpiar_json;
  --
  --
  FUNCTION fl_to_reg_x2000000_web(p_reg IN reg_x2000000_web)
    RETURN x2000000_web%ROWTYPE IS
    --
    l_reg x2000000_web%ROWTYPE;
    --
  BEGIN
    --
    l_reg.cod_cia        := p_reg.cod_cia;
    l_reg.num_cotizacion := p_reg.num_cotizacion;
    l_reg.num_riesgo     := p_reg.num_riesgo;
    l_reg.cod_campo      := p_reg.cod_campo;
    l_reg.num_secu       := p_reg.num_secu;
    l_reg.val_campo      := p_reg.val_campo;
    l_reg.txt_campo      := p_reg.txt_campo;
    l_reg.txt_campo1     := p_reg.txt_campo1;
    l_reg.txt_campo2     := p_reg.txt_campo2;
    --
    RETURN l_reg;
    --
  END fl_to_reg_x2000000_web;
  -- Funcion para validar si el token existe y esta vigente
  --
  FUNCTION f_valida_token(pp_token VARCHAR2) --portal_web.t_usuario_ws.sessionid%TYPE)
   RETURN VARCHAR2 IS
    --
    l_valida     VARCHAR2(1) := 'N';
    l_val_campo  g2000906_web.val_campo%TYPE;
    l_diff_horas NUMBER := NULL;
    --
  BEGIN
    --
    BEGIN
      --
      l_val_campo := ss_k_web.f_obtener_constante(g_cod_cia,
                                                  g_cod_modulo,
                                                  'TOKEN_TIME');
      --
    EXCEPTION
      WHEN OTHERS THEN
        --
        l_val_campo := NULL;
        --
    END;
    --
    SELECT 'S', 24 * (sysdate - login)
      INTO l_valida, l_diff_horas
      FROM portal_web.t_usuario_ws
     WHERE sessionid = pp_token
       AND mca_activa = 'S';
    --
    IF l_valida = 'S' AND l_diff_horas <= 8 THEN
      RETURN 'S';
    ELSE
      RETURN 'N';
    END IF;
    --
    SELECT 'S'
      INTO l_valida
      FROM portal_web.t_usuario_ws
     WHERE sessionid = pp_token
       AND mca_activa = 'S';
    --
    RETURN l_valida;
    --
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 'N';
  END f_valida_token;
  --
  FUNCTION f_table_mensajes RETURN table_mensajes
    PIPELINED IS
  BEGIN
    --
    IF g_tab_mensajes.COUNT > 0 THEN
      FOR fila IN g_tab_mensajes.FIRST .. g_tab_mensajes.LAST LOOP
        PIPE ROW(g_tab_mensajes(fila));
      END LOOP;
    END IF;
    --
    RETURN;
    --
  END f_table_mensajes;
  -- Retorna el Agente relacionado al TOKEN
  --
  FUNCTION f_valida_agt_token(pp_token VARCHAR2, pp_producto VARCHAR2) --portal_web.t_usuario_ws.sessionid%TYPE)
   RETURN VARCHAR2 IS
    --
    l_cod_agt VARCHAR2(20); --portal_web@portweb.t_usuario_ws.usuario_nombre%TYPE;
    --
  BEGIN
    --
    SELECT usuario_nombre
      INTO l_cod_agt
      FROM portal_web.t_usuario_ws
     WHERE sessionid = pp_token
       AND cod_producto = pp_producto
       AND mca_activa = 'S';
    --
    RETURN l_cod_agt;
    --
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END f_valida_agt_token;
  --
  --
  -- Retorna la moneda relacionado al TOKEN
  --
  FUNCTION f_valida_cod_mon_token(pp_token VARCHAR2) --portal_web.t_usuario_ws.sessionid%TYPE)
   RETURN VARCHAR2 IS
    --
    l_cod_mon a1000400.cod_mon%TYPE; --portal_web@portweb.t_usuario_ws.usuario_nombre%TYPE;
    --
  BEGIN
    --
    l_cod_mon := 84;
    /*SELECT cod_mon
     INTO l_cod_mon
     FROM t_usuario_ws@portalwe
    WHERE sessionid = pp_token
      AND mca_activa = 'S';*/
    --
    RETURN l_cod_mon;
    --
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END f_valida_cod_mon_token;
  --
  --
  PROCEDURE pl_insert_error(p_cod_mensaje IN x1010020_web.cod_mensaje%TYPE DEFAULT -2000,
                            p_txt_mensaje IN x1010020_web.txt_mensaje%TYPE) IS
  BEGIN
    --
    g_tab_mensajes.EXTEND(1);
    g_fila := g_tab_mensajes.LAST;
    --
    ptraza(g_nom_archivo,
           'a',
           'Insert mensaje error p_cod_mensaje ' || p_cod_mensaje || ' ' ||
           p_txt_mensaje);
    g_tab_mensajes(g_fila).cod_mensaje := p_cod_mensaje;
    g_tab_mensajes(g_fila).txt_mensaje := p_txt_mensaje;
    g_tab_mensajes(g_fila).tip_mensaje := 'E';
    --
  END pl_insert_error;
  --
  PROCEDURE p_lee_datos_tercero(p_elemento       IN CLOB,
                                p_num_cotizacion IN x2000001_web.num_cotizacion%TYPE) IS
    --
    l_elemento CLOB;
    l_longitud NUMBER := 0;
    l_valor    VARCHAR2(100);
    l_valor1   VARCHAR2(100);
    l_texto    VARCHAR2(32000);
    l_json1    CLOB;
    l_index1   INTEGER := 0;
    --
  BEGIN
    --
    l_longitud := length(p_elemento);
    --
    l_elemento := p_elemento;
    ptraza('p_lee_datos_tercero_' || p_num_cotizacion,
           'w',
           '1 l_longitud ' || l_longitud);
    --
    l_valor := instr(l_elemento, '{');
    ptraza('p_lee_datos_tercero_' || p_num_cotizacion,
           'a',
           'l_valor ' || l_valor);
    l_valor1 := instr(substr(l_elemento, l_valor, l_longitud), '}');
    ptraza('p_lee_datos_tercero_' || p_num_cotizacion,
           'a',
           'l_valor1 ' || l_valor1);
    l_texto := ltrim(rtrim(substr(l_elemento, l_valor, l_valor1 - 1)));
    ptraza('p_lee_datos_tercero_' || p_num_cotizacion,
           'a',
           'l_texto ' || l_texto);
    l_texto := ltrim(rtrim(l_texto)) || '}';
    --
    ptraza('p_lee_datos_tercero_' || p_num_cotizacion, 'a', l_texto);
    l_elemento := substr(l_elemento, l_valor1 + 3, l_longitud);
    l_json1    := fl_limpiar_json(l_texto);
    --
    ptraza('p_lee_datos_tercero_' || p_num_cotizacion,
           'a',
           '*****************');
    ptraza('p_lee_datos_tercero_' || p_num_cotizacion,
           'a',
           '1 l_elemento ' || l_elemento);
    dc_k_json_web.p_lee(json(l_json1));
    --
    g_dv_tercero := strarray();
    --
    g_dv_tercero.EXTEND(1);
    l_index1 := g_dv_tercero.LAST;
    --
    BEGIN
      --
      ptraza('p_lee_datos_tercero_' || p_num_cotizacion,
             'a',
             'RIESGO ' || dc_k_json_web.f_get_value('NUM_RIESGO'));
      g_dv_tercero(l_index1) := '{';
      g_dv_tercero(l_index1) := g_dv_tercero(l_index1) || 'NUM_RIESGO: "' ||
                                dc_k_json_web.f_get_value('NUM_RIESGO') || '",';
      g_dv_tercero(l_index1) := g_dv_tercero(l_index1) || 'NOM1_TERCERO: "' ||
                                dc_k_json_web.f_get_value('NOM1_TERCERO') || '",';
      g_dv_tercero(l_index1) := g_dv_tercero(l_index1) || 'APE1_TERCERO: "' ||
                                dc_k_json_web.f_get_value('APE1_TERCERO') || '",';
      g_dv_tercero(l_index1) := g_dv_tercero(l_index1) ||
                                'APE2_TERCERO: "JUAN",';
      g_dv_tercero(l_index1) := g_dv_tercero(l_index1) ||
                                'FEC_NACIMIENTO: "' ||
                                dc_k_json_web.f_get_value('FEC_NACIMIENTO') || '",';
      g_dv_tercero(l_index1) := g_dv_tercero(l_index1) || 'MCA_SEXO: "' ||
                                dc_k_json_web.f_get_value('MCA_SEXO') || '",';
      g_dv_tercero(l_index1) := g_dv_tercero(l_index1) || 'COD_PAIS: "' ||
                                dc_k_json_web.f_get_value('COD_PAIS') || '",';
      g_dv_tercero(l_index1) := g_dv_tercero(l_index1) ||
                                'COD_NACIONALIDAD: "' ||
                                nvl(dc_k_json_web.f_get_value('COD_NACIONALIDAD'),'NIC') || '",';
      g_dv_tercero(l_index1) := g_dv_tercero(l_index1) ||
                                'COD_EST_CIVIL: "' ||
                                dc_k_json_web.f_get_value('COD_EST_CIVIL') || '",';
      g_dv_tercero(l_index1) := g_dv_tercero(l_index1) || 'COD_ESTADO: "' ||
                                dc_k_json_web.f_get_value('COD_ESTADO') || '",';
      g_dv_tercero(l_index1) := g_dv_tercero(l_index1) ||
                                'COD_LOCALIDAD: "NULL",';
      g_dv_tercero(l_index1) := g_dv_tercero(l_index1) || 'COD_PROV: "' ||
                                dc_k_json_web.f_get_value('COD_PROV') || '",';
      g_dv_tercero(l_index1) := g_dv_tercero(l_index1) ||
                                'NOM_DOMICILIO1: "' ||
                                dc_k_json_web.f_get_value('NOM_DOMICILIO1') || '",';
      g_dv_tercero(l_index1) := g_dv_tercero(l_index1) ||
                                'NOM_DOMICILIO2: "' ||
                                dc_k_json_web.f_get_value('NOM_DOMICILIO2') || '",';
      g_dv_tercero(l_index1) := g_dv_tercero(l_index1) ||
                                'NOM_DOMICILIO3: "' ||
                                dc_k_json_web.f_get_value('NOM_DOMICILIO3') || '",';
      g_dv_tercero(l_index1) := g_dv_tercero(l_index1) || 'TLF_NUMERO: "' ||
                                dc_k_json_web.f_get_value('TLF_NUMERO') || '",';
      g_dv_tercero(l_index1) := g_dv_tercero(l_index1) ||
                                'TLF_PAIS: "505",';
      g_dv_tercero(l_index1) := g_dv_tercero(l_index1) || 'COD_DOCUM: "' ||
                                dc_k_json_web.f_get_value('COD_DOCUM') || '",';
      g_dv_tercero(l_index1) := g_dv_tercero(l_index1) || 'TIP_DOCUM: "' ||
                                dc_k_json_web.f_get_value('TIP_DOCUM') || '"';
      g_dv_tercero(l_index1) := g_dv_tercero(l_index1) || '}';
      --
    EXCEPTION
      WHEN OTHERS THEN
        ptraza('p_lee_datos_tercero_' || p_num_cotizacion,
               'a',
               'Error al leer datos del json ' || sqlerrm);
    END;
    --
    ptraza('p_lee_datos_tercero_' || p_num_cotizacion,
           'a',
           '------------------------------------------------------');
    --
    l_longitud := length(l_elemento);
    --
    IF l_longitud > 0 THEN
      --
      ptraza('p_lee_datos_tercero_' || p_num_cotizacion,
             'a',
             '2 l_longitud ' || l_longitud);
      l_valor := instr(l_elemento, '{');
      ptraza('p_lee_datos_tercero_' || p_num_cotizacion,
             'a',
             'l_valor ' || l_valor);
      l_valor1 := instr(substr(l_elemento, l_valor, l_longitud), '}');
      ptraza('p_lee_datos_tercero_' || p_num_cotizacion,
             'a',
             'l_valor1 ' || l_valor1);
      l_texto := ltrim(rtrim(substr(l_elemento, l_valor, l_valor1 - 1)));
      l_texto := ltrim(rtrim(l_texto)) || '}';
      ptraza('p_lee_datos_tercero_' || p_num_cotizacion, 'a', l_texto);
      l_json1    := fl_limpiar_json(l_texto);
      l_elemento := substr(l_elemento, l_valor1 + 2, l_longitud);
      ptraza('p_lee_datos_tercero_' || p_num_cotizacion,
             'a',
             '*****************');
      ptraza('p_lee_datos_tercero_' || p_num_cotizacion,
             'a',
             '1 l_elemento ' || l_elemento);
      --
      dc_k_json_web.p_lee(json(l_json1));
      --
      g_dv_tercero.EXTEND(1);
      l_index1 := g_dv_tercero.LAST;
      --
      BEGIN
        --
        ptraza('p_lee_datos_tercero_' || p_num_cotizacion,
               'a',
               'RIESGO ' || dc_k_json_web.f_get_value('NUM_RIESGO'));
        g_dv_tercero(l_index1) := '{';
        g_dv_tercero(l_index1) := g_dv_tercero(l_index1) || 'NUM_RIESGO: "' ||
                                  dc_k_json_web.f_get_value('NUM_RIESGO') || '",';
        g_dv_tercero(l_index1) := g_dv_tercero(l_index1) ||
                                  'NOM1_TERCERO: "' ||
                                  dc_k_json_web.f_get_value('NOM1_TERCERO') || '",';
        g_dv_tercero(l_index1) := g_dv_tercero(l_index1) ||
                                  'APE1_TERCERO: "' ||
                                  dc_k_json_web.f_get_value('APE1_TERCERO') || '",';
        g_dv_tercero(l_index1) := g_dv_tercero(l_index1) ||
                                  'APE2_TERCERO: "JUAN",';
        g_dv_tercero(l_index1) := g_dv_tercero(l_index1) ||
                                  'FEC_NACIMIENTO: "' ||
                                  dc_k_json_web.f_get_value('FEC_NACIMIENTO') || '",';
        g_dv_tercero(l_index1) := g_dv_tercero(l_index1) || 'MCA_SEXO: "' ||
                                  dc_k_json_web.f_get_value('MCA_SEXO') || '",';
        g_dv_tercero(l_index1) := g_dv_tercero(l_index1) || 'COD_PAIS: "' ||
                                  dc_k_json_web.f_get_value('COD_PAIS') || '",';
        g_dv_tercero(l_index1) := g_dv_tercero(l_index1) ||
                                  'COD_NACIONALIDAD: "' ||
                                  dc_k_json_web.f_get_value('COD_NACIONALIDAD') || '",';
        g_dv_tercero(l_index1) := g_dv_tercero(l_index1) ||
                                  'COD_EST_CIVIL: "' ||
                                  dc_k_json_web.f_get_value('COD_EST_CIVIL') || '",';
        g_dv_tercero(l_index1) := g_dv_tercero(l_index1) || 'COD_ESTADO: "' ||
                                  dc_k_json_web.f_get_value('COD_ESTADO') || '",';
        g_dv_tercero(l_index1) := g_dv_tercero(l_index1) ||
                                  'COD_LOCALIDAD: "NULL",';
        g_dv_tercero(l_index1) := g_dv_tercero(l_index1) || 'COD_PROV: "' ||
                                  dc_k_json_web.f_get_value('COD_PROV') || '",';
        g_dv_tercero(l_index1) := g_dv_tercero(l_index1) ||
                                  'NOM_DOMICILIO1: "' ||
                                  dc_k_json_web.f_get_value('NOM_DOMICILIO1') || '",';
        g_dv_tercero(l_index1) := g_dv_tercero(l_index1) ||
                                  'NOM_DOMICILIO2: "' ||
                                  dc_k_json_web.f_get_value('NOM_DOMICILIO2') || '",';
        g_dv_tercero(l_index1) := g_dv_tercero(l_index1) ||
                                  'NOM_DOMICILIO3: "' ||
                                  dc_k_json_web.f_get_value('NOM_DOMICILIO3') || '",';
        g_dv_tercero(l_index1) := g_dv_tercero(l_index1) || 'TLF_NUMERO: "' ||
                                  dc_k_json_web.f_get_value('TLF_NUMERO') || '",';
        g_dv_tercero(l_index1) := g_dv_tercero(l_index1) ||
                                  'TLF_PAIS: "505",';
        g_dv_tercero(l_index1) := g_dv_tercero(l_index1) || 'COD_DOCUM: "' ||
                                  dc_k_json_web.f_get_value('COD_DOCUM') || '",';
        g_dv_tercero(l_index1) := g_dv_tercero(l_index1) || 'TIP_DOCUM: "' ||
                                  dc_k_json_web.f_get_value('TIP_DOCUM') || '"';
        g_dv_tercero(l_index1) := g_dv_tercero(l_index1) || '}';
        --
      EXCEPTION
        WHEN OTHERS THEN
          ptraza('p_lee_datos_tercero_' || p_num_cotizacion,
                 'a',
                 'Error al leer datos del json ' || sqlerrm);
      END;
      --
      ptraza('p_lee_datos_tercero_' || p_num_cotizacion,
             'a',
             '------------------------------------------------------');
      --
    END IF;
    --
    l_longitud := length(l_elemento);
    --
    IF l_longitud > 0 THEN
      --
      ptraza('p_lee_datos_tercero_' || p_num_cotizacion,
             'a',
             '3 l_longitud ' || l_longitud);
      l_valor := instr(l_elemento, '{');
      ptraza('p_lee_datos_tercero_' || p_num_cotizacion,
             'a',
             'l_valor ' || l_valor);
      l_valor1 := instr(substr(l_elemento, l_valor + 1, l_longitud), '}');
      ptraza('p_lee_datos_tercero_' || p_num_cotizacion,
             'a',
             'l_valor1 ' || l_valor1);
      l_texto := ltrim(rtrim(substr(l_elemento, l_valor, l_valor1 - 0)));
      l_texto := ltrim(rtrim(l_texto)) || '}';
      ptraza('p_lee_datos_tercero_' || p_num_cotizacion, 'a', l_texto);
      l_json1    := fl_limpiar_json(l_texto);
      l_elemento := substr(l_elemento, l_valor1 + 3, l_longitud);
      ptraza('p_lee_datos_tercero_' || p_num_cotizacion,
             'a',
             '*****************');
      ptraza('p_lee_datos_tercero_' || p_num_cotizacion,
             'a',
             '1 l_elemento ' || l_elemento);
      --
      dc_k_json_web.p_lee(json(l_json1));
      --
      g_dv_tercero.EXTEND(1);
      l_index1 := g_dv_tercero.LAST;
      --
      BEGIN
        --
        ptraza('p_lee_datos_tercero_' || p_num_cotizacion,
               'a',
               'RIESGO ' || dc_k_json_web.f_get_value('NUM_RIESGO'));
        g_dv_tercero(l_index1) := '{';
        g_dv_tercero(l_index1) := g_dv_tercero(l_index1) || 'NUM_RIESGO: "' ||
                                  dc_k_json_web.f_get_value('NUM_RIESGO') || '",';
        g_dv_tercero(l_index1) := g_dv_tercero(l_index1) ||
                                  'NOM1_TERCERO: "' ||
                                  dc_k_json_web.f_get_value('NOM1_TERCERO') || '",';
        g_dv_tercero(l_index1) := g_dv_tercero(l_index1) ||
                                  'APE1_TERCERO: "' ||
                                  dc_k_json_web.f_get_value('APE1_TERCERO') || '",';
        g_dv_tercero(l_index1) := g_dv_tercero(l_index1) || 'COD_DOCUM: "' ||
                                  dc_k_json_web.f_get_value('COD_DOCUM') || '",';
        g_dv_tercero(l_index1) := g_dv_tercero(l_index1) || 'TIP_DOCUM: "' ||
                                  dc_k_json_web.f_get_value('TIP_DOCUM') || '",';
        g_dv_tercero(l_index1) := g_dv_tercero(l_index1) ||
                                  'PCT_PARTICIPACION: "' ||
                                  dc_k_json_web.f_get_value('PCT_PARTICIPACION') || '"';
        g_dv_tercero(l_index1) := g_dv_tercero(l_index1) || '}';
        --
      EXCEPTION
        WHEN OTHERS THEN
          ptraza('p_lee_datos_tercero_' || p_num_cotizacion,
                 'a',
                 'Error al leer datos del json ' || sqlerrm);
      END;
      --
    END IF;
    --
    ptraza('p_lee_datos_tercero_' || p_num_cotizacion,
           'a',
           '------------------------------------------------------');
    --
    l_longitud := length(l_elemento);
    --
    IF l_longitud > 0 THEN
      --
      ptraza('p_lee_datos_tercero_' || p_num_cotizacion,
             'a',
             '4 l_longitud ' || l_longitud);
      l_valor  := instr(l_elemento, '{');
      l_valor1 := instr(substr(l_elemento, l_valor + 1, l_longitud), '}');
      l_texto  := ltrim(rtrim(substr(l_elemento, l_valor, l_valor1 - 0)));
      l_texto  := ltrim(rtrim(l_texto)) || '}';
      ptraza('p_lee_datos_tercero_' || p_num_cotizacion, 'a', l_texto);
      l_json1    := fl_limpiar_json(l_texto);
      l_elemento := substr(l_elemento, l_valor1, l_longitud);
      ptraza('p_lee_datos_tercero_' || p_num_cotizacion,
             'a',
             '*****************');
      ptraza('p_lee_datos_tercero_' || p_num_cotizacion,
             'a',
             '1 l_elemento ' || l_elemento);
      --
      dc_k_json_web.p_lee(json(l_json1));
      --
      g_dv_tercero.EXTEND(1);
      l_index1 := g_dv_tercero.LAST;
      --
      BEGIN
        --
        ptraza('p_lee_datos_tercero_' || p_num_cotizacion,
               'a',
               'RIESGO ' || dc_k_json_web.f_get_value('NUM_RIESGO'));
        g_dv_tercero(l_index1) := '{';
        g_dv_tercero(l_index1) := g_dv_tercero(l_index1) || 'NUM_RIESGO: "' ||
                                  dc_k_json_web.f_get_value('NUM_RIESGO') || '",';
        g_dv_tercero(l_index1) := g_dv_tercero(l_index1) ||
                                  'NOM1_TERCERO: "' ||
                                  dc_k_json_web.f_get_value('NOM1_TERCERO') || '",';
        g_dv_tercero(l_index1) := g_dv_tercero(l_index1) ||
                                  'APE1_TERCERO: "' ||
                                  dc_k_json_web.f_get_value('APE1_TERCERO') || '",';
        g_dv_tercero(l_index1) := g_dv_tercero(l_index1) || 'COD_DOCUM: "' ||
                                  dc_k_json_web.f_get_value('COD_DOCUM') || '",';
        g_dv_tercero(l_index1) := g_dv_tercero(l_index1) || 'TIP_DOCUM: "' ||
                                  dc_k_json_web.f_get_value('TIP_DOCUM') || '",';
        g_dv_tercero(l_index1) := g_dv_tercero(l_index1) ||
                                  'PCT_PARTICIPACION: "' ||
                                  dc_k_json_web.f_get_value('PCT_PARTICIPACION') || '"';
        g_dv_tercero(l_index1) := g_dv_tercero(l_index1) || '}';
        --
      EXCEPTION
        WHEN OTHERS THEN
          ptraza('p_lee_datos_tercero_' || p_num_cotizacion,
                 'a',
                 'Error al leer datos del json ' || sqlerrm);
      END;
      --
    END IF;
    ptraza('p_lee_datos_tercero_' || p_num_cotizacion,
           'a',
           '------------------------------------------------------');
    --
    l_longitud := length(l_elemento);
    --
    IF l_longitud > 0 THEN
      --
      ptraza('p_lee_datos_tercero_' || p_num_cotizacion,
             'a',
             '5 l_longitud ' || l_longitud);
      l_valor  := instr(l_elemento, '{');
      l_valor1 := instr(substr(l_elemento, l_valor + 1, l_longitud), '}');
      l_texto  := ltrim(rtrim(substr(l_elemento, l_valor, l_valor1 - 0)));
      l_texto  := ltrim(rtrim(l_texto)) || '}';
      ptraza('p_lee_datos_tercero_' || p_num_cotizacion, 'a', l_texto);
      l_json1    := fl_limpiar_json(l_texto);
      l_elemento := substr(l_elemento, l_valor1, l_longitud);
      ptraza('p_lee_datos_tercero_' || p_num_cotizacion,
             'a',
             '*****************');
      ptraza('p_lee_datos_tercero_' || p_num_cotizacion,
             'a',
             '1 l_elemento ' || l_elemento);
      --
      dc_k_json_web.p_lee(json(l_json1));
      --
      g_dv_tercero.EXTEND(1);
      l_index1 := g_dv_tercero.LAST;
      --
      BEGIN
        --
        ptraza('p_lee_datos_tercero_' || p_num_cotizacion,
               'a',
               'RIESGO ' || dc_k_json_web.f_get_value('NUM_RIESGO'));
        g_dv_tercero(l_index1) := '{';
        g_dv_tercero(l_index1) := g_dv_tercero(l_index1) || 'NUM_RIESGO: "' ||
                                  dc_k_json_web.f_get_value('NUM_RIESGO') || '",';
        g_dv_tercero(l_index1) := g_dv_tercero(l_index1) ||
                                  'NOM1_TERCERO: "' ||
                                  dc_k_json_web.f_get_value('NOM1_TERCERO') || '",';
        g_dv_tercero(l_index1) := g_dv_tercero(l_index1) ||
                                  'APE1_TERCERO: "' ||
                                  dc_k_json_web.f_get_value('APE1_TERCERO') || '",';
        g_dv_tercero(l_index1) := g_dv_tercero(l_index1) || 'COD_DOCUM: "' ||
                                  dc_k_json_web.f_get_value('COD_DOCUM') || '",';
        g_dv_tercero(l_index1) := g_dv_tercero(l_index1) || 'TIP_DOCUM: "' ||
                                  dc_k_json_web.f_get_value('TIP_DOCUM') || '",';
        g_dv_tercero(l_index1) := g_dv_tercero(l_index1) ||
                                  'PCT_PARTICIPACION: "' ||
                                  dc_k_json_web.f_get_value('PCT_PARTICIPACION') || '"';
        g_dv_tercero(l_index1) := g_dv_tercero(l_index1) || '}';
        --
      EXCEPTION
        WHEN OTHERS THEN
          ptraza('p_lee_datos_tercero_' || p_num_cotizacion,
                 'a',
                 'Error al leer datos del json ' || sqlerrm);
      END;
      --
    END IF;
    --
    ptraza('p_lee_datos_tercero_' || p_num_cotizacion, 'a', 'FIN');
    --
  EXCEPTION
    WHEN OTHERS THEN
      ptraza('p_lee_datos_tercero_' || p_num_cotizacion,
             'a',
             'Error ' || sqlerrm);
  END p_lee_datos_tercero;
  --
  PROCEDURE p_login_ws(p_parametros IN CLOB,
                       p_login      OUT gc_ref_cursor,
                       p_errores    OUT gc_ref_cursor) IS
    --
    -- PARAMETROS ENVIADOS DESDE LA WEB
    p_usuario        VARCHAR2(100);
    p_password       VARCHAR2(100);
    p_producto       VARCHAR2(10);
    p_cod_mon        a1000400.cod_mon%TYPE;
    l_usuario_nombre portal_web.t_usuario.usuario_nombre%TYPE;
    --
    l_parametros_clob  CLOB;
    l_bloqueado        VARCHAR2(100);
    p_salida_login     VARCHAR2(100) := NULL;
    l_existe           BOOLEAN;
    l_password_encript portal_web.t_usuario.paswd_aut%TYPE;
    l_dato_1           VARCHAR(200);
    l_dato_2           VARCHAR2(200);
    l_dato_3           VARCHAR2(200);
    l_cantidad         NUMBER := 0;
    l_mca              NUMBER;
    l_mcantlm          VARCHAR(1) := 'N';
    --
    TYPE objeto_ldap IS RECORD(
      email_address    VARCHAR2(256),
      tip_docum        a1001390.tip_docum%TYPE,
      cod_docum        a1001390.cod_docum%TYPE,
      nom_tercero      VARCHAR(256),
      cod_act_tercero  a1001390.cod_act_tercero%TYPE,
      mca_inh          VARCHAR2(1),
      usuario_activo   VARCHAR2(10),
      cod_agt          VARCHAR2(20),
      grupos           VARCHAR2(20),
      cnt_claveerrada  NUMBER,
      contrasenaexpiro VARCHAR2(20),
      cod_cia          VARCHAR2(10));
    --
    l_ref_cursor gc_ref_cursor;
    --
    CURSOR c_usuario IS
      SELECT usuario_nombre, bloqueado
        FROM portal_web.t_usuario
       WHERE email = p_usuario
         AND upper(paswd_aut) = l_password_encript
         AND mca_tipo_autenticacion = 'L'
         AND bloqueado = trn.NO;
    --
    CURSOR c_descompone_cod_usr IS
      SELECT rownum, token dato
        FROM (SELECT TRIM(substr(txt,
                                 instr(txt, '_', 1, LEVEL) + 1,
                                 instr(txt, '_', 1, LEVEL + 1) -
                                 instr(txt, '_', 1, LEVEL) - 1)) AS token
                FROM (SELECT '_' || l_usuario_nombre || '_' AS txt FROM dual)
              CONNECT BY LEVEL <=
                         length(txt) - length(REPLACE(txt, '_', '')) - 1);
    --
    CURSOR c_agt_valido(    pp_cod_cia a1001332.cod_cia%TYPE, 
                            pp_tip_docum a1001332.tip_docum%TYPE, 
                            pp_cod_docum a1001332.cod_docum%TYPE
                        ) IS
      SELECT cod_agt
        FROM a1001332 a, a1001390 b, a1001399 c
       WHERE a.cod_cia = pp_cod_cia
         AND nvl(a.mca_inh, 'N') = 'N'
         AND a.fec_validez = (SELECT MAX(b.fec_validez)
                                FROM a1001332 b
                               WHERE b.cod_cia = pp_cod_cia
                                 AND b.cod_agt = a.cod_agt)
         AND b.cod_cia = c.cod_cia
         AND b.tip_docum = c.tip_docum
         AND b.cod_docum = c.cod_docum
         AND b.cod_cia = a.cod_cia
         AND b.cod_act_tercero = 2
         AND b.cod_tercero = a.cod_agt
         AND a.tip_docum = pp_tip_docum
         AND a.cod_docum = pp_cod_docum;
    --
    CURSOR c_sub_agt_valido(    pp_cod_cia a1001332.cod_cia%TYPE, 
                                pp_tip_docum a1001332.tip_docum%TYPE, 
                                pp_cod_docum a1001332.cod_docum%TYPE
                            ) IS
      SELECT cod_agt
        FROM a1001337 a, a1001390 b, a1001399 c
       WHERE a.cod_cia = pp_cod_cia
         AND nvl(a.mca_inh, 'N') = 'N'
         AND a.fec_validez =
             (SELECT MAX(b.fec_validez)
                FROM a1001337 b
               WHERE b.cod_cia = pp_cod_cia
                 AND b.cod_emp_agt = a.cod_emp_agt)
         AND b.cod_cia = c.cod_cia
         AND b.tip_docum = c.tip_docum
         AND b.cod_docum = c.cod_docum
         AND b.cod_cia = a.cod_cia
         AND b.cod_act_tercero = 2
         AND b.cod_tercero = a.cod_agt
         AND a.tip_docum = pp_tip_docum
         AND a.cod_docum = pp_cod_docum;
    --
  BEGIN
    --
    l_parametros_clob := p_parametros; --fl_limpiar_json(p_parametros);
    g_nom_archivo     := 'ws_login_micro';
    ptraza(g_nom_archivo, 'w', '------- INICIO << p_login_ws >> -------');
    --
    g_tab_mensajes.DELETE;
    --
    BEGIN
      --
      -- Lee Parametros Enviados desde la Web
      IF l_parametros_clob IS NOT NULL THEN
        --
        ptraza(g_nom_archivo, 'a', 'Parametros ' || l_parametros_clob);
        --
        dc_k_util_json_web.p_lee(json(l_parametros_clob));
        --
        BEGIN
          --
          p_usuario  := dc_k_util_json_web.f_get_value('usuario');
          p_password := dc_k_util_json_web.f_get_value('password');
          p_producto := dc_k_util_json_web.f_get_value('producto');
          --
        EXCEPTION
          WHEN OTHERS THEN
            --
            ptraza(g_nom_archivo,
                   'a',
                   'Error en l_parametros_clob: ' || SQLERRM);
            --
        END;
        --
      END IF;
      --
      ptraza(g_nom_archivo,
             'a',
             'p_usuario: ' || p_usuario || ' p_password: ' || p_password ||
             ' p_producto ' || NVL(p_producto, '0'));
      --
      IF (p_usuario IS NULL) AND (p_password IS NULL) THEN
        --
        pl_insert_error(p_txt_mensaje => 'Debe indicar usuario y clave!');
        --
      ELSIF (p_usuario IS NULL) THEN
        --
        pl_insert_error(p_txt_mensaje => 'Debe indicar usuario!');
        --
      ELSIF (p_password IS NULL) THEN
        --
        pl_insert_error(p_txt_mensaje => 'Debe indicar clave!');
        --
      ELSIF (p_producto NOT IN ('1', '2', '3')) THEN
        --
        pl_insert_error(p_txt_mensaje => 'Producto Incorrecto');
        --
      ELSIF (NVL(p_producto, '0') IN ('0')) THEN
        --
        pl_insert_error(p_txt_mensaje => 'Producto Incorrecto');
        --
      ELSE
        --      
        SELECT dbms_obfuscation_toolkit.md5(input => UTL_RAW.cast_to_raw(p_password))
          INTO l_password_encript
          FROM DUAL;
        --
        ptraza(g_nom_archivo,
               'a',
               'Usuario ' || p_usuario || ' ' || p_password ||
               ' Encriptado ' || l_password_encript);
        --
        OPEN c_usuario;
        FETCH c_usuario
          INTO l_usuario_nombre, l_bloqueado;
        l_existe := c_usuario%FOUND;
        CLOSE c_usuario;
        --
        ptraza(g_nom_archivo,
               'a',
               'l_usuario_nombre ' || l_usuario_nombre || ' l_bloqueado ' ||
               l_bloqueado);
        --
        IF l_bloqueado = 'S' THEN
          --
          pl_insert_error(p_txt_mensaje => 'El usuario esta bloqueado!');
          --
        ELSIF NVL(l_usuario_nombre, 'N') <> 'N' THEN
          --
          /* Se descompone el p_cod_usr para utilizarlo los valores al obtener
             el nombre y apellido de usuario
          */
          FOR reg_c IN c_descompone_cod_usr LOOP
            --
            SELECT COUNT(*)
              INTO l_cantidad
              FROM (SELECT TRIM(substr(txt,
                                       instr(txt, '_', 1, LEVEL) + 1,
                                       instr(txt, '_', 1, LEVEL + 1) -
                                       instr(txt, '_', 1, LEVEL) - 1)) AS token
                      FROM (SELECT '_' || l_usuario_nombre || '_' AS txt
                              FROM dual)
                    CONNECT BY LEVEL <=
                               length(txt) - length(REPLACE(txt, '_', '')) - 1);
            --
            l_mca := instr(l_usuario_nombre, '1_');
            --
            IF l_mca > 0 THEN
              l_mcantlm := 'C';
            END IF;
            --
            ptraza(g_nom_archivo,
                   'a',
                   'Descompone usuario ' || reg_c.dato || ' l_cantidad ' ||
                   l_cantidad || ' reg_c.rownum ' || reg_c.rownum ||
                   ' l_mcantlm ' || l_mcantlm);
            --
            IF reg_c.dato != ' ' THEN
              IF (reg_c.rownum = 1 AND l_cantidad >= reg_c.rownum) THEN
                --
                l_dato_1 := reg_c.dato;
                --
              ELSIF (reg_c.rownum = 2 AND l_cantidad >= reg_c.rownum) THEN
                --
                l_dato_2 := reg_c.dato;
              ELSIF (reg_c.rownum = 3 AND l_cantidad >= reg_c.rownum) THEN
                --
                l_dato_3 := reg_c.dato;
              END IF;
              --
            END IF;
            --
          END LOOP;
          --
          ptraza(g_nom_archivo,
                 'a',
                 'l_dato_1 ' || l_dato_1 || ' l_dato_2 ' || l_dato_2 ||
                 ' l_dato_3 ' || l_dato_3);
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
            END;
            --
          END IF;
          --
          ptraza(g_nom_archivo, 'a', 'COD_AGT ' || g_cod_agt);
          --
          SELECT dbms_random.random || dbms_random.STRING('K', 8)
            INTO p_salida_login
            FROM dual;
          --
          ptraza(g_nom_archivo, 'a', 'p_salida_login ' || p_salida_login);
          --
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
               p_salida_login,
               trn.SI,
               p_producto,
               p_cod_mon,
               g_fec_actu);
            --
            IF SQL%ROWCOUNT = 1 THEN
              -- Inactiva token anteriores
              ptraza(g_nom_archivo, 'a', 'INSERT OK');
              UPDATE portal_web.t_usuario_ws
                 SET mca_activa = 'N', logout = SYSDATE
               WHERE cod_cia = g_cod_cia
                 AND usuario_nombre = g_cod_agt
                 AND cod_producto = p_producto
                 AND sessionid != p_salida_login;
              --
              IF SQL%ROWCOUNT <> 0 THEN
                ptraza(g_nom_archivo,
                       'a',
                       'Se actualizaron ' || SQL%ROWCOUNT ||
                       ' registros anteriores');
              END IF;
              --
            END IF;
            --
          EXCEPTION
            WHEN OTHERS THEN
              ptraza(g_nom_archivo, 'a', 'Error al insert ' || SQLERRM);
          END;
          --
        ELSIF (l_usuario_nombre IS NULL) THEN
          --
          pl_insert_error(p_txt_mensaje => 'El usuario no existe!');
          --
        END IF;
        --
      END IF;
      --
    EXCEPTION
      WHEN OTHERS THEN
        --
        pl_insert_error(p_txt_mensaje => SQLERRM);
        --
    END;
    --
    COMMIT;
    --
    OPEN p_login FOR
      SELECT p_salida_login AS salida_login FROM dual;
    --
    OPEN p_errores FOR
      SELECT a.cod_mensaje, a.txt_mensaje
        FROM TABLE(f_table_mensajes) a
       WHERE tip_mensaje = 'E';
    --
    ptraza(g_nom_archivo, 'a', '------- FIN << p_login_ws >> -------');
    --
  END p_login_ws;
  --
  -- MICRO SEGUROS ACCIDENTES PERSONALES
  --
  PROCEDURE p_emision_ws_ap(p_token          IN VARCHAR2,
                            p_datos_riesgo   IN CLOB,
                            p_datos_tercero  IN CLOB,
                            p_codigo_error   OUT VARCHAR2,
                            p_mensaje        OUT VARCHAR2,
                            p_cursor_emision OUT gc_ref_cursor) IS
    --
    L_NLS_NUMERIC_CHARACTERS VARCHAR2(100);
    l_grabar                 BOOLEAN;
    l_emite                  VARCHAR2(1) := 'N';
    l_reg_x2000000_web       x2000000_web%ROWTYPE;
    l_cantidad               NUMBER;
    l_total_suma_aseg        NUMBER := 0;
    l_cod_nivel3             a1001332.cod_nivel3%TYPE;
    l_tercero                VARCHAR2(1) := 'N';
    l_riesgo                 VARCHAR2(1) := 'N';
    l_num_cotizacion         x2000001_web.num_cotizacion%TYPE;
    l_num_poliza             a2000030.num_poliza%TYPE;
    l_num_recibo             a2990700.num_recibo%TYPE;
    --
    l_index                 INTEGER := 0;
    l_dv_datos_riesgo_clob  CLOB := fl_limpiar_json(p_datos_riesgo);
    l_dv_datos_tercero_clob CLOB := fl_limpiar_json(p_datos_tercero);
    l_dv_cobertura          strarray;
    l_dv_poliza             strarray;
    l_dv_riesgo             strarray;
    l_parametros_emision    strarray;
    --
    l_datos_poliza_emision gc_ref_cursor;
    l_errores_emision      gc_ref_cursor;
    --
    l_cod_mon        a1000400.cod_mon%TYPE := NULL;
    l_moneda         VARCHAR2(4) := NULL;
    l_plan           VARCHAR2(4) := NULL;
    l_cod_plan       VARCHAR2(2);
    l_estatura       VARCHAR2(8) := NULL;
    l_peso           VARCHAR2(8) := NULL;
    l_fec_efec_spto  VARCHAR2(10) := NULL;
    l_cod_fracc_pago a2000020.val_campo%TYPE := 'NULL';
    --
    CURSOR c_valida_cob_muerte IS
      SELECT COUNT(DISTINCT(a.num_poliza)), SUM(d.suma_aseg)
        FROM a2000030 a, a2000060 c, a2000040 d
       WHERE a.cod_cia = g_cod_cia
         AND a.cod_ramo = g_cod_ramo_acc
         AND a.num_spto = (SELECT MAX(b.num_spto)
                             FROM a2000030 b
                            WHERE b.cod_cia = a.cod_cia
                              AND b.num_poliza = a.num_poliza
                              AND b.mca_spto_anulado = trn.NO)
         AND trunc(sysdate) BETWEEN a.fec_efec_spto and a.fec_vcto_spto
         AND a.mca_poliza_anulada = trn.NO
         AND d.cod_cia = a.cod_cia
         AND d.num_poliza = a.num_poliza
         AND d.cod_cob = 7101 -- Cobertura de Muerte
         AND d.mca_vigente = trn.SI
         AND d.mca_baja_cob = trn.NO
         AND c.cod_cia = a.cod_cia
         AND c.num_poliza = a.num_poliza
         AND c.tip_benef = g_tip_benef_aseg
         AND c.mca_vigente = trn.SI
         AND c.mca_baja = trn.NO
         AND c.tip_docum = g_tip_docum_aseg
         AND c.cod_docum = g_cod_docum_aseg;
    --
    l_longitud_terceros          NUMBER := 0;
    l_longitud_terceros_original NUMBER := 0;
    --
  BEGIN
    --
    g_session_id := p_token;
    --
    g_nom_archivo := 'ws_emision_acc';
    ptraza(g_nom_archivo,
           'w',
           '------- INICIO << p_emision_ws >> -------' || g_session_id);
    --
    trn_k_global.asigna('COD_USR', g_cod_usr);
    trn_k_global.asigna('cod_idioma', g_cod_idioma);
    trn_k_global.asigna('g_cod_usr', g_cod_usr);
    l_num_poliza := NULL;
    l_num_recibo := NULL;
    --
    BEGIN
      --
      SELECT VALUE
        INTO L_NLS_NUMERIC_CHARACTERS
        FROM nls_session_parameters
       WHERE parameter = 'NLS_NUMERIC_CHARACTERS';
      --
      ptraza('em_k_ws_auto_web_emite',
             'a',
             'NLS_NUMERIC_CHARACTERS ' || L_NLS_NUMERIC_CHARACTERS);
      --
      trn_k_dinamico.p_ejecuta_sentencia('alter session set NLS_NUMERIC_CHARACTERS = ".,"');
      trn_k_dinamico.p_ejecuta_sentencia('alter session set NLS_DATE_FORMAT="DD/MM/RR"');
      --
    EXCEPTION
      WHEN OTHERS THEN
        ptraza('em_k_ws_auto_web_emite',
               'a',
               'Error obtener NLS_NUMERIC_CHARACTERS ' || sqlerrm);
    END;
    --
    ptraza(g_nom_archivo, 'a', 'p_token ' || p_token);
    --
    IF p_token IS NOT NULL THEN
      --
      g_continua := f_valida_token(p_token);
      ptraza(g_nom_archivo, 'a', 'g_continua ' || g_continua);
      g_cod_agt := f_valida_agt_token(p_token, g_k_producto_ap);
      --
      ptraza(g_nom_archivo, 'a', 'g_cod_agt ' || g_cod_agt);
      --
      IF g_cod_agt IS NOT NULL THEN
        --
        dc_k_a1001332.p_lee(g_cod_cia,
                            to_number(g_cod_agt),
                            trunc(sysdate));
        l_cod_nivel3 := dc_k_a1001332.f_cod_nivel3;
        ptraza(g_nom_archivo,
               'a',
               'g_cod_agt ' || g_cod_agt || ' l_cod_nivel3 ' ||
               l_cod_nivel3);
        --
        ptraza(g_nom_archivo,
               'a',
               'g_continua ' || g_continua || ' g_cod_agt ' || g_cod_agt);
        --
        IF g_continua = 'S' THEN
          --
          trn_k_global.asigna('WEB_SERVICE', 'S');
          g_tab_mensajes.DELETE;
          --
          IF l_dv_datos_riesgo_clob IS NOT NULL THEN
            --
            BEGIN
              ptraza(g_nom_archivo,
                     'a',
                     'l_dv_datos_riesgo_clob ' || l_dv_datos_riesgo_clob);
              --
              l_riesgo := 'S';
              --
              dc_k_json_web.p_lee(json(l_dv_datos_riesgo_clob));
              --
              BEGIN
                --
                l_moneda        := dc_k_json_web.f_get_value('COD_MON');
                l_plan          := dc_k_json_web.f_get_value('COD_PLAN');
                l_estatura      := dc_k_json_web.f_get_value('NUM_ESTATURA');
                l_peso          := dc_k_json_web.f_get_value('NUM_PESO');
                l_fec_efec_spto := to_char(trunc(sysdate), 'dd-mm-yyyy');
                --
                IF l_moneda = 'USD' THEN
                  l_cod_mon := 84;
                ELSE
                  l_cod_mon := 55;
                END IF;
                --
                IF l_plan = 'A' THEN
                  l_cod_plan := '1';
                ELSIF l_plan = 'B' THEN
                  l_cod_plan := '2';
                END IF;
                --
              EXCEPTION
                WHEN OTHERS THEN
                  ptraza(g_nom_archivo,
                         'a',
                         'Error al leer datos del json ' || sqlerrm);
              END;
              --
              ptraza(g_nom_archivo,
                     'a',
                     'l_moneda ' || l_moneda || ' l_plan ' || l_plan ||
                     ' l_estatura ' || l_estatura || ' l_peso ' || l_peso ||
                     ' l_fec_efec_spto ' || l_fec_efec_spto ||
                     ' l_cod_mon ' || l_cod_mon);
            EXCEPTION
              WHEN OTHERS THEN
                ptraza(g_nom_archivo,
                       'a',
                       ' Error al leer l_dv_datos_riesgo_clob ' || sqlerrm);
            END;
          END IF;
          --
          IF l_dv_datos_tercero_clob IS NOT NULL THEN
            --
            SELECT length(l_dv_datos_tercero_clob), length(p_datos_tercero)
              INTO l_longitud_terceros, l_longitud_terceros_original
              FROM DUAL;
            ptraza(g_nom_archivo,
                   'a',
                   'LONGITUD ' || l_longitud_terceros ||
                   ' l_longitud_terceros_original ' ||
                   l_longitud_terceros_original);
            l_tercero := 'S';
            --
          END IF;
          --
          ptraza(g_nom_archivo,
                 'a',
                 'Riesgo ' || l_riesgo || ' Terceros ' || l_tercero);
          --
          ptraza(g_nom_archivo, 'a', '---------------------------------');
          BEGIN
            --
            IF (l_riesgo = 'S' AND l_tercero = 'S') THEN
              --
              l_num_cotizacion := em_k_util_cotizacion_web.f_num_cotizacion(g_cod_ramo_acc);
              --
              ptraza(g_nom_archivo,
                     'a',
                     'NUM_COTIZACION: ' || l_num_cotizacion ||
                     ' p_lee_datos_tercero');
              --
              p_lee_datos_tercero(l_dv_datos_tercero_clob,
                                  l_num_cotizacion);
              --
              g_reg_x2000001_web.cod_cia            := g_cod_cia;
              g_reg_x2000001_web.num_cotizacion     := l_num_cotizacion;
              g_reg_x2000001_web.cod_estatus        := g_estatus_pendiente;
              g_reg_x2000001_web.cod_ramo           := g_cod_ramo_acc;
              g_reg_x2000001_web.tip_cotizacion     := 'E';
              g_reg_x2000001_web.mca_financiamiento := 'N';
              g_reg_x2000001_web.cod_agt            := g_cod_agt;
              g_reg_x2000001_web.cod_usr            := g_cod_usr;
              g_reg_x2000001_web.fec_actu           := g_fec_actu;
              g_reg_x2000001_web.cod_modulo         := g_cod_modulo;
              g_reg_x2000001_web.cod_emp_agt        := trn.NULO; --l_sub_agt;
              g_reg_x2000001_web.datos1             := TO_CLOB(l_dv_datos_tercero_clob);
              --
              ptraza(g_nom_archivo, 'a', 'em_k_x2000001_web.p_inserta');
              em_k_x2000001_web.p_inserta(g_reg_x2000001_web);
              --
              g_tab_x2000000_web.DELETE;
              --
              ptraza(g_nom_archivo, 'a', 'DELETE FROM x2000000_web');
              DELETE FROM x2000000_web
               WHERE cod_cia = g_cod_cia
                 AND num_cotizacion = l_num_cotizacion;
              --
              COMMIT;
              --
              l_dv_riesgo    := strarray();
              l_dv_cobertura := strarray();
              l_dv_poliza    := strarray();
              --
              l_dv_poliza.EXTEND(1);
              l_index := l_dv_poliza.LAST;
              --
              l_dv_poliza(l_index) := '{';
              l_dv_poliza(l_index) := l_dv_poliza(l_index) ||
                                      'COD_MODALIDAD: "' ||
                                      g_cod_modalidad_acc || '",';
              l_dv_poliza(l_index) := l_dv_poliza(l_index) || 'COD_PLAN: "' ||
                                      l_cod_plan || '",';
              l_dv_poliza(l_index) := l_dv_poliza(l_index) ||
                                      'NUM_DIAS_GRAC: "NULL"';
              l_dv_poliza(l_index) := l_dv_poliza(l_index) || '}';
              --
              l_dv_riesgo.EXTEND(1);
              l_index := l_dv_riesgo.LAST;
              --
              l_dv_riesgo(l_index) := '{';
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'COD_PLAN: "' ||
                                      l_cod_plan || '",';
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) ||
                                      'NUM_ESTATURA: "' || l_estatura || '",';
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'NUM_PESO: "' ||
                                      l_estatura || '"';
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || '}';
              --
              ptraza(g_nom_archivo,
                     'a',
                     'PL_INSERTA_DATOS l_fec_efec_spto ' ||
                     replace(l_fec_efec_spto, '-', '') || ' COD_MON ' ||
                     l_cod_mon);
              --
              trn_k_global.asigna('ws_traza_emision', g_nom_archivo);
              em_k_cotiza_acc_pers_web.pl_inserta_datos(p_session_id          => g_session_id,
                                                        p_cod_cia             => g_cod_cia,
                                                        p_cod_ramo            => g_cod_ramo_acc,
                                                        p_cod_mon             => l_cod_mon,
                                                        p_num_cotizacion      => l_num_cotizacion,
                                                        p_fec_efec_poliza     => l_fec_efec_spto,
                                                        p_num_duracion_poliza => g_num_duracion_poliza,
                                                        p_txt_duracion_poliza => ' ', --p_txt_duracion_poliza,
                                                        p_num_poliza_grupo    => trn.NULO,
                                                        p_num_contrato        => trn.NULO,
                                                        p_cod_modalidad       => g_cod_modalidad_acc,
                                                        p_cod_fracc_pago      => nvl(l_cod_fracc_pago,
                                                                                     1),
                                                        p_cod_nivel3          => l_cod_nivel3,
                                                        p_dv_poliza           => l_dv_poliza,
                                                        p_dv_riesgo           => l_dv_riesgo,
                                                        p_dv_cobertura        => l_dv_cobertura,
                                                        p_dat_asegurado       => g_dv_tercero,
                                                        p_fec_efec_spto       => to_date(replace(l_fec_efec_spto,
                                                                                                 '-',
                                                                                                 ''),
                                                                                         'DDMMYYYY'));
              --
              ptraza(g_nom_archivo,
                     'a',
                     '-----------------Despues de em_k_cotiza_acc_pers_web.pl_inserta_datos');
              ptraza(g_nom_archivo,
                     'a',
                     'COUNT ' || g_tab_x2000000_web.COUNT);
              IF g_tab_x2000000_web.COUNT > 0 THEN
                --
                l_emite := 'S';
                --
                FOR fila IN g_tab_x2000000_web.FIRST .. g_tab_x2000000_web.LAST LOOP
                  --
                  BEGIN
                    --
                    IF (g_tab_x2000000_web(fila).cod_campo = 'COD_COBERTURA') AND
                       (g_tab_x2000000_web(fila).txt_campo1 IS NULL) AND
                       (g_tab_x2000000_web(fila).txt_campo2 IS NULL) THEN
                      --
                      l_grabar := FALSE;
                      --
                    ELSE
                      --
                      l_grabar := TRUE;
                      --
                    END IF;
                    --
                    IF l_grabar THEN
                      --
                      l_reg_x2000000_web := fl_to_reg_x2000000_web(g_tab_x2000000_web(fila));
                      --
                      ptraza(g_nom_archivo,
                             'a',
                             'INSERT INTO x2000000_web CAMPO ' ||
                             l_reg_x2000000_web.cod_campo || ' VALOR ' ||
                             l_reg_x2000000_web.val_campo || ' RIEGO ' ||
                             l_reg_x2000000_web.num_riesgo || ' NUM_SECU ' ||
                             l_reg_x2000000_web.num_secu);
                      --
                      INSERT INTO x2000000_web
                        (cod_cia,
                         num_cotizacion,
                         num_riesgo,
                         cod_campo,
                         num_secu,
                         val_campo,
                         txt_campo,
                         txt_campo1,
                         txt_campo2)
                      VALUES
                        (l_reg_x2000000_web.cod_cia,
                         l_reg_x2000000_web.num_cotizacion,
                         l_reg_x2000000_web.num_riesgo,
                         l_reg_x2000000_web.cod_campo,
                         l_reg_x2000000_web.num_secu,
                         l_reg_x2000000_web.val_campo,
                         l_reg_x2000000_web.txt_campo,
                         l_reg_x2000000_web.txt_campo1,
                         l_reg_x2000000_web.txt_campo2);
                      --
                    END IF;
                    --
                  EXCEPTION
                    WHEN OTHERS THEN
                      --
                      ptraza(g_nom_archivo,
                             'a',
                             'Error insert x2000000_web Campo ' ||
                             l_reg_x2000000_web.cod_campo || ' ' || SQLERRM);
                      --
                  END;
                  --
                END LOOP;
                --
                COMMIT;
                --
              END IF;
              --
              BEGIN
                -- Valida cobertura de muerte
                l_cantidad        := 0;
                l_total_suma_aseg := 0;
                ptraza(g_nom_archivo,
                       'a',
                       'VALIDA COBERTURA DE MUERTE. Asegurado ' ||
                       g_tip_docum_aseg || ' ' || g_cod_docum_aseg);
                --
                OPEN c_valida_cob_muerte;
                FETCH c_valida_cob_muerte
                  INTO l_cantidad, l_total_suma_aseg;
                CLOSE c_valida_cob_muerte;
                --
                ptraza(g_nom_archivo, 'a', 'CANTIDAD ' || l_cantidad);
                --
                IF (l_cantidad >= 4 OR l_total_suma_aseg > 10000) THEN
                  --
                  ptraza(g_nom_archivo,
                         'a',
                         '   REGISTRA ERROR POR CANTIDAD DE EMISIONES O SUMA ASEGURADA');
                  dc_k_util_web.p_set_mensaje(p_cod_cia         => g_cod_cia,
                                              p_session_id      => g_session_id,
                                              p_cod_mensaje     => 80997,
                                              p_cod_idioma      => g_cod_idioma,
                                              p_txt_mensaje     => '. NO SE PUEDE COMPLETAR LA EMISION',
                                              p_mca_tip_mensaje => 'E');
                  --
                END IF;
                --
              EXCEPTION
                WHEN OTHERS THEN
                  ptraza(g_nom_archivo,
                         'a',
                         'Error validacion ' || sqlerrm);
              END;
              --
            END IF;
            --
          EXCEPTION
            WHEN OTHERS THEN
              --
              ptraza(g_nom_archivo,
                     'a',
                     'Error en << p_generar_cotizacion >>: ' || SQLERRM);
              --
              dc_k_util_web.p_set_mensaje(p_cod_cia         => g_cod_cia,
                                          p_session_id      => g_session_id,
                                          p_cod_mensaje     => -20001,
                                          p_cod_idioma      => g_cod_idioma,
                                          p_txt_mensaje     => SQLERRM,
                                          p_mca_tip_mensaje => 'E');
              --
          END;
          --
          IF l_num_cotizacion IS NOT NULL THEN
            --
            BEGIN
              l_num_poliza := trn.NULO;
              ptraza(g_nom_archivo,
                     'a',
                     'EMITE LA POLIZA l_emite ' || l_emite);
              --
              l_parametros_emision := strarray();
              l_parametros_emision.EXTEND(1);
              l_index := l_parametros_emision.LAST;
              --
              l_parametros_emision(l_index) := '{';
              l_parametros_emision(l_index) := l_parametros_emision(l_index) ||
                                               'SESSION_ID: "' ||
                                               g_session_id || '",';
              l_parametros_emision(l_index) := l_parametros_emision(l_index) ||
                                               'COD_CIA: "' || g_cod_cia || '",';
              l_parametros_emision(l_index) := l_parametros_emision(l_index) ||
                                               'COD_FRACC_PAGO: "' ||
                                               nvl(l_cod_fracc_pago, 1) || '",';
              l_parametros_emision(l_index) := l_parametros_emision(l_index) ||
                                               'MCA_DOMICILIADO: "' || 'N' || '",';
              l_parametros_emision(l_index) := l_parametros_emision(l_index) ||
                                               'TIP_GESTOR: "' || 'AG' || '",';
              l_parametros_emision(l_index) := l_parametros_emision(l_index) ||
                                               'COD_GESTOR: "' || g_cod_agt || '",';
              l_parametros_emision(l_index) := l_parametros_emision(l_index) ||
                                               'COD_OFICINA: "' ||
                                               l_cod_nivel3 || '",';
              l_parametros_emision(l_index) := l_parametros_emision(l_index) ||
                                               'FEC_EFEC_SPTO: "' ||
                                               l_fec_efec_spto || '",';
              l_parametros_emision(l_index) := l_parametros_emision(l_index) ||
                                               'NUM_COTIZACION: "' ||
                                               l_num_cotizacion || '"';
              l_parametros_emision(l_index) := l_parametros_emision(l_index) || '}';
              --
              ptraza(g_nom_archivo,
                     'a',
                     'inicia em_k_cotiza_acc_pers_web.p_emite_poliza');
              em_k_cotiza_acc_pers_web.p_emite_poliza(l_parametros_emision, --   IN strarray,
                                                      l_datos_poliza_emision, -- OUT gc_ref_cursor,
                                                      l_errores_emision); --      OUT gc_ref_cursor)
              --
              ptraza(g_nom_archivo,
                     'a',
                     'fin em_k_cotiza_acc_pers_web.p_emite_poliza');
              --
              LOOP
                FETCH l_datos_poliza_emision
                  INTO l_num_poliza, l_num_recibo;
                EXIT WHEN l_datos_poliza_emision%NOTFOUND;
                --
                ptraza(g_nom_archivo,
                       'a',
                       '   NUM_POLIZA ' || l_num_poliza || ' RECIBO ' ||
                       l_num_recibo);
              END LOOP;
              --
            EXCEPTION
              WHEN OTHERS THEN
                l_num_poliza := NULL;
                l_num_recibo := NULL;
                --
                ptraza(g_nom_archivo,
                       'a',
                       '        ERROR p_emite_poliza ' || SQLERRM);
            END;
            --  
            IF l_num_poliza IS NOT NULL THEN
              --            
              p_codigo_error := '00';
              p_mensaje      := 'Emision Exitosa Poliza No. ' ||
                                l_num_poliza || ' Recibo No. ' ||
                                l_num_recibo;
              --
              OPEN p_cursor_emision FOR
                SELECT l_num_poliza num_poliza FROM DUAL;
              --
            ELSE
              --            
              p_codigo_error := '400';
              p_mensaje      := 'Falla en Emision - se genero Cotizacion No. ' ||
                                l_num_cotizacion;
              --
              OPEN p_cursor_emision FOR
                SELECT l_num_cotizacion num_poliza FROM DUAL;
              --
            END IF;
            --
          ELSE
            --
            p_codigo_error := '400';
            p_mensaje      := 'Error en el proceso. Favor comunicarse con Oficina Comercial';
            --
            OPEN p_cursor_emision FOR
              SELECT ' ' num_poliza FROM DUAL;
            --
          END IF;
          --
        ELSE
          --
          p_codigo_error := '400';
          p_mensaje      := 'Error de Autenticacion';
          --
          OPEN p_cursor_emision FOR
            SELECT ' ' num_poliza FROM DUAL;
          --
        END IF;
        --
      ELSE
        --
        p_codigo_error := '400';
        p_mensaje      := 'Error de Autenticacion';
        --
        OPEN p_cursor_emision FOR
          SELECT ' ' num_poliza FROM DUAL;
        --
      END IF;
      --
    ELSE
      --
      p_codigo_error := '400';
      p_mensaje      := 'Error de Autenticacion';
      --
      OPEN p_cursor_emision FOR
        SELECT ' ' num_poliza FROM DUAL;
      --
    END IF;
    --
    ptraza(g_nom_archivo,
           'a',
           'FIN p_codigo_error ' || p_codigo_error || ' p_mensaje ' ||
           p_mensaje || ' Cotizacion ' || l_num_cotizacion);
    --
  EXCEPTION
    WHEN OTHERS THEN
      p_codigo_error := '99';
      p_mensaje      := g_mensaje_error_general;
      ptraza(g_nom_archivo, 'a', 'Error General p_emision_ws ' || SQLERRM);
      --
  END p_emision_ws_ap;
  --
  -- MICRO SEGUROS VIDA
  --
  PROCEDURE p_emision_ws_vi(p_token          IN VARCHAR2,
                            p_datos_riesgo   IN CLOB,
                            p_datos_tercero  IN CLOB,
                            p_codigo_error   OUT VARCHAR2,
                            p_mensaje        OUT VARCHAR2,
                            p_cursor_emision OUT gc_ref_cursor) IS
    --
    L_NLS_NUMERIC_CHARACTERS VARCHAR2(100);
    l_grabar                 BOOLEAN;
    l_emite                  VARCHAR2(1) := 'N';
    l_reg_x2000000_web       x2000000_web%ROWTYPE;
    l_cantidad               NUMBER;
    l_total_suma_aseg        NUMBER := 0;
    l_cod_nivel3             a1001332.cod_nivel3%TYPE;
    l_tercero                VARCHAR2(1) := 'N';
    l_riesgo                 VARCHAR2(1) := 'N';
    l_num_cotizacion         x2000001_web.num_cotizacion%TYPE;
    l_num_poliza             a2000030.num_poliza%TYPE;
    l_num_recibo             a2990700.num_recibo%TYPE;
    --
    l_index                 INTEGER := 0;
    l_dv_datos_riesgo_clob  CLOB := fl_limpiar_json(p_datos_riesgo);
    l_dv_datos_tercero_clob CLOB := fl_limpiar_json(p_datos_tercero);
    l_dv_cobertura          strarray;
    l_dv_poliza             strarray;
    l_dv_riesgo             strarray;
    l_parametros_emision    strarray;
    --
    l_datos_poliza_emision gc_ref_cursor;
    l_errores_emision      gc_ref_cursor;
    --
    l_cod_mon        a1000400.cod_mon%TYPE := NULL;
    l_moneda         VARCHAR2(4) := NULL;
    l_plan           VARCHAR2(4) := NULL;
    l_cod_plan       VARCHAR2(2);
    l_estatura       VARCHAR2(8) := NULL;
    l_peso           VARCHAR2(8) := NULL;
    l_fec_efec_spto  VARCHAR2(10) := NULL;
    l_cod_fracc_pago a2000020.val_campo%TYPE := 'NULL';
    --
    CURSOR c_valida_cob_muerte IS
      SELECT COUNT(DISTINCT(a.num_poliza)), SUM(d.suma_aseg)
        FROM a2000030 a, a2000060 c, a2000040 d
       WHERE a.cod_cia = g_cod_cia
         AND a.cod_ramo = g_cod_ramo_vida
         AND a.num_spto = (SELECT MAX(b.num_spto)
                             FROM a2000030 b
                            WHERE b.cod_cia = a.cod_cia
                              AND b.num_poliza = a.num_poliza
                              AND b.mca_spto_anulado = trn.NO)
         AND trunc(sysdate) BETWEEN a.fec_efec_spto and a.fec_vcto_spto
         AND a.mca_poliza_anulada = trn.NO
         AND d.cod_cia = a.cod_cia
         AND d.num_poliza = a.num_poliza
         AND d.cod_cob = 7101 -- Cobertura de Muerte
         AND d.mca_vigente = trn.SI
         AND d.mca_baja_cob = trn.NO
         AND c.cod_cia = a.cod_cia
         AND c.num_poliza = a.num_poliza
         AND c.tip_benef = g_tip_benef_aseg
         AND c.mca_vigente = trn.SI
         AND c.mca_baja = trn.NO
         AND c.tip_docum = g_tip_docum_aseg
         AND c.cod_docum = g_cod_docum_aseg;
    --
    l_longitud_terceros          NUMBER := 0;
    l_longitud_terceros_original NUMBER := 0;
    --
  BEGIN
    --
    g_session_id := p_token;
    --
    g_nom_archivo := 'ws_emision_vida';
    ptraza(g_nom_archivo,
           'w',
           '------- INICIO << p_emision_ws >> -------' || g_session_id);
    --
    trn_k_global.asigna('COD_USR', g_cod_usr);
    trn_k_global.asigna('cod_idioma', g_cod_idioma);
    trn_k_global.asigna('g_cod_usr', g_cod_usr);
    l_num_poliza := NULL;
    l_num_recibo := NULL;
    --
    BEGIN
      --
      SELECT VALUE
        INTO L_NLS_NUMERIC_CHARACTERS
        FROM nls_session_parameters
       WHERE parameter = 'NLS_NUMERIC_CHARACTERS';
      --
      ptraza('em_k_ws_auto_web_emite',
             'a',
             'NLS_NUMERIC_CHARACTERS ' || L_NLS_NUMERIC_CHARACTERS);
      --
      trn_k_dinamico.p_ejecuta_sentencia('alter session set NLS_NUMERIC_CHARACTERS = ".,"');
      trn_k_dinamico.p_ejecuta_sentencia('alter session set NLS_DATE_FORMAT="DD/MM/RR"');
      --
    EXCEPTION
      WHEN OTHERS THEN
        ptraza('em_k_ws_auto_web_emite',
               'a',
               'Error obtener NLS_NUMERIC_CHARACTERS ' || sqlerrm);
    END;
    --
    ptraza(g_nom_archivo, 'a', 'p_token ' || p_token);
    --
    IF p_token IS NOT NULL THEN
      --
      g_continua := f_valida_token(p_token);
      ptraza(g_nom_archivo, 'a', 'g_continua ' || g_continua);
      g_cod_agt := f_valida_agt_token(p_token, g_k_producto_vida);
      --
      ptraza(g_nom_archivo, 'a', 'g_cod_agt ' || g_cod_agt);
      --
      IF g_cod_agt IS NOT NULL THEN
        --
        dc_k_a1001332.p_lee(g_cod_cia,
                            to_number(g_cod_agt),
                            trunc(sysdate));
        l_cod_nivel3 := dc_k_a1001332.f_cod_nivel3;
        ptraza(g_nom_archivo,
               'a',
               'g_cod_agt ' || g_cod_agt || ' l_cod_nivel3 ' ||
               l_cod_nivel3);
        --
        ptraza(g_nom_archivo,
               'a',
               'g_continua ' || g_continua || ' g_cod_agt ' || g_cod_agt);
        --
        IF g_continua = 'S' THEN
          --
          trn_k_global.asigna('WEB_SERVICE', 'S');
          g_tab_mensajes.DELETE;
          --
          IF l_dv_datos_riesgo_clob IS NOT NULL THEN
            --
            BEGIN
              ptraza(g_nom_archivo,
                     'a',
                     'l_dv_datos_riesgo_clob ' || l_dv_datos_riesgo_clob);
              --
              l_riesgo := 'S';
              --
              dc_k_json_web.p_lee(json(l_dv_datos_riesgo_clob));
              --
              BEGIN
                --
                l_moneda        := dc_k_json_web.f_get_value('COD_MON');
                l_plan          := dc_k_json_web.f_get_value('COD_PLAN');
                l_estatura      := dc_k_json_web.f_get_value('NUM_ESTATURA');
                l_peso          := dc_k_json_web.f_get_value('NUM_PESO');
                l_fec_efec_spto := to_char(trunc(sysdate), 'dd-mm-yyyy');
                --
                IF l_moneda = 'USD' THEN
                  l_cod_mon := 84;
                ELSE
                  l_cod_mon := 55;
                END IF;
                --
                IF l_plan = 'A' THEN
                  l_cod_plan := '1';
                ELSIF l_plan = 'B' THEN
                  l_cod_plan := '2';
                END IF;
                --
              EXCEPTION
                WHEN OTHERS THEN
                  ptraza(g_nom_archivo,
                         'a',
                         'Error al leer datos del json ' || sqlerrm);
              END;
              --
              ptraza(g_nom_archivo,
                     'a',
                     'l_moneda ' || l_moneda || ' l_plan ' || l_plan ||
                     ' l_estatura ' || l_estatura || ' l_peso ' || l_peso ||
                     ' l_fec_efec_spto ' || l_fec_efec_spto ||
                     ' l_cod_mon ' || l_cod_mon);
            EXCEPTION
              WHEN OTHERS THEN
                ptraza(g_nom_archivo,
                       'a',
                       ' Error al leer l_dv_datos_riesgo_clob ' || sqlerrm);
            END;
          END IF;
          --
          IF l_dv_datos_tercero_clob IS NOT NULL THEN
            --
            SELECT length(l_dv_datos_tercero_clob), length(p_datos_tercero)
              INTO l_longitud_terceros, l_longitud_terceros_original
              FROM DUAL;
            ptraza(g_nom_archivo,
                   'a',
                   'LONGITUD ' || l_longitud_terceros ||
                   ' l_longitud_terceros_original ' ||
                   l_longitud_terceros_original);
            l_tercero := 'S';
            --
          END IF;
          --
          ptraza(g_nom_archivo,
                 'a',
                 'Riesgo ' || l_riesgo || ' Terceros ' || l_tercero);
          --
          ptraza(g_nom_archivo, 'a', '---------------------------------');
          BEGIN
            --
            IF (l_riesgo = 'S' AND l_tercero = 'S') THEN
              --
              l_num_cotizacion := em_k_util_cotizacion_web.f_num_cotizacion(g_cod_ramo_vida);
              --
              ptraza(g_nom_archivo,
                     'a',
                     'NUM_COTIZACION: ' || l_num_cotizacion ||
                     ' p_lee_datos_tercero');
              --
              p_lee_datos_tercero(l_dv_datos_tercero_clob,
                                  l_num_cotizacion);
              --
              g_reg_x2000001_web.cod_cia            := g_cod_cia;
              g_reg_x2000001_web.num_cotizacion     := l_num_cotizacion;
              g_reg_x2000001_web.cod_estatus        := g_estatus_pendiente;
              g_reg_x2000001_web.cod_ramo           := g_cod_ramo_vida;
              g_reg_x2000001_web.tip_cotizacion     := 'E';
              g_reg_x2000001_web.mca_financiamiento := 'N';
              g_reg_x2000001_web.cod_agt            := g_cod_agt;
              g_reg_x2000001_web.cod_usr            := g_cod_usr;
              g_reg_x2000001_web.fec_actu           := g_fec_actu;
              g_reg_x2000001_web.cod_modulo         := g_cod_modulo;
              g_reg_x2000001_web.cod_emp_agt        := trn.NULO; --l_sub_agt;
              g_reg_x2000001_web.datos1             := TO_CLOB(l_dv_datos_tercero_clob);
              --
              ptraza(g_nom_archivo, 'a', 'em_k_x2000001_web.p_inserta');
              em_k_x2000001_web.p_inserta(g_reg_x2000001_web);
              --
              g_tab_x2000000_web.DELETE;
              --
              ptraza(g_nom_archivo, 'a', 'DELETE FROM x2000000_web');
              DELETE FROM x2000000_web
               WHERE cod_cia = g_cod_cia
                 AND num_cotizacion = l_num_cotizacion;
              --
              COMMIT;
              --
              l_dv_riesgo    := strarray();
              l_dv_cobertura := strarray();
              l_dv_poliza    := strarray();
              --
              l_dv_poliza.EXTEND(1);
              l_index := l_dv_poliza.LAST;
              --
              l_dv_poliza(l_index) := '{';
              l_dv_poliza(l_index) := l_dv_poliza(l_index) ||
                                      'COD_MODALIDAD: "' ||
                                      g_cod_modalidad_vida || '",';
              l_dv_poliza(l_index) := l_dv_poliza(l_index) || 'COD_PLAN: "' ||
                                      l_cod_plan || '",';
              l_dv_poliza(l_index) := l_dv_poliza(l_index) ||
                                      'NUM_DIAS_GRAC: "NULL"';
              l_dv_poliza(l_index) := l_dv_poliza(l_index) || '}';
              --
              l_dv_riesgo.EXTEND(1);
              l_index := l_dv_riesgo.LAST;
              --
              l_dv_riesgo(l_index) := '{';
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'COD_PLAN: "' ||
                                      l_cod_plan || '",';
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) ||
                                      'NUM_ESTATURA: "' || l_estatura || '",';
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'NUM_PESO: "' ||
                                      l_estatura || '"';
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || '}';
              --
              ptraza(g_nom_archivo,
                     'a',
                     'PL_INSERTA_DATOS l_fec_efec_spto ' ||
                     replace(l_fec_efec_spto, '-', '') || ' COD_MON ' ||
                     l_cod_mon);
              --
              trn_k_global.asigna('ws_traza_emision', g_nom_archivo);
              --
              em_k_cotiza_micro_vida_web.pl_inserta_datos(p_session_id          => g_session_id,
                                                          p_cod_cia             => g_cod_cia,
                                                          p_cod_ramo            => g_cod_ramo_vida,
                                                          p_cod_mon             => l_cod_mon,
                                                          p_num_cotizacion      => l_num_cotizacion,
                                                          p_fec_efec_poliza     => l_fec_efec_spto,
                                                          p_num_duracion_poliza => g_num_duracion_poliza,
                                                          p_txt_duracion_poliza => ' ', --p_txt_duracion_poliza,
                                                          p_num_poliza_grupo    => trn.NULO,
                                                          p_num_contrato        => trn.NULO,
                                                          p_cod_modalidad       => g_cod_modalidad_vida,
                                                          p_cod_fracc_pago      => NVL(l_cod_fracc_pago,
                                                                                       1),
                                                          p_cod_nivel3          => l_cod_nivel3,
                                                          p_dv_poliza           => l_dv_poliza,
                                                          p_dv_riesgo           => l_dv_riesgo,
                                                          p_dv_cobertura        => l_dv_cobertura,
                                                          p_dat_asegurado       => g_dv_tercero);
              --
              ptraza(g_nom_archivo,
                     'a',
                     '-----------------Despues de em_k_cotiza_micro_vida_web.pl_inserta_datos');
              ptraza(g_nom_archivo,
                     'a',
                     'COUNT ' || g_tab_x2000000_web.COUNT);
              IF g_tab_x2000000_web.COUNT > 0 THEN
                --
                l_emite := 'S';
                --
                FOR fila IN g_tab_x2000000_web.FIRST .. g_tab_x2000000_web.LAST LOOP
                  --
                  BEGIN
                    --
                    IF (g_tab_x2000000_web(fila).cod_campo = 'COD_COBERTURA') AND
                       (g_tab_x2000000_web(fila).txt_campo1 IS NULL) AND
                       (g_tab_x2000000_web(fila).txt_campo2 IS NULL) THEN
                      --
                      l_grabar := FALSE;
                      --
                    ELSE
                      --
                      l_grabar := TRUE;
                      --
                    END IF;
                    --
                    IF l_grabar THEN
                      --
                      l_reg_x2000000_web := fl_to_reg_x2000000_web(g_tab_x2000000_web(fila));
                      --
                      ptraza(g_nom_archivo,
                             'a',
                             'INSERT INTO x2000000_web CAMPO ' ||
                             l_reg_x2000000_web.cod_campo || ' VALOR ' ||
                             l_reg_x2000000_web.val_campo || ' RIEGO ' ||
                             l_reg_x2000000_web.num_riesgo || ' NUM_SECU ' ||
                             l_reg_x2000000_web.num_secu);
                      --
                      INSERT INTO x2000000_web
                        (cod_cia,
                         num_cotizacion,
                         num_riesgo,
                         cod_campo,
                         num_secu,
                         val_campo,
                         txt_campo,
                         txt_campo1,
                         txt_campo2)
                      VALUES
                        (l_reg_x2000000_web.cod_cia,
                         l_reg_x2000000_web.num_cotizacion,
                         l_reg_x2000000_web.num_riesgo,
                         l_reg_x2000000_web.cod_campo,
                         l_reg_x2000000_web.num_secu,
                         l_reg_x2000000_web.val_campo,
                         l_reg_x2000000_web.txt_campo,
                         l_reg_x2000000_web.txt_campo1,
                         l_reg_x2000000_web.txt_campo2);
                      --
                    END IF;
                    --
                  EXCEPTION
                    WHEN OTHERS THEN
                      --
                      ptraza(g_nom_archivo,
                             'a',
                             'Error insert x2000000_web Campo ' ||
                             l_reg_x2000000_web.cod_campo || ' ' || SQLERRM);
                      --
                  END;
                  --
                END LOOP;
                --
                COMMIT;
                --
              END IF;
              --
              /*BEGIN
                -- Valida cobertura de muerte
                l_cantidad        := 0;
                l_total_suma_aseg := 0;
                ptraza(g_nom_archivo,
                       'a',
                       'VALIDA COBERTURA DE MUERTE. Asegurado ' ||
                       g_tip_docum_aseg || ' ' || g_cod_docum_aseg);
                --
                OPEN c_valida_cob_muerte;
                FETCH c_valida_cob_muerte
                  INTO l_cantidad, l_total_suma_aseg;
                CLOSE c_valida_cob_muerte;
                --
                ptraza(g_nom_archivo, 'a', 'CANTIDAD ' || l_cantidad);
                --
                IF (l_cantidad >= 4 OR l_total_suma_aseg > 10000) THEN
                  --
                  ptraza(g_nom_archivo,
                         'a',
                         '   REGISTRA ERROR POR CANTIDAD DE EMISIONES O SUMA ASEGURADA');
                  dc_k_util_web.p_set_mensaje(p_cod_cia         => g_cod_cia,
                                              p_session_id      => g_session_id,
                                              p_cod_mensaje     => 80997,
                                              p_cod_idioma      => g_cod_idioma,
                                              p_txt_mensaje     => '. NO SE PUEDE COMPLETAR LA EMISION',
                                              p_mca_tip_mensaje => 'E');
                  --
                END IF;
                --
              EXCEPTION
                WHEN OTHERS THEN
                  ptraza(g_nom_archivo,
                         'a',
                         'Error validacion ' || sqlerrm);
              END;*/
              --
            END IF;
            --
          EXCEPTION
            WHEN OTHERS THEN
              --
              ptraza(g_nom_archivo,
                     'a',
                     'Error en << p_generar_cotizacion >>: ' || SQLERRM);
              --
              dc_k_util_web.p_set_mensaje(p_cod_cia         => g_cod_cia,
                                          p_session_id      => g_session_id,
                                          p_cod_mensaje     => -20001,
                                          p_cod_idioma      => g_cod_idioma,
                                          p_txt_mensaje     => SQLERRM,
                                          p_mca_tip_mensaje => 'E');
              --
          END;
          --
          IF l_num_cotizacion IS NOT NULL THEN
            --
            BEGIN
              l_num_poliza := trn.NULO;
              ptraza(g_nom_archivo,
                     'a',
                     'EMITE LA POLIZA l_emite ' || l_emite);
              --
              l_parametros_emision := strarray();
              l_parametros_emision.EXTEND(1);
              l_index := l_parametros_emision.LAST;
              --
              l_parametros_emision(l_index) := '{';
              l_parametros_emision(l_index) := l_parametros_emision(l_index) ||
                                               'SESSION_ID: "' ||
                                               g_session_id || '",';
              l_parametros_emision(l_index) := l_parametros_emision(l_index) ||
                                               'COD_CIA: "' || g_cod_cia || '",';
              l_parametros_emision(l_index) := l_parametros_emision(l_index) ||
                                               'COD_FRACC_PAGO: "' ||
                                               nvl(l_cod_fracc_pago, 1) || '",';
              l_parametros_emision(l_index) := l_parametros_emision(l_index) ||
                                               'MCA_DOMICILIADO: "' || 'N' || '",';
              l_parametros_emision(l_index) := l_parametros_emision(l_index) ||
                                               'TIP_GESTOR: "' || 'AG' || '",';
              l_parametros_emision(l_index) := l_parametros_emision(l_index) ||
                                               'COD_GESTOR: "' || g_cod_agt || '",';
              l_parametros_emision(l_index) := l_parametros_emision(l_index) ||
                                               'COD_OFICINA: "' ||
                                               l_cod_nivel3 || '",';
              l_parametros_emision(l_index) := l_parametros_emision(l_index) ||
                                               'FEC_EFEC_SPTO: "' ||
                                               l_fec_efec_spto || '",';
              l_parametros_emision(l_index) := l_parametros_emision(l_index) ||
                                               'NUM_COTIZACION: "' ||
                                               l_num_cotizacion || '"';
              l_parametros_emision(l_index) := l_parametros_emision(l_index) || '}';
              --
              ptraza(g_nom_archivo,
                     'a',
                     'inicia em_k_cotiza_micro_vida_web.p_emite_poliza');
              em_k_cotiza_micro_vida_web.p_emite_poliza(l_parametros_emision, --   IN strarray,
                                                        l_datos_poliza_emision, -- OUT gc_ref_cursor,
                                                        l_errores_emision); --      OUT gc_ref_cursor)
              --
              ptraza(g_nom_archivo,
                     'a',
                     'fin em_k_cotiza_micro_vida_web.p_emite_poliza');
              --
              LOOP
                FETCH l_datos_poliza_emision
                  INTO l_num_poliza, l_num_recibo;
                EXIT WHEN l_datos_poliza_emision%NOTFOUND;
                --
                ptraza(g_nom_archivo,
                       'a',
                       '   NUM_POLIZA ' || l_num_poliza || ' RECIBO ' ||
                       l_num_recibo);
              END LOOP;
              --
            EXCEPTION
              WHEN OTHERS THEN
                l_num_poliza := NULL;
                l_num_recibo := NULL;
                --
                ptraza(g_nom_archivo,
                       'a',
                       '        ERROR p_emite_poliza ' || SQLERRM);
            END;
            --  
            IF l_num_poliza IS NOT NULL THEN
              --            
              p_codigo_error := '00';
              p_mensaje      := 'Emision Exitosa Poliza No. ' ||
                                l_num_poliza || ' Recibo No. ' ||
                                l_num_recibo;
              --
              OPEN p_cursor_emision FOR
                SELECT l_num_poliza num_poliza FROM DUAL;
              --
            ELSE
              --            
              p_codigo_error := '400';
              p_mensaje      := 'Falla en Emision - se genero Cotizacion No. ' ||
                                l_num_cotizacion;
              --
              OPEN p_cursor_emision FOR
                SELECT l_num_cotizacion num_poliza FROM DUAL;
              --
            END IF;
            --
          ELSE
            --
            p_codigo_error := '400';
            p_mensaje      := 'Error en el proceso. Favor comunicarse con Oficina Comercial';
            --
            OPEN p_cursor_emision FOR
              SELECT ' ' num_poliza FROM DUAL;
            --
          END IF;
          --
        ELSE
          --
          p_codigo_error := '400';
          p_mensaje      := 'Error de Autenticacion';
          --
          OPEN p_cursor_emision FOR
            SELECT ' ' num_poliza FROM DUAL;
          --
        END IF;
        --
      ELSE
        --
        p_codigo_error := '400';
        p_mensaje      := 'Error de Autenticacion';
        --
        OPEN p_cursor_emision FOR
          SELECT ' ' num_poliza FROM DUAL;
        --
      END IF;
      --
    ELSE
      --
      p_codigo_error := '400';
      p_mensaje      := 'Error de Autenticacion';
      --
      OPEN p_cursor_emision FOR
        SELECT ' ' num_poliza FROM DUAL;
      --
    END IF;
    --
    ptraza(g_nom_archivo,
           'a',
           'FIN p_codigo_error ' || p_codigo_error || ' p_mensaje ' ||
           p_mensaje || ' Cotizacion ' || l_num_cotizacion);
    --
  EXCEPTION
    WHEN OTHERS THEN
      p_codigo_error := '99';
      p_mensaje      := g_mensaje_error_general;
      ptraza(g_nom_archivo, 'a', 'Error General p_emision_ws ' || SQLERRM);
      --
  END p_emision_ws_vi;
  --
  -- MICRO SEGUROS SOA
  --
  PROCEDURE p_emision_ws_soa(p_token          IN VARCHAR2,
                             p_datos_riesgo   IN CLOB,
                             p_datos_tercero  IN CLOB,
                             p_codigo_error   OUT VARCHAR2,
                             p_mensaje        OUT VARCHAR2,
                             p_cursor_emision OUT gc_ref_cursor) IS
    --
    L_NLS_NUMERIC_CHARACTERS VARCHAR2(100);
    l_grabar                 BOOLEAN;
    l_emite                  VARCHAR2(1) := 'N';
    l_reg_x2000000_web       x2000000_web%ROWTYPE;
    l_cantidad               NUMBER;
    l_total_suma_aseg        NUMBER := 0;
    l_cod_nivel3             a1001332.cod_nivel3%TYPE;
    l_tercero                VARCHAR2(1) := 'N';
    l_riesgo                 VARCHAR2(1) := 'N';
    l_num_cotizacion         x2000001_web.num_cotizacion%TYPE;
    l_num_poliza             a2000030.num_poliza%TYPE;
    l_num_recibo             a2990700.num_recibo%TYPE;
    --
    l_index                 INTEGER := 0;
    l_dv_datos_riesgo_clob  CLOB := fl_limpiar_json(p_datos_riesgo);
    l_dv_datos_tercero_clob CLOB := fl_limpiar_json(p_datos_tercero);
    l_dv_cobertura          strarray;
    l_dv_poliza             strarray;
    l_dv_riesgo             strarray;
    l_parametros_emision    strarray;
    --
    l_datos_poliza_emision gc_ref_cursor;
    l_errores_emision      gc_ref_cursor;
    --
    l_cod_mon        a1000400.cod_mon%TYPE := NULL;
    l_moneda         VARCHAR2(4) := NULL;
    l_cod_ano        VARCHAR2(4) := NULL;
    l_cod_categoria  VARCHAR2(20) := NULL;
    l_cod_clase      VARCHAR2(20) := NULL;
    l_cod_color      VARCHAR2(20) := NULL;
    l_cod_marca      VARCHAR2(20) := NULL;
    l_cod_modelo     VARCHAR2(20) := NULL;
    l_cod_sub_modelo VARCHAR2(20) := NULL;
    l_cod_tipo       VARCHAR2(20) := NULL;
    l_cod_uso        VARCHAR2(20) := NULL;
    l_des_chasis     VARCHAR2(50) := NULL;
    l_des_motor      VARCHAR2(50) := NULL;
    l_num_placa      VARCHAR2(20) := NULL;
    l_num_pasajeros  VARCHAR2(2) := NULL;
    l_num_tonelaje   VARCHAR2(4) := NULL;
    l_fec_efec_spto  VARCHAR2(10) := NULL;
    l_MCA_VEH_ESP    VARCHAR2(10) := 'N';
    l_COD_USO_IMP    VARCHAR2(10) := '1';
    l_COD_MERCADO    VARCHAR2(10) := '3';
    l_COD_CANAL_DIST VARCHAR2(10) := '6';
    l_cod_fracc_pago a2000020.val_campo%TYPE := 'NULL';
    --
    CURSOR c_valida_cob_muerte IS
      SELECT COUNT(DISTINCT(a.num_poliza)), SUM(d.suma_aseg)
        FROM a2000030 a, a2000060 c, a2000040 d
       WHERE a.cod_cia = g_cod_cia
         AND a.cod_ramo = g_cod_ramo_soa
         AND a.num_spto = (SELECT MAX(b.num_spto)
                             FROM a2000030 b
                            WHERE b.cod_cia = a.cod_cia
                              AND b.num_poliza = a.num_poliza
                              AND b.mca_spto_anulado = trn.NO)
         AND trunc(sysdate) BETWEEN a.fec_efec_spto and a.fec_vcto_spto
         AND a.mca_poliza_anulada = trn.NO
         AND d.cod_cia = a.cod_cia
         AND d.num_poliza = a.num_poliza
         AND d.cod_cob = 7101 -- Cobertura de Muerte
         AND d.mca_vigente = trn.SI
         AND d.mca_baja_cob = trn.NO
         AND c.cod_cia = a.cod_cia
         AND c.num_poliza = a.num_poliza
         AND c.tip_benef = g_tip_benef_aseg
         AND c.mca_vigente = trn.SI
         AND c.mca_baja = trn.NO
         AND c.tip_docum = g_tip_docum_aseg
         AND c.cod_docum = g_cod_docum_aseg;
    --
    l_longitud_terceros          NUMBER := 0;
    l_longitud_terceros_original NUMBER := 0;
    --
  BEGIN
    --
    g_session_id := p_token;
    --
    g_nom_archivo := 'ws_emision_soa_' || g_session_id;
    ptraza(g_nom_archivo, 'w', '------- INICIO << p_emision_ws >> -------');
    --
    trn_k_global.asigna('COD_USR', g_cod_usr);
    trn_k_global.asigna('cod_idioma', g_cod_idioma);
    trn_k_global.asigna('g_cod_usr', g_cod_usr);
    l_num_poliza := NULL;
    l_num_recibo := NULL;
    --
    BEGIN
      --
      SELECT VALUE
        INTO L_NLS_NUMERIC_CHARACTERS
        FROM nls_session_parameters
       WHERE parameter = 'NLS_NUMERIC_CHARACTERS';
      --
      ptraza(g_nom_archivo,
             'a',
             'NLS_NUMERIC_CHARACTERS ' || L_NLS_NUMERIC_CHARACTERS);
      --
      trn_k_dinamico.p_ejecuta_sentencia('alter session set NLS_NUMERIC_CHARACTERS = ".,"');
      trn_k_dinamico.p_ejecuta_sentencia('alter session set NLS_DATE_FORMAT="DD/MM/RR"');
      --
    EXCEPTION
      WHEN OTHERS THEN
        ptraza(g_nom_archivo,
               'a',
               'Error obtener NLS_NUMERIC_CHARACTERS ' || sqlerrm);
    END;
    --
    ptraza(g_nom_archivo, 'a', 'p_token ' || p_token);
    --
    IF p_token IS NOT NULL THEN
      --
      g_continua := f_valida_token(p_token);
      ptraza(g_nom_archivo, 'a', 'g_continua ' || g_continua);
      g_cod_agt := f_valida_agt_token(p_token, g_k_producto_soa);
      --
      ptraza(g_nom_archivo, 'a', 'g_cod_agt ' || g_cod_agt);
      --
      IF g_cod_agt IS NOT NULL THEN
        --
        dc_k_a1001332.p_lee(g_cod_cia,
                            to_number(g_cod_agt),
                            trunc(sysdate));
        l_cod_nivel3 := dc_k_a1001332.f_cod_nivel3;
        ptraza(g_nom_archivo,
               'a',
               'g_cod_agt ' || g_cod_agt || ' l_cod_nivel3 ' ||
               l_cod_nivel3 || ' g_continua ' || g_continua);
        --
        IF g_continua = 'S' THEN
          --
          trn_k_global.asigna('WEB_SERVICE', 'S');
          g_tab_mensajes.DELETE;
          --
          IF l_dv_datos_riesgo_clob IS NOT NULL THEN
            --
            BEGIN
              ptraza(g_nom_archivo,
                     'a',
                     'DATOS RIESGOS ' || l_dv_datos_riesgo_clob);
              --
              l_riesgo := 'S';
              --
              dc_k_json_web.p_lee(json(l_dv_datos_riesgo_clob));
              --
              BEGIN
                --
                l_moneda         := dc_k_json_web.f_get_value('COD_MON');
                l_fec_efec_spto  := to_char(trunc(sysdate), 'dd-mm-yyyy');
                l_cod_ano        := dc_k_json_web.f_get_value('COD_ANO');
                l_cod_categoria  := dc_k_json_web.f_get_value('COD_CATEGORIA');
                l_cod_clase      := dc_k_json_web.f_get_value('COD_CLASE');
                l_cod_color      := dc_k_json_web.f_get_value('COD_COLOR');
                l_cod_marca      := dc_k_json_web.f_get_value('COD_MARCA');
                l_cod_modelo     := dc_k_json_web.f_get_value('COD_MODELO');
                l_cod_sub_modelo := dc_k_json_web.f_get_value('COD_SUB_MODELO');
                l_cod_tipo       := dc_k_json_web.f_get_value('COD_TIPO');
                l_cod_uso        := dc_k_json_web.f_get_value('COD_USO');
                l_des_chasis     := dc_k_json_web.f_get_value('DES_CHASIS');
                l_des_motor      := dc_k_json_web.f_get_value('DES_MOTOR');
                l_num_placa      := dc_k_json_web.f_get_value('NUM_PLACA');
                l_num_pasajeros  := dc_k_json_web.f_get_value('NUM_PASAJEROS');
                l_num_tonelaje   := dc_k_json_web.f_get_value('NUM_TONELAJE');
                --
                IF l_moneda = 'USD' THEN
                  l_cod_mon := 84;
                ELSE
                  l_cod_mon := 55;
                END IF;
                --
              EXCEPTION
                WHEN OTHERS THEN
                  ptraza(g_nom_archivo,
                         'a',
                         'Error al leer datos del json ' || sqlerrm);
              END;
              --
              ptraza(g_nom_archivo,
                     'a',
                     'l_moneda ' || l_moneda || ' l_fec_efec_spto ' ||
                     l_fec_efec_spto || ' l_cod_mon ' || l_cod_mon ||' cod_ano '||l_cod_ano||
                     ' l_cod_categoria ' || l_cod_categoria ||
                     ' l_cod_clase ' || l_cod_clase || ' l_cod_color ' ||
                     l_cod_color || ' l_cod_marca ' || l_cod_marca ||
                     ' l_cod_modelo ' || l_cod_modelo ||
                     ' l_cod_sub_modelo ' || l_cod_sub_modelo);
              ptraza(g_nom_archivo,
                     'a',
                     'l_cod_tipo ' || l_cod_tipo || ' l_cod_uso ' ||
                     l_cod_uso || ' l_des_chasis ' || l_des_chasis ||
                     ' l_des_motor ' || l_des_motor || ' l_num_placa ' ||
                     l_num_placa || ' l_num_pasajeros ' || l_num_pasajeros ||
                     ' l_num_tonelaje ' || l_num_tonelaje);
            EXCEPTION
              WHEN OTHERS THEN
                ptraza(g_nom_archivo,
                       'a',
                       ' Error al leer l_dv_datos_riesgo_clob ' || sqlerrm);
            END;
          END IF;
          --
          IF l_dv_datos_tercero_clob IS NOT NULL THEN
            --
            SELECT length(l_dv_datos_tercero_clob), length(p_datos_tercero)
              INTO l_longitud_terceros, l_longitud_terceros_original
              FROM DUAL;
            ptraza(g_nom_archivo,
                   'a',
                   'LONGITUD ' || l_longitud_terceros ||
                   ' l_longitud_terceros_original ' ||
                   l_longitud_terceros_original || ' l_tercero ' ||
                   l_tercero);
            l_tercero := 'S';
            --
          END IF;
          --
          ptraza(g_nom_archivo,
                 'a',
                 'Riesgo ' || l_riesgo || ' Terceros ' || l_tercero);
          --
          ptraza(g_nom_archivo, 'a', '---------------------------------');
          BEGIN
            --
            IF (l_riesgo = 'S' AND l_tercero = 'S') THEN
              --
              l_num_cotizacion := em_k_util_cotizacion_web.f_num_cotizacion(g_cod_ramo_soa);
              --
              ptraza(g_nom_archivo,
                     'a',
                     'NUM_COTIZACION: ' || l_num_cotizacion ||
                     ' p_lee_datos_tercero');
              --
              p_lee_datos_tercero(l_dv_datos_tercero_clob,
                                  l_num_cotizacion);
              --
              g_reg_x2000001_web.cod_cia            := g_cod_cia;
              g_reg_x2000001_web.num_cotizacion     := l_num_cotizacion;
              g_reg_x2000001_web.cod_estatus        := g_estatus_pendiente;
              g_reg_x2000001_web.cod_ramo           := g_cod_ramo_soa;
              g_reg_x2000001_web.tip_cotizacion     := 'E';
              g_reg_x2000001_web.mca_financiamiento := 'N';
              g_reg_x2000001_web.cod_agt            := g_cod_agt;
              g_reg_x2000001_web.cod_usr            := g_cod_usr;
              g_reg_x2000001_web.fec_actu           := g_fec_actu;
              g_reg_x2000001_web.cod_modulo         := g_cod_modulo;
              g_reg_x2000001_web.cod_emp_agt        := trn.NULO; --l_sub_agt;
              g_reg_x2000001_web.datos1             := TO_CLOB(l_dv_datos_tercero_clob);
              --
              ptraza(g_nom_archivo, 'a', 'em_k_x2000001_web.p_inserta');
              em_k_x2000001_web.p_inserta(g_reg_x2000001_web);
              --
              g_tab_x2000000_web.DELETE;
              --
              ptraza(g_nom_archivo, 'a', 'DELETE FROM x2000000_web');
              DELETE FROM x2000000_web
               WHERE cod_cia = g_cod_cia
                 AND num_cotizacion = l_num_cotizacion;
              --
              COMMIT;
              --
              l_dv_riesgo    := strarray();
              l_dv_cobertura := strarray();
              l_dv_poliza    := strarray();
              --
              l_dv_poliza.EXTEND(1);
              l_index := l_dv_poliza.LAST;
              --
              l_dv_poliza(l_index) := '{';
              l_dv_poliza(l_index) := l_dv_poliza(l_index) ||
                                      'COD_MODALIDAD: "' ||
                                      g_cod_modalidad_acc || '",';
              l_dv_poliza(l_index) := l_dv_poliza(l_index) ||
                                      'NUM_DIAS_GRAC: "NULL"';
              l_dv_poliza(l_index) := l_dv_poliza(l_index) || '}';
              --
              l_dv_riesgo.EXTEND(1);
              l_index := l_dv_riesgo.LAST;
              -- COD_MODALIDAD
              l_dv_riesgo(l_index) := '{';
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'COD_MON: "' ||
                                      l_moneda || '",';
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) ||
                                      'COD_ANO: "' || l_cod_ano || '",';
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'COD_CATEGORIA: "' ||
                                      l_cod_categoria || '",';
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'COD_MODALIDAD: "' ||
                                      g_cod_modalidad_soa || '",';
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'COD_CLASE: "' ||
                                      l_cod_clase || '",';
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'COD_COLOR: "' ||
                                      l_cod_color || '",';
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'COD_MARCA: "' ||
                                      l_cod_marca || '",';
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'COD_MODELO: "' ||
                                      l_cod_modelo || '",';
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'COD_SUB_MODELO: "' ||
                                      l_cod_sub_modelo || '",';
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'COD_TIPO: "' ||
                                      l_cod_tipo || '",';
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'COD_USO: "' ||
                                      l_cod_uso || '",';
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'DES_CHASIS: "' ||
                                      l_des_chasis || '",';
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'DES_MOTOR: "' ||
                                      l_des_motor || '",';
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'NUM_PASAJEROS: "' ||
                                      l_num_pasajeros || '",';
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'NUM_PLACA: "' ||
                                      l_num_placa || '",';
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'MCA_VEH_ESP: "' ||
                                      l_MCA_VEH_ESP || '",';
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'COD_USO_IMP: "' ||
                                      l_COD_USO_IMP || '",';
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'COD_MERCADO: "' ||
                                      l_COD_MERCADO || '",';
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'COD_CANAL_DIST: "' ||
                                      l_COD_CANAL_DIST || '",';
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'MCA_CERO_KM: "' ||
                                      'N' || '",';-- ojo obtener constante
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'MCA_VAL_ACTUAL: "' ||
                                      'S' || '",'; -- ojo obtener constante                       
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'IMP_VAL_NUEVO: "' ||
                                      '0' || '",';  -- ojo obtener constante
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'IMP_VAL_ACTUAL: "' ||
                                      '0' || '",';  -- ojo obtener constante
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'MCA_TRAN_MAN: "' ||
                                      'N' || '",'; -- ojo obtener constante
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'MCA_SIST_ELECT: "' ||
                                      'N' || '",'; -- ojo obtener constante
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'MCA_GARAG_CERR: "' ||
                                      'N' || '",';-- ojo obtener constante
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'MCA_SEG_RC: "' ||
                                      'S' || '",';-- ojo obtener constante
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'MCA_DESC_SEG_RC: "' ||
                                      'S' || '",';-- ojo obtener constante
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'PCT_DES_SEG_RC: "' ||
                                      '12' || '",'; -- ojo obtener constante
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'IMP_IVA: "' ||
                                      '0' || '",'; -- ojo obtener constante
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'IMP_GAS_DE: "' ||
                                      '0' || '",'; -- ojo obtener constante                        
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'IMP_PR_NETA: "' ||
                                      '0' || '",'; -- ojo obtener constante                        
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'MCA_ASIS: "' ||
                                      'N' || '",'; -- ojo obtener constante        
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'MCA_COB_CAT: "' ||
                                      'N' || '",'; -- ojo obtener constante        
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'MCA_COB_COL: "' ||
                                      'N' || '",'; -- ojo obtener constante        
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'MCA_COB_DM: "' ||
                                      'N' || '",'; -- ojo obtener constante        
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'MCA_COB_EXTCAP: "' ||
                                      'N' || '",'; -- ojo obtener constante        
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'MCA_COB_RTRP: "' ||
                                      'N' || '",'; -- ojo obtener constante        
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'MCA_COB_RV: "' ||
                                      'N' || '",'; -- ojo obtener constante        
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'MCA_COB_TUM: "' ||
                                      'N' || '",'; -- ojo obtener constante        
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'MCA_DEV_DER_EMI: "' ||
                                      'N' || '",'; -- ojo obtener constante        
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'MCA_EXCENTA_IMP: "' ||
                                      'N' || '",'; -- ojo obtener constante        
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'MCA_EXONERA_IMP: "' ||
                                      'N' || '",'; -- ojo obtener constante        
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'MCA_EXPEDIENTE: "' ||
                                      'S' || '",'; -- ojo obtener constante        
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'MCA_COB_EXTCAM: "' ||
                                      'N' || '",'; -- ojo obtener constante        
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'MCA_COB_PTRT: "' ||
                                      'N' || '",'; -- ojo obtener constante        
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'MCA_COB_PTS: "' ||
                                      'N' || '",'; -- ojo obtener constante        
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'MCA_COB_VR: "' ||
                                      'N' || '",'; -- ojo obtener constante        
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'MCA_COLECTIVO: "' ||
                                      'N' || '",'; -- ojo obtener constante        
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'MCA_COB_RCDTEX: "' ||
                                      'N' || '",'; -- ojo obtener constante        
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'MCA_TAL_ELE: "' ||
                                      'N' || '",'; -- ojo obtener constante        
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'MCA_COB_EM: "' ||
                                      'N' || '",'; -- ojo obtener constante        
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'MCA_DESC_COB: "' ||
                                      'N' || '",'; -- ojo obtener constante        
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'MCA_SUST_INFLAM: "' ||
                                      'N' || '",'; -- ojo obtener constante        
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'MCA_REC_GRUA: "' ||
                                      'N' || '",'; -- ojo obtener constante        
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'MCA_DED_ELEG: "' ||
                                      'N' || '",'; -- ojo obtener constante        
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'NUM_OPER: "' ||
                                      '0' || '",'; -- ojo obtener constante 
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || 'NUM_TONELAJE: "' ||
                                      l_num_tonelaje || '"';
              l_dv_riesgo(l_index) := l_dv_riesgo(l_index) || '}';
              -- MCA_TRAN_MAN
              ptraza(g_nom_archivo,
                     'a',
                     'PL_INSERTA_DATOS l_fec_efec_spto ' ||
                     replace(l_fec_efec_spto, '-', '') || ' COD_MON ' ||
                     l_cod_mon);
              --
              trn_k_global.asigna('ws_traza_emision', g_nom_archivo);
              --
              em_k_cotiza_auto_soa_web.pl_inserta_datos(p_session_id          => g_session_id,
                                                        p_cod_cia             => g_cod_cia,
                                                        p_cod_ramo            => g_cod_ramo_soa,
                                                        p_cod_mon             => l_cod_mon,
                                                        p_num_cotizacion      => l_num_cotizacion,
                                                        p_fec_efec_poliza     => l_fec_efec_spto,
                                                        p_num_duracion_poliza => g_num_duracion_poliza,
                                                        p_txt_duracion_poliza => ' ', --p_txt_duracion_poliza,
                                                        p_num_poliza_grupo    => trn.NULO,
                                                        p_num_contrato        => trn.NULO,
                                                        p_cod_modalidad       => g_cod_modalidad_soa,
                                                        p_cod_fracc_pago      => l_cod_fracc_pago,
                                                        p_cod_nivel3          => l_cod_nivel3,
                                                        p_dv_poliza           => l_dv_poliza,
                                                        p_dv_riesgo           => l_dv_riesgo,
                                                        p_dv_cobertura        => l_dv_cobertura,
                                                        p_dat_asegurado       => g_dv_tercero);
              --
              ptraza(g_nom_archivo,
                     'a',
                     '-----------------Despues de em_k_cotiza_auto_soa_web.pl_inserta_datos');
              ptraza(g_nom_archivo,
                     'a',
                     'COUNT ' || g_tab_x2000000_web.COUNT);
              IF (g_tab_x2000000_web.COUNT > 0 OR g_tab_x2000000_web.COUNT = 0) THEN -- OJO
                --
                l_emite := 'S';
                --
                ptraza(g_nom_archivo,
                     'a',
                     'RECORRE g_tab_x2000000_web');
                FOR fila IN g_tab_x2000000_web.FIRST .. g_tab_x2000000_web.LAST LOOP
                  --
                  BEGIN
                    --
                    IF (g_tab_x2000000_web(fila).cod_campo = 'COD_COBERTURA') AND
                       (g_tab_x2000000_web(fila).txt_campo1 IS NULL) AND
                       (g_tab_x2000000_web(fila).txt_campo2 IS NULL) THEN
                      --
                      l_grabar := FALSE;
                      --
                    ELSE
                      --
                      l_grabar := TRUE;
                      --
                    END IF;
                    --
                    IF l_grabar THEN
                      --
                      l_reg_x2000000_web := fl_to_reg_x2000000_web(g_tab_x2000000_web(fila));
                      --
                      ptraza(g_nom_archivo,
                             'a',
                             'INSERT INTO x2000000_web CAMPO ' ||
                             l_reg_x2000000_web.cod_campo || ' VALOR ' ||
                             l_reg_x2000000_web.val_campo || ' RIEGO ' ||
                             l_reg_x2000000_web.num_riesgo || ' NUM_SECU ' ||
                             l_reg_x2000000_web.num_secu);
                      --
                      INSERT INTO x2000000_web
                        (cod_cia,
                         num_cotizacion,
                         num_riesgo,
                         cod_campo,
                         num_secu,
                         val_campo,
                         txt_campo,
                         txt_campo1,
                         txt_campo2)
                      VALUES
                        (l_reg_x2000000_web.cod_cia,
                         l_reg_x2000000_web.num_cotizacion,
                         l_reg_x2000000_web.num_riesgo,
                         l_reg_x2000000_web.cod_campo,
                         l_reg_x2000000_web.num_secu,
                         l_reg_x2000000_web.val_campo,
                         l_reg_x2000000_web.txt_campo,
                         l_reg_x2000000_web.txt_campo1,
                         l_reg_x2000000_web.txt_campo2);
                      --
                    END IF;
                    --
                  EXCEPTION
                    WHEN OTHERS THEN
                      --
                      ptraza(g_nom_archivo,
                             'a',
                             'Error insert x2000000_web Campo ' ||
                             l_reg_x2000000_web.cod_campo || ' ' || SQLERRM);
                      --
                  END;
                  --
                END LOOP;
                --
                COMMIT;
                --
              END IF;
              --
            END IF;
            --
          EXCEPTION
            WHEN OTHERS THEN
              --
              ptraza(g_nom_archivo,
                     'a',
                     'Error en << p_emision_ws_soa >>: ' || SQLERRM);
              --
              dc_k_util_web.p_set_mensaje(p_cod_cia         => g_cod_cia,
                                          p_session_id      => g_session_id,
                                          p_cod_mensaje     => -20001,
                                          p_cod_idioma      => g_cod_idioma,
                                          p_txt_mensaje     => SQLERRM,
                                          p_mca_tip_mensaje => 'E');
              --
          END;
          --
          IF l_num_cotizacion IS NOT NULL THEN
            --
            BEGIN
              l_num_poliza := trn.NULO;
              ptraza(g_nom_archivo,
                     'a',
                     'EMITE LA POLIZA l_emite ' || l_emite);
              --
              l_parametros_emision := strarray();
              l_parametros_emision.EXTEND(1);
              l_index := l_parametros_emision.LAST;
              --
              l_parametros_emision(l_index) := '{';
              l_parametros_emision(l_index) := l_parametros_emision(l_index) ||
                                               'SESSION_ID: "' ||
                                               g_session_id || '",';
              l_parametros_emision(l_index) := l_parametros_emision(l_index) ||
                                               'COD_CIA: "' || g_cod_cia || '",';
              l_parametros_emision(l_index) := l_parametros_emision(l_index) ||
                                               'COD_FRACC_PAGO: "' ||
                                               nvl(l_cod_fracc_pago, 1) || '",';
              l_parametros_emision(l_index) := l_parametros_emision(l_index) ||
                                               'MCA_DOMICILIADO: "' || 'N' || '",';
              l_parametros_emision(l_index) := l_parametros_emision(l_index) ||
                                               'TIP_GESTOR: "' || 'AG' || '",';
              l_parametros_emision(l_index) := l_parametros_emision(l_index) ||
                                               'COD_GESTOR: "' || g_cod_agt || '",';
              l_parametros_emision(l_index) := l_parametros_emision(l_index) ||
                                               'COD_OFICINA: "' ||
                                               l_cod_nivel3 || '",';
              l_parametros_emision(l_index) := l_parametros_emision(l_index) ||
                                               'FEC_EFEC_SPTO: "' ||
                                               l_fec_efec_spto || '",';
              l_parametros_emision(l_index) := l_parametros_emision(l_index) ||
                                               'NUM_COTIZACION: "' ||
                                               l_num_cotizacion || '"';
              l_parametros_emision(l_index) := l_parametros_emision(l_index) || '}';
              --
              ptraza(g_nom_archivo,
                     'a',
                     'inicia em_k_cotiza_auto_soa_web.p_emite_poliza');
              --
              em_k_cotiza_auto_soa_web.p_emite_poliza(l_parametros_emision, --   IN strarray,
                                                      l_datos_poliza_emision, -- OUT gc_ref_cursor,
                                                      l_errores_emision); --      OUT gc_ref_cursor)
              --
              ptraza(g_nom_archivo,
                     'a',
                     'fin em_k_cotiza_auto_soa_web.p_emite_poliza');
              --
              LOOP
                FETCH l_datos_poliza_emision
                  INTO l_num_poliza, l_num_recibo;
                EXIT WHEN l_datos_poliza_emision%NOTFOUND;
                --
                ptraza(g_nom_archivo,
                       'a',
                       '   NUM_POLIZA ' || l_num_poliza || ' RECIBO ' ||
                       l_num_recibo);
              END LOOP;
              --
            EXCEPTION
              WHEN OTHERS THEN
                l_num_poliza := NULL;
                l_num_recibo := NULL;
                --
                ptraza(g_nom_archivo,
                       'a',
                       '        ERROR p_emite_poliza ' || SQLERRM);
            END;
            --  
            IF l_num_poliza IS NOT NULL THEN
              --            
              p_codigo_error := '00';
              p_mensaje      := 'Emision Exitosa Poliza No. ' ||
                                l_num_poliza || ' Recibo No. ' ||
                                l_num_recibo;
              --
              OPEN p_cursor_emision FOR
                SELECT l_num_poliza num_poliza FROM DUAL;
              --
            ELSIF (l_num_poliza IS NULL AND l_num_cotizacion IS NOT NULL) THEN -- OJO
              --            
              p_codigo_error := '00';
              p_mensaje      := 'Emision Exitosa Poliza No. ' ||
                                l_num_cotizacion;
              --
              OPEN p_cursor_emision FOR
                SELECT l_num_cotizacion num_poliza FROM DUAL;
              --
            ELSE
              --            
              p_codigo_error := '400';
              p_mensaje      := 'Falla en Emision - se genero Cotizacion No. ' ||
                                l_num_cotizacion;
              --
              OPEN p_cursor_emision FOR
                SELECT l_num_cotizacion num_poliza FROM DUAL;
              --
            END IF;
            --
          ELSE
            --
            p_codigo_error := '400';
            p_mensaje      := 'Error en el proceso. Favor comunicarse con Oficina Comercial';
            --
            OPEN p_cursor_emision FOR
              SELECT ' ' num_poliza FROM DUAL;
            --
          END IF;
          --
        ELSE
          --
          p_codigo_error := '400';
          p_mensaje      := 'Error de Autenticacion';
          --
          OPEN p_cursor_emision FOR
            SELECT ' ' num_poliza FROM DUAL;
          --
        END IF;
        --
      ELSE
        --
        p_codigo_error := '400';
        p_mensaje      := 'Error de Autenticacion';
        --
        OPEN p_cursor_emision FOR
          SELECT ' ' num_poliza FROM DUAL;
        --
      END IF;
      --
    ELSE
      --
      p_codigo_error := '400';
      p_mensaje      := 'Error de Autenticacion';
      --
      OPEN p_cursor_emision FOR
        SELECT ' ' num_poliza FROM DUAL;
      --
    END IF;
    --
    COMMIT;
    --
    ptraza(g_nom_archivo,
           'a',
           'FIN p_codigo_error ' || p_codigo_error || ' p_mensaje ' ||
           p_mensaje || ' Cotizacion ' || l_num_cotizacion);
    --
  EXCEPTION
    WHEN OTHERS THEN
      p_codigo_error := '99';
      p_mensaje      := g_mensaje_error_general;
      ptraza(g_nom_archivo, 'a', 'Error General p_emision_ws ' || SQLERRM);
      --
  END p_emision_ws_soa;
  --
END em_k_ws_microseguros_web;

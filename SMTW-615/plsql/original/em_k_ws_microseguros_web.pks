create or replace PACKAGE em_k_ws_microseguros_web IS
  --
  /* -------------------------------------------------------------------
  -- Procedimientos y funciones para Web Services Cotizador Accidentes Personales
  */
  /* -------------------- VERSION = 1.00 -------------------------------
  -- CARRIERHOUSE - 01/09/2020
  -- CONSTRUCCION
  /* -------------------- MODIFICACIONES -------------------------------
  --
  */ -------------------------------------------------------------------
  g_continua VARCHAR2(1) := NULL;
  --
  TYPE reg_x2000000_web IS RECORD(
    num_duracion_poliza NUMBER(2),
    cod_cia             x2000000_web.cod_cia%TYPE,
    num_cotizacion      x2000000_web.num_cotizacion%TYPE,
    num_riesgo          x2000000_web.num_riesgo%TYPE,
    cod_campo           x2000000_web.cod_campo%TYPE,
    num_secu            x2000000_web.num_secu%TYPE,
    val_campo           x2000000_web.val_campo%TYPE,
    txt_campo           x2000000_web.txt_campo%TYPE,
    txt_campo1          x2000000_web.txt_campo1%TYPE,
    txt_campo2          x2000000_web.txt_campo2%TYPE,
    mca_obligatorio     a1002150.mca_obligatorio%TYPE);

  --
  TYPE reg_importe IS RECORD(
    num_duracion_poliza g2000911_web.num_duracion_poliza%TYPE,
    txt_duracion_poliza g2000911_web.val_campo%TYPE,
    num_riesgo          NUMBER,
    imp_prima_total     NUMBER,
    imp_prima_fracc     NUMBER,
    imp_prima_no_fracc  NUMBER);
  --
  TYPE reg_mensaje IS RECORD(
    cod_mensaje x1010020_web.cod_mensaje%TYPE,
    txt_mensaje x1010020_web.txt_mensaje%TYPE,
    tip_mensaje VARCHAR2(1));

  --
  TYPE gc_ref_cursor IS REF CURSOR;

  --
  TYPE reg_dato_variable IS RECORD(
    cod_campo       g2000020.cod_campo%TYPE,
    val_defecto     g2000020.val_defecto%TYPE,
    cod_modalidad   g2000020.cod_modalidad%TYPE,
    num_secu        g2000020.num_secu%TYPE,
    mca_obligatorio g2000020.mca_obligatorio%TYPE,
    tip_nivel       g2000020.tip_nivel%TYPE);

  --
  --
  TYPE table_x2000000_web IS TABLE OF reg_x2000000_web;
  --
  g_tab_x2000000_web table_x2000000_web := table_x2000000_web();
  --
  TYPE table_g2000020 IS TABLE OF reg_dato_variable INDEX BY BINARY_INTEGER;
  --
  g_tab_g2000020 table_g2000020;
  --
  TYPE table_mensajes IS TABLE OF reg_mensaje;

  --
  TYPE table_importes IS TABLE OF reg_importe;

  --
  FUNCTION f_table_mensajes RETURN table_mensajes
    PIPELINED;

  --
  FUNCTION fl_limpiar_json(p_json IN CLOB) RETURN CLOB;
  -- */
  FUNCTION f_valida_cod_mon_token(pp_token VARCHAR2) RETURN VARCHAR2;
  --
  FUNCTION f_valida_token(pp_token VARCHAR2) RETURN VARCHAR2;
  --
  FUNCTION f_valida_agt_token(pp_token VARCHAR2, pp_producto VARCHAR2) RETURN VARCHAR2;
  --
  PROCEDURE p_login_ws(p_parametros IN CLOB,
                       p_login      OUT gc_ref_cursor,
                       p_errores    OUT gc_ref_cursor);

  --
  PROCEDURE p_emision_ws_ap(p_token          IN VARCHAR2,
                            p_datos_riesgo   IN CLOB,
                            p_datos_tercero  IN CLOB,
                            p_codigo_error   OUT VARCHAR2,
                            p_mensaje        OUT VARCHAR2,
                            p_cursor_emision OUT gc_ref_cursor);
  --
  PROCEDURE p_emision_ws_vi(p_token          IN VARCHAR2,
                            p_datos_riesgo   IN CLOB,
                            p_datos_tercero  IN CLOB,
                            p_codigo_error   OUT VARCHAR2,
                            p_mensaje        OUT VARCHAR2,
                            p_cursor_emision OUT gc_ref_cursor);
  --
  PROCEDURE p_emision_ws_soa(p_token          IN VARCHAR2,
                            p_datos_riesgo   IN CLOB,
                            p_datos_tercero  IN CLOB,
                            p_codigo_error   OUT VARCHAR2,
                            p_mensaje        OUT VARCHAR2,
                            p_cursor_emision OUT gc_ref_cursor);
  --
END em_k_ws_microseguros_web;

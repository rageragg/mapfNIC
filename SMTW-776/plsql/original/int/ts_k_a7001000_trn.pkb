create or replace PACKAGE BODY ts_k_a7001000_trn AS
 --
 /* -------------------- VERSION = 1.37 --------------------  */
 --
 /* -------------------------------------------------------
 ||
 || M O D I F I C A D O   P A R A  I N C L U I R  procedures
 || y funciones de nucleo que se eliminan de la BBDD.
 ||
 */ --------------------------------------------------------
 --
 /* -------------------- DESCRIPCION -------------------- 
 || Trata la Tabla : A7001000. Tabla de los expedientes de un siniestro.
 */ -----------------------------------------------------
 --
 /* -------------------- MODIFICACIONES -------------------------- 
 --
 /* -------------------- DESCRIPCION -----------------------
 || --------------------------------------------------------
 || 2011/08/16 - YMMILLAN - 1.37 - (MS-2011-07-00694)
 || En el procedimiento p_nom_persona_rel asignar al parámetro de salida p_nombre_rel, 
 || el nombre y apellido del tomador.
 */ -------------------------------------------------------
 -- 
 g_cod_idioma          g1010020.cod_idioma%TYPE;
 g_existe              BOOLEAN := FALSE;
 g_existen_expedientes BOOLEAN := TRUE;
 --
  -- suma val.inic. exptes. del sini. expresado en la moneda del siniestro 
 g_tot_imp_val_inicial    NUMBER := 0;  
  -- suma valorac.  exptes. del sini. expresado en la moneda del siniestro
 g_tot_imp_val            NUMBER := 0;  
  -- suma liquidado exptes. del sini. expresado en la moneda del siniestro
 g_tot_imp_liq            NUMBER := 0;  
  -- suma pagado    exptes. del sini. expresado en la moneda del siniestro
 g_tot_imp_pag            NUMBER := 0;  
 --
 --
   CURSOR c_a7001000_juicios ( pl_cod_cia  a7001000.cod_cia %TYPE,
                               pl_num_sini a7001000.num_sini%TYPE ) IS
      SELECT 'S'
        FROM A7001000 A, G7000100 B
       WHERE A.cod_cia                 = pl_cod_cia
         AND A.num_sini                = pl_num_sini
         AND ( NVL(A.mca_juicio,'N')     = 'N'
            OR  ( NVL(A.mca_juicio,'N')     = 'S'
                  AND NVL(tip_est_juicio,'P') = 'T' ) )
         AND A.cod_cia                 = B.cod_cia
         AND A.cod_ramo                = B.cod_ramo
         AND A.tip_exp                 = B.tip_exp
         AND B.mca_juicio              = 'S';
   --    AND NVL(tip_est_juicio,'P') = 'P';
 --
 CURSOR c_a7001000( pl_cod_cia  a7001000.cod_cia %TYPE,
                    pl_num_sini a7001000.num_sini%TYPE,
                    pl_num_exp  a7001000.num_exp %TYPE ) IS
        SELECT *
          FROM a7001000
         WHERE cod_cia  = pl_cod_cia
           AND num_sini = pl_num_sini
           AND num_exp  = pl_num_exp;
 --
 CURSOR c_a7001000_1( pl_cod_cia      a7001000.cod_cia        %TYPE,
                      pl_num_sini     a7001000.num_sini       %TYPE,
                      pl_tip_exp      a7001000.tip_exp        %TYPE,
                      pl_tip_exp_afec a7001000.tip_exp_afec   %TYPE,
                      pl_tip_docum    a7001000.tip_docum      %TYPE,
                      pl_cod_docum    a7001000.cod_docum      %TYPE ) IS
        SELECT *
          FROM a7001000
         WHERE cod_cia         = pl_cod_cia
           AND num_sini        = pl_num_sini
           AND tip_exp         = pl_tip_exp
           AND tip_exp_afec    = pl_tip_exp_afec
	   AND tip_docum       = pl_tip_docum
	   AND cod_docum       = pl_cod_docum
	   AND mca_exp_recobro = 'S';
 --
 CURSOR c_a7001000_2( pl_cod_cia    a7001000.cod_cia   %TYPE,
                      pl_num_sini   a7001000.num_sini  %TYPE,
                      pl_tip_exp    a7001000.tip_exp   %TYPE,
                      pl_tip_docum  a7001000.tip_docum %TYPE,
                      pl_cod_docum  a7001000.cod_docum %TYPE ) IS
        SELECT *
          FROM a7001000
         WHERE cod_cia         = pl_cod_cia
           AND num_sini        = pl_num_sini
           AND tip_exp         = pl_tip_exp
	   AND tip_docum       = pl_tip_docum
	   AND cod_docum       = pl_cod_docum;
 --
 CURSOR c_a7001000_1m( pl_cod_cia      a7001000.cod_cia        %TYPE,
                       pl_num_sini     a7001000.num_sini       %TYPE,
                       pl_tip_exp      a7001000.tip_exp        %TYPE,
                       pl_tip_exp_afec a7001000.tip_exp_afec   %TYPE,
                       pl_tip_docum    a7001000.tip_docum      %TYPE,
                       pl_cod_docum    a7001000.cod_docum      %TYPE,
		       pl_num_exp      a7001000.num_exp        %TYPE ) IS
        SELECT *
          FROM a7001000
         WHERE cod_cia         = pl_cod_cia
           AND num_sini        = pl_num_sini
           AND num_exp        <> pl_num_exp
           AND tip_exp         = pl_tip_exp
           AND tip_exp_afec    = pl_tip_exp_afec
	   AND tip_docum       = pl_tip_docum
	   AND cod_docum       = pl_cod_docum
	   AND mca_exp_recobro = 'S';
 --
 CURSOR c_a7001000_2m( pl_cod_cia    a7001000.cod_cia   %TYPE,
                       pl_num_sini   a7001000.num_sini  %TYPE,
                       pl_tip_exp    a7001000.tip_exp   %TYPE,
                       pl_tip_docum  a7001000.tip_docum %TYPE,
                       pl_cod_docum  a7001000.cod_docum %TYPE,
		       pl_num_exp    a7001000.num_exp   %TYPE ) IS
        SELECT *
          FROM a7001000
         WHERE cod_cia         = pl_cod_cia
           AND num_sini        = pl_num_sini
           AND num_exp        <> pl_num_exp
           AND tip_exp         = pl_tip_exp
	   AND tip_docum       = pl_tip_docum
	   AND cod_docum       = pl_cod_docum ;
 --
 reg a7001000%ROWTYPE;
 --
 /* -----------------------------------------------------
 || Procedimientos internos
 */ -----------------------------------------------------    
 --
 PROCEDURE pp_asigna(p_nom_global VARCHAR2,
                     p_val_global VARCHAR2) IS
 BEGIN
    --
    trn_k_global.asigna(p_nom_global, p_val_global);
    --
 END pp_asigna;
 --
 --
 PROCEDURE pp_asigna(p_nom_global VARCHAR2,
                     p_val_global NUMBER) IS
 BEGIN
    --
    trn_k_global.asigna(p_nom_global, TO_CHAR(p_val_global));
    --
 END pp_asigna;
 --
 PROCEDURE pp_asigna(p_nom_global VARCHAR2,
                     p_val_global DATE) IS
 BEGIN
    --
    trn_k_global.asigna(p_nom_global,TO_CHAR(p_val_global,'ddmmyyyy'));
    --
 END pp_asigna;
 --
 --
 PROCEDURE mx(p_tit VARCHAR2,
              p_val VARCHAR2) IS
 BEGIN
    --
    pp_asigna('fic_traza','sini');
    pp_asigna('cab_traza','A7001000->');
    --
    /*
    em_k_traza.p_escribe(p_tit,
                         p_val);
    */                    
    --
 END mx;
 --
 --
 PROCEDURE mx(p_tit VARCHAR2,
              p_val BOOLEAN) IS
 BEGIN
    --
    pp_asigna('fic_traza',   'sini');
    pp_asigna('cab_traza', 'A7001000->');
    --
    /*
    em_k_traza.p_escribe(p_tit,
                         p_val);
    */                           
    --
 END mx;
 --
 /* -----------------------------------------------------
 || pp_devuelve_error : Devuelve el error al llamador
 */ -----------------------------------------------------
 PROCEDURE pp_devuelve_error ( p_cod_mensaje g1010020.cod_mensaje%TYPE,
                               p_anx_mensaje VARCHAR2                  )
 IS
 BEGIN
  --
  g_cod_idioma := trn_k_global.cod_idioma;
  --
  IF p_cod_mensaje BETWEEN 20000
                       AND 20999
  THEN
     --
     RAISE_APPLICATION_ERROR(-p_cod_mensaje,
                             ss_k_mensaje.f_texto_idioma(p_cod_mensaje,
                                                         g_cod_idioma ) ||
                             p_anx_mensaje
                            );
     --
  ELSE
     --
     RAISE_APPLICATION_ERROR(-20000,
                             ss_k_mensaje.f_texto_idioma(p_cod_mensaje,
                                                         g_cod_idioma ) ||
                             p_anx_mensaje
                            );
     --
  END IF;
  --
 END pp_devuelve_error;
 --
 PROCEDURE p_comprueba_error IS
  --
  l_cod_mensaje g1010020.cod_mensaje%TYPE;
  l_txt_mensaje g1010020.txt_mensaje%TYPE;
  l_hay_error   EXCEPTION;
  --
  BEGIN
   IF NOT g_existe
    THEN
     l_cod_mensaje := 20001;
     l_txt_mensaje := ss_f_mensaje(l_cod_mensaje);
     l_txt_mensaje := l_txt_mensaje || ' (PK a7001000)';
     --
     RAISE_APPLICATION_ERROR(-l_cod_mensaje,l_txt_mensaje);
     --
   END IF;
   --
  END p_comprueba_error;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || Lee el registro de la tabla de expediente en funcion de los parametros
 ||pasados.
 */ ----------------------------------------------------- 
 PROCEDURE p_lee_a7001000( p_cod_cia  a7001000.cod_cia %TYPE,
                           p_num_sini a7001000.num_sini%TYPE,
                           p_num_exp  a7001000.num_exp %TYPE ) IS
 --
 BEGIN
  OPEN        c_a7001000(
                         p_cod_cia,
                         p_num_sini,
                         p_num_exp);
  FETCH       c_a7001000 INTO reg;
  g_existe := c_a7001000%FOUND;
  CLOSE       c_a7001000;
  --
  p_comprueba_error;
  --
 END p_lee_a7001000;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || Lee el registro de la tabla de expediente en funcion de los parametros
 ||pasados.
 */ ----------------------------------------------------- 
 PROCEDURE p_lee_a7001000_1    ( p_cod_cia      a7001000.cod_cia      %TYPE,
                                 p_num_sini     a7001000.num_sini     %TYPE,
                                 p_tip_exp      a7001000.tip_exp      %TYPE,
                                 p_tip_exp_afec a7001000.tip_exp_afec %TYPE,
                              		 p_tip_docum    a7001000.tip_docum    %TYPE,
                            				 p_cod_docum    a7001000.cod_docum    %TYPE )
 IS
 --
 BEGIN
  OPEN        c_a7001000_1(
                            p_cod_cia,
                            p_num_sini,
                            p_tip_exp,
                            p_tip_exp_afec,
			    p_tip_docum,
			    p_cod_docum);
  FETCH       c_a7001000_1 INTO reg;
  g_existe := c_a7001000_1%FOUND;
  CLOSE       c_a7001000_1;
  --
  p_comprueba_error;
  --
 END p_lee_a7001000_1;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || Lee el registro de la tabla de expediente en funcion de los parametros
 ||pasados.
 */ -----------------------------------------------------
 PROCEDURE p_lee_a7001000_2( p_cod_cia  a7001000.cod_cia %TYPE,
                             p_num_sini a7001000.num_sini%TYPE,
                             p_tip_exp  a7001000.tip_exp %TYPE,
                             p_tip_docum  a7001000.tip_docum %TYPE,
                             p_cod_docum  a7001000.cod_docum %TYPE ) IS
 --
 BEGIN
  --
  OPEN        c_a7001000_2(
                         p_cod_cia,
                         p_num_sini,
                         p_tip_exp,
                         p_tip_docum,
                         p_cod_docum);
  FETCH       c_a7001000_2 INTO reg;
  g_existe := c_a7001000_2%FOUND;
  CLOSE       c_a7001000_2;
  --
  p_comprueba_error;
  --
 END p_lee_a7001000_2;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || Lee el registro de la tabla de expediente en funcion de los parametros
 ||pasados.
 */ ----------------------------------------------------- 
 PROCEDURE p_lee_a7001000_1m   ( p_cod_cia      a7001000.cod_cia      %TYPE,
                                 p_num_sini     a7001000.num_sini     %TYPE,
                                 p_tip_exp      a7001000.tip_exp      %TYPE,
                                 p_tip_exp_afec a7001000.tip_exp_afec %TYPE,
                            				 p_tip_docum    a7001000.tip_docum    %TYPE,
                            				 p_cod_docum    a7001000.cod_docum    %TYPE,
                            				 p_num_exp      a7001000.num_exp      %TYPE)
 IS
 --
 BEGIN
  --
  OPEN        c_a7001000_1m(
                            p_cod_cia,
                            p_num_sini,
                            p_tip_exp,
                            p_tip_exp_afec,
                     			    p_tip_docum,
                     			    p_cod_docum,
                     			    p_num_exp);
  FETCH       c_a7001000_1m INTO reg;
  g_existe := c_a7001000_1m%FOUND;
  CLOSE       c_a7001000_1m;
  --
  p_comprueba_error;
  --
 END p_lee_a7001000_1m;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || Lee el registro de la tabla de expediente en funcion de los parametros
 ||pasados.
 */ -----------------------------------------------------
 PROCEDURE p_lee_a7001000_2m( p_cod_cia    a7001000.cod_cia   %TYPE,
                              p_num_sini   a7001000.num_sini  %TYPE,
                              p_tip_exp    a7001000.tip_exp   %TYPE,
                              p_tip_docum  a7001000.tip_docum %TYPE,
                              p_cod_docum  a7001000.cod_docum %TYPE,
                     			      p_num_exp    a7001000.num_exp   %TYPE ) IS
 BEGIN
  OPEN        c_a7001000_2m(
                         p_cod_cia,
                         p_num_sini,
                         p_tip_exp,
                         p_tip_docum,
                         p_cod_docum,
			                      p_num_exp);
  FETCH       c_a7001000_2m INTO reg;
  g_existe := c_a7001000_2m%FOUND;
  CLOSE       c_a7001000_2m;
  --
  p_comprueba_error;
  --
 END p_lee_a7001000_2m;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || Devuelve el sector del registro leido.
 */ -----------------------------------------------------
 FUNCTION f_cod_sector RETURN NUMBER IS
 BEGIN
  --
  p_comprueba_error;
  --
  RETURN reg.cod_sector;
  --
 END f_cod_sector;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || Devuelve el ramo del registro leido.
 */ -----------------------------------------------------
 FUNCTION f_cod_ramo RETURN NUMBER IS
 BEGIN
  --
  p_comprueba_error;
  --
  RETURN reg.cod_ramo;
  --
 END f_cod_ramo;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || Devuelve el tipo de expediente del registro leido.
 */ ----------------------------------------------------- 
 FUNCTION f_tip_exp RETURN VARCHAR2 IS
 BEGIN
  --
  p_comprueba_error;
  --
  RETURN reg.tip_exp;
  --
 END f_tip_exp;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || Devuelve el estado del expediente del registro leido.
 */ ----------------------------------------------------- 
 FUNCTION f_tip_est_exp RETURN VARCHAR2 IS
 BEGIN
  --
  p_comprueba_error;
  --
  RETURN reg.tip_est_exp;
  --
 END f_tip_est_exp;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || Devuelve si el expediente leido es o no un recobro.
 */ ----------------------------------------------------- 
 FUNCTION f_mca_exp_recobro RETURN VARCHAR2 IS
 BEGIN
  --
  p_comprueba_error;
  --
  RETURN reg.mca_exp_recobro;
  --
 END f_mca_exp_recobro;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || Devuelve si el expediente leido tiene o no asociado un recobro.
 */ ----------------------------------------------------- 
 FUNCTION f_mca_recobro RETURN VARCHAR2 IS
 BEGIN
  --
  p_comprueba_error;
  --
  RETURN reg.mca_recobro;
  --
 END f_mca_recobro;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || Devuelve el estado del expediente de recobro asociado.
 */ -----------------------------------------------------
 FUNCTION f_tip_est_recobro RETURN VARCHAR2 IS
 BEGIN
  --
  p_comprueba_error;
  --
  RETURN reg.tip_est_recobro;
  --
 END f_tip_est_recobro;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || Devuelve el numero de expediente al que afecta si el expediente es un
 ||recobro.
 */ ----------------------------------------------------- 
 FUNCTION f_num_exp_afec RETURN NUMBER IS
 BEGIN
  --
  p_comprueba_error;
  --
  RETURN reg.num_exp_afec;
  --
 END f_num_exp_afec;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || Devuelve el tipo de expediente al que esta afectando el recobro.
 */ ----------------------------------------------------- 
 FUNCTION f_tip_exp_afec RETURN VARCHAR2 IS
 BEGIN
  --
  p_comprueba_error;
  --
  RETURN reg.tip_exp_afec;
  --
 END f_tip_exp_afec;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || Devuelve el estado del expediente al que esta afectando el recobro.
 */ -----------------------------------------------------
 FUNCTION f_tip_est_afec RETURN VARCHAR2 IS
 BEGIN
  --
  p_comprueba_error;
  --
  RETURN reg.tip_est_afec;
  --
 END f_tip_est_afec;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || Devuelve si el expediente esta o no asociado a un juicio.
 */ ----------------------------------------------------- 
 FUNCTION f_mca_juicio RETURN VARCHAR2 IS
 BEGIN
  --
  p_comprueba_error;
  --
  RETURN reg.mca_juicio;
  --
 END f_mca_juicio;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || Devuelve el estado en el que se encuentra el juicio que este asociado
 ||al expediente.
 */ ----------------------------------------------------- 
 FUNCTION f_tip_est_juicio RETURN VARCHAR2 IS
 BEGIN
  --
  p_comprueba_error;
  --
  RETURN reg.tip_est_juicio;
  --
 END f_tip_est_juicio;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || Devuelve la fecha de apertura del expediente.
 */ -----------------------------------------------------
 FUNCTION f_fec_aper_exp RETURN DATE IS
 BEGIN
  --
  p_comprueba_error;
  --
  RETURN reg.fec_aper_exp;
  --
 END f_fec_aper_exp;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || Devuelve la fecha de terminacion del expediente.
 */ ----------------------------------------------------- 
 FUNCTION f_fec_term_exp RETURN DATE IS
 BEGIN
  --
  p_comprueba_error;
  --
  RETURN reg.fec_term_exp;
  --
 END f_fec_term_exp;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || Devuelve la fecha de modificacion del expediente.
 */ -----------------------------------------------------
 FUNCTION f_fec_modi_exp RETURN DATE IS
 BEGIN
  --
  p_comprueba_error;
  --
  RETURN reg.fec_modi_exp;
  --
 END f_fec_modi_exp;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || Devuelve la fecha de reapertura del expediente.
 */ -----------------------------------------------------
 FUNCTION f_fec_reap_exp RETURN DATE IS
 BEGIN
  --
  p_comprueba_error;
  --
  RETURN reg.fec_reap_exp;
  --
 END f_fec_reap_exp;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || Devuelve la fecha de la ultima liquidacion del expediente.
 */ -----------------------------------------------------
 FUNCTION f_fec_ult_liq RETURN DATE IS
 BEGIN
  --
  p_comprueba_error;
  --
  RETURN reg.fec_ult_liq;
  --
 END f_fec_ult_liq;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || Devuelve si el expediente esta o no retenido por control tecnico.
 */ -----------------------------------------------------
 FUNCTION f_mca_provisional RETURN VARCHAR2 IS
 BEGIN
  --
  p_comprueba_error;
  --
  RETURN reg.mca_provisional;
  --
 END f_mca_provisional;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || Devuelve la fecha de autorizacion del control tecnico.
 */ -----------------------------------------------------
 FUNCTION f_fec_autorizacion RETURN DATE IS
 BEGIN
  --
  p_comprueba_error;
  --
  RETURN reg.fec_autorizacion;
  --
 END f_fec_autorizacion;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || Devuelve el tipo de documento de la persona a la cual afecta el expediente.
 */ -----------------------------------------------------
 FUNCTION f_tip_docum RETURN VARCHAR2 IS
 BEGIN
  --
  p_comprueba_error;
  --
  RETURN reg.tip_docum;
  --
 END f_tip_docum;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || Devuelve el codigo de documento de la persona a la cual afecta el 
 ||expediente.
 */ -----------------------------------------------------
 FUNCTION f_cod_docum RETURN VARCHAR2 IS
 BEGIN
  --
  p_comprueba_error;
  --
  RETURN reg.cod_docum;
  --
 END f_cod_docum;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || Devuelve el nombre de la persona a la cual afecta el expediente.
 */ -----------------------------------------------------
 FUNCTION f_nombre RETURN VARCHAR2 IS
 BEGIN
  --
  p_comprueba_error;
  --
  RETURN reg.nombre;
  --
 END f_nombre;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || Devuelve los apellidos de la persona a la cual afecta el expediente.
 */ -----------------------------------------------------
 FUNCTION f_apellidos RETURN VARCHAR2 IS
 BEGIN
  --
  p_comprueba_error;
  --
  RETURN reg.apellidos;
  --
 END f_apellidos;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || Devuelve la moneda del expediente.
 */ -----------------------------------------------------
 FUNCTION f_cod_mon RETURN NUMBER IS
 BEGIN
  --
  p_comprueba_error;
  --
  RETURN reg.cod_mon;
  --
 END f_cod_mon;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || Devuelve el importe de la valoracion inicial del expediente.
 */ -----------------------------------------------------
 FUNCTION f_imp_val_inicial RETURN NUMBER IS
 BEGIN
  --
  p_comprueba_error;
  --
  RETURN reg.imp_val_inicial;
  --
 END f_imp_val_inicial;
 --
 /* -------------------- DESCRIPCION -------------------------- 
 || TRON2000  - 00/11/27 
 || Devuelve el importe de la valoracion inicial del siniestro  
 || expresado en la moneda del siniestro.
 */ ----------------------------------------------------------- 
 FUNCTION f_tot_imp_val_inicial RETURN NUMBER IS
 BEGIN
  --
  IF NOT g_existen_expedientes
  THEN
     RAISE_APPLICATION_ERROR
	   ( -20001, ss_f_mensaje_idioma (20001, trn_k_global.cod_idioma) ||
	   ' a7001000 : [-]');
  ELSE
    RETURN g_tot_imp_val_inicial;
  END IF;
  --
 END f_tot_imp_val_inicial;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || Devuelve si el calculo de reservas es manual o por procedimiento.
 */ -----------------------------------------------------
 FUNCTION f_mca_rva_manual RETURN VARCHAR2 IS
 BEGIN
  --
  p_comprueba_error;
  --
  RETURN reg.mca_rva_manual;
  --
 END f_mca_rva_manual;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || Devuelve si el expediente forma parte o no en el calculo de reservas.
 */ -----------------------------------------------------
 FUNCTION f_mca_calcula_rva RETURN VARCHAR2 IS
 BEGIN
  --
  p_comprueba_error;
  --
  RETURN reg.mca_calcula_rva;
  --
 END f_mca_calcula_rva;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || Devuelve el importe de la valoracion actual del expediente.
 */ -----------------------------------------------------
 FUNCTION f_imp_val RETURN NUMBER IS
 BEGIN
  --
  p_comprueba_error;
  --
  RETURN reg.imp_val;
  --
 END f_imp_val;
 --
 /* -------------------- DESCRIPCION -------------------------- 
 || TRON2000  - 00/11/27 
 || Devuelve el importe de la valoracion del siniestro  
 || expresado en la moneda del siniestro.
 */ ----------------------------------------------------------- 
 FUNCTION f_tot_imp_val RETURN NUMBER IS
 BEGIN
  --
  IF NOT g_existen_expedientes
  THEN
     RAISE_APPLICATION_ERROR
	   ( -20001, ss_f_mensaje_idioma (20001, trn_k_global.cod_idioma) ||
	   ' a7001000 : [-]');
  ELSE
    RETURN g_tot_imp_val;
  END IF;
  --
 END f_tot_imp_val;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || TRON2000  - 98/05/27 
 || Devuelve el importe total liquidado del expediente.
 */ -----------------------------------------------------
 FUNCTION f_imp_liq RETURN NUMBER IS
 BEGIN
  --
  p_comprueba_error;
  --
  RETURN reg.imp_liq;
  --
 END f_imp_liq;
 --
 /* -------------------- DESCRIPCION -------------------------- 
 || TRON2000  - 00/11/27 
 || Devuelve el importe de la liquidacion del siniestro 
 || expresado en la moneda del siniestro.
 */ ----------------------------------------------------------- 
 FUNCTION f_tot_imp_liq RETURN NUMBER IS
 BEGIN
  --
  IF NOT g_existen_expedientes
  THEN
     RAISE_APPLICATION_ERROR
	   ( -20001, ss_f_mensaje_idioma (20001, trn_k_global.cod_idioma) ||
	   ' a7001000 : [-]');
  ELSE
    RETURN g_tot_imp_liq;
  END IF;
  --
 END f_tot_imp_liq;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || TRON2000  - 98/05/27 
 || Devuelve el importe total pagado del expediente.
 */ -----------------------------------------------------
 FUNCTION f_imp_pag RETURN NUMBER IS
 BEGIN
  --
  p_comprueba_error;
  --
  RETURN reg.imp_pag;
  --
 END f_imp_pag;
 --
 /* -------------------- DESCRIPCION -------------------------- 
 || TRON2000  - 00/11/27 
 || Devuelve el importe de los pagos del siniestro 
 || expresado en la moneda del siniestro.
 */ ----------------------------------------------------------- 
 FUNCTION f_tot_imp_pag RETURN NUMBER IS
 BEGIN
  --
  IF NOT g_existen_expedientes
  THEN
     RAISE_APPLICATION_ERROR
	   ( -20001, ss_f_mensaje_idioma (20001, trn_k_global.cod_idioma) ||
	   ' a7001000 : [-]');
  ELSE
    RETURN g_tot_imp_pag;
  END IF;
  --
 END f_tot_imp_pag;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || TRON2000  - 98/05/27 
 || Devuelve la valoracion neta de coaseguro del expediente.
 */ -----------------------------------------------------
 FUNCTION f_imp_val_neto RETURN NUMBER IS
 BEGIN
  --
  p_comprueba_error;
  --
  RETURN reg.imp_val_neto;
  --
 END f_imp_val_neto;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || TRON2000  - 98/05/27 
 || Devuelve las liquidaciones netas de coaseguro del expediente.
 */ -----------------------------------------------------
 FUNCTION f_imp_liq_neto RETURN NUMBER IS
 BEGIN
  --
  p_comprueba_error;
  --
  RETURN reg.imp_liq_neto;
  --
 END f_imp_liq_neto;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || TRON2000  - 98/05/27 
 || Devuelve los pagos netos de coaseguro del expediente.
 */ -----------------------------------------------------
 FUNCTION f_imp_pag_neto RETURN NUMBER IS
 BEGIN
  --
  p_comprueba_error;
  --
  RETURN reg.imp_pag_neto;
  --
 END f_imp_pag_neto;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || TRON2000  - 98/05/27 
 || Devuelve el porcentaje de participacion de nuestra compa¤ia en el coa-
 ||seguro.
 */ -----------------------------------------------------
 FUNCTION f_pct_coa RETURN NUMBER IS
 BEGIN
  --
  p_comprueba_error;
  --
  RETURN reg.pct_coa;
  --
 END f_pct_coa;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || TRON2000  - 98/05/27 
 || Devuelve la reserva a 31-12 del expediente.
 */ -----------------------------------------------------
 FUNCTION f_imp_rva_3112 RETURN NUMBER IS
 BEGIN
  --
  p_comprueba_error;
  --
  RETURN reg.imp_rva_3112;
  --
 END f_imp_rva_3112;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || TRON2000  - 98/05/27 
 || Devuelve la fecha del ultimo calculo de reservas a 31-12.
 */ -----------------------------------------------------
 FUNCTION f_fec_rva_3112 RETURN DATE IS
 BEGIN
  --
  p_comprueba_error;
  --
  RETURN reg.fec_rva_3112;
  --
 END f_fec_rva_3112;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || TRON2000  - 98/05/27 
 || Devuelve el codigo del supervisor del tramitador del expediente.
 */ -----------------------------------------------------
 FUNCTION f_cod_supervisor RETURN NUMBER IS
 BEGIN
  --
  p_comprueba_error;
  --
  RETURN reg.cod_supervisor;
  --
 END f_cod_supervisor;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || TRON2000  - 98/05/27 
 || Devuelve el codigo del tramitador del expediente.
 */ -----------------------------------------------------
 FUNCTION f_cod_tramitador RETURN NUMBER IS
 BEGIN
  --
  p_comprueba_error;
  --
  RETURN reg.cod_tramitador;
  --
 END f_cod_tramitador;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || TRON2000  - 98/05/27 
 || Devuelve el codigo del usuario.
 */ -----------------------------------------------------
 FUNCTION f_cod_usr RETURN VARCHAR2 IS
 BEGIN
  --
  p_comprueba_error;
  --
  RETURN reg.cod_usr;
  --
 END f_cod_usr;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || TRON2000  - 98/05/27 
 || Devuelve la fecha de actualizacion.
 */ -----------------------------------------------------
 FUNCTION f_fec_actu RETURN DATE IS
 BEGIN
  --
  p_comprueba_error;
  --
  RETURN reg.fec_actu;
  --
 END f_fec_actu;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || TRON2000  - 98/05/27 
 || Devuelve el codigo de nivel1 de la estructura comercial.
 */ -----------------------------------------------------
 FUNCTION f_cod_nivel1 RETURN NUMBER IS
 BEGIN
  --
  p_comprueba_error;
  --
  RETURN reg.cod_nivel1;
  --
 END f_cod_nivel1;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || TRON2000  - 98/05/27 
 || Devuelve el codigo de nivel2 de la estructura comercial.
 */ -----------------------------------------------------
 FUNCTION f_cod_nivel2 RETURN NUMBER IS
 BEGIN
  --
  p_comprueba_error;
  --
  RETURN reg.cod_nivel2;
  --
 END f_cod_nivel2;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || TRON2000  - 98/05/27 
 || Devuelve el codigo de nivel3 de la estructura comercial.
 */ -----------------------------------------------------
 FUNCTION f_cod_nivel3 RETURN NUMBER IS
 BEGIN
  --
  p_comprueba_error;
  --
  RETURN reg.cod_nivel3;
  --
 END f_cod_nivel3;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || Devuelve la fecha de denuncia del expediente.
 */ -----------------------------------------------------
 FUNCTION f_fec_denu_exp RETURN DATE IS
 BEGIN
   --
   p_comprueba_error;
   --
   RETURN reg.fec_denu_exp;
   --
 END f_fec_denu_exp;
 --
 /* -------------------- DESCRIPCION -------------------- 
 || Devuelve la fecha de aviso del expediente.
 */ -----------------------------------------------------
 FUNCTION f_fec_aviso_exp RETURN DATE IS
 BEGIN
   --
   p_comprueba_error;
   --
   RETURN reg.fec_aviso_exp;
   --
 END f_fec_aviso_exp; 
 -- 
 /* -------------------- MODIFICACIONES -------------------- 
 || TRON2000  - 00/12/11
 || Creacion. Inserta en a7001000 un registro. Los campos que 
 || no llegan por par metro son constantes o se calculan en
 || body.
 || Sustituye al procedurte ts_p_inserta_a7001000_trn habiendo
 || modificado los parametros que recibe ya que se han dejado
 || de pasar aquellos que son valores constantes o que se 
 || calculan siempre de la misma forma.
 */ --------------------------------------------------------
 --
 PROCEDURE p_inserta( p_cod_cia          a7001000.cod_cia         %TYPE,
                      p_cod_sector       a7001000.cod_sector      %TYPE,
                      p_cod_ramo         a7001000.cod_ramo        %TYPE,
                      p_num_sini         a7001000.num_sini        %TYPE,
                      p_num_exp          a7001000.num_exp         %TYPE,
                      p_tip_exp          a7001000.tip_exp         %TYPE,
                      p_mca_exp_recobro  a7001000.mca_exp_recobro %TYPE,
                      p_num_exp_afec     a7001000.num_exp_afec    %TYPE,
                      p_tip_exp_afec     a7001000.tip_exp_afec    %TYPE,
                      p_tip_est_afec     a7001000.tip_est_afec    %TYPE,
                      p_fec_aper_exp     a7001000.fec_aper_exp    %TYPE,
                      p_tip_docum        a7001000.tip_docum       %TYPE,
                      p_cod_docum        a7001000.cod_docum       %TYPE,
                      p_nombre           a7001000.nombre          %TYPE,
                      p_apellidos        a7001000.apellidos       %TYPE,
                      p_cod_mon          a7001000.cod_mon         %TYPE,
                      p_cod_supervisor   a7001000.cod_supervisor  %TYPE,
                      p_cod_tramitador   a7001000.cod_tramitador  %TYPE,
                      p_tip_apertura     a7001000.tip_apertura    %TYPE)
 IS
  -- Valores constantes --
  l_tip_est_exp        a7001000.tip_est_exp    %TYPE := 'P';
  l_mca_recobro        a7001000.mca_recobro    %TYPE := 'N';
  l_mca_rva_manual     a7001000.mca_rva_manual %TYPE := 'S';
  l_mca_provisional    a7001000.mca_provisional%TYPE := 'N';
  l_mca_juicio         a7001000.mca_juicio     %TYPE := 'N';
  l_imp_val_inicial    a7001000.imp_val_inicial%TYPE :=  0 ;
  l_imp_val            a7001000.imp_val        %TYPE :=  0 ;
  l_imp_val_neto       a7001000.imp_val_neto   %TYPE :=  0 ;
  l_pct_coa            a7001000.pct_coa        %TYPE := NULL;
  -- Valores obtenidos de g7000100 --
  l_mca_calcula_rva    a7001000.mca_calcula_rva%TYPE ;
  -- Valores obtenidos de a1001339 --
  l_cod_nivel3         a7001000.cod_nivel3     %TYPE ;
  -- Valores obtenidos de a1000702 --
  l_cod_nivel1         a7001000.cod_nivel1     %TYPE ;
  l_cod_nivel2         a7001000.cod_nivel2     %TYPE ;
  -- Valores obtenidos del sistema --
  l_fec_actu           a7001000.fec_actu       %TYPE := trn_k_tiempo.f_fec_actu;
  l_cod_usr            a7001000.cod_usr        %TYPE := trn_k_global.cod_usr;
 --
 BEGIN
   --
   ts_k_g7000100.p_lee ( p_cod_cia , p_cod_ramo , p_tip_exp );
   l_mca_calcula_rva  := ts_k_g7000100.f_mca_calcula_rva;
   --
   -- Change for 1.35: the references to package ts_k_a1001339 are replaced by dc_k_a1001339
   --
   dc_k_a1001339.p_lee_cod_tramitador ( p_cod_cia        => p_cod_cia        , 
                                        p_cod_tramitador => p_cod_tramitador );
   l_cod_nivel3 := dc_k_a1001339.f_cod_nivel3;
   --
   dc_k_a1000702.p_lee ( p_cod_cia , l_cod_nivel3 );
   l_cod_nivel1 := dc_k_a1000702.f_cod_nivel1;
   l_cod_nivel2 := dc_k_a1000702.f_cod_nivel2;
   --
   INSERT INTO a7001000
     ( cod_cia          , cod_sector     ,
       cod_ramo         , num_sini       ,
       num_exp          , tip_exp        ,
       tip_est_exp      , mca_exp_recobro,
       mca_recobro      , num_exp_afec   ,
       tip_exp_afec     , tip_est_afec   ,
       mca_juicio                        , 
       fec_aper_exp     , mca_provisional,
       tip_docum        , cod_docum      ,
       nombre           , apellidos      ,
       cod_mon          , mca_rva_manual ,
       imp_val_inicial  , imp_val        ,
       imp_val_neto     , pct_coa        ,
       mca_calcula_rva                   ,
       cod_supervisor   , cod_tramitador ,
       cod_usr          , fec_actu       ,
       cod_nivel1       , cod_nivel2     ,
       cod_nivel3       , tip_apertura
     )
   VALUES
     ( p_cod_cia          , p_cod_sector     ,
       p_cod_ramo         , p_num_sini       ,
       p_num_exp          , p_tip_exp        ,
       l_tip_est_exp      , p_mca_exp_recobro,
       l_mca_recobro      , p_num_exp_afec   ,
       p_tip_exp_afec     , p_tip_est_afec   ,
       l_mca_juicio                          , 
       p_fec_aper_exp     , l_mca_provisional,
       p_tip_docum        , p_cod_docum      ,
       p_nombre           , p_apellidos      ,
       p_cod_mon          , l_mca_rva_manual ,
       l_imp_val_inicial  , l_imp_val        ,
       l_imp_val_neto     , l_pct_coa        ,
       l_mca_calcula_rva                     ,
       p_cod_supervisor   , p_cod_tramitador ,
       l_cod_usr          , l_fec_actu       ,
       l_cod_nivel1       , l_cod_nivel2     ,
       l_cod_nivel3       , p_tip_apertura
   );
   --
 END p_inserta;
 --
 /* --------------------------------------------------------
 || TRON2000  - 00/12/12
 || Creacion. Actualiza la reserva a fin de a¤o para el expe- 
 ||           diente indicado por parametro.                  
 ||           Sera utilizado en el package
 ||           <ts_k_carga_reservas_trn>                  
 */ --------------------------------------------------------
 PROCEDURE p_actualiza_rva3112  
	  ( p_cod_cia       a7001000.cod_cia      %TYPE
	  , p_num_sini      a7001000.num_sini     %TYPE
	  , p_num_exp       a7001000.num_exp      %TYPE
	  , p_imp_rva_3112  a7001000.imp_rva_3112 %TYPE )
 IS
  --
 BEGIN
   --
   UPDATE a7001000
   SET imp_rva_3112 = p_imp_rva_3112,
       fec_actu     = trn_k_tiempo.f_fec_actu
   WHERE cod_cia  = p_cod_cia
     AND num_sini = p_num_sini
     AND num_exp  = p_num_exp ;
   --
 END p_actualiza_rva3112;
 --
 /* --------------------------------------------------------
 || TRON2000  - 00/12/12
 || Creacion. Inicializa las columnas referentes a la reserva 
 ||           3112 del ejercicio correspondiente (para todos
 ||           los registros existentes en la tabla).       
 ||           Sera utilizado en el package
 ||           <ts_k_carga_reservas_trn>                  
 */ --------------------------------------------------------
 PROCEDURE p_inicializa_rva3112  
	  ( p_fec_rva_3112     a7001000.fec_rva_3112    %TYPE )
 IS
  --
 BEGIN
   --
   UPDATE a7001000
   SET imp_rva_3112 = 0 ,
       fec_rva_3112 = p_fec_rva_3112,
       fec_actu     = trn_k_tiempo.f_fec_actu ;
   --
 END p_inicializa_rva3112;
 --
 /* --------------------------------------------------------
 || MVMARTI   - 30/01/2003
 || Creacion. Realiza las modificaciones correspondientes     
 ||           a una operacion de retencion por   control
 ||           tecnico. 
 */ --------------------------------------------------------
 PROCEDURE p_act_mca_provisional  
	  ( p_cod_cia          a7001000.cod_cia         %TYPE
	  , p_num_sini         a7001000.num_sini        %TYPE
	  , p_num_exp          a7001000.num_exp         %TYPE 
          , p_mca_provisional  a7001000.mca_provisional %TYPE)
 IS
  --
 BEGIN
   --
   IF NVL( p_mca_provisional, 'X' ) NOT IN ('S','N')
   THEN
     --
     pp_devuelve_error ( 20047, ' [ts_k_a7001000.p_act_mca_provisional]');
     --
   ELSE
     --
     UPDATE a7001000
     SET mca_provisional = p_mca_provisional,
         fec_actu        = trn_k_tiempo.f_fec_actu
     WHERE cod_cia  = p_cod_cia
       AND num_sini = p_num_sini
       AND num_exp  = p_num_exp;
     --
   END IF;
   --
 END p_act_mca_provisional;
 --
 /* --------------------------------------------------------
 || Maria     - 00/12/12
 || Creacion. Realiza las modificaciones correspondientes     
 ||           a una operacion de autorizacion de control
 ||           tecnico. Se utilizara en package             
 ||           <ts_k_autorizaciones_trn>                  
 */ --------------------------------------------------------
 PROCEDURE p_autoriza  
	  ( p_cod_cia          a7001000.cod_cia         %TYPE
	  , p_num_sini         a7001000.num_sini        %TYPE
	  , p_num_exp          a7001000.num_exp         %TYPE
	  , p_imp_val          a7001000.imp_val         %TYPE
	  , p_imp_val_neto     a7001000.imp_val_neto    %TYPE
	  , p_fec_autorizacion a7001000.fec_autorizacion%TYPE )
 IS
  --
 BEGIN
   --
   UPDATE a7001000
   SET mca_provisional  = 'N'               ,
       fec_autorizacion = p_fec_autorizacion,
       imp_val          = NVL(imp_val, 0) + NVL(p_imp_val, 0) ,
       imp_val_neto     = NVL(imp_val_neto, 0) + NVL(p_imp_val_neto, 0),
       fec_actu         = trn_k_tiempo.f_fec_actu
   WHERE cod_cia  = p_cod_cia
     AND num_sini = p_num_sini
     AND num_exp  = p_num_exp
     AND NVL(mca_provisional, 'N' )='S';
   --
 END p_autoriza;
 --
 /* --------------------------------------------------------
 || TRON2000  - 00/12/11
 || Creacion. Sustituye al procedimiento de nucleo            
 ||           <ts_p_actualiza_a7001000_trn>.
 ||           Los campos referentes al usuario y fecha de  
 ||           actualizaci¢n dejan de ser par metros para 
 ||           pasar a calcularse dentro del body.
 */ --------------------------------------------------------
 PROCEDURE p_actualiza_datos_persona_rel 
	  ( p_cod_cia          a7001000.cod_cia         %TYPE
	  , p_num_sini         a7001000.num_sini        %TYPE
	  , p_num_exp          a7001000.num_exp         %TYPE
	  , p_fec_modi_exp     a7001000.fec_modi_exp    %TYPE
	  , p_tip_docum        a7001000.tip_docum       %TYPE
	  , p_cod_docum        a7001000.cod_docum       %TYPE
	  , p_nombre           a7001000.nombre          %TYPE
	  , p_apellidos        a7001000.apellidos       %TYPE )
 IS
  --
  -- Valores obtenidos del sistema --
  l_fec_actu           a7001000.fec_actu       %TYPE := trn_k_tiempo.f_fec_actu;
  l_cod_usr            a7001000.cod_usr        %TYPE := trn_k_global.cod_usr;
  --
 BEGIN
   --
   UPDATE a7001000
   SET fec_modi_exp = p_fec_modi_exp,
       tip_docum    = p_tip_docum   ,
       cod_docum    = p_cod_docum   ,
       nombre       = p_nombre      ,
       apellidos    = p_apellidos   ,
       cod_usr      = l_cod_usr     ,
       fec_actu     = trn_k_tiempo.f_fec_actu
   WHERE cod_cia   = p_cod_cia
     AND num_sini  = p_num_sini
     AND num_exp   = p_num_exp;
   --
 END p_actualiza_datos_persona_rel;
 --
 /* --------------------------------------------------------
 || TRON2000  - 00/12/07
 || Creacion. Sustituye al procedimiento de nucleo            
 ||           <ts_p_actualiza_a7001000_2_trn>.
 ||           El campo MCA_RECOBRO solo se actualiza cuando
 ||           se indica TIP_EST_RECOBRO = 'P'.
 */ --------------------------------------------------------
 PROCEDURE p_actualiza_estado_recobro 
	  ( p_cod_cia          a7001000.cod_cia         %TYPE
	  , p_num_sini         a7001000.num_sini        %TYPE
	  , p_num_exp          a7001000.num_exp         %TYPE
	  , p_tip_est_recobro  a7001000.tip_est_recobro %TYPE )
 IS
 BEGIN
   --
   UPDATE a7001000
      SET tip_est_recobro    = p_tip_est_recobro,
       	  mca_recobro        = DECODE ( p_tip_est_recobro, 'P', 'S', mca_recobro ),
          fec_actu           = trn_k_tiempo.f_fec_actu          
    WHERE cod_cia      = p_cod_cia
      AND num_sini     = p_num_sini
      AND num_exp      = p_num_exp;
   --
 END p_actualiza_estado_recobro;
 --
 /* --------------------------------------------------------
 || TRON2000  - 00/12/07
 || Creacion. Sustituye al procedimiento de nucleo            
 ||           <ts_p_actualiza_a7001000_6_trn>, dado que          
 ||           no se estaba utilizando se modifica a¤adiendo
 ||           las columnas referentes a los importes liquidados
 ||           y valorados para darle mas funcionalidad.                
 */ --------------------------------------------------------
 PROCEDURE p_actualiza_val_liq_pag 
	  ( p_cod_cia          a7001000.cod_cia         %TYPE
	  , p_num_sini         a7001000.num_sini        %TYPE
	  , p_num_exp          a7001000.num_exp         %TYPE
	  , p_imp_val          a7001000.imp_val         %TYPE
	  , p_imp_val_neto     a7001000.imp_val_neto    %TYPE
	  , p_imp_liq          a7001000.imp_liq         %TYPE
	  , p_imp_liq_neto     a7001000.imp_liq_neto    %TYPE 
	  , p_imp_pag          a7001000.imp_pag         %TYPE
	  , p_imp_pag_neto     a7001000.imp_pag_neto    %TYPE)
 IS
 BEGIN
   --
   UPDATE a7001000
      SET imp_val      = nvl(imp_val     ,0) + nvl(p_imp_val     ,0),
       	  imp_val_neto = nvl(imp_val_neto,0) + nvl(p_imp_val_neto,0),
       	  imp_liq      = nvl(imp_liq     ,0) + nvl(p_imp_liq     ,0),
       	  imp_liq_neto = nvl(imp_liq_neto,0) + nvl(p_imp_liq_neto,0),
       	  imp_pag      = nvl(imp_pag     ,0) + nvl(p_imp_pag     ,0),
          imp_pag_neto = nvl(imp_pag_neto,0) + nvl(p_imp_pag_neto,0),
          fec_actu     = trn_k_tiempo.f_fec_actu
    WHERE cod_cia      = p_cod_cia
      AND num_sini     = p_num_sini
      AND num_exp      = p_num_exp;
   --
 END p_actualiza_val_liq_pag;
 --
 /* --------------------------------------------------------
 || TRON2000  - 00/12/07
 || Creacion. UNIFICA   los  procedimientos de nucleo        
 ||           <ts_p_actualiza_a7001000_5_trn> junto con          
 ||           <ts_p_actualiza_a7001000_4_trn>. Estos dos
 ||           procedimientos funcionalmente van unidos as¡   
 ||           que se recogen en uno s¢lo.                  
 ||           Este procedimiento actualiza el estado del 
 ||           siniestro/expte indicados (adem s de la fecha
 ||           correspondiente: terminacion o reapertura) y
 ||           la marca correspondiente en los recobros asociados
 ||           del expediente.    
 */ --------------------------------------------------------
 PROCEDURE p_actualiza_estado
	  ( p_cod_cia          a7001000.cod_cia         %TYPE
	  , p_num_sini         a7001000.num_sini        %TYPE
	  , p_num_exp          a7001000.num_exp         %TYPE
	  , p_tip_est_exp      a7001000.tip_est_exp     %TYPE
	  , p_fecha_estado     a7001000.fec_term_exp    %TYPE )
 IS
 BEGIN
   --
   /* 09-08-2001. Se modifica que si la fecha de estado que se pasa es nula,
     deje puesta la fecha de reapertura que habia. Pues en el cambio de valo-
     racion se llama al p_actualiza_importes_estado, el cual pasa como estado
     'P' y como fecha_estado un NULL, entonces si venimos de la rehabilitacion
     de expedientes, borrariamos la fecha de reapertura que dicho programa ha 
     puesto.
   */ 
   --
   IF p_tip_est_exp = 'P'  -- Caso de reapertura 
   THEN
     UPDATE a7001000
      SET tip_est_exp    = p_tip_est_exp,
          fec_reap_exp   = NVL(p_fecha_estado , fec_reap_exp),
       	  fec_term_exp   = NULL,
          fec_actu       = trn_k_tiempo.f_fec_actu          
      WHERE cod_cia      = p_cod_cia
        AND num_sini     = p_num_sini
        AND num_exp      = p_num_exp;
     --
   ELSE  -- Caso de terminaci¢n
     --
     UPDATE a7001000
      SET tip_est_exp    = p_tip_est_exp,
          fec_term_exp   = p_fecha_estado,
          fec_actu       = trn_k_tiempo.f_fec_actu          
      WHERE cod_cia      = p_cod_cia
        AND num_sini     = p_num_sini
        AND num_exp      = p_num_exp;
   END IF;                     
   --
   -----------------------------------------
   -- Actualizamos estado del expediente  --
   -- afectado en los recobros asociados. --
   -----------------------------------------
   UPDATE a7001000
      SET tip_est_afec    = p_tip_est_exp,
          fec_actu        = trn_k_tiempo.f_fec_actu      
    WHERE cod_cia         = p_cod_cia
      AND num_sini        = p_num_sini
      AND mca_exp_recobro = 'S'
      AND num_exp_afec    = p_num_exp;
   --
 END p_actualiza_estado;
  --
 /* -------------------- MODIFICACIONES -------------------- 
 || Usuario   - AA/MM/DD
 || Comentario
 || --------------------------------------------------------
 || TRON2000  - 00/10/24
 || Creacion. Modifica el supervisor, tramitador y estructura 
 ||           comercial de este £ltimo, para el siniestro/exp.
 ||           indicados por par metro.
 ||           Si no se indica tramitador se mantienen los c¢-
 ||           digos de nivel que hubiera en la a7001000.
 */ --------------------------------------------------------
 PROCEDURE p_actualiza
	  ( p_cod_cia          a7001000.cod_cia         %TYPE
	  , p_num_sini         a7001000.num_sini        %TYPE
	  , p_num_exp          a7001000.num_exp         %TYPE
	  , p_cod_supervisor   a7001000.cod_supervisor  %TYPE
	  , p_cod_tramitador   a7001000.cod_tramitador  %TYPE ) 
 IS
 --
    l_cod_nivel1             a7001000.cod_nivel1   %TYPE;
    l_cod_nivel2             a7001000.cod_nivel2   %TYPE;
    l_cod_nivel3             a1001339.cod_nivel3   %TYPE;
    l_cod_nivel3_a7001000    a7001000.cod_nivel3   %TYPE;
    l_cambia                 VARCHAR2(1) := 'N';
 --
 BEGIN
  --
  IF NVL( p_cod_tramitador, trn.COD_TERCERO_GEN ) NOT IN ( trn.COD_TERCERO_GEN, 0 )
  THEN
    --
    -- Change for 1.35: The references to package ts_k_a1001339 are replaced by dc_k_a1001339
    --
    dc_k_a1001339.p_lee_cod_tramitador ( p_cod_cia        => p_cod_cia       , 
                                         p_cod_tramitador => p_cod_tramitador);
    l_cod_nivel3 := dc_k_a1001339.f_cod_nivel3;
    --
    p_lee_a7001000 ( p_cod_cia, p_num_sini , p_num_exp );
    l_cod_nivel3_a7001000  := f_cod_nivel3;
    --
    IF l_cod_nivel3 != l_cod_nivel3_a7001000
    THEN
      --
      l_cambia := 'S';
      dc_k_a1000702.p_lee ( p_cod_cia , l_cod_nivel3 );
      l_cod_nivel1 := dc_k_a1000702.f_cod_nivel1;
      l_cod_nivel2 := dc_k_a1000702.f_cod_nivel2;
      --
    END IF;
    --
  END IF;  -- de p_cod_tramitador NOT IN ( trn.COD_TERCERO_GEN, 0 ) --
  --
  UPDATE  a7001000
     SET  cod_supervisor = p_cod_supervisor,
          cod_tramitador = p_cod_tramitador,
        	 cod_nivel1     = DECODE( l_cambia, 'S', l_cod_nivel1, cod_nivel1 ),
          cod_nivel2     = DECODE( l_cambia, 'S', l_cod_nivel2, cod_nivel2 ),
          cod_nivel3     = DECODE( l_cambia, 'S', l_cod_nivel3, cod_nivel3 ),
          fec_actu       = trn_k_tiempo.f_fec_actu          
  WHERE cod_cia    = p_cod_cia
    AND num_sini   = p_num_sini
    AND num_exp    = p_num_exp;
  --
 END p_actualiza;
  --
 /* --------------------------------------------------------
 || Maria     - 00/12/07
 || Creacion. Sustituye al procedimiento de nucleo 
 || <ts_p_actualiza_a7001000_1_trn>. Dado que los tres campos
 || de importes de valoraci¢n que actualiza, vienen dados por
 || la informacion existente en la tabla h7001200, en lugar
 || de pasarlos por parametros, se determinan dentro del 
 || cuerpo de este procedimiento.
 */ --------------------------------------------------------
 PROCEDURE p_actualiza_reserva_apertura 
	  ( p_cod_cia        a7001000.cod_cia  %TYPE
	  , p_num_sini       a7001000.num_sini %TYPE
	  , p_num_exp        a7001000.num_exp  %TYPE 
	  , p_mca_rva_manual a7001000.mca_rva_manual %TYPE )
 IS
   --
   l_cod_cia_coa      h7001200.cod_cia_coa     %TYPE  := trn.COD_TERCERO_GEN;
   l_imp_val_inicial  a7001000.imp_val_inicial %TYPE;
   l_imp_val          a7001000.imp_val         %TYPE;
   l_imp_val_neto     a7001000.imp_val_neto    %TYPE;
   --
   l_pct_coa        a7001000.pct_coa       %TYPE := NULL;
   l_tip_coaseguro  a7000900.tip_coaseguro %TYPE;
   l_num_poliza     a7000900.num_poliza    %TYPE;
   l_num_spto       a7000900.num_spto      %TYPE;
   l_num_spto_aux   a7000900.num_spto      %TYPE;
   l_num_apli       a7000900.num_apli      %TYPE;
   l_num_spto_apli  a7000900.num_spto_apli %TYPE;
   --
 BEGIN
   --
   ts_k_h7001200.p_lee_sum    ( p_cod_cia
			      , p_num_sini
			      , p_num_exp
			      , l_cod_cia_coa
			      , NULL
			      , NULL             );
   l_imp_val_neto := ts_k_h7001200.f_tot_imp_val;
   --
   ts_k_h7001200.p_lee_sum    ( p_cod_cia
			      , p_num_sini
			      , p_num_exp 
			      , NULL
			      , NULL
			      , NULL         );
   l_imp_val_inicial := ts_k_h7001200.f_tot_imp_val;
   l_imp_val         := l_imp_val_inicial;
   --
   ts_k_a7000900.p_lee_a7000900 ( p_cod_cia, p_num_sini );
   l_tip_coaseguro := ts_k_a7000900.f_tip_coaseguro;
   --
   -- Si es coaseguro cedido, busco el porcentaje de nuestra cia., diferen-
   -- ciando si tenemos o no numero de aplicacion.
   -- si no, pongo el 100.
   --
   IF l_tip_coaseguro = 1 -- Coaseguro cedido.
   THEN
      l_num_poliza    := ts_k_a7000900.f_num_poliza;
      l_num_spto      := ts_k_a7000900.f_num_spto;
      l_num_apli      := ts_k_a7000900.f_num_apli;  
      l_num_spto_apli := ts_k_a7000900.f_num_spto_apli;
      --
      --
      -- Llamada para hallar el num_spto correcto (preguntando si corresponde
      -- a alguna anualidad anterior)
      --
      l_num_spto_aux := em_k_a2000030.f_max_spto_tip_spto ( p_cod_cia      => p_cod_cia    ,
                                                            p_num_poliza   => l_num_poliza ,
                                                            p_num_spto     => l_num_spto   ,
                                                            p_tip_spto     => trn.NULO     ); 
      --
      -- Calculo el porcentaje de participacion para el spto obtenido.
      -- 
      l_pct_coa := em_k_a2000100.f_participacion_coa (p_cod_cia             => p_cod_cia,
                                                      p_num_poliza          => l_num_poliza,
                                                      p_num_spto            => l_num_spto_aux,
                                                      p_cod_cia_aseguradora => trn.COD_TERCERO_GEN,
                                                      p_tip_coaseguro       => l_tip_coaseguro );
      --                                                                                                                                                
   ELSE
      --
      l_pct_coa := 100;
      --
   END IF;
   --
   UPDATE a7001000
      SET mca_rva_manual    = p_mca_rva_manual,
          imp_val           = nvl(l_imp_val,0),
          imp_val_neto      = nvl(l_imp_val_neto,0),
          imp_val_inicial   = nvl(l_imp_val_inicial, imp_val_inicial),
          pct_coa           = l_pct_coa,
          fec_actu          = trn_k_tiempo.f_fec_actu          
    WHERE cod_cia      = p_cod_cia
      AND num_sini     = p_num_sini
      AND num_exp      = p_num_exp;
   --
 END p_actualiza_reserva_apertura;
  --
 /* --------------------------------------------------------
 || Maria     - 00/12/07
 || Creacion. Sustituye a los procedimientos de nucleo 
 || <ts_p_actualiza_a7001000_3_trn>
 || <ts_p_actualiza_a7001000_9_trn>. 
 || Las columnas TIP_EST_EXP y FEC_TERM_EXP se actualizan
 || a traves del procedimiento p_actualiza_estado porque
 || se llevan a cabo otras acciones.
 */ --------------------------------------------------------
 /* Comentado porque el cambio de valoracion se lleva a cabo
    cuando el expediente esta P as¡ que no es necesario modi-
    car el estado previamente, la rehabilitacion y lo trae
    pendiente. En su lugar se ha de llamar a p_actualiza_importes
    */
/* SUSTITUIDO POR p_actualiza_importes
 PROCEDURE p_actualiza_importes_estado 
	 ( p_cod_cia           a7001000.cod_cia        %TYPE,
	   p_num_sini          a7001000.num_sini       %TYPE,
	   p_num_exp           a7001000.num_exp        %TYPE,
           p_tip_est_exp       a7001000.tip_est_exp    %TYPE,
           p_fec_term_exp      a7001000.fec_term_exp   %TYPE,
           p_fec_ult_liq       a7001000.fec_ult_liq    %TYPE,
           p_imp_val           a7001000.imp_val        %TYPE,
           p_imp_val_neto      a7001000.imp_val_neto   %TYPE,
           p_imp_liq           a7001000.imp_liq        %TYPE,
	   p_mca_rva_manual    a7001000.mca_rva_manual %TYPE )
 IS
 BEGIN
  --
   IF p_tip_est_exp IS NOT NULL
   THEN
     p_actualiza_estado ( p_cod_cia
		        , p_num_sini
 		        , p_num_exp
 		        , p_tip_est_exp
 		        , p_fec_term_exp );
   END IF;
   --
   UPDATE a7001000
      SET fec_ult_liq        = NVL(p_fec_ult_liq   , fec_ult_liq    ) ,
          imp_val            = NVL(imp_val,0)      + NVL(p_imp_val,0) ,
          imp_liq            = NVL(imp_liq,0)      + NVL(p_imp_liq,0) ,
          imp_val_neto       = NVL(p_imp_val_neto, imp_val_neto)      ,
          imp_liq_neto       = NVL(imp_liq_neto,0) + NVL(p_imp_liq,0) ,
          mca_rva_manual     = NVL(p_mca_rva_manual, mca_rva_manual )
    WHERE cod_cia      = p_cod_cia
      AND num_sini     = p_num_sini
      AND num_exp      = p_num_exp ;
   --
 END p_actualiza_importes_estado;
  SUSTITUIDO por p_actualiza_importes */
  --
 PROCEDURE p_actualiza_importes
	 ( p_cod_cia           a7001000.cod_cia        %TYPE,
	   p_num_sini          a7001000.num_sini       %TYPE,
	   p_num_exp           a7001000.num_exp        %TYPE,
    p_fec_ult_liq       a7001000.fec_ult_liq    %TYPE,
    p_imp_val           a7001000.imp_val        %TYPE,
    p_imp_val_neto      a7001000.imp_val_neto   %TYPE,
    p_imp_liq           a7001000.imp_liq        %TYPE,
	   p_mca_rva_manual    a7001000.mca_rva_manual %TYPE )
 IS
    --
 BEGIN
  --
    UPDATE a7001000
      SET fec_ult_liq        = NVL(p_fec_ult_liq   , fec_ult_liq    ) ,
          imp_val            = NVL(imp_val,0)      + NVL(p_imp_val,0) ,
          imp_liq            = NVL(imp_liq,0)      + NVL(p_imp_liq,0) ,
          imp_val_neto       = NVL(p_imp_val_neto, imp_val_neto)      ,
          imp_liq_neto       = NVL(imp_liq_neto,0) + NVL(p_imp_liq,0) ,
          mca_rva_manual     = NVL(p_mca_rva_manual, mca_rva_manual ),
          fec_actu           = trn_k_tiempo.f_fec_actu          
    WHERE cod_cia      = p_cod_cia
      AND num_sini     = p_num_sini
      AND num_exp      = p_num_exp ;
   --
 END p_actualiza_importes;
  --
 /* --------------------------------------------------------
 || Maria     - 00/12/07
 || Creacion. Sustituye al procedimiento de nucleo 
 || <ts_p_actualiza_a7001000_7_trn> 
 || Inserta en la a7001020.
 */ --------------------------------------------------------
 PROCEDURE p_actualiza_juicio 
	 ( p_cod_cia           a7001000.cod_cia        %TYPE,
	   p_num_sini          a7001000.num_sini       %TYPE,
	   p_num_exp           a7001000.num_exp        %TYPE,
    p_num_juicio        a7005000.num_juicio     %TYPE,
    p_mca_juicio        a7001000.mca_juicio     %TYPE,
    p_tip_est_juicio    a7001000.tip_est_juicio %TYPE )
 IS
    l_mca_juicio          a7001000.mca_juicio     %TYPE;
    l_tip_est_juicio      a7001000.tip_est_juicio %TYPE ;
    --
    l_mca_juicio_ant      a7001000.mca_juicio     %TYPE;
    l_tip_est_juicio_ant  a7001000.tip_est_juicio %TYPE;
    --
    l_mca_estado_a7001020 a7001020.mca_estado     %TYPE;
    --
    l_cod_sector       a7001020.cod_sector        %TYPE;
    l_cod_ramo         a7001020.cod_ramo          %TYPE;
    l_cod_supervisor   a7001020.cod_supervisor    %TYPE;
    l_cod_tramitador   a7001020.cod_tramitador    %TYPE;
    l_num_modificacion a7001020.num_modificacion  %TYPE;
    l_obs              a7001020.observaciones     %TYPE;
    l_cod_usr          a7001020.cod_usr           %TYPE;
    l_fec_mvto         a7001020.fec_mvto          %TYPE;
    --
 BEGIN
   --
   /* Si quiero actualizar el juicio como terminado, miro que el expediente no tenga 
      otro juicio pendiente */
   --
   l_tip_est_juicio := p_tip_est_juicio ;
   --
   l_mca_juicio     := p_mca_juicio;   
   --
   /* Evaluo la marca que recibo */
   --
   IF l_tip_est_juicio = 'T'
   THEN
      IF ts_k_a7005010.f_val_jui_pen (p_cod_cia,
                                      p_num_sini,
                                      p_num_exp ,
                                      p_num_juicio) = 'S'
      THEN
         --
         l_tip_est_juicio := 'P';
         --
         l_mca_estado_a7001020     := 'JU';
         --
      ELSE -- Si no hay otros juicios pendientes
      --
      /* Si se termina el juicio el estado del expediente de la a7001020
         pasará de JU, a Pendiente */
         --
         l_mca_estado_a7001020     := 'P';
         --
      END IF;
      --
    ELSE -- Si el tip_est_juicio es 'P'
      --
      l_tip_est_juicio      := 'P';
      l_mca_estado_a7001020 := 'JU';
      --
    END IF; 
    --
    /* Si quiero actualizar la marca juicio a 'N', miro que el expediente no tenga
    otro juicio */
    --
    IF l_mca_juicio = 'N'
    THEN
       --
       IF ts_k_a7005010.f_val_exp_jui( p_cod_cia,
                                      p_num_sini,
                                      p_num_exp) = 'S'
       THEN
          --
          l_mca_juicio          := 'S';
          l_mca_estado_a7001020 := 'JU';
          --
       ELSE -- Si no hay juicios pendientes
          --
          l_mca_estado_a7001020 := 'P';
          --
       END IF;
       --
    END IF;
    --
    /* Lee como estaba la marca y estado del juicio antes de update.Si están iguales
       no hago nada*/
    --
    p_lee_a7001000 (p_cod_cia,
                    p_num_sini,
                    p_num_exp);
    --
    l_mca_juicio_ant     := f_mca_juicio;
    --
    l_tip_est_juicio_ant := f_tip_est_juicio;
    --
    IF NVL(l_mca_juicio_ant,'Z')     != l_mca_juicio   OR 
       NVL(l_tip_est_juicio_ant,'Z') != NVL(l_tip_est_juicio,'P')
    THEN
      --
      UPDATE a7001000
         SET mca_juicio     = l_mca_juicio     ,
             tip_est_juicio = l_tip_est_juicio ,
             fec_actu       = trn_k_tiempo.f_fec_actu          
          WHERE cod_cia        = p_cod_cia
            AND num_sini       = p_num_sini
            AND num_exp        = p_num_exp ;
      --
      l_cod_sector       := f_cod_sector;
      l_cod_ramo         := f_cod_ramo;
      l_cod_supervisor   := f_cod_supervisor;
      l_cod_tramitador   := f_cod_tramitador;
      --
      ts_k_a7001020.p_lee(p_cod_cia,
                          p_num_sini,
                          p_num_exp);
      --
      l_num_modificacion := ts_k_a7001020.f_num_modificacion + 1;
      --
      l_fec_mvto         := TO_DATE(trn_k_global.devuelve ('fec_proceso'),'DDMMYYYY');
      l_cod_usr          := trn_k_global.cod_usr;
      --
      ts_k_a7001020.p_inserta_a7001020 (p_cod_cia                ,
                                        l_cod_sector             ,
                                        l_cod_ramo               ,
                                        l_cod_supervisor         ,         
                                        l_cod_tramitador         ,
                                        p_num_sini               ,
                                        p_num_exp                ,
                                        l_num_modificacion       ,
                                        l_mca_estado_a7001020    ,
                                        l_obs                    ,
                                        l_fec_mvto               ,
                                        l_cod_usr                );
    END IF;
   --
 END p_actualiza_juicio;
  --
 /* --------------------------------------------------------
 || Maria     - 00/11/23
 || Creacion
 */ --------------------------------------------------------
 PROCEDURE p_lee_datos_siniestro ( p_cod_cia  a7001000.cod_cia %TYPE,
                                   p_num_sini a7001000.num_sini%TYPE ) 
 IS
 --
 /* -------------------- DESCRIPCION ----------------------- 
 || Procedimiento que recorre los expedientes del siniestro
 || indicado por par metros acumulando los totales de :
 ||   valoracion_inicial en G_TOT_IMP_VAL_INICIAL;
 ||   valoracion         en G_TOT_IMP_VAL        ;
 ||   liquidado          en G_TOT_IMP_LIQ        ;
 ||   pagado             en G_TOT_IMP_PAG        ;
 */ -------------------------------------------------------
 --
   l_tot_imp_val_inicial    NUMBER := 0;
   l_tot_imp_val            NUMBER := 0;
   l_tot_imp_liq            NUMBER := 0;
   l_tot_imp_pag            NUMBER := 0;
 --
 BEGIN
    --
    g_existen_expedientes := TRUE;
    --
    ts_k_apertura.p_imp_cons_siniestro (p_cod_cia        ,
                                        p_num_sini       ,
                                        l_tot_imp_val_inicial,
                                        l_tot_imp_val    ,
                                        l_tot_imp_liq,
                                        l_tot_imp_pag); 
    --
    g_tot_imp_val_inicial := l_tot_imp_val_inicial;
    g_tot_imp_val         := l_tot_imp_val    ;
    g_tot_imp_liq         := l_tot_imp_liq;
    g_tot_imp_pag         := l_tot_imp_pag; 
    --
 END p_lee_datos_siniestro;
 --
 --
 /* -------------------- DESCRIPCION ---------------------- 
 || Maria     - 00/12/11
 || Creacion. Sustituye a la funcion de nucleo con nombre
 || <ts_f_val_exp_judiciales_trn>. El valor retornado sera 
 || 'S' si existen expedientes para asociar al juicio.     
 */ -------------------------------------------------------
 FUNCTION f_val_exp_judiciales 
       ( p_cod_cia        a7001000.cod_cia   %TYPE
       , p_num_sini       a7001000.num_sini  %TYPE )
 RETURN VARCHAR2
 IS
   l_cuenta_exp    VARCHAR2(1);
 BEGIN
   OPEN        c_a7001000_juicios( p_cod_cia, p_num_sini );
   FETCH       c_a7001000_juicios INTO l_cuenta_exp;
   CLOSE       c_a7001000_juicios;
   --
   RETURN l_cuenta_exp;
   --
 END f_val_exp_judiciales;
 --
 /* -------------------- DESCRIPCION ---------------------- 
 || Maria     - 00/12/11
 || Creacion. Sustituye a la funcion de nucleo con nombre
 || <ts_f_cuenta_exp_trn>. El valor retornado sera el n§   
 || de expedientes del siniestro con el tipo de expediente 
 || indicado por par metro (si se indica nulo se cuentan
 || todos). 
 */ -------------------------------------------------------
 FUNCTION f_cuenta_exp 
       ( p_cod_cia        a7001000.cod_cia   %TYPE
       , p_num_sini       a7001000.num_sini  %TYPE
       , p_tip_exp        a7001000.tip_exp   %TYPE )
 RETURN NUMBER 
 IS
   l_cuenta_exp    NUMBER;
 BEGIN
   --
   SELECT COUNT(*)
     INTO l_cuenta_exp
     FROM A7001000
    WHERE cod_cia     = p_cod_cia
      AND num_sini    = p_num_sini
      AND tip_exp     = NVL(p_tip_exp, tip_exp);
   --
   RETURN l_cuenta_exp;
 END f_cuenta_exp;
 --
 FUNCTION f_hay_exp_no_definidos ( p_cod_cia   a7001000.cod_cia   %TYPE ,
                                   p_num_sini  a7001000.num_sini  %TYPE ,
                                   p_cod_ramo  g7000080.cod_ramo  %TYPE ,
                                   p_cod_causa g7000080.cod_causa %TYPE )
 RETURN VARCHAR2 
 IS
 /* -------------------- DESCRIPCION ---------------------- 
 || Maria     - 00/12/11
 || Creacion. Sustituye a la funcion de nucleo con nombre
 || <ts_f_a7001000_3_trn>. El valor retornado sera una 'S'
 || si hay algun expediente aperturado y que no este 
 || definido en la tabla g7000080 para la causa indicada.
 */ -------------------------------------------------------
 --
   l_contador   NUMBER(6) := 0;
   --   
   CURSOR c_a7001000
   IS
     SELECT COUNT(*)
     FROM a7001000
     WHERE cod_cia  = p_cod_cia
       AND num_sini = p_num_sini
       AND tip_exp NOT IN ( SELECT tip_exp
                            FROM g7000080
                            WHERE cod_cia   = p_cod_cia
                            AND cod_ramo  = p_cod_ramo
                            AND cod_causa = p_cod_causa );
 --
 BEGIN
  --
  OPEN  c_a7001000;
  FETCH c_a7001000 INTO l_contador;
  CLOSE c_a7001000;
  --
  IF l_contador > 0
  THEN
    RETURN 'S';
  ELSE
    RETURN 'N';
  END IF;
  --
 END f_hay_exp_no_definidos;
 --
 /* -------------------- DESCRIPCION ---------------------- 
 || Maria     - 00/12/11
 || Creacion. Sustituye a la funcion de nucleo con nombre
 || <ts_f_a7001000_4_trn>. El valor retornado sera el n§   
 || de expedientes del siniestro con el codigo de supervisor
 || indicado por par metro.                        
 */ ------------------------------------------------------- 
 FUNCTION f_num_exp_del_supervisor 
	  ( p_cod_cia   a7001000.cod_cia              %TYPE
	  , p_num_sini  a7001000.num_sini             %TYPE
	  , p_cod_supervisor a7001000.cod_supervisor  %TYPE )
 RETURN NUMBER 
 IS
 --
   l_cuenta_exp    NUMBER;
 BEGIN
   --
   SELECT COUNT(*)
     INTO l_cuenta_exp
     FROM a7001000
    WHERE cod_cia        = p_cod_cia
      AND num_sini       = p_num_sini
      AND cod_supervisor = p_cod_supervisor;
   --
   RETURN l_cuenta_exp;
 END f_num_exp_del_supervisor ;
 --
 /*-------------------------------------------------------
 || f_cuenta_recobros_de_un_exp
 */ -------------------------------------------------------
-- 
 FUNCTION f_cuenta_recobros_de_un_exp
       ( p_cod_cia        a7001000.cod_cia       %TYPE,
         p_num_sini       a7001000.num_sini      %TYPE,
         p_tip_exp        a7001000.tip_exp       %TYPE,
         p_num_exp_afec   a7001000.num_exp_afec  %TYPE )
 RETURN NUMBER 
 IS
   --
   l_cuenta     a7001000.num_exp      %TYPE;
   --
 BEGIN
   --
   SELECT COUNT(*)
     INTO l_cuenta
     FROM a7001000
    WHERE cod_cia         = p_cod_cia
      AND num_sini        = p_num_sini
      AND tip_exp         = p_tip_exp
      AND num_exp_afec    = p_num_exp_afec
      AND mca_exp_recobro = 'S';
   --
   RETURN NVL(l_cuenta, 0);
   --
 END f_cuenta_recobros_de_un_exp;
 --
 /* -------------------- DESCRIPCION ---------------------- 
 || f_hay_expedientes_retenido
 */ -------------------------------------------------------
 --
 FUNCTION f_hay_expedientes_retenido ( p_cod_cia   a7001000.cod_cia   %TYPE
                                     , p_num_sini  a7001000.num_sini  %TYPE )
 RETURN VARCHAR2 
 IS
 --
   l_hay   VARCHAR2(1) := 'N';
   --
   CURSOR c_a7001000
   IS
     SELECT 'S'
     FROM a7001000
     WHERE cod_cia                  = p_cod_cia
       AND num_sini                 = p_num_sini
       AND NVL(mca_provisional,'N') = 'S';
 --
 BEGIN
  --
  OPEN  c_a7001000;
  FETCH c_a7001000 INTO l_hay;
  CLOSE c_a7001000;
  --
  RETURN l_hay;
  --
 END f_hay_expedientes_retenido;
 --
 /* -------------------- DESCRIPCION ---------------------- 
 || f_max_num_exp
 */ -------------------------------------------------------
 --
 FUNCTION f_max_num_exp ( p_cod_cia        a7001000.cod_cia   %TYPE,
                          p_num_sini       a7001000.num_sini  %TYPE )
 RETURN NUMBER  
 IS
   --
   l_max_num_exp    a7001000.num_exp      %TYPE;
   -- 
 BEGIN
   --
   SELECT MAX(num_exp)
     INTO l_max_num_exp
     FROM a7001000
    WHERE cod_cia         = p_cod_cia
      AND num_sini        = p_num_sini;
   --
   RETURN NVL(l_max_num_exp, 0);
   --
 END f_max_num_exp;
 --
 /* -------------------- DESCRIPCION ----------------------- 
 || ABMUNO     - 16/05/2007
 ||  Procedimiento que inserta un registro completo en la A7001000.
 */ ------------------------------------------------------- 
 --
 PROCEDURE p_inserta (p_reg a7001000%ROWTYPE)
 IS
 BEGIN
   --
   INSERT INTO a7001000
         ( cod_cia          ,
           cod_sector       ,
           cod_ramo         ,
           num_sini         ,
           num_exp          ,
           tip_exp          ,
           tip_est_exp      ,
           mca_exp_recobro  ,
           mca_recobro      ,
           tip_est_recobro  ,
           num_exp_afec     ,
           tip_exp_afec     ,
           tip_est_afec     ,
           mca_juicio       ,
           tip_est_juicio   ,
           fec_aper_exp     ,
           fec_term_exp     ,
           fec_modi_exp     ,
           fec_reap_exp     ,
           fec_ult_liq      ,
           mca_provisional  ,
           fec_autorizacion ,
           tip_docum        ,
           cod_docum        ,
           nombre           ,
           apellidos        ,
           cod_mon          ,
           imp_val_inicial  ,
           mca_rva_manual   ,
           imp_val          ,
           imp_liq          ,
           imp_pag          ,
           imp_val_neto     ,
           imp_liq_neto     ,
           imp_pag_neto     ,
           pct_coa          ,
           imp_rva_3112     ,
           fec_rva_3112     ,
           cod_supervisor   ,
           cod_tramitador   ,
           cod_usr          ,
           fec_actu         ,
           mca_calcula_rva  ,
           cod_nivel1       ,
           cod_nivel2       ,
           cod_nivel3       ,
           tip_apertura     ,
           fec_denu_exp     ,
           fec_aviso_exp    
         )
  VALUES ( p_reg.cod_cia          ,
           p_reg.cod_sector       ,
           p_reg.cod_ramo         ,
           p_reg.num_sini         ,
           p_reg.num_exp          ,
           p_reg.tip_exp          ,
           p_reg.tip_est_exp      ,
           p_reg.mca_exp_recobro  ,
           p_reg.mca_recobro      ,
           p_reg.tip_est_recobro  ,
           p_reg.num_exp_afec     ,
           p_reg.tip_exp_afec     ,
           p_reg.tip_est_afec     ,
           p_reg.mca_juicio       ,
           p_reg.tip_est_juicio   ,
           p_reg.fec_aper_exp     ,
           p_reg.fec_term_exp     ,
           p_reg.fec_modi_exp     ,
           p_reg.fec_reap_exp     ,
           p_reg.fec_ult_liq      ,
           p_reg.mca_provisional  ,
           p_reg.fec_autorizacion ,
           p_reg.tip_docum        ,
           p_reg.cod_docum        ,
           p_reg.nombre           ,
           p_reg.apellidos        ,
           p_reg.cod_mon          ,
           p_reg.imp_val_inicial  ,
           p_reg.mca_rva_manual   ,
           p_reg.imp_val          ,
           p_reg.imp_liq          ,
           p_reg.imp_pag          ,
           p_reg.imp_val_neto     ,
           p_reg.imp_liq_neto     ,
           p_reg.imp_pag_neto     ,
           p_reg.pct_coa          ,
           p_reg.imp_rva_3112     ,
           p_reg.fec_rva_3112     ,
           p_reg.cod_supervisor   ,
           p_reg.cod_tramitador   ,
           p_reg.cod_usr          ,
           p_reg.fec_actu         ,
           p_reg.mca_calcula_rva  ,
           p_reg.cod_nivel1       ,
           p_reg.cod_nivel2       ,
           p_reg.cod_nivel3       ,
           p_reg.tip_apertura     ,
           p_reg.fec_denu_exp     ,
           p_reg.fec_aviso_exp    
         );
   --
 END p_inserta;
 -- 
 /* -------------------- DESCRIPCION ----------------------- 
 || ABMUNO     - 16/05/2007
 ||  Procedimiento que actualiza las fechas de denucia y de 
 || aviso del expediente.
 */ -------------------------------------------------------
 -- 
 PROCEDURE p_actualiza_fec_exp ( p_cod_cia       a7001000.cod_cia      %TYPE,
                                 p_num_sini      a7001000.num_sini     %TYPE,
                                 p_num_exp       a7001000.num_exp      %TYPE,
                                 p_fec_denu_exp  a7001000.fec_denu_exp %TYPE,
                                 p_fec_aviso_exp a7001000.fec_aviso_exp%TYPE )
 IS
 BEGIN
    --
    UPDATE a7001000
    SET fec_denu_exp  = p_fec_denu_exp,
        fec_aviso_exp = p_fec_aviso_exp,
        fec_actu      = trn_k_tiempo.f_fec_actu
   WHERE cod_cia  = p_cod_cia
     AND num_sini = p_num_sini
     AND num_exp  = p_num_exp ;    
    --                                 
 END p_actualiza_fec_exp;
 --
  -- 
 /* -------------------- DESCRIPCION -----------------------
 || PPASTOR - 24/10/2007
 || Procedimiento que busca el nombre de la persona
 || relacionada con el expediente.
 */ -------------------------------------------------------
 -- 
 PROCEDURE p_nom_persona_rel(p_cod_cia          IN a7001000.cod_cia          %TYPE,
                             p_tip_docum        IN v1001390.tip_docum        %TYPE, 
                             p_cod_docum        IN v1001390.cod_docum        %TYPE,
                             p_nombre_rel       IN OUT v1001390.nom_completo %TYPE)
 IS
    --
    CURSOR c_nom_persona_rel IS
    SELECT nombre, apellidos
      FROM A7001000
     WHERE cod_cia   = p_cod_cia
       AND tip_docum = p_tip_docum
       AND cod_docum = p_cod_docum;
    --   
    l_nom_persona_rel v1001390.nom_completo %TYPE;
    --
    l_ape_persona_rel a7001000.apellidos    %TYPE;
    --
 BEGIN
    -- 
    OPEN c_nom_persona_rel;
    FETCH c_nom_persona_rel INTO l_nom_persona_rel, l_ape_persona_rel;
    --
    IF c_nom_persona_rel%FOUND
    THEN
       --
       p_nombre_rel := l_ape_persona_rel || ', ' || l_nom_persona_rel; 
       --
    END IF;
    --
    CLOSE c_nom_persona_rel;
    -- 
 END p_nom_persona_rel;
 -- 
END ts_k_a7001000_trn;

create or replace PACKAGE BODY ts_k_ap700117_trn
IS
 --
 /* ------------------- VERSION = 1.32 -----------------*/
 --
 /* -------------------- DESCRIPCION --------------------
 || Package en el cual se van a incluir todos los procesos necesarios
 || para el control de la rutina ap700117.
 || Rutina que controla la Apertura de Expedientes.
 || --
 || -------------------------------------------------------------------
 || 2015/10/21 - JLOROMERO - 1.32 - (MU-2015-056746)
 || Se crea el procedimiento p_batch_recobro_aut para la apertura automatica de
 || recobros asociados a expedientes de no recobro.
 */ -------------------------------------------------------------------
 --
 -- ==============================================================
 /*
 ||               Globales al package.
 */
 -- ==============================================================
 --
 -- Tablas de Siniestro
 --
 g_cod_cia             a7000900.cod_cia             %TYPE;
 g_cod_ramo            a7000900.cod_ramo            %TYPE;
 g_num_sini            a7000900.num_sini            %TYPE;
 g_cod_causa           a7000900.cod_causa_sini      %TYPE;
 g_cod_supervisor      a7001020.cod_supervisor      %TYPE;
 g_cod_tramitador      a7001020.cod_tramitador      %TYPE;
 g_tip_tramitador      a1001339.tip_tramitador      %TYPE;
 g_nom_tramitador      v1001390.nom_completo        %TYPE;
 g_fec_proceso         a7000900.fec_sini            %TYPE;
 g_cod_usr             a7000900.cod_usr             %TYPE;
 --
 g_tip_mvto_batch_stro b7000910.tip_mvto_batch_stro %TYPE;
 --
 g_cod_idioma        g1010010.cod_idioma      %TYPE := trn_k_global.cod_idioma;
 g_cod_mensaje       g1010020.cod_mensaje     %TYPE;
 g_anx_mensaje         VARCHAR(250);
 g_txt_error           VARCHAR(250);
 --
 g_k_ini_corchete CONSTANT VARCHAR2(2) := ' [';
 g_k_fin_corchete CONSTANT VARCHAR2(1) := ']';
 g_k_fin_corchete CONSTANT VARCHAR2(1) := ']';
 --
 ge_no_existe EXCEPTION;
 PRAGMA EXCEPTION_INIT (ge_no_existe, -20001);
 --
 /* --------------------------------------------------------------
 ||               Procedimientos Internos
 */---------------------------------------------------------------
 --
 /* -----------------------------------------------------
 || pp_error_despues_de_tratarlo :
 ||
 || Se ha producido un error, se ha tratado la excepcion
 || y ahora hay que devolverlo al llamador
 */ -----------------------------------------------------
 --
 PROCEDURE pp_error_despues_de_tratarlo IS
 BEGIN
  --
  IF g_cod_mensaje BETWEEN -20999
                       AND -20000
   THEN
    --
    RAISE_APPLICATION_ERROR(g_cod_mensaje,
                             SUBSTR(g_txt_error
                                    ,INSTR(g_txt_error  ,
                                           g_cod_mensaje,
                                           -1
                                          ) + 7
                                   )
                            );
    --
   ELSE
    --
    RAISE_APPLICATION_ERROR(-20000,g_txt_error);
    --
  END IF;
  --
 END pp_error_despues_de_tratarlo;
 --
 /* ----------------------------------------------------
 || Devuelve el error
 */ ----------------------------------------------------
 --
 PROCEDURE pp_devuelve_error IS
 BEGIN
  --
  IF g_cod_mensaje BETWEEN 20000
                       AND 20999
  THEN
     --
     RAISE_APPLICATION_ERROR(-g_cod_mensaje,
                             ss_k_mensaje.f_texto_idioma(g_cod_mensaje,
                                                         g_cod_idioma ) ||
                             g_anx_mensaje
                            );
     --
  ELSE
     --
     RAISE_APPLICATION_ERROR(-20000,
                             ss_k_mensaje.f_texto_idioma(g_cod_mensaje,
                                                         g_cod_idioma ) ||
                             g_anx_mensaje
                            );
     --
  END IF;
  --
 END pp_devuelve_error;
 --
 /* -----------------------------------------------------
 || pp_asigna :
 ||
 || Llama a trn_k_global.asigna
 */ -----------------------------------------------------
 --
 PROCEDURE pp_asigna(p_nom_global VARCHAR2,
                     p_val_global VARCHAR2) IS
 BEGIN
  --
  trn_k_global.asigna(p_nom_global,p_val_global);
  --
 END pp_asigna;
 --
 /* -----------------------------------------------------
 || pp_asigna :
 ||
 || Llama a trn_k_global.asigna
 */ -----------------------------------------------------
 --
 PROCEDURE pp_asigna(p_nom_global VARCHAR2,
                     p_val_global NUMBER  ) IS
 BEGIN
  --
  trn_k_global.asigna(p_nom_global,TO_CHAR(p_val_global));
  --
 END pp_asigna;
 --
 /* -----------------------------------------------------
 || pp_asigna :
 ||
 || Llama a trn_k_global.asigna
 */ -----------------------------------------------------
 --
 PROCEDURE pp_asigna(p_nom_global VARCHAR2,
                     p_val_global DATE    ) IS
 BEGIN
  --
  trn_k_global.asigna(p_nom_global,TO_CHAR(p_val_global,'ddmmyyyy'));
  --
 END pp_asigna;
 --
 --
 /* --------------------------------------------------------
 || mx :
 ||
 || Genera la traza
 */ --------------------------------------------------------
 --
 PROCEDURE mx(p_tit VARCHAR2,
              p_val VARCHAR2) IS
 BEGIN
  --
  pp_asigna('fic_traza','sini'      );
  pp_asigna('cab_traza','ap700117->');
  --
  /*
  em_k_traza.p_escribe(p_tit,
                       p_val);
  */
  --
 END mx;
 --
 /* --------------------------------------------------------
 || mx :
 ||
 || Genera la traza
 */ --------------------------------------------------------
 --
 PROCEDURE mx(p_tit VARCHAR2,
              p_val BOOLEAN ) IS
 BEGIN
  --
  pp_asigna('fic_traza','sini'      );
  pp_asigna('cab_traza','ap700117->');
  --
  /*
  em_k_traza.p_escribe(p_tit,
                       p_val);
  */
  --
 END mx;
 --
 /* ----------------------------------------------------
 || Devuelve la descripcion del error
 */ ----------------------------------------------------
 --
 FUNCTION fp_txt_mensaje(p_cod_mensaje g1010020.cod_mensaje%TYPE)
          RETURN g1010020.txt_mensaje%TYPE IS
 BEGIN
  --
  RETURN ss_k_mensaje.f_texto_idioma(p_cod_mensaje,g_cod_idioma);
  --
 END fp_txt_mensaje;
 --
 /* ----------------------------------------------------
 || Valida sobre la tabla g1010031
 */ ----------------------------------------------------
 --
 FUNCTION fp_g1010031(p_cod_campo g1010031.cod_campo%TYPE,
                      p_cod_valor g1010031.cod_valor%TYPE)
          RETURN g1010031.nom_valor%TYPE IS
  --
  l_retorno g1010031.nom_valor%TYPE := NULL;
  --
 BEGIN
  --
  l_retorno := ss_f_nom_valor(p_cod_campo ,
                              999         ,
                              p_cod_valor ,
                              g_cod_idioma);
  --
  RETURN l_retorno;
  --
 END fp_g1010031;
 --
--
PROCEDURE pp_inicializa_variables
IS
--
BEGIN
  --
  g_cod_idioma          :=  NULL;
  g_cod_cia             :=  NULL;
  g_num_sini            :=  NULL;
  --
  g_cod_causa           :=  NULL;
  g_cod_supervisor      :=  NULL;
  g_cod_tramitador      :=  NULL;
  g_tip_tramitador      :=  NULL;
  g_nom_tramitador      :=  NULL;
  g_fec_proceso         :=  NULL;
  g_cod_usr             :=  NULL;
  --
  g_tip_mvto_batch_stro := NULL;
  --
END pp_inicializa_variables;
--
--
PROCEDURE pp_carga_globales
IS
--
   l_fec_proc_sini      a1001600.fec_proc_stro        %TYPE;
BEGIN
  --
  g_tip_mvto_batch_stro:= trn_k_global.ref_f_global('tip_mvto_batch_stro');
  --
  g_cod_usr            :=  trn_k_global.cod_usr;
  g_cod_idioma         :=  trn_k_global.cod_idioma;
  g_cod_cia            :=  trn_k_global.devuelve ('cod_cia');
  g_num_sini           :=  trn_k_global.devuelve ('num_sini');
  --
  g_cod_tramitador     :=  trn_k_global.devuelve ('cod_tramitador');
  g_tip_tramitador     :=  trn_k_global.devuelve ('tip_tramitador');
  g_cod_supervisor     :=  trn_k_global.devuelve ('cod_supervisor');
  g_fec_proceso        :=  TO_DATE(trn_k_global.devuelve ('fec_proceso'),
                           'DDMMYYYY');
  --
EXCEPTION
WHEN ge_no_existe
THEN
     RAISE_APPLICATION_ERROR(-20001,'[TS_K_ap700117] '||SQLERRM);
END pp_carga_globales;
--
--
PROCEDURE pp_borra_globales
IS
BEGIN
  --
  /* Borra las globales creadas por este package. */
  --
  trn_k_global.borra_variable ('cod_causa');
  trn_k_global.borra_variable ('num_poliza');
  trn_k_global.borra_variable ('num_spto');
  trn_k_global.borra_variable ('max_spto_40');
  trn_k_global.borra_variable ('num_apli');
  trn_k_global.borra_variable ('num_spto_apli');
  trn_k_global.borra_variable ('max_spto_apli_40');
  trn_k_global.borra_variable ('num_riesgo');
  trn_k_global.borra_variable ('num_periodo');
  trn_k_global.borra_variable ('nom_tramitador');
  --
  trn_k_global.borra_variable ('estado_admitido_sini');
  trn_k_global.borra_variable ('admite_provisional_sini');
  --
  --
END pp_borra_globales;
--
--
/* --------------------------------------------------------------
||  Procedimiento que se lanza antes del ts_k_cabsini.p_inicio.
||  Carga en globales, los estados que admite el programa de apertura
|| de expedientes:
||  El siniestro ha de estar Pendiente (a no ser que venga de la Rehabili-
|| tacion de Siniestros).
||  El siniestro no puede estar retenido por Control Tecnico.
*/ --------------------------------------------------------------
--
PROCEDURE p_carga_globales_validacion
IS
BEGIN
  --
  trn_k_global.asigna ('estado_admitido_sini'       , 'P');
  trn_k_global.asigna ('admite_provisional_sini'    , 'N');
  --
END p_carga_globales_validacion;
--
--
/* --------------------------------------------------------------
||  Procedimiento inicializa las variables, borra la tabla de memoria de
|| los expediente que se van a aperturar y carga las globales.
*/ --------------------------------------------------------------
--
PROCEDURE p_inicio
IS
BEGIN
  --
  pp_inicializa_variables;
  --
  -- pp_carga_globales;
  --
END p_inicio;
--
/* --------------------------------------------------------------
|| Devuelve los campos que se van a visializar en la pantalla.
*/ --------------------------------------------------------------
PROCEDURE p_devuelve
         (p_cod_evento           IN OUT  a7000900.cod_evento       %TYPE ,
          p_nom_evento           IN OUT  a7990700.nom_evento       %TYPE ,
          p_cod_causa            IN OUT  a7000900.cod_causa_sini   %TYPE ,
          p_nom_causa            IN OUT  g7000200.nom_causa        %TYPE ,
          p_cod_consecuencia_1   IN OUT  a7000930.cod_consecuencia %TYPE ,
          p_cod_consecuencia_2   IN OUT  a7000930.cod_consecuencia %TYPE ,
          p_cod_consecuencia_3   IN OUT  a7000930.cod_consecuencia %TYPE ,
          p_cod_consecuencia_4   IN OUT  a7000930.cod_consecuencia %TYPE ,
          p_cod_consecuencia_5   IN OUT  a7000930.cod_consecuencia %TYPE )
--
IS
  --
  l_contador NUMBER;
  l_mca_tramitable    g7000200.mca_tramitable %TYPE;
  --
  CURSOR c_a7000930 ( pc_cod_cia         a7000930.cod_cia     %TYPE,
                      pc_num_sini        a7000930.num_sini    %TYPE,
                      pc_cod_causa       a7000930.cod_causa   %TYPE)
      IS
  SELECT cod_consecuencia
    FROM a7000930
   WHERE cod_cia   = pc_cod_cia
     AND num_sini  = pc_num_sini
     AND tip_causa = 1
     AND cod_causa = pc_cod_causa
     AND fec_mvto  = (SELECT MAX(fec_mvto)
                        FROM A7000930
                       WHERE cod_cia   = pc_cod_cia
                         AND num_sini  = pc_num_sini
                         AND tip_causa = 1
                         AND cod_causa = pc_cod_causa)
    ORDER BY cod_consecuencia;
  --
  l_tip_poliza_stro a7000900.tip_poliza_stro%TYPE;
  --
BEGIN
   --
   pp_carga_globales;
   --
   ts_k_a7000900.p_lee_a7000900 (g_cod_cia, g_num_sini);
   --
   -- se valida que la póliza no sea ficticia
   l_tip_poliza_stro := ts_k_a7000900.f_tip_poliza_stro;
   IF l_tip_poliza_stro = 'FT'
   THEN
      --
      -- POLIZA FICTICIA TEMPORAL, NO SE PUEDEN ABRIR EXPEDIENTES
      g_cod_mensaje := 70001222;
      g_anx_mensaje := NULL;
      --
      pp_devuelve_error;
      --
   END IF;
   --
   g_cod_ramo      := ts_k_a7000900.f_cod_ramo;
   p_cod_evento    := ts_k_a7000900.f_cod_evento;
   --
   IF p_cod_evento IS NOT NULL
   THEN
      --
      ts_k_a7990700.p_lee (p_cod_evento);
      p_nom_evento := ts_k_a7990700.f_nom_evento;
      --
   ELSE
      --
      p_nom_evento := NULL;
      --
   END IF;
   --
   p_cod_causa := ts_k_a7000900.f_cod_causa_sini;
   g_cod_causa := p_cod_causa;
   --
   ts_k_g7000200.p_lee (g_cod_cia,
                        1,           -- tip_causa de Siniestros
                        g_cod_causa);
   --
   p_nom_causa      := ts_k_g7000200.f_nom_causa;
   l_mca_tramitable := ts_k_g7000200.f_mca_tramitable;
   --
   l_contador := 0;
   --
   FOR reg1 IN c_a7000930 (g_cod_cia, g_num_sini, g_cod_causa)
   LOOP
      --
      EXIT WHEN l_contador = 5;
      --
      l_contador := l_contador + 1;
      --
      IF l_contador = 1
      THEN
         --
         p_cod_consecuencia_1 := reg1.cod_consecuencia;
         --
      ELSIF l_contador = 2
      THEN
         --
         p_cod_consecuencia_2 := reg1.cod_consecuencia;
         --
      ELSIF l_contador = 3
      THEN
         --
         p_cod_consecuencia_3 := reg1.cod_consecuencia;
         --
      ELSIF l_contador = 4
      THEN
         --
         p_cod_consecuencia_4 := reg1.cod_consecuencia;
         --
      ELSIF l_contador = 5
      THEN
         --
         p_cod_consecuencia_5 := reg1.cod_consecuencia;
         --
      END IF;
      --
   END LOOP;
   --
   /* Si la causa del Siniestro es NO TRAMITABLE, dare un mensaje de error
     para no continuar con la apertura de expedientes. */
   --
   IF NVL(l_mca_tramitable, 'N') = 'N'
   THEN
      --
      /* CAUSA DEL SINIESTRO NO TRAMITABLE. NO PUEDE APERTURAR EXPEDIENTES. */
      --
      g_cod_mensaje := 20345;
      g_anx_mensaje := NULL;
      --
      pp_devuelve_error;
      --
   END IF;
   --
END p_devuelve;
--
--
/* --------------------------------------------------------------
|| Carga en memoria las globales que va a necesitar la rutina de
|| apertura de expedientes AS700030.
*/ --------------------------------------------------------------
--
PROCEDURE p_carga_globales_apertura
IS
  --
  l_num_poliza             a7000900.num_poliza       %TYPE;
  l_num_spto               a7000900.num_spto         %TYPE;
  l_max_spto_40            a7000900.num_spto         %TYPE;
  l_num_apli               a7000900.num_apli         %TYPE;
  l_num_spto_apli          a7000900.num_spto_apli    %TYPE;
  l_max_spto_apli_40       a7000900.num_spto_apli    %TYPE;
  l_num_spto_apli_riesgo   a7000900.num_spto_apli    %TYPE;
  l_num_riesgo             a7000900.num_riesgo       %TYPE;
  l_num_spto_riesgo        a7000900.num_spto_riesgo  %TYPE;
  l_num_periodo            a7000900.num_periodo      %TYPE;
  l_fec_sini               a7000900.fec_sini         %TYPE;
  --
  l_temporal               VARCHAR2(1) := 'S';
  --
  PROCEDURE pi_obtener_nom_tramitador
  IS
    --
    li_cod_docum             v1001390.cod_docum            %TYPE;
    li_tip_docum             v1001390.tip_docum            %TYPE;
    li_tip_tramitador        a1001339.tip_tramitador       %TYPE;
    --
  BEGIN
    --
    dc_p_nom_ape_completo_1 (g_cod_cia,
                             g_cod_tramitador,
                             9,                 -- actividad, tramitadores.
                             g_nom_tramitador,
                             li_tip_docum,
                             li_cod_docum);
    --
  END pi_obtener_nom_tramitador;
  --
  --
BEGIN
  --
  /* El ts_k_a7000900.p_lee_a7000900 esta hecho en el p_devuelve. */
  --
  l_num_poliza     := ts_k_a7000900.f_num_poliza;
  l_num_spto       := ts_k_a7000900.f_num_spto;
  l_num_apli       := ts_k_a7000900.f_num_apli;
  l_num_spto_apli  := ts_k_a7000900.f_num_spto_apli;
  l_num_riesgo     := ts_k_a7000900.f_num_riesgo;
  l_num_spto_riesgo:= ts_k_a7000900.f_num_spto_riesgo;
  l_num_periodo    := ts_k_a7000900.f_num_periodo;
  --
  IF l_num_apli = 0
  THEN
     --
     l_max_spto_40 := em_f_max_spto_a2000040 (g_cod_cia,
                                              l_num_poliza,
                                              l_num_riesgo,
                                              l_num_spto_riesgo,
                                              l_fec_sini,
                                              'S',
                                              g_cod_ramo );
     --
     l_max_spto_apli_40 := l_num_spto_apli;
     --
  ELSE
     --
     l_max_spto_40 := l_num_spto;
     --
     /*
     l_num_spto_apli_riesgo := em_f_max_spto_apli_a31(g_cod_cia,
                                                      l_num_poliza,
                                                      l_num_apli,
                                                      l_num_riesgo,
                                                      l_fec_sini,
                                                      l_temporal    );
     */
     --
     l_max_spto_apli_40 := em_f_max_spto_apli_a40 (g_cod_cia,
                                                   l_num_poliza,
                                                   l_num_spto,
                                                   l_num_apli,
                                                   l_num_spto_riesgo,
                                                   g_cod_ramo );
     --
  END IF;
  --
  IF NVL(g_tip_mvto_batch_stro,'0') ='0'
  THEN
     --
     pi_obtener_nom_tramitador;
     --
  END IF;
  --
  trn_k_global.asigna ('cod_causa',        TO_CHAR(g_cod_causa));
  --
  trn_k_global.asigna ('num_poliza',       l_num_poliza);
  trn_k_global.asigna ('num_spto',         TO_CHAR(l_num_spto));
  trn_k_global.asigna ('max_spto_40',      TO_CHAR(l_max_spto_40));
  trn_k_global.asigna ('num_apli',         TO_CHAR(l_num_apli));
  trn_k_global.asigna ('num_spto_apli',    TO_CHAR(l_num_spto_apli));
  trn_k_global.asigna ('max_spto_apli_40', TO_CHAR(l_max_spto_apli_40));
  trn_k_global.asigna ('num_riesgo',       TO_CHAR(l_num_riesgo));
  trn_k_global.asigna ('num_periodo',      TO_CHAR(l_num_periodo));
  --
  trn_k_global.asigna ('nom_tramitador',   g_nom_tramitador);
  --
END p_carga_globales_apertura;
--
--
/*----------------------------------------------------------------
|| Procedimiento : p_terminar_apertura_exp
*/----------------------------------------------------------------
--
PROCEDURE p_terminar_apertura_exp (p_llamado_desde_otro_programa IN  VARCHAR2)
IS
  --
  l_tip_exp                   a7001000.tip_exp        %TYPE := NULL;
  l_mca_term_automatica       a7000900.tip_est_sini   %TYPE :='S';
  --
  l_cod_error_ct         a2000220.cod_error            %TYPE;
  --
BEGIN
  --
  /* Compruebo que si he abierto expedientes se hayan abierto los obliga-
    torios */
  --
  -- Junio 2003.
  -- En la G7000001, se añade una marca y un procedimiento para indicar
  -- mediante la global mca_aper_sin_obliga, si se apertura el siniestro
  -- sin estar aperturados los expedientes obligatorios.
  -- Aunque no hay ninguno aperturado, también se hace la validación.
  --
  --
  --IF NVL(ts_k_a7001000.f_cuenta_exp (g_cod_cia,
  --                                   g_num_sini,
  --                                   l_tip_exp),0) != 0
  --THEN
      --
      ts_k_as700030.p_comprueba_aper_exp;
      --
  --END IF;
  --
  /* Si no hay ningun expediente pendiente y hay alguno abierto termina
    el siniestro.
    Julio-2004. Si soy la rehabilitación, primero hay que rehabilitar y
    luego terminar */
  --
  IF ts_k_a7000900.f_est_exptes_del_stro(g_cod_cia,
                                                 g_num_sini) = 'T'
     AND NVL(ts_k_a7001000.f_cuenta_exp (g_cod_cia,
                                         g_num_sini,
                                         l_tip_exp),0) != 0
     AND NVL(g_tip_mvto_batch_stro,'0')!= '14'
  THEN
      --
      ts_k_terminar_siniestro.p_terminar_siniestro
                              (g_cod_cia,
                               g_num_sini,
                               g_cod_supervisor,
                               g_cod_tramitador,
                               g_fec_proceso,
                               g_cod_usr,
                               l_mca_term_automatica);
  END IF;
  --
  /* Si el programa no ha sido llamado, desbloqueo el siniestro. SI ha sido
    llamado lo desbloqueara el programa que lo ha llamado.
     Este procedimiento, hace COMMIT. */
  --
  IF g_num_sini IS NOT NULL AND
     p_llamado_desde_otro_programa = 'N'
  THEN
     BEGIN
       --
       ts_k_a7000900.p_actualiza_exclusivo (g_cod_cia, g_num_sini, 'N');
       --
     EXCEPTION
     /* Controla que si no existe el siniestro, no de error. */
     WHEN OTHERS
     THEN
          NULL;
     END;
     --
  END IF;
  --
  /* 01-10-2005.
    Como al abandonar la apertura se borran todas las globales, antes de
    ejecutarlo, guardo la global cod_error_ct que la necesitara el proceso
    batch.*/
  --
  l_cod_error_ct := trn_k_global.ref_f_global ('cod_error_ct');
  --
  /* 01-10-2005. */
  --
  IF p_llamado_desde_otro_programa = 'N'
  THEN
    --
    /* Si es el movimiento 20 soy llamado desde la apertura ON-LINE
       y no tengo que borrar las globales principales. Si es el 14
       rehabilitación, tiene que borrar el AP700115  */
    --
    IF NVL(g_tip_mvto_batch_stro,'0') != '20'
    THEN
       trn_k_global.borra_todas;
    END IF;
    --
  ELSE
    --
    /* OJOOOOO CUIDADO MIRAR BIEN SI DEBO DECIR QUE NO ES LLAMADO */
    --
    IF NVL(g_tip_mvto_batch_stro,'0') != '20'
    THEN
       pp_borra_globales; -- borrar las globales creadas por este programa.
    END IF;
    --
  END IF;
  --
  pp_inicializa_variables;
  --
  ts_k_as700030.p_borra_variables;
  --
  /* 01-10-2005.
    Antes de abandonar el programa, asigno la global para que el proceso
   batch la pueda tratar.*/
  --
  trn_k_global.asigna ('cod_error_ct', l_cod_error_ct);
  --
  /* 01-10-2005. */
  --
END p_terminar_apertura_exp;
--
/*----------------------------------------------------------------
||
*/----------------------------------------------------------------
--
PROCEDURE p_abandonar_apertura_exp (p_llamado_desde_otro_programa IN  VARCHAR2)
IS
BEGIN
  --
  /* Si el programa no ha sido llamado, desbloqueo el siniestro. SI ha sido
    llamado lo desbloqueara el programa que lo ha llamado.
     Este procedimiento, hace COMMIT. */
  --
  IF g_num_sini IS NOT NULL AND
     p_llamado_desde_otro_programa = 'N'
  THEN
     BEGIN
       --
       ts_k_a7000900.p_actualiza_exclusivo (g_cod_cia, g_num_sini, 'N');
       --
     EXCEPTION
     /* Controla que si no existe el siniestro, no de error. */
     WHEN OTHERS
     THEN
          NULL;
     END;
     --
  END IF;
  --
  --
  IF p_llamado_desde_otro_programa = 'N'
  THEN
    --
    pp_inicializa_variables;
    --
    trn_k_global.borra_todas;
    --
    ts_k_as700030.p_borra_variables;
    --
  ELSE
    --
    pp_inicializa_variables;
    --
    pp_borra_globales; -- borrar todas las globales creadas por este programa.
    --
    ts_k_as700030.p_borra_variables;
    --
  END IF;
  --
END p_abandonar_apertura_exp;
--
PROCEDURE p_batch
IS
  l_cod_evento           a7000900.cod_evento       %TYPE ;
  l_nom_evento           a7990700.nom_evento       %TYPE ;
  l_cod_causa            a7000900.cod_causa_sini   %TYPE ;
  l_nom_causa            g7000200.nom_causa        %TYPE ;
  l_cod_consecuencia_1   a7000930.cod_consecuencia %TYPE ;
  l_cod_consecuencia_2   a7000930.cod_consecuencia %TYPE ;
  l_cod_consecuencia_3   a7000930.cod_consecuencia %TYPE ;
  l_cod_consecuencia_4   a7000930.cod_consecuencia %TYPE ;
  l_cod_consecuencia_5   a7000930.cod_consecuencia %TYPE ;
  --
  l_num_exp_antes_aper   NUMBER := 0;
  l_num_exp_despues_aper NUMBER := 0;
  l_tip_exp              a7001000.tip_exp          %TYPE;
  --
BEGIN
    --
    p_carga_globales_validacion;
    --
    -- Solo para el batch el usuario que ejecuta puede no ser
    -- tramitador.
    --
    trn_k_global.asigna ('admite_cualquier_tramitador', 'S');
    --
    ts_k_cabsini.p_inicio_batch;
    --
    trn_k_global.asigna ('cod_pgm_sini', 'AP700117');
    --
    p_inicio;
    --
    p_devuelve
         (l_cod_evento           ,
          l_nom_evento           ,
          l_cod_causa            ,
          l_nom_causa            ,
          l_cod_consecuencia_1   ,
          l_cod_consecuencia_2   ,
          l_cod_consecuencia_3   ,
          l_cod_consecuencia_4   ,
          l_cod_consecuencia_5  );
    --
    p_carga_globales_apertura;
    --
    /* Cuento los expedientes que hay abiertos para el siniestro antes
       de intentar aperturar los expedientes */
    --
    l_num_exp_antes_aper := NVL(ts_k_a7001000.f_cuenta_exp (g_cod_cia,
                                                            g_num_sini,
                                                            l_tip_exp),0);
    --
    ts_k_as700030.p_batch;
    --
    /* Cuento los expedientes que hay abiertos para el siniestro .
       Comparo con lo que habia antes de intentar aperturar expedientes */
    --
    l_num_exp_despues_aper := NVL(ts_k_a7001000.f_cuenta_exp (g_cod_cia,
                                                              g_num_sini,
                                                              l_tip_exp),0);
    --
    IF trn_k_global.devuelve('tip_mvto_batch_stro') IN ('10','20')
    THEN
       p_terminar_apertura_exp ('N');
    ELSE
       p_terminar_apertura_exp ('S');
    END IF;
    --
    IF l_num_exp_antes_aper = l_num_exp_despues_aper
    THEN
      --
       pp_asigna('DEFINICION','N');
       --
       g_cod_idioma := trn_k_global.cod_idioma;
       --
       g_cod_mensaje:= 70001145;
       g_anx_mensaje:= '  ts_k_ap700117';
       pp_devuelve_error;
    END IF;
    --
EXCEPTION
WHEN OTHERS
THEN
  g_txt_error   := SQLERRM;
  g_cod_mensaje := SQLCODE;
  --
  /* Si hay definicion de expedientes lo que ha fallado
     es la apertura de un expediente, hay que deshacerlo */
  --
  IF NVL(trn_k_global.ref_f_global('DEFINICION'),'N') = 'S'
  THEN
     ts_k_as700030.p_deshacer_expediente;
  END IF;
  --
  pp_error_despues_de_tratarlo ;
  --
END p_batch;
--
PROCEDURE p_batch_recobro_aut
IS
  l_cod_evento           a7000900.cod_evento       %TYPE ;
  l_nom_evento           a7990700.nom_evento       %TYPE ;
  l_cod_causa            a7000900.cod_causa_sini   %TYPE ;
  l_nom_causa            g7000200.nom_causa        %TYPE ;
  l_cod_consecuencia_1   a7000930.cod_consecuencia %TYPE ;
  l_cod_consecuencia_2   a7000930.cod_consecuencia %TYPE ;
  l_cod_consecuencia_3   a7000930.cod_consecuencia %TYPE ;
  l_cod_consecuencia_4   a7000930.cod_consecuencia %TYPE ;
  l_cod_consecuencia_5   a7000930.cod_consecuencia %TYPE ;
  --
BEGIN
    --
    p_carga_globales_validacion;
    --
    -- Solo para el batch el usuario que ejecuta puede no ser
    -- tramitador.
    --
    trn_k_global.asigna ('admite_cualquier_tramitador', 'S');
    --
    ts_k_cabsini.p_inicio_batch;
    --
    trn_k_global.asigna ('cod_pgm_sini', 'AP700117');
    --
    p_inicio;
    --
    p_devuelve
         (l_cod_evento           ,
          l_nom_evento           ,
          l_cod_causa            ,
          l_nom_causa            ,
          l_cod_consecuencia_1   ,
          l_cod_consecuencia_2   ,
          l_cod_consecuencia_3   ,
          l_cod_consecuencia_4   ,
          l_cod_consecuencia_5  );
    --
    p_carga_globales_apertura;
    --
    ts_k_as700030.p_batch_recobro;
    --
EXCEPTION
WHEN OTHERS
THEN
  --
  g_txt_error   := SQLERRM;
  g_cod_mensaje := SQLCODE;
  --
  pp_error_despues_de_tratarlo ;
  --
END p_batch_recobro_aut;
--
END ts_k_ap700117_trn;


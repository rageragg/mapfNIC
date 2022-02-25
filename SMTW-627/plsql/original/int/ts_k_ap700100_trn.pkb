create or replace PACKAGE BODY ts_k_ap700100_trn
AS
   --
   /* ------------------- VERSION = 1.90  ---------------*/
   --
   /* -------------------- DESCRIPCION --------------------
   || Package en el cual se van a incluir todos los procesos necesarios
   || para el programa de apertura del siniestro.
   || Tambien se incluye el proceso batch.
   */ -----------------------------------------------------
   --
   /* -------------------- MODIFICACIONES --------------------------------------
   || 2020/04/23 - MARIANJ - 1.91 - (MU-2020-028860)
   || Se modifica para que el control tecnico de nivel 4 no permita auditoria.
   */ --------------------------------------------------------------------------
   --
   /*
   ||               Globales al package.
   */
   --
   -- Tablas de Siniestro
   --
   g_cod_cia              a7000900.cod_cia           %TYPE;
   g_cod_sector           a7000900.cod_sector        %TYPE;
   g_cod_ramo             a7000900.cod_ramo          %TYPE;
   g_num_poliza           a7000900.num_poliza        %TYPE;
   g_num_spto             a7000900.num_spto          %TYPE;
   g_num_riesgo           a7000900.num_riesgo        %TYPE;
   g_num_periodo          a7000900.num_periodo       %TYPE;
   g_num_spto_riesgo      a7000900.num_spto_riesgo   %TYPE;
   g_max_spto_40          a7000900.num_spto_riesgo   %TYPE;
   g_max_spto_apli_40     a7000900.num_spto_riesgo   %TYPE;
   g_num_apli             a7000900.num_apli          %TYPE;
   g_num_spto_apli        a7000900.num_spto_apli     %TYPE;
   g_num_spto_apli_riesgo a7000900.num_spto_apli     %TYPE;
   g_cod_modalidad        a7000900.cod_modalidad     %TYPE;
   g_num_sini             a7000900.num_sini          %TYPE;
   g_fec_proc_sini        a7000900.fec_proc_sini     %TYPE;
   g_fec_proceso          a7000900.fec_proc_sini     %TYPE;
   g_fec_sini             a7000900.fec_sini          %TYPE;
   g_fec_denu_sini        a7000900.fec_denu_sini     %TYPE;
   g_hora_sini            a7000900.hora_sini         %TYPE;
   g_hora_denu_sini       a7000900.hora_denu_sini    %TYPE;
   g_mca_provisional      a7000900.mca_provisional   %TYPE;
   g_tip_coaseguro        a7000900.tip_coaseguro     %TYPE;
   g_tip_docum_tomador    a7000900.tip_docum_tomador %TYPE;
   g_cod_docum_tomador    a7000900.cod_docum_tomador %TYPE;
   g_tip_docum_aseg       a7000900.tip_docum_aseg    %TYPE;
   g_cod_docum_aseg       a7000900.cod_docum_aseg    %TYPE;
   g_cod_agt              a7000900.cod_agt           %TYPE;
   g_cod_nivel1           a7000900.cod_nivel1        %TYPE;
   g_cod_nivel2           a7000900.cod_nivel2        %TYPE;
   g_cod_nivel3           a7000900.cod_nivel3        %TYPE;
   g_cod_nivel3_captura   a7000900.cod_nivel3_captura%TYPE;
   g_cod_mon              a7000900.cod_mon           %TYPE;
   g_cod_causa            a7000900.cod_causa_sini    %TYPE;
   g_num_poliza_grupo     a7000900.num_poliza_grupo  %TYPE;
   g_tip_docum_contacto   a7000900.tip_docum_contacto%TYPE;
   g_cod_docum_contacto   a7000900.cod_docum_contacto%TYPE;
   g_email_contacto       a7000900.email_contacto    %TYPE;
   g_tip_relacion         a7000900.tip_relacion      %TYPE;
   g_ape_contacto         a7000900.ape_contacto      %TYPE;
   g_nom_contacto         a7000900.nom_contacto      %TYPE;
   g_tel_pais_contacto    a7000900.tel_pais_contacto %TYPE;
   g_tel_zona_contacto    a7000900.tel_zona_contacto %TYPE;
   g_tel_numero_contacto  a7000900.tel_numero_contacto%TYPE;
   g_cod_supervisor       a7000900.cod_supervisor    %TYPE;
   g_retenido_sini        a7000900.mca_provisional   %TYPE;
   g_cod_evento           a7000900.cod_evento        %TYPE;
   g_num_sini_ref         a7000900.num_sini_ref      %TYPE;
   g_tip_apertura         a7000900.tip_apertura      %TYPE := 'M';
   g_tip_causa            g7000200.tip_causa         %TYPE;
   g_imp_val_ini_sini     a7000900.imp_val_ini_sini  %TYPE;
   g_fec_spto_anul        a2000030.fec_spto_anulado  %TYPE;
   --
   g_cod_tramitador  a7001000.cod_tramitador         %TYPE;
   g_tip_tramitador  a1001339.tip_tramitador         %TYPE;
   g_mca_tramitable  g7000200.mca_tramitable         %TYPE;
   g_mca_aper_aut    g7000001.mca_aper_aut           %TYPE;
   g_mca_aut_on_line g7000001.mca_aut_on_line        %TYPE;
   --
   -- Otras tablas
   --
   g_cod_tratamiento      a1001800.cod_tratamiento   %TYPE;
   g_nom_ramo             a1001800.nom_ramo          %TYPE;
   g_cod_tip_vehi         a2100701.cod_tip_vehi      %TYPE;
   g_tip_poliza_tr        a2000030.tip_poliza_tr     %TYPE;
   g_mca_datos_minimos    a2000030.mca_datos_minimos %TYPE;
   g_mca_provisional_pol  a2000030.mca_provisional   %TYPE;
   g_mca_exclusivo        a2000030.mca_exclusivo     %TYPE;
   g_mca_exclusivo_riesgo a2000030.mca_exclusivo     %TYPE;
   g_fec_efec_poliza      a2000030.fec_efec_poliza   %TYPE;
   g_fec_vcto_poliza      a2000030.fec_vcto_poliza   %TYPE;
   g_fec_efec_spto        a2000030.fec_efec_spto     %TYPE;
   g_fec_efec_riesgo      a2000031.fec_efec_riesgo   %TYPE;
   g_fec_vcto_riesgo      a2000031.fec_vcto_riesgo   %TYPE;
   g_tip_situacion        a5020500.tip_situacion     %TYPE;
   g_nom_riesgo           a2000031.nom_riesgo        %TYPE;
   g_fec_validez          a2100701.fec_validez       %TYPE;
   --
   g_num_orden            b7000900.num_orden         %TYPE;
   --
   g_cod_idioma  g1010010.cod_idioma       %TYPE := trn_k_global.cod_idioma;
   g_cod_mensaje g1010020.cod_mensaje      %TYPE;
   g_cod_usr     g1002700.cod_usr          %TYPE;
   g_anx_mensaje VARCHAR2(250);
   g_txt_error   VARCHAR2(2000);
   --
   g_cod_sistema       a2000220.cod_sistema     %TYPE := '7';
   g_cod_nivel_salto_1 a2000220.cod_nivel_salto %TYPE := '1';
   g_cod_nivel_salto_2 a2000220.cod_nivel_salto %TYPE := '2';
   --
   -- el salto de nivel 3 es s¢lo para actualizaci¢n,  ya que la ejecucion
   -- de los errores de CT la lleva a cabo la rutina de consecuencias
   --
   g_cod_nivel_salto_3 a2000220.cod_nivel_salto  %TYPE := '3';
   -- 1.82
   g_cod_nivel_salto_4 a2000220.cod_nivel_salto  %TYPE := '4';
   --
   g_cod_pgm                   g9990003.cod_pgm  %TYPE := 'AP700100';
   g_mca_puede_haber_auditoria    VARCHAR2(1)          := 'S';
   g_mca_no_puede_haber_auditoria VARCHAR2(1)          := 'N';
   --
   g_tip_poliza_stro a7000900.tip_poliza_stro%TYPE;
   --
   g_mca_hay_ctrl_tecnico VARCHAR2(1);
   --
   g_cod_tip_spto_rf           A2991800.tip_spto %TYPE := 'RF';
   --
   /*---------------------------------------------------------------------
   || Cursor para leer toda la informacion del siniestro de la tabla
   || B7000900 para el proceso Batch
   ||
   */ ----------------------------------------------------------------------
   CURSOR c_b7000900(pc_num_sini_ref        b7000900.num_sini_ref        %TYPE,
                     pc_fec_tratamiento     b7000900.fec_tratamiento     %TYPE,
                     pc_tip_mvto_batch_stro b7000900.tip_mvto_batch_stro %TYPE,
                     pc_num_orden           b7000900.num_orden           %TYPE,
                     pc_cod_cia             b7000900.cod_cia             %TYPE) IS
      SELECT *
        FROM b7000900
       WHERE num_sini_ref        = pc_num_sini_ref
         AND fec_tratamiento     = pc_fec_tratamiento
         AND tip_mvto_batch_stro = pc_tip_mvto_batch_stro
         AND num_orden           = pc_num_orden
         AND cod_cia             = pc_cod_cia;
   --
   g_reg b7000900%ROWTYPE;
   --
   /* Variables utilizadas en el query de las coberturas */
   --
   /* Tabla PL*/
   TYPE reg_a2000040 IS RECORD(
      num_secu_k          PLS_INTEGER,
      post_query          BOOLEAN,
      cod_cob             a2000040.cod_cob              %TYPE,
      nom_cob             a1002150.nom_cob              %TYPE,
      cod_mon_capital     a2000040.cod_mon_capital      %TYPE,
      cod_cob_relacionada a1002150.cod_cob              %TYPE,
      nom_cob_relacionada a1002150.nom_cob              %TYPE,
      suma_aseg           a2000040.suma_aseg            %TYPE,
      cod_franquicia      a2000040.cod_franquicia       %TYPE,
      val_franquicia      a2100700.val_franquicia       %TYPE,
      tip_franquicia      g1010031.nom_valor            %TYPE,
      tip_franquicia_stro g1010031.nom_valor            %TYPE,
      val_franquicia_min  a2000040.val_franquicia_min   %TYPE,
      tip_franquicia_min  g1010031.nom_valor            %TYPE,
      val_franquicia_max  a2000040.val_franquicia_max   %TYPE,
      tip_franquicia_max  g1010031.nom_valor            %TYPE,
      deducible           a2000040.mca_baja_cob         %TYPE);
   --
   greg_a2000040      reg_a2000040;
   --
   TYPE tabla_a2000040 IS TABLE OF greg_a2000040%TYPE INDEX BY BINARY_INTEGER;
   --
   g_tb_a2000040 tabla_a2000040;
   --
   g_fila           BINARY_INTEGER;
   g_fila_devuelve  BINARY_INTEGER;
   g_max_secu_query BINARY_INTEGER;
   --
   --
   g_cnt_pk PLS_INTEGER;
   --
   g_k_si    CONSTANT  VARCHAR2(1) := trn.SI  ;
   g_k_nulo  CONSTANT  VARCHAR2(4) := trn.NULO;
   g_k_cero  CONSTANT  NUMBER(1)   := trn.CERO;
   g_k_no    CONSTANT  VARCHAR2(1) := trn.NO  ;
   g_k_uno   CONSTANT  NUMBER(1)   := trn.UNO ;
   --
   g_k_nueva_emision   CONSTANT VARCHAR2(2) := em.NUEVA_EMISION;
   --
   g_k_tip_pol_trans_fija  CONSTANT VARCHAR2(1) := em.TIP_POL_TRANS_FIJA;
   --
   /* --------------------------------------------------------------
   ||               Procedimientos Internos
   */ ---------------------------------------------------------------
   --
   /* ----------------------------------------------------
   || Devuelve el error
   */ ----------------------------------------------------
   --
   PROCEDURE pp_devuelve_error IS
   BEGIN
      --
      IF g_cod_mensaje BETWEEN 20000 AND 20999
      THEN
         --
         raise_application_error(-g_cod_mensaje,
                                 ss_k_mensaje.f_texto_idioma(g_cod_mensaje,
                                                             g_cod_idioma) ||
                                 g_anx_mensaje);
         --
      ELSE
         --
         raise_application_error(-20000,
                                 ss_k_mensaje.f_texto_idioma(g_cod_mensaje,
                                                             g_cod_idioma) ||
                                 g_anx_mensaje);
         --
      END IF;
      --
   END pp_devuelve_error;
   --
   /* ----------------------------------------------------------------
   || fp_calcula_num_spto: Valida la hora asociada a el suplemento
   */ ----------------------------------------------------------------
   --
   FUNCTION fp_calcula_num_spto(p_cod_cia       IN a2000030.cod_cia      %TYPE,
                                p_num_poliza    IN a2000030.num_poliza   %TYPE,
                                p_fec_sini      IN a2000030.fec_efec_spto%TYPE,
                                p_temporal      IN a7000900.tip_est_sini %TYPE,
                                p_hora_sini     IN a7000900.hora_sini    %TYPE)
      RETURN a2000030.num_spto%TYPE
      --
   IS
   --
      CURSOR lc_a2000030(pc_cod_cia       a2000030.cod_cia      %TYPE,
                         pc_num_poliza    a2000030.num_poliza   %TYPE,
                         pc_fec_sini      a2000030.fec_efec_spto%TYPE,
                         pc_temporal      a7000900.tip_est_sini %TYPE)
      IS
         SELECT num_spto     ,
                hora_desde   ,
                fec_efec_spto,
                fec_vcto_spto,
                fec_vcto_spto_publico
           FROM a2000030
          WHERE cod_cia                       = pc_cod_cia
            AND num_poliza                    = pc_num_poliza
            AND num_apli                      = 0
            --AND hora_desde                   IS NOT NULL
            AND pc_fec_sini             BETWEEN fec_efec_spto
                                            AND fec_vcto_spto -- (MU-2016-005661)
            AND NVL(mca_spto_tmp,'N')         = DECODE(pc_temporal, 'S', mca_spto_tmp, 'N')
            AND (   NVL(mca_spto_anulado,'N') = 'N'
                 OR (     mca_spto_anulado    = 'S'
                      AND mca_provisional     = 'S'))
          ORDER BY num_spto DESC;
      --
      l_contador NUMBER;
      l_fec_vcto a2000030.fec_vcto_spto%TYPE;
      --
      l_hora_desde      a2000030.hora_desde %TYPE;
     --
   BEGIN
      --
      l_contador := g_k_cero;
      --
      FOR lreg_a2000030 IN lc_a2000030(pc_cod_cia    =>  p_cod_cia   ,
                                       pc_num_poliza =>  p_num_poliza,
                                       pc_fec_sini   =>  p_fec_sini  ,
                                       pc_temporal   =>  p_temporal  )
      LOOP
         --
         IF dc_k_a1001800.f_mca_registra_hora = g_k_no THEN
           --
           l_hora_desde := '00:00';
           --
         ELSE
           --
           l_hora_desde := nvl(lreg_a2000030.hora_desde, '00:00');
           --
         END IF;
         --
         l_contador := l_contador + g_k_uno;
         l_fec_vcto := em_k_cons_datos_fijos.f_fec_vcto_spto_publico(p_hora_desde            => l_hora_desde,
                                                                     p_fec_vcto_spto         => lreg_a2000030.fec_vcto_spto,
                                                                     p_fec_vcto_spto_publico => lreg_a2000030.fec_vcto_spto_publico);
         --
         IF (p_fec_sini   > lreg_a2000030.fec_efec_spto
            OR (    p_fec_sini   = lreg_a2000030.fec_efec_spto
                    AND nvl(p_hora_sini, '23:59') >= l_hora_desde))
            AND
            (p_fec_sini   < TRUNC(l_fec_vcto)
                  OR (p_fec_sini   = TRUNC(l_fec_vcto)
                     AND lreg_a2000030.fec_vcto_spto_publico IS NULL)
                  OR (p_fec_sini   = TRUNC(l_fec_vcto)
                      AND nvl(p_hora_sini, '00:00') <= TO_CHAR(l_fec_vcto, 'hh24:mi')))
         THEN
            --
            RETURN lreg_a2000030.num_spto;
            --
         END IF;
         --
      END LOOP;
      --
      IF l_contador = g_k_cero
      THEN
         --
         RETURN g_k_nulo;
         --
      ELSE
         -- LA POLIZA NO ESTA VIGENTE A LA FECHA
         g_cod_mensaje  := 70001214;
         --
         g_anx_mensaje  := 'em_p_a2000030_1';
         --
         pp_devuelve_error;
         --
      END IF;
      --
   END fp_calcula_num_spto;
   --
   /* ------------------------------------------------------------------------------
   || fp_calcula_num_spto_apli: Valida la hora asociada al suplemento de aplicacion
   */ ------------------------------------------------------------------------------
   --
   FUNCTION fp_calcula_num_spto_apli(p_cod_cia     IN a2000030.cod_cia      %TYPE,
                                     p_num_poliza  IN a2000030.num_poliza   %TYPE,
                                     p_fec_sini    IN a2000030.fec_efec_spto%TYPE,
                                     p_temporal    IN a7000900.tip_est_sini %TYPE,
                                     p_hora_sini   IN a7000900.hora_sini    %TYPE,
                                     p_num_apli    IN a2000030.num_apli     %TYPE)
      RETURN a2000030.num_spto_apli%TYPE
   IS
   --
      CURSOR lc_a2000030_spto(pc_cod_cia    a2000030.cod_cia   %TYPE,
                              pc_num_poliza a2000030.num_poliza%TYPE,
                              pc_num_apli   a2000030.num_apli  %TYPE)
      IS
         SELECT num_spto
           FROM a2000030
          WHERE cod_cia    = pc_cod_cia
            AND num_poliza = pc_num_poliza
            AND num_apli   = pc_num_apli;
      --
      CURSOR lc_a2000030(pc_cod_cia       a2000030.cod_cia      %TYPE,
                         pc_num_poliza    a2000030.num_poliza   %TYPE,
                         pc_fec_sini      a2000030.fec_efec_spto%TYPE,
                         pc_temporal      a7000900.tip_est_sini %TYPE,
                         pc_num_apli      a2000030.num_apli     %TYPE,
                         pc_num_spto      a2000030.num_spto     %TYPE)
      IS
         SELECT num_spto_apli,
                hora_desde   ,
                fec_efec_spto,
                fec_vcto_spto,
                fec_vcto_spto_publico
           FROM a2000030
          WHERE cod_cia                   = pc_cod_cia
            AND num_poliza                = pc_num_poliza
            AND num_apli                  = pc_num_apli
            --AND hora_desde               IS NOT NULL
            AND num_spto                  = pc_num_spto
            AND pc_fec_sini         BETWEEN fec_efec_spto
                                        AND fec_vcto_spto --(MU-2016-005661)
            AND NVL(mca_spto_tmp,    'N') = DECODE(pc_temporal, 'S', mca_spto_tmp, 'N')
            AND NVL(mca_spto_anulado,'N') = 'N'
          ORDER BY num_spto_apli DESC;
      --
      l_num_spto a2000030.num_spto%TYPE;
      --
      l_contador NUMBER;
      l_fec_vcto a2000030.fec_vcto_spto%TYPE;
      --
      l_hora_desde      a2000030.hora_desde %TYPE;
   --
   BEGIN
      --
      l_contador := g_k_cero;
      --
      OPEN lc_a2000030_spto(pc_cod_cia    => p_cod_cia   ,
                            pc_num_poliza => p_num_poliza,
                            pc_num_apli   => p_num_apli  );
      --
      FETCH lc_a2000030_spto INTO l_num_spto;
      --
      CLOSE lc_a2000030_spto;
      --
      FOR lreg_a2000030 IN lc_a2000030(pc_cod_cia     =>  p_cod_cia   ,
                                       pc_num_poliza  =>  p_num_poliza,
                                       pc_fec_sini    =>  p_fec_sini  ,
                                       pc_temporal    =>  p_temporal  ,
                                       pc_num_apli    =>  p_num_apli  ,
                                       pc_num_spto    =>  l_num_spto  )
      LOOP
         --
         l_contador := l_contador + g_k_uno;
         --
         IF dc_k_a1001800.f_mca_registra_hora = g_k_no THEN
           --
           l_hora_desde := '00:00';
           --
         ELSE
           --
           l_hora_desde := nvl(lreg_a2000030.hora_desde, '00:00');
           --
         END IF;
         --
         l_fec_vcto := em_k_cons_datos_fijos.f_fec_vcto_spto_publico(p_hora_desde            => l_hora_desde,
                                                                     p_fec_vcto_spto         => lreg_a2000030.fec_vcto_spto,
                                                                     p_fec_vcto_spto_publico => lreg_a2000030.fec_vcto_spto_publico);
         --
         IF    (p_fec_sini         > lreg_a2000030.fec_efec_spto
            OR (     p_fec_sini   = lreg_a2000030.fec_efec_spto
                AND nvl(p_hora_sini, '00:00') >= l_hora_desde))
            AND
            -- Validamos la nueva fecha de vencimiento p?blico
            (p_fec_sini   < TRUNC(l_fec_vcto)
                  OR (p_fec_sini   = TRUNC(l_fec_vcto)
                     AND lreg_a2000030.fec_vcto_spto_publico IS NULL)
                  OR (p_fec_sini   = TRUNC(l_fec_vcto)
                      AND nvl(p_hora_sini, '00:00') <= TO_CHAR(l_fec_vcto, 'hh24:mi')))
         THEN
            --
            RETURN lreg_a2000030.num_spto_apli;
            --
         END IF;
         --
      END LOOP;
      --
      IF l_contador = g_k_cero
      THEN
         --
         RETURN g_k_nulo;
         --
      ELSE
         -- NO EXISTE LA APLICAC. PARA LA POLIZA O NO ESTA VIGENTE A
         g_cod_mensaje  := 70001192;
         --
         g_anx_mensaje  := TO_CHAR(p_fec_sini, 'DD/MM/YYYY');
         --
         pp_devuelve_error;
         --
      END IF;
      --
   END fp_calcula_num_spto_apli;
   --
   /* -------------------------------------------------------------------------
   || fp_valida_fecha_hora: Determina si el suplemento/aplicación de la poliza
   || tiene la misma fecha de notificacion del siniestro y verifica la hora_desde
   || con la hora del siniestro para indicar si el spto/apli está vigente o no.
   */ -------------------------------------------------------------------------
   --
   FUNCTION fp_valida_fecha_hora(p_cod_cia       IN a2000030.cod_cia      %TYPE,
                                 p_num_poliza    IN a2000030.num_poliza   %TYPE,
                                 p_num_spto      IN a2000030.num_spto     %TYPE,
                                 p_num_apli      IN a2000030.num_apli     %TYPE,
                                 p_num_spto_apli IN a2000030.num_spto_apli%TYPE,
                                 p_fec_sini      IN a2000030.fec_efec_spto%TYPE,
                                 p_hora_sini     IN a2000030.hora_desde   %TYPE)
      RETURN BOOLEAN
   IS
   --
      CURSOR lc_a2000030(pc_cod_cia       IN a2000030.cod_cia      %TYPE,
                         pc_num_poliza    IN a2000030.num_poliza   %TYPE,
                         pc_num_spto      IN a2000030.num_spto     %TYPE,
                         pc_num_apli      IN a2000030.num_apli     %TYPE,
                         pc_num_spto_apli IN a2000030.num_spto_apli%TYPE)
      IS
         SELECT fec_efec_spto,
                hora_desde,
                fec_vcto_spto,
                fec_vcto_spto_publico
           FROM a2000030
          WHERE cod_cia       = pc_cod_cia
            AND num_poliza    = pc_num_poliza
            AND num_spto      = pc_num_spto
            AND num_apli      = pc_num_apli
            AND num_spto_apli = pc_num_spto_apli;
      --
      l_hora_desde    a2000030.hora_desde   %TYPE;
      l_fec_efec_spto a2000030.fec_efec_spto%TYPE;
      l_fec_vcto_spto         a2000030.fec_vcto_spto%TYPE;
      l_fec_vcto_spto_publico a2000030.fec_vcto_spto_publico%TYPE;
      l_hora_desde_pub        a2000030.hora_desde   %TYPE;
   --
   BEGIN
      --
      OPEN lc_a2000030(pc_cod_cia       => p_cod_cia      ,
                       pc_num_poliza    => p_num_poliza   ,
                       pc_num_spto      => p_num_spto     ,
                       pc_num_apli      => p_num_apli     ,
                       pc_num_spto_apli => p_num_spto_apli);
      --
      FETCH lc_a2000030 INTO l_fec_efec_spto,
                             l_hora_desde   ,
                             l_fec_vcto_spto        ,
                             l_fec_vcto_spto_publico;
      --
      l_hora_desde_pub := TO_CHAR(em_k_cons_datos_fijos.f_fec_vcto_spto_publico(
                                            p_hora_desde            => l_hora_desde,
                                            p_fec_vcto_spto         => l_fec_vcto_spto,
                                            p_fec_vcto_spto_publico => l_fec_vcto_spto_publico), 'hh24:mi');
      --
      IF lc_a2000030%FOUND
      THEN
         --
         IF    p_fec_sini  < l_fec_efec_spto
            OR (    p_fec_sini  = l_fec_efec_spto
               AND nvl(p_hora_sini, '00:00') < nvl(l_hora_desde_pub, nvl(l_hora_desde, '00:00')))
         THEN
            --
            RETURN TRUE;
            --
         END IF;
         --
      END IF;
      --
      RETURN FALSE;
      --
   END fp_valida_fecha_hora;
   --
   /* ----------------------------------------------------
   || Devuelve la marca de provisional del siniestro
   */ ----------------------------------------------------
   --
   FUNCTION f_mca_provisional RETURN a7000900.mca_provisional%TYPE IS
   BEGIN
      --
      RETURN NVL(g_mca_provisional,   'N');
      --
   END f_mca_provisional;
  --
   /* ----------------------------------------------------
   || Valida sobre la tabla g1010031
   */ ----------------------------------------------------
   --
   FUNCTION fi_g1010031(p_cod_campo g1010031.cod_campo%TYPE,
                        p_cod_valor g1010031.cod_valor%TYPE)
      RETURN g1010031.nom_valor%TYPE IS
      --
      l_retorno g1010031.nom_valor%TYPE := NULL;
      --
   BEGIN
      --
      l_retorno := ss_f_nom_valor(p_cod_campo,
                                  999,
                                  p_cod_valor,
                                  g_cod_idioma);
      --
      RETURN l_retorno;
      --
   END fi_g1010031;
   --
   /* ----------------------------------------------------
   || Devuelve la descripcion del error
   */ ----------------------------------------------------
   --
   FUNCTION fi_txt_mensaje(p_cod_mensaje g1010020.cod_mensaje%TYPE)
      RETURN g1010020.txt_mensaje%TYPE IS
   BEGIN
      --
      RETURN ss_k_mensaje.f_texto_idioma(p_cod_mensaje,
                                         g_cod_idioma);
      --
    END fi_txt_mensaje;
   --
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
      trn_k_global.asigna(p_nom_global,
                          p_val_global);
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
                       p_val_global NUMBER) IS
   BEGIN
      --
      trn_k_global.asigna(p_nom_global, TO_CHAR(p_val_global));
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
                       p_val_global DATE) IS
   BEGIN
      --
      trn_k_global.asigna(p_nom_global,TO_CHAR(p_val_global,'ddmmyyyy'));
      --
   END pp_asigna;
   --
     /* --------------------------------------------------------
   || mx :
   ||
   || Genera la traza
   */ --------------------------------------------------------
   --
 /*  PROCEDURE mx(p_tit VARCHAR2,
                p_val VARCHAR2)
   IS
   BEGIN
      --
      pp_asigna (p_nom_global => 'fic_traza',
                 p_val_global => 'ap700100');
      pp_asigna (p_nom_global => 'cab_traza',
                 p_val_global => '->'      );
      --
      em_k_traza.p_escribe (p_titulo => p_tit,
                            p_valor  => p_val);
      --
   END mx;*/
   --
   --
   --
   /*PROCEDURE mx(p_tit VARCHAR2,
                p_val BOOLEAN) IS
   BEGIN
      --
      pp_asigna(p_nom_global => 'fic_traza',
                p_val_global => 'ap700100');
      --
      pp_asigna(p_nom_global => 'cab_traza',
                p_val_global => '->');
      --
      em_k_traza.p_escribe (p_titulo => p_tit,
                            p_valor  => p_val);
      --
   END mx;*/
   /* ----------------------------------------------------
   || pp_control_acceso_general: Control de acceso a datos
   */ ----------------------------------------------------
   PROCEDURE pp_control_acceso_general
   IS
   --
      l_tab_subag    dc_k_a1001337.table_cod_emp_agt;
      l_acceso       VARCHAR2(1);
   --
   BEGIN
      --
      --@mx('I', 'pp_control_acceso_general');
      --
      -- Generamos la tabla de sub_agentes
      l_tab_subag := em_k_a2000060.f_tab_subagentes(
                                        p_cod_cia      => g_cod_cia     ,
                                        p_num_poliza   => g_num_poliza  ,
                                        p_num_apli     => g_num_apli    ,
                                        p_fec_vigencia => TRUNC(SYSDATE));
      --
      -- Capturamos si se tiene acceso a los datos
      l_acceso := ss_k_acceso.f_permite( p_cod_cia        => g_cod_cia    ,
                                         p_cod_usr_cia    => g_cod_usr    ,
                                         p_cod_nivel3     => g_cod_nivel3 ,
                                         p_cod_agt        => g_cod_agt    ,
                                         p_tb_cod_emp_agt => l_tab_subag  ,
                                         p_cod_ramo       => g_cod_ramo   );
      --
      -- Verificamos si tenemos acceso a los datos
      IF l_acceso = trn.NO
      THEN
         --
         /* Usuario sin acceso a los datos */
         g_cod_mensaje  := 20018;
         g_anx_mensaje  := '-'||g_cod_usr||'-';
         --
         pp_devuelve_error;
         --
      END IF;
      --
      --@mx('F', 'pp_control_acceso_general');
      --
   END pp_control_acceso_general;
   --
   /* -------------------------------------------------------------------------------------
   || pp_control_acceso_general_gen: Control de acceso a datos  de siniestro generico
   ||                                Solo se tendra acceso si se tiene acceso total a los datos
   */ -------------------------------------------------------------------------------------
   PROCEDURE pp_control_acceso_general_gen
   IS
   --
      l_tab_subag    dc_k_a1001337.table_cod_emp_agt;
      l_acceso       VARCHAR2(1);
   --
   BEGIN
      --
      --@mx('I', 'pp_control_acceso_general_gen');
      --
      l_tab_subag(1) := TRN.COD_TERCERO_GEN;
      --
      -- Capturamos si se tiene acceso a los datos
      l_acceso := ss_k_acceso.f_permite( p_cod_cia        => g_cod_cia             ,
                                         p_cod_usr_cia    => g_cod_usr             ,
                                         p_cod_nivel3     => DC.COD_NIVEL3_GEN     ,
                                         p_cod_agt        => TRN.COD_TERCERO_GEN   ,
                                         p_tb_cod_emp_agt => l_tab_subag           ,
                                         p_cod_ramo       => EM.COD_RAMO_GEN       );
      --
      -- Verificamos si tenemos acceso a los datos
      IF l_acceso = trn.NO
      THEN
         --
         /* Usuario sin acceso a los datos */
         g_cod_mensaje  := 20018;
         g_anx_mensaje  := '-'||g_cod_usr||'-';
         --
         pp_devuelve_error;
         --
      END IF;
      --
      --@mx('F', 'pp_control_acceso_general_gen');
      --
   END pp_control_acceso_general_gen;
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
      IF g_cod_mensaje BETWEEN - 20999 AND - 20000
      THEN
         --
         raise_application_error(g_cod_mensaje,
                                 SUBSTR(g_txt_error,
                                        INSTR(g_txt_error,
                                              g_cod_mensaje,
                                              -1
                                             ) + 7
                                       )
                                );
         --
      ELSE
         --
         raise_application_error(-20000,
                                 g_txt_error);
         --
      END IF;
      --
   END pp_error_despues_de_tratarlo;
   --
   --
   /* ----------------------------------------------------
   || Inicializa las variables g
   */ ----------------------------------------------------
   --
   PROCEDURE pp_inicializa_variables IS
   BEGIN
      --
      --@mx('I','pp_inicializa_variables');
      --
      g_cod_cia              := NULL;
      g_cod_sector           := NULL;
      g_cod_ramo             := NULL;
      g_num_poliza           := NULL;
      g_num_spto             := NULL;
      g_num_riesgo           := NULL;
      g_num_periodo          := NULL;
      g_num_spto_riesgo      := NULL;
      g_max_spto_40          := NULL;
      g_max_spto_apli_40     := NULL;
      g_num_apli             := NULL;
      g_num_spto_apli        := NULL;
      g_num_spto_apli_riesgo := NULL;
      g_cod_modalidad        := NULL;
      g_num_sini             := NULL;
      g_fec_proc_sini        := NULL;
      g_fec_proceso          := NULL;
      g_fec_sini             := NULL;
      g_fec_denu_sini        := NULL;
      g_hora_sini            := NULL;
      g_hora_denu_sini       := NULL;
      g_tip_coaseguro        := NULL;
      g_tip_docum_tomador    := NULL;
      g_cod_docum_tomador    := NULL;
      g_tip_docum_aseg       := NULL;
      g_cod_docum_aseg       := NULL;
      g_cod_agt              := NULL;
      g_cod_nivel1           := NULL;
      g_cod_nivel2           := NULL;
      g_cod_nivel3           := NULL;
      g_cod_nivel3_captura   := NULL;
      g_cod_mon              := NULL;
      g_cod_causa            := NULL;
      g_mca_datos_minimos    := NULL;
      g_num_poliza_grupo     := NULL;
      g_ape_contacto         := NULL;
      g_nom_contacto         := NULL;
      g_tip_docum_contacto   := NULL;
      g_cod_docum_contacto   := NULL;
      g_email_contacto       := NULL;
      g_tip_relacion         := NULL;
      g_tel_pais_contacto    := NULL;
      g_tel_zona_contacto    := NULL;
      g_tel_numero_contacto  := NULL;
      g_cod_supervisor       := NULL;
      g_retenido_sini        := NULL;
      g_mca_provisional      := NULL;
      g_cod_evento           := NULL;
      g_tip_causa            := NULL;
      --
      g_cod_tramitador  := NULL;
      g_tip_tramitador  := NULL;
      g_mca_tramitable  := NULL;
      g_mca_aper_aut    := NULL;
      g_mca_aut_on_line := NULL;
      --
      -- Otras tablas
      --
      g_cod_tratamiento      := NULL;
      g_nom_ramo             := NULL;
      g_cod_tip_vehi         := NULL;
      g_tip_poliza_tr        := NULL;
      g_mca_provisional_pol  := NULL;
      g_mca_exclusivo        := NULL;
      g_mca_exclusivo_riesgo := NULL;
      g_fec_efec_poliza      := NULL;
      g_fec_vcto_poliza      := NULL;
      g_fec_efec_spto        := NULL;
      g_fec_efec_riesgo      := NULL;
      g_fec_vcto_riesgo      := NULL;
      g_tip_situacion        := NULL;
      g_nom_riesgo           := NULL;
      g_tip_apertura         := NULL;
      g_num_sini_ref         := NULL;
      g_num_orden            := NULL;
      --
      /* Inicializa tabla de consecuencias */
      ts_k_as700010.p_borra_tabla_memoria;
      --
      /* Inicializa tabla de expedientes */
      ts_k_as700030.p_borra_variables;
      --
      /* Borra tabla de coberturas de la poliza */
      g_tb_a2000040.DELETE;
      --
      --@mx('F','pp_inicializa_variables');
      --
   END pp_inicializa_variables;
   --
   /* ----------------------------------------------------
   || Asigna las globales necesarias para continuar con la apertura
   */ ----------------------------------------------------
   --
   PROCEDURE pp_inicializa_globales IS
   BEGIN
      --
      --@mx('I','pp_inicializa_globales');
      --
      trn_k_global.borra_todas;
      --
      --@mx('F','pp_inicializa_globales');
      --
   END pp_inicializa_globales;
   --
   /* ----------------------------------------------------
   || Asigna las globales necesarias para continuar con la apertura
   */ ----------------------------------------------------
   --
   PROCEDURE pp_asigna_globales IS
   BEGIN
      --
      --@mx('I','pp_asigna_globales');
      --
      trn_k_global.asigna('num_riesgo',      TO_CHAR(g_num_riesgo));
      trn_k_global.asigna('num_spto_riesgo', TO_CHAR(g_num_spto_riesgo));
      trn_k_global.asigna('nom_riesgo',      g_nom_riesgo);
      trn_k_global.asigna('max_spto_40',     TO_CHAR(g_max_spto_40));
      trn_k_global.asigna('max_spto_apli_40',TO_CHAR(g_max_spto_apli_40));
      trn_k_global.asigna('num_periodo',     TO_CHAR(g_num_periodo));
      trn_k_global.asigna('fec_efec_riesgo', TO_CHAR(g_fec_efec_riesgo,'DDMMYYYY'));
      trn_k_global.asigna('fec_vcto_riesgo', TO_CHAR(g_fec_vcto_riesgo,'DDMMYYYY'));
      trn_k_global.asigna('fec_denu_sini',   TO_CHAR(g_fec_denu_sini,  'DDMMYYYY'));
      trn_k_global.asigna('fec_sini',        TO_CHAR(g_fec_sini,  'DDMMYYYY'));
      trn_k_global.asigna('fec_proc_sini',   TO_CHAR(g_fec_proc_sini,  'DDMMYYYY'));
      trn_k_global.asigna('fec_proceso',     TO_CHAR(g_fec_proceso,    'DDMMYYYY'));
      trn_k_global.asigna('hora_sini',       g_hora_sini);
      trn_k_global.asigna('hora_denu_sini',  g_hora_denu_sini);
      trn_k_global.asigna('nom_ramo',        g_nom_ramo);
      trn_k_global.asigna('cod_tramitador',  g_cod_tramitador);
      trn_k_global.asigna('tip_tramitador',  g_tip_tramitador);
      trn_k_global.asigna('cod_supervisor',  g_cod_supervisor);
      trn_k_global.asigna('tip_situacion',   g_tip_situacion);
      --
      --@mx('F','pp_asigna_globales');
      --
      --
   END pp_asigna_globales;
   --
   PROCEDURE pp_asigna_globales_ct IS
   BEGIN
      --
      --@mx('I','pp_asigna_globales_ct');
      --
      trn_k_global.asigna('tip_relacion'      ,  g_tip_relacion);
      trn_k_global.asigna('tip_docum_contacto',  g_tip_docum_contacto);
      trn_k_global.asigna('cod_docum_contacto',  g_cod_docum_contacto);
      trn_k_global.asigna('email_contacto',      g_email_contacto);
      trn_k_global.asigna('nom_contacto',        g_nom_contacto);
      trn_k_global.asigna('ape_contacto',        g_ape_contacto);
      trn_k_global.asigna('tel_pais_contacto',   g_tel_pais_contacto);
      trn_k_global.asigna('tel_zona_contacto',   g_tel_zona_contacto);
      trn_k_global.asigna('tel_numero_contacto', g_tel_numero_contacto);
      trn_k_global.asigna('cod_evento',          TO_CHAR(g_cod_evento));
      --
      --@mx('F','pp_asigna_globales_ct');
      --
   END pp_asigna_globales_ct;
   --
   /* ----------------------------------------------------
   || Devuelve el numero del riesgo en el caso de que solo exista
   || un riesgo.
   */ ----------------------------------------------------
   --
   PROCEDURE pp_saca_riesgos
   IS
      --
      l_mca_estado VARCHAR2(1) := 'V';
      --
   BEGIN
      --
      --@mx('I','pp_saca_riesgos');
      --
      g_num_riesgo := NULL;
      --
      /* Se va a determinar si la poliza solo tiene un riesgo vigente a la fecha
      que lo tome por defecto. Si no se pedira por pantalla */
      --
      IF (g_tip_poliza_tr = 'F'    AND -- Si No es transportes
         em_f_num_riesgos(g_cod_cia,
                          g_num_poliza,
                          l_mca_estado,
                          g_fec_sini,
                          g_hora_sini) = 1) OR
         (g_tip_poliza_tr != 'F' AND -- Si es transportes
          em_f_num_riesgos_apli(g_cod_cia,
                                g_num_poliza,
                                g_num_spto,
                                g_num_apli,
                                l_mca_estado,
                                g_fec_sini,
                                g_hora_sini) = 1)
      THEN
         --
         IF         g_tip_poliza_tr                     = g_k_tip_pol_trans_fija
            OR (    g_tip_poliza_tr                    <> g_k_tip_pol_trans_fija
                AND g_num_apli                          = g_k_cero
                AND ts_k_g7000001.f_mca_siniestra_marco = g_k_si                )
         THEN
            --
            g_num_riesgo := em_f_recupera_riesgo(g_cod_cia,
                                                 g_num_poliza,
                                                 l_mca_estado,
                                                 g_fec_sini,
                                                 g_hora_sini);
            --
         ELSE
            --
            g_num_riesgo := em_f_recupera_riesgo_apli(g_cod_cia,
                                                      g_num_poliza,
                                                      g_num_spto,
                                                      g_num_apli,
                                                      l_mca_estado,
                                                      g_fec_sini,
                                                      g_hora_sini);
            --
         END IF;
         --
      END IF;
      --
      --@mx('F','pp_saca_riesgos');
      --
   END pp_saca_riesgos;
   --
   /* --------------------------------------------------------
   || Recupera el numero de siniestro
   */ --------------------------------------------------------
   --
   FUNCTION fp_num_sini
            RETURN a7000900.num_sini%TYPE
   IS
    --
    l_num_sini a7000900.num_sini%TYPE ;
    --
   BEGIN
     --
     --@mx('I','fp_num_sini');
     --
     /* Recupero del saco un número de siniestro.*/
     --
     l_num_sini := ts_k_recupera_numero_sini.f_numero_siniestro(g_cod_cia,
                                                                g_cod_sector,
                                                                g_cod_ramo,
                                                                g_cod_nivel3);
     --
     --@mx('*','l_num_sini del saco: '||l_num_sini);
     --
     /* -----------------------------------------
     || El Loop es por si el numero obtenido,
     || ya esta siendo utilizado, por lo que busca
     || numeros hasta que encuentre uno libre.
     */ -----------------------------------------
     --
     DECLARE
       --
       le_no_existe EXCEPTION;
       PRAGMA       EXCEPTION_INIT(le_no_existe,-20001);
       --
     BEGIN
       --
       /* Valido si existe el número de siniestro obtenido en la tabla real.*/
       --
       ts_k_a7000900.p_lee_a7000900 (g_cod_cia,
                                     l_num_sini);
       --
       LOOP
         --
         /* Si ya existe lo borro del saco y obtengo otro nuevo número
         de siniestro. */
         --
         ts_k_g7000140.p_borra(g_cod_cia,
                               l_num_sini);
         --
         l_num_sini := ts_k_recupera_numero_sini.f_numero_siniestro(g_cod_cia,
                                                                    g_cod_sector,
                                                                    g_cod_ramo,
                                                                    g_cod_nivel3);
         --
         --@mx('*','l_num_sini del saco: '||l_num_sini);
         --
         ts_k_a7000900.p_lee_a7000900 (g_cod_cia,
                                       l_num_sini);
         --
       END LOOP;
       --
       --@mx('F','fp_num_sini');
       --
     EXCEPTION
     WHEN le_no_existe
     THEN
       --
       /* Si alguno de los números leidos no existiera, sera el que utilice.
          Por tanto, no provoco el error.*/
       --
       --@mx('*','entra en la exception. El numero no existe en a7000900');
       --
       NULL;
       --
       --@mx('F','EXCEPTION - fp_num_sini');
       --
     END;
     --
     /* Devuelvo el número de siniestro obtenido.*/
     --
     --@mx('*','l_num_sini que devuelvo : '||l_num_sini);
     --
     RETURN l_num_sini;
     --
   END fp_num_sini;
   --
   /* -----------------------------------------------------
   || pp_p_query : Rellena la tabla PL.
   */ -----------------------------------------------------
   --
   PROCEDURE pp_p_query IS
      --
      /* Definicion del registro que obtengo del cursor variable */
      --
      TYPE reg_a2000040_v IS RECORD(
         cod_cob            a2000040.cod_cob            %TYPE,
         suma_aseg          a2000040.suma_aseg          %TYPE,
         cod_mon_capital    a2000040.cod_mon_capital    %TYPE,
         cod_franquicia     a2000040.cod_franquicia     %TYPE,
         val_franquicia_max a2000040.val_franquicia_max %TYPE,
         val_franquicia_min a2000040.val_franquicia_min %TYPE);
      --
      l_reg reg_a2000040_v;
      --
      TYPE cursor_variable IS REF CURSOR RETURN l_reg   %TYPE;
      --
      l_cursor cursor_variable;
      --
   BEGIN
      --
      --@mx('I','pp_p_query');
      --
      g_tb_a2000040.DELETE;
      --
      g_fila   := 0;
      g_cnt_pk := 1;
      --
      OPEN l_cursor FOR
         SELECT cod_cob,
                NVL(suma_aseg,0) * NVL(imp_unidad, 1),
                cod_mon_capital,
                cod_franquicia,
                val_franquicia_max,
                val_franquicia_min
           FROM a2000040
          WHERE cod_cia               = g_cod_cia
            AND num_poliza            = g_num_poliza
            AND num_spto              = g_max_spto_40
            AND num_apli              = g_num_apli
            AND num_spto_apli         = g_max_spto_apli_40
            AND num_riesgo            = g_num_riesgo
            AND num_periodo           = g_num_periodo
            AND NVL(mca_baja_cob,'N') = 'N'
            AND cod_ramo              = g_cod_ramo
          ORDER BY num_secu;
      --
      FETCH l_cursor INTO l_reg;
      --
      WHILE l_cursor%FOUND
      LOOP
         --
         /* 26-12-2005.
             Accedo a la tabla de Coberturas a nivel de compañía para
            excluir las coberturas ficticias a nivel de póliza y de riesgo.
         */
         --
         em_k_a1002050.p_lee (g_cod_cia, l_reg.cod_cob);
         --
         IF em_k_a1002050.f_tip_cob NOT IN ('9','8')
         THEN
            --
            g_fila := g_fila + 1;
            --
            g_tb_a2000040(g_fila).num_secu_k         := g_fila;
            g_tb_a2000040(g_fila).post_query         := FALSE;
            --
            g_tb_a2000040(g_fila).cod_cob            := l_reg.cod_cob;
            g_tb_a2000040(g_fila).cod_mon_capital    := l_reg.cod_mon_capital;
            g_tb_a2000040(g_fila).suma_aseg          := l_reg.suma_aseg;
            g_tb_a2000040(g_fila).cod_franquicia     := l_reg.cod_franquicia;
            g_tb_a2000040(g_fila).val_franquicia_max := l_reg.val_franquicia_max;
            g_tb_a2000040(g_fila).val_franquicia_min := l_reg.val_franquicia_min;
            --
         END IF;
         --
         FETCH l_cursor INTO l_reg;
         --
      END LOOP;
      --
      CLOSE l_cursor;
      --
      g_max_secu_query := g_fila;
      g_fila           := NULL;
      g_fila_devuelve  := NULL;
      --
      --@mx('F','pp_p_query');
      --
   END pp_p_query;
   --
   /* -----------------------------------------------------
   || pp_rellena_registro : Registro en el que estoy posicionado de la tabla PL
   */ -----------------------------------------------------
   PROCEDURE pp_rellena_registro(p_fila BINARY_INTEGER) IS
   BEGIN
      --
      --@mx('I','pp_rellena_registro');
      --
      greg_a2000040.cod_cob             := g_tb_a2000040(p_fila).cod_cob;
      greg_a2000040.nom_cob             := g_tb_a2000040(p_fila).nom_cob;
      greg_a2000040.cod_mon_capital     := g_tb_a2000040(p_fila).cod_mon_capital;
      greg_a2000040.cod_cob_relacionada := g_tb_a2000040(p_fila).cod_cob_relacionada;
      greg_a2000040.nom_cob_relacionada := g_tb_a2000040(p_fila).nom_cob_relacionada;
      greg_a2000040.suma_aseg           := g_tb_a2000040(p_fila).suma_aseg;
      greg_a2000040.cod_franquicia      := g_tb_a2000040(p_fila).cod_franquicia;
      greg_a2000040.val_franquicia      := g_tb_a2000040(p_fila).val_franquicia;
      greg_a2000040.tip_franquicia      := g_tb_a2000040(p_fila).tip_franquicia;
      greg_a2000040.tip_franquicia_stro := g_tb_a2000040(p_fila).tip_franquicia_stro;
      greg_a2000040.val_franquicia_min  := g_tb_a2000040(p_fila).val_franquicia_min;
      greg_a2000040.tip_franquicia_min  := g_tb_a2000040(p_fila).tip_franquicia_min;
      greg_a2000040.val_franquicia_max  := g_tb_a2000040(p_fila).val_franquicia_max;
      greg_a2000040.tip_franquicia_max  := g_tb_a2000040(p_fila).tip_franquicia_max;
      greg_a2000040.deducible           := g_tb_a2000040(p_fila).deducible;
      --
      --@mx('F','pp_rellena_registro');
      --
   END pp_rellena_registro;
   --
   /* -----------------------------------------------------
   || post_query :
   */ -----------------------------------------------------
   PROCEDURE pp_post_query(p_fila BINARY_INTEGER) IS
      l_cod_modalidad a1002150.cod_modalidad %TYPE;
      --
   BEGIN
      --
      --@mx('I','pp_post_query');
      --
      IF NOT g_tb_a2000040(p_fila).post_query
      THEN
         BEGIN
            --
            /* Obtengo el nombre de la cobertura */
            --
            /* Voy a mirar si la cobertura obtenida depende de otra cobertura
            Leo del packages de la tabla de coberturas por ramo*/
            --
            IF g_cod_tratamiento != 'V'
            THEN
               l_cod_modalidad := 99999;
            ELSE
               l_cod_modalidad := g_cod_modalidad;
            END IF;
            --
            g_tb_a2000040(p_fila).nom_cob := em_k_a1002150.f_reg_max_fec_validez ( g_cod_cia,
                                                                                   g_cod_ramo,
                                                                                   l_cod_modalidad,
                                                                                   g_tb_a2000040(p_fila).cod_cob,
                                                                                   g_fec_sini).nom_cob;
            --
            g_fec_validez := em_k_a1002150.f_max_fec_validez ( g_cod_cia,
                                                               g_cod_ramo,
                                                               TRUNC(SYSDATE));
            --
            em_k_a1002150.p_lee(g_cod_cia,
                                g_cod_ramo,
                                l_cod_modalidad,
                                g_tb_a2000040(p_fila).cod_cob,
                                g_fec_validez);
            --
            /*Saco la cobertura de la que depende */
            --
            g_tb_a2000040(p_fila).cod_cob_relacionada := em_k_a1002150.f_cod_cob_relacionada;
            --
            /* En el caso de que dependa de alguna cobertura es decir que la
            cobertura relacionada no este nula, saco el nombre de la misma en
            el nom_cob_relacionada */
            --
            IF g_tb_a2000040(p_fila).cod_cob_relacionada IS NOT NULL
            THEN
               em_k_a1002150.p_lee(g_cod_cia,
                                   g_cod_ramo,
                                   l_cod_modalidad,
                                   g_tb_a2000040(p_fila).cod_cob_relacionada,
                                   g_fec_validez);
               --
               g_tb_a2000040(p_fila).nom_cob_relacionada := em_k_a1002150.f_nom_cob;
               --
            END IF;
            --
            /* Voy a sacar los deducibles Obtengo el valor de la franquicia */
            --
            IF g_tb_a2000040(p_fila).cod_franquicia IS NOT NULL
            THEN
               --
               em_k_a2100700.p_lee(g_cod_cia,
                                   g_tb_a2000040(p_fila).cod_mon_capital,
                                   g_tb_a2000040(p_fila).cod_franquicia);
               --
               g_tb_a2000040(p_fila).val_franquicia := em_k_a2100700.f_val_franquicia;
               --
               g_tb_a2000040(p_fila).tip_franquicia := ss_f_nom_valor('TIP_FRANQUICIA',
                                                                      '999',
                                                                      TO_CHAR(em_k_a2100700.f_tip_franquicia),
                                                                      g_cod_idioma);
               --
               /* Obtengo el tipo de vehiculo si el tratamiento es de autos.*/
               --
               IF g_cod_tratamiento = 'A'
                THEN
                  --
                  em_k_g2990015.p_lee(p_cod_cia => g_cod_cia);
                  --
                  g_cod_tip_vehi := em_f_dato_var_a2000020(p_cod_cia     => g_cod_cia,
                                                           p_num_poliza  => g_num_poliza,
                                                           p_num_spto    => g_num_spto,
                                                           p_num_riesgo  => g_num_riesgo,
                                                           p_num_periodo => g_num_periodo,
                                                           p_cod_campo   => em_k_g2990015.f_cod_tip_vehi, --'COD_TIP_VEHI',
                                                           p_cod_ramo    => g_cod_ramo);
                  --
                  --@mx('g_cod_tip_vehi-->', g_cod_tip_vehi);
                  --
               ELSE
                  g_cod_tip_vehi := 999;
               END IF; -- Del tratamiento
               --
               em_k_a2100701.p_lee(g_cod_cia,
                                   g_cod_ramo,
                                   l_cod_modalidad,
                                   g_tb_a2000040(p_fila).cod_cob,
                                   g_cod_tip_vehi,
                                   g_tb_a2000040(p_fila).cod_franquicia,
                                   g_tb_a2000040(p_fila).cod_mon_capital,
                                   g_fec_validez);
               --
               g_tb_a2000040(p_fila).tip_franquicia_stro := ss_f_nom_valor('TIP_FRANQUICIA_STROS',
                                                                           '999',
                                                                           TO_CHAR(em_k_a2100701.f_tip_franquicia_stros),
                                                                           g_cod_idioma);
               --
               /* Obtengo la descripcion del tipo valor minimo y el valor maximo */
               --
               IF NVL(g_tb_a2000040(p_fila).val_franquicia_min,
                      0) != 0
               THEN
                  g_tb_a2000040(p_fila).tip_franquicia_min := ss_f_nom_valor('TIP_FRANQUICIA_MIN',
                                                                             '999',
                                                                             TO_CHAR(em_k_a2100701.f_tip_franquicia_min),
                                                                             g_cod_idioma);
               END IF; -- De la franquicia minima
               --
               IF NVL(g_tb_a2000040(p_fila).val_franquicia_max,
                      0) != 0
               THEN
                  g_tb_a2000040(p_fila).tip_franquicia_max := ss_f_nom_valor('TIP_FRANQUICIA_MAX',
                                                                             '999',
                                                                             TO_CHAR(em_k_a2100701.f_tip_franquicia_max),
                                                                             g_cod_idioma);
               END IF; -- De la franquicia maxima
               --
            END IF; -- De si el cod_franquicia no es nulo.
            --
            /* Si los importes de las franquicias son TODOS cero, no muestro
              que la cobertura tenga deducible.*/
            --
            IF g_tb_a2000040(p_fila).cod_franquicia IS NULL OR
               ( NVL(g_tb_a2000040(p_fila).val_franquicia_max, 0) = 0 AND
                 NVL(g_tb_a2000040(p_fila).val_franquicia_min, 0) = 0 AND
                 NVL(g_tb_a2000040(p_fila).val_franquicia, 0)     = 0 )
            THEN
               --
               g_tb_a2000040(p_fila).deducible := 'N';
               --
            ELSE
               --
               g_tb_a2000040(p_fila).deducible := 'S';
               --
            END IF;
            --
         EXCEPTION
            WHEN OTHERS THEN
               g_tb_a2000040(p_fila).tip_franquicia_stro := 'NO VALIDO';
         END;
         ---
         pp_rellena_registro(p_fila);
         --
         g_tb_a2000040(p_fila).post_query := TRUE;
         --
      END IF;
      --
      --@mx('F','pp_post_query');
      --
   END pp_post_query;
   --
   /* --------------------------------------------------------------
   || Obtener el codigo de tramitador
   */ --------------------------------------------------------------
   --
   PROCEDURE pp_obtener_tramitador
   IS
      --
      l_cod_docum   v1001390.cod_docum  %TYPE;
      l_tip_docum   v1001390.tip_docum  %TYPE;
      l_tip_estado  a1001339.tip_estado %TYPE;
      --
   BEGIN
      --
      --@mx('I','pp_obtener_tramitador');
      --
      BEGIN
         -- Change for 1.60: References to package ts_k_a1001339 are replaced by dc_k_a1001339
         -- ts_k_a1001339.p_lee(g_cod_cia, g_cod_usr);
         --
         dc_k_a1001339.p_lee_cod_usr_tramitador (p_cod_cia             => g_cod_cia,
                                                 p_cod_usr_tramitador  => g_cod_usr);
         --
      EXCEPTION
         WHEN OTHERS THEN
            --
            /* USUARIO NO DEFINIDO COMO TRAMITADOR */
            g_cod_mensaje := 20348;
            g_anx_mensaje := NULL;
            --
            pp_devuelve_error;
      END;
      --
      -- Change for 1.60: References to package ts_k_a1001339 are replaced by dc_k_a1001339
      --
      g_tip_tramitador     := dc_k_a1001339.f_tip_tramitador;
      g_cod_tramitador     := dc_k_a1001339.f_cod_tramitador;
      g_tip_tramitador     :=  ts_k_tramitacion.f_evalua_tip_tramitador(g_cod_cia,
                                                                      g_cod_sector,
                                                                      g_cod_ramo,
                                                                      g_cod_tramitador,
                                                                      g_tip_tramitador);
         --
      g_cod_supervisor     := dc_k_a1001339.f_cod_supervisor;
      g_cod_nivel3_captura := dc_k_a1001339.f_cod_nivel3;
      --
      BEGIN
         --
         ts_k_a1001338.p_lee_cod_supervisor(g_cod_cia,
                                            g_cod_supervisor);
         --
      EXCEPTION
         WHEN OTHERS THEN
            --
            /* EL SUPERVISOR DEL TRAMITADOR NO EXISTE */
            --
            g_cod_mensaje := 70001065;
            g_anx_mensaje := NULL;
            --
            pp_devuelve_error;
      END;
      --
      /* 28-07-2005. Modificado para que si el tramitador no está Activo
        o Suspendido de Asignación no se le permita continuar.  */
      --
      -- Change for 1.60: References to package ts_k_a1001339 are replaced by dc_k_a1001339
      --
      l_tip_estado := dc_k_a1001339.f_tip_estado;
      --
      /*  Si el tramitador esta de baja, suspendido... es decir no esta activo
        tampoco le dejo continuar.
          Solo se le deja continuar si esta Activo o suspendido de asignacion.*/
      --
      IF l_tip_estado NOT IN ('A', 'SA')
      THEN
        --
        /* EL USUARIO NO TIENE ACCESO ESTA : 70001105.*/
        --
        g_cod_mensaje := 70001105;
        g_anx_mensaje := ' ' ||
                         ss_f_nom_valor('TIP_ESTADO' ,
                                        999         ,
                                        l_tip_estado ,
                                        g_cod_idioma);
        --
        pp_devuelve_error;
        --
      END IF;
      --
      /* 28-07-2005. Fin modificación.*/
      --
      BEGIN
         IF g_tip_tramitador = 'R'
         THEN
            /* Paso la sucursal del tramitador y miro cual es la tramitadora asigna
            da a esa sucursal */
            --
            ts_k_g7000150.p_lee(g_cod_cia,
                                g_cod_sector,
                                g_cod_nivel3_captura);
            --
            g_cod_nivel3_captura := ts_k_g7000150.f_cod_nivel3_tramitadora;
            --
         ELSIF g_tip_tramitador = 'C'
         THEN
            /* Paso la sucursal de la poliza y busco cual es la tramitadora */
            --
            ts_k_g7000150.p_lee(g_cod_cia,
                                g_cod_sector,
                                g_cod_nivel3);
            --
            g_cod_nivel3_captura := ts_k_g7000150.f_cod_nivel3_tramitadora;
         END IF;
         --
      EXCEPTION
         WHEN OTHERS THEN
            --
            /* ESA OFICINA NO TIENE ASIGNADA TRAMITADORA */
            g_cod_mensaje := 20349;
            g_anx_mensaje := NULL;
            --
            pp_devuelve_error;
            --
      END;
      --
      /* Busco el supervisor que le correponde */
      --
      IF g_tip_tramitador != 'T'
      THEN
         BEGIN
            ts_p_obtiene_supervisor(g_cod_cia,
                                    g_cod_sector,
                                    g_cod_ramo,
                                    g_num_poliza,
                                    g_cod_nivel3_captura,
                                    l_cod_docum,
                                    l_tip_docum,
                                    g_cod_supervisor);
         EXCEPTION
         WHEN OTHERS
         THEN
               /* NO HAY SUPERVISOR ASIGNADO A ESA OFICINA */
               g_cod_mensaje := 20352;
               g_anx_mensaje := NULL;
               --
               pp_devuelve_error;
               --
         END;
      END IF;
      --
      --@mx('F','pp_obtener_tramitador');
      --
   END pp_obtener_tramitador;
   /* --------------------------------------------------------------
   || Inserta la tabla de siniestros a7000900
   */ --------------------------------------------------------------
   PROCEDURE pp_inserta_a7000900
   IS
     --
     l_num_spto_riesgo    a7000900.num_spto_riesgo    %TYPE;
     --
   BEGIN
      --
      --@mx('I','pp_inserta_a7000900');
      --
      /* Aqui ya se ha lanzado el c.t. se cambia la asignacion antes de
         lanzar el nivel 2 de control tecnico en el p_v_cod_evento.
                pp_asigna_globales_ct;
       */
      --
      /* --------------------
         Comento estas lineas porque la rutina de CT indicara en el parametro si
         el siniestro queda retenido o no. Maria 24/05/2002
         --
         IF g_retenido_sini = 'S'
         THEN
            g_mca_provisional := 'S';
         ELSE
            g_mca_provisional := 'N';
         END IF;
         --
      */
      --
      g_num_sini_ref    := NVL(trn_k_global.ref_f_global ('num_sini_ref'), '');
      g_mca_provisional := 'N'; -- el siniestro nace NO provisional y se actualiza
      -- en el procedure ts_k_as799001.p_actualiza
      --
      /* 17-03-2004.*/
      --
      IF g_num_apli = 0
      THEN
        --
        l_num_spto_riesgo := g_num_spto_riesgo;
        --
      ELSE
        --
        l_num_spto_riesgo := g_num_spto_apli_riesgo;
        --
      END IF;
      --
      ts_k_a7000900.p_inserta(g_cod_cia,
                              g_cod_sector,
                              g_cod_ramo,
                              g_cod_modalidad,
                              g_cod_mon,
                              g_num_poliza_grupo,
                              g_num_poliza,
                              g_num_spto,
                              g_num_apli,
                              g_num_spto_apli,
                              g_num_riesgo,
                              l_num_spto_riesgo,
                              g_num_periodo,
                              g_num_sini,
                              g_tip_docum_aseg,
                              g_cod_docum_aseg,
                              g_mca_provisional,
                              g_cod_supervisor,
                              g_cod_nivel3_captura,
                              g_fec_proceso, -- Tabla a1001600 Formateada
                              g_fec_sini,
                              g_hora_sini,
                              g_fec_denu_sini,
                              g_hora_denu_sini,
                              g_cod_causa,
                              g_cod_evento,
                              g_nom_contacto,
                              g_ape_contacto,
                              g_tel_pais_contacto,
                              g_tel_zona_contacto,
                              g_tel_numero_contacto,
                              g_cod_usr,
                              g_tip_apertura,
                              g_num_sini_ref,
                              g_tip_docum_contacto,
                              g_cod_docum_contacto,
                              g_email_contacto,
                              g_tip_relacion,
                              g_tip_poliza_stro,
                              g_imp_val_ini_sini);
      --
      --@mx('F','pp_inserta_a7000900');
      --
   END pp_inserta_a7000900;
   --
   /* --------------------------------------------------------------
   || Inserta la tabla de siniestros a7001020
   */ --------------------------------------------------------------
   PROCEDURE pp_inserta_a7001020
   IS
      --
      l_num_exp          a7001020.num_exp          %TYPE := NULL;
      l_max_modificacion a7001020.num_modificacion %TYPE := 1;
      l_mca_estado       a7001020.mca_estado       %TYPE;
      l_cod_tramitador   a7001020.cod_tramitador   %TYPE;
      l_observaciones    a7001020.observaciones    %TYPE := NULL;
      --
   BEGIN
      --
      --@mx('I','pp_inserta_a7001020');
      --
      IF g_tip_tramitador != 'T'
      THEN
         --
         l_cod_tramitador := NULL;
         l_mca_estado     := 'AU';
         --
      ELSE
         --
         l_cod_tramitador := g_cod_tramitador;
         l_mca_estado     := 'P';
         --
      END IF;
      --
      ts_k_a7001020.p_inserta_a7001020(g_cod_cia,
                                       g_cod_sector,
                                       g_cod_ramo,
                                       g_cod_supervisor,
                                       l_cod_tramitador,
                                       g_num_sini,
                                       l_num_exp,
                                       l_max_modificacion,
                                       l_mca_estado,
                                       l_observaciones,
                                       g_fec_proceso,
                                       g_cod_usr);
      --
      --@mx('F','pp_inserta_a7001020');
      --
   END pp_inserta_a7001020;
   --
   /* --------------------------------------------------------------
   || Inserta la tabla de siniestros a7000930
   */ --------------------------------------------------------------
   PROCEDURE pp_inserta_a7000930 IS
      --
      l_fec_mvto         a7000930.fec_mvto         %TYPE;
      l_cod_consecuencia a7000930.cod_consecuencia %TYPE := 99999;
      l_num_exp          a7001000.num_exp          %TYPE := 0;
      l_indice           NUMBER                          := 1;
      --
   BEGIN
      --
      --@mx('I','pp_inserta_a7000930');
      --
      /* Calculo la fecha que tengo que grabar en la a7000930 */
      --
      l_fec_mvto := ts_f_fec_mvto_causa(g_cod_cia,
                                        g_num_sini,
                                        l_num_exp,
                                        g_tip_causa,
                                        g_fec_proceso);
      --
      IF g_mca_tramitable = 'N'
      THEN
         --
         ts_k_a7000930.p_inserta(g_cod_cia,
                                 g_num_sini,
                                 g_tip_causa,
                                 g_cod_causa,
                                 l_cod_consecuencia,
                                 l_fec_mvto);
         --
      ELSE
         --
         WHILE l_indice <= ts_k_as700010.f_num_consecuencias
         LOOP
            l_cod_consecuencia := ts_k_as700010.f_cod_consecuencia(l_indice);
            --
            l_indice := l_indice + 1;
            --
            ts_k_a7000930.p_inserta(g_cod_cia,
                                    g_num_sini,
                                    g_tip_causa,
                                    g_cod_causa,
                                    l_cod_consecuencia,
                                    l_fec_mvto);
            --
         END LOOP;
         --
      END IF;
      --
      --@mx('F','pp_inserta_a7000930');
      --
   END pp_inserta_a7000930;
   --
   /* --------------------------------------------------------------
   || Suma un caso al supervisor del siniestro
   */ --------------------------------------------------------------
   PROCEDURE pp_actualiza_supervisor IS
      --
      l_num_siniestros a1001338.num_siniestros %TYPE;
      --
   BEGIN
      --
      --@mx('I','pp_actualiza_supervisor');
      --
      ts_k_a1001338.p_lee_cod_supervisor(g_cod_cia,
                                         g_cod_supervisor);
      --
      l_num_siniestros := NVL(ts_k_a1001338.f_num_siniestros,
                              0) + 1;
      --
      ts_k_a1001338.p_actualiza(g_cod_cia,
                                g_cod_supervisor,
                                l_num_siniestros);
      --
      --@mx('F','pp_actualiza_supervisor');
      --
   END pp_actualiza_supervisor;
   --
   /*---------------------------------------------------------------
   || p_inicio
   */ -----------------------------------------------------------
   PROCEDURE p_inicio IS
   BEGIN
      --
      --@mx('I','p_inicio');
      --
      pp_inicializa_variables;
      --
      trn_k_global.asigna('admite_cualquier_tramitador',  'S');
      trn_k_global.asigna('ENTORNO_TRONWEB',              'S');
      --
      -- Maria 10/02/2003 ts_k_as799001.p_inicializa;
      --
      --@mx('F','p_inicio');
      --
   END;
   --
   /*---------------------------------------------------------------
   || pp_saca_asegurado
   */ -----------------------------------------------------------
   PROCEDURE pp_saca_asegurado IS
   BEGIN
      --
      --@mx('I','pp_saca_asegurado');
      --
      /* Se va a buscar el asegurado, si no hay se va a obtener el conductor
      y si no hay, se va a devolver el tomador */
      --
      IF         g_tip_poliza_tr                     = g_k_tip_pol_trans_fija
         OR (    g_tip_poliza_tr                    <> g_k_tip_pol_trans_fija
             AND g_num_apli                          = g_k_cero
             AND ts_k_g7000001.f_mca_siniestra_marco = g_k_si                )
      THEN
         --
         em_p_beneficiario_a2000060(g_cod_cia,
                                    g_num_poliza,
                                    g_num_spto_riesgo,
                                    g_num_riesgo,
                                    '2',
                                    g_tip_docum_aseg,
                                    g_cod_docum_aseg);
      ELSE
         em_p_benef_apli_a2000060(g_cod_cia,
                                  g_num_poliza,
                                  g_num_spto_riesgo,
                                  g_num_apli,
                                  g_num_spto_apli,
                                  g_num_riesgo,
                                  '2',
                                  g_tip_docum_aseg,
                                  g_cod_docum_aseg);
      END IF;
      --
      --@mx('F','pp_saca_asegurado');
      --
   EXCEPTION
   WHEN OTHERS
   THEN
      --
      BEGIN
          em_p_beneficiario_a2000060(g_cod_cia,
                                     g_num_poliza,
                                     g_num_spto_riesgo,
                                     g_num_riesgo,
                                     '3',
                                     g_tip_docum_aseg,
                                     g_cod_docum_aseg);
         EXCEPTION
         WHEN OTHERS
         THEN
               --
               g_tip_docum_aseg := g_tip_docum_tomador;
               g_cod_docum_aseg := g_cod_docum_tomador;
         END;
   --
   END pp_saca_asegurado;
   --
   /* --------------------------------------------------------------
   || Valida la fecha del siniestro.
   */ --------------------------------------------------------------
   PROCEDURE p_v_fec_sini(p_fec_sini a7000900.fec_sini %TYPE) IS
      --
      --
   BEGIN
      --
      --@mx('I','p_v_fec_sini');
      --
      /* Inicializa todas las variable g */
      --
      g_cod_cia    := trn_k_global.cod_cia;
      g_cod_idioma := trn_k_global.cod_idioma;
      g_cod_usr    := trn_k_global.cod_usr;
      --
      g_fec_sini := p_fec_sini;
      trn_k_global.asigna('fec_sini', TO_CHAR(g_fec_sini, 'DDMMYYYY'));
      --
      dc_p_fechas_proceso('S', -- Tipo de proceso Siniestros
                          g_cod_cia,
                          g_fec_proc_sini, -- Sin formatear
                          g_fec_proceso); -- Formateada
      --
      IF g_fec_sini IS NULL
      THEN
         g_cod_mensaje := 20003;
         g_anx_mensaje := ' p_v_fec_sini';
         --
         pp_devuelve_error;
         --
         --
      ELSIF ts_k_apertura.f_aper_sini_a_futuro = trn.NO AND g_fec_sini > g_fec_proceso
      THEN
         g_cod_mensaje := 20300;
         g_anx_mensaje := ' ( FEC_SINI) ';
         --
         pp_devuelve_error;
         --
      ELSIF ts_k_apertura.f_aper_sini_a_futuro = trn.NO AND g_fec_sini > SYSDATE
      THEN
         --
         g_cod_mensaje := 20301;
         g_anx_mensaje := ' (FEC_SINI) ';
         --
         pp_devuelve_error;
         --
      ELSIF ts_k_apertura.f_aper_sini_a_futuro = trn.SI AND g_fec_sini > SYSDATE AND
            (TO_CHAR (g_fec_sini,'YYYY') <> TO_CHAR (SYSDATE,'YYYY')   OR
             TO_CHAR (g_fec_sini,'MM') <> TO_CHAR (SYSDATE,'MM')        )
      THEN
         --
         g_cod_mensaje := 70001254;
         g_anx_mensaje := ' ';
         --
         pp_devuelve_error;
         --
      END IF;
      --
      ts_k_apertura.p_v_fec_sini ( p_fec_sini );
      --
      --@mx('F','p_v_fec_sini');
      --
   END p_v_fec_sini;
   ---
   /*-------------------------------------------------------
   || Valida que la hora del siniestro se haya introducido
   || hh24:mm
   */ -------------------------------------------------------
   PROCEDURE pp_comprueba_formato_hora(p_hora a7000900.hora_sini %TYPE) IS
      l_hora_sini VARCHAR2(4);
   BEGIN
      --
      --@mx('I','pp_comprueba_formato_hora');
      --
      IF p_hora IS NOT NULL
      THEN
         --
         IF INSTR(p_hora,
                  ':') != 3
         THEN
            --
            g_cod_mensaje := 70001119;
            --
            pp_devuelve_error;
         END IF;
         --
         l_hora_sini := TO_CHAR(TO_DATE(p_hora,'HH24:MI'), 'HHMI');
         --
      END IF;
      --
      --@mx('F','pp_comprueba_formato_hora');
      --
   END pp_comprueba_formato_hora;
   --
   /* --------------------------------------------------------------
   || Valida la hora del siniestro.
   || Se controla que si la fecha es la del dia, la hora del siniestro no
   || sea mayor que la del sistema
   */ --------------------------------------------------------------
   PROCEDURE p_v_hora_sini(p_hora_sini a7000900.hora_sini %TYPE) IS
      --
      error_hora EXCEPTION;
      PRAGMA EXCEPTION_INIT(error_hora, -01851);
      v_fecha DATE;
      --
   BEGIN
      --
      --@mx('I','p_v_hora_sini');
      --
      BEGIN
        --
        SELECT TO_DATE(p_hora_sini,'HH24:MI') INTO v_fecha
        FROM dual;
        EXCEPTION
          WHEN error_hora THEN
            --
            g_cod_mensaje := 70001119;
            g_anx_mensaje := NULL;
            --
            pp_devuelve_error;
      END;
      --
      g_hora_sini := p_hora_sini;
      --
      IF g_hora_sini IS NOT NULL
      THEN
         --
         IF TO_CHAR(g_fec_sini, 'DDMMYYYY') = TO_CHAR(SYSDATE,'DDMMYYYY')
         THEN
            --
            IF TO_DATE(g_hora_sini,'HH24:MI') >
               TO_DATE(TO_CHAR(SYSDATE,'HH24:MI'),'HH24:MI')
            THEN
               -- HORA DEL SINIESTRO NO PUEDE SER MAYOR A LA SYSDATE
               --
               g_cod_mensaje := 70001074;
               g_anx_mensaje := NULL;
               --
               pp_devuelve_error;
               --
            END IF; -- Si la hora del siniestro es mayor a la del sistema
            --
         END IF; -- Si la fecha es igual a la del sistema
         --
      END IF; -- Si no es nula
      --
      trn_k_global.asigna('hora_sini',       g_hora_sini);
      --
      ts_k_apertura.p_v_hora_sini ( p_hora_sini );
      --
      --@mx('F','p_v_hora_sini');
      --
   END p_v_hora_sini;
   --
   /* --------------------------------------------------------------
   || Valida la fecha de denuncia
   || Controla que no sea mayor a la del siniestro, ni mayor a la del dia
   */ --------------------------------------------------------------
   PROCEDURE p_v_fec_denu_sini(p_fec_denu_sini a7000900.fec_denu_sini %TYPE) IS
      --
   BEGIN
      --
      --@mx('I','p_v_fec_denu_sini');
      --
      g_fec_denu_sini := p_fec_denu_sini;
      --
      IF ts_k_apertura.f_aper_sini_a_futuro = trn.NO AND g_fec_denu_sini < g_fec_sini
      THEN
         g_cod_mensaje := 20302;
         g_anx_mensaje := ' (FEC_DENU_SINI) ';
         --
         pp_devuelve_error;
         --
      END IF;
      --
      IF ts_k_apertura.f_aper_sini_a_futuro = trn.NO AND g_fec_denu_sini > SYSDATE
      THEN
         g_cod_mensaje := 20301;
         g_anx_mensaje := ' (FEC_DENU_SINI) ';
         --
         pp_devuelve_error;
         --
      END IF;
      --
      trn_k_global.asigna('fec_denu_sini',   TO_CHAR(g_fec_denu_sini,  'DDMMYYYY'));
      --
      ts_k_apertura.p_v_fec_denu ( p_fec_denu_sini );
      --
      --@mx('F','p_v_fec_denu_sini');
      --
   END p_v_fec_denu_sini;
   --
   /* --------------------------------------------------------------
   || Valida la hora de notificacion del siniestro.
   || Se controla que si la fecha es la del dia, la hora de notificacion del
   || siniestro no  sea mayor que la del sistema
   */ --------------------------------------------------------------
   PROCEDURE p_v_hora_denu_sini(p_hora_denu_sini a7000900.hora_denu_sini %TYPE) IS
      --
      error_hora EXCEPTION;
      PRAGMA EXCEPTION_INIT(error_hora, -01851);
      v_fecha DATE;
      --
   BEGIN
      --
      --@mx('I','p_v_hora_denu_sini');
      --
      BEGIN
      --
        SELECT TO_DATE(p_hora_denu_sini,'HH24:MI') INTO v_fecha
        FROM DUAL;
        EXCEPTION
          WHEN error_hora THEN
            --
            g_cod_mensaje := 70001119;
            g_anx_mensaje := NULL;
            --
            pp_devuelve_error;
      END;
      --
      g_hora_denu_sini := p_hora_denu_sini;
      --
      IF g_hora_denu_sini IS NOT NULL
      THEN
         --
         IF TO_CHAR(g_fec_denu_sini,'DDMMYYYY') = TO_CHAR(SYSDATE,'DDMMYYYY')
         THEN
            --
            IF TO_DATE(g_hora_denu_sini,'HH24:MI') >
               TO_DATE(TO_CHAR(SYSDATE, 'HH24:MI'),'HH24:MI')
            THEN
               -- HORA DEL SINIESTRO NO PUEDE SER MAYOR A LA SYSDATE
               --
               g_cod_mensaje := 70001074;
               g_anx_mensaje := NULL;
               --
               pp_devuelve_error;
               --
            END IF; -- Si la hora del siniestro es mayor a la del sistema
            --
         END IF; -- Si la fecha es igual a la del sistema
         --
         IF     TO_CHAR(g_fec_sini,'DDMMYYYY') = TO_CHAR(g_fec_denu_sini,'DDMMYYYY')
            AND g_hora_sini IS NOT NULL
         THEN
            --
            IF TO_DATE(g_hora_sini,'HH24:MI') >
               TO_DATE(g_hora_denu_sini,'HH24:MI')
            THEN
               -- HORA DEL SINIESTRO NO PUEDE SER MAYOR A LA HORA DE DENUNCIA
               --
               g_cod_mensaje := 70001248;
               g_anx_mensaje := NULL;
               --
               pp_devuelve_error;
               --
            END IF; -- Si la hora del siniestro es mayor a la de denuncia
            --
         END IF; -- Si la fecha del siniestro es igual a la de denuncia
                 -- y la hora del siniestro no es nula
         --
      END IF; -- Si no es nula
      --
      trn_k_global.asigna('hora_denu_sini',  g_hora_denu_sini);
      --
      ts_k_apertura.p_v_hora_denu ( p_hora_denu_sini );
      --
      --@mx('F','p_v_hora_denu_sini');
      --
   END p_v_hora_denu_sini;
   --
   /* --------------------------------------------------------------
   || Menu de opciones 1
   || Asigna las variables que tiene hasta ahora
   || a globales para que se pueda llamar a alguna opcion
   */ --------------------------------------------------------------
   --
   PROCEDURE p_asigna_globales_menu_1 IS
   BEGIN
      --
      --@mx('I','p_asigna_globales_menu_1');
      --
      trn_k_global.asigna('fec_sini',      TO_CHAR(g_fec_sini, 'DDMMYYYY'));
      trn_k_global.asigna('fec_denu_sini', TO_CHAR(g_fec_denu_sini,'DDMMYYYY'));
      trn_k_global.asigna('hora_sini',     g_hora_sini);
      trn_k_global.asigna('hora_denu_sini', g_hora_denu_sini);
      trn_k_global.asigna('externo',       'S');
      --
      --@mx('F','p_asigna_globales_menu_1');
      --
   END;
   --
   /* --------------------------------------------------------------
   || Borra Menu de opciones 1
   || Borra las variables que ha asignado
   */ --------------------------------------------------------------
   --
   PROCEDURE p_borra_globales_menu_1 IS
   BEGIN
      --
      --@mx('I','p_borra_globales_menu_1');
      --
      trn_k_global.borra_variable('fec_sini');
      trn_k_global.borra_variable('fec_denu_sini');
      trn_k_global.borra_variable('hora_sini');
      trn_k_global.borra_variable('hora_denu_sini');
      trn_k_global.borra_variable('externo');
      --
      --@mx('F','p_borra_globales_menu_1');
      --
   END;
   --
   /* --------------------------------------------------------------
   || Valida el numero de poliza
   || Controla que exista, que no este anulada, obtiene el suplemento
   || a la fecha,....
   */ --------------------------------------------------------------
   --
   PROCEDURE p_v_num_poliza
           ( p_num_poliza      IN       a7000900.num_poliza      %TYPE,
             p_num_spto        IN OUT   a7000900.num_spto        %TYPE,
             p_num_apli        IN OUT   a7000900.num_apli        %TYPE,
             p_num_spto_apli   IN OUT   a7000900.num_spto_apli   %TYPE,
             p_num_riesgo      IN OUT   a7000900.num_riesgo      %TYPE,
             p_tip_poliza_tr   IN OUT   a2000030.tip_poliza_tr   %TYPE,
             p_tip_poliza_stro IN OUT   a7000900.tip_poliza_stro %TYPE) IS
      --
      l_num_dias_max        g7000900.num_dias_max       %TYPE := 0;
      l_num_spto            a7000900.num_spto           %TYPE := 0;
      l_temporal            a7000900.tip_est_sini       %TYPE := 'S';
      --
      l_mca_poliza_anulada  a2000030.mca_poliza_anulada %TYPE;
      l_fec_emision         a2000030.fec_emision        %TYPE;
      l_fec_emision_spto    a2000030.fec_emision_spto   %TYPE;
      l_mca_sini_pol_anul   a2991800.mca_sini_pol_anul  %TYPE;
      --
      l_reg a2000030%ROWTYPE;
      --
      l_mca_retencion g7000140.mca_retencion %TYPE := 'N';
      --
   BEGIN
      --
      --@mx('I','p_v_num_poliza');
      --
      /* 28-12-2004.
         Si ya hay un numero de siniestro calculado, lo que se hace es dejarlo como
        que no ha sido utilizado, ya que el numero de siniestro se va a calcular siempre
        debido a que se puede cambiar el número de poliza bien por que ha saltado un C.Tecnico
        de nivel 1 y al corregir errores se cambia la poliza o una vez que se ha introducido
        la poliza y el riesgo nos damos cuenta que la poliza no es la correcta y con el
        ratón cambiamos el número.*/
      --
      IF g_num_sini IS NOT NULL
      THEN
         --
         --@mx('*','Si hay número de siniestro calculado, lo libero pues voy tomar uno nuevo');
         --@mx('g_num_sini',g_num_sini);
         --
         ts_k_g7000140.p_modifica(g_cod_cia,
                                  g_num_sini,
                                  l_mca_retencion,
                                  g_cod_usr);
         --
      END IF;
      --
      --
      g_num_poliza := p_num_poliza;
      trn_k_global.asigna('num_poliza', g_num_poliza);
      --
      BEGIN
         --
         g_cod_ramo := em_f_cod_ramo(g_cod_cia,
                                     g_num_poliza);
         g_tip_poliza_stro := 'R';
         --
      EXCEPTION
      WHEN OTHERS
      THEN
         --
         BEGIN
            --
            ts_k_a7000910.p_lee(p_num_poliza,
                                NULL);
            --
            g_cod_ramo := ts_k_a7000910.f_cod_ramo;
            --
            g_tip_poliza_stro := 'FT';
            --
         EXCEPTION
         WHEN OTHERS
         THEN
            --
            -- LA POLIZA NO EXISTE
            --
            g_cod_mensaje := 20000;
            g_anx_mensaje := fi_txt_mensaje(70001099);
            --
            pp_devuelve_error;
            --
         END;
         --
      END;
      --
      p_tip_poliza_stro := g_tip_poliza_stro;
      --
      dc_k_a1001800.p_lee(g_cod_cia,
                          g_cod_ramo);
      --
      g_cod_sector := dc_k_a1001800.f_cod_sector;
      --
      g_cod_tratamiento := dc_k_a1001800.f_cod_tratamiento;
      --
      g_nom_ramo := dc_k_a1001800.f_nom_ramo;
      --
      -- Valida si se tiene en cuenta la tabla de extemporaneidad.
      IF ts_k_apertura.f_extemporaneidad = 'S'
      THEN
         --
         /* Valida que el siniestro no este denunciado fuera de plazo */
         --
         BEGIN
            --
            ts_k_g7000900.p_lee(g_cod_cia,
                                g_cod_sector,
                                g_cod_ramo);
            --
            l_num_dias_max := ts_k_g7000900.f_num_dias_max;
            --
         EXCEPTION
         WHEN OTHERS
         THEN
            --
            /* Busco con el Ramo 999, para todos los ramos */
            --
            BEGIN
                --
                ts_k_g7000900.p_lee(g_cod_cia,
                                    g_cod_sector,
                                    999);
                --
                l_num_dias_max := ts_k_g7000900.f_num_dias_max;
                --
            EXCEPTION
            WHEN OTHERS
            THEN
               l_num_dias_max := NULL;
            END;
            --
         END;
         --
         IF (g_fec_denu_sini - g_fec_sini) > l_num_dias_max
         THEN
            -- SINIESTRO DENUNCIADO FUERA DE PLAZO
            g_cod_mensaje := 20303;
            g_anx_mensaje := NULL;
            --
            pp_devuelve_error;
            --
         END IF;
         --
      END IF;
      --
      IF g_tip_poliza_stro = 'R'      -- Es una póliza Real.
      THEN
         --
         /* Determino si la poliza es fija, es decir no tiene aplicaciones */
         --
         p_tip_poliza_tr := ts_f_a2000030_1(g_cod_cia,
                                            g_num_poliza,
                                            l_num_spto);
         --
         g_tip_poliza_tr := p_tip_poliza_tr;
         --
         IF g_tip_poliza_tr = 'F'
         THEN
            --
            g_num_apli      := 0;
            --
            trn_k_global.asigna('num_apli'     , TO_CHAR(g_num_apli));
            --
            g_num_spto_apli := 0;
            --
            trn_k_global.asigna('num_spto_apli', TO_CHAR(g_num_spto_apli));
            --
            /* Voy a obtener, el suplemento de la poliza a la fecha del siniestro
            marca de anulacion,fecha_efecto y vcto de la poliza, fecha emision,
            fecha emision del spto */
            --
            BEGIN
               --
               l_temporal  :=  ts_k_apertura.f_mca_spto_temp(p_cod_cia       => g_cod_cia      ,
                                                             p_cod_sector    => g_cod_sector   ,
                                                             p_cod_ramo      => g_cod_ramo     ,
                                                             p_cod_modalidad => g_cod_modalidad,
                                                             p_num_poliza    => g_num_poliza   ,
                                                             p_num_apli      => g_num_apli     ,
                                                             p_num_riesgo    => g_num_riesgo   ,
                                                             p_fec_sini      => g_fec_sini     );
               --
               p_num_spto := fp_calcula_num_spto(p_cod_cia     => g_cod_cia   ,
                                                 p_num_poliza  => g_num_poliza,
                                                 p_fec_sini    => g_fec_sini  ,
                                                 p_temporal    => l_temporal  ,
                                                 p_hora_sini   => g_hora_sini );
               --
               IF p_num_spto IS NULL
               THEN
                  --
                  em_p_a2000030_1(p_cod_cia            => g_cod_cia            ,
                                  p_num_poliza         => g_num_poliza         ,
                                  p_fecha              => g_fec_sini           ,
                                  p_temporal           => l_temporal           , --S
                                  p_num_spto           => p_num_spto           ,
                                  p_mca_poliza_anulada => l_mca_poliza_anulada ,
                                  p_fec_efec_poliza    => g_fec_efec_poliza    ,
                                  p_fec_vcto_poliza    => g_fec_vcto_poliza    ,
                                  p_fec_emision        => l_fec_emision        ,
                                  p_fec_emision_spto   => l_fec_emision_spto   ,
                                  p_mca_sini_pol_anul  => l_mca_sini_pol_anul  );
                  --
               ELSE
                  --
                  em_k_a2000030.p_lee(p_cod_cia       => g_cod_cia       ,
                                      p_num_poliza    => g_num_poliza    ,
                                      p_num_spto      => p_num_spto      ,
                                      p_num_apli      => g_k_cero        ,
                                      p_num_spto_apli => g_k_cero        );
                  --
                  l_reg := em_k_a2000030.f_devuelve_reg;
                  --
                  l_mca_poliza_anulada := l_reg.mca_poliza_anulada ;
                  g_fec_efec_poliza    := l_reg.fec_efec_poliza    ;
                  g_fec_vcto_poliza    := l_reg.fec_vcto_poliza    ;
                  l_fec_emision        := l_reg.fec_emision        ;
                  l_fec_emision_spto   := l_reg.fec_emision_spto   ;
                  --
                  -- Obtención de la mca_sini_pol_anul
                  IF l_reg.tip_spto != g_k_nueva_emision
                  THEN
                     --
                     em_k_a2991800.p_lee_tip_ambito(p_cod_cia       => g_cod_cia         ,
                                                    p_cod_spto      => l_reg.cod_spto    ,
                                                    p_sub_cod_spto  => l_reg.sub_cod_spto,
                                                    p_tip_emision   => g_k_nueva_emision );
                     --
                     l_mca_sini_pol_anul := em_k_a2991800.f_mca_sini_pol_anul;
                     --
                  ELSE
                     --
                     l_mca_sini_pol_anul := g_k_no;
                     --
                  END IF;
                  --
               END IF;
               --
            EXCEPTION
            WHEN OTHERS
            THEN
              --
              --@mx('*','p_v_num_poliza - poliza vencida');
              --
              IF ts_k_apertura.f_poliza_no_vig_no_apli = 'S'
               THEN
                --
                --@mx('*','p_v_num_poliza - poliza sin fecha');
                --
                em_p_a2000030_1(g_cod_cia            ,
                                g_num_poliza         ,
                                NULL                 ,
                                l_temporal           , --S
                                p_num_spto           ,
                                l_mca_poliza_anulada ,
                                g_fec_efec_poliza    ,
                                g_fec_vcto_poliza    ,
                                l_fec_emision        ,
                                l_fec_emision_spto   ,
                                l_mca_sini_pol_anul  );
                --
                --@mx('*','p_v_num_poliza - g_fec_efec_poliza = '||g_fec_efec_poliza);
                --@mx('*','p_v_num_poliza - g_fec_sini = '||g_fec_sini);
                --
                IF     g_fec_efec_poliza > g_fec_sini
                   OR (fp_valida_fecha_hora(p_cod_cia       => g_cod_cia   ,
                                            p_num_poliza    => g_num_poliza,
                                            p_num_spto      => p_num_spto  ,
                                            p_num_apli      => g_k_cero    ,
                                            p_num_spto_apli => g_k_cero    ,
                                            p_fec_sini      => g_fec_sini  ,
                                            p_hora_sini     => g_hora_sini ))
                THEN
                  --
                  --@mx('*','p_v_num_poliza -  fec_efec > fec_sini ');
                  --
                  -- LA POLIZA NO ESTA VIGENTE A LA FECHA. 70001214.
                  --
                  IF f_devuelve_spto_discontinuo (p_cod_cia    => g_cod_cia,
                                                  p_num_poliza => g_num_poliza,
                                                  p_fec_sini   => g_fec_sini,
                                                  p_hora_sini  => g_hora_sini) THEN
                     g_cod_mensaje := 70001294;
                     g_anx_mensaje := '';
                  ELSE
                     g_cod_mensaje := 70001214;
                     g_anx_mensaje := ' em_p_a2000030_1';
                  END IF;
                  --
                  pp_devuelve_error;
                  --
                END IF;
                --
              ELSE
                --
                --@mx('*','p_v_num_poliza - ERROR');
                --
                -- LA POLIZA NO ESTA VIGENTE A LA FECHA. 70001214.
                --
                IF f_devuelve_spto_discontinuo (p_cod_cia    => g_cod_cia,
                                                p_num_poliza => g_num_poliza,
                                                p_fec_sini   => g_fec_sini,
                                                p_hora_sini  => g_hora_sini) THEN
                   g_cod_mensaje := 70001294;
                   g_anx_mensaje := '';
                ELSE
                   g_cod_mensaje := 70001214;
                   g_anx_mensaje := ' em_p_a2000030_1';
                END IF;
                --
                pp_devuelve_error;
                --
              END IF;
              --
            END;
            --
            g_num_spto := p_num_spto;
            trn_k_global.asigna('num_spto', TO_CHAR(g_num_spto));
            --
            em_k_a2000030.p_lee(g_cod_cia,
                                g_num_poliza,
                                g_num_spto,
                                g_num_apli,
                                g_num_spto_apli);
            --
            g_mca_exclusivo       := em_k_a2000030.f_mca_exclusivo;
            g_mca_provisional_pol := em_k_a2000030.f_mca_provisional;
            g_mca_datos_minimos   := em_k_a2000030.f_mca_datos_minimos;
            g_tip_coaseguro       := em_k_a2000030.f_tip_coaseguro;
            g_tip_docum_tomador   := em_k_a2000030.f_tip_docum;
            g_cod_docum_tomador   := em_k_a2000030.f_cod_docum;
            g_cod_agt             := em_k_a2000030.f_cod_agt;
            g_cod_nivel1          := em_k_a2000030.f_cod_nivel1;
            g_cod_nivel2          := em_k_a2000030.f_cod_nivel2;
            g_cod_nivel3          := em_k_a2000030.f_cod_nivel3;
            g_cod_mon             := em_k_a2000030.f_cod_mon;
            g_num_poliza_grupo    := em_k_a2000030.f_num_poliza_grupo;
            g_fec_efec_spto       := em_k_a2000030.f_fec_efec_spto;
            --
            /* ---------------------------
               Control de Acceso a Datos
            */ ---------------------------
            --
            pp_control_acceso_general;
            --
            IF ts_k_apertura.f_aper_sini_a_futuro =  trn.NO AND g_fec_sini > SYSDATE
            THEN
               --
               g_cod_mensaje := 70001255;
               g_anx_mensaje := ' ';
               --
               pp_devuelve_error;
               --
            END IF;
            --
            IF l_mca_poliza_anulada = 'S' AND l_mca_sini_pol_anul = 'N'
            THEN
               -- POLIZA SUPLEMENTO ANULADO
               g_cod_mensaje := 20043;
               g_anx_mensaje := NULL;
               --
               pp_devuelve_error;
            ELSIF l_mca_poliza_anulada = 'S' AND l_mca_sini_pol_anul = 'S' AND g_fec_sini> g_fec_efec_spto
            THEN
               -- POLIZA SUPLEMENTO ANULADO
               g_cod_mensaje := 20043;
               g_anx_mensaje := NULL;
               --
               pp_devuelve_error;
            END IF;
            --
            IF NVL(g_mca_datos_minimos,'N') = 'N'
            THEN
               --
               IF g_mca_provisional_pol = 'S'
               THEN
                  -- POLIZA RETENIDA
                  g_cod_mensaje := 20032;
                  g_anx_mensaje := NULL;
                  --
                  pp_devuelve_error;
                  --
               END IF;
               --
            ELSIF NVL(g_mca_datos_minimos,'N') = 'S' AND g_mca_provisional_pol = 'S'
            THEN
               --
               /* Cuando la poliza esta retenida con datos minimos, se podra modificar
                 el campo tip_poliza_stro de la a7000900, para posteriormente poder
                 realizar controles tecnicos sin tener que acceder nuevamente a la
                 poliza.
               */
               --
               g_tip_poliza_stro := ts_k_apertura.f_tip_poliza_stro_dmin_ret;
               --
            END IF;
            --
            pp_saca_riesgos;
            --
            p_num_riesgo := NVL(g_num_riesgo,
                                0);
            --
         END IF; -- Final del IF g_tip_poliza_tr = 'F'
         --
      ELSE       -- Es una póliza ficticia, por lo que tomo la informacion de la A7000910.
         --
         /* ---------------------------
            Control de Acceso a Datos
         */ ---------------------------
         pp_control_acceso_general_gen;
         --
         g_num_poliza := p_num_poliza;
         trn_k_global.asigna('num_poliza',g_num_poliza);
         --
         g_cod_modalidad := 99999;
         g_cod_mon := ts_k_a7000910.f_cod_mon;
         --
         p_num_spto      := ts_k_a7000910.f_num_spto;
         p_num_apli      := ts_k_a7000910.f_num_apli;
         p_num_spto_apli := ts_k_a7000910.f_num_spto_apli;
         --
         p_num_riesgo := ts_k_a7000910.f_num_riesgo;
         g_num_riesgo := p_num_riesgo;
         --
         g_num_periodo := ts_k_a7000910.f_num_periodo;
         trn_k_global.asigna('num_periodo',g_num_periodo);
         g_num_spto_riesgo := 0;
         trn_k_global.asigna('num_spto_riesgo',g_num_spto_riesgo);
         --
         g_cod_sector := ts_k_a7000910.f_cod_sector;
         trn_k_global.asigna('cod_sector',g_cod_sector);
         --
         g_cod_ramo := ts_k_a7000910.f_cod_ramo;
         trn_k_global.asigna('cod_ramo',g_cod_ramo);
         --
         g_num_apli := ts_k_a7000910.f_num_apli;
         trn_k_global.asigna('num_apli',g_num_apli);
         --
         g_num_spto := ts_k_a7000910.f_num_spto;
         trn_k_global.asigna('num_spto',g_num_spto);
         --
         g_num_spto_apli := ts_k_a7000910.f_num_spto_apli;
         trn_k_global.asigna('num_spto_apli',ts_k_a7000910.f_num_spto_apli);
         --
         g_cod_nivel1 := ts_k_a7000910.f_cod_nivel1;
         trn_k_global.asigna('cod_nivel1',g_cod_nivel1);
         g_cod_nivel2 := ts_k_a7000910.f_cod_nivel2;
         trn_k_global.asigna('cod_nivel2',g_cod_nivel2);
         g_cod_nivel3 := ts_k_a7000910.f_cod_nivel3;
         trn_k_global.asigna('cod_nivel3',g_cod_nivel3);
         --
         g_tip_docum_tomador := ts_k_a7000910.f_tip_docum_tomador;
         trn_k_global.asigna('tip_docum',g_tip_docum_tomador);
         g_cod_docum_tomador := ts_k_a7000910.f_cod_docum_tomador;
         trn_k_global.asigna('cod_docum',g_cod_docum_tomador);
         --
         g_tip_docum_aseg := ts_k_a7000910.f_tip_docum_tomador;
         g_cod_docum_aseg := ts_k_a7000910.f_cod_docum_tomador;
         --
         g_cod_agt           := ts_k_a7000910.f_cod_agt;
         trn_k_global.asigna('cod_agt',g_cod_agt);
         --
         g_tip_causa := '1'; -- Causas de Siniestro
         trn_k_global.asigna('cod_grp_est'     ,'2');
         trn_k_global.asigna('tip_causa'       , g_tip_causa);
         trn_k_global.asigna('tip_causa_origen', g_tip_causa);
         --
         pp_asigna_globales;
         --
         -- Cuando la póliza es ficticia, obtengo el número de siniestro que corresponde, ya
         -- que para las póliza reales el número se obtiene en el p_v_num_riesgo.
         --
         /* 08/03/2006. Se crea una funcion, fp_num_sini, que devuelve el numero de siniestro
           que corresponde, controlando que si el número ya está siendo utilizado se busca otro
           número nuevo.*/
         --
         g_num_sini := fp_num_sini;
         --
         /*g_num_sini := ts_k_recupera_numero_sini.f_numero_siniestro(g_cod_cia,
                                                                    g_cod_sector,
                                                                    g_cod_ramo,
                                                                    g_cod_nivel3);
         */
         --
         --@mx('Numero de Siniestro obtenido (poliza ficticia): ',g_num_sini);
         --
         trn_k_global.asigna('num_sini',g_num_sini);
         --
         pp_obtener_tramitador;
         --
      END IF;
      --
      ts_k_apertura.p_v_num_poliza (p_num_poliza);
      --
      --@mx('F','p_v_num_poliza');
      --
   END p_v_num_poliza;
   --
   /* --------------------------------------------------------------
   || Valida La aplicacion.
   || En el caso en el que la poliza no sea fija, se ejecutara
   || la validacion de la aplicacion.
   */ --------------------------------------------------------------
   PROCEDURE p_v_num_apli(p_num_apli      IN a2000030.num_apli          %TYPE,
                          p_num_spto      IN OUT a2000030.num_spto      %TYPE,
                          p_num_spto_apli IN OUT a2000030.num_spto_apli %TYPE,
                          p_num_riesgo    IN OUT a2000031.num_riesgo    %TYPE)
   IS
      --
      l_temporal         a7000900.tip_est_sini         %TYPE := 'S';
      l_fec_emision      a2000030.fec_emision          %TYPE;
      l_fec_emision_spto a2000030.fec_emision_spto     %TYPE;
      --
      l_mca_poliza_anulada a2000030.mca_poliza_anulada %TYPE;
      l_mca_sini_pol_anul  a2991800.mca_sini_pol_anul  %TYPE;
      --
      l_reg a2000030%ROWTYPE;
      --
      l_no_existe EXCEPTION;
      PRAGMA EXCEPTION_INIT(l_no_existe, -20001);
      --
   BEGIN
      --
      --@mx('I','p_v_num_apli');
      --
      IF p_num_apli IS NULL
      THEN
         g_cod_mensaje := 20003;
         g_anx_mensaje := ' p_v_num_apli';
         --
         pp_devuelve_error;
         --
      END IF;
      --
      g_num_apli := p_num_apli;
    --
      trn_k_global.asigna('num_apli', TO_CHAR(g_num_apli));
      --
      ts_k_g7000001.p_lee(p_cod_cia  => g_cod_cia,
                          p_cod_ramo => g_cod_ramo);
      --
      IF g_num_apli != g_k_cero
      THEN
         --
         IF ts_k_apertura.f_aper_sini_a_futuro =  trn.NO AND g_fec_sini > SYSDATE
         THEN
            --
            g_cod_mensaje := 70001255;
            g_anx_mensaje := '';
            --
            pp_devuelve_error;
            --
         END IF;
         --
         /* Voy a obtener, el suplemento de la aplicacion, y de la poliza
         a la fecha del siniestro
         marca de anulacion,fecha_efecto y vcto de la poliza, fecha emision,
         fecha emision del spto */
         --
         BEGIN
            --
            l_temporal  :=  ts_k_apertura.f_mca_spto_temp(p_cod_cia       => g_cod_cia      ,
                                                          p_cod_sector    => g_cod_sector   ,
                                                          p_cod_ramo      => g_cod_ramo     ,
                                                          p_cod_modalidad => g_cod_modalidad,
                                                          p_num_poliza    => g_num_poliza   ,
                                                          p_num_apli      => g_num_apli     ,
                                                          p_num_riesgo    => g_num_riesgo   ,
                                                          p_fec_sini      => g_fec_sini     );
            --
            p_num_spto_apli := fp_calcula_num_spto_apli(p_cod_cia     => g_cod_cia   ,
                                                        p_num_poliza  => g_num_poliza,
                                                        p_fec_sini    => g_fec_sini  ,
                                                        p_temporal    => l_temporal  ,
                                                        p_hora_sini   => g_hora_sini ,
                                                        p_num_apli    => g_num_apli  );
            --
            IF p_num_spto_apli IS NULL
            THEN
              --
              p_num_spto := g_k_nulo;
              --
               em_p_a2000030_2(p_cod_cia            => g_cod_cia            ,
                               p_num_poliza         => g_num_poliza         ,
                               p_num_apli           => g_num_apli           ,
                               p_fecha              => g_fec_sini           ,
                               p_num_spto           => p_num_spto           ,
                               p_num_spto_apli      => p_num_spto_apli      ,
                               p_mca_poliza_anulada => l_mca_poliza_anulada ,
                               p_fec_efec_poliza    => g_fec_efec_poliza    ,
                               p_fec_vcto_poliza    => g_fec_vcto_poliza    ,
                               p_fec_emision_spto   => l_fec_emision_spto   ,
                               p_mca_spto_tmp       => l_temporal           , --S
                               p_mca_sini_pol_anul  => l_mca_sini_pol_anul  );
               --
            ELSE
               --
               IF p_num_spto IS NULL
               THEN
                  --
                  p_num_spto := em_f_spto_apli (p_cod_cia    => g_cod_cia   ,
                                                p_num_poliza => g_num_poliza,
                                                p_num_apli   => p_num_apli  );
                  --
               END IF;
               --
               em_k_a2000030.p_lee(p_cod_cia       => g_cod_cia       ,
                                  p_num_poliza    => g_num_poliza    ,
                                  p_num_spto      => p_num_spto      ,
                                  p_num_apli      => p_num_apli      ,
                                  p_num_spto_apli => p_num_spto_apli );
               --
               l_reg := em_k_a2000030.f_devuelve_reg;
               --
               l_mca_poliza_anulada := l_reg.mca_poliza_anulada ;
               g_fec_efec_poliza    := l_reg.fec_efec_poliza    ;
               g_fec_vcto_poliza    := l_reg.fec_vcto_poliza    ;
               l_fec_emision_spto   := l_reg.fec_emision_spto   ;
               --
               --Obtencion de la mca_sini_pol_anul
               --
               IF l_reg.tip_spto != g_k_nueva_emision
               THEN
                  --
                  em_k_a2991800.p_lee_tip_ambito(p_cod_cia      => g_cod_cia         ,
                                                 p_cod_spto     => l_reg.cod_spto    ,
                                                 p_sub_cod_spto => l_reg.sub_cod_spto,
                                                 p_tip_emision  => g_k_nueva_emision );
                  --
                  l_mca_sini_pol_anul := em_k_a2991800.f_mca_sini_pol_anul;
                  --
               ELSE
                  --
                  l_mca_sini_pol_anul := g_k_no;
                  --
               END IF;
               --
            END IF;
            --
         EXCEPTION
         WHEN l_no_existe
         THEN
            --
            IF     g_tip_poliza_tr != g_k_tip_pol_trans_fija
               AND ts_k_esp_instalacion.f_riesgo_no_vigente = g_k_si
            THEN
               --
               em_p_a2000030_2(p_cod_cia            => g_cod_cia            ,
                               p_num_poliza         => g_num_poliza         ,
                               p_num_apli           => g_num_apli           ,
                               p_fecha              => g_k_nulo             ,
                               p_num_spto           => p_num_spto           ,
                               p_num_spto_apli      => p_num_spto_apli      ,
                               p_mca_poliza_anulada => l_mca_poliza_anulada ,
                               p_fec_efec_poliza    => g_fec_efec_poliza    ,
                               p_fec_vcto_poliza    => g_fec_vcto_poliza    ,
                               p_fec_emision_spto   => l_fec_emision_spto   ,
                               p_mca_spto_tmp       => l_temporal           , --S
                               p_mca_sini_pol_anul  => l_mca_sini_pol_anul  );
               --
               em_k_a2000030.p_lee(p_cod_cia       => g_cod_cia      ,
                                   p_num_poliza    => g_num_poliza   ,
                                   p_num_spto      => p_num_spto     ,
                                   p_num_apli      => g_num_apli     ,
                                   p_num_spto_apli => p_num_spto_apli);
               --
               g_fec_efec_spto   := em_k_a2000030.f_fec_efec_spto;
               --
               IF    g_fec_efec_spto > g_fec_sini
                 OR (fp_valida_fecha_hora(p_cod_cia       => g_cod_cia      ,
                                           p_num_poliza    => g_num_poliza   ,
                                           p_num_spto      => p_num_spto     ,
                                           p_num_apli      => g_num_apli     ,
                                           p_num_spto_apli => p_num_spto_apli,
                                           p_fec_sini      => g_fec_sini     ,
                                           p_hora_sini     => g_hora_sini    ))
               THEN
                  --
                  g_cod_mensaje := 70001192; --No existe la aplicac. para la poliza o no esta vigente a:
                  --
                  g_anx_mensaje := TO_CHAR(g_fec_sini, trn_k_g0000000.f_txt_formato_fecha);
                  --
                  pp_devuelve_error;
                  --
               END IF;
               --
            ELSE
               --
               g_cod_mensaje := 70001192; --No existe la aplicac. para la poliza o no esta vigente a:
               --
               g_anx_mensaje := TO_CHAR(g_fec_sini, trn_k_g0000000.f_txt_formato_fecha);
               --
               pp_devuelve_error;
               --
            END IF;
            --
         END;
         --
         g_num_spto      := p_num_spto;
         trn_k_global.asigna('num_spto', TO_CHAR(g_num_spto));
         g_num_spto_apli := p_num_spto_apli;
         trn_k_global.asigna('num_spto_apli', TO_CHAR(g_num_spto_apli));
         g_fec_spto_anul := em_k_a2000030.f_fec_spto_anulado;
         --
         IF l_mca_poliza_anulada = g_k_si AND l_mca_sini_pol_anul = g_k_no
         THEN
            -- POLIZA SUPLEMENTO ANULADO
            g_cod_mensaje := 20043;
            g_anx_mensaje := NULL;
            --
            pp_devuelve_error;
            ELSIF l_mca_poliza_anulada = g_k_si AND l_mca_sini_pol_anul = g_k_si AND g_fec_sini> g_fec_efec_spto
         THEN
            -- POLIZA SUPLEMENTO ANULADO
            g_cod_mensaje := 20043;
            g_anx_mensaje := NULL;
            --
            pp_devuelve_error;
         END IF;
         --
         em_k_a2000030.p_lee(g_cod_cia,
                             g_num_poliza,
                             g_num_spto,
                             g_num_apli,
                             g_num_spto_apli);
         --
         g_mca_exclusivo       := em_k_a2000030.f_mca_exclusivo;
         g_mca_provisional_pol := em_k_a2000030.f_mca_provisional;
         g_mca_datos_minimos   := em_k_a2000030.f_mca_datos_minimos;
         g_tip_coaseguro       := em_k_a2000030.f_tip_coaseguro;
         g_tip_docum_tomador   := em_k_a2000030.f_tip_docum;
         g_cod_docum_tomador   := em_k_a2000030.f_cod_docum;
         g_cod_agt             := em_k_a2000030.f_cod_agt;
         g_cod_nivel1          := em_k_a2000030.f_cod_nivel1;
         g_cod_nivel2          := em_k_a2000030.f_cod_nivel2;
         g_cod_nivel3          := em_k_a2000030.f_cod_nivel3;
         g_cod_mon             := em_k_a2000030.f_cod_mon;
         g_num_poliza_grupo    := em_k_a2000030.f_num_poliza_grupo;
         g_fec_efec_spto       := em_k_a2000030.f_fec_efec_spto;
         --
         IF NVL(g_mca_datos_minimos,'N') = g_k_no
         THEN
            IF g_mca_provisional_pol = g_k_si
            THEN
               -- POLIZA RETENIDA
               g_cod_mensaje := 20032;
               g_anx_mensaje := NULL;
               --
               pp_devuelve_error;
               --
            END IF;
         END IF;
         --
      ELSE --La poliza es Fija
         IF g_tip_poliza_tr != g_k_tip_pol_trans_fija AND
            ts_k_g7000001.f_mca_siniestra_marco = g_k_no
         THEN
            -- VALOR INTRODUCIDO NO VALIDO. 20005
            g_cod_mensaje := 20005;
            g_anx_mensaje := NULL;
            --
            pp_devuelve_error;
            --
         END IF;
         IF g_tip_poliza_tr != g_k_tip_pol_trans_fija AND
            ts_k_g7000001.f_mca_siniestra_marco = g_k_si
         THEN
            --
            g_num_spto_apli := g_k_cero;
            --
            --Se Realiza esto para devolver este valor a Java cuando cargue los suplementos de aplicacion
            --
            p_num_spto_apli := g_num_spto_apli;
            --
            trn_k_global.asigna('num_spto_apli', TO_CHAR(g_num_spto_apli));
            --
            /* Obtenemos los datos de la poliza para la apertura del sinistro */
            --
            BEGIN
               --
               l_temporal  :=  ts_k_apertura.f_mca_spto_temp(p_cod_cia       => g_cod_cia      ,
                                                             p_cod_sector    => g_cod_sector   ,
                                                             p_cod_ramo      => g_cod_ramo     ,
                                                             p_cod_modalidad => g_cod_modalidad,
                                                             p_num_poliza    => g_num_poliza   ,
                                                             p_num_apli      => g_num_apli     ,
                                                             p_num_riesgo    => g_num_riesgo   ,
                                                             p_fec_sini      => g_fec_sini     );
               --
               p_num_spto := fp_calcula_num_spto(p_cod_cia     => g_cod_cia   ,
                                                 p_num_poliza  => g_num_poliza,
                                                 p_fec_sini    => g_fec_sini  ,
                                                 p_temporal    => l_temporal  ,
                                                 p_hora_sini   => g_hora_sini );
               --
               IF p_num_spto IS NULL
               THEN
                  --
                  em_p_a2000030_1(p_cod_cia            => g_cod_cia            ,
                                  p_num_poliza         => g_num_poliza         ,
                                  p_fecha              => g_fec_sini           ,
                                  p_temporal           => l_temporal           , --S
                                  p_num_spto           => p_num_spto           ,
                                  p_mca_poliza_anulada => l_mca_poliza_anulada ,
                                  p_fec_efec_poliza    => g_fec_efec_poliza    ,
                                  p_fec_vcto_poliza    => g_fec_vcto_poliza    ,
                                  p_fec_emision        => l_fec_emision        ,
                                  p_fec_emision_spto   => l_fec_emision_spto   ,
                                  p_mca_sini_pol_anul  => l_mca_sini_pol_anul  );
                  --
               ELSE
                  --
                  em_k_a2000030.p_lee(p_cod_cia       => g_cod_cia       ,
                                      p_num_poliza    => g_num_poliza    ,
                                      p_num_spto      => p_num_spto      ,
                                      p_num_apli      => g_k_cero        ,
                                      p_num_spto_apli => g_k_cero        );
                  --
                  l_reg := em_k_a2000030.f_devuelve_reg;
                  --
                  l_mca_poliza_anulada := l_reg.mca_poliza_anulada ;
                  g_fec_efec_poliza    := l_reg.fec_efec_poliza    ;
                  g_fec_vcto_poliza    := l_reg.fec_vcto_poliza    ;
                  l_fec_emision        := l_reg.fec_emision        ;
                  l_fec_emision_spto   := l_reg.fec_emision_spto   ;
                  --
                  -- Obtencion de la mca_sini_pol_anul
                  IF l_reg.tip_spto != g_k_nueva_emision
                  THEN
                     --
                     em_k_a2991800.p_lee_tip_ambito(p_cod_cia       => g_cod_cia         ,
                                                    p_cod_spto      => l_reg.cod_spto    ,
                                                    p_sub_cod_spto  => l_reg.sub_cod_spto,
                                                    p_tip_emision   => g_k_nueva_emision );
                     --
                     l_mca_sini_pol_anul := em_k_a2991800.f_mca_sini_pol_anul;
                     --
                  ELSE
                     --
                     l_mca_sini_pol_anul := g_k_no;
                     --
                  END IF;
                  --
               END IF;
               --
            EXCEPTION
            WHEN OTHERS
            THEN
               --
               IF ts_k_apertura.f_poliza_no_vig_no_apli = g_k_si
               THEN
                  --
                  em_p_a2000030_1(g_cod_cia            ,
                                  g_num_poliza         ,
                                  NULL                 ,
                                  l_temporal           ,
                                  p_num_spto           ,
                                  l_mca_poliza_anulada ,
                                  g_fec_efec_poliza    ,
                                  g_fec_vcto_poliza    ,
                                  l_fec_emision        ,
                                  l_fec_emision_spto   ,
                                  l_mca_sini_pol_anul  );
                  --
                  IF  g_fec_efec_poliza > g_fec_sini
                  OR (fp_valida_fecha_hora(p_cod_cia       => g_cod_cia   ,
                                           p_num_poliza    => g_num_poliza,
                                           p_num_spto      => p_num_spto  ,
                                           p_num_apli      => g_k_cero    ,
                                           p_num_spto_apli => g_k_cero    ,
                                           p_fec_sini      => g_fec_sini  ,
                                           p_hora_sini     => g_hora_sini ))
                  THEN
                     --
                     -- LA POLIZA NO ESTA VIGENTE
                     --
                     g_cod_mensaje := 70001214;
                     g_anx_mensaje := ' em_p_a2000030_1';
                     --
                     pp_devuelve_error;
                     --
                  END IF;
                  --
               ELSE
                  --
                  -- LA POLIZA NO ESTA VIGENTE.
                  --
                  g_cod_mensaje := 70001214;
                  g_anx_mensaje := ' em_p_a2000030_1';
                  --
                  pp_devuelve_error;
                  --
               END IF;
               --
            END;
            --
            g_num_spto := p_num_spto;
            trn_k_global.asigna('num_spto', TO_CHAR(g_num_spto));
            --
            em_k_a2000030.p_lee(g_cod_cia,
                                g_num_poliza,
                                g_num_spto,
                                g_num_apli,
                                g_num_spto_apli);
            --
            g_mca_exclusivo       := em_k_a2000030.f_mca_exclusivo;
            g_mca_provisional_pol := em_k_a2000030.f_mca_provisional;
            g_mca_datos_minimos   := em_k_a2000030.f_mca_datos_minimos;
            g_tip_coaseguro       := em_k_a2000030.f_tip_coaseguro;
            g_tip_docum_tomador   := em_k_a2000030.f_tip_docum;
            g_cod_docum_tomador   := em_k_a2000030.f_cod_docum;
            g_cod_agt             := em_k_a2000030.f_cod_agt;
            g_cod_nivel1          := em_k_a2000030.f_cod_nivel1;
            g_cod_nivel2          := em_k_a2000030.f_cod_nivel2;
            g_cod_nivel3          := em_k_a2000030.f_cod_nivel3;
            g_cod_mon             := em_k_a2000030.f_cod_mon;
            g_num_poliza_grupo    := em_k_a2000030.f_num_poliza_grupo;
            g_fec_efec_spto       := em_k_a2000030.f_fec_efec_spto;
            --
            /* - Control de Acceso a Datos - */
            --
            pp_control_acceso_general;
            --
            IF ts_k_apertura.f_aper_sini_a_futuro =  trn.NO AND g_fec_sini > SYSDATE
            THEN
               --
               g_cod_mensaje := 70001255;
               g_anx_mensaje := ' ';
               --
               pp_devuelve_error;
               --
            END IF;
            --
            IF l_mca_poliza_anulada = g_k_si AND l_mca_sini_pol_anul = g_k_no
            THEN
               -- POLIZA SUPLEMENTO ANULADO
               g_cod_mensaje := 20043;
               g_anx_mensaje := NULL;
               --
               pp_devuelve_error;
            ELSIF l_mca_poliza_anulada = g_k_si AND l_mca_sini_pol_anul = g_k_si AND g_fec_sini> g_fec_efec_spto
            THEN
               -- POLIZA SUPLEMENTO ANULADO
               g_cod_mensaje := 20043;
               g_anx_mensaje := NULL;
               --
               pp_devuelve_error;
            END IF;
            --
            IF NVL(g_mca_datos_minimos,g_k_no) = g_k_no
            THEN
               --
               IF g_mca_provisional_pol = g_k_si
               THEN
                  -- POLIZA RETENIDA
                  g_cod_mensaje := 20032;
                  g_anx_mensaje := NULL;
                  --
                  pp_devuelve_error;
                  --
               END IF;
               --
            ELSIF NVL(g_mca_datos_minimos,g_k_no) = g_k_si AND g_mca_provisional_pol = g_k_si
            THEN
               --
               g_tip_poliza_stro := ts_k_apertura.f_tip_poliza_stro_dmin_ret;
               --
            END IF;
            --
         END IF;
         --
      END IF;
      --
      pp_saca_riesgos;
      --
      p_num_riesgo := NVL(g_num_riesgo,g_k_cero);
      --
      ts_k_apertura.p_v_num_apli (p_num_apli);
      --
      --@mx('F','p_v_num_apli');
      --
   END p_v_num_apli;
   --
   /* --------------------------------------------------------------
   || p_pre_lv_num_riesgo: paso de globales necesarias para llamar al
   || programa de la Consulta de Riesgos (AC299310).
   */ --------------------------------------------------------------
   PROCEDURE p_pre_lv_num_riesgo(p_num_poliza    a2000031.num_poliza    %TYPE,
                                 p_num_spto      a2000031.num_spto      %TYPE,
                                 p_num_apli      a2000031.num_apli      %TYPE,
                                 p_num_spto_apli a2000031.num_spto_apli %TYPE,
                                 p_num_riesgo    a2000031.num_riesgo    %TYPE,
                                 p_fec_sini      a7000900.fec_sini      %TYPE)
   IS
   BEGIN
      --
      --@mx('I','p_pre_lv_num_riesgo');
      --
      trn_k_global.asigna('c_externo','S');
      trn_k_global.asigna('c_cod_ramo',g_cod_ramo);
      trn_k_global.asigna('c_num_poliza',p_num_poliza);
      trn_k_global.asigna('c_num_spto',p_num_spto);
      trn_k_global.asigna('c_num_apli',p_num_apli);
      trn_k_global.asigna('c_num_spto_apli',p_num_spto_apli);
      trn_k_global.asigna('c_num_riesgo',p_num_riesgo);
      trn_k_global.asigna('c_consulta','F');
      trn_k_global.asigna('c_mca_poliza','P');
      trn_k_global.asigna('c_fecha_consulta',TO_CHAR(p_fec_sini,'ddMMyyyy'));
      -- trn_k_global.asigna('c_fecha_consulta',TO_CHAR(TRUNC(SYSDATE),'ddMMyyyy'));
      --
      -- se añade la carga de la global c_modulo_llamador para que la consulta de
      -- riesgos tenga en cuenta que la llmada se hace desde siniestros.
      -- MARIANJ - 11/03/2009
      trn_k_global.asigna('c_modulo_llamador','TS');
      --
      --@mx('F','p_pre_lv_num_riesgo');
      --
   END p_pre_lv_num_riesgo;
   --
   /* --------------------------------------------------------------
   || p_pre_lv_num_riesgo: borra las globales que se han utilizado para
   || llamar al programa de la Consulta de Riesgos (AC299310).
   */ --------------------------------------------------------------
   PROCEDURE p_post_lv_num_riesgo
   IS
   BEGIN
      --
      --@mx('I','p_post_lv_num_riesgo');
      --
      trn_k_global.borra_variable('c_externo');
      trn_k_global.borra_variable('c_cod_ramo');
      trn_k_global.borra_variable('c_num_poliza');
      trn_k_global.borra_variable('c_num_spto');
      trn_k_global.borra_variable('c_num_apli');
      trn_k_global.borra_variable('c_num_spto_apli');
      trn_k_global.borra_variable('c_num_riesgo');
      trn_k_global.borra_variable('c_consulta');
      trn_k_global.borra_variable('c_mca_poliza');
      trn_k_global.borra_variable('c_fecha_consulta');
      --
      -- MARIANJ - 11/03/2009
      trn_k_global.borra_variable('c_modulo_llamador');
      --
      --@mx('F','p_post_lv_num_riesgo');
      --
   END p_post_lv_num_riesgo;
   --
   /* --------------------------------------------------------------
   || Valida el Riesgo
   || Saca el nombre del riesgo, marca exclusivo......
   || a la fecha,....
   */ --------------------------------------------------------------
   PROCEDURE p_v_num_riesgo(p_num_riesgo         IN a7000900.num_riesgo            %TYPE,
                            p_nom_riesgo         IN OUT a2000031.nom_riesgo        %TYPE,
                            p_hay_mas_siniestros IN OUT a7000900.tip_est_sini      %TYPE,
                            p_exclusivo          IN OUT a7000900.mca_exclusivo     %TYPE,
                            p_nom_situacion      IN OUT a5020500.nom_situacion     %TYPE,
                            p_tip_docum_tomador  IN OUT a7000900.tip_docum_tomador %TYPE,
                            p_cod_docum_tomador  IN OUT a7000900.cod_docum_tomador %TYPE,
                            p_nom_tomador        IN OUT v1001390.nom_completo      %TYPE,
                            p_cod_agt            IN OUT a7000900.cod_agt           %TYPE,
                            p_nom_agente         IN OUT v1001390.nom_completo      %TYPE)
  IS
      --
      l_fec_sini a7000900.fec_sini %TYPE;
      --
      l_mca_baja_riesgo a2000031.mca_baja_riesgo %TYPE;
      l_temporal        VARCHAR2(1) := 'S';
      --
      l_cod_act_tercero v1001390.cod_act_tercero %TYPE := 1;
      l_cod_tercero     v1001390.cod_tercero     %TYPE;
      l_cod_docum       v1001390.cod_docum       %TYPE;
      l_tip_docum       v1001390.tip_docum       %TYPE;
      --
      l_tip_spto        a2000030.tip_spto           %TYPE;
      --
      l_no_existe EXCEPTION;
      PRAGMA EXCEPTION_INIT(l_no_existe, -20001);
      --
   BEGIN
      --
      --@mx('I','p_v_num_riesgo');
      --
      IF p_num_riesgo IS NULL
      THEN
         g_cod_mensaje := 20003;
         g_anx_mensaje := ' p_v_num_riesgo';
         --
         pp_devuelve_error;
         --
      END IF;
      --
      g_num_riesgo        := p_num_riesgo;
      --
      p_tip_docum_tomador := g_tip_docum_tomador;
      p_cod_docum_tomador := g_cod_docum_tomador;
      p_cod_agt           := g_cod_agt;
      --
      IF g_tip_coaseguro = 1 -- Coaseguro Cedido
      THEN
         IF ts_f_a2000100(g_cod_cia,
                          g_num_poliza,
                          g_num_spto) = 'N' -- Si no hay distribucion
         THEN
            -- POLIZA CON COASEGURO Y SIN DISTRIBUCION
            g_cod_mensaje := 20095;
            g_anx_mensaje := NULL;
            --
            pp_devuelve_error;
            --
         END IF; -- Si tiene distribucion de Coaseguro
         --
      END IF; -- Si tiene Coaseguro Cedido
      --
      -- Se recupera el maximo endoso para el riesgo a la fecha del siniestro
      -- Primero se mira si acepta siniestros fuera de vigencia.
      --
      l_fec_sini := g_fec_sini;
      --
      /* Si la fecha de vencimiento es menor que la fecha del siniestro. Se
         mirará si la póliza tiene aplicaciones, si la función f_riesgo_no_vigente
         es = 'S', se perimitirá .
      */
      --
      IF g_fec_vcto_poliza < g_fec_sini
      THEN
         --
         IF g_tip_poliza_tr !='F' AND
            ts_k_esp_instalacion.f_riesgo_no_vigente = 'S'
         THEN
            --
            l_fec_sini := g_fec_vcto_poliza;
            --
         END IF;
         --
      END IF;
      --
      l_temporal  :=  ts_k_apertura.f_mca_spto_temp(p_cod_cia       => g_cod_cia      ,
                                                    p_cod_sector    => g_cod_sector   ,
                                                    p_cod_ramo      => g_cod_ramo     ,
                                                    p_cod_modalidad => g_cod_modalidad,
                                                    p_num_poliza    => g_num_poliza   ,
                                                    p_num_apli      => g_num_apli     ,
                                                    p_num_riesgo    => g_num_riesgo   ,
                                                    p_fec_sini      => g_fec_sini     );
      --
      IF         g_tip_poliza_tr                     = g_k_tip_pol_trans_fija
         OR (    g_tip_poliza_tr                    <> g_k_tip_pol_trans_fija
             AND g_num_apli                          = g_k_cero
             AND ts_k_g7000001.f_mca_siniestra_marco = g_k_si                )
      THEN
         --
         g_num_spto_riesgo := em_f_max_spto_a2000031_1(g_cod_cia,
                                                       g_num_poliza,
                                                       g_num_riesgo,
                                                       l_fec_sini,
                                                       l_temporal);
         --
         IF g_num_spto_riesgo IS NULL
         THEN
           --
           IF ts_k_apertura.f_riesgo_no_vig_no_apli = 'S'
           THEN
             l_fec_sini := g_fec_vcto_poliza;
           END IF;
           --
           g_num_spto_riesgo := em_f_max_spto_a2000031_1(g_cod_cia,
                                                         g_num_poliza,
                                                         g_num_riesgo,
                                                         l_fec_sini,
                                                         l_temporal);
           --
         END IF;
         --
         g_num_spto_apli_riesgo := 0;
         --
      ELSE
         --
         g_num_spto_apli_riesgo := em_f_max_spto_apli_a31(g_cod_cia,
                                                          g_num_poliza,
                                                          g_num_apli,
                                                          g_num_riesgo,
                                                          l_fec_sini,
                                                          l_temporal);
         --
         g_num_spto_riesgo := trn_k_global.devuelve('num_spto_tr');
         --
      END IF;
      --
      /* Voy a mirar si el suplemento de riesgo que voy siniestrar esta
      retenido. */
      --
      BEGIN
         --
         em_k_a2000030.p_lee(g_cod_cia,
                             g_num_poliza,
                             g_num_spto_riesgo,
                             g_num_apli,
                             g_num_spto_apli);
         --
      EXCEPTION
      WHEN l_no_existe
      THEN
        -- NO EXISTE EL RIESGO PARA LA POLIZA Y/O APL. O NO ESTA VIGENTE
        g_cod_mensaje := 70001193;
        g_anx_mensaje := TO_CHAR(l_fec_sini, trn_k_g0000000.f_txt_formato_fecha);
        --
        pp_devuelve_error;
        --
      END;
      --
      g_mca_exclusivo_riesgo := em_k_a2000030.f_mca_exclusivo;
      --
      g_mca_datos_minimos := em_k_a2000030.f_mca_datos_minimos;
      --
      IF g_mca_exclusivo = 'S' OR g_mca_exclusivo_riesgo = 'S'
      THEN
         p_exclusivo := 'S';
      ELSE
         p_exclusivo := 'N';
      END IF;
      --
      /* Con el suplemento del riesgo Se vuelve a ir a la 30 para saber si
      el suplemento del riesgo esta retenido por control tecnico, ya que este
      suplemento puede ser distinto que el de la poliza.*/
      --
      g_mca_provisional_pol := em_k_a2000030.f_mca_provisional;
      --
      IF NVL(g_mca_datos_minimos,'N') = 'N'
      THEN
         IF NVL(g_mca_provisional_pol,'N') = 'S'
         THEN
            -- POLIZA RETENIDA POR CONTROL TECNICO
            g_cod_mensaje := 20032;
            g_anx_mensaje := NULL;
            --
            pp_devuelve_error;
            --
         END IF;
         --
      END IF;
      --
      /* Recupero los datos del riesgo de la tabla A2000031 */
      --
      BEGIN
         --
         -- se modifica para pasar el num_spto_apli_riesgo en lugar del num_spto_apli.
         -- (MARIANJ - 11/03/2009)
           em_p_a2000031_datos_fecha(g_cod_cia,
                                     g_num_poliza,
                                     g_num_spto_riesgo,
                                     g_num_apli,
                                     g_num_spto_apli_riesgo, -- g_num_spto_apli.
                                     g_num_riesgo,
                                     l_fec_sini,
                                     g_cod_modalidad,
                                     g_fec_efec_riesgo,
                                     g_fec_vcto_riesgo,
                                     l_mca_baja_riesgo,
                                     g_nom_riesgo);
         --
         p_nom_riesgo := g_nom_riesgo;
         --
      EXCEPTION
      WHEN l_no_existe
      THEN
         -- NO EXISTE EL RIESGO PARA LA POLIZA Y/O APL. O NO ESTA VIGENTE
         g_cod_mensaje := 70001193;
         g_anx_mensaje := TO_CHAR(l_fec_sini, trn_k_g0000000.f_txt_formato_fecha);
         --
         pp_devuelve_error;
         --
      END;
      --
      IF NVL(l_mca_baja_riesgo,'N') = 'S'
      THEN
         -- EL RIESGO ESTA DADO DE BAJA
         --
         g_cod_mensaje := 20000;
         g_anx_mensaje := fi_txt_mensaje(23000013);
         --
         pp_devuelve_error;
         --
      END IF;
      --
      BEGIN
         --
         p_hay_mas_siniestros := 'N';
         --
         ts_k_a7000900.p_siniestro_a_misma_fecha(g_cod_cia,
                                                 g_num_poliza,
                                                 g_num_apli,
                                                 g_num_riesgo,
                                                 g_fec_sini);
         --
      EXCEPTION
      WHEN OTHERS
      THEN
         p_hay_mas_siniestros := 'S';
      END;
      /* Se obtiene la situacion del recibo y su descripcion */
      --
      g_tip_situacion := ts_f_llama_situ_poliza(g_cod_cia,
                                                g_num_poliza,
                                                g_num_apli,
                                                g_fec_sini);
      --
      IF g_tip_situacion IS NULL
       THEN
        --
        p_nom_situacion := '????';
        --
      ELSE
        --
        gc_k_a5020500.p_lee(g_tip_situacion);
        --
        p_nom_situacion := gc_k_a5020500.f_nom_situacion;
        --
      END IF;
      --
      /* Obtengo el nombre y apellido del  tomador de la poliza */
      --
      dc_p_nom_ape_completo(g_cod_cia,
                            g_tip_docum_tomador,
                            g_cod_docum_tomador,
                            l_cod_act_tercero,
                            p_nom_tomador,
                            l_cod_tercero);
      /* Obtengo el nombre y apellidos del agente de la poliza */
      --
      l_cod_act_tercero := 2;
      --
      dc_p_nom_ape_completo_1(g_cod_cia,
                              g_cod_agt,
                              l_cod_act_tercero,
                              p_nom_agente,
                              l_tip_docum,
                              l_cod_docum);
      --
      /* FALTA llamada al p_ver_benef_a2000060 */
      pp_saca_asegurado;
      --
      /* Se modifica el f_determina_periodo por em_k_periodo Junio 2003
      --
      g_num_periodo := em_f_determina_periodo(g_fec_efec_poliza,
                                              g_fec_vcto_poliza,
                                              g_fec_sini);
      */
      --
      g_num_periodo := em_k_periodos.f_en_cual ( g_cod_cia         ,
                                                g_num_poliza       ,
                                                g_num_spto         ,
                                                g_num_apli         ,
                                                g_fec_efec_poliza  ,
                                                g_fec_vcto_poliza  ,
                                                g_fec_sini         ,
                                                l_tip_spto         );
      --
      IF        g_tip_poliza_tr                     = g_k_tip_pol_trans_fija
         OR (   g_tip_poliza_tr                    <> g_k_tip_pol_trans_fija
            AND g_num_apli                          = g_k_cero
            AND ts_k_g7000001.f_mca_siniestra_marco = g_k_si                )
      THEN
         --
         g_max_spto_40 := em_f_max_spto_a2000040(g_cod_cia,
                                                 g_num_poliza,
                                                 g_num_riesgo,
                                                 g_num_spto_riesgo,
                                                 l_fec_sini,
                                                 'S',
                                                 g_cod_ramo);
         --
         g_max_spto_apli_40 := g_num_spto_apli;
         --
      ELSE
         --
         /*22/11/2005.
            Modificado el g_max_spto_40 ya que se le estaba asignando
           el g_num_spto_riesgo y debe de ser el g_num_spto.
            También los parámetros de la función, en vez del g_spto_riesgo
           se pasa el g_num_spto y en vez del g_num_spto_apli el
           g_num_spto_riesgo. */
         --
         g_max_spto_40 := g_num_spto;
         --
         -- si la póliza es de transportes se recupera el num_spto_apli_riesgo en
         --lugar del num_spto_apli. (MARIANJ - 11/03/2009)
         --
          g_max_spto_apli_40 := em_f_max_spto_apli_a40(g_cod_cia,
                                                      g_num_poliza,
                                                      g_num_spto,
                                                      g_num_apli,
                                                      g_num_spto_apli_riesgo, --g_num_spto_riesgo (11/03/2009)
                                                      g_cod_ramo);
         --
      END IF;
      --
      trn_k_global.asigna('cod_cia',   TO_CHAR(g_cod_cia));
      trn_k_global.asigna('cod_sector',TO_CHAR(g_cod_sector));
      trn_k_global.asigna('cod_ramo',  TO_CHAR(g_cod_ramo));
      --
      pp_obtener_tramitador;
      --
      pp_asigna_globales;
      --
      /* 28-12-2004.
         Se elimina la condicion del IF g_num_sini = 0, ya que hay que calcular siempre
        el número de siniestro por que se ha introducido un numero de poliza que no es
        correcto o por que salta un C.Tecnico de nivel 1 y al corregir errores podemos
        cambiar la póliza por lo que hay que volver a obtener el numero.*/
      --
      --IF NVL(g_num_sini,0) = 0
      --THEN
      --
      /* 08/03/2006. Se crea una funcion, fp_num_sini, que devuelve el numero de siniestro
        que corresponde, controlando que si el número ya está siendo utilizado se busca otro
        número nuevo.*/
      --
      g_num_sini := fp_num_sini;
      --
      /*g_num_sini := ts_k_recupera_numero_sini.f_numero_siniestro(g_cod_cia,
                                                                 g_cod_sector,
                                                                 g_cod_ramo,
                                                                 g_cod_nivel3);
      */
      --
      --@mx('Numero de Siniestro obtenido : ',g_num_sini);
      --
      --END IF;
      --
      g_tip_causa := '1'; -- Causas de Siniestro
      --
      trn_k_global.asigna('cod_grp_est'     ,'2');
      trn_k_global.asigna('tip_causa'       , g_tip_causa);
      trn_k_global.asigna('tip_causa_origen', g_tip_causa);
      --
      trn_k_global.asigna('num_sini',         TO_CHAR(g_num_sini));
      --
      ts_k_apertura.p_v_num_riesgo (p_num_riesgo);
      -- Establecemos la fecha de vencimiento p?blico del riesgo para introducir en las variables
      -- globales en caso de apertura de siniestros
      trn_k_global.asigna('fec_vcto_riesgo_pub',
         TO_CHAR(em_k_cons_datos_fijos.f_fec_vcto_riesgo_publico(p_hora_desde             => NULL                                 ,
                                                                 p_fec_vcto_riesgo        => g_fec_vcto_riesgo                    ,
                                                                 p_fec_vcto_spto_publico  => em_k_a2000030.f_fec_vcto_spto_publico)
                 ,'DDMMYYYY'));
      --
      --@mx('F','p_v_num_riesgo');
      --
   END p_v_num_riesgo;
   --
   /**-------------------- DESCRIPCION --------------------
   || Procedimiento.
   || Funcion para recuperar el tip_docum y el cod_docum y el nombre del asegurado.
   */ -----------------------------------------------------
   PROCEDURE p_recupera_asegurado (p_cod_cia            IN a7000900.cod_cia                %TYPE,
                                   p_num_poliza         IN a7000900.num_poliza             %TYPE,
                                   p_num_riesgo         IN a7000900.num_riesgo             %TYPE,
                                   p_num_spto_riesgo    IN a7000900.num_spto_riesgo        %TYPE,
                                   p_num_apli           IN a7000900.num_apli               %TYPE,
                                   p_num_spto_apli      IN a7000900.num_spto_apli          %TYPE,
                                   p_cod_docum          IN OUT a7000900.cod_docum_aseg     %TYPE,
                                   p_tip_docum          IN OUT a7000900.tip_docum_aseg     %TYPE,
                                   p_nom_completo       IN OUT a7000900.nom_contacto       %TYPE
                                   )
   IS
   BEGIN
     --
     ts_k_apertura.p_recupera_aseg (p_cod_cia ,
                                    p_num_poliza,
                                    p_num_riesgo,
                                    p_num_spto_riesgo,
                                    p_num_apli ,
                                    p_num_spto_apli ,
                                    p_cod_docum,
                                    p_tip_docum,
                                    p_nom_completo
                                    );
     --
   END p_recupera_asegurado;
   --
   /*--------------------------------------------------------
   || p_recupera_cob: Carga la tabla PL/SQL
   */ --------------------------------------------------------
   PROCEDURE p_recupera_cob IS
      --
   BEGIN
      --
      --@mx('I','p_recupera_cob');
      --
      /* Pregunto por la variable g_num_poliza, porque si es llamado desde fuera
      no tiene asignadas las variables, g necesarias para el cursor */
      --
      IF g_num_poliza IS NULL
      THEN
         g_cod_cia          := trn_k_global.devuelve('cod_cia');
         g_num_poliza       := trn_k_global.devuelve('num_poliza');
         g_max_spto_40      := trn_k_global.devuelve('max_spto_40');
         g_num_spto         := trn_k_global.devuelve('num_spto');
         g_num_apli         := trn_k_global.devuelve('num_apli');
         g_max_spto_apli_40 := trn_k_global.devuelve('max_spto_apli_40');
         g_num_riesgo       := trn_k_global.devuelve('num_riesgo');
         g_num_periodo      := trn_k_global.devuelve('num_periodo');
         g_cod_ramo         := trn_k_global.devuelve('cod_ramo');
         g_cod_idioma       := trn_k_global.devuelve('cod_idioma');
         -- cmiraor
         g_num_spto_riesgo   := trn_k_global.devuelve('num_spto_riesgo');
         --
         g_num_sini         := trn_k_global.devuelve('num_sini');
         -- cmiraor, se comenta para leee de la a2000031 cuando el tratamiento
         -- es distinto a vida
         /*
         ts_k_a7000900.p_lee_a7000900(g_cod_cia, g_num_sini);
         g_cod_modalidad    := ts_k_a7000900.f_cod_modalidad;
         */
         --
         --
      END IF;
      --
      IF g_cod_tratamiento IS NULL
      THEN
         dc_k_a1001800.p_lee(g_cod_cia,
                             g_cod_ramo);
         --
         g_cod_sector := dc_k_a1001800.f_cod_sector;
         --
         g_cod_tratamiento := dc_k_a1001800.f_cod_tratamiento;
         --
         --
      END IF;
      --
      -- cmiraor
      IF g_cod_tratamiento = em.TRATAMIENTO_VIDA
       THEN
       --
       em_k_a2000031.p_lee(p_cod_cia    => g_cod_cia,
                           p_num_poliza => g_num_poliza,
                           p_num_spto   => g_max_spto_40,
                           p_num_apli   => g_num_apli,
                           p_num_spto_apli => g_max_spto_apli_40,
                           p_num_riesgo => g_num_riesgo);
      --
      g_cod_modalidad := em_k_a2000031.f_cod_modalidad;
      --
      END IF;

      --
      --
      pp_p_query;
      --
      --@mx('F','p_recupera_cob');
      --
   END p_recupera_cob;
   --
   /* -----------------------------------------------------
   || p_devuelve : Devuelve la informacion a la tabla
   */ -----------------------------------------------------
   PROCEDURE p_devuelve(p_num_secu_k          IN OUT NUMBER,
                        p_cod_cob             IN OUT a2000040.cod_cob %TYPE,
                        p_nom_cob             IN OUT a1002150.nom_cob %TYPE,
                        p_cod_cob_relacionada IN OUT a1002150.cod_cob_relacionada %TYPE,
                        p_nom_cob_relacionada IN OUT a1002150.nom_cob %TYPE,
                        p_suma_aseg           IN OUT a2000040.suma_aseg %TYPE,
                        p_val_franquicia      IN OUT VARCHAR2,
                        p_tip_franquicia      IN OUT g1010031.nom_valor %TYPE,
                        p_tip_franquicia_stro IN OUT g1010031.nom_valor %TYPE,
                        p_val_franquicia_min  IN OUT VARCHAR2,
                        p_tip_franquicia_min  IN OUT g1010031.nom_valor %TYPE,
                        p_val_franquicia_max  IN OUT VARCHAR2,
                        p_tip_franquicia_max  IN OUT g1010031.nom_valor %TYPE,
                        p_deducible           IN OUT a2000040.mca_baja_cob %TYPE,
                        p_cod_mon_iso         IN OUT a1000400.cod_mon_iso %TYPE) IS
   --
   l_num_decimales_mon     a1000400.num_decimales%TYPE;
   l_num_decimales         NUMBER;
   l_num_decimales_limites NUMBER;
   l_cod_modalidad         a1002150.cod_modalidad %TYPE;
   --
   BEGIN
      --
      --@mx('I','p_devuelve');
      --
      IF g_cod_tratamiento != 'V'
      THEN
         l_cod_modalidad := 99999;
      ELSE
         l_cod_modalidad := g_cod_modalidad;
      END IF;
      --
      IF g_fila_devuelve IS NULL
      THEN
         --
         IF g_tb_a2000040.EXISTS(g_tb_a2000040.FIRST)
         THEN
            --
            g_fila_devuelve := g_tb_a2000040.FIRST;
            --
            p_num_secu_k := g_fila_devuelve;
            --
            pp_post_query(g_fila_devuelve);
            --
            p_cod_cob             := g_tb_a2000040(g_fila_devuelve).cod_cob;
            p_nom_cob             := g_tb_a2000040(g_fila_devuelve).nom_cob;
            p_cod_cob_relacionada := g_tb_a2000040(g_fila_devuelve)
                                    .cod_cob_relacionada;
            p_nom_cob_relacionada := g_tb_a2000040(g_fila_devuelve)
                                    .nom_cob_relacionada;
            p_suma_aseg           := g_tb_a2000040(g_fila_devuelve).suma_aseg;
            p_val_franquicia      := g_tb_a2000040(g_fila_devuelve).val_franquicia;
            p_tip_franquicia      := g_tb_a2000040(g_fila_devuelve)
                                    .tip_franquicia;
            p_tip_franquicia_stro := g_tb_a2000040(g_fila_devuelve)
                                    .tip_franquicia_stro;
            p_val_franquicia_min  := g_tb_a2000040(g_fila_devuelve).val_franquicia_min;
            p_tip_franquicia_min  := g_tb_a2000040(g_fila_devuelve)
                                    .tip_franquicia_min;
            p_val_franquicia_max  := g_tb_a2000040(g_fila_devuelve).val_franquicia_max;
            p_tip_franquicia_max  := g_tb_a2000040(g_fila_devuelve)
                                    .tip_franquicia_max;
            p_deducible           := g_tb_a2000040(g_fila_devuelve).deducible;
            --
            dc_k_a1000400.p_lee(g_tb_a2000040(g_fila_devuelve).cod_mon_capital);
            p_cod_mon_iso         := dc_k_a1000400.f_cod_mon_iso;
            l_num_decimales_mon   := dc_k_a1000400.f_num_decimales;
            --
            IF g_tb_a2000040(g_fila_devuelve).cod_franquicia IS NOT NULL
            THEN
                em_k_a2100700.p_lee(g_cod_cia,
                                    g_tb_a2000040(g_fila_devuelve).cod_mon_capital,
                                    g_tb_a2000040(g_fila_devuelve).cod_franquicia);
                --
                IF em_k_a2100700.f_tip_franquicia = 1 OR
                   em_k_a2100700.f_tip_franquicia = 2
                THEN
                   l_num_decimales := l_num_decimales_mon;
                ELSE
                   l_num_decimales := '0';
                END IF;
                --
                em_k_a2100701.p_lee(g_cod_cia,
                                    g_cod_ramo,
                                    l_cod_modalidad,
                                    g_tb_a2000040(g_fila_devuelve).cod_cob,
                                    g_cod_tip_vehi,
                                    g_tb_a2000040(g_fila_devuelve).cod_franquicia,
                                    g_tb_a2000040(g_fila_devuelve).cod_mon_capital,
                                    g_fec_validez);
                --
                IF (em_k_a2100701.f_tip_franquicia_min = 1 OR
                    em_k_a2100701.f_tip_franquicia_min = 2) AND
                   (em_k_a2100701.f_tip_franquicia_max = 1 OR
                    em_k_a2100701.f_tip_franquicia_max = 2)
                THEN
                   l_num_decimales_limites := l_num_decimales_mon;
                ELSE
                   l_num_decimales_limites := '0';
                END IF;
            ELSE
                l_num_decimales := l_num_decimales_mon;
                l_num_decimales_limites := l_num_decimales_mon;
            END IF;
            --
         ELSE
            --Tabla  vacia
            --
            p_num_secu_k := NULL;
            --
            p_cod_cob             := NULL;
            p_nom_cob             := NULL;
            p_cod_cob_relacionada := NULL;
            p_nom_cob_relacionada := NULL;
            p_suma_aseg           := NULL;
            p_val_franquicia      := NULL;
            p_tip_franquicia      := NULL;
            p_tip_franquicia_stro := NULL;
            p_val_franquicia_min  := NULL;
            p_tip_franquicia_min  := NULL;
            p_val_franquicia_max  := NULL;
            p_tip_franquicia_max  := NULL;
            p_deducible           := NULL;
            --
            g_fila_devuelve := g_max_secu_query;
            --
         END IF;
         --
      ELSIF g_fila_devuelve != g_max_secu_query -- Hay pero no es el primero
      THEN
         --
         g_fila_devuelve := g_tb_a2000040.NEXT(g_fila_devuelve);
         --
         pp_post_query(g_fila_devuelve);
         --
         p_num_secu_k := g_fila_devuelve;
         --
         p_cod_cob             := g_tb_a2000040(g_fila_devuelve).cod_cob;
         p_nom_cob             := g_tb_a2000040(g_fila_devuelve).nom_cob;
         p_cod_cob_relacionada := g_tb_a2000040(g_fila_devuelve)
                                 .cod_cob_relacionada;
         p_nom_cob_relacionada := g_tb_a2000040(g_fila_devuelve)
                                 .nom_cob_relacionada;
         p_suma_aseg           := g_tb_a2000040(g_fila_devuelve).suma_aseg;
         p_val_franquicia      := g_tb_a2000040(g_fila_devuelve).val_franquicia;
         p_tip_franquicia      := g_tb_a2000040(g_fila_devuelve).tip_franquicia;
         p_tip_franquicia_stro := g_tb_a2000040(g_fila_devuelve)
                                 .tip_franquicia_stro;
         p_val_franquicia_min  := g_tb_a2000040(g_fila_devuelve).val_franquicia_min;
         p_tip_franquicia_min  := g_tb_a2000040(g_fila_devuelve)
                                 .tip_franquicia_min;
         p_val_franquicia_max  := g_tb_a2000040(g_fila_devuelve).val_franquicia_max;
         p_tip_franquicia_max  := g_tb_a2000040(g_fila_devuelve)
                                 .tip_franquicia_max;
         p_deducible := g_tb_a2000040(g_fila_devuelve).deducible;
         --
         dc_k_a1000400.p_lee(g_tb_a2000040(g_fila_devuelve).cod_mon_capital);
         p_cod_mon_iso         := dc_k_a1000400.f_cod_mon_iso;
         l_num_decimales_mon   := dc_k_a1000400.f_num_decimales;
         --
         IF g_tb_a2000040(g_fila_devuelve).cod_franquicia IS NOT NULL
         THEN
             em_k_a2100700.p_lee(g_cod_cia,
                                 g_tb_a2000040(g_fila_devuelve).cod_mon_capital,
                                 g_tb_a2000040(g_fila_devuelve).cod_franquicia);
             --
             IF em_k_a2100700.f_tip_franquicia = 1 OR
                em_k_a2100700.f_tip_franquicia = 2
             THEN
                l_num_decimales := l_num_decimales_mon;
             ELSE
                l_num_decimales := '0';
             END IF;
             --
             em_k_a2100701.p_lee(g_cod_cia,
                                 g_cod_ramo,
                                 l_cod_modalidad,
                                 g_tb_a2000040(g_fila_devuelve).cod_cob,
                                 g_cod_tip_vehi,
                                 g_tb_a2000040(g_fila_devuelve).cod_franquicia,
                                 g_tb_a2000040(g_fila_devuelve).cod_mon_capital,
                                 g_fec_validez);
             --
             IF (em_k_a2100701.f_tip_franquicia_min = 1 OR
                 em_k_a2100701.f_tip_franquicia_min = 2) AND
                (em_k_a2100701.f_tip_franquicia_max = 1 OR
                 em_k_a2100701.f_tip_franquicia_max = 2)
             THEN
                l_num_decimales_limites := l_num_decimales_mon;
             ELSE
                l_num_decimales_limites := '0';
             END IF;
            --
         ELSE
            l_num_decimales := l_num_decimales_mon;
            l_num_decimales_limites := l_num_decimales_mon;
         END IF;
         --
      ELSE
         -- Es el ultimo porque es igual a la maxima fila
         --
         p_num_secu_k := NULL;
         --
         p_cod_cob             := NULL;
         p_nom_cob             := NULL;
         p_cod_cob_relacionada := NULL;
         p_nom_cob_relacionada := NULL;
         p_suma_aseg           := NULL;
         p_val_franquicia      := NULL;
         p_tip_franquicia      := NULL;
         p_tip_franquicia_stro := NULL;
         p_val_franquicia_min  := NULL;
         p_tip_franquicia_min  := NULL;
         p_val_franquicia_max  := NULL;
         p_tip_franquicia_max  := NULL;
         p_deducible           := NULL;
         --
      END IF;
      --
      IF p_tip_franquicia <> '2'
      THEN
         p_cod_mon_iso    := NULL;
      END IF;
      --
      IF l_num_decimales IS NULL
      THEN
         l_num_decimales := '0';
      END IF;
      --
      IF l_num_decimales_limites IS NULL
      THEN
         l_num_decimales_limites := '0';
      END IF;
      --
      p_val_franquicia := dc_k_a1000400.f_redondea_importe_fmt(p_val_franquicia,
                                                            l_num_decimales,
                                                            9);
/*      p_val_franquicia_max := dc_k_a1000400.f_redondea_importe_fmt(p_val_franquicia_max,
                                                            l_num_decimales_limites,
                                                            9);
      p_val_franquicia_min := dc_k_a1000400.f_redondea_importe_fmt(p_val_franquicia_min,
                                                            l_num_decimales_limites,
                                                            9);
      --            */
      IF TO_NUMBER(REPLACE(REPLACE(p_val_franquicia,','),'.'),'999999999') = 0
      THEN
         p_cod_mon_iso         := NULL;
         p_val_franquicia      := NULL;
         p_tip_franquicia      := NULL;
         p_tip_franquicia_stro := NULL;
      END IF;
      --
      IF TO_NUMBER(REPLACE(REPLACE(p_val_franquicia_min,','),'.'),'999999999') = 0
      THEN
         p_val_franquicia_min  := NULL;
         p_tip_franquicia_min  := NULL;
      END IF;
      --
      IF TO_NUMBER(REPLACE(REPLACE(p_val_franquicia_max,','),'.'),'999999999') = 0
      THEN
         p_val_franquicia_max  := NULL;
         p_tip_franquicia_max  := NULL;
      END IF;
      --
      --@mx('F','p_devuelve');
      --
   END p_devuelve;
   --
   /* --------------------------------------------------------------
   || Menu de opciones 2
   || Asigna las variables que tiene hasta ahora
   || a globales para que se pueda llamar a alguna opcion
   */ --------------------------------------------------------------
   --
   PROCEDURE p_asigna_globales_menu_2(p_cod_pgm_call g1010131.cod_pgm_call %TYPE)
   IS
   BEGIN
      --
      --@mx('I','p_asigna_globales_menu_2');
      --
      trn_k_global.asigna('c_mca_poliza'     , 'P');
      trn_k_global.asigna('c_consulta'       , 'S');
      trn_k_global.asigna('c_externo'        , 'S');
      trn_k_global.asigna('c_cod_cia'        , g_cod_cia);
      trn_k_global.asigna('c_num_poliza'     , g_num_poliza);
      trn_k_global.asigna('c_num_spto'       , g_num_spto);
      trn_k_global.asigna('c_num_apli'       , g_num_apli);
      trn_k_global.asigna('c_num_spto_apli'  , g_num_spto_apli);
      trn_k_global.asigna('c_fecha_consulta' , '');
      trn_k_global.asigna('c_cod_tratamiento', g_cod_tratamiento);
      trn_k_global.asigna('c_cod_ramo'       , g_cod_ramo);
      trn_k_global.asigna('s_consulta'       , 'S');
      trn_k_global.asigna('c_num_sini'       , g_num_sini);
      trn_k_global.asigna('c_num_riesgo'     , g_num_riesgo);
      trn_k_global.asigna('c_nom_riesgo'     , g_nom_riesgo);
      trn_k_global.asigna('c_fec_efec_riesgo', TO_CHAR(g_fec_efec_riesgo, 'ddmmyyyy'));
      trn_k_global.asigna('c_fec_vcto_riesgo', TO_CHAR(g_fec_vcto_riesgo, 'ddmmyyyy'));
      trn_k_global.asigna('c_mca_sini'       , trn.SI);
      --
      --@mx('F','p_asigna_globales_menu_2');
      --
   END;
   --
   /* --------------------------------------------------------------
   || Borra   opciones 2
   || Borra las variables que se asignan en el menu de opciones 2
   */ --------------------------------------------------------------
   --
   PROCEDURE p_borra_globales_menu_2(p_cod_pgm_call g1010131.cod_pgm_call %TYPE)
   IS
   BEGIN
      --
      --@mx('I','p_borra_globales_menu_2');
      --
      trn_k_global.borra_variable('c_mca_poliza');
      trn_k_global.borra_variable('c_consulta');
      trn_k_global.borra_variable('c_externo');
      trn_k_global.borra_variable('c_cod_cia');
      trn_k_global.borra_variable('c_num_poliza');
      trn_k_global.borra_variable('c_num_spto');
      trn_k_global.borra_variable('c_num_apli');
      trn_k_global.borra_variable('c_num_spto_apli');
      trn_k_global.borra_variable('c_fecha_consulta');
      trn_k_global.borra_variable('c_cod_tratamiento');
      trn_k_global.borra_variable('c_cod_ramo');
      trn_k_global.borra_variable('s_consulta');
      trn_k_global.borra_variable('c_num_sini');
      trn_k_global.borra_variable('c_num_riesgo');
      trn_k_global.borra_variable('c_nom_riesgo');
      trn_k_global.borra_variable('c_fec_efec_riesgo');
      trn_k_global.borra_variable('c_fec_vcto_riesgo');
      trn_k_global.borra_variable('c_mca_sini');
      --
      --@mx('F','p_borra_globales_menu_2');
      --
   END;
   --
   /*
   || Validacion del codigo de evento
   */
   --
   --{{ TG_PPUB
   --}} TG_PPUB
   --
   /*
   || Validacion del codigo de evento
   */
   --
   PROCEDURE p_v_cod_evento(p_cod_evento           IN a7990700.cod_evento              %TYPE,
                            p_nom_evento           IN OUT a7990700.nom_evento          %TYPE,
                            p_mca_hay_ctrl_tecnico IN OUT VARCHAR2                          ,
                            p_ape_contacto         IN OUT a7000900.ape_contacto        %TYPE,
                            p_nom_contacto         IN OUT a7000900.nom_contacto        %TYPE,
                            p_tel_pais_contacto    IN OUT a7000900.tel_pais_contacto   %TYPE,
                            p_tel_zona_contacto    IN OUT a7000900.tel_zona_contacto   %TYPE,
                            p_tel_numero_contacto  IN OUT a7000900.tel_numero_contacto %TYPE,
                            p_email_contacto       IN OUT a7000900.email_contacto      %TYPE)
   IS
   --
   l_fec_inicio_evento     a7990700.fec_inicio_evento%TYPE;
   l_fec_fin_evento        a7990700.fec_fin_evento%TYPE;
   l_fec_denu_evento       a7990700.fec_denu_evento%TYPE;
   --
   BEGIN
      --
      --@mx('I','p_v_cod_evento');
      --
      g_ape_contacto        := p_ape_contacto;
      g_nom_contacto        := p_nom_contacto;
      g_tel_pais_contacto   := p_tel_pais_contacto;
      g_tel_zona_contacto   := p_tel_zona_contacto;
      g_tel_numero_contacto := p_tel_numero_contacto;
      g_email_contacto      := p_email_contacto;
      --
      p_mca_hay_ctrl_tecnico := 'N';
      --
      g_cod_evento := p_cod_evento;
      --
      IF p_cod_evento IS NOT NULL
      THEN
         --
         l_fec_inicio_evento := TO_DATE(trn_k_global.ref_f_global('fec_inicio_evento'),'ddmmyyyy');
         --
         trn_k_global.borra_variable('fec_inicio_evento');
         --
         IF l_fec_inicio_evento IS NULL
          THEN
           --
           l_fec_inicio_evento := ts_k_a7990700.f_devuelve_max_fec_evento(p_cod_evento, g_fec_sini);
           --
         END IF;
         --
         ts_k_a7990700.p_lee(p_cod_evento, l_fec_inicio_evento); --743
         --
         l_fec_fin_evento    := ts_k_a7990700.f_fec_fin_evento;
         l_fec_denu_evento   := ts_k_a7990700.f_fec_denu_evento;
         --
         IF l_fec_fin_evento IS NOT NULL
         THEN
            IF g_fec_sini BETWEEN l_fec_inicio_evento AND l_fec_fin_evento
            THEN
               IF l_fec_denu_evento IS NULL OR l_fec_denu_evento >= g_fec_denu_sini
               THEN
                  --
                  p_nom_evento  := ts_k_a7990700.f_nom_evento;
                  --
               ELSE
                  --
                  g_cod_mensaje := 70001257;
                  g_anx_mensaje := 'p_v_cod_evento';
                  --
                  pp_devuelve_error;
                  --
               END IF;
            ELSE
               IF g_fec_sini < l_fec_inicio_evento
               THEN
                  --
                  g_cod_mensaje := 70001258;
                  g_anx_mensaje := 'p_v_cod_evento';
                  --
                  pp_devuelve_error;
                  --
               ELSIF g_fec_sini > l_fec_fin_evento
               THEN
                  --
                  g_cod_mensaje := 70001259;
                  g_anx_mensaje := 'p_v_cod_evento';
                  --
                  pp_devuelve_error;
                  --
               END IF;
               --
            END IF;
         ELSIF l_fec_fin_evento IS NULL
         THEN
            IF g_fec_sini >= l_fec_inicio_evento
            THEN
               IF l_fec_denu_evento IS NULL OR l_fec_denu_evento >= g_fec_denu_sini
               THEN
                  --
                  p_nom_evento  := ts_k_a7990700.f_nom_evento;
                  --
               ELSE
                  --
                  g_cod_mensaje := 70001257;
                  g_anx_mensaje := 'p_v_cod_evento';
                  --
                  pp_devuelve_error;
                  --
               END IF;
            ELSE
               --
               g_cod_mensaje := 70001258;
               g_anx_mensaje := 'p_v_cod_evento';
               --
               pp_devuelve_error;
               --
            END IF;
         END IF;
      ELSE
         p_nom_evento := NULL;
      END IF;
      --
      IF g_tip_poliza_stro = 'R'
      THEN
         --
         pp_asigna_globales_ct;
         --
         IF ts_k_as799001.f_calcula_errores(g_cod_sistema,
                                            g_cod_nivel_salto_2,
                                            g_mca_puede_haber_auditoria,
                                            g_cod_pgm) > 0
         THEN
            --
            p_mca_hay_ctrl_tecnico := 'S';
            --
         END IF;
         --
      END IF;
      --
      --@mx('F','p_v_cod_evento');
      --
   END p_v_cod_evento;
   --
   /* ----------------------------------------------------------------
   || Validacion del campo tip_relacion del contacto con el asegurado
   */ ----------------------------------------------------------
   PROCEDURE p_v_tip_relacion(p_tip_relacion        IN     a7000900.tip_relacion        %TYPE,
                              p_nom_tip_relacion    IN OUT g1010031.nom_valor           %TYPE,
                              p_tip_docum_contacto  IN OUT a7000900.tip_docum_contacto  %TYPE,
                              p_cod_docum_contacto  IN OUT a7000900.cod_docum_contacto  %TYPE,
                              p_nom_contacto        IN OUT a7000900.nom_contacto        %TYPE,
                              p_ape_contacto        IN OUT a7000900.ape_contacto        %TYPE,
                              p_tel_pais_contacto   IN OUT a7000900.tel_pais_contacto   %TYPE,
                              p_tel_zona_contacto   IN OUT a7000900.tel_zona_contacto   %TYPE,
                              p_tel_numero_contacto IN OUT a7000900.tel_numero_contacto %TYPE,
                              p_email_contacto      IN OUT a7000900.email_contacto      %TYPE)
   IS
   BEGIN
      --
      --@mx('I','p_v_tip_relacion');
      --
      g_tip_relacion := p_tip_relacion;
      --
      IF p_tip_relacion IS NOT NULL
      THEN
         p_nom_tip_relacion := fi_g1010031('tip_relacion',
                                           p_tip_relacion);
      ELSE
         p_nom_tip_relacion := TRN.NULO;
      END IF;
      --
      trn_k_global.asigna('tip_docum_aseg',         g_tip_docum_aseg);
      trn_k_global.asigna('cod_docum_aseg',         g_cod_docum_aseg);
      trn_k_global.asigna('cod_agt',                g_cod_agt);
      --
      ts_k_apertura.p_relacion_aseg (p_cod_cia             => g_cod_cia             ,
                                     p_tip_relacion        => g_tip_relacion        ,
                                     p_tip_docum_contacto  => p_tip_docum_contacto  ,
                                     p_cod_docum_contacto  => p_cod_docum_contacto  ,
                                     p_nom_contacto        => p_nom_contacto        ,
                                     p_ape_contacto        => p_ape_contacto        ,
                                     p_tel_pais_contacto   => p_tel_pais_contacto   ,
                                     p_tel_zona_contacto   => p_tel_zona_contacto   ,
                                     p_tel_numero_contacto => p_tel_numero_contacto ,
                                     p_email_contacto      => p_email_contacto      );
      --
   END p_v_tip_relacion;
   --
   /* ----------------------------------------------------------------
   || Validacion del campo tip_docum_contacto
   */ ----------------------------------------------------------
   PROCEDURE p_v_tip_docum_contacto(p_tip_docum_contacto IN a7000900.tip_docum_contacto %TYPE)
   IS
   BEGIN
      --
      --@mx('I','p_v_tip_docum_contacto');
      --
      IF p_tip_docum_contacto IS NOT NULL
      THEN
         --
         dc_k_a1002300.p_lee(p_tip_docum_contacto);
         --
      END IF;
      --
      g_tip_docum_contacto := p_tip_docum_contacto;
      --
      --@mx('F','p_v_tip_docum_contacto');
      --
   END p_v_tip_docum_contacto;
   --
   /* ----------------------------------------------------------------
   || Validacion del campor cod_docum_contacto
   */ ----------------------------------------------------------
  PROCEDURE p_v_cod_docum_contacto(p_tip_docum_contacto IN a7000900.tip_docum_contacto %TYPE,
                                   p_cod_docum_contacto IN a7000900.cod_docum_contacto %TYPE,
                                   p_nom_contacto       IN OUT a7000900.nom_contacto   %TYPE,
                                   p_ape_contacto       IN OUT a7000900.ape_contacto   %TYPE)
   IS
      l_no_existe EXCEPTION;
      PRAGMA EXCEPTION_INIT(l_no_existe,         -20001);
      --
      l_cod_docum_contacto a7000900.cod_docum_contacto %TYPE;
   BEGIN
      --
      --@mx('I','p_v_cod_docum_contacto');
      --
      g_cod_cia := NVL(g_cod_cia,trn_k_global.cod_cia);
      --
      IF p_cod_docum_contacto IS NOT NULL
      THEN
         l_cod_docum_contacto := dc_f_devuelve_docum(p_tip_docum_contacto,
                                                     p_cod_docum_contacto);
         --
         g_cod_docum_contacto := p_cod_docum_contacto;
         --
         BEGIN
             dc_k_a1001399.p_lee(g_cod_cia,
                                 p_tip_docum_contacto,
                                 p_cod_docum_contacto);
             --
             p_nom_contacto := SUBSTR(dc_k_a1001399.f_nom_tercero, 1,30);
             p_ape_contacto := dc_k_a1001399.f_ape1_tercero || ' ' ||
                               dc_k_a1001399.f_ape2_tercero;
         EXCEPTION
         WHEN l_no_existe
         THEN
             --
             p_nom_contacto := NULL;
             p_ape_contacto := NULL;
             --
          END;
         --
       ELSE
         --
         g_cod_docum_contacto := NULL;
         --
       END IF;
      --
      --@mx('F','p_v_cod_docum_contacto');
      --
  END p_v_cod_docum_contacto;
   --
   /* ------------------------------------------
   || Validacion del codigo de la causa
   */ ------------------------------------------
   --
   PROCEDURE p_v_cod_causa(p_cod_causa              IN g7000200.cod_causa               %TYPE,
                           p_nom_causa              IN OUT g7000200.nom_causa           %TYPE,
                           p_mca_tramitable         IN OUT g7000200.mca_tramitable      %TYPE,
                           p_tip_tramitador         IN OUT a1001339.tip_tramitador      %TYPE,
                           p_mca_hay_ctrl_tecnico3  IN OUT VARCHAR2                          )
   IS
      --
      l_mca_inh g7000070.mca_inh %TYPE;
      --
   BEGIN
      --
      --@mx('I','p_v_cod_causa');
      --
      p_mca_hay_ctrl_tecnico3 := 'N';
      g_tip_apertura          := 'M';
      g_cod_causa             := p_cod_causa;
      --
      ts_k_a7000200.p_lee_2(g_cod_cia,
                            g_cod_ramo,
                            g_tip_causa,
                            g_cod_causa);
      --
      IF ts_k_a7000200.f_mca_inh = 'S'
      THEN
         g_cod_mensaje := 20020;
         g_anx_mensaje := 'Causa: ' || g_cod_causa;
         --
         pp_devuelve_error;
         --
      END IF;
      --
      ts_k_g7000200.p_lee(g_cod_cia,
                          g_tip_causa,
                          g_cod_causa);
      --
      p_nom_causa      := ts_k_g7000200.f_nom_causa;
      p_tip_tramitador := g_tip_tramitador;
      --
      p_mca_tramitable := ts_k_g7000200.f_mca_tramitable;
      g_mca_tramitable := p_mca_tramitable;
    --
      trn_k_global.asigna('cod_causa',         TO_CHAR(g_cod_causa));
      trn_k_global.asigna('cod_causa_origen',  TO_CHAR(g_cod_causa));
      --
      /* Mira en la g7000070 si hay consecuencias definidas para la causa */
      --
      IF g_mca_tramitable = 'S'
      THEN
         --
         IF ts_k_g7000070.f_hay_consecuencias(g_cod_cia,
                                              g_cod_ramo,
                                              g_cod_causa) = 'N'
         THEN
            -- NO EXISTEN CONSECUENCIAS PARA LA CAUSA (20304).
            g_cod_mensaje := 20304;
            g_anx_mensaje := ' G7000070,Causa: ' || TO_CHAR(g_cod_causa);
            --
            pp_devuelve_error;
            --
         END IF;
         --
       ELSE
       --
            pp_asigna_globales_ct;
            --
            IF ts_k_as799001.f_calcula_errores(g_cod_sistema,
                                               g_cod_nivel_salto_3,
                                               g_mca_puede_haber_auditoria,
                                               g_cod_pgm) > 0
            THEN
                --
                p_mca_hay_ctrl_tecnico3 := 'S';
                --
            END IF;
            --
      END IF;
      --
      --@mx('F','p_v_cod_causa');
      --
   END p_v_cod_causa;
   --
   /* ----------------------------------------------------------
   || Este procedimiento se va a lanzar siempre y cuando la causa
   || sea no tramitable o el tramitador sea cabinero o recepcionista
   || p_graba_tablas_stros Graba el siniestro en la tablas
   || a7000900 ,a7000930, a7001020
   */ -------------------------------------------------------------
   --
   PROCEDURE p_graba_a7000900
   IS
   BEGIN
      --
      --@mx('I','p_graba_a7000900');
      --
      /* Se hace una lectura previa para saber si ya esta grabado*/
      --
      ts_k_a7000900.p_lee_a7000900(g_cod_cia,
                                   g_num_sini);
      --
      /* Si existe el siniestro en la A7000900, se actualiza */
      --
      ts_k_a7000900.p_actualiza_evento(g_cod_cia,
                                       g_num_sini,
                                       g_fec_sini,
                                       g_cod_evento,
                                       g_cod_causa,
                                       g_ape_contacto,
                                       g_nom_contacto,
                                       g_tel_pais_contacto,
                                       g_tel_zona_contacto,
                                       g_tel_numero_contacto,
                                       g_tip_docum_contacto,
                                       g_cod_docum_contacto,
                                       g_email_contacto,
                                       g_tip_relacion);
      --
      --@mx('F','p_graba_a7000900');
      --
   EXCEPTION
   WHEN OTHERS
   THEN
      --
      /* Si no existe el siniestro en la A7000900 se inserta */
      --
      pp_inserta_a7000900;
      --
   END p_graba_a7000900;
   --
   /* ----------------------------------------------------------
   || Este procedimiento se va a lanzar siempre y cuando la causa sea tramita
   || ble. graba en ,a7000930, a7001020
   */ -------------------------------------------------------------
   --
   PROCEDURE p_graba_resto_stros
   IS
      l_mca_provisional a2000030.mca_provisional %TYPE;
      --
      PROCEDURE pi_actualiza_errores_ct(p_mca_provisional IN OUT a3001700.mca_provisional%TYPE)
      IS
         --
         l_mca_provisional_1 a3001700.mca_provisional%TYPE;
         l_mca_provisional_2 a3001700.mca_provisional%TYPE;
         l_mca_provisional_3 a3001700.mca_provisional%TYPE;
         l_mca_provisional_4 a3001700.mca_provisional%TYPE;
         --
      BEGIN
         --
         ts_k_as799001.p_actualiza(l_mca_provisional_1,
                                   g_cod_sistema,
                                   g_cod_nivel_salto_1);
         --
         ts_k_as799001.p_actualiza(l_mca_provisional_2,
                                   g_cod_sistema,
                                   g_cod_nivel_salto_2);
         --
         ts_k_as799001.p_actualiza(l_mca_provisional_3,
                                   g_cod_sistema,
                                   g_cod_nivel_salto_3);
         --
         ts_k_as799001.p_actualiza(l_mca_provisional_4,
                                   g_cod_sistema,
                                   g_cod_nivel_salto_4);
         --
         IF (l_mca_provisional_1 = 'S') OR (l_mca_provisional_2 = 'S') OR
            (l_mca_provisional_3 = 'S')
      -- 1.82
            OR (l_mca_provisional_4 = 'S')
         THEN
            p_mca_provisional := 'S';
         ELSE
            p_mca_provisional := 'N';
         END IF;
         --
      END pi_actualiza_errores_ct;
      --
   BEGIN
      --
      --@mx('I','p_graba_resto_stros');
      --
      -- Validaciones necesarias antes de finalizar la apertura del siniestro.
      ts_k_apertura.p_sini_antes_exp;
      --
      pp_inserta_a7001020;
      --
      pp_inserta_a7000930;
      --
      pi_actualiza_errores_ct(g_mca_provisional);
      --
      pp_actualiza_supervisor;
      --
	  -- 1.88
	  dc_k_rgpd_consentimiento.p_registra_consentimiento;
	  --
      COMMIT;
      --
      /* Lanzo la apertura de expedientes  batch . Primero miro si el ramo
      Acepta la apertura batch desde el ON-LINE, si es así lanzo el BATCH*/
      /* La apertura de expedientes batch, la realizo si el siniestro NO
        se queda retenido por C.T. */
      --
      IF NVL(g_mca_provisional, 'N') = 'N'
      THEN
         --
         BEGIN
            --
            ts_k_g7000001.p_lee(g_cod_cia,
                                g_cod_ramo);
            --
            g_mca_aut_on_line := NVL(ts_k_g7000001.f_mca_aut_on_line, 'N');
            g_mca_aper_aut    := NVL(ts_k_g7000001.f_mca_aper_aut,'N');
            --
         EXCEPTION
         WHEN OTHERS
         THEN
            g_mca_aut_on_line := 'N';
            g_mca_aper_aut    := 'N';
         END;
         --
         /* Si estoy en el ON-LINE tip_mvto_batch_stro = 0 y el ramo admite
         apertura BATCH desde el ON-LINE lanzo la apertura automatica*/
         --
         IF g_mca_aut_on_line = 'S' AND
            NVL(trn_k_global.ref_f_global('tip_mvto_batch_stro'),'0') = '0'
         THEN
            --
            pp_asigna('mca_aut_on_line',  'S');
            pp_asigna('tip_mvto_batch_stro',  '20');
            pp_asigna('fec_tratamiento'    ,  TRUNC(SYSDATE));
            --
            /* Controlo las excepciones que me pueda dar la apertura automatica
            para no cortar el ON-LINE*/
            --
            BEGIN
               --
               ts_k_ap700117.p_batch;
               --
               trn_k_global.borra_variable('tip_mvto_batch_stro');
               trn_k_global.borra_variable('fec_tratamiento');
               --
            EXCEPTION
            WHEN OTHERS
            THEN
                trn_k_global.borra_variable('tip_mvto_batch_stro');
                trn_k_global.borra_variable('fec_tratamiento');
            END;
            --
         END IF;
         --
      END IF; -- De si NO está retenido por C.T.
      --
      --mx('F','p_graba_resto_stros');
      --
   END p_graba_resto_stros;
   --
   /* ----------------------------------------------------------
   || Se sale del AP700100 sin grabar
   || Hace un Rollback de la base de datos.
   || Modifica el saco para marcar el siniestro como no usado
   || Borra globales y variables y tablas de memoria.
   */ -------------------------------------------------------------
   --
   PROCEDURE p_abandonar_stro
   IS
      l_mca_retencion g7000140.mca_retencion %TYPE := 'N';
   BEGIN
      --
      --@mx('I','p_abandonar_stro');
      --
      ROLLBACK;
      --
      IF g_num_sini IS NOT NULL
      THEN
         --
         ts_k_g7000140.p_modifica(g_cod_cia,
                                  g_num_sini,
                                  l_mca_retencion,
                                  g_cod_usr);
         --
      END IF;
      --
      pp_inicializa_variables;
      --
      pp_inicializa_globales;
      --
      /* QUITAR  */
      --
      COMMIT;
      --
      --@mx('F','p_abandonar_stro');
      --
   END p_abandonar_stro;
   --
   /* ----------------------------------------------------------
   || Se sale del AP700100 habiendo grabado el siniestro y la causa es no
   || tramitable o el tramitador no es 'T' por lo que no tiene opcion a
   || aperturar expedientes.
   || Modifica el saco para borrar el siniestro como no usado
   || Borra globales y variables y tablas de memoria.
   */ -------------------------------------------------------------
   --
   PROCEDURE p_termina_apertura_stro
   IS
   BEGIN
      --
      --@mx('I','p_termina_apertura_stro');
      --
      /* Borra el siniestro del saco*/
      --
      ts_k_g7000140.p_borra(g_cod_cia,
                            g_num_sini);
      --
      ts_k_apertura.p_final_aper_stro;
      --
      pp_inicializa_variables;
      pp_inicializa_globales;
      --
      COMMIT;
      --
      --@mx('F','p_termina_apertura_stro');
      --
   END p_termina_apertura_stro;
   --
   PROCEDURE p_termina_apertura_expedientes
   IS
      --
      l_tip_exp             a7001000.tip_exp                       %TYPE := NULL;
      l_mca_term_automatica a7000900.tip_est_sini                  %TYPE := 'S';
      --
   BEGIN
      --
      --@mx('I','p_termina_apertura_expedientes');
      --
      /* Borra el siniestro del saco*/
      --
      ts_k_g7000140.p_borra(g_cod_cia,
                            g_num_sini);
      --
      /* Si no hay ningun expediente pendiente y hay alguno abierto termina
      el siniestro */
      --
      IF ts_k_a7000900.f_est_exptes_del_stro(g_cod_cia,g_num_sini) = 'T' AND
         NVL(ts_k_a7001000.f_cuenta_exp(g_cod_cia,
                                        g_num_sini,
                                        l_tip_exp), 0) != 0
      THEN
         --
         /* Compruebo si se han terminado los expedientes*/
         --
         ts_k_terminar_siniestro.p_terminar_siniestro(g_cod_cia,
                                                      g_num_sini,
                                                      g_cod_supervisor,
                                                      g_cod_tramitador,
                                                      g_fec_proceso,
                                                      g_cod_usr,
                                                      l_mca_term_automatica);
         --
      END IF;
      --
      ts_k_apertura.p_final_aper_stro;
      --
      pp_inicializa_globales;
      pp_inicializa_variables;
      --
      /* QUITAR  */
      --
      COMMIT;
      --
      --@mx('F','p_termina_apertura_expedientes');
      --
   END p_termina_apertura_expedientes;
   --
   /* Termina el package */
   --
   /* ------------------------------------------
   || Va a realizar la apertura Batch, sacando la informacion
   || de la tablas B7000900.
   || Recibe por parametro del ts_k_batch,
   */ ------------------------------------------
   --
   PROCEDURE p_batch(p_cod_cia             IN     b7000900.cod_cia             %TYPE ,
                     p_fec_tratamiento     IN     b7000900.fec_tratamiento     %TYPE ,
                     p_tip_mvto_batch_stro IN     b7000900.tip_mvto_batch_stro %TYPE ,
                     p_num_sini_ref        IN     b7000900.num_sini_ref        %TYPE ,
                     p_num_sini            IN OUT b7000900.num_sini            %TYPE ,
                     p_num_orden           IN     b7000900.num_orden           %TYPE )
   IS
      --
      l_existe BOOLEAN := FALSE;
      --
      /* Variables para recoger datos de los procedimientos */
      --
      l_num_spto             a7000900.num_spto             %TYPE;
      l_num_apli             a7000900.num_apli             %TYPE;
      l_num_spto_apli        a7000900.num_spto_apli        %TYPE;
      l_num_riesgo           a7000900.num_riesgo           %TYPE;
      l_tip_poliza_tr        a2000030.tip_poliza_tr        %TYPE;
      l_tip_poliza_stro      a7000900.tip_poliza_stro      %TYPE;
      l_nom_riesgo           a2000031.nom_riesgo           %TYPE;
      l_nom_evento           a7990700.nom_evento           %TYPE;
      l_hay_mas_siniestros   a7000900.tip_est_sini         %TYPE;
      l_exclusivo            a7000900.mca_exclusivo        %TYPE;
      l_nom_causa            g7000200.nom_causa            %TYPE;
      l_mca_tramitable       g7000200.mca_tramitable       %TYPE;
      l_tip_tramitador       a1001339.tip_tramitador       %TYPE;
      l_nom_situacion        a5020500.nom_situacion        %TYPE;
      l_tip_docum_contacto   a7000900.tip_docum_contacto   %TYPE;
      l_cod_docum_contacto   a7000900.cod_docum_contacto   %TYPE;
      l_tip_docum_tomador    a7000900.tip_docum_tomador    %TYPE;
      l_cod_docum_tomador    a7000900.cod_docum_tomador    %TYPE;
      l_nom_tomador          v1001390.nom_completo         %TYPE;
      l_cod_agt              a7000900.cod_agt              %TYPE;
      l_nom_agente           v1001390.nom_completo         %TYPE;
      l_ape_contacto         a7000900.ape_contacto         %TYPE;
      l_nom_contacto         a7000900.nom_contacto         %TYPE;
      l_tel_pais_contacto    a7000900.tel_pais_contacto    %TYPE;
      l_tel_zona_contacto    a7000900.tel_zona_contacto    %TYPE;
      l_tel_numero_contacto  a7000900.tel_numero_contacto  %TYPE;
      l_email_contacto       a7000900.email_contacto       %TYPE;
      l_nom_tip_relacion     g1010031.nom_valor            %TYPE;
      l_tip_exp              a7001000.tip_exp              %TYPE := '999';
      l_cod_grp_est          g9990002.cod_grp_est          %TYPE := '2';
      l_mca_hay_ctrl_tecnico VARCHAR2(1);
      --
      /* Variables para el Control Tecnico Batch. */
      --
      l_cod_sistema          a2000220.cod_sistema          %TYPE;
      l_cod_nivel_salto_1    a2000220.cod_nivel_salto      %TYPE;
      l_cod_nivel_salto_2    a2000220.cod_nivel_salto      %TYPE;
      l_cod_nivel_salto_3    a2000220.cod_nivel_salto      %TYPE;
-- 1.82
      l_tip_rechazo          g2000210.tip_rechazo          %TYPE;
      l_num_exp              a2000220.num_exp              %TYPE;
      l_num_liq              a2000220.num_liq              %TYPE;
      l_cod_error_ct         a2000220.cod_error            %TYPE;
      --
   BEGIN
      --
      --@mx('I','p_batch');
      --
      OPEN c_b7000900(p_num_sini_ref,
                      p_fec_tratamiento,
                      p_tip_mvto_batch_stro,
                      p_num_orden,
                      p_cod_cia);
      --
      FETCH c_b7000900  INTO g_reg;
      --
      l_existe := c_b7000900%FOUND;
      --
      CLOSE c_b7000900;
      --
      IF NOT l_existe
      THEN
         g_cod_mensaje := 70001118;
         g_anx_mensaje := NULL;
         pp_devuelve_error;
      END IF;
      --
      /* ----------------------------------------------------
      || Inicializa las variables g
      */ -----------------------------------------------------
      --
      pp_inicializa_variables;
      --
      g_num_sini_ref := p_num_sini_ref;
      g_num_orden    := p_num_orden;
      --
      trn_k_global.asigna('num_sini_ref', g_reg.num_sini_ref);
      -- Necesario para el Control Tecnico
      trn_k_global.asigna ('cod_pgm_sini',    'AP700100');
      --
      p_v_fec_sini(g_reg.fec_sini);
      --
      pp_comprueba_formato_hora(g_reg.hora_sini);
      p_v_hora_sini(g_reg.hora_sini);
      --
      p_v_fec_denu_sini(g_reg.fec_denu_sini);
      --
      pp_comprueba_formato_hora(g_reg.hora_denu_sini);
      p_v_hora_denu_sini(g_reg.hora_denu_sini);
      --
      p_v_num_poliza(g_reg.num_poliza  ,
                     l_num_spto        ,
                     l_num_apli        ,
                     l_num_spto_apli   ,
                     l_num_riesgo      ,
                     l_tip_poliza_tr   ,
                     l_tip_poliza_stro );
      --
      p_v_num_apli(g_reg.num_apli  ,
                   l_num_spto      ,
                   l_num_spto_apli ,
                   l_num_riesgo    );
      --
      p_v_num_riesgo(g_reg.num_riesgo     ,
                     l_nom_riesgo         ,
                     l_hay_mas_siniestros ,
                     l_exclusivo          ,
                     l_nom_situacion      ,
                     l_tip_docum_tomador  ,
                     l_cod_docum_tomador  ,
                     l_nom_tomador        ,
                     l_cod_agt            ,
                     l_nom_agente         );
      --
      -- Ejecucion de errores de CT de nivel de salto 1
      --
      l_mca_hay_ctrl_tecnico := TRN.NO;
      --
      p_aceptar_datos_identif ( l_mca_hay_ctrl_tecnico );
      --
      IF l_mca_hay_ctrl_tecnico = TRN.SI
      THEN
        --
        -- Si ha un Error de Rechazo, provoco el error 70001190 para que
        -- lo recoga el ts_k_batch.
        -- Si el error es de Observacion, no se hace nada.
        -- Si el error es de auditoria, se continua y sera detectado por
        -- el ts_k_batch.
        --
        l_cod_sistema       := '7';
        l_cod_nivel_salto_1 := '1';
        l_tip_rechazo       := '2';
        l_num_liq           :=  0;
        l_num_exp           :=  0;
        --
        IF ts_k_as799001.f_hay_errores_ct (g_num_sini          ,
                                           l_num_exp           ,
                                           l_num_liq           ,
                                           l_cod_sistema       ,
                                           l_cod_nivel_salto_1 ,
                                           l_tip_rechazo) = TRN.SI
        THEN
          --
          -- RECHAZADO POR CONTROL TECNICO. 70001190.
          --
          g_cod_mensaje := 70001190;
          g_anx_mensaje := ' COD_SISTEMA = 7, NIVEL_SALTO = 1';
          --
          pp_devuelve_error;
          --
        END IF;
        --
      END IF;
      --
      p_v_tip_relacion(g_reg.tip_relacion   ,
                       l_nom_tip_relacion   ,
                       l_tip_docum_contacto ,
                       l_cod_docum_contacto ,
                       l_nom_contacto       ,
                       l_ape_contacto       ,
                       l_tel_pais_contacto  ,
                       l_tel_zona_contacto  ,
                       l_tel_numero_contacto,
                       l_email_contacto     );
      --
      g_reg.tip_docum_contacto := NVL(g_reg.tip_docum_contacto,l_tip_docum_contacto);
      --
      p_v_tip_docum_contacto(g_reg.tip_docum_contacto);
      --
      g_reg.cod_docum_contacto := NVL(g_reg.cod_docum_contacto,l_cod_docum_contacto);
      --
      p_v_cod_docum_contacto(g_reg.tip_docum_contacto,
                             g_reg.cod_docum_contacto,
                             l_nom_contacto,
                             l_ape_contacto);
      --
      g_reg.nom_contacto := NVL(l_nom_contacto, g_reg.nom_contacto);
      --
      g_reg.ape_contacto := NVL(l_ape_contacto, g_reg.ape_contacto);
      --
      IF (g_reg.tel_pais_contacto IS NULL AND
          g_reg.tel_zona_contacto IS NULL AND
          g_reg.tel_numero_contacto IS NULL)
      THEN
        --
         g_reg.tel_pais_contacto   := l_tel_pais_contacto;
         g_reg.tel_zona_contacto   := l_tel_zona_contacto;
         g_reg.tel_numero_contacto := l_tel_numero_contacto;
        --
      END IF;
      --
      g_reg.email_contacto         := NVL(g_reg.email_contacto, l_email_contacto);
      --
      l_mca_hay_ctrl_tecnico       := TRN.NO;
      --
      IF ts_k_ld_param_sini_ramo.f_pedir_imp_val_ini_sini(g_cod_cia, g_cod_ramo) = TRN.SI
      THEN
      --
         p_v_imp_val_ini_sini(g_reg.imp_val_ini_sini);
      --
      END IF;
      --
      p_v_cod_evento(g_reg.cod_evento          ,
                     l_nom_evento              ,
                     l_mca_hay_ctrl_tecnico    ,
                     g_reg.ape_contacto        ,
                     g_reg.nom_contacto        ,
                     g_reg.tel_pais_contacto   ,
                     g_reg.tel_zona_contacto   ,
                     g_reg.tel_numero_contacto ,
                     g_reg.email_contacto); -- Ejecucion errores CT de
      -- nivel de salto 2
      --
      IF l_mca_hay_ctrl_tecnico = TRN.SI
      THEN
        --
        -- Si ha un Error de Rechazo, provoco el error 70001190 para que
        -- lo recoga el ts_k_batch.
        -- Si el error es de Observacion, no se hace nada.
        -- Si el error es de auditoria, se continua y sera detectado por
        -- el ts_k_batch.
        --
        l_cod_sistema       := '7';
        l_cod_nivel_salto_2 := '2';
        l_tip_rechazo       := '2';
        l_num_liq           :=  0;
        l_num_exp           :=  0;
        --
        IF ts_k_as799001.f_hay_errores_ct (g_num_sini          ,
                                           l_num_exp           ,
                                           l_num_liq           ,
                                           l_cod_sistema       ,
                                           l_cod_nivel_salto_2 ,
                                           l_tip_rechazo) = TRN.SI
        THEN
          --
          -- RECHAZADO POR CONTROL TECNICO. 70001190.
          --
          g_cod_mensaje := 70001190;
          g_anx_mensaje := ' COD_SISTEMA = 7, NIVEL_SALTO = 2';
          --
          pp_devuelve_error;
          --
        END IF;
        --
      END IF;
      --
      p_v_cod_causa(g_reg.cod_causa_sini ,
                    l_nom_causa          ,
                    l_mca_tramitable     ,
                    l_tip_tramitador     ,
                    g_mca_hay_ctrl_tecnico);
      --
      IF   l_mca_tramitable = trn.NO
       AND g_mca_hay_ctrl_tecnico = trn.SI
      THEN
        --
        l_cod_sistema       := '7';
        l_cod_nivel_salto_3 := '3';
        l_tip_rechazo       := '2';
        l_num_liq           :=  0;
        l_num_exp           :=  0;
        --
        IF ts_k_as799001.f_hay_errores_ct (g_num_sini         ,
                                           l_num_exp          ,
                                           l_num_liq          ,
                                           l_cod_sistema      ,
                                           l_cod_nivel_salto_3,
                                           l_tip_rechazo) = 'S'
        THEN
          --
          -- RECHAZADO POR CONTROL TECNICO. 70001190.
          --
          g_cod_mensaje := 70001190;
          g_anx_mensaje := ' COD_SISTEMA = 7, NIVEL_SALTO = 3';
          --
          pp_devuelve_error;
          --
        END IF;
        --
      END IF;
      --
      g_tip_apertura := 'A';
      --
      p_graba_a7000900;
      --
      -- Se pone la llamada a la agrupacion 22 despues del p_v_cod_causa.
      /* Se llama a las estructuras del ramo y se revisa si hay algun dato
      primero asigno globales por que las necesita el ts_k_as700020*/
      --
      l_cod_grp_est := '22';
      --
      trn_k_global.asigna('cod_cia'     ,    g_cod_cia);
      trn_k_global.asigna('cod_sector'  ,    g_cod_sector);
      trn_k_global.asigna('cod_ramo'    ,    g_cod_ramo);
      trn_k_global.asigna('tip_exp'     ,    l_tip_exp);
      trn_k_global.asigna('cod_grp_est' ,    l_cod_grp_est);
      --
      /* Globales para las estructuras del siniestro */
      --
      trn_k_global.asigna('num_sini'        ,  g_num_sini);
      trn_k_global.asigna('num_sini_ref'    ,  g_reg.num_sini_ref);
      trn_k_global.asigna('fec_tratamiento' ,  TO_CHAR(g_reg.fec_tratamiento,'DDMMYYYY'));
      --
      trn_k_global.asigna('tip_mvto_batch_stro' ,  g_reg.tip_mvto_batch_stro);
      trn_k_global.asigna('num_orden'           ,  g_num_orden);
      --
      /* Llamada a las estructuras de siniestros */
      --
      ts_k_as700020.p_batch;
      --
      IF g_mca_tramitable = TRN.SI
      THEN
         --
         /* ----------------------------------------------------------------
         || Valida las consecuencias de la tabla B7000930 y las introduce
         || en la tabla PL
         */ -------------------------------------------------------------
         --
         ts_k_as700010.p_batch(g_cod_cia                 ,
                               g_reg.fec_tratamiento     ,
                               g_reg.tip_mvto_batch_stro ,
                               g_reg.num_sini            ,
                               g_reg.num_sini_ref        ,
                               g_num_orden               );
      END IF;
      --
      --p_graba_a7000900;
      --
      /* OJOOOO    PENDIENTE BLOQUEO DEL SINIESTRO UNA VEZ ABIERTO */
      --pp_bloquea_siniestro;
      --
      p_num_sini := g_num_sini;
      --
      /* Se llama a las estructuras del ramo y se revisa si hay algun dato
      primero asigno globales por que las necesita el ts_k_as700020*/
      --
      /*Se vuelve a llamar a las estructuras con la agrupacion 2 y se pasan
      otra vez la globales por si el control técnico de las consecuencias
      ha cambiado el valor de alguna de ellas.*/
      --
      l_cod_grp_est := '2';
      --
      trn_k_global.asigna('cod_cia'    ,    g_cod_cia);
      trn_k_global.asigna('cod_sector' ,    g_cod_sector);
      trn_k_global.asigna('cod_ramo'   ,    g_cod_ramo);
      trn_k_global.asigna('tip_exp'    ,    l_tip_exp);
      trn_k_global.asigna('cod_grp_est',    l_cod_grp_est);
      --
      /* Globales para las estructuras del siniestro */
      --
      trn_k_global.asigna('num_sini'        ,  g_num_sini);
      trn_k_global.asigna('num_sini_ref'    ,  g_reg.num_sini_ref);
      trn_k_global.asigna('fec_tratamiento' ,  TO_CHAR(g_reg.fec_tratamiento,'DDMMYYYY'));
      --
      trn_k_global.asigna('tip_mvto_batch_stro' ,  g_reg.tip_mvto_batch_stro);
      trn_k_global.asigna('num_orden'           ,  g_num_orden);
      --
      /* Llamada a las estructuras de siniestros */
      --
      ts_k_as700020.p_batch;
      --
      -- 1.82
      IF ts_k_as799001.f_calcula_errores(g_cod_sistema,
                                         g_cod_nivel_salto_4,
                                         g_mca_no_puede_haber_auditoria,
                                         g_cod_pgm) > 0
      THEN
         --
         l_mca_hay_ctrl_tecnico := 'S';
         --
      END IF;
      --
      -- nivel de salto 4
      --
      IF l_mca_hay_ctrl_tecnico = TRN.SI
      THEN
        --
        -- Si ha un Error de Rechazo, provoco el error 70001190 para que
        -- lo recoga el ts_k_batch.
        -- Si el error es de Observacion, no se hace nada.
        -- Si el error es de auditoria, se continua y sera detectado por
        -- el ts_k_batch.
        --
        l_cod_sistema       := '7';
        l_tip_rechazo       := '2';
        l_num_liq           :=  0;
        l_num_exp           :=  0;
        --
        IF ts_k_as799001.f_hay_errores_ct (g_num_sini          ,
                                           l_num_exp           ,
                                           l_num_liq           ,
                                           l_cod_sistema       ,
                                           g_cod_nivel_salto_4 ,
                                           l_tip_rechazo) = TRN.SI
        THEN
          --
          -- RECHAZADO POR CONTROL TECNICO. 70001190.
          --
          g_cod_mensaje := 70001190;
          g_anx_mensaje := ' COD_SISTEMA = 7, NIVEL_SALTO = 4';
          --
          pp_devuelve_error;
          --
        END IF;
        --
      END IF;
      p_graba_resto_stros;
      -- fin 1.82
      /* Si la causa es tramitable  y no está retenido por C.T.
        se va a aperturar expedientes*/
      --
      IF NVL(g_mca_tramitable,  TRN.NO) = TRN.SI AND
         NVL(g_mca_provisional, TRN.NO) = TRN.NO
      THEN
         --
         BEGIN
            --
            /* Voy a comprobar si el ramo admite apertura de expedientes
            automatica */
            --
            IF g_mca_aper_aut = TRN.SI
            THEN
               --
               ts_k_as700030.p_batch;
               --
            END IF;
            --
         EXCEPTION
         WHEN OTHERS
         THEN
               --
               /*01-10-2005*/
               --
               /* Como el p_termina_apertura_stro borra todas las globales, antes de
                 ejecutarlo, guardo la global cod_error_ct que la necesitara el proceso
                 batch.*/
               --
               g_txt_error   := SQLERRM;
               g_cod_mensaje := SQLCODE;
               --
               l_cod_error_ct := trn_k_global.ref_f_global ('cod_error_ct');
               --
               /*01-10-2005.*/
               --
               --
               /* Si hay definicion de expedientes lo que ha fallado
               es la apertura de un expediente, hay que deshacerlo */
               --
               IF trn_k_global.devuelve('DEFINICION') = TRN.SI
               THEN
                  --
                  BEGIN
                    --
                    ts_k_as700030.p_deshacer_expediente;
                    --
                  EXCEPTION
                  WHEN OTHERS
                  THEN
                      --
                      p_termina_apertura_stro;
                      --
                      /* 01-10-2005. */
                      --
                      trn_k_global.asigna ('cod_error_ct', l_cod_error_ct);
                      --
                      /* 01-10-2005. */
                      --
                      pp_error_despues_de_tratarlo;
                      --
                  END;
                  --
               END IF;
               --
               p_termina_apertura_stro;
               --
               /* 01-10-2005. */
               --
               trn_k_global.asigna ('cod_error_ct', l_cod_error_ct);
               --
               /* 01-10-2005. */
               --
               pp_error_despues_de_tratarlo;
               --
         END;
         --
      END IF; -- De si es una causa tramitable y no esta retenido por C.T.
      --
      /* Como el p_termina_apertura_stro borra todas las globales, antes de
        ejecutarlo, guardo la global cod_error_ct que la necesitara el proceso
        batch.*/
      --
      l_cod_error_ct := trn_k_global.ref_f_global ('cod_error_ct');
      --
      p_termina_apertura_stro;
      --
      trn_k_global.asigna ('cod_error_ct', l_cod_error_ct);
      --
      --@mx('F','p_batch');
      --
      /* --------------------------
      || Si nos falla la apertura del siniestro, entonces y solo entonces
      || deshago el siniestro
      */ ----------------------------------
      --
   EXCEPTION
   WHEN OTHERS
   THEN
      --
      g_txt_error   := SUBSTR(SQLERRM, 1, 2000);
      g_cod_mensaje := SQLCODE;
      --
      /* Como el p_termina_apertura_stro borra todas las globales, antes de
        ejecutarlo, guardo la global cod_error_ct que la necesitara el proceso
        batch.*/
      --
      l_cod_error_ct := trn_k_global.ref_f_global ('cod_error_ct');
      --
      p_abandonar_stro;
      --
      trn_k_global.asigna ('cod_error_ct', l_cod_error_ct);
      --
      pp_error_despues_de_tratarlo;
      --
   END p_batch;
   --
   /*--------------------------------------------------------------------
   ||p_aceptar_datos_identif
   */--------------------------------------------------------------------
   --
   PROCEDURE p_aceptar_datos_identif(p_mca_hay_ctrl_tecnico IN OUT VARCHAR2)
   IS
   BEGIN
      --
      --@mx('I','p_aceptar_datos_identif');
      --
      IF g_num_poliza IS NOT NULL  AND
         g_num_riesgo IS NOT NULL
      THEN
          --
          p_mca_hay_ctrl_tecnico := 'N';
          --
          IF g_tip_poliza_stro = 'R'
          THEN
             --
             IF ts_k_as799001.f_calcula_errores(g_cod_sistema,
                                                g_cod_nivel_salto_1,
                                                g_mca_puede_haber_auditoria,
                                                g_cod_pgm) > 0
             THEN
                --
                p_mca_hay_ctrl_tecnico := 'S';
                --
             END IF;
             --
          END IF;
          --
      END IF;
      --
      --@mx('F','p_aceptar_datos_identif');
      --
   END p_aceptar_datos_identif;
   --
   /* -------------------- DESCRIPCION --------------------
   || Procedimiento.
   || Valida el campo num_sini_ref.
   */ -----------------------------------------------------
   --
   PROCEDURE p_v_num_sini_ref (p_num_sini_ref   a7000900.num_sini_ref %TYPE)
   IS
   BEGIN
     --
     --@mx('I','p_v_num_sini_ref');
     --
     ts_k_apertura.p_v_num_sini_ref ( p_num_sini_ref );
     --
     --@mx('F','p_v_num_sini_ref');
     --
   END p_v_num_sini_ref;
  --
  /* -------------------- DESCRIPCION --------------------
  || Funcion
  || Devuelve el valor por defecto de la fechasini.
  */ -----------------------------------------------------
  --
  FUNCTION f_fec_sini_defecto RETURN DATE
  IS
  BEGIN
    --
    RETURN ts_k_apertura.f_fec_sini_defecto;
    --
  END f_fec_sini_defecto ;
  --
  /* -------------------- DESCRIPCION --------------------
  || Funcion
  || Devuelve el valor por defecto de la hora sini.
  */ -----------------------------------------------------
  --
  FUNCTION f_hora_sini_defecto RETURN VARCHAR2
  IS
  BEGIN
    --
    RETURN ts_k_apertura.f_hora_sini_defecto;
    --
  END f_hora_sini_defecto ;
  --
  /* -------------------- DESCRIPCION --------------------
  || Funcion
  || Devuelve el valor por defecto de la fecha de denuncia.
  */ -----------------------------------------------------
  --
  FUNCTION f_fec_denu_defecto RETURN DATE
  IS
  BEGIN
    --
    RETURN ts_k_apertura.f_fec_denu_defecto;
    --
  END f_fec_denu_defecto ;
  --
  /* -------------------- DESCRIPCION --------------------
  || Funcion
  || Devuelve el valor por defecto de hora denuncia sini.
  */ -----------------------------------------------------
  --
  FUNCTION f_hora_denu_sini_defecto RETURN VARCHAR2
  IS
  BEGIN
    --
    RETURN ts_k_apertura.f_hora_denu_sini_defecto;
    --
  END f_hora_denu_sini_defecto ;
  --
  /* -------------------- DESCRIPCION --------------------
  || Funcion
  || Devuelve el valor por defecto del numero de poliza.
  */ -----------------------------------------------------
  --
  FUNCTION f_num_poliza_defecto RETURN VARCHAR2
  IS
  BEGIN
    --
    RETURN ts_k_apertura.f_num_poliza_defecto;
    --
  END f_num_poliza_defecto ;
  --
  /* -------------------- DESCRIPCION --------------------
  || Funcion
  || Devuelve el valor por defecto del numero de riesgo.
  */ -----------------------------------------------------
  --
  FUNCTION f_num_riesgo_defecto RETURN NUMBER
  IS
  BEGIN
    --
    RETURN ts_k_apertura.f_num_riesgo_defecto;
    --
  END f_num_riesgo_defecto ;
  --
  /* -------------------- DESCRIPCION --------------------
  || Funcion
  || Devuelve el valor por defecto el tipo de relacion de la persona
  || de contacto con el asegurado.
  */ -----------------------------------------------------
  --
  FUNCTION f_tip_relacion_defecto RETURN VARCHAR2
  IS
  BEGIN
    --
    RETURN ts_k_apertura.f_tip_relacion_defecto;
    --
  END f_tip_relacion_defecto ;
  --
  /* -------------------- DESCRIPCION --------------------
  || Funcion
  || Devuelve el valor por defecto Tipo de documento del contacto
  */ -----------------------------------------------------
  --
  FUNCTION f_tip_docum_cont_defecto RETURN VARCHAR2
  IS
  BEGIN
    --
    RETURN ts_k_apertura.f_tip_docum_cont_defecto;
   --
  END f_tip_docum_cont_defecto ;
  --
  /* -------------------- DESCRIPCION --------------------
  || Funcion
  || Devuelve el valor por defecto Codigo documento del contacto
  */ -----------------------------------------------------
  --
  FUNCTION f_cod_docum_cont_defecto RETURN VARCHAR2
  IS
  BEGIN
    --
    RETURN ts_k_apertura.f_cod_docum_cont_defecto;
    --
  END f_cod_docum_cont_defecto ;
  --
  /* -------------------- DESCRIPCION --------------------
  || Funcion
  || Devuelve el valor por defecto Nombre de la persona de contacto
  */ -----------------------------------------------------
  --
  FUNCTION f_nom_cont_defecto RETURN VARCHAR2
  IS
  BEGIN
    --
    RETURN ts_k_apertura.f_nom_cont_defecto;
    --
    --
  END f_nom_cont_defecto ;
  --
  /* -------------------- DESCRIPCION --------------------
  || Funcion
  || Devuelve el valor por defecto Apellidos de la persona de contacto
  */ -----------------------------------------------------
  --
  FUNCTION f_ape_cont_defecto RETURN VARCHAR2
  IS
  BEGIN
    --
    RETURN ts_k_apertura.f_ape_cont_defecto;
    --
  END f_ape_cont_defecto ;
  --
  /* -------------------- DESCRIPCION --------------------
  || Funcion
  || Devuelve el valor por defecto Pais del telefono de contacto
  */ -----------------------------------------------------
  --
  FUNCTION f_tel_p_cont_defecto RETURN VARCHAR2
  IS
  BEGIN
    --
    RETURN ts_k_apertura.f_tel_p_cont_defecto;
    --
  END f_tel_p_cont_defecto ;
  --
  /* -------------------- DESCRIPCION --------------------
  || Funcion
  || Devuelve el valor por defecto Zona del telefono de contacto
  */ -----------------------------------------------------
  --
  FUNCTION f_tel_z_cont_defecto RETURN VARCHAR2
  IS
  BEGIN
    --
    RETURN ts_k_apertura.f_tel_z_cont_defecto;
    --
  END f_tel_z_cont_defecto ;
  --
  /* -------------------- DESCRIPCION --------------------
  || Funcion
  || Devuelve el valor por defecto Numero del telefono de contacto
  */ -----------------------------------------------------
  --
  FUNCTION f_tel_n_cont_defecto RETURN VARCHAR2
  IS
  BEGIN
    --
    RETURN ts_k_apertura.f_tel_n_cont_defecto;
    --
  END f_tel_n_cont_defecto ;
  --
  /* -------------------- DESCRIPCION --------------------
  || Funcion
  || Devuelve el valor por defecto el email de contacto
  */ -----------------------------------------------------
  --
  FUNCTION f_email_cont_defecto RETURN VARCHAR2
  IS
  BEGIN
    --
    RETURN ts_k_apertura.f_email_cont_defecto;
    --
  END f_email_cont_defecto ;
  --
  /* -------------------- DESCRIPCION --------------------
  || Funcion
  || Devuelve el valor por defecto del numero de aplicación.
  */ -----------------------------------------------------
  --
  FUNCTION f_num_apli_defecto RETURN NUMBER
  IS
  BEGIN
    --
    RETURN ts_k_apertura.f_num_apli_defecto;
    --
  END f_num_apli_defecto ;
  --
  /* -------------------- DESCRIPCION --------------------
  || Procedimiento que valida que la póliza no sea ficticia.
  */ -----------------------------------------------------
  PROCEDURE p_val_poliza_ficticia (p_num_sini IN a7000900.num_sini%TYPE) IS
     --
     l_tip_poliza_stro a7000900.tip_poliza_stro%TYPE;
     --
  BEGIN
     --
     --@mx('I','p_val_poliza_ficticia');
     --
     ts_k_a7000900.p_lee_a7000900 (g_cod_cia, p_num_sini);
     --
     -- se valida que la póliza no sea ficticia
     l_tip_poliza_stro := ts_k_a7000900.f_tip_poliza_stro;
     --
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
     --@mx('F','p_val_poliza_ficticia');
     --
  END p_val_poliza_ficticia;
    --
 /**--------------------------------------------------------------
 || Devuelve el número de decimales del siniestro/poliza
 */--------------------------------------------------------------
 --
PROCEDURE p_decimales_poliza( p_num_decimales OUT a1000400.num_decimales %TYPE)
 IS
 BEGIN
    --
    IF g_cod_mon IS NULL
    THEN
      --
      -- Como es llamado desde fuera, tengo que cargar las variables necesarias
      -- para el cursor de pp_p_query.
      --
      g_cod_cia          := trn_k_global.devuelve('cod_cia');
      g_num_sini         := trn_k_global.devuelve('num_sini');
      g_num_poliza       := trn_k_global.devuelve('num_poliza');
      g_num_spto         := trn_k_global.devuelve('num_spto');
      g_num_apli         := trn_k_global.devuelve('num_apli');
      g_num_spto_apli    := trn_k_global.devuelve('num_spto_apli');
      g_max_spto_40      := trn_k_global.devuelve('max_spto_40');
      g_max_spto_apli_40 := trn_k_global.devuelve('max_spto_apli_40');
      g_num_riesgo       := trn_k_global.devuelve('num_riesgo');
      g_num_periodo      := trn_k_global.devuelve('num_periodo');
      g_cod_ramo         := trn_k_global.devuelve('cod_ramo');
      g_cod_idioma       := trn_k_global.devuelve('cod_idioma');
      --
      ts_k_a7000900.p_lee_a7000900(g_cod_cia, g_num_sini);
      g_cod_modalidad    := ts_k_a7000900.f_cod_modalidad;
      --
      em_k_a2000030.p_lee(g_cod_cia,
                          g_num_poliza,
                          g_num_spto,
                          g_num_apli,
                          g_num_spto_apli);
      --
      g_cod_mon := em_k_a2000030.f_cod_mon;
      --
    END IF;
    --
    dc_k_a1000400.p_lee(g_cod_mon);
    --
    p_num_decimales := dc_k_a1000400.f_num_decimales;
    --
 END p_decimales_poliza;
  --
     --
   /* ----------------------------------------------------------------
   || Validacion del importe de la valoracion inicial del siniestro
   */ ----------------------------------------------------------
   PROCEDURE p_v_imp_val_ini_sini(p_imp_val_ini_sini IN a7000900.imp_val_ini_sini%TYPE)
   IS
   BEGIN
      --
      g_imp_val_ini_sini := p_imp_val_ini_sini;
      --
      trn_k_global.asigna('imp_val_ini_sini', g_imp_val_ini_sini);
      --
   END p_v_imp_val_ini_sini;
   --
--
/*--------------------------------------------------------------
 || f_calcula_errores_ct
 || LLeva a cabo el c?ulo de errores de CT del nivel de salto
 || que se indica por par?tro, indicando en el resultado si
 || se han producido errores o no.
  */--------------------------------------------------------------
 --
 FUNCTION f_calcula_errores_ct    ( p_cod_nivel_salto  g2000220.cod_nivel_salto %TYPE )
          RETURN VARCHAR2
 IS
   --
   l_mca_hay_errores_ct  VARCHAR2(1);
   --
 BEGIN
  --
  --@mx('I','f_calcula_errores_ct');
  --@mx('nivelsalto',p_cod_nivel_salto);
  --
  l_mca_hay_errores_ct := 'N';
  --
  IF ts_k_as799001.f_calcula_errores ( 7, --g_k_cod_sistema              ,
                                       4, --g_k_nivelCT_rehab            ,
                                       g_mca_no_puede_haber_auditoria,
                                       g_cod_pgm                  ) > 0
  THEN
    l_mca_hay_errores_ct := 'S';
  END IF;
  --
  --@mx('lhayerrores',l_mca_hay_errores_ct);
  --@mx('F','f_calcula_errores_ct');
  --
  RETURN l_mca_hay_errores_ct;
  --
 END f_calcula_errores_ct;
 --
 /*--------------------------------------------------------------
 || f_devuelve_spto_discontinuo
 || Para una fecha dada consulta si existe algun suplemento de renovaci?n
 || que por ser discontin?o no estaba vigente a la fecha del siniestro
  */--------------------------------------------------------------
 --
 FUNCTION f_devuelve_spto_discontinuo (p_cod_cia         IN    a2000030.cod_cia       %TYPE,
                                       p_num_poliza      IN    a2000030.num_poliza    %TYPE,
                                       p_fec_sini        IN    a7000900.fec_sini      %TYPE,
                                       p_hora_sini       IN    a7000900.hora_sini     %TYPE DEFAULT TO_DATE('0000', 'HH24MI'))
          RETURN BOOLEAN
 IS
   --
   p_num_spto    a2000030.num_spto    %TYPE;
   --
 BEGIN
  --
  --@mx('I','fp_devuelve_spto_discontinuo');
  --
  SELECT MIN(num_spto)
    INTO p_num_spto
    FROM a2000030
   WHERE cod_cia = p_cod_cia
     AND num_poliza = p_num_poliza
     AND tip_spto = g_cod_tip_spto_rf
     AND (fec_efec_spto > p_fec_sini
         OR (fec_efec_spto = p_fec_sini
             AND (hora_desde IS NULL
                  OR hora_desde > p_hora_sini)))
     -- A?adimos esta condicion para evitar errores con fechas anteriores a la generaci?n de la p?liza
     AND p_fec_sini > (SELECT fec_efec_poliza
                         FROM a2000030 supl_p
                        WHERE supl_p.cod_cia = p_cod_cia
                          AND supl_p.num_poliza = p_num_poliza
                          AND supl_p.num_spto = 0
                          AND supl_p.num_apli = 0
                          AND supl_p.num_spto_apli = 0);
  --
  IF p_num_spto IS NULL THEN
    --
    RETURN FALSE;
    --
  ELSE
    --
    RETURN TRUE;
    --
  END IF;
  --
  --@mx('F','f_devuelve_spto_discontinuo');
  --
 END f_devuelve_spto_discontinuo;
 --
--
END ts_k_ap700100_trn;


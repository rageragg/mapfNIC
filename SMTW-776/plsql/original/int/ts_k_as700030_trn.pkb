create or replace PACKAGE BODY          ts_k_as700030_trn
IS
 --
 /* ------------------- VERSION = 2.06 -----------------*/
 --
 /* -------------------- DESCRIPCION --------------------
 ||  Rutina que controla la Apertura de Expedientes.
 */ --------------------------------------------------------------
 --
 /* ----------------------- MODIFICACIONES -----------------------
 || 2020/04/17 - LRUIZG1 - 2.06 - (MU-2019-081439)
 || Se modifica el procedimiento p_graba_resto_exp para que cuando
 || se cree el expediente se llame al procedimiento
 || ts_k_apertura.p_final_aper_exp.
 */ --------------------------------------------------------------
 --
 -- ==============================================================
 /*
 ||               Globales al package.
 */
 -- ==============================================================
 --
 -- Tablas de Siniestro
 --
 g_cod_cia                 g7000080.cod_cia       %TYPE;
 g_cod_ramo                g7000080.cod_ramo      %TYPE;
 g_cod_causa               g7000080.cod_causa     %TYPE;
 g_num_sini                a7000930.num_sini      %TYPE;
 g_num_poliza              a2000040.num_poliza    %TYPE;
 g_num_spto                a2000040.num_spto      %TYPE;
 g_max_spto_40             a2000040.num_spto      %TYPE;
 g_num_apli                a2000040.num_apli      %TYPE;
 g_num_spto_apli           a2000040.num_spto_apli %TYPE;
 g_max_spto_apli_40        a2000040.num_spto_apli %TYPE;
 g_num_riesgo              a2000040.num_riesgo    %TYPE;
 g_num_periodo             a2000040.num_periodo   %TYPE;
 --
 g_num_exp                 a7001000.num_exp       %TYPE;
 g_cod_sector              a7001000.cod_sector    %TYPE;
 g_tip_exp                 a7001000.tip_exp       %TYPE;
 g_cod_mon                 a7001000.cod_mon       %TYPE;
 g_cod_mon_exp             a7001000.cod_mon       %TYPE;
 g_fec_proceso             a7001000.fec_aper_exp  %TYPE;
 g_cod_tramitador          a7001000.cod_tramitador%TYPE;
 g_cod_trami_usu           a7001000.cod_tramitador%TYPE;
 g_cod_tramitador_nuevo    a7001000.cod_tramitador%TYPE;
 g_cod_supervisor          a7001000.cod_supervisor%TYPE;
 g_cod_supervisor_nuevo    a7001000.cod_supervisor%TYPE;
 g_cod_nivel3              a7001000.cod_nivel3    %TYPE;
 g_num_exp_afec            a7001000.num_exp_afec  %TYPE;
 g_tip_exp_afec            a7001000.tip_exp_afec  %TYPE;
 g_tip_est_afec            a7001000.tip_est_afec  %TYPE;
 --
 g_tip_docum_exp           a7001000.tip_docum     %TYPE;
 g_cod_docum_exp           a7001000.cod_docum     %TYPE;
 g_tip_docum_tramitador    a7001000.tip_docum     %TYPE;
 g_cod_docum_tramitador    a7001000.cod_docum     %TYPE;
 g_nombre_exp              a7001000.nombre        %TYPE;
 g_apellidos_exp           a7001000.apellidos     %TYPE;
 g_mca_rva_manual          a7001000.mca_rva_manual%TYPE;
 g_tip_apertura            a7001000.tip_apertura  %TYPE := 'M';
 g_tip_causa               g7000200.tip_causa     %TYPE;
 g_tip_causa_aper_exp      a7000200.tip_causa     %TYPE := 15;
 g_cm_causas_no_definidas  g1010020.cod_mensaje   %TYPE := 20332;
 --
 g_nom_prg_exp             g9990003.nom_prg       %TYPE;
 --
 g_k_tip_cto_rva_indem  CONSTANT a7000300.tip_cto_rva%TYPE := 'I';
 --
 g_k_tip_mvto           CONSTANT h7001200.tip_mvto%TYPE := 'E';
 --
 -- Tabla de memoria de los posibles exptes. a aperturar.
 --
 TYPE reg_tip_exp      IS RECORD
      ( tip_exp             g7000080.tip_exp             %TYPE ,
        nom_exp             g7000090.nom_exp             %TYPE ,
        mca_obligatorio     g7000080.mca_obligatorio     %TYPE ,
        num_exp_aper        a7001000.num_exp             %TYPE ,
        mca_aper_aut        g7000100.mca_aper_aut        %TYPE ,
        nom_prg_nro_exp_aut g7000100.nom_prg_nro_exp_aut %TYPE ,
        nro_exp_aut         NUMBER                             );
 --
 greg_tipo_de_expedientes     reg_tip_exp;
 --
 TYPE tabla_tipo_de_expedientes IS TABLE OF greg_tipo_de_expedientes%TYPE
      INDEX BY BINARY_INTEGER;
 --
 gtb_tipos_de_expedientes  tabla_tipo_de_expedientes;
 --
 -- Tabla de memoria de los recobros apert aut
 --
 TYPE reg_rec_aut      IS RECORD
      (tip_exp_rec         g7007030.tip_exp_rec             %TYPE,
       nom_prg_nro_exp_aut g7000100.nom_prg_nro_exp_aut  %TYPE
      );
 --
 greg_rec_aut     reg_rec_aut;
 --
 TYPE tabla_recobro_aut IS TABLE OF greg_rec_aut%TYPE
      INDEX BY BINARY_INTEGER;
 --
 gtb_recobros_aut  tabla_recobro_aut;
 --
 g_fila_devuelve  BINARY_INTEGER;
 g_max_secu_query BINARY_INTEGER;
 --
 g_max_tipos_exp       NUMBER(5);
 g_max_tipos_exp_afec  NUMBER(5);
 --
 -- Tabla de memoria de los posible exptes. que pueden afectar al un recobro.
 --
 TYPE reg_tip_exp_afec      IS RECORD
      ( num_sini            a7001000.num_sini             %TYPE ,
        num_exp             a7001000.num_exp              %TYPE ,
        tip_exp             a7001000.tip_exp              %TYPE ,
        nom_exp             g7000090.nom_exp              %TYPE ,
        tip_est_exp         a7001000.tip_est_exp          %TYPE ,
        mca_aper_aut        g7000100.mca_aper_aut         %TYPE ,
        nom_prg_nro_exp_aut g7000100.nom_prg_nro_exp_aut  %TYPE ,
        nro_exp_aut         NUMBER                              );
 --
 greg_tipo_de_expedientes_afec     reg_tip_exp_afec;
 --
 TYPE tabla_tipo_de_expedientes_afec IS TABLE OF
                                     greg_tipo_de_expedientes_afec%TYPE
      INDEX BY BINARY_INTEGER;
 --
 gtb_tipos_de_expedientes_afec  tabla_tipo_de_expedientes_afec;
 --
 g_fila_devuelve_afec  BINARY_INTEGER;
 g_max_secu_query_afec BINARY_INTEGER;
 --
 -- Variables/Constantes generales que se utilizan en el CT
 --
 g_k_cod_sistema                CONSTANT a2000220.cod_sistema    %TYPE := '7';
 g_k_cod_nivel_salto5           CONSTANT a2000220.cod_nivel_salto%TYPE := '5';
 g_k_cod_nivel_salto6           CONSTANT a2000220.cod_nivel_salto%TYPE := '6';
 g_k_mca_puede_haber_auditoria  CONSTANT VARCHAR2(1)                   := 'S';
 g_mca_hay_errores_ct                    VARCHAR2(1);
 g_cod_pgm                               g9990003.cod_pgm        %TYPE;
 --
 g_cod_idioma        g1010010.cod_idioma        %TYPE;
 g_cod_mensaje       g1010020.cod_mensaje       %TYPE;
 g_anx_mensaje       VARCHAR(250);
 g_txt_error         VARCHAR(600);
 --
 g_k_ini_corchete CONSTANT VARCHAR2(2) := ' [';
 g_k_fin_corchete CONSTANT VARCHAR2(1) := ']';
 --
 g_cod_pgm_est       g9990003.cod_pgm%TYPE;
 --
 g_k_si  CONSTANT  VARCHAR2(1) := trn.SI;
 g_k_no  CONSTANT  VARCHAR2(1) := trn.NO;
 --
 ge_no_existe EXCEPTION;
 PRAGMA EXCEPTION_INIT (ge_no_existe, -20001);
 --
 g_mca_aper_aut       g7000001.mca_aper_aut        %TYPE;
 g_mca_aut_on_line    g7000001.mca_aut_on_line     %TYPE;
 g_mca_aper_recob_exp g7000001.mca_aper_recob_exp  %TYPE;
 --
 /* --------------------------------------------------------------
 ||               Procedimientos Internos
 */---------------------------------------------------------------
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
 /* --------------------------------------------------------
 ||
 || mx :
 || Genera la traza
 */ --------------------------------------------------------
 --
 PROCEDURE mx(p_tit VARCHAR2,
              p_val VARCHAR2) IS
 BEGIN
  --
  pp_asigna('fic_traza','jsant2');
  pp_asigna('cab_traza','as700030->');
  --
  --
  em_k_traza.p_escribe(p_tit,
                       p_val);
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
  pp_asigna('fic_traza','jsant2');
  pp_asigna('cab_traza','as700030->');
  --
  --
  em_k_traza.p_escribe(p_tit,
                       p_val);
  --
 END;
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
PROCEDURE pp_borra_globales
IS
BEGIN
  --
  --@mx('I','pp_borra_globales');
  --
  trn_k_global.borra_variable ('tip_exp');
  trn_k_global.borra_variable ('num_exp_afec');
  trn_k_global.borra_variable ('tip_exp_afec');
  trn_k_global.borra_variable ('tip_est_afec');
  trn_k_global.borra_variable ('fec_aper_exp');
  trn_k_global.borra_variable ('cod_causa_sini');
  trn_k_global.borra_variable ('cod_consecuencia');
  trn_k_global.borra_variable ('cod_cob');
  trn_k_global.borra_variable ('cod_cto_rva');
  trn_k_global.borra_variable ('mca_apertura');
  --
  --@mx(('F','pp_borra_globales');
  --
END pp_borra_globales;
--
--
PROCEDURE pp_inicializa_variables
IS
--
BEGIN
   --
   --@mx('I','pp_inicializa_variables');
   --
   g_cod_idioma              :=  NULL;
   g_cod_cia                 :=  NULL;
   g_cod_ramo                :=  NULL;
   g_cod_sector              :=  NULL;
   g_cod_causa               :=  NULL;
   g_num_sini                :=  NULL;
   g_num_poliza              :=  NULL;
   g_num_spto                :=  NULL;
   g_max_spto_40             :=  NULL;
   g_num_apli                :=  NULL;
   g_num_spto_apli           :=  NULL;
   g_max_spto_apli_40        :=  NULL;
   g_num_riesgo              :=  NULL;
   g_num_periodo             :=  NULL;
   g_fec_proceso             :=  NULL;
   g_cod_tramitador          :=  NULL;
   g_cod_trami_usu           :=  NULL;
   g_cod_tramitador_nuevo    :=  NULL;
   g_cod_supervisor          :=  NULL;
   g_cod_supervisor_nuevo    :=  NULL;
   g_num_exp                 :=  NULL;
   g_tip_exp                 :=  NULL;
   g_cod_mon                 :=  NULL;
   g_cod_mon_exp             :=  NULL;
   g_num_exp_afec            :=  NULL;
   g_tip_exp_afec            :=  NULL;
   g_tip_est_afec            :=  NULL;
   g_tip_docum_exp           :=  NULL;
   g_cod_docum_exp           :=  NULL;
   g_tip_docum_tramitador    :=  NULL;
   g_cod_docum_tramitador    :=  NULL;
   g_nombre_exp              :=  NULL;
   g_apellidos_exp           :=  NULL;
   g_mca_rva_manual          :=  NULL;
   g_tip_apertura            :=  NULL;
   g_nom_prg_exp             :=  NULL;
   g_cod_pgm                 :=  NULL;
  --
  --@mx('F','pp_inicializa_variables');
  --
END pp_inicializa_variables;
--
/* --------------------------------------------------------------
||  Procedimiento que borrar la tabla de memoria de los expedientes
|| que se van a aperturar y la de los afectados.
*/ --------------------------------------------------------------
PROCEDURE pp_borra_tabla_memoria_exp
IS
BEGIN
   --
   --@mx('I','pp_borra_tabla_memoria_exp');
   --
   gtb_tipos_de_expedientes.DELETE;
   --
   gtb_tipos_de_expedientes_afec.DELETE;
   --
   --@mx('F','pp_borra_tabla_memoria_exp');
  --
END pp_borra_tabla_memoria_exp;
--
PROCEDURE pp_carga_globales
IS
--
BEGIN
   --
   --@mx('I','pp_carga_globales');
   --
   g_cod_idioma         :=  trn_k_global.cod_idioma;
   g_cod_cia            :=  trn_k_global.devuelve ('cod_cia');
   g_cod_ramo           :=  trn_k_global.devuelve ('cod_ramo');
   g_cod_sector         :=  trn_k_global.devuelve ('cod_sector');
   g_cod_causa          :=  trn_k_global.devuelve ('cod_causa');
   g_num_sini           :=  trn_k_global.devuelve ('num_sini');
   g_num_poliza         :=  trn_k_global.devuelve ('num_poliza');
   g_num_spto           :=  trn_k_global.devuelve ('num_spto');
   g_max_spto_40        :=  trn_k_global.devuelve ('max_spto_40');
   g_num_apli           :=  trn_k_global.devuelve ('num_apli');
   g_num_spto_apli      :=  trn_k_global.devuelve ('num_spto_apli');
   g_max_spto_apli_40   :=  trn_k_global.devuelve ('max_spto_apli_40');
   g_num_riesgo         :=  trn_k_global.devuelve ('num_riesgo');
   g_num_periodo        :=  trn_k_global.devuelve ('num_periodo');
   g_fec_proceso        :=  TO_DATE(trn_k_global.devuelve ('fec_proceso'),
                           'DDMMYYYY');
   g_cod_tramitador     :=  trn_k_global.devuelve ('cod_tramitador');
   g_cod_trami_usu      :=  trn_k_global.devuelve ('cod_tramitador');
   g_cod_supervisor     :=  trn_k_global.devuelve ('cod_supervisor');
   --
   ts_k_a7000900.p_lee_a7000900 (g_cod_cia,
                                 g_num_sini);
   --
   g_cod_nivel3         := ts_k_a7000900.f_cod_nivel3_captura;
   g_cod_pgm            := trn_k_global.devuelve ('cod_pgm_sini');
   --
   --@mx('F','pp_carga_globales');
   --
EXCEPTION
WHEN ge_no_existe
THEN
     RAISE_APPLICATION_ERROR(-20001,'[TS_K_AS700030] '||SQLERRM);
END pp_carga_globales;
--
/* --------------------------------------------------------------
|| pp_reserva_promedio
*/---------------------------------------------------------------
--
PROCEDURE pp_reserva_promedio
IS
 --
 CURSOR c_lee_imp_iniciales
 IS
   SELECT cod_cob, cod_cto_rva, imp_inicial, nom_prg_imp_inicial,
          cod_consecuencia, nom_prg_validacion
     FROM g7001200
    WHERE cod_cia          = g_cod_cia
      AND cod_ramo         = g_cod_ramo
      AND cod_causa        = g_cod_causa
      AND cod_consecuencia IN
          (SELECT cod_consecuencia
             FROM a7000930 a
            WHERE a.cod_cia     = g_cod_cia
              AND a.num_sini    = g_num_sini
              AND a.tip_causa   = '1'
              AND a.cod_causa   = g_cod_causa
              AND a.fec_mvto    = ( SELECT MAX(fec_mvto)
                                    FROM a7000930 b
                                   WHERE b.cod_cia     = g_cod_cia
                                     AND b.num_sini    = g_num_sini
                                     AND b.tip_causa   = '1'
                                     AND b.cod_causa   = g_cod_causa )
          )
      AND tip_exp          = g_tip_exp
      AND cod_cob          IN (SELECT cod_cob
                                 FROM a2000040
                                WHERE cod_ramo       = g_cod_ramo
                                  AND cod_cia        = g_cod_cia
                                  AND num_poliza     = g_num_poliza
                                  AND num_spto       = g_max_spto_40
                                  AND num_apli       = g_num_apli
                                  AND num_spto_apli  = g_max_spto_apli_40
                                  AND num_riesgo     = g_num_riesgo
                                  AND num_periodo    = g_num_periodo
                                  AND NVL(mca_baja_cob, 'N') = 'N')
      AND NVL(mca_inh, 'N') = 'N';
 --
 li_nom_cob                    a1002050.nom_cob           %TYPE;
 li_tip_cob                    a1002050.tip_cob           %TYPE;
 li_mca_inh                    a1002050.mca_inh           %TYPE;
 --
 li_suma_aseg                  a2000040.suma_aseg         %TYPE := 0;
 li_suma_aseg_cob              a2000040.suma_aseg         %TYPE := 0;
 li_diferencia                 h7001200.imp_val           %TYPE := 0;
 --
 li_imp_val                    h7001200.imp_val           %TYPE := 0;
 li_cod_consecuencia           g7001200.cod_consecuencia  %TYPE ;
 li_cod_cob                    g7001200.cod_cob           %TYPE;
 li_cod_cto_rva                g7001200.cod_cto_rva       %TYPE;
 --
 -- Contador del numero de registros que voy insertando en la h7001200.
 li_contador                   a7001000.num_exp           %TYPE;
 --
 li_inserto                    VARCHAR2(1);
 li_existe                     h7001200.cod_cia           %TYPE;
 l_hay_error                   EXCEPTION;
  --
BEGIN
   --@mx('I','pp_reserva_promedio');
   --
   li_contador := 0;
   --
   FOR reg IN c_lee_imp_iniciales
   LOOP
      --
      li_inserto  := 'S';
      --
      li_imp_val          := 0;
      li_cod_consecuencia := reg.cod_consecuencia;
      li_cod_cob          := reg.cod_cob;
      li_cod_cto_rva      := reg.cod_cto_rva;
      --
      /* Se usa tambien esta porque algunos sitios esta cod_causa y
         otra cod_causa_sini.*/
      --
      trn_k_global.asigna('cod_causa_sini'  ,TO_CHAR(g_cod_causa));
      trn_k_global.asigna('cod_consecuencia',TO_CHAR(li_cod_consecuencia));
      trn_k_global.asigna('cod_cob'         ,TO_CHAR(li_cod_cob));
      trn_k_global.asigna('cod_cto_rva'     ,TO_CHAR(li_cod_cto_rva));
      --
      IF reg.nom_prg_imp_inicial IS NOT NULL
      THEN
         --
         trn_k_dinamico.p_ejecuta_procedimiento (reg.nom_prg_imp_inicial);
         --
         li_imp_val   := trn_k_global.devuelve ('imp_val');
         --
      ELSE
         --
         li_imp_val   := reg.imp_inicial;
         --
      END IF;
      --
      -- Nov.2004
      -- Se agrega validacion del importe
      --
      IF reg.nom_prg_validacion IS NOT NULL
      THEN
         trn_k_global.asigna('imp_val',TO_CHAR(li_imp_val));
         --
         trn_p_dinamico (reg.nom_prg_validacion);
         --
         li_suma_aseg := trn_k_global.devuelve('suma_aseg');
         --
         IF NVL(g_num_exp_afec, 0) = 0  -- No es un recobro
         THEN
           IF li_suma_aseg < li_imp_val
           THEN
             li_diferencia:= (NVL(li_imp_val,0)- NVL(li_suma_aseg,0));
             -- EL IMPORTE SUPERA LA SUMA ASEGURADA (20318).
             g_cod_mensaje := 20318;
             g_anx_mensaje := TO_CHAR(li_diferencia)|| 'TIP_EXP '|| g_tip_exp;
             pp_devuelve_error;
             --
           END IF;
           --
         ELSE -- Si es un recobro.
            --
            ts_k_a7000300.p_lee (g_cod_cia, li_cod_cto_rva);
            --
            IF (li_imp_val > 0 AND
                ts_k_a7000300.f_tip_cto_rva = g_k_tip_cto_rva_indem ) OR
               (li_imp_val > 0 AND
                ts_k_a7000300.f_tip_cto_rva <> g_k_tip_cto_rva_indem  AND
                ts_k_liquidaciones.f_permite_posit_rec = 'N')
            THEN
               -- EL IMPORTE DEBE SER NEGATIVO (20083).
               g_cod_mensaje := 20083;
               g_anx_mensaje := ' '||li_imp_val||' ';
               --
               pp_devuelve_error;
               --
             ELSIF li_suma_aseg > li_imp_val
             THEN
               --
               li_diferencia:= (NVL(li_imp_val,0)- NVL(li_suma_aseg,0));
               -- EL IMPORTE SUPERA LA SUMA ASEGURADA (20318).
               g_cod_mensaje := 20318;
               g_anx_mensaje := TO_CHAR(li_diferencia)|| 'TIP_EXP '|| g_tip_exp;
               pp_devuelve_error;
               --
             END IF;
          --
        END IF;
        --
      ELSE  --  no hay prog.validacion -- AQUI
        --
        -- ValidarÃ© contra la suma asegurada. La obtengo mediante el ts_k_apertura,
        -- funcion que nos devuelve la suma asegurada de la cobertura en la moneda
        -- del expediente.
        --
        li_suma_aseg_cob := ts_k_apertura.f_saca_suma_aseg_cob;
        --
        em_p_a1002050_1 ( g_cod_cia, li_cod_cob, li_nom_cob,
                          li_tip_cob,    li_mca_inh );
        --
        IF NVL(g_num_exp_afec, 0) = 0  -- No es un recobro
        THEN
           IF li_suma_aseg_cob < li_imp_val AND
              -- li_tip_cob NOT IN ( '5', '6' )      MU-2018-024699
              li_tip_cob NOT IN ( '5', '6', '7' ) -- MU-2018-024699
           THEN
              --
              li_diferencia:= (NVL(li_imp_val,0)- NVL(li_suma_aseg_cob,0));
              --
              -- EL IMPORTE SUPERA LA SUMA ASEGURADA (20318).
              g_cod_mensaje := 20318;
              g_anx_mensaje := TO_CHAR(li_diferencia);
              --
              pp_devuelve_error;
              --
           END IF;
           --
        ELSE                  --  Es un recobro
          --
           ts_k_a7000300.p_lee (g_cod_cia, li_cod_cto_rva);
          --
          IF (li_imp_val > 0 AND
              ts_k_a7000300.f_tip_cto_rva = g_k_tip_cto_rva_indem ) OR
             (li_imp_val > 0 AND
              ts_k_a7000300.f_tip_cto_rva <> g_k_tip_cto_rva_indem  AND
              ts_k_liquidaciones.f_permite_posit_rec = 'N')
          ----
          THEN
            -- EL IMPORTE DEBE SER NEGATIVO (20083).
            g_cod_mensaje := 20083;
            g_anx_mensaje := '  '||li_imp_val||' ' ;
            pp_devuelve_error;
          END IF;
          --
        END IF;
        --
      END IF;
      --
      -- Antes de insertar, si es un recobro, validare que su afectado,
      --tenga definidas la cob/cto_rva que estoy tratando.
      --
      IF NVL(g_num_exp_afec, 0) <> 0 AND
         ts_f_val_rec_como_asoc(g_tip_exp, g_tip_exp_afec) = 'S'
      THEN
         BEGIN
           SELECT cod_cia
             INTO li_existe
             FROM h7001200
            WHERE cod_cia     = g_cod_cia
              AND num_sini    = g_num_sini
              AND num_exp     = g_num_exp_afec
              AND cod_cob     = li_cod_cob
              AND cod_cto_rva = li_cod_cto_rva
              AND num_mvto    = ( SELECT MAX(num_mvto)
                                    FROM h7001200
                                   WHERE cod_cia     = g_cod_cia
                                     AND num_sini    = g_num_sini
                                     AND num_exp     = g_num_exp_afec
                                     AND cod_cob     = li_cod_cob
                                     AND cod_cto_rva = li_cod_cto_rva
                                     AND tip_mvto    = 'E' );
         --
         EXCEPTION
           WHEN OTHERS
           THEN
                li_inserto := 'N';
         END;   -- Fin del bloque para la select.
         --
      END IF;   -- Fin de si es un recobro.
      --
      IF NVL(li_imp_val,0) <> 0 AND li_inserto = 'S'
      THEN
         --
         ts_k_h7001200.p_inserta_distribuyendo
                                 (
                                  g_cod_cia,
                                  g_num_sini,
                                  g_num_exp,
                                  'E',                 -- tip_mvto
                                  'I',                 -- sub_tip_mvto
                                  reg.cod_cob,
                                  reg.cod_cto_rva,
                                  'P',                 -- tip_est_cob
                                  'N',                 -- mca_provisional
                                  g_fec_proceso,
                                  li_imp_val,          -- imp_mvto_val
                                  0,                   -- imp_mvto_liq
                                  g_cod_mon_exp,
                                  NULL                 -- num_liq
                                  );
        --
        li_contador := li_contador + 1;
        --
     END IF; -- Del IF li_imp_val <> 0
     --
   END LOOP;
   --
   IF li_contador <  1
   THEN
     --
     /* NO PUEDE APERTURAR EL EXPEDIENTE, AGOTADA LA COBERTURA (20378).*/
     --
     g_cod_mensaje := 20378;
     g_anx_mensaje := NULL;
     --
     pp_devuelve_error;
     --
   END IF;
   --
   --@mx('F','pp_reserva_promedio');
   --
END pp_reserva_promedio;
--
/* --------------------------------------------------------------
||  Procedimiento inicializa las variables, borra la tabla de memoria de
|| los expediente que se van a aperturar y carga las globales.
*/ --------------------------------------------------------------
PROCEDURE p_inicio
IS
BEGIN
  --@mx('I','p_inicio');
  --
  ts_k_as799001.p_inicializa ( g_k_cod_sistema     ,
                               g_k_cod_nivel_salto5 );
  --
  ts_k_as799001.p_inicializa ( g_k_cod_sistema     ,
                               g_k_cod_nivel_salto6 );
  --
  p_borra_variables;
  --
  pp_carga_globales;
  --
  --@mx('F','p_inicio');
  --
END p_inicio;
--
/* --------------------------------------------------------------
||  Procedimiento que carga en memoria los expedientes que se van a
|| aperturar.
*/ --------------------------------------------------------------
--
PROCEDURE p_query
IS
   --
   /*  26-01-11 -  MS-2011-01-00042 -  Inicio
   || se incluye en el where la validaciÃ³n de mca_sini para consultar solo los tipos de expedientes reales
   */
   CURSOR c_g7000080   (pc_cod_cia        g7000080.cod_cia       %TYPE,
                        pc_cod_ramo       g7000080.cod_ramo      %TYPE,
                        pc_cod_causa      g7000080.cod_causa     %TYPE,
                        pc_num_sini       a7000930.num_sini      %TYPE,
                        pc_max_fec_mvto   a7000930.fec_mvto      %TYPE)
   IS
      SELECT a.cod_cob, a.tip_exp, a.cod_consecuencia, a.mca_obligatorio,
             c.mca_exp_recobro
        FROM g7000080 a, g7000090 c
       WHERE a.cod_cia           = pc_cod_cia
         AND c.cod_cia           = pc_cod_cia
         AND a.cod_ramo          = pc_cod_ramo
         AND a.tip_exp           = c.tip_exp
         AND a.cod_causa         = pc_cod_causa
         AND a.cod_consecuencia
             IN (SELECT cod_consecuencia
                   FROM a7000930
                  WHERE cod_cia     = pc_cod_cia
                    AND num_sini    = pc_num_sini
                    AND tip_causa   = 1
                    AND cod_causa   = pc_cod_causa
                    AND fec_mvto    = pc_max_fec_mvto)
         AND a.mca_inh  = 'N'
         AND c.mca_sini = TRN.SI
       ORDER BY c.mca_exp_recobro, a.tip_exp;
   -- 26-01-11 -  MS-2011-01-00042 -  Fin
   --
   CURSOR c_a2000040   (pc_cod_cia        g7000080.cod_cia       %TYPE,
                        pc_cod_ramo       g7000080.cod_ramo      %TYPE,
                        pc_num_poliza     a2000040.num_poliza    %TYPE,
                        pc_num_spto       a2000040.num_spto      %TYPE,
                        pc_num_apli       a2000040.num_apli      %TYPE,
                        pc_num_spto_apli  a2000040.num_spto_apli %TYPE,
                        pc_num_riesgo     a2000040.num_riesgo    %TYPE,
                        pc_num_periodo    a2000040.num_periodo   %TYPE)
   IS
     SELECT cod_cob
       FROM a2000040
      WHERE cod_ramo      = pc_cod_ramo
        AND cod_cia       = pc_cod_cia
        AND num_poliza    = pc_num_poliza
        AND num_spto      = pc_num_spto
        AND num_apli      = pc_num_apli
        AND num_spto_apli = pc_num_spto_apli
        AND num_riesgo    = pc_num_riesgo
        AND num_periodo   = pc_num_periodo
        AND NVL(mca_baja_cob, 'N') = 'N';
   --
   CURSOR c_g7001200   (pc_cod_cia           g7001200.cod_cia           %TYPE,
                        pc_cod_causa         g7001200.cod_causa         %TYPE,
                        pc_cod_consecuencia  g7001200.cod_consecuencia  %TYPE,
                        pc_tip_exp           g7000080.tip_exp           %TYPE,
                        pc_cod_cob           g7001200.cod_cob           %TYPE)
   IS
     SELECT 'S'
       FROM g7001200
      WHERE cod_cia          = pc_cod_cia
        AND cod_causa        = pc_cod_causa
        AND cod_consecuencia = pc_cod_consecuencia
        AND tip_exp          = pc_tip_exp
        AND cod_cob          = pc_cod_cob;
   --
   l_mca_existe          VARCHAR2(1) := 'N';
   l_existe              BOOLEAN;
   l_puntero             NUMBER(5) := 0;
   l_devuelve_cod_cob    BINARY_INTEGER;
   l_devuelve_tip_exp    BINARY_INTEGER;
   l_max_fec_mvto        a7000930.fec_mvto     %TYPE;
   --
BEGIN
  --
  --@mx('I','p_query');
  --
  /* Borro la "tabla de memoria donde registro las claves. */
  --
  trn_k_clave.p_borra;
  --
  /* Cada cobertura de la poliza, la registro con el trn_k_clave. */
  --
  FOR reg2 IN c_a2000040 (g_cod_cia,
                          g_cod_ramo,
                          g_num_poliza,
                          g_max_spto_40,
                          g_num_apli,
                          g_max_spto_apli_40,
                          g_num_riesgo,
                          g_num_periodo)
 LOOP
    --
    /* Registro la cobertura en una "tabla de memoria" para saber las coberturas
      que tiene contratada la poliza. */
    --
    l_devuelve_cod_cob := trn_k_clave.f_devuelve (TO_CHAR(reg2.cod_cob));
    --
  END LOOP; -- Del bloque para cargar las coberturas con el trn_k_clave.
  --
  l_max_fec_mvto := ts_k_a7000930.f_maxima_fec_mvto (g_cod_cia,
                                                     g_num_sini,
                                                     1);        -- tip_causa
  --
  l_puntero := 0;
  --
  FOR reg1 IN  c_g7000080 (g_cod_cia,
                           g_cod_ramo,
                           g_cod_causa,
                           g_num_sini,
                           l_max_fec_mvto)
  LOOP
     --
     /* Si esta registrada la cobertura (la tiene contratada la poliza) y el
      expediente no esta registrado (no lo he grabado en mi tabla de memoria
      para ser mostrado por pantalla), lo grabo en mi tabla de memoria, siempre
      y cuando exista el registro en la g7001200. */
     --
     IF trn_k_clave.f_existe (reg1.cod_cob) AND
        NOT trn_k_clave.f_existe (reg1.tip_exp)
     THEN
       --
        /* Miro si hay datos en la g7001200 para la causa/consecuencia/cob/exp.*/
        --
        OPEN c_g7001200  (g_cod_cia            ,
                          g_cod_causa          ,
                          reg1.cod_consecuencia,
                          reg1.tip_exp         ,
                          reg1.cod_cob         );
        --
        FETCH c_g7001200 INTO l_mca_existe;
        l_existe := c_g7001200%FOUND;
        CLOSE c_g7001200;
        --
        IF l_existe
        THEN
           --
           l_puntero := l_puntero + 1;
           --
           gtb_tipos_de_expedientes(l_puntero).tip_exp      :=   reg1.tip_exp;
           --
           ts_k_g7000090.p_lee (g_cod_cia,
                                reg1.tip_exp);
           gtb_tipos_de_expedientes(l_puntero).nom_exp      :=  ts_k_g7000090.f_nom_exp;
           --
           gtb_tipos_de_expedientes(l_puntero).mca_obligatorio := reg1.mca_obligatorio;
           --
           gtb_tipos_de_expedientes(l_puntero).num_exp_aper    :=
                                             f_cuenta_exp_aper (reg1.tip_exp);
           --
           /* Incluido proceso para la apertura automatica (BATCH) */
           --
           ts_k_g7000100.p_lee (g_cod_cia,
                                g_cod_ramo,
                                reg1.tip_exp);
           --
           gtb_tipos_de_expedientes(l_puntero).mca_aper_aut    :=
                                    ts_k_g7000100.f_apertura_automatica(g_cod_cia,
                                                                        g_cod_ramo,
                                                                        reg1.tip_exp);
           --
           gtb_tipos_de_expedientes(l_puntero).nom_prg_nro_exp_aut :=
                                    ts_k_g7000100.f_nom_prg_nro_exp_aut;
           --
           gtb_tipos_de_expedientes(l_puntero).nro_exp_aut := 0;
           --
           /* Registro en una "tabla de memoria" el expediente para saber que ya
           lo tengo registrado en mi tabla de memoria de trabajo. */
           --
           l_devuelve_tip_exp := trn_k_clave.f_devuelve (reg1.tip_exp);
           --
        END IF; -- De si el registro existe en la g7001200 para poder insertarlo
                --en mi tabla de memoria.
        --
     END IF; -- De si la cobertura existe (si la tiene contratada en la poliza).
            -- y el expediente no lo he grabado en mi tabla de memoria. */
    --
  END LOOP; -- Para recorrer los expedientes que se pueden aperturar.
  --
  g_fila_devuelve  := NULL;
  g_max_secu_query := l_puntero;
  g_max_tipos_exp  := l_puntero;
  --
  IF l_puntero = 0
  THEN
     --
     /* NO HAY EXPEDIENTES DEFINIDOS PARA APERTURAR. 20316. */
     --
     g_cod_mensaje := 20316;
     g_anx_mensaje := NULL;
     --
     pp_devuelve_error;
     --
  END IF;
  --
  --@mx('F','p_query');
  --
END p_query;
--
/* --------------------------------------------------------------
|| Devuelve un registro de la tabla de memoria de los posibles expedientes
|| a aperturar.
*/ --------------------------------------------------------------
PROCEDURE p_devuelve
         (p_num_secu_k           IN OUT  NUMBER                          ,
          p_tip_exp              IN OUT  g7000080.tip_exp             %TYPE ,
          p_nom_exp              IN OUT  g7000090.nom_exp             %TYPE ,
          p_mca_obligatorio      IN OUT  g7000080.mca_obligatorio     %TYPE ,
          p_num_exp_aper         IN OUT  a7001000.num_exp             %TYPE ,
          p_mca_aper_aut         IN OUT  g7000100.mca_aper_aut        %TYPE )
IS
  --
BEGIN
  --
  --@mx('I','p_devuelve');
  --
  IF g_fila_devuelve IS NULL
  THEN
    --
    IF gtb_tipos_de_expedientes.EXISTS(gtb_tipos_de_expedientes.FIRST)
     THEN
      --
      g_fila_devuelve := gtb_tipos_de_expedientes.FIRST;
      --
      p_num_secu_k := g_fila_devuelve;
      --
      p_tip_exp       := gtb_tipos_de_expedientes(g_fila_devuelve).tip_exp;
      p_nom_exp       := gtb_tipos_de_expedientes(g_fila_devuelve).nom_exp;
      p_mca_obligatorio    :=
            gtb_tipos_de_expedientes(g_fila_devuelve).mca_obligatorio;
      p_num_exp_aper       :=
            gtb_tipos_de_expedientes(g_fila_devuelve).num_exp_aper;
      p_mca_aper_aut       :=
            gtb_tipos_de_expedientes(g_fila_devuelve).mca_aper_aut;
      --
    ELSE --Tabla  vacia
      --
      p_num_secu_k := NULL;
      --
      p_tip_exp          := NULL;
      p_nom_exp          := NULL;
      p_mca_obligatorio  := NULL;
      p_num_exp_aper     := NULL;
      p_mca_aper_aut     := NULL;
      --
      g_fila_devuelve := g_max_secu_query;
      --
    END IF;
    --
  ELSIF g_fila_devuelve != g_max_secu_query -- Hay pero no es el primero
  THEN
        --
        g_fila_devuelve := gtb_tipos_de_expedientes.NEXT(g_fila_devuelve);
        --
        p_num_secu_k := g_fila_devuelve;
        --
        p_tip_exp        :=gtb_tipos_de_expedientes(g_fila_devuelve).tip_exp;
        p_nom_exp        :=gtb_tipos_de_expedientes(g_fila_devuelve).nom_exp;
        p_mca_obligatorio:=
              gtb_tipos_de_expedientes(g_fila_devuelve).mca_obligatorio;
        p_num_exp_aper   :=
              gtb_tipos_de_expedientes(g_fila_devuelve).num_exp_aper;
        p_mca_aper_aut   :=
              gtb_tipos_de_expedientes(g_fila_devuelve).mca_aper_aut;
        --
    ELSE -- Es el ultimo porque es igual a la maxima fila
        --
        p_num_secu_k := NULL;
        --
        p_tip_exp            := NULL;
        p_nom_exp            := NULL;
        p_mca_obligatorio    := NULL;
        p_num_exp_aper       := NULL;
        p_mca_aper_aut       := NULL;
        --
  END IF;
  --
  --@mx('F','p_devuelve');
  --
END p_devuelve;
--
/* --------------------------------------------------------------
|| Procedimiento que controla el inicio de la apertura del expediente.
|| Procedimiento que se debe de llamar cuando se seleccione un tipo de
|| expediente.
*/ --------------------------------------------------------------
PROCEDURE p_selecciona_expediente
          ( p_tip_exp               IN     a7001000.tip_exp       %TYPE,
            p_pide_moneda           IN OUT VARCHAR2                    ,
            p_pide_causas_aper      IN OUT g7000100.mca_causa_aper%TYPE,
            p_pide_exp_a_aperturar  IN OUT VARCHAR2                    )
IS
BEGIN
  --
  --@mx('I','p_selecciona_expediente');
  --
  g_tip_exp          := p_tip_exp;
  --
  g_num_exp_afec     :=  NULL;
  g_tip_exp_afec     :=  NULL;
  g_tip_est_afec     :=  NULL;
  g_tip_docum_exp    :=  NULL;
  g_cod_docum_exp    :=  NULL;
  g_nombre_exp       :=  NULL;
  g_apellidos_exp    :=  NULL;
  g_mca_rva_manual   :=  NULL;
  --
  p_pide_causas_aper := 'N';
  --
  IF g_tip_exp IS NOT NULL
  THEN
     --
     ts_k_a7000900.p_lee_a7000900 (g_cod_cia,
                                   g_num_sini);
     --
     ts_k_g7000100.p_lee (g_cod_cia,
                          g_cod_ramo,
                          g_tip_exp);
     --
     g_cod_mon := ts_k_g7000100.f_cod_mon;
     --
     ts_k_g7000090.p_lee (g_cod_cia, g_tip_exp);
     --
     IF ts_k_g7000090.f_mca_inh = 'S'
     THEN
         --
         /* CODIGO INHABILITADO. 200020.*/
         --
         g_cod_mensaje := 20020;
         g_anx_mensaje := ' G7000090 ';
         --
         pp_devuelve_error;
      --
     END IF;
    --
     /* Asigno esta global, para indicar que estoy en la apertura de
       expedientes.*/
     --
     trn_k_global.asigna ('mca_apertura', 'S');
     --
     IF NVL(ts_k_g7000100.f_mca_unico, 'S') = 'S' AND
        NVL(ts_k_a7001000.f_cuenta_exp (g_cod_cia, g_num_sini, g_tip_exp),0) != 0
     THEN
         --
         trn_k_global.asigna('DEFINICION','N');
         --
         /* SOLO SE PUEDE APERTURAR UN EXPEDIENTE DE ESE TIPO. 20320 */
        --
        g_cod_mensaje := 20320;
        g_anx_mensaje := NULL;
        --
        pp_devuelve_error;
       --
     END IF;
     --
     IF NVL(ts_k_g7000100.f_mca_mon_unica, 'S') = 'S'
     THEN
        --
        p_pide_moneda := 'N';
        --
     ELSE
        --
        p_pide_moneda := 'S';
        --
     END IF;
     --
     -- Se lee la marca de causas de apertura de la tabla de
     -- parametros generales de siniestros por compaÃ±ia, g7000000,
     -- para pedir causas de apertura en caso de que la marca sea 'S'.
     ts_k_g7000000.p_lee(g_cod_cia);
     --
     IF NVL(ts_k_g7000000.f_mca_causa_aper, 'S') = 'S'
     THEN
        --
        -- Si para la apertura del tipo de expediente se piden causas es necesario
        -- asignar la global tip_exp para la rutina de causas.
        --
        trn_k_global.asigna('tip_exp', g_tip_exp);
        --
        IF NVL(ts_k_g7000100.f_mca_causa_aper, 'S') = 'S' AND
           (NVL(trn_k_global.ref_f_global('tip_mvto_batch_stro'),'0') = '21'  OR
           trn_k_global.ref_f_global('tip_mvto_batch_stro') IS NULL)
        THEN
           --
           IF ts_k_a7000200.f_existe_con_tip_exp ( g_cod_cia           ,
                                                   g_cod_ramo          ,
                                                   g_tip_causa_aper_exp,
                                                   NULL                , -- cod_causa
                                                   g_tip_exp           ) != 'S'
           THEN
              --
              /* NO HAY CAUSAS DEFINIDAS PARA EL RAMO */
              g_cod_mensaje := g_cm_causas_no_definidas;
              g_anx_mensaje := NULL;
              pp_devuelve_error;
              --
           ELSE
              --
              p_pide_causas_aper := 'S';
              --
           END IF;
           --
        ELSE
           --
           p_pide_causas_aper := 'N';
           --
        END IF;
        --
     ELSE
     --
        p_pide_causas_aper := 'N';
     --
     END IF;
     --
     IF NVL(ts_k_g7000090.f_mca_exp_recobro, 'N') = 'S'
     THEN
        --
        p_pide_exp_a_aperturar  := 'S';
        --
     ELSE
        --
        p_pide_exp_a_aperturar  := 'N';
        --
    END IF;
    --
    trn_k_global.asigna('s_consulta','N');
    --
    IF ts_k_g7000100.f_mca_valoracion_ajustada = g_k_si
    THEN
       --
       trn_k_global.asigna('cambia_valoracion',g_k_si);
       --
    ELSE
       --
       trn_k_global.asigna('cambia_valoracion',g_k_no);
       --
    END IF;
    --
  ELSE
     trn_k_global.asigna('DEFINICION','N');
     --
     /* NO HAY EXPEDIENTES DEFINIDOS PARA APERTURAR. 20316.*/
     --
     g_cod_mensaje := 20316;
     g_anx_mensaje := NULL;
     --
     pp_devuelve_error;
     --
  END IF; -- Si el tipo de expediente no es nulo
  --
  --@mx('F','p_selecciona_expediente');
  --
END p_selecciona_expediente;
--
/* --------------------------------------------------------------
||  Procedimiento que continua con la apertura del expediente.
||  Procedimiento que se llama, o bien despues de p_selecciona_expediente o
|| despues de pedir la moneda del expediente (en caso de pedirse).
||  Inserta el expediente en la A700100.
||  Devuelve el codigo del programa (estructura) al cual hay que llamar.
*/ --------------------------------------------------------------
PROCEDURE p_inserta_expediente
          (p_cod_pgm_exp      IN OUT g9990003.cod_pgm        %TYPE)
IS
   g_tip_tramitador   a1001339.tip_tramitador  %TYPE := NULL;
   --
   PROCEDURE pi_inserta_a7001000
   IS
     --
     li_tip_exp         a7001000.tip_exp         %TYPE := NULL;
     li_tip_docum       a7001000.tip_docum       %TYPE := NULL;
     li_cod_docum       a7001000.cod_docum       %TYPE := NULL;
     li_nombre          a7001000.nombre          %TYPE := NULL;
     li_apellidos       a7001000.apellidos       %TYPE := NULL;
     --
   BEGIN
     --
     --@mx('I','pi_inserta_a7001000');
     --
     /*
     g_num_exp := NVL(ts_k_a7001000.f_cuenta_exp (g_cod_cia, g_num_sini,
                                                  li_tip_exp), 0) + 1;
     */
     --
     /* 26-04-2006.
         Para obtener el numero de expediente a insertar, en vez de contar
        el numero de expedientes, lo que se hace es obtener el maximo
        numero de expediente. */
     --
     g_num_exp := NVL(ts_k_a7001000.f_max_num_exp (g_cod_cia,
                                                   g_num_sini), 0) + 1;
     --
     IF NVL(ts_k_g7000100.f_mca_mon_unica, 'N') = 'S'
     THEN
        --
        IF g_cod_mon = 99    -- Esta es la de la definicion (g7000100).
        THEN
           --
           g_cod_mon_exp := ts_k_a7000900.f_cod_mon;
           --
        ELSE
           --
           g_cod_mon_exp := g_cod_mon;
           --
        END IF;
        --
     ELSIF g_cod_mon = 99 -- Esta es la moneda que introduce el usuario.
     THEN
           --
           g_cod_mon_exp := ts_k_a7000900.f_cod_mon;
           --
     ELSE
           --
           g_cod_mon_exp := g_cod_mon;
           --
     END IF;
     --
     /* Antes de insertar en la a7001000, leo de la definicion el tipo de
       expediente, ya que si es un recobro, el ultimo p_lee que he hecho de
       esta tabla (g7000090), es para leer el nombre del tipo de expediente
       afectado.
     */
     --
     ts_k_g7000090.p_lee (g_cod_cia, g_tip_exp);
     --
     ts_k_a7001000.p_inserta( g_cod_cia          ,
                              g_cod_sector       ,
                              g_cod_ramo         ,
                              g_num_sini         ,
                              g_num_exp          ,
                              g_tip_exp          ,
                              ts_k_g7000090.f_mca_exp_recobro  ,
                              g_num_exp_afec     ,
                              g_tip_exp_afec     ,
                              g_tip_est_afec     ,
                              g_fec_proceso      ,
                              li_tip_docum       ,
                              li_cod_docum       ,
                              li_nombre          ,
                              li_apellidos       ,
                              g_cod_mon_exp      ,
                              g_cod_supervisor   ,
                              g_cod_tramitador   ,
                              g_tip_apertura
                            );
     --
     --@mx('F','pi_inserta_a7001000');
     --
   END pi_inserta_a7001000;
   --
   PROCEDURE pi_llamada_est_exp
   IS
     --
     li_cod_est_exp    g7000100.cod_est       %TYPE;
     li_cod_grp_est    g9990002.cod_grp_est   %TYPE := '3'; -- Datos fijos del expediente.
     --
   BEGIN
     --
     --@mx('I','pi_llamada_est_exp');
     --
     dc_k_g1000900.p_lee( g_cod_cia );
     --
     li_cod_est_exp := ts_k_g7000100.f_cod_est;
     --
     IF li_cod_est_exp = '9999999999'
     THEN
        --
        IF ts_k_g7000100.f_nom_prg_cod_est IS NOT NULL
        THEN
           --
           li_cod_est_exp := ts_k_g7000100.f_asigna_cod_est(g_cod_cia,
                                                            g_cod_ramo,
                                                            g_tip_exp);
           --
        ELSE
           --
           p_cod_pgm_exp := '9999999999';
           --
        END IF;
        --
     END IF;
     --
     --@mx('*','pi_llamada_est_exp - li_cod_est_exp = '||li_cod_est_exp);
     --@mx('*','pi_llamada_est_exp - p_cod_pgm_exp = '||p_cod_pgm_exp);
     --
     /* 03-04-2008.
        Si el cÃ³digo de estructura es diferente de 9999999999, deberemos buscar
      el cÃ³digo de programa correspondiente.
        Pero por si el procedimiento nos devuelve de nuevo la estructura 9999999999,
      debemos devolver como programa el 9999999999 para que no se llame a
      ninguna estructura de datos. */
     --
     IF li_cod_est_exp = '9999999999'
     THEN
        --
        p_cod_pgm_exp := '9999999999';
        --
     ELSE
        --
        trn_k_global.asigna('cod_est', li_cod_est_exp);
        --
        dc_k_g9990003.p_lee (li_cod_est_exp);
        --
        IF dc_k_g9990003.f_nom_prg_carga_est IS NULL
        THEN
          --
          p_cod_pgm_exp  := dc_k_g9990003.f_cod_pgm;
          --
        ELSE
          --
          ss_k_programas.p_lee ( dc_k_g9990003.f_cod_pgm );
          --
          IF ss_k_programas.f_tip_pgm = 'PNL'
          THEN
            --
            p_cod_pgm_exp  := dc_k_g1000900.f_cod_pgm_exp;
            --
          ELSE
            --
            p_cod_pgm_exp := dc_k_g9990003.f_cod_pgm;
            --
          END IF; -- Si tip_pgm ='PNL'
          --
        END IF; -- If nom_prg_carga
        --
        g_cod_pgm_est := p_cod_pgm_exp;
        g_nom_prg_exp := dc_k_g9990003.f_nom_prg;
        --
        -- 09-10-2007. Se asigna el codigo de agrupacion datos fijos del
        -- expediente, para que este disponible en las estructuras y asi poder
        -- validar si la estructura es o no obligatoria.
        --
        trn_k_global.asigna('cod_grp_est', li_cod_grp_est);
        --
     END IF;
     --
     --@mx('F','pi_llamada_est_exp');
     --
   END pi_llamada_est_exp;
   --
   --
BEGIN
  --
  --@mx('I','p_inserta_expediente');
  --
  /* Antes de grabar en la A7001000, pongo un SAVEPOINT expediente, de forma
    que si en la estructura de datos abandonan, deshare la insercion en la
    A7001000. */
  --
  SAVEPOINT expediente;
  --
  /* Llamo a la nueva rutina para reasignar tramitador */
  --
  ts_p_obtiene_tramitador (g_cod_cia,
                           g_cod_sector,
                           g_cod_ramo,
                           g_num_poliza,
                           g_cod_nivel3,
                           g_cod_trami_usu ,
                           g_tip_exp,
                           g_cod_docum_tramitador,
                           g_tip_docum_tramitador,
                           g_cod_tramitador_nuevo);
  --
  /* Se mira si despues del ts_p_obtiene tramitador cambia el supervisor
     y el tramitador con respecto al de la apertura*/
  --
  IF g_cod_tramitador_nuevo != g_cod_tramitador
  THEN
     g_cod_tramitador := g_cod_tramitador_nuevo;
     --
  END IF;
  --
  -- Change for 1.86: the references to package ts_k_a1001339 are replaced by dc_k_a1001339
  dc_k_a1001339.p_lee_cod_tramitador (p_cod_cia        => g_cod_cia       ,
                                      p_cod_tramitador => g_cod_tramitador);
  --
  g_cod_supervisor := dc_k_a1001339.f_cod_supervisor;
  --
  g_tip_tramitador := dc_k_a1001339.f_tip_tramitador;
  --
  g_tip_tramitador           :=  ts_k_tramitacion.f_evalua_tip_tramitador(g_cod_cia,
                                                                  g_cod_sector,
                                                                  g_cod_ramo,
                                                                  g_cod_tramitador,
                                                                  g_tip_tramitador);
  --
  IF g_tip_tramitador != 'T'
  THEN
    /* USUARIO NO DEFINIDO COMO TRAMITADOR (por que no existe en la a1001339)*/
    g_cod_mensaje  := 20348;
    g_anx_mensaje  := ' A1001339 [ts_k_as700030]';
    --
    pp_devuelve_error;
    --
  END IF;
  --
  /* Inserto los datos del expediente */
  --
  IF NVL(trn_k_global.ref_f_global('tip_mvto_batch_stro'),'0') = '0'
  THEN
    g_tip_apertura := 'M';
  ELSE
    g_tip_apertura := 'A';
  END IF;
  --
  pi_inserta_a7001000;
  --
  /* Devuelvo el codigo del programa al que hay que llamar para cargar los
    datos del expediente. Si la estructura es 9999999999 comprobarÃ¡ si existe
    un procedimiento que devuelva el cÃ³digo de la estructura, o es un tipo de
    expediente sin estructura de datos asociada. */
  --
  /* 30/08/2007 - marianj
  IF ts_k_g7000100.f_cod_est != '9999999999'
  THEN
    pi_llamada_est_exp;
  ELSE
    p_cod_pgm_exp := '9999999999';
  END IF;
  */
  --
  --@mx('*','ts_k_g7000100.f_cod_est: ' || ts_k_g7000100.f_cod_est );
  --@mx('*','p_cod_pgm: ' || p_cod_pgm_exp );
  --
  /* Asigno las globales que necesito */
  --
  trn_k_global.asigna ('num_sini',     TO_CHAR(g_num_sini));
  trn_k_global.asigna ('num_exp',      TO_CHAR(g_num_exp));
  trn_k_global.asigna ('tip_exp',      g_tip_exp);
  trn_k_global.asigna ('num_exp_afec', TO_CHAR(g_num_exp_afec));
  trn_k_global.asigna ('tip_exp_afec', g_tip_exp_afec);
  trn_k_global.asigna ('tip_est_afec', g_tip_est_afec);
  trn_k_global.asigna ('fec_aper_exp', TO_CHAR(g_fec_proceso,'DDMMYYYY'));
  --
  pi_llamada_est_exp;
  --
  --@mx('F','p_inserta_expediente');
  --
EXCEPTION
WHEN OTHERS
THEN
  --
  RAISE_APPLICATION_ERROR (SQLCODE, SQLERRM);
  --
END p_inserta_expediente;
--
/* --------------------------------------------------------------
|| Procedimiento que devuelve el valor por defecto de la moneda del expdte.
|| Se debe de llamar al inicio de la ventana en la que se va a pedir la moneda
|| del expediente.
*/ --------------------------------------------------------------
PROCEDURE p_devuelve_cod_mon_exp
          (p_tip_exp          IN OUT    a7001000.tip_exp        %TYPE,
           p_cod_mon          IN OUT    a7001000.cod_mon        %TYPE,
           p_nom_mon          IN OUT    a1000400.nom_mon        %TYPE)
IS
BEGIN
  --
  --@mx('I','p_devuelve_cod_mon_exp');
  --
  p_tip_exp := g_tip_exp;
  --
  /* Si la moneda leida de la definicion del expediente, es la 99, por defecto,
    devuelvo la moneda de la poliza (la del siniestro), si no es 99, devuelvo
    la de la definicion (g7000100). */
  --
  IF g_cod_mon = 99
  THEN
     --
     p_cod_mon := ts_k_a7000900.f_cod_mon;
     --
  ELSE
     --
     p_cod_mon := g_cod_mon;
     --
  END IF;
  --
  dc_k_a1000400.p_lee (p_cod_mon);
  --
  p_nom_mon := dc_k_a1000400.f_nom_mon;
  --
  --@mx('F','p_devuelve_cod_mon_exp');
  --
END p_devuelve_cod_mon_exp;
--
/* --------------------------------------------------------------
|| Procedimiento de validacion de la moneda del expediente.
*/ --------------------------------------------------------------
PROCEDURE p_v_cod_mon
          ( p_cod_mon          IN        a7001000.cod_mon        %TYPE,
            p_nom_mon          IN OUT    a1000400.nom_mon        %TYPE)
IS
BEGIN
  --
  --@mx('I','p_v_cod_mon');
  --
  g_cod_mon := p_cod_mon;
  --
  IF g_cod_mon IS NOT NULL
  THEN
     --
     dc_k_a1000400.p_lee (g_cod_mon);
     --
     p_nom_mon := dc_k_a1000400.f_nom_mon;
     --
     /* Valido que para la moneda introducida, exista cambio a la fecha */
     --
     BEGIN
       --
       dc_k_a1000500.p_lee_max_fecha
                   (g_cod_mon,
                    TO_DATE(trn_k_global.devuelve('fec_proceso'),'DDMMYYYY'));
       --
     EXCEPTION
     WHEN OTHERS
     THEN
          /* CODIGO DE MONEDA: %1 SIN TIPO DE CAMBIO DEFINIDO. 20183.*/
          --
          g_cod_mensaje := 20183;
          g_anx_mensaje := NULL;
          --
          pp_devuelve_error;
     END;
     --
  ELSE
     --
     p_nom_mon := NULL;
     --
  END IF;
  --
  --@mx('F','p_v_cod_mon');
  --
EXCEPTION
WHEN OTHERS
THEN
  --
  RAISE_APPLICATION_ERROR (SQLCODE, SQLERRM);
  --
--
END p_v_cod_mon;
--
/* --------------------------------------------------------------
|| Procedimiento que dependiendo del parametro p_valoracion_ajustada,
|| Insertara en la h7001200 por reserva promedio, o devolvera el
|| codigo del programa al cual se va a llamar.
*/ --------------------------------------------------------------
PROCEDURE p_valoracion_expediente
          ( p_valoracion_ajustada IN        VARCHAR2                     ,
            p_cod_pgm_valoracion  IN OUT    g9990003.cod_pgm        %TYPE,
            p_mca_hay_errores_ct  IN OUT    VARCHAR2                      )
IS
  --
  l_opcion    NUMBER    := 1;
  --
BEGIN
  --
  --@mx('I','p_valoracion_expediente');
  --
  p_mca_hay_errores_ct := 'N';
  --
  IF NVL(p_valoracion_ajustada, 'N') = 'N'
  THEN
    --
    pp_reserva_promedio;
    --
    g_mca_rva_manual := 'N';
    --
    IF ts_k_as799001.f_calcula_errores ( g_k_cod_sistema               ,
                                         g_k_cod_nivel_salto6          ,
                                         g_k_mca_puede_haber_auditoria ,
                                         g_cod_pgm                     ) > 0
    THEN
      p_mca_hay_errores_ct := 'S';
    END IF;
    --
  ELSE
     --
     IF ts_k_g7000100.f_mca_factura = g_k_si
     THEN
        --
        -- La versiÃ³n _trn, devuelve el AP300000, FacturaciÃ³n de Salud.
        --
        p_cod_pgm_valoracion := NVL(ts_k_esp_instalacion.f_nom_pgm ( l_opcion ), 'AP300000');
        --
     ELSE
        --
        p_cod_pgm_valoracion := NVL(ts_k_esp_instalacion.f_nom_pgm_valoracion, 'AP700105');
        --
     END IF;
     --
     g_mca_rva_manual := g_k_si;
     --
  END IF;
  --
  g_mca_hay_errores_ct := p_mca_hay_errores_ct;
  --
  --@mx('F','p_valoracion_expediente');
  --
END p_valoracion_expediente;
--
/* --------------------------------------------------------------
|| Procedimiento que inserta el resto de tablas que se necesitan para
|| la apertura del expediente.
*/ --------------------------------------------------------------
PROCEDURE p_graba_resto_exp
IS
  --
  l_tip_causa          a7001030.tip_causa         %TYPE := 15;
  l_cod_causa          a7001030.cod_causa         %TYPE := ts.cod_causa_gen;
  l_fec_mvto           a7001030.fec_mvto          %TYPE;
  --
  l_num_modificacion   a7001020.num_modificacion  %TYPE;
  l_mca_estado         a7001020.mca_estado        %TYPE := 'P';
  --
  l_supervisor_au      a7001020.cod_supervisor    %TYPE;
  l_num_siniestros     a1001338.num_siniestros    %TYPE;
  --
  l_cod_plan           g7000100.cod_plan          %TYPE;
  --
  l_puntero            NUMBER(5)                        := 0;
  --
  PROCEDURE pi_traspasa_errores_ct IS
    --
    /* 02-04-2008.
        Creo dos variables diferentes para saber si existen errores
     del nivel 5 y al final del procedimiento preguntar por ella
     para modificar o no la h7001200.
        Los del nivel 6, son unicamente los producidos en las valoraciones
     promedio.*/
    --
    l_mca_provisional_5    h7001200.mca_provisional %TYPE;
    l_mca_provisional_6    h7001200.mca_provisional %TYPE;
    --
  BEGIN
    --
    --@mx('I','pi_traspasa_errores_ct');
    --@mx('g_cod_cia:  ', g_cod_cia);
    --@mx('g_num_sini: ', g_num_sini);
    --@mx('g_num_exp:  ', g_num_exp);
    --
    l_mca_provisional_5 := 'N';
    l_mca_provisional_6 := 'N';
    --
    /* El nivel 5, es de Datos Fijos del Expediente y la inserccion
      en la a2000220 se controla desde esta Rutina de Apertura de Expedientes
       Si los hubiera, se insertara en la a2000220 los errores del
      nivel de salto 5 y se dejara retenido el expediente en la a7001000.*/
    --
    ts_k_as799001.p_actualiza ( l_mca_provisional_5 ,
                                g_k_cod_sistema     ,
                                g_k_cod_nivel_salto5 );
    --
    /* Ahora realizamos el tratamiento del C.Tecnico del nivel 6 cuando
     la valoracion ha sido promedio, es decir, insertaremos en la a2000220,
     y dejaremos retenido el expediente tanto en la a7001000 como en la
     h7001200.
       Si la valoracion no es promedio, es decir, llamamos al Ajuste de
     reservas (AP700105) o a otro programa (facturacion), seran estos
     programas los que se encargen del tratamiento del nivel 6 de C.T.
     insertardo en la a2000220, reteniendo el expediente tanto en la
     a7001000 como en la h7001200.
      --
      La g_mca_hay_errores_ct, unicamente serÃ¡ igual a S si hay errores
     del nivel de salto 6 cuando hemos lanzado la valoracion promedio.
    */
    --
    IF g_mca_hay_errores_ct = 'S'
    THEN
       --
       --@mx('*','Hay errores_ct del nivel 6 por valoracion promedio');
       --
       --@mx('*','Actualizo a S la a7001000.mca_provisional');
       --
       ts_k_as799001.p_actualiza ( l_mca_provisional_6 ,
                                   g_k_cod_sistema     ,
                                   g_k_cod_nivel_salto6 );
       --
       IF l_mca_provisional_6 = 'S'
       THEN
         --
         --@mx('*','Actualizo a S la h7001200.mca_provisional');
         --
         /* Actualiza la h7001200 para dejar la mca_provisional a 'S',
           ya que al ser una valoracion promedio, los registros se insertan con la
           mca_provisional a N y como el expediente se ha quedado retenido por
           C.T, hay que dejarlo tambien retenido en la h7001200.*/
         --
         ts_k_h7001200.p_retiene  (g_cod_cia,
                                   g_num_sini,
                                   g_num_exp);
         --
       END IF;
       --
    END IF; -- De si hay errores C.T. nivel 6 por una valoracion promedio.
    --
    /* 02-04-2008.
       Ahora tengo que ver si existen errores del nivel 5 para dejar retenido
      el expediente en la h7001200.
       Solo lo realizare si NO se ha quedado retenido por el nivel 6 en la
      valoracion promedio, pues en ese caso, la modificacion de la mca_provisional
      a S en la h7001200, se ha hecho anterioremente.*/
    --
    IF l_mca_provisional_5 = 'S' AND
       l_mca_provisional_6 = 'N'
    THEN
      --
      --@mx('*', 'Hay errores del nivel 5 y NO del 6 por valoracion promedio. Dejo retenida la h7001200');
      --
      ts_k_h7001200.p_retiene  (g_cod_cia,
                                g_num_sini,
                                g_num_exp);
      --
    END IF;
    --
    --@mx('F','pi_traspasa_errores_ct');
    --
  END pi_traspasa_errores_ct;
  --
BEGIN -- P_graba_resto_exp
  --
  --@mx('I','p_graba_resto_exp');
  --
  pi_traspasa_errores_ct;
  --
  /* Actualizo la a7001000.
    La persona relacionada.
    El importe inicial, el importe valorado, el importe valorado neto, el
    porcentaje de coaseguro y si es reserva manual. Las marcas de los
    recobros. */
  --
  ts_k_a7001000.p_actualiza_datos_persona_rel
           (g_cod_cia,
            g_num_sini,
            g_num_exp,
            NULL,               -- fec_modi_exp
            trn_k_global.ref_f_global('tip_docum_exp'),  -- g_tip_docum_exp
            trn_k_global.ref_f_global('cod_docum_exp'),  -- g_cod_docum_exp
            trn_k_global.ref_f_global('nombre_exp'),     -- g_nombre_exp
            trn_k_global.ref_f_global('apellidos_exp')); -- g_apellidos_exp
  --
  /* Se borran las globales, despuÃ©s de actualizar la tabla a7001000, para que no
   haya problemas con el siguiente expediente si estas globales no se vuelven a
   asignar */
  --
  trn_k_global.borra_variable('tip_docum_exp');
  trn_k_global.borra_variable('cod_docum_exp');
  trn_k_global.borra_variable('nombre_exp'   );
  trn_k_global.borra_variable('apellidos_exp');
  --
  ts_k_a7001000.p_actualiza_reserva_apertura
                (g_cod_cia,
                 g_num_sini,
                 g_num_exp,
                 g_mca_rva_manual);
  --
  IF g_num_exp_afec <> 0
  THEN
     --
     ts_k_a7001000.p_actualiza_estado_recobro (g_cod_cia,
                                               g_num_sini,
                                               g_num_exp_afec,
                                               'P'       -- tip_est_recobro
                                               );
     --
  END IF;
  --
  /* Inserto en la a7001030,
      Una causa automatica de apertura de expediente. (tip_causa=15). */
  --
  l_fec_mvto := ts_f_fec_mvto_causa
                (g_cod_cia,
                 g_num_sini,
                 g_num_exp,
                 l_tip_causa,
                 g_fec_proceso);
  --
  ts_k_g7000000.p_lee(g_cod_cia);
  --
  IF NVL(ts_k_g7000100.f_mca_causa_aper, 'S') = 'S' AND
     NVL(ts_k_g7000000.f_mca_causa_aper, 'S') = 'S' AND
     (NVL(trn_k_global.ref_f_global('tip_mvto_batch_stro'),'0') = '21'  OR
     trn_k_global.ref_f_global('tip_mvto_batch_stro') IS NULL)
  THEN
     --
     -- l_num_causas  NUMBER(3) := ts_k_as700040.f_num_causas;
     FOR i IN 1..ts_k_as700040.f_num_causas
     LOOP
        --
        ts_k_a7001030.p_inserta (g_cod_cia                   ,
                                 g_num_sini                  ,
                                 g_num_exp                   ,
                                 l_tip_causa                 ,
                                 ts_k_as700040.f_cod_causa(i),
                                 l_fec_mvto                  );
        --
     END LOOP;
  --
  ELSE
     --
     ts_k_a7001030.p_inserta (g_cod_cia  ,
                              g_num_sini ,
                              g_num_exp  ,
                              l_tip_causa,
                              l_cod_causa,
                              l_fec_mvto );
  END IF;
  --
  /* Inserto en la a7001020.*/
  --
  BEGIN
    --
    ts_k_a7001020.p_lee (g_cod_cia, g_num_sini, g_num_exp);
    l_num_modificacion := ts_k_a7001020.f_num_modificacion + 1;
    --
  EXCEPTION
  WHEN ge_no_existe
  THEN
    --
    l_num_modificacion := 1;
    --
  END;
  --
  ts_k_a7001020.p_inserta_a7001020
                (g_cod_cia,
                 g_cod_sector,
                 g_cod_ramo,
                 g_cod_supervisor,
                 g_cod_tramitador,
                 g_num_sini,
                 g_num_exp,
                 l_num_modificacion,
                 l_mca_estado,
                 NULL,                    -- observaciones
                 g_fec_proceso,
                 trn_k_global.cod_usr);
  --
  IF ts_k_g7000100.f_mca_factura = g_k_si
  THEN
     --
     ts_k_a7001000.p_lee_a7001000(g_cod_cia, g_num_sini, g_num_exp);
     --
     IF ts_k_a7001000.f_tip_est_exp = 'T'
     THEN
        --
        ts_k_a7001020.p_inserta_a7001020(g_cod_cia,
                                         g_cod_sector,
                                         g_cod_ramo,
                                         g_cod_supervisor,
                                         g_cod_tramitador,
                                         g_num_sini,
                                         g_num_exp,
                                         l_num_modificacion + 1,
                                         'T',
                                         NULL,               -- observaciones
                                         g_fec_proceso,
                                         trn_k_global.cod_usr);
        --
     END IF; -- SI ESTA EL EXPEDIENTE TERMINADO
     --
  END IF; -- SI ES EXPEDIENTE DE FACTURACION
  --
  /* Actualizo el numero de casos del tramitador */
  --
  IF g_cod_tramitador IS NOT NULL
  THEN
    --
    -- Change for 1.86: the references to package ts_k_a1001339 are replaced by dc_k_a1001339
    --
    dc_k_a1001339.p_lee_cod_tramitador (p_cod_cia        => g_cod_cia       ,
                                        p_cod_tramitador => g_cod_tramitador);
    --
    dc_k_a1001339.p_actualiza (p_cod_cia        => g_cod_cia,
                               p_cod_tramitador => g_cod_tramitador,
                               p_num_siniestros => NVL(dc_k_a1001339.f_num_siniestros, 0) + 1);
    --
  END IF;
  --
 /*Se verifica que no haya un registro con expediente 0 (Siniestros) con estado AU
  porque si existe lo que se harÃ¡ serÃ¡ insertar un registro 'P' para el siniestro */
  --
  BEGIN
       IF ts_k_a7001020.f_ultimo_estado( g_cod_cia   ,
                                         g_num_sini   ,
                                             0    ) = 'AU'
       THEN
       --
          ts_k_a7001020.p_lee (g_cod_cia, g_num_sini, NULL);
          --
          l_num_modificacion := ts_k_a7001020.f_num_modificacion + 1;
          l_supervisor_au    :=  NVL(ts_k_a7001020.f_cod_supervisor,0);
          --
          ts_k_a7001020.p_inserta_a7001020
                        (g_cod_cia,
                         g_cod_sector,
                         g_cod_ramo,
                         g_cod_supervisor,
                         g_cod_tramitador,
                         g_num_sini,
                         0,                               -- g_num_exp,
                         l_num_modificacion,
                        'P',                             -- l_mca_estado,
                         NULL,                            -- observaciones
                         g_fec_proceso,
                         trn_k_global.cod_usr);
          --
          -- Si el supervisor del expediente es distinto que el supervisor que tenÃ­a
          -- el siniestro se resta un caso al anterior supervisor.
          --
          IF g_cod_supervisor != l_supervisor_au
          THEN
             -- Restar un caso al supervisor antiguo
             ts_k_a1001338.p_lee_cod_supervisor ( g_cod_cia         ,
                                                  l_supervisor_au );
             --
             l_num_siniestros       := NVL(ts_k_a1001338.f_num_siniestros, 0)  - 1;
             --
             ts_k_a1001338.p_actualiza ( g_cod_cia        ,
                                         l_supervisor_au   ,
                                         l_num_siniestros );
             --
             -- Sumar un caso al supervisor nuevo
             --
             ts_k_a1001338.p_lee_cod_supervisor ( g_cod_cia         ,
                                                  g_cod_supervisor );
             --
             l_num_siniestros       := NVL(ts_k_a1001338.f_num_siniestros, 0)  + 1;
             --
             ts_k_a1001338.p_actualiza ( g_cod_cia             ,
                                         g_cod_supervisor       ,
                                         l_num_siniestros );
             --
          END IF;
          --
       END IF;
--
  EXCEPTION
  WHEN OTHERS
  THEN
    --
    NULL;
    --
  END;
  --
  /* Inserto el Plan de Tramitacion del expediente */
  --
  l_cod_plan := ts_k_g7000100.f_asigna_cod_plan( g_cod_cia,
                                                 g_cod_ramo,
                                                 g_tip_exp);
  --
  IF l_cod_plan IS NOT NULL
  THEN
    --
    ts_k_a7500000.p_inserta_plan (g_cod_cia, g_num_sini, g_num_exp, l_cod_plan,
                                  g_cod_tramitador);
    --
  END IF;
  --
  /* Si NO es un RECOBRO, lanzo el procedimiento para los suplementos de
    baja de capital (a7001005). */
  --
  IF NVL(ts_k_g7000090.f_mca_exp_recobro, 'N') = 'N'
  THEN
    --
    ts_k_a7001005.p_coberturas_baja_capital (g_cod_cia,
                                             g_num_sini,
                                             g_num_exp);
    --
  END IF;
  --
  /* Actualizo el campo num_exp_aper de mi tabla de memoria, para ver si
    se han aperturado los expedientes obligatorios.
     Busco en la tabla de memoria, el registro del expediente que estoy
    aperturando. */
  --
  l_puntero := 0;
  --
  WHILE l_puntero < g_max_secu_query
  LOOP
    --
    l_puntero := l_puntero + 1;
    --
    IF gtb_tipos_de_expedientes(l_puntero).tip_exp = g_tip_exp
    THEN
      --
      gtb_tipos_de_expedientes(l_puntero).num_exp_aper    :=
                                           f_cuenta_exp_aper (g_tip_exp);
      --
    END IF;
    --
  END LOOP;
  --
  /* Generacion de avisos a nivel de expediente. */
  --
  /* El p_lee de la g7000100, se hace en el p_selecciona_expediente, donde
    ya tenemos el expediente que se va a tratar.*/
  --
  IF ts_k_g7000100.f_nom_prg_aviso_aut IS NOT NULL
  THEN
    BEGIN
      --
      trn_k_dinamico.p_ejecuta_procedimiento(ts_k_g7000100.f_nom_prg_aviso_aut);
      --
    EXCEPTION
    WHEN OTHERS
    THEN
      --
      /* Si se produce un error en el procedimiento, borro la global para no
        insertar el Aviso.*/
      --
      trn_k_global.borra_variable ('nom_aviso');
      --
    END;
    --
    IF trn_k_global.ref_f_global ('nom_aviso') IS NOT NULL
    THEN
      --
      ts_k_ap750000.p_inserta_aviso_general_exp
                    (g_cod_cia,
                     g_num_sini,
                     g_num_exp,
                     NVL(trn_k_global.ref_f_global ('sub_tip_tramite'), 'AP'),
                     'N',      -- mca_privado
                     trn_k_global.ref_f_global ('nom_aviso'),
                     NVL(trn_k_global.ref_f_global ('num_dias'), 0),
                     g_cod_tramitador);
      --
    END IF;
    --
    trn_k_global.borra_variable ('sub_tip_tramite');
    trn_k_global.borra_variable ('nom_aviso');
    trn_k_global.borra_variable ('num_dias');
    --
  END IF;
  --
  /* Buscamos si el expediente estÃ¡ retenido por el control tÃ©cnico para llamar
     a la rutina de Reaseguro de siniestros*/
  BEGIN
     --
     ts_k_a7001000.p_lee_a7001000 ( p_cod_cia  => g_cod_cia
                                   ,p_num_sini => g_num_sini
                                   ,p_num_exp  => g_num_exp);
     --
     ts_k_a7000900.p_lee_a7000900 ( p_cod_cia  => g_cod_cia
                                   ,p_num_sini => g_num_sini);
     --
     IF NVL(ts_k_a7001000.f_mca_provisional,'N') = 'N'
     THEN
        --
        ra_k_rutina_stros.p_inicio( p_cod_cia        => g_cod_cia
                                   ,p_num_sini       => g_num_sini
                                   ,p_num_exp        => g_num_exp
                                   ,p_num_liq        => NULL
                                   ,p_tip_mvto       => g_k_tip_mvto
                                   ,p_sub_tip_mvto   => NULL
                                   ,p_num_contrato   => NULL
                                   ,p_anio_contrato  => NULL
                                   ,p_serie_contrato => NULL
                                   ,p_fec_mvto       =>  g_fec_proceso
                                   ,p_cod_evento     => ts_k_a7000900.f_cod_evento);
        --
     END IF;
     --
     dc_k_rgpd_consentimiento.p_registra_consentimiento;
     --
     ts_k_apertura.p_final_aper_exp;
     --
  EXCEPTION
  WHEN OTHERS
  THEN
     --
     -- MS-2010-07-01020 -  Inicio (Se modifica el procedimiento p_graba_resto_exp para mostrar el error devuelto por reaseguro)
        --g_cod_mensaje  := 10204;
     g_cod_mensaje  := SQLCODE;
        --g_anx_mensaje  := ' ra_k_rutina_stros ';
     g_anx_mensaje  := SQLERRM(SQLCODE);
     -- MS-2010-07-01020 -  Fin
     --
     pp_devuelve_error;
     --
  END;
  --
END p_graba_resto_exp;
--
/* --------------------------------------------------------------
|| Procedimiento que comprueba que se hayan aperturado todos los
|| expedientes obligatorios.
*/ --------------------------------------------------------------
--
PROCEDURE p_comprueba_aper_exp
IS
  --
  l_tip_exp            a7001000.tip_exp                 %TYPE := NULL;
  l_puntero            NUMBER(5)                        := 0;
  --
BEGIN
  --
  --@mx('I','p_comprueba_aper_exp');
  --
  /* Valido que haya abierto los obligatorios siempre y cuando haya
    aperturado alguno . */
  --
  -- DE MOMENTO ESTO SE QUITA (26-04-2001).
  --
  -- Junio 2003.
  --  En la G7000001, se aÃ±ade una marca y un procedimiento para indicar
  -- mediante la global mca_aper_sin_obliga, si se apertura el siniestro
  -- sin estar aperturados los expedientes obligatorios.
  --  Aunque no hay ninguno aperturado, tambiÃ©n se hace la validaciÃ³n.
  --  Esta comprobaciÃ³n solo se lanza si estamos en el ON-LINE, en el proceso
  -- Batch, NO se lanza.
  --
  IF  NVL(trn_k_global.ref_f_global('tip_mvto_batch_stro'),'0') = '0'
  THEN
    --
    l_puntero := 0;
    --
    WHILE l_puntero < g_max_secu_query
    LOOP
      --
      l_puntero := l_puntero + 1;
      --
      IF gtb_tipos_de_expedientes(l_puntero).mca_obligatorio = 'S'    AND
         NVL(gtb_tipos_de_expedientes(l_puntero).num_exp_aper, 0) = 0 AND
         ts_k_g7000001.f_apertura_sin_obliga (g_cod_cia,
                                              g_cod_ramo) = 'N'
      THEN
        --
        -- DEBE APERTURAR TODOS LOS EXP. OBLIGATORIOS. 70001100.
        --
        g_cod_mensaje := 70001100;
        g_anx_mensaje := NULL;
        --
        pp_devuelve_error;
        --
      END IF;
      --
    END LOOP;
    --
  END IF;
  --
  /* Como este es el ultimo procedimiento que se ejecuta, antes de irme,
    borro todas las globales que se han asignado en el AS700030. */
  --
  pp_borra_globales;
  --
  --@mx('F','p_comprueba_aper_exp');
  --
END p_comprueba_aper_exp;
--
/* --------------------------------------------------------------
||  Procedimiento que carga en memoria los expedientes que se van a
|| poder asociar a un recobro.
*/ --------------------------------------------------------------
PROCEDURE p_query_para_recobros
IS
   --
   /* Cursor de los posibles expedientes a los cuales va a afectar el
     recobro que estoy aperturando. */
   --
   CURSOR c_a7001000_afec
                       (pc_cod_cia        a7001000.cod_cia       %TYPE,
                        pc_cod_ramo       a7001000.cod_ramo      %TYPE,
                        pc_num_sini       a7001000.num_sini      %TYPE,
                        pc_tip_exp        a7001000.tip_exp       %TYPE)
   IS
      SELECT tip_exp, num_exp, tip_est_exp
        FROM a7001000
       WHERE cod_cia           = pc_cod_cia
         AND num_sini          = pc_num_sini
         AND mca_exp_recobro   = 'N'
         AND tip_exp
             IN ( SELECT tip_exp
                    FROM g7007030
                   WHERE cod_cia     = pc_cod_cia
                     AND cod_ramo    = pc_cod_ramo
                     AND tip_exp_rec = pc_tip_exp );
   --
   l_puntero_afec   NUMBER(5) := 0;
   --
BEGIN
  --
  --@mx('I','p_query_para_recobros');
  --
  gtb_tipos_de_expedientes_afec.DELETE;
  --
  /* El g_tip_exp es el expediente de Recobro que estoy aperturando y que he
    cargado en el p_selecciona_expediente. */
  --
  l_puntero_afec := 0;
  --
  FOR reg1_afec IN  c_a7001000_afec (g_cod_cia,
                                     g_cod_ramo,
                                     g_num_sini,
                                     g_tip_exp)
  LOOP
    --
    l_puntero_afec := l_puntero_afec + 1;
    --
    gtb_tipos_de_expedientes_afec(l_puntero_afec).num_sini        :=
                                  g_num_sini      ;
    --
    gtb_tipos_de_expedientes_afec(l_puntero_afec).num_exp         :=
                                  reg1_afec.num_exp;
    --
    gtb_tipos_de_expedientes_afec(l_puntero_afec).tip_exp         :=
                                  reg1_afec.tip_exp;
    --
    ts_k_g7000090.p_lee (g_cod_cia, reg1_afec.tip_exp);
    gtb_tipos_de_expedientes_afec(l_puntero_afec).nom_exp         :=
                                  ts_k_g7000090.f_nom_exp;
    --
    gtb_tipos_de_expedientes_afec(l_puntero_afec).tip_est_exp     :=
                                  reg1_afec.tip_est_exp;
    --
    -- Cambiado por Maria 23022004
    --
     pp_asigna('NUM_EXP_ASIG', reg1_afec.num_exp);
     pp_asigna('TIP_EXP',g_tip_exp);
    --
    /* Incluido para la apertura automatica. (BATCH).*/
    --
    gtb_tipos_de_expedientes_afec(l_puntero_afec).mca_aper_aut    :=
                 ts_k_g7007030.f_apertura_automatica (g_cod_cia,
                                                      g_cod_ramo,
                                                      reg1_afec.tip_exp,
                                                      g_tip_exp);
    --
    gtb_tipos_de_expedientes_afec(l_puntero_afec).nom_prg_nro_exp_aut:=
                                  ts_k_g7000100.f_nom_prg_nro_exp_aut;
    --
    gtb_tipos_de_expedientes_afec(l_puntero_afec).nro_exp_aut:=0;
        --
  END LOOP;
  --
  /* En el proceso Batch, si se intenta abrir un exp. de recobro y no se ha abierto
    el afectado, no se debe de producir error.
     El procedimiento de apertura automÃ¡tica del recobro deberÃ­a controlar que no se
    abra este, si no hay expediente afectado abierto.
  */
  IF l_puntero_afec = 0 AND
     NVL(trn_k_global.ref_f_global('tip_mvto_batch_stro'),'0') = '0'
  THEN
     --
     /* NO HAY EXPEDIENTE PARA ASOCIAR EL RECOBRO */
     --
     --g_cod_mensaje := 20316;
     --
     g_cod_mensaje := 70008042;
     g_anx_mensaje := NULL;
     --
     pp_devuelve_error;
     --
  END IF;
  --
  g_fila_devuelve_afec  := NULL;
  g_max_secu_query_afec := l_puntero_afec;
  g_max_tipos_exp_afec  := l_puntero_afec;
  --
  trn_k_global.borra_variable('TIP_EXP');
  trn_k_global.borra_variable('NUM_EXP_ASIG');
  --
  --@mx('F','p_query_para_recobros');
  --
END p_query_para_recobros;
--
/* --------------------------------------------------------------
|| Devuelve un registro de la tabla de memoria de los posibles expedientes
|| que van a afectar a un recobro.
*/ --------------------------------------------------------------
PROCEDURE p_devuelve_para_recobros
         (p_num_secu_k_afec      IN OUT  NUMBER                          ,
          p_num_sini             IN OUT  a7001000.num_sini         %TYPE ,
          p_num_exp              IN OUT  a7001000.num_exp          %TYPE ,
          p_tip_exp              IN OUT  a7001000.tip_exp          %TYPE ,
          p_nom_exp              IN OUT  g7000090.nom_exp          %TYPE ,
          p_tip_est_exp          IN OUT  a7001000.tip_est_exp      %TYPE ,
          p_mca_aper_aut         IN OUT  g7000100.mca_aper_aut     %TYPE )
IS
  --
BEGIN
  --
  --@mx('I','p_devuelve_para_recobros');
  --
  IF g_fila_devuelve_afec IS NULL
  THEN
    --
    IF gtb_tipos_de_expedientes_afec.EXISTS(gtb_tipos_de_expedientes_afec.FIRST)
     THEN
      --
      g_fila_devuelve_afec := gtb_tipos_de_expedientes_afec.FIRST;
      --
      p_num_secu_k_afec := g_fila_devuelve_afec;
      --
      p_num_sini       :=
      gtb_tipos_de_expedientes_afec(g_fila_devuelve_afec).num_sini;
      --
      p_num_exp        :=
      gtb_tipos_de_expedientes_afec(g_fila_devuelve_afec).num_exp;
      --
      p_tip_exp        :=
      gtb_tipos_de_expedientes_afec(g_fila_devuelve_afec).tip_exp;
      --
      p_nom_exp        :=
      gtb_tipos_de_expedientes_afec(g_fila_devuelve_afec).nom_exp;
      --
      p_tip_est_exp    :=
      gtb_tipos_de_expedientes_afec(g_fila_devuelve_afec).tip_est_exp;
      --
    ELSE --Tabla  vacia
      --
      p_num_secu_k_afec := NULL;
      --
      p_num_sini       := NULL;
      p_num_exp        := NULL;
      p_tip_exp        := NULL;
      p_nom_exp        := NULL;
      p_tip_est_exp    := NULL;
      --
      g_fila_devuelve_afec := g_max_secu_query_afec;
      --
    END IF;
    --
   ELSIF g_fila_devuelve_afec != g_max_secu_query_afec
                                 -- Hay pero no es el primero
       THEN
        --
        g_fila_devuelve_afec :=
        gtb_tipos_de_expedientes_afec.NEXT(g_fila_devuelve_afec);
        --
        p_num_secu_k_afec := g_fila_devuelve_afec;
        --
        p_num_sini       :=
        gtb_tipos_de_expedientes_afec(g_fila_devuelve_afec).num_sini;
        --
        p_num_exp        :=
        gtb_tipos_de_expedientes_afec(g_fila_devuelve_afec).num_exp;
        --
        p_tip_exp        :=
        gtb_tipos_de_expedientes_afec(g_fila_devuelve_afec).tip_exp;
        --
        p_nom_exp        :=
        gtb_tipos_de_expedientes_afec(g_fila_devuelve_afec).nom_exp;
        --
        p_tip_est_exp    :=
        gtb_tipos_de_expedientes_afec(g_fila_devuelve_afec).tip_est_exp;
        --
       ELSE -- Es el ultimo porque es igual a la maxima fila
        --
        p_num_secu_k_afec := NULL;
        --
        p_num_sini         := NULL;
        p_num_exp          := NULL;
        p_tip_exp          := NULL;
        p_nom_exp          := NULL;
        p_tip_est_exp      := NULL;
        p_mca_aper_aut     := NULL;
        --
  END IF;
  --
  --@mx('F','p_devuelve_para_recobros');
  --
END p_devuelve_para_recobros;
--
/* --------------------------------------------------------------
|| Procedimiento que carga las variables que necesito para aperturar
|| un expediente de recobro.
*/ --------------------------------------------------------------
PROCEDURE p_carga_variables_recobro
          (p_tip_exp          IN     a7001000.tip_exp_afec       %TYPE,
           p_num_exp          IN     a7001000.num_exp_afec       %TYPE,
           p_tip_est_exp      IN     a7001000.tip_est_afec       %TYPE,
           p_hay_mas_de_uno   IN OUT VARCHAR2                         )
IS
  --
  l_cuenta  a7001000.num_exp  %TYPE := 0;
  --
BEGIN
  --
  --@mx('I','p_carga_variables_recobro');
  --
  g_tip_exp_afec := NULL;
  g_num_exp_afec := NULL;
  g_tip_est_afec := NULL;
  --
  g_tip_exp_afec := p_tip_exp;
  g_num_exp_afec := p_num_exp;
  g_tip_est_afec := p_tip_est_exp;
  --
  l_cuenta := ts_k_a7001000.f_cuenta_recobros_de_un_exp
                            (g_cod_cia,
                             g_num_sini,
                             g_tip_exp,
                             g_num_exp_afec);
  --
  IF l_cuenta > 0
  THEN
     --
     p_hay_mas_de_uno := 'S';
     --
  ELSE
     --
     p_hay_mas_de_uno := 'N';
     --
  END IF;
  --
  --@mx('F','p_carga_variables_recobro');
  --
END p_carga_variables_recobro;
--
/* --------------------------------------------------------------
||  Funcion que devuelve el numero de expedientes aperturados de un tipo
|| determinado en un siniestro.
*/ --------------------------------------------------------------
 FUNCTION f_cuenta_exp_aper  (p_tip_exp    a7001000.tip_exp %TYPE)
 RETURN NUMBER
 IS
 --
 BEGIN
   --
   --@mx('I','f_cuenta_exp_aper');
   --
   RETURN NVL(ts_k_a7001000.f_cuenta_exp (g_cod_cia, g_num_sini, p_tip_exp),0);
   --
   --@mx('F','f_cuenta_exp_aper')
   --
 EXCEPTION
 WHEN ge_no_existe
 THEN
   --
   --@mx('*','Exception : f_cuenta_exp_aper');
   --
   RETURN 0;
   --
 END f_cuenta_exp_aper;
--
/* --------------------------------------------------------------
|| Procedimiento que va a recoger los valores que se necesitan para poder
|| actualizar la a7001000 con los datos de la persona relacionada con el
|| expediente. Las estructuras de expedientes, deben de llamar a este procedi-
|| miento para cargar estos valores.
*/ --------------------------------------------------------------
PROCEDURE p_modif_persona_a7001000
          ( p_tip_docum_exp       a7001000.tip_docum          %TYPE,
            p_cod_docum_exp       a7001000.cod_docum          %TYPE,
            p_nombre_exp          a7001000.nombre             %TYPE,
            p_apellidos_exp       a7001000.apellidos          %TYPE
          )
IS
BEGIN
  --
  --@mx('I','p_modif_persona_a7001000');
  --
  g_tip_docum_exp := p_tip_docum_exp;
  g_cod_docum_exp := p_cod_docum_exp;
  g_nombre_exp    := p_nombre_exp;
  g_apellidos_exp := p_apellidos_exp;
  --
  --@mx('F','p_modif_persona_a7001000');
  --
END p_modif_persona_a7001000;
--
PROCEDURE p_deshacer_expediente
IS
BEGIN
  --
  --@mx('I','p_deshacer_expediente');
  --
  ROLLBACK TO SAVEPOINT expediente;
  --
  --@mx('F','p_deshacer_expediente');
  --
END p_deshacer_expediente;
--
PROCEDURE p_borra_variables
IS
BEGIN
  --
  --@mx('I','p_borra_variables');
  --
  pp_inicializa_variables;
  --
  pp_borra_tabla_memoria_exp;
  --
  --@mx('F','p_borra_variables');
  --
END p_borra_variables;
--
/* -----------------------------------------------------
|| pp_lanza_ct_nivel5 :
||
|| Procedimiento para lanzar CT de nivel de salto = 5
*/ -----------------------------------------------------
PROCEDURE pp_lanza_ct_nivel5
IS
--
   l_cod_sistema         a2000220.cod_sistema          %TYPE;
   l_cod_nivel_salto_5   a2000220.cod_nivel_salto      %TYPE;
   l_tip_rechazo         g2000210.tip_rechazo          %TYPE;
   l_num_liq             a2000220.num_liq              %TYPE;
--
BEGIN
   --
   --  Se lanza el Control TÃ©cnico del nivel de salto = 5.
   --
   IF f_hay_errCT_nivel5 = 'S'
   THEN
     --
     -- Si ha un Error de Rechazo, provoco el error 70001190 para que
     -- lo recoga el ts_k_batch.
     -- Si el error es de ObservaciÃ³n, no se hace nada.
     -- Si el error es de auditorÃ­a, se continua y serÃ¡ detectado por
     -- el ts_k_batch.
     --
     l_cod_sistema       := '7';
     l_cod_nivel_salto_5 := '5';
     l_tip_rechazo       := '2';
     l_num_liq           :=  0;
     --
     IF ts_k_as799001.f_hay_errores_ct (g_num_sini         ,
                                        g_num_exp          ,
                                        l_num_liq          ,
                                        l_cod_sistema      ,
                                        l_cod_nivel_salto_5,
                                        l_tip_rechazo) = 'S'
     THEN
       --
       -- RECHAZADO POR CONTROL TECNICO. 70001190.
       --
       g_cod_mensaje := 70001190;
       g_anx_mensaje := ' COD_SISTEMA = 7, NIVEL_SALTO = 5';
       --
       pp_devuelve_error;
       --
     END IF;
     --
   END IF;
   --
END pp_lanza_ct_nivel5;
--
/*--------------------------------------------------------------
|| p_batch:
||
|| Procedimiento que lanza la apertura de expedientes automatica
*/-------------------------------------------------------------
PROCEDURE p_batch
IS
 l_inicio                  NUMBER(5)    := 1;
 l_max_nro_tip_exp         NUMBER(5)    := 0;
 l_max_nro_tip_exp_afec    NUMBER(5)    := 0;
 --
 l_pide_moneda             VARCHAR2(1);
 l_pide_causa_aper         VARCHAR2(1);
 l_pide_exp_a_aperturar    VARCHAR2(1);
 l_hay_mas_de_uno          VARCHAR2(1);
 --
 l_cod_pgm_exp         g9990003.cod_pgm        %TYPE;
 l_cod_grp_est         g9990002.cod_grp_est    %TYPE := '4';
 --
 l_valoracion_ajustada VARCHAR2(1);
 l_cod_pgm_valoracion  g9990003.cod_pgm        %TYPE;
 --
 /* Variables para el Control TÃ©cnico Batch. */
 --
 l_mca_hay_errores_ct  VARCHAR2(1);
 l_cod_sistema         a2000220.cod_sistema          %TYPE;
 l_cod_nivel_salto_5   a2000220.cod_nivel_salto      %TYPE;
 l_tip_rechazo         g2000210.tip_rechazo          %TYPE;
 l_num_liq             a2000220.num_liq              %TYPE;
 l_cod_error_ct        a2000220.cod_error            %TYPE;
 --
 l_fec_tratamiento     b7000910.fec_tratamiento     %TYPE;
 --
BEGIN
 --
 --@mx('I','p_batch 30');
 --
 p_inicio;
 --
 /* Esta global se pone a N porque si no sale bien el pquery el ts_k_ap700100
    que le llama no podra hacer el deshacer expediente */
 --
 trn_k_global.asigna('DEFINICION','N');
 --
 p_query;
 --
 /* Esta global es S porque hay definicion y hay que deshacer el expediente */
 --
 trn_k_global.asigna('DEFINICION','S');
 --
 l_max_nro_tip_exp := g_max_tipos_exp;
 --
   /* Desde el 1, hasta el ultimo tipo de expediente del ramo que se puede
      abrir para la causa-consecuencia seleccionada */
   --
   FOR i IN 1..l_max_nro_tip_exp
   LOOP
    --
      /* Si el expediente se puede abrir automaticamente */
      --
      IF gtb_tipos_de_expedientes(i).mca_aper_aut = 'S'
      THEN
        -----------------------------------------------------
        -- Calculamos el numero de expedientes a aperturar --
        -----------------------------------------------------
        IF NVL(gtb_tipos_de_expedientes(i).nom_prg_nro_exp_aut,'N') != 'N'
        THEN
          pp_asigna('tip_exp',gtb_tipos_de_expedientes(i).tip_exp);
          --
          trn_k_dinamico.p_ejecuta_procedimiento
                           (gtb_tipos_de_expedientes(i).nom_prg_nro_exp_aut);
          --
          gtb_tipos_de_expedientes(i).nro_exp_aut:=
                            NVL(trn_k_global.ref_f_global('NUM_EXPEDIENTES'),0);
          trn_k_global.borra_variable('TIP_EXP');
          --
        ELSE
    -- OJOOOO
          gtb_tipos_de_expedientes(i).nro_exp_aut:= 1;
        END IF;
        --
        /* Se abriran tantos expedientes deltipo como indique el nro_Exp_aut*/
        --
         FOR j IN 1 ..gtb_tipos_de_expedientes(i).nro_exp_aut
         LOOP
            --
            p_selecciona_expediente  (gtb_tipos_de_expedientes(i).tip_exp,
                                      l_pide_moneda        ,
                                      l_pide_causa_aper    ,
                                      l_pide_exp_a_aperturar  );
            --
            IF l_pide_causa_aper = 'S'
            THEN
            --
              g_num_exp := NVL(ts_k_a7001000.f_max_num_exp (g_cod_cia, g_num_sini), 0) + 1;
              trn_k_global.asigna('tip_causa', g_tip_causa_aper_exp);
              --
              ts_k_as700040.p_batch(p_cod_cia             => g_cod_cia,
                                      p_fec_tratamiento     => TO_DATE(TO_CHAR(trn_k_global.devuelve('fec_tratamiento')),'DDMMYYYY'),
                                      p_tip_mvto_batch_stro => trn_k_global.devuelve('tip_mvto_batch_stro'),
                                      p_num_sini            => g_num_sini,
                                      p_num_orden           => trn_k_global.devuelve('num_orden'),
                                      p_num_exp             => g_num_exp);
            --
            END IF;
            --
            /* Si es un recobro tengo que cargar la tabla en memoria de
               los distintos expedientes que puedo asociarle el recobro */
            --
            IF l_pide_exp_a_aperturar = 'S'
            THEN
               --
               p_query_para_recobros;
               --
               l_max_nro_tip_exp_afec := g_max_tipos_exp_afec;
               --
               FOR K IN 1..l_max_nro_tip_exp_afec
               LOOP
                  IF gtb_tipos_de_expedientes_afec(K).mca_aper_aut = 'S'
                  THEN
                    --
                     p_carga_variables_recobro (
                           gtb_tipos_de_expedientes_afec(K).tip_exp,
                           gtb_tipos_de_expedientes_afec(K).num_exp,
                           gtb_tipos_de_expedientes_afec(K).tip_est_exp,
                           l_hay_mas_de_uno );
                     --
                     p_inserta_expediente (l_cod_pgm_exp      );
                     --
                     -- Recojo procedimiento con la estructura. --
                     --
                     IF g_nom_prg_exp IS NOT NULL
                     THEN
                        trn_k_dinamico.p_ejecuta_procedimiento (g_nom_prg_exp);
                     END IF;
                     --
                     -- 01/10/2005.
                     --  Se lanza el Control TÃ©cnico del nivel de salto = 5.
                     --
                     pp_lanza_ct_nivel5;
                     --
                     -- Fin 01/10/2005.
                     --
                     -- Se va a insertar la valoracion del expediente
                     --
                     p_valoracion_expediente ( l_valoracion_ajustada ,
                                               l_cod_pgm_valoracion  ,
                                               l_mca_hay_errores_ct  );
                     --
                     p_graba_resto_exp;
                     --
                     /* Tratamiento de las Estructuras complementarias del Expediente.*/
                     --
                     /* Se llama a las estructuras del ramo y se revisa si hay algun dato
                       primero asigno globales por que las necesita el ts_k_as700020*/
                     --
                     trn_k_global.asigna('cod_sector', g_cod_sector);
                     trn_k_global.asigna('cod_ramo',   g_cod_ramo);
                     trn_k_global.asigna('tip_exp',    g_tip_exp);
                     trn_k_global.asigna('cod_grp_est',l_cod_grp_est);
                     --
                     /* Globales para las estructuras del expediente */
                     --
                     ts_k_as700020.p_batch;
                     --
                  END IF; -- Si el recobro se abre automaticamente.
                  --
                END LOOP;
                --
            ELSE -- Si no es un recobro
               --
               p_inserta_expediente (l_cod_pgm_exp      );
               --
               -- Recojo procedimiento con la estructura.--
               --
               IF g_nom_prg_exp IS NOT NULL
               THEN
                  trn_k_dinamico.p_ejecuta_procedimiento (g_nom_prg_exp);
               END IF;
               --
               -- 14/09/2005.
               --  Se lanza el Control TÃ©cnico del nivel de salto = 5.
               --
               IF f_hay_errCT_nivel5 = 'S'
               THEN
                 --
                 -- Si ha un Error de Rechazo, provoco el error 70001190 para que
                 -- lo recoga el ts_k_batch.
                 -- Si el error es de ObservaciÃ³n, no se hace nada.
                 -- Si el error es de auditorÃ­a, se continua y serÃ¡ detectado por
                 -- el ts_k_batch.
                 --
                 l_cod_sistema       := '7';
                 l_cod_nivel_salto_5 := '5';
                 l_tip_rechazo       := '2';
                 l_num_liq           :=  0;
                 --
                 IF ts_k_as799001.f_hay_errores_ct (g_num_sini         ,
                                                    g_num_exp          ,
                                                    l_num_liq          ,
                                                    l_cod_sistema      ,
                                                    l_cod_nivel_salto_5,
                                                    l_tip_rechazo) = 'S'
                 THEN
                   --
                   -- RECHAZADO POR CONTROL TECNICO. 70001190.
                   --
                   g_cod_mensaje := 70001190;
                   g_anx_mensaje := ' COD_SISTEMA = 7, NIVEL_SALTO = 5';
                   --
                   pp_devuelve_error;
                   --
                 END IF;
                 --
               END IF;
               --
               -- Fin 14/09/2005.
               --
               -- Se va a insertar la valoracion del expediente
               --
               p_valoracion_expediente ( l_valoracion_ajustada ,
                                         l_cod_pgm_valoracion  ,
                                         l_mca_hay_errores_ct  );
               --
               p_graba_resto_exp;
               --
               /* Tratamiento de las Estructuras complementarias del Expediente.*/
               --
               /* Se llama a las estructuras del ramo y se revisa si hay algun dato
                 primero asigno globales por que las necesita el ts_k_as700020*/
               --
               trn_k_global.asigna('cod_sector', g_cod_sector);
               trn_k_global.asigna('cod_ramo',   g_cod_ramo);
               trn_k_global.asigna('tip_exp',    g_tip_exp);
               trn_k_global.asigna('cod_grp_est',l_cod_grp_est);
               --
               /* Globales para las estructuras del expediente */
               --
               ts_k_as700020.p_batch;
               --
               COMMIT;
               --
            END IF ; -- Si es un recobro
            --
         END LOOP; -- Loop hasta el numero de expedientes que indique el proc.
         --
      END IF;
      --
   END LOOP; -- Loop hasta el ultimo tipo de expediente de la tabla
 --
 --@mx('F','p_batch');
 --
 EXCEPTION
 WHEN OTHERS
 THEN
      --
      g_txt_error := SQLERRM||' as700030';
      g_cod_mensaje := -SQLCODE;
      --
      --@mx('F','Error en p_batch');
      --
      RAISE_APPLICATION_ERROR(-g_cod_mensaje,g_txt_error);
 --
END p_batch;
--
  FUNCTION f_hay_errCT_nivel5 RETURN VARCHAR2 IS
    --
    l_mca_hay_errores_ct    VARCHAR2(1) := 'N';
    --
  BEGIN
     --
     --@mx('I', 'f_hay_errCT_nivel5');
     --
     IF ts_k_as799001.f_calcula_errores ( g_k_cod_sistema               ,
                                          g_k_cod_nivel_salto5          ,
                                          g_k_mca_puede_haber_auditoria ,
                                          g_cod_pgm_est                 ) > 0
    THEN
      l_mca_hay_errores_ct := 'S';
    END IF;
    --
    --@mx('F', 'f_hay_errCT_nivel5');
    --
    RETURN l_mca_hay_errores_ct;
    --
  END f_hay_errCT_nivel5;
  --
 -------------------------------------------------------
 -- Procedimiento para asignar la global tip_causa.
 -------------------------------------------------------
  PROCEDURE p_asigna_tip_causa  ( p_tip_causa IN g7000200.tip_causa%TYPE)
  IS
  BEGIN
     --
     g_tip_causa := p_tip_causa;
     --
     trn_k_global.asigna('tip_causa',  g_tip_causa);
     --
  END p_asigna_tip_causa;
  --
/* --------------------------------------------------------------
|| Procedimiento para asignar cod_pgm_call
*/ --------------------------------------------------------------
   PROCEDURE p_asigna_globales_menu (p_cod_pgm_call  g1010131.cod_pgm_call%TYPE)
   IS
   --
   BEGIN
      --
      ts_k_globales_opciones.p_asigna(p_cod_pgm  => p_cod_pgm_call,
                                      p_num_sini => g_num_sini    ,
                                      p_num_exp  => g_num_exp     );
      --
   END p_asigna_globales_menu;
   --
/* --------------------------------------------------------------
|| Procedimiento para borrar globales
*/ --------------------------------------------------------------
   PROCEDURE p_borra_globales_menu
   IS
   --
   BEGIN
      --
      ts_k_globales_opciones.p_borra_globales;
      --
   END p_borra_globales_menu;
   --
/* -----------------------------------------------------
|| pp_recobros_asoc :
||
|| Procedimiento que recupera los recobros asociados a un
|| expediente de no recobro
*/ -----------------------------------------------------
PROCEDURE pp_recobros_asoc_aut
IS
   --
   /* Cursor de los posibles expedientes a los cuales va a afectar el
     recobro que estoy aperturando. */
   --
   CURSOR c_g7007030
                       (pc_cod_cia        a7001000.cod_cia       %TYPE,
                        pc_cod_ramo       a7001000.cod_ramo      %TYPE,
                        pc_tip_exp        a7001000.tip_exp       %TYPE)
   IS
      SELECT r.tip_exp_rec, c.nom_prg_nro_exp_aut
        FROM g7007030 r, g7000100 c
       WHERE r.cod_cia      = c.cod_cia
         AND r.cod_ramo     = c.cod_ramo
         AND r.tip_exp_rec  = c.tip_exp
         AND r.cod_cia      = pc_cod_cia
         AND r.cod_ramo     = pc_cod_ramo
         AND r.tip_exp      = pc_tip_exp
         AND r.mca_aper_aut = trn.SI
         AND c.mca_aper_aut = trn.SI;
   --
   l_puntero_afec   NUMBER(5) := 0;
   --
BEGIN
  --
  --@mx('I','p_exp_afec');
  --
  gtb_recobros_aut.DELETE;
  --
  /* El g_tip_exp es el expediente de Recobro que estoy aperturando y que he
    cargado en el p_selecciona_expediente. */
  --
  l_puntero_afec := 0;
  --
  FOR reg1_afec IN  c_g7007030 (g_cod_cia,
                                g_cod_ramo,
                                g_tip_exp)
  LOOP
    --
    l_puntero_afec := l_puntero_afec + 1;
    --
    gtb_recobros_aut(l_puntero_afec).tip_exp_rec         := reg1_afec.tip_exp_rec;
    gtb_recobros_aut(l_puntero_afec).nom_prg_nro_exp_aut := reg1_afec.nom_prg_nro_exp_aut;
    --
  END LOOP;
  --
END pp_recobros_asoc_aut;
--
/* -----------------------------------------------------
|| p_batch_recobro :
||
|| Procedimiento que realiza la apertura automatica
|| de expedientes de recobro asociados a expedientes de
|| no recobro
*/ -----------------------------------------------------
PROCEDURE p_batch_recobro
IS
--
   l_hay_mas_de_uno       VARCHAR2(1);
   --
   l_cod_pgm_exp          g9990003.cod_pgm    %TYPE;
   l_cod_grp_est          g9990002.cod_grp_est%TYPE := '4';
   --
   l_mca_hay_errores_ct   VARCHAR2(1);
   l_valoracion_ajustada  VARCHAR2(1);
   l_cod_pgm_valoracion   g9990003.cod_pgm    %TYPE;
   l_tip_exp              a7001000.tip_exp    %TYPE;
   l_num_exp              NUMBER;
--
BEGIN
   --
   --Nos guardamos el tipo de expediente para restaurarlo al salir
   --ya que sera sobreescrito con el tipo de recobro
   l_tip_exp := g_tip_exp;
   --
   --Recuperamos los datos fijos del expediente de no recobro
   --que se esta aperturando.Los datos fijos se cargan en la
   --tabla gtb_tipos_de_expedientes_afec
   p_query_para_recobros_aut;
   --
   --Recuperamos los expedientes de recobro
   --asociados al expediente que se esta aperturando.Los recobros
   --se cargan en la tabla gtb_recobros_aut
   pp_recobros_asoc_aut;
   --
   --Recorremos los recobros recuperados
   FOR i IN 1..gtb_recobros_aut.COUNT
   LOOP
     --
     g_tip_exp := gtb_recobros_aut(i).tip_exp_rec;
     --
     --Ejecutamos el procedimiento para comprobar el numero de recobros que se tienen que aperturar
     IF gtb_recobros_aut(i).nom_prg_nro_exp_aut IS NOT NULL
     THEN
        --
        trn_k_dinamico.p_ejecuta_procedimiento (gtb_recobros_aut(i).nom_prg_nro_exp_aut);
        l_num_exp:=NVL(trn_k_global.ref_f_global('NUM_EXPEDIENTES'),0);
        --
     ELSE
       --
       l_num_exp := 1;
       --
     END IF;
     --
     FOR j IN 1..l_num_exp
     LOOP
     --
        BEGIN
           p_carga_variables_recobro (
                  gtb_tipos_de_expedientes_afec(1).tip_exp,
                  gtb_tipos_de_expedientes_afec(1).num_exp,
                  gtb_tipos_de_expedientes_afec(1).tip_est_exp,
                  l_hay_mas_de_uno );
           --
           p_inserta_expediente (l_cod_pgm_exp      );
           --
           -- Recojo procedimiento con la estructura. --
           --
           IF g_nom_prg_exp IS NOT NULL
           THEN
              trn_k_dinamico.p_ejecuta_procedimiento (g_nom_prg_exp);
           END IF;
           --
           -- 01/10/2005.
           --  Se lanza el Control TÃ©cnico del nivel de salto = 5.
           --
           pp_lanza_ct_nivel5;
           --
           -- Fin 01/10/2005.
           --
           -- Se va a insertar la valoracion del expediente
           --
           p_valoracion_expediente ( l_valoracion_ajustada ,
                                     l_cod_pgm_valoracion  ,
                                     l_mca_hay_errores_ct  );
           --
           p_graba_resto_exp;
           --
           /* Tratamiento de las Estructuras complementarias del Expediente.*/
           --
           /* Se llama a las estructuras del ramo y se revisa si hay algun dato
             primero asigno globales por que las necesita el ts_k_as700020*/
           --
           trn_k_global.asigna('cod_sector', g_cod_sector);
           trn_k_global.asigna('cod_ramo',   g_cod_ramo);
           trn_k_global.asigna('tip_exp',    g_tip_exp);
           trn_k_global.asigna('cod_grp_est',l_cod_grp_est);
           --
           /* Globales para las estructuras del expediente */
           --
           ts_k_as700020.p_batch;
           --
           COMMIT;
           --
        EXCEPTION
          WHEN OTHERS THEN
            --
            p_deshacer_expediente;
            --
        END;
        --
     END LOOP;
     --
   END LOOP;
   --
   g_tip_exp := l_tip_exp;
   pp_borra_globales;
   --
EXCEPTION
  WHEN OTHERS THEN
    --
    p_deshacer_expediente;
    --
END p_batch_recobro;
--
/* --------------------------------------------------------------
||  Procedimiento que carga en memoria los datos del expediente
|| que se va a asociar al recobro (Apertura automatica)
*/ --------------------------------------------------------------
PROCEDURE p_query_para_recobros_aut
IS
   --
   /* Cursor de los posibles expedientes a los cuales va a afectar el
     recobro que estoy aperturando. */
   --
   CURSOR c_a7001000_afec
                       (pc_cod_cia        a7001000.cod_cia       %TYPE,
                        pc_num_sini       a7001000.num_sini      %TYPE,
                        pc_num_exp        a7001000.num_exp       %TYPE)
   IS
      SELECT tip_exp, num_exp, tip_est_exp
        FROM a7001000
       WHERE cod_cia           = pc_cod_cia
         AND num_sini          = pc_num_sini
         AND num_exp           = pc_num_exp
         AND mca_exp_recobro   = trn.NO;
   --
   l_puntero_afec   NUMBER(5) := 0;
   --
BEGIN
  --
  --@mx('I','p_query_para_recobros');
  --
  gtb_tipos_de_expedientes_afec.DELETE;
  --
  l_puntero_afec := 0;
  --
  FOR reg1_afec IN  c_a7001000_afec (g_cod_cia,
                                     g_num_sini,
                                     g_num_exp)
  LOOP
    --
    l_puntero_afec := l_puntero_afec + 1;
    --
    gtb_tipos_de_expedientes_afec(l_puntero_afec).num_sini        :=
                                  g_num_sini      ;
    --
    gtb_tipos_de_expedientes_afec(l_puntero_afec).num_exp         :=
                                  reg1_afec.num_exp;
    --
    gtb_tipos_de_expedientes_afec(l_puntero_afec).tip_exp         :=
                                  reg1_afec.tip_exp;
    --
    ts_k_g7000090.p_lee (g_cod_cia, reg1_afec.tip_exp);
    gtb_tipos_de_expedientes_afec(l_puntero_afec).nom_exp         :=
                                  ts_k_g7000090.f_nom_exp;
    --
    gtb_tipos_de_expedientes_afec(l_puntero_afec).tip_est_exp     :=
                                  reg1_afec.tip_est_exp;
    --
    -- Cambiado por Maria 23022004
    --
     pp_asigna('NUM_EXP_ASIG', reg1_afec.num_exp);
     pp_asigna('TIP_EXP',g_tip_exp);
    --
    /* Incluido para la apertura automatica. (BATCH).*/
    --
    gtb_tipos_de_expedientes_afec(l_puntero_afec).mca_aper_aut    := trn.si;
    --
    gtb_tipos_de_expedientes_afec(l_puntero_afec).nom_prg_nro_exp_aut:=
                                  ts_k_g7000100.f_nom_prg_nro_exp_aut;
    --
    gtb_tipos_de_expedientes_afec(l_puntero_afec).nro_exp_aut:=0;
        --
  END LOOP;
  --
  /* En el proceso Batch, si se intenta abrir un exp. de recobro y no se ha abierto
    el afectado, no se debe de producir error.
     El procedimiento de apertura automÃ¡tica del recobro deberÃ­a controlar que no se
    abra este, si no hay expediente afectado abierto.
  */
  IF l_puntero_afec = 0 AND
     NVL(trn_k_global.ref_f_global('tip_mvto_batch_stro'),'0') = '0'
  THEN
     --
     /* NO HAY EXPEDIENTE PARA ASOCIAR EL RECOBRO */
     --
     --g_cod_mensaje := 20316;
     --
     g_cod_mensaje := 70008042;
     g_anx_mensaje := NULL;
     --
     pp_devuelve_error;
     --
  END IF;
  --
  g_fila_devuelve_afec  := NULL;
  g_max_secu_query_afec := l_puntero_afec;
  g_max_tipos_exp_afec  := l_puntero_afec;
  --
  trn_k_global.borra_variable('TIP_EXP');
  trn_k_global.borra_variable('NUM_EXP_ASIG');
  --
  --@mx('F','p_query_para_recobros');
  --
END p_query_para_recobros_aut;
--
/* -----------------------------------------------------
|| p_recobro_aut :
||
|| Procedimiento que controla si se debe realizar la
|| apertura automatica de expedientes de recobro asociados
|| a expedientes de no recobro
*/ -----------------------------------------------------
PROCEDURE p_recobro_aut IS
BEGIN
--
   --Obtenemos los parametros de siniestros para cia/ramo
   BEGIN
      ts_k_g7000001.p_lee (p_cod_cia  => g_cod_cia,
                           p_cod_ramo => g_cod_ramo);
      --
      g_mca_aut_on_line    := ts_k_g7000001.f_mca_aut_on_line;
      g_mca_aper_aut       := ts_k_g7000001.f_mca_aper_aut;
      g_mca_aper_recob_exp := ts_k_g7000001.f_mca_aper_recob_exp;
      --
   EXCEPTION
   WHEN OTHERS
   THEN
      g_mca_aut_on_line    := 'N';
      g_mca_aper_aut       := 'N';
      g_mca_aper_recob_exp := 'N';
   END;
   --
   --Se valida la apertura automÃ¡tica de recobro
   --
   IF     g_mca_aut_on_line    = 'S'
      AND g_mca_aper_aut       = 'S'
      AND g_mca_aper_recob_exp = 'S'
   THEN
      --
      pp_asigna('mca_aut_on_line'    ,  'S');
      pp_asigna('tip_mvto_batch_stro',  '20');
      pp_asigna('fec_tratamiento'    ,  TRUNC(SYSDATE));
      --
      --Controlamos posibles errores para no interrumpir on-line
      BEGIN
         --
         --Lanzamos operativa batch para aperturar recobros
         --
         ts_k_ap700117.p_batch_recobro_aut;
         --
         trn_k_global.borra_variable('mca_aut_on_line');
         trn_k_global.borra_variable('tip_mvto_batch_stro');
         trn_k_global.borra_variable('fec_tratamiento');
         --
         --MU-2017-072243
         IF NVL(trn_k_global.ref_f_global(p_variable => 'ESTADO_ADMITIDO_SINI'), 'X') ='P'
         THEN
            --
            trn_k_global.borra_variable('num_sini');
            --
         END IF;
         --MU-2017-072243
         --
      EXCEPTION
      WHEN OTHERS
      THEN
         trn_k_global.borra_variable('mca_aut_on_line');
         trn_k_global.borra_variable('tip_mvto_batch_stro');
         trn_k_global.borra_variable('fec_tratamiento');
         --
         --MU-2017-072243
         IF NVL(trn_k_global.ref_f_global(p_variable => 'ESTADO_ADMITIDO_SINI'), 'X') ='P'
         THEN
            --
            trn_k_global.borra_variable('num_sini');
            --
         END IF;
         --MU-2017-072243
      END;
      --
   END IF;
   --
END p_recobro_aut;
--
END ts_k_as700030_trn;


create or replace PACKAGE BODY ts_k_ap740055_trn
IS
 --
 /* ------------------- VERSION = 1.03 -----------------*/
 --
 /* -------------------- DESCRIPCION --------------------
 || 2010/05/07 - RFRIVERO - v 1.03
 || Se cambian la asignacion a la variable g_fec_actu de
 || TRUNC(SYSDATE) o SYSDATE por la funcion trn_k_tiempo.f_fec_actu
 */ -----------------------------------------------------
 -- ==============================================================
 /*
 ||               Globales al package.
 */                                         
 -- ==============================================================
 /* --------------------------------------------------
 || Aqui comienza la declaracion de variables GLOBALES
 */ --------------------------------------------------
 g_cod_cia      a7000900.cod_cia    %TYPE;
 --
 g_cod_usr      a7000900.cod_usr    %TYPE;
 g_fec_actu     a7000900.fec_actu   %TYPE;
 --
 g_llamado      VARCHAR2(1);
 g_nom_prg_obs_tramite   g9990020.nom_prg_obs_tramite %TYPE;
 --
 g_cod_ramo     a7000900.cod_ramo   %TYPE;
 g_cod_sector   a7000900.cod_sector %TYPE;
 g_num_poliza   a7000900.num_poliza %TYPE;
 --
 g_cod_nivel3   g7000155.cod_nivel3 %TYPE;
 --
 g_cod_tramitador_aper a7001024.cod_tramitador  %TYPE;
 g_cod_tramitador      a7001024.cod_tramitador  %TYPE;
 --
 g_tip_exp_aper a7001000.tip_exp         %TYPE; 
 --
  g_num_sini     a7001000.num_sini   %TYPE;
 g_num_exp      a7001000.num_exp    %TYPE;
 --
 g_cod_idioma          g1010010.cod_idioma        %TYPE;
 g_cod_mensaje         g1010020.cod_mensaje       %TYPE;
 -- g_anx_mensaje       VARCHAR(250);
 g_anx_mensaje         VARCHAR2(250):= '[ ts_k_ap740055 ]';
 --
 g_k_ini_corchete CONSTANT VARCHAR2(2) := ' [';
 g_k_fin_corchete CONSTANT VARCHAR2(1) := ']';
 --
 /* --------------------------
 -- Excepciones controladas --
 -- ----------------------- */
 g_no_existe   EXCEPTION;
 --
 PRAGMA EXCEPTION_INIT (g_no_existe  , -20001);
 --
 g_cm_no_existe   g1010020.cod_mensaje%TYPE := 20001;
 --
 /* --------------------------------------------------------------
 ||               Procedimientos Internos
 */---------------------------------------------------------------
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
 || 
 || mx :
 || Genera la traza
 */ -------------------------------------------------------- 
 --
/*
 PROCEDURE mx(p_tit VARCHAR2,
              p_val VARCHAR2) IS
 BEGIN
    --
    pp_asigna (p_nom_global => 'fic_traza',
               p_val_global => 'ap740055' );
    --
    pp_asigna (p_nom_global => 'cab_traza',
               p_val_global => '->');
    --
    em_k_traza.p_escribe (p_titulo => p_tit,
                          p_valor  => p_val);
    --
 END mx;
*/
 --
 /* -------------------------------------------------------- 
 || mx :
 || 
 || Genera la traza
 */ -------------------------------------------------------- 
 --
/*
 PROCEDURE mx(p_tit VARCHAR2,
              p_val BOOLEAN ) IS
 BEGIN
    --
    pp_asigna (p_nom_global => 'fic_traza',
               p_val_global => 'ap740055' );
    --
    pp_asigna (p_nom_global => 'cab_traza',
               p_val_global => '->');
    --
    em_k_traza.p_escribe (p_titulo => p_tit,
                          p_valor  => p_val);
    --
 END mx;
*/
 --
 /* ----------------------------------------------------
 || Devuelve el error 
 */ ----------------------------------------------------
 --
 PROCEDURE pi_devuelve_error IS
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
 END pi_devuelve_error;
 --
 /* ----------------------------------------------------
 || Devuelve la descripcion del error
 */ ----------------------------------------------------
 --
 FUNCTION fi_txt_mensaje(p_cod_mensaje g1010020.cod_mensaje%TYPE)
          RETURN g1010020.txt_mensaje%TYPE IS
 BEGIN
  --
  RETURN ss_k_mensaje.f_texto_idioma(p_cod_mensaje,g_cod_idioma);
  --
 END fi_txt_mensaje;
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
  l_retorno := ss_f_nom_valor(p_cod_campo ,
                              999         ,
                              p_cod_valor ,
                              g_cod_idioma);
  --
  RETURN l_retorno;
  --
 END fi_g1010031;
--
 /* -------------------- MODIFICACIONES --------------------
 || Juan Luj n     - 02/04/22
 || Creacion.
 */ -----------------------------------------------------
 --
 --
 /* -------------------- MODIFICACIONES --------------------
 || Juan Lujan  - 02/04/22
 || Creacion p_inicio.
 */ --------------------------------------------------------
 --
 PROCEDURE p_inicio ( p_llamado IN VARCHAR2 )
 IS
 BEGIN
    --
    g_cod_cia       := trn_k_global.cod_cia;
    g_cod_usr       := trn_k_global.cod_usr;
    g_cod_idioma    := trn_k_global.cod_idioma;
    g_fec_actu      := trn_k_tiempo.f_fec_actu;
    g_llamado       := p_llamado;
    --
    g_num_sini            := trn_k_global.devuelve('num_sini');
    g_num_exp             := trn_k_global.devuelve('num_exp');
    --
    g_cod_ramo            := trn_k_global.devuelve('cod_ramo'); 
    g_cod_sector          := trn_k_global.devuelve('cod_sector');
    g_num_poliza          := trn_k_global.devuelve('num_poliza');
    g_cod_tramitador      := trn_k_global.devuelve('cod_tramitador');
    g_tip_exp_aper        := trn_k_global.devuelve('tip_exp');
    --
    g_nom_prg_obs_tramite := trn_k_global.ref_f_global('nom_prg_obs_tramite');
      
    trn_k_global.asigna('cod_nivel3_asig','NULL');
    --
 END p_inicio;
 --
 /* -----------------------------------------------------
 || p_v_cod_nivel3:
 || ---
 || Validación de la oficina tramitadora donde se quiere enviar el 
 || expediente.      
 */ -----------------------------------------------------
 --
 PROCEDURE p_v_cod_nivel3    
          (p_cod_nivel3         IN     g7000155.cod_nivel3        %TYPE,
           p_nom_nivel3         IN OUT a1000702.nom_nivel3        %TYPE) IS
   --
   l_cod_tratamiento  a1001800.cod_tratamiento   %TYPE;
   --
 BEGIN 
    ---
    IF p_cod_nivel3 IS NOT NULL
    THEN
       --
       BEGIN
       --
       dc_k_a1001800.p_lee(g_cod_cia,
                           g_cod_ramo);
       l_cod_tratamiento  := dc_k_a1001800.f_cod_tratamiento;
       --
       EXCEPTION
       WHEN OTHERS
       THEN
          --
          g_cod_mensaje := 20001;
          g_anx_mensaje := g_k_ini_corchete
                           ||
                           'ap740055 p_v_cod_nivel3 lee a1001800'
                           || g_k_fin_corchete;
          --
          pi_devuelve_error;
          --
       END;
       --
       ts_k_g7000155.p_lee( g_cod_cia,
                            l_cod_tratamiento, 
                            g_cod_sector,
                            g_cod_ramo,
                            p_cod_nivel3);
       --
       BEGIN
       --
       dc_k_a1000702.p_lee(g_cod_cia,
                           p_cod_nivel3);
       --
       p_nom_nivel3   := dc_k_a1000702.f_nom_nivel3;
       --
       EXCEPTION 
       WHEN OTHERS
       THEN
          --
          g_cod_mensaje := 20001;
          g_anx_mensaje := g_k_ini_corchete||
                           'ap740055 p_v_cod_nivel3 lee a1000702'|| g_k_fin_corchete;
          --
          pi_devuelve_error;
          --
       END;
       --
       trn_k_global.asigna('cod_nivel3_asig',p_cod_nivel3);
       --
       ts_p_valida_nivel3_asig;
       --
       g_cod_nivel3  := p_cod_nivel3;
       --
   END IF;
   --
 END p_v_cod_nivel3;
 --
 /* -----------------------------------------------------
 || p_v_cod_tramitador  
 */ -----------------------------------------------------
 --
 PROCEDURE p_v_cod_tramitador
          (p_cod_tramitador     IN     a1001339.cod_tramitador    %TYPE,
           p_nom_tramitador     IN OUT v1001390.nom_completo      %TYPE) IS
  --
 BEGIN 
    ---
    IF p_cod_tramitador IS NOT NULL
    THEN
       --
       /* Se valida que sea tramitador */
       --
       -- Change for 1.2: The references to package ts_k_a1001339 are replaced by dc_k_a1001339
       -- 
       dc_k_a1001339.p_lee_cod_tramitador (p_cod_cia        => g_cod_cia       ,
                                           p_cod_tramitador => p_cod_tramitador);
       --
       /* Se obtiene su nombre de la vista */
       --
       dc_k_v1001390.p_lee ( g_cod_cia,
                            '9',   -- TRAMITADORES.
                             NULL, -- tip_docum,
                             NULL, -- cod_docum,
                             p_cod_tramitador );
       --
       p_nom_tramitador := dc_k_v1001390.f_nom_completo;
       --
       /* Obtengo el tramitador del expediente para verificar que no sea el mismo 
          que tiene asignado el expediente */
       --
       ts_k_a7001000.p_lee_a7001000(g_cod_cia,
                                   g_num_sini,
                                   g_num_exp);          
       --            
       g_cod_tramitador_aper :=  ts_k_a7001000.f_cod_tramitador;
       --                        
       IF p_cod_tramitador = g_cod_tramitador_aper
       THEN
          --
          -- Error se está reasignado al dueño del expediente.
          g_cod_mensaje := 70001209;
          g_anx_mensaje := g_k_ini_corchete||
                           ' ap740055 '
                           || g_k_fin_corchete;
          --
          pi_devuelve_error;
          --
        END IF;
        --
        trn_k_global.asigna('cod_tramitador_asig', p_cod_tramitador);
       --
       /* Se llama a la validacion variable */
       --
       ts_p_valida_tramit_asig;
       --
    ELSE
       g_cod_mensaje := 20003;
       g_anx_mensaje := g_k_ini_corchete||
                           ' ap740055.- p_v_cod_tramitador '
                           || g_k_fin_corchete;
        --
        pi_devuelve_error;
        --    
    END IF; 
    --
 END p_v_cod_tramitador;
 --
 /* -----------------------------------------------------
 || p_pre_cod_tramitador  
 */ -----------------------------------------------------
 --
 PROCEDURE p_pre_cod_tramitador 
         ( p_cod_tramitador      IN OUT a1001339.cod_tramitador %TYPE)
  IS
    --
    l_tip_docum    a1001339.tip_docum  %TYPE;
    l_cod_docum    a1001339.cod_docum  %TYPE;
    --
   BEGIN
   --
   /* Se obtiene el tramitador por defecto y se devuelve al Java */
   --
    ts_p_obtiene_tramitador (g_cod_cia              ,
                             g_cod_sector           , 
                             g_cod_ramo             ,
                             g_num_poliza           ,
                             g_cod_nivel3           , -- El que se ha pasado por pantalla
                             g_cod_tramitador       , -- El que ha entrado
                             g_tip_exp_aper         ,
                             l_cod_docum            ,
                             l_tip_docum            , 
                             p_cod_tramitador       ); 
      --
  EXCEPTION
  WHEN OTHERS
  THEN
     --
     p_cod_tramitador := NULL;
     --
   END;
 --
 /* -----------------------------------------------------
 || p_actualiza  
 */ -----------------------------------------------------
 --
   PROCEDURE p_actualiza 
          (p_cod_nivel3         IN     g7000155.cod_nivel3        %TYPE,
           p_nom_nivel3         IN     a1000702.nom_nivel3        %TYPE,
           p_cod_tramitador     IN     a1001339.cod_tramitador    %TYPE,
           p_nom_tramitador     IN     v1001390.nom_completo      %TYPE) IS
   -- 
   BEGIN
   --
   ts_p_valida_reasignacion;
   -- 
    ts_k_ap740000.p_reasigna_expediente (g_num_sini,
                                         g_num_exp,
                                         g_cod_tramitador_aper,
                                         p_cod_tramitador      
                                         );
   --
   trn_k_global.asigna('cod_tramitador',p_cod_tramitador);
   trn_k_global.asigna('nom_tramitador',p_nom_tramitador);
    --
   IF g_nom_prg_obs_tramite IS NOT NULL
   THEN
      trn_k_dinamico.p_ejecuta_procedimiento(g_nom_prg_obs_tramite);
   END IF;
   -- 
 END;
   -- 
--
 /* --------------------------------------------------
 || Borra las globales correspondientes dependiendo
 || de si es llamado por otro programa o llamado por  
 || el menu directamente.
  */ --------------------------------------------------
 PROCEDURE p_salir ( p_llamado    VARCHAR2 )
 --
 IS
  --
    PROCEDURE pi_borra_variables
    IS
    BEGIN
     --
    g_llamado             := NULL;
    g_num_sini            := NULL;
    g_num_exp             := NULL;
    g_cod_cia             := NULL;
    g_cod_usr             := NULL;
    g_fec_actu            :=  NULL;
    g_llamado             :=  NULL;
    --
    g_cod_ramo            := NULL; 
    g_cod_sector          := NULL;
    g_num_poliza          := NULL;
    g_cod_tramitador_aper := NULL;
    g_cod_tramitador      := NULL;
    g_tip_exp_aper        := NULL;
    --
   END pi_borra_variables;
   --
   PROCEDURE pi_borra_globales
   IS
   --
   BEGIN
      --
      trn_k_global.borra_variable('cod_nivel3_asig');
      trn_k_global.borra_variable('cod_tramitador_asig');
      --
   END pi_borra_globales;
   --
 BEGIN -- p_salir --
   --
   IF p_llamado = 'N' -- Ha sido llamado desde el Menu Principal.
   THEN
     --
     IF g_num_sini IS NOT NULL
     THEN
        ts_k_a7000900.p_actualiza_exclusivo(g_cod_cia,
                                            g_num_sini,
                                            'N');
     END IF;
     --
     trn_k_global.borra_todas;
     --
   ELSE
     --
     pi_borra_globales;
     --
   END IF;
   --
   pi_borra_variables;
   --
 END p_salir;
--
END ts_k_ap740055_trn;
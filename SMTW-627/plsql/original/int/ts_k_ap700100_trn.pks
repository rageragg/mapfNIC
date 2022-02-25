create or replace PACKAGE ts_k_ap700100_trn
AS
 --
 /* -------------------- VERSION = 1.21 --------------------*/
 --
 /**-------------------- DESCRIPCION --------------------
 ||
 || Package del programa AP700100 Apertura de Siniestros.
 ||
 */ -----------------------------------------------------------------
 --
 /* -------------------- MODIFICACIONES --------------------------------------
 || 2016/02/04 - PSANTOS - 1.21 - (MU-2016-011648)
 || Se modificar el funcionamiento del alta de siniestros para controlar cuando estemos dando de
 || alta siniestros en fechas no efectivas de la póliza debido a suplementos de renovación discontinuos
 || dados de alta para la propia póliza
 || Se genera una nueva función f_devuelve_spto_discontinuo que comprueba si existe un suplemento
 || discontinúo con un efecto/vencimiento posterior a la fecha de ocurrencia del siniestro
 */ --------------------------------------------------------------------------
 --
 /**-------------------- DESCRIPCION --------------------
 || Inicializa las variables.
 */ -----------------------------------------------------
 --
 PROCEDURE p_inicio;
 --
 /**-------------------- DESCRIPCION --------------------
 || Valida la fecha del siniestro.
 */ -----------------------------------------------------
 --
 PROCEDURE p_v_fec_sini
           ( p_fec_sini      a7000900.fec_sini      %TYPE);
 --
 /**-------------------- DESCRIPCION --------------------
 || Valida la hora del siniestro si no es nula.
 */ -----------------------------------------------------
 --
 PROCEDURE p_v_hora_sini
           (p_hora_sini      a7000900.hora_sini      %TYPE);
 --
 /**-------------------- DESCRIPCION --------------------
 || Valida la fecha de denuncia, notificacion del siniestro.
 */ -----------------------------------------------------
 --
 PROCEDURE p_v_fec_denu_sini
           ( p_fec_denu_sini         a7000900.fec_denu_sini  %TYPE);
 --
 /**-------------------- DESCRIPCION --------------------
 || Valida la hora de notificacion del siniestro si no es nula.
 */ -----------------------------------------------------
 --
 PROCEDURE p_v_hora_denu_sini
           (p_hora_denu_sini      a7000900.hora_denu_sini      %TYPE);
 --
 /**--------------------------------------------------------------
 || Menu de opciones 1
 || Asigna las variables que tiene hasta ahora
 || a globales para que se pueda llamar a alguna opcion
 */ --------------------------------------------------------------
 --
 PROCEDURE p_asigna_globales_menu_1;
 --
 /**--------------------------------------------------------------
 || Borra opciones 1
 || Borra las variables que se asignaron en el menu 1
 */ --------------------------------------------------------------
 --
 PROCEDURE p_borra_globales_menu_1;
 --
 /**-------------------- DESCRIPCION --------------------
 || Valida la poliza: que exista, no este anulada, no sea un siniestro
 || declarado fuera de plazo...
 */ -----------------------------------------------------
 --
 PROCEDURE p_v_num_poliza
           ( p_num_poliza      IN       a7000900.num_poliza      %TYPE,
             p_num_spto        IN OUT   a7000900.num_spto        %TYPE,
             p_num_apli        IN OUT   a7000900.num_apli        %TYPE,
             p_num_spto_apli   IN OUT   a7000900.num_spto_apli   %TYPE,
             p_num_riesgo      IN OUT   a7000900.num_riesgo      %TYPE,
             p_tip_poliza_tr   IN OUT   a2000030.tip_poliza_tr   %TYPE,
             p_tip_poliza_stro IN OUT   a7000900.tip_poliza_stro %TYPE);
 --
 /**-------------------- DESCRIPCION --------------------
 || Valida la aplicacion, y obtiene el spto, spto_apli...
 */ -----------------------------------------------------
 --
 PROCEDURE p_v_num_apli (p_num_apli      IN      a2000030.num_apli     %TYPE,
                         p_num_spto      IN OUT  a2000030.num_spto     %TYPE,
                         p_num_spto_apli IN OUT  a2000030.num_spto_apli%TYPE,
                         p_num_riesgo    IN OUT  a2000031.num_riesgo   %TYPE);
 --
 /**--------------------------------------------------------------
 || p_pre_lv_num_riesgo: paso de globales necesarias para llamar al
 || programa de la Consulta de Riesgos (AC299310).
 */ --------------------------------------------------------------
 --
 PROCEDURE p_pre_lv_num_riesgo(p_num_poliza    a2000031.num_poliza    %TYPE,
                               p_num_spto      a2000031.num_spto      %TYPE,
                               p_num_apli      a2000031.num_apli      %TYPE,
                               p_num_spto_apli a2000031.num_spto_apli %TYPE,
                               p_num_riesgo    a2000031.num_riesgo    %TYPE,
                               p_fec_sini      a7000900.fec_sini      %TYPE);
 --
 /**--------------------------------------------------------------
 || p_pre_lv_num_riesgo: borra las globales que se han utilizado para
 || llamar al programa de la Consulta de Riesgos (AC299310).
 */ --------------------------------------------------------------
 --
 PROCEDURE p_post_lv_num_riesgo;
 --
 /**-------------------- DESCRIPCION --------------------
 || Valida El riesgo, que exista , obtiene el nombre del riesgo...
 */ -----------------------------------------------------
 --
 PROCEDURE p_v_num_riesgo
           ( p_num_riesgo            IN     a7000900.num_riesgo        %TYPE,
             p_nom_riesgo            IN OUT a2000031.nom_riesgo        %TYPE,
             p_hay_mas_siniestros    IN OUT a7000900.tip_est_sini      %TYPE,
             p_exclusivo             IN OUT a7000900.mca_exclusivo     %TYPE,
             p_nom_situacion         IN OUT a5020500.nom_situacion     %TYPE,
             p_tip_docum_tomador     IN OUT a7000900.tip_docum_tomador %TYPE,
             p_cod_docum_tomador     IN OUT a7000900.cod_docum_tomador %TYPE,
             p_nom_tomador           IN OUT v1001390.nom_completo      %TYPE,
             p_cod_agt               IN OUT a7000900.cod_agt           %TYPE,
             p_nom_agente            IN OUT v1001390.nom_completo      %TYPE );
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
                                 );
 /**--------------------------------------------------------------
 || Rellena la tabla pl con todas las coberturas de la poliza
 */--------------------------------------------------------------
 --
 PROCEDURE p_recupera_cob;
 --
 /**--------------------------------------------------------------
 || Devuelve las coberturas y su descripcion
 */--------------------------------------------------------------
 --
 PROCEDURE p_devuelve
           (p_num_secu_k          IN OUT NUMBER,
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
            p_cod_mon_iso         IN OUT a1000400.cod_mon_iso %TYPE);
            -- p_num_decimales       IN OUT a1000400.num_decimales %TYPE);
 --
 /**--------------------------------------------------------------
 || Menu de opciones 2
 || Asigna las variables que tiene hasta ahora
 || a globales para que se pueda llamar a alguna opcion
 */ --------------------------------------------------------------
 --
 PROCEDURE p_asigna_globales_menu_2
           (p_cod_pgm_call  IN g1010131.cod_pgm_call  %TYPE);
 --
 /**--------------------------------------------------------------
 || Borra   opciones 2
 || Borra las variables que se asignaron para el menu 2
 */ --------------------------------------------------------------
 --
 PROCEDURE p_borra_globales_menu_2
           (p_cod_pgm_call  IN g1010131.cod_pgm_call  %TYPE);
 --
 /**-------------------- DESCRIPCION --------------------
 || Valida si no es nulo que exista el cod_evento y devuelve el nombre
 */ -----------------------------------------------------
 --
 --{{ TG_PPUB_E
 PROCEDURE p_v_cod_evento
           ( p_cod_evento            IN     a7990700.cod_evento%TYPE          ,
             p_nom_evento            IN OUT a7990700.nom_evento%TYPE          ,
             p_mca_hay_ctrl_tecnico  IN OUT VARCHAR2                          ,
             p_ape_contacto          IN OUT a7000900.ape_contacto        %TYPE,
             p_nom_contacto          IN OUT a7000900.nom_contacto        %TYPE,
             p_tel_pais_contacto     IN OUT a7000900.tel_pais_contacto   %TYPE,
             p_tel_zona_contacto     IN OUT a7000900.tel_zona_contacto   %TYPE,
             p_tel_numero_contacto   IN OUT a7000900.tel_numero_contacto %TYPE,
             p_email_contacto        IN OUT a7000900.email_contacto      %TYPE);
--}} TG_PPUB_E
 --
 /**-------------------- DESCRIPCION --------------------
 || Valida el tipo de relacion de la persona de contacto con el
 || asegurado y devuelve el nombre, el telefono y el email
 */ -----------------------------------------------------
 --
 PROCEDURE p_v_tip_relacion(p_tip_relacion        IN     a7000900.tip_relacion        %TYPE,
                            p_nom_tip_relacion    IN OUT g1010031.nom_valor           %TYPE,
                            p_tip_docum_contacto  IN OUT a7000900.tip_docum_contacto  %TYPE,
                            p_cod_docum_contacto  IN OUT a7000900.cod_docum_contacto  %TYPE,
                            p_nom_contacto        IN OUT a7000900.nom_contacto        %TYPE,
                            p_ape_contacto        IN OUT a7000900.ape_contacto        %TYPE,
                            p_tel_pais_contacto   IN OUT a7000900.tel_pais_contacto   %TYPE,
                            p_tel_zona_contacto   IN OUT a7000900.tel_zona_contacto   %TYPE,
                            p_tel_numero_contacto IN OUT a7000900.tel_numero_contacto %TYPE,
                            p_email_contacto      IN OUT a7000900.email_contacto      %TYPE);
 --
 /**-------------------- DESCRIPCION --------------------
 || Valida el tipo de documento de la persona de contacto
 */ -----------------------------------------------------
 --
 PROCEDURE p_v_tip_docum_contacto
           ( p_tip_docum_contacto IN    a7000900.tip_docum_contacto %TYPE);
 --
 /**-------------------- DESCRIPCION --------------------
 || Valida el codigo de documento de la persona de contacto
 */ -----------------------------------------------------
 --
 PROCEDURE p_v_cod_docum_contacto
           (p_tip_docum_contacto IN     a7000900.tip_docum_contacto %TYPE,
            p_cod_docum_contacto IN     a7000900.cod_docum_contacto %TYPE,
            p_nom_contacto       IN OUT a7000900.nom_contacto       %TYPE,
            p_ape_contacto       IN OUT a7000900.ape_contacto       %TYPE);
 --
 /**-------------------- DESCRIPCION --------------------
 || Valida el codigo de causa (no este inhabilitada, que existan consecuen-
 || cias ,) y obtiene el nombre de la causa.
 */ -----------------------------------------------------
 --
 PROCEDURE p_v_cod_causa
           ( p_cod_causa              IN     g7000200.cod_causa           %TYPE,
             p_nom_causa              IN OUT g7000200.nom_causa           %TYPE,
             p_mca_tramitable         IN OUT g7000200.mca_tramitable      %TYPE,
             p_tip_tramitador         IN OUT a1001339.tip_tramitador      %TYPE,
             p_mca_hay_ctrl_tecnico3  IN OUT VARCHAR2                          );
 --
 /**--------------------------------------------------------
 || Graba las tablas de siniestros a7000900,a7001020,a7000930
 ||
 */----------------------------------------------------------
 --
 PROCEDURE p_graba_a7000900;
 --
 /**--------------------------------------------------------
 || Graba las tablas de siniestros a7000900,a7001020,a7000930
 */----------------------------------------------------------
 --
 PROCEDURE p_graba_resto_stros;
 --
 /**--------------------------------------------------------
 || Abandona la apertura del siniestro haciendo ROLLBACK, marcando
 || el siniestro como no usado y borrando variables y globales
 */----------------------------------------------------------
 --
 PROCEDURE p_abandonar_stro;
 --
 /**--------------------------------------------------------
 || Termina  la apertura del siniestro borra el numero del saco
 || y borra variables y globales
 */----------------------------------------------------------
 --
 PROCEDURE p_termina_apertura_stro;
 --
 /**--------------------------------------------------------
 || Termina  la apertura del siniestro borra el numero del saco
 || y borra variables y globales y mira si se han terminado todos
 || los expedientes para terminar el siniestro.
 */----------------------------------------------------------
 --
 PROCEDURE p_termina_apertura_expedientes;
 --
 /**----------------------------------------------------
 || Devuelve la marca de provisional del siniestro
 */ ----------------------------------------------------
 --
 FUNCTION f_mca_provisional
          RETURN a7000900.mca_provisional%TYPE;
 --
 /**----------------------------------------------------------------
 || Proceso automatico de apertura de siniestros. Llamado desde el
 || ts_k_batch.
 */-----------------------------------------------------------------
 --
 PROCEDURE p_batch
           ( p_cod_cia             IN     b7000900.cod_cia             %TYPE,
             p_fec_tratamiento     IN     b7000900.fec_tratamiento     %TYPE,
             p_tip_mvto_batch_stro IN     b7000900.tip_mvto_batch_stro %TYPE,
             p_num_sini_ref        IN     b7000900.num_sini_ref        %TYPE,
             p_num_sini            IN OUT b7000900.num_sini            %TYPE,
             p_num_orden           IN     b7000900.num_orden           %TYPE);
 --
 /**----------------------------------------------------------------
 || Ejecuta los errores de CT de nivel de salto 1 para el sistema 7.
 */-----------------------------------------------------------------
 --
 PROCEDURE p_aceptar_datos_identif ( p_mca_hay_ctrl_tecnico  IN OUT VARCHAR2 );
 --
 /**-------------------- DESCRIPCION --------------------
 || Valida el campo num_sini_ref.
 */ -----------------------------------------------------
 --
 PROCEDURE p_v_num_sini_ref (p_num_sini_ref   a7000900.num_sini_ref %TYPE);
 --
 /**-------------------- DESCRIPCION --------------------
 || Devuelve el valor por defecto de la fechasini.
 */ -----------------------------------------------------
 --
 FUNCTION f_fec_sini_defecto RETURN DATE;
 --
 /**-------------------- DESCRIPCION --------------------
 || Devuelve el valor por defecto de la hora del siniestro.
 */ -----------------------------------------------------
 --
 FUNCTION f_hora_sini_defecto RETURN VARCHAR2;
 --
 /**-------------------- DESCRIPCION --------------------
 || Devuelve el valor por defecto de la fecha de denuncia.
 */ -----------------------------------------------------
 --
 FUNCTION f_fec_denu_defecto RETURN DATE;
 --
 /**-------------------- DESCRIPCION --------------------
 || Devuelve el valor por defecto de la hora de denuncia.
 */ -----------------------------------------------------
 --
 FUNCTION f_hora_denu_sini_defecto RETURN VARCHAR2;
 --
 /**-------------------- DESCRIPCION --------------------
 || Devuelve el valor por defecto de la poliza.
 */ -----------------------------------------------------
 --
 FUNCTION f_num_poliza_defecto RETURN VARCHAR2;
 --
 /**-------------------- DESCRIPCION --------------------
 || Devuelve el valor por defecto del numero de riesgo.
 */ -----------------------------------------------------
 --
 FUNCTION f_num_riesgo_defecto RETURN NUMBER;
 --
 /**-------------------- DESCRIPCION --------------------
 || Devuelve el valor por defecto el tipo de relacion de la persona
 || de contacto con el asegurado.
 */ -----------------------------------------------------
 --
 FUNCTION f_tip_relacion_defecto RETURN VARCHAR2;
 --
 /**-------------------- DESCRIPCION --------------------
 || Devuelve el valor por defecto Tipo de documento del contacto
 */ -----------------------------------------------------
 --
 FUNCTION f_tip_docum_cont_defecto RETURN VARCHAR2;
 --
 /**-------------------- DESCRIPCION --------------------
 || Devuelve el valor por defecto codigo de documento del contacto
 */ -----------------------------------------------------
 --
 FUNCTION f_cod_docum_cont_defecto RETURN VARCHAR2;
 --
 /**-------------------- DESCRIPCION --------------------
 || Devuelve el valor por defecto Nombre de la persona de contacto
 */ -----------------------------------------------------
 --
 FUNCTION f_nom_cont_defecto RETURN VARCHAR2;
 --
 /**-------------------- DESCRIPCION --------------------
 || Devuelve el valor por defecto Apellidos de la persona de contacto
 */ -----------------------------------------------------
 --
 FUNCTION f_ape_cont_defecto RETURN VARCHAR2;
 --
 /**-------------------- DESCRIPCION --------------------
 || Devuelve el valor por defecto Pais del telefono de contacto
 */ -----------------------------------------------------
 --
 FUNCTION f_tel_p_cont_defecto RETURN VARCHAR2;
 --
 /**-------------------- DESCRIPCION --------------------
 || Devuelve el valor por defecto Zona del telefono de contacto
 */ -----------------------------------------------------
 --
 FUNCTION f_tel_z_cont_defecto RETURN VARCHAR2;
 --
 /**-------------------- DESCRIPCION --------------------
 || Devuelve el valor por defecto Numero del telefono de contacto
 */ -----------------------------------------------------
 --
 FUNCTION f_tel_n_cont_defecto RETURN VARCHAR2;
 --
 /**-------------------- DESCRIPCION --------------------
 || Devuelve el valor por defecto el email de contacto
 */ -----------------------------------------------------
 --
 FUNCTION f_email_cont_defecto RETURN VARCHAR2;
 --
 /**-------------------- DESCRIPCION --------------------
 || Devuelve el valor por defecto del numero de aplicación.
 */ -----------------------------------------------------
 --
 FUNCTION f_num_apli_defecto RETURN NUMBER;
 --
 /* -------------------- DESCRIPCION --------------------
 || Procedimiento que valida que la póliza no sea ficticia.
 */ -----------------------------------------------------
 PROCEDURE p_val_poliza_ficticia (p_num_sini IN a7000900.num_sini%TYPE);
 --
 /**--------------------------------------------------------------
 || Devuelve el número de decimales del siniestro/poliza
 */--------------------------------------------------------------
 --
 PROCEDURE p_decimales_poliza
           ( p_num_decimales        OUT a1000400.num_decimales %TYPE);
 --
 /**-------------------- DESCRIPCION --------------------
 || Valida importe de valoración inicial del siniestro
 */ -----------------------------------------------------
 --
 PROCEDURE p_v_imp_val_ini_sini (p_imp_val_ini_sini IN a7000900.imp_val_ini_sini%TYPE);
 --
 --
 /** ------------------------------------------------------------
 || f_calcula_errores_ct
 || LLeva a cabo el calculo de errores de CT del nivel de salto
 || que se indica por parametro, indicando en el resultado si
 || se han producido errores o no.
 */--------------------------------------------------------------
 --
 FUNCTION f_calcula_errores_ct 	 ( p_cod_nivel_salto  g2000220.cod_nivel_salto %TYPE )
          RETURN VARCHAR2;
 --
  /** ---------------------------------------------
 || Retorna 'S' si se producen errores de control
 || tecnico en el nivel de salto indicado y 'N'
 || en caso contrario .
 */ ----------------------------------------------
 --
 FUNCTION f_devuelve_spto_discontinuo (p_cod_cia         IN    a2000030.cod_cia       %TYPE,
                                       p_num_poliza      IN    a2000030.num_poliza    %TYPE,
                                       p_fec_sini        IN    a7000900.fec_sini      %TYPE,
                                       p_hora_sini       IN    a7000900.hora_sini     %TYPE DEFAULT TO_DATE('0000', 'HH24MI'))
          RETURN BOOLEAN;
 /*--------------------------------------------------------------
 || f_devuelve_spto_discontinuo
 || Para una fecha dada consulta si existe algun suplemento de renovación
 || que por ser discontinúo no estaba vigente a la fecha del siniestro
  */--------------------------------------------------------------
 --
 --
 END ts_k_ap700100_trn;


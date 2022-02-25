create or replace PACKAGE ts_k_ap700117_trn
AS
 --
 /* -------------------- VERSION = 1.2 --------------------*/
 --
 /* -------------------- DESCRIPCION --------------------
 ||  Package del programa de Apertura de Expedientes AP700117.
 ||  Controla todas las operaciones que se realizan en dicho programa.
 ||  ---
 || 2015/10/21 - JLOROMERO - 1.2 - (MU-2015-056746)
 || Se crea el procedimiento p_batch_recobro_aut para la apertura automatica de
 || recobros asociados a expedientes de no recobro.
 */ -----------------------------------------------------
 --
 PROCEDURE p_carga_globales_validacion;
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
 PROCEDURE p_inicio;
 --
/* --------------------------------------------------------------
||  Procedimiento que inicializa las variables, borra la tabla de memoria
|| y carga las globales.
*/ --------------------------------------------------------------
 --
 PROCEDURE p_devuelve
          (p_cod_evento           IN OUT  a7000900.cod_evento       %TYPE ,
           p_nom_evento           IN OUT  a7990700.nom_evento       %TYPE ,
           p_cod_causa            IN OUT  a7000900.cod_causa_sini   %TYPE ,
           p_nom_causa            IN OUT  g7000200.nom_causa        %TYPE ,
           p_cod_consecuencia_1   IN OUT  a7000930.cod_consecuencia %TYPE ,
           p_cod_consecuencia_2   IN OUT  a7000930.cod_consecuencia %TYPE ,
           p_cod_consecuencia_3   IN OUT  a7000930.cod_consecuencia %TYPE ,
           p_cod_consecuencia_4   IN OUT  a7000930.cod_consecuencia %TYPE ,
           p_cod_consecuencia_5   IN OUT  a7000930.cod_consecuencia %TYPE );
  --
 /* --------------------------------------------------------------
 || Procedimiento que devuelve los campos que van a visualizarse por
 || pantalla.
 */ --------------------------------------------------------------
 --
 PROCEDURE p_carga_globales_apertura;
 --
 /* -------------------- DESCRIPCION --------------------
 || Procedimiento que carga en memoria las globales que va a necesitar
 || la Rutina de Apertura de expedientes AS700030.
 */ --------------------------------------------------------------
 --
 PROCEDURE p_terminar_apertura_exp
          (p_llamado_desde_otro_programa IN VARCHAR2                  );
 --
 /* -------------------- DESCRIPCION --------------------
 || Procedimiento que controla la Terminacion de la Apertura de Expedientes.
 */ --------------------------------------------------------------
 --
 PROCEDURE p_abandonar_apertura_exp
          (p_llamado_desde_otro_programa IN VARCHAR2                  );
 --
 /* -------------------- DESCRIPCION --------------------
 || Procedimiento que controla el abandonar la Apertura de Expedientes.
 */ --------------------------------------------------------------
 --
/* PROCEDURE p_batch (p_cod_cia           b7000910.cod_cia             %TYPE,
                    p_fec_tratamiento     b7000910.fec_tratamiento     %TYPE,
                    p_tip_mvto_batch_stro b7000910.tip_mvto_batch_stro %TYPE,
                    p_num_sini            b7000910.num_sini            %TYPE);*/
 --
 PROCEDURE p_batch;
 --
 /* -------------------- DESCRIPCION --------------------
 || Procedimiento para la apertura de expedientes Batch
 */ ------------------------------------------------------
 --
 PROCEDURE p_batch_recobro_aut;
 --
 /* -------------------- DESCRIPCION --------------------
 || Procedimiento para la apertura automatica de expedientes
 || de recobro asociados a expedientes de no recobro
 */ ------------------------------------------------------
 --
-- --------------------------------------------------------------
END ts_k_ap700117_trn;


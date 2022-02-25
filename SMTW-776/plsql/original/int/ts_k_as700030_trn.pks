create or replace PACKAGE ts_k_as700030_trn
AS
 --
 /* -------------------- VERSION = 1.28 --------------------*/
 --
 /* -------------------- DESCRIPCION -----------------------------------
 ||  Package de la rutina AS700030.
 ||  Controla todas las operaciones que se realizan en la apertura de
 || expedientes.
 || ---------------------------------------------------------------------
 || 2015/10/21 - JLOROMERO - 1.28 - (MU-2015-056746)
 || Se crean los siguientes procedimientos para la apertura automatica de
 || recobros asociados a expedientes de no recobro:
 || -p_recobro_aut
 || -pp_recobros_asoc_aut
 || -p_batch_recobro
 || -p_query_para_recobros_aut
 || ---------------------------------------------------------------------
 */ ---------------------------------------------------------------------
 --
 PROCEDURE p_inicio;
 --
/* --------------------------------------------------------------
||  Procedimiento que inicializa las variables, borra la tabla de memoria
|| y carga las globales.
*/ --------------------------------------------------------------
 --
 PROCEDURE p_query;
 --
/* --------------------------------------------------------------
|| Devuelve un registro de la tabla de memoria de los posibles expedientes
 || a aperturar.
*/ --------------------------------------------------------------
 PROCEDURE p_devuelve
          (p_num_secu_k           IN OUT  NUMBER                          ,
           p_tip_exp              IN OUT  g7000080.tip_exp          %TYPE ,
           p_nom_exp              IN OUT  g7000090.nom_exp          %TYPE ,
           p_mca_obligatorio      IN OUT  g7000080.mca_obligatorio  %TYPE ,
           p_num_exp_aper         IN OUT  a7001000.num_exp          %TYPE ,
           p_mca_aper_aut         IN OUT  g7000100.mca_aper_aut     %TYPE );
 --
 /* -------------------- DESCRIPCION --------------------
 || Devuelve un registro de la tabla de memoria
 */ --------------------------------------------------------------
 --
 PROCEDURE p_selecciona_expediente
           ( p_tip_exp                IN     a7001000.tip_exp       %TYPE,
             p_pide_moneda            IN OUT VARCHAR2                    ,
             p_pide_causas_aper       IN OUT g7000100.mca_causa_aper%TYPE,
             p_pide_exp_a_aperturar   IN OUT VARCHAR2                    );
 --
 /* --------------------------------------------------------------
 || Procedimiento que controla el inicio de la apertura del expediente.
 || Procedimiento que se debe de llamar cuando se seleccione un tipo de
 || expediente.
 */ --------------------------------------------------------------
 --
 PROCEDURE p_inserta_expediente
           (p_cod_pgm_exp      IN OUT g9990003.cod_pgm        %TYPE);
 --
 /* --------------------------------------------------------------
 || Procedimiento que continua con la apertura del expediente.
 || Procedimiento que se llama, o bien despues de p_selecciona_expediente o
 || despues de pedir la moneda del expediente (en caso de pedirse).
 */ --------------------------------------------------------------
 --
 PROCEDURE p_devuelve_cod_mon_exp
           (p_tip_exp          IN OUT    a7001000.tip_exp        %TYPE,
            p_cod_mon          IN OUT    a7001000.cod_mon        %TYPE,
            p_nom_mon          IN OUT    a1000400.nom_mon        %TYPE);
 /* --------------------------------------------------------------
 || Procedimiento que devuelve el valor por defecto de la moneda del expdte.
 || Se debe de llamar al inicio de la ventana en la que se va a pedir la moneda
 || del expediente.
 */ --------------------------------------------------------------
 --
 PROCEDURE p_v_cod_mon
           ( p_cod_mon          IN        a7001000.cod_mon        %TYPE,
             p_nom_mon          IN OUT    a1000400.nom_mon        %TYPE);
 /* --------------------------------------------------------------
 || Procedimiento que valida la moneda del expediente.
 */ --------------------------------------------------------------
 --
 PROCEDURE p_valoracion_expediente
           ( p_valoracion_ajustada IN        VARCHAR2                     ,
             p_cod_pgm_valoracion  IN OUT    g9990003.cod_pgm        %TYPE,
             p_mca_hay_errores_ct  IN OUT    VARCHAR2                      );
 /* --------------------------------------------------------------
 || Procedimiento que dependiendo del parametro p_valoracion_ajustada,
 || Insertara en la h7001200 por reserva promedio, o devolvera el
 || codigo del programa al cual se va a llamar.
 */ --------------------------------------------------------------
 --
 PROCEDURE p_graba_resto_exp;
 /* --------------------------------------------------------------
 || Procedimiento que graba el resto de las tablas que se necesitan
 || para la apertura de expedientes.
 */ --------------------------------------------------------------
 --
 PROCEDURE p_comprueba_aper_exp;
 /* --------------------------------------------------------------
 || Procedimiento que comprueba que se hayan abierto todos los
 || expedientes obligatorios.
 */ --------------------------------------------------------------
 --
 PROCEDURE p_query_para_recobros;
 /* --------------------------------------------------------------
 || Procedimiento que carga en memoria los expedientes que se van
 || a poder asociar a un recobro.
 */ --------------------------------------------------------------
 --
 PROCEDURE p_devuelve_para_recobros
          (p_num_secu_k_afec      IN OUT  NUMBER                          ,
           p_num_sini             IN OUT  a7001000.num_sini         %TYPE ,
           p_num_exp              IN OUT  a7001000.num_exp          %TYPE ,
           p_tip_exp              IN OUT  a7001000.tip_exp          %TYPE ,
           p_nom_exp              IN OUT  g7000090.nom_exp          %TYPE ,
           p_tip_est_exp          IN OUT  a7001000.tip_est_exp      %TYPE ,
           p_mca_aper_aut         IN OUT  g7000100.mca_aper_aut     %TYPE );
 /* --------------------------------------------------------------
 || Devuelve un registro de la tabla de memoria de los posibles expedientes
 || que van a afectar a un recobro.
 */ --------------------------------------------------------------
 --
 --
 PROCEDURE p_carga_variables_recobro
     (p_tip_exp          IN     a7001000.tip_exp_afec       %TYPE,
      p_num_exp          IN     a7001000.num_exp_afec       %TYPE,
      p_tip_est_exp      IN     a7001000.tip_est_afec       %TYPE,
      p_hay_mas_de_uno   IN OUT VARCHAR2                         );
 /* --------------------------------------------------------------
 || Procedimiento que carga las variables que necesito para aperturar
 || un expediente de recobro.
 || Nos devuelve en p_hay_mas_de_uno si hay que mostrar un mensaje diciendo
 || que el afectado que estamos seleccionando, ya tiene abierto un recobro del
 || mismo tipo.
 */ --------------------------------------------------------------
 --
 --
 FUNCTION f_cuenta_exp_aper (p_tip_exp     a7001000.tip_exp   %TYPE)
 RETURN NUMBER;
 /* --------------------------------------------------------------
 || Funcion que devuelve el numero de expedientes que se han aperturado
 || de un tipo. Todos los datos deben de estar cargados en las g_....
 */ --------------------------------------------------------------
 --
 --
 PROCEDURE p_modif_persona_a7001000
     ( p_tip_docum_exp       a7001000.tip_docum          %TYPE,
             p_cod_docum_exp       a7001000.cod_docum          %TYPE,
             p_nombre_exp          a7001000.nombre             %TYPE,
             p_apellidos_exp       a7001000.apellidos          %TYPE
           );
 /* --------------------------------------------------------------
 || Procedimiento que va a recoger los valores que se necesitan para poder
 || actualizar la a7001000 con los datos de la persona relacionada con el
 || expediente. Las estructuras de expedientes, deben de llamar a este procedi-
 || miento para cargar estos valores.
 */ --------------------------------------------------------------
 --
 --
 PROCEDURE p_deshacer_expediente;
 /* --------------------------------------------------------------
 || Procedimiento que realiza un ROLLBACK para deshacer el expediente que se
 || ha insertado en la a7001000.
 */ --------------------------------------------------------------
 --
 --
 PROCEDURE p_borra_variables;
 /* --------------------------------------------------------------
 || Procedimiento que borra las varables tipo g_ que se utilizan en el
 || programa AS700030, asi como las tablas de memoria que utiliza.
 */ --------------------------------------------------------------
 --
 PROCEDURE p_batch ;
 --
 /*-----------------------------------------------------------------
 || Procedimiento que lanza el proceso batch
 ||
 */-------------------------------------------------------------
--
 FUNCTION f_hay_errCT_nivel5 RETURN VARCHAR2;
 /* ----------------------------------------------------------------
 || Funci?n que lanza los procedures de errores de CT del sistema 7
 || y nivel de salto 5.
 */ ----------------------------------------------------------------
 /** ---------------------------------------------------------
 || Procedimiento para asignar la global tip_causa.
 */-------------------------------------------------------
 --
 PROCEDURE p_asigna_tip_causa  ( p_tip_causa IN g7000200.tip_causa%TYPE);
 --
 /** ---------------------------------------------------------
 || Procedimiento para asignar cod_pgm_call
 */-------------------------------------------------------
 --
 PROCEDURE p_asigna_globales_menu (p_cod_pgm_call IN g1010131.cod_pgm_call%TYPE);
 --
 /** ---------------------------------------------------------
 || Procedimiento para borrar globales
 */-------------------------------------------------------
 --
 PROCEDURE p_borra_globales_menu;
 --
 /** ---------------------------------------------------------
 || Procedimientos para la apertura automatica de expedientes de recobro
 || asociados a expedientes de no recobro
 */-------------------------------------------------------
 --
 PROCEDURE p_recobro_aut;
 PROCEDURE p_batch_recobro;
 PROCEDURE p_query_para_recobros_aut;
-- --------------------------------------------------------------
END ts_k_as700030_trn;


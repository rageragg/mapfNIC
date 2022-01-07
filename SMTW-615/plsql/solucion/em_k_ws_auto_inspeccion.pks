create or replace package em_k_ws_auto_inspeccion AS
    /* -------------------------------------------------------------------
    || Procedimientos y funciones para Web Services Cotizador VIDA
    */
    /* -------------------- VERSION = 1.00 -------------------------------
    || CARRIERHOUSE - 18/08/2021
    || CONSTRUCCION
    /* -------------------- MODIFICACIONES -------------------------------
    ||
    */
    --
    -- constantes
    K_TIP_BUSCAR_COTIZACION     CONSTANT VARCHAR2(20) := 'B-COT-001';
    K_TIP_LEER_COTIZACION       CONSTANT VARCHAR2(20) := 'L-COT-001';
    K_TIP_ACTUALIZAR_COTIZACION CONSTANT VARCHAR2(20) := 'A-COT-001';
    K_TIP_ACTUALIZAR_FOTOS      CONSTANT VARCHAR2(20) := 'A-FOT-001';
    K_TIP_LIST_PIEZAS           CONSTANT VARCHAR2(20) := 'L-PZA-001';
    K_TIP_LIST_MUNICIPIO        CONSTANT VARCHAR2(20) := 'L-MCP-001';
    K_TIP_LIST_MARCA_VEHICULO   CONSTANT VARCHAR2(20) := 'L-MAR-V01';
    K_TIP_LIST_USO_VEHICULO     CONSTANT VARCHAR2(20) := 'L-USO-V01';
    K_TIP_LIST_COLOR            CONSTANT VARCHAR2(20) := 'L-COL-V01';
    K_TIP_DOCUMENTO             CONSTANT VARCHAR2(20) := 'A-TIP-D01';
    K_TIP_RESPUESTA             CONSTANT VARCHAR2(20) := 'A-TIP-R01';
    K_TIP_LIST_DEPARTAMENTOS    CONSTANT VARCHAR2(20) := 'L-DEP-001';
    K_TIP_LIST_LINEAS           CONSTANT VARCHAR2(20) := 'L-LNA-001';
    K_TIP_ACTUALIZAR_ROTURA     CONSTANT VARCHAR2(20) := 'A-ROT-001';
    K_TIP_ACTUALIZAR_ACCESORIOS CONSTANT VARCHAR2(20) := 'A-ACC-001';
    --
    -- globales
    TYPE gc_ref_cursor IS REF CURSOR;
    --
    -- entrada buscar cotizacion
    TYPE typ_reg_b_cot_001 IS RECORD( 
        access_token        VARCHAR2(128),
        usuario             VARCHAR2(128),
        tipusuario          VARCHAR2(128),
        identificacion      VARCHAR2(128),
        placa               VARCHAR2(128),
        numeroCotizacion    VARCHAR2(128)
    );
    -- entrada informacion cotizacion
    TYPE typ_reg_i_cot_001 IS RECORD( 
        access_token        VARCHAR2(128),
        numeroCotizacion    VARCHAR2(128)
    );
    -- entrada actualizar cotizacion
    TYPE typ_reg_a_cot_001 IS RECORD( 
        access_token        VARCHAR2(128),
        numeroCotizacion    VARCHAR2(128),
        placa               VARCHAR2(128),
        marca               VARCHAR2(128),
        linea               VARCHAR2(128),
        version             VARCHAR2(128),
        modelo              VARCHAR2(128),
        codFase             VARCHAR2(128),
        motor               VARCHAR2(128),
        chasis              VARCHAR2(128),
        serie               VARCHAR2(128), 
        uso                 VARCHAR2(128),
        color               VARCHAR2(128)
    );   
    -- entrada fotos
    TYPE typ_reg_a_fot_001 IS RECORD(
        access_token        VARCHAR2(128),
        numeroCotizacion    VARCHAR2(128),
        tipoFoto            VARCHAR2(80),
        byteFoto            VARCHAR2(80)
    );
    -- entrada municipios
    TYPE typ_reg_l_mcp_001 IS RECORD(
        access_token        VARCHAR2(128),
        codigo              VARCHAR2(128)
    );
    --
    -- entrada documentos
    TYPE typ_reg_a_doc_001 IS RECORD(
        access_token        VARCHAR2(128),
        numeroCotizacion    VARCHAR2(128),
        tipoDocumento       VARCHAR2(80),
        byteFoto            VARCHAR2(80)
    );
    -- entrada respuesta
    TYPE typ_reg_a_res_001 IS RECORD(
        access_token        VARCHAR2(128),
        numeroCotizacion    VARCHAR2(128),
        resultado           VARCHAR2(80),
        comentarios         VARCHAR2(80)
    );
    -- entrada respuesta (DETALLE)
    TYPE typ_reg_a_res_002 IS RECORD(
        access_token        VARCHAR2(128),
        numeroCotizacion    VARCHAR2(128),
        control             VARCHAR2(80)
    );
    -- entrada de roturas (DETALLE)
    TYPE typ_reg_a_rot_002 IS RECORD(
        access_token        VARCHAR2(128),
        numeroCotizacion    VARCHAR2(128),
        pieza               VARCHAR2(128),
        nivelRotuta         VARCHAR2(128),
        valorRotura         VARCHAR2(80),
        byteFoto            VARCHAR2(80)
    );
    -- entrada de accesorios (DETALLE)
    TYPE typ_reg_a_acc_002 IS RECORD(
        access_token        VARCHAR2(128),
        numeroCotizacion    VARCHAR2(128),
        marca               VARCHAR2(128),
        referencia          VARCHAR2(128),
        valorAccesorio      VARCHAR2(80),
        byteFoto            VARCHAR2(80)
    );
    --
    -- salida de token
    TYPE typ_reg_token IS RECORD(
        access_token    VARCHAR2(128),
        token_type      VARCHAR2(128),
        expires_in      NUMBER(8),
        txt_mensaje     VARCHAR2(512)
    );
    --
    -- salida de cotizacion cliente
    TYPE typ_reg_cliente_cotizacion IS RECORD(
	    access_token        VARCHAR2(128),
	    usuario             VARCHAR2(128),
	    tip_usuario         VARCHAR2(128),
	    identificacion      VARCHAR2(128),
	    placa               VARCHAR2(128),
	    numeroCotizacion    VARCHAR2(128),
        poliza              VARCHAR2(128),
        txt_mensaje         VARCHAR2(512),
        fechaEfectoPoliza   VARCHAR2(128),
        fechaVctoPoliza     VARCHAR2(128),
        tipDocum            VARCHAR2(128)
    );
    --
    -- salida de mensajes
    TYPE typ_reg_mensaje IS RECORD(
        cod_mensaje x1010020_web.cod_mensaje%TYPE,
        txt_mensaje x1010020_web.txt_mensaje%TYPE,
        tip_mensaje VARCHAR2(1)
    );
    --
    -- salida de informacion de cotizacion
    TYPE typ_reg_info_cotizacion IS RECORD(
        tipoDocumento   VARCHAR2(128),
        numDocumento    VARCHAR2(128),
        nombres         VARCHAR2(128),
        apellidoPaterno VARCHAR2(128),
        apellidoMaterno VARCHAR2(128),
        telefono        VARCHAR2(128),
        email           VARCHAR2(128),
        ciudad          VARCHAR2(128),
        direccion       VARCHAR2(128),
        placa           VARCHAR2(128),
        marca           VARCHAR2(128),
        linea           VARCHAR2(128),
        version         VARCHAR2(128),
        modelo          VARCHAR2(128),
        codFase         VARCHAR2(128),
        motor           VARCHAR2(128),
        chasis          VARCHAR2(128),
        serie           VARCHAR2(128),
        uso             VARCHAR2(128),
        color           VARCHAR2(128)
    );
    --
    -- registro de cotizacion
    TYPE typ_reg_cotizacion IS RECORD(
        numeroCotizacion    VARCHAR2(128),
        placa               VARCHAR2(128),
        marca               VARCHAR2(128),
        linea               VARCHAR2(128),
        version             VARCHAR2(128),
        modelo              VARCHAR2(128),
        codFase             VARCHAR2(128),
        motor               VARCHAR2(128),
        chasis              VARCHAR2(128),
        serie               VARCHAR2(128),
        uso                 VARCHAR2(128),
        color               VARCHAR2(128)
    );
    --
    -- registro de control tecnico
    TYPE typ_reg_ctrl_tecnico IS RECORD(
        nombreControl     VARCHAR2(128)
    );
    --
    -- registro simples
    TYPE typ_reg_lista_simple IS RECORD(
        codigo      VARCHAR2(128),
        descripcion VARCHAR2(128)
    );
    --
    -- tablas
    TYPE typ_tab IS TABLE OF VARCHAR2(80) INDEX BY VARCHAR2(20);
    TYPE typ_tab_token IS TABLE OF typ_reg_token INDEX BY BINARY_INTEGER;
    TYPE typ_tab_cliente_cotizacion IS TABLE OF typ_reg_cliente_cotizacion;
    TYPE typ_tab_info_cotizacion IS TABLE OF typ_reg_info_cotizacion;
    TYPE typ_tab_reg_cotizacion IS TABLE OF typ_reg_cotizacion;
    TYPE typ_tab_reg_ctrl_tecnico IS TABLE OF typ_reg_ctrl_tecnico;
    TYPE typ_tab_reg_simple IS TABLE OF typ_reg_lista_simple;
    TYPE typ_tab_reg_fotos IS TABLE OF typ_reg_a_fot_001;
    TYPE typ_tab_reg_documentos IS TABLE OF typ_reg_a_doc_001;
    TYPE typ_tab_reg_respuestas IS TABLE OF typ_reg_a_res_001;
    TYPE typ_tab_reg_respuestas_ctrl IS TABLE OF typ_reg_a_res_002;
    TYPE typ_tab_reg_rotura_det IS TABLE OF typ_reg_a_rot_002;
    TYPE typ_tab_reg_accesorio_det IS TABLE OF typ_reg_a_acc_002;
    --
    -- devuelve error
    PROCEDURE p_devuelve_error( p_hay_error  OUT BOOLEAN,
                                p_cod_error  OUT VARCHAR2,
                                p_msg_error  OUT VARCHAR2,
                                p_sql_error  OUT VARCHAR2
                              );
    --
    -- login
    PROCEDURE p_login_ws(   p_parametros IN CLOB,
                            p_token      OUT gc_ref_cursor,
                            p_mensaje    OUT VARCHAR2
                        );
    -- login
    PROCEDURE p_login_ws(   p_parametros IN CLOB,
                            p_token      OUT gc_ref_cursor
                        );                    
    --
    -- buscar cotizacion     
    PROCEDURE p_buscar_cotizacion_cliente(  p_parametros IN CLOB,
                                            p_cotizacion OUT gc_ref_cursor,
                                            p_errores    OUT VARCHAR2
                                         );  
    --  
    -- devolvemos la informacion de la cotizacion (DETALLE)
    PROCEDURE p_informacion_cotizacion( p_parametros IN CLOB, 
                                        p_cotizacion OUT gc_ref_cursor,
                                        p_errores    OUT VARCHAR2
                                      );
    --  
    -- actualizar datos
    PROCEDURE p_actualiza_cotizacion(  p_parametros IN CLOB, 
                                       p_errores    OUT VARCHAR2
                                    );
    --
    -- incluir foto del vehiculo      
    PROCEDURE p_graba_foto_vehiculo(  p_parametros IN CLOB, 
                                      p_errores    OUT VARCHAR2
                                    );                          
    --
    --  lista piezas  
    PROCEDURE p_lista_piezas(   p_parametros IN CLOB, 
                                p_piezas     OUT gc_ref_cursor,
                                p_errores    OUT VARCHAR2
                            );
    --
    -- incluir danios a vehiculos      
    PROCEDURE p_graba_rotura_vehiculo(  p_parametros IN CLOB, 
                                        p_errores    OUT VARCHAR2
                                     );  
    --
    -- incluir accesorios a vehiculos      
    PROCEDURE p_graba_accesorio_vehiculo(  p_parametros IN CLOB, 
                                           p_errores    OUT VARCHAR2
                                        ); 
    --
    -- incluir documentos asociados a vehiculos      
    PROCEDURE p_graba_documento_vehiculo(  p_parametros IN CLOB, 
                                           p_errores    OUT VARCHAR2
                                        );     
    --
    --  lista control tecnico  
    PROCEDURE p_lista_ctrl_tecnico(     p_parametros IN CLOB, 
                                        p_ctrl_tec   OUT gc_ref_cursor,
                                        p_errores    OUT VARCHAR2
                                );                                                                                                                                 
    --  
    -- envio Respuesta
    PROCEDURE p_envio_respuesta(    p_parametros        IN CLOB, 
                                    p_errores           OUT VARCHAR2
                                );
    --
    --  lista Departamentos  
    PROCEDURE p_lista_dpto(     p_parametros    IN CLOB, 
                                p_departaemtno  OUT gc_ref_cursor,
                                p_errores       OUT VARCHAR2
                          );
    --       
    --  lista Municipios  
    PROCEDURE p_lista_mpio(     p_parametros    IN CLOB, 
                                p_mpio          OUT gc_ref_cursor,
                                p_errores       OUT VARCHAR2
                          );
    --       
    --  lista Marcas  
    PROCEDURE p_lista_marcas(   p_parametros    IN CLOB, 
                                p_marcas        OUT gc_ref_cursor,
                                p_errores       OUT VARCHAR2
                          );  
    --       
    --  lista Lineas  
    PROCEDURE p_lista_lineas(   p_parametros    IN CLOB, 
                                p_lineas        OUT gc_ref_cursor,
                                p_errores       OUT VARCHAR2
                          );  
    --       
    --  lista usos  
    PROCEDURE p_lista_usos(     p_parametros    IN CLOB, 
                                p_usos          OUT gc_ref_cursor,
                                p_errores       OUT VARCHAR2
                          ); 
    --       
    --  lista colores 
    PROCEDURE p_lista_colores(  p_parametros    IN CLOB, 
                                p_colores       OUT gc_ref_cursor,
                                p_errores       OUT VARCHAR2
                          );                                                                                                                    
    --                        
end em_k_ws_auto_inspeccion;
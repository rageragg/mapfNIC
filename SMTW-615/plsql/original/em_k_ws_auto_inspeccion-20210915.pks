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
        tipoFoto            VARCHAR2(128),
        byteFoto            CLOB
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
    -- salida de cotrizacion cliente
    TYPE typ_reg_cliente_cotizacion IS RECORD(
	    access_token        VARCHAR2(128),
	    usuario             VARCHAR2(128),
	    tip_usuario         VARCHAR2(128),
	    identificacion      VARCHAR2(128),
	    placa               VARCHAR2(128),
	    numeroCotizacion    VARCHAR2(128),
        poliza              VARCHAR2(128),
        txt_mensaje         VARCHAR2(512)
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
    -- registro de piezas
    TYPE typ_reg_prieza IS RECORD(
        nombrePieza     VARCHAR2(128)
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
    TYPE typ_tab_token IS TABLE OF typ_reg_token INDEX BY BINARY_INTEGER;
    TYPE typ_tab_cliente_cotizacion IS TABLE OF typ_reg_cliente_cotizacion;
    TYPE typ_tab_info_cotizacion IS TABLE OF typ_reg_info_cotizacion;
    TYPE typ_tab_reg_cotizacion IS TABLE OF typ_reg_cotizacion;
    TYPE typ_tab_reg_pieza IS TABLE OF typ_reg_prieza;
    TYPE typ_tab_reg_ctrl_tecnico IS TABLE OF typ_reg_ctrl_tecnico;
    TYPE typ_tab_reg_simple IS TABLE OF typ_reg_lista_simple;
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
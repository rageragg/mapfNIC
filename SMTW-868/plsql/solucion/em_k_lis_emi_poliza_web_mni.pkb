create or replace PACKAGE BODY em_k_lis_emi_poliza_web_mni IS

    /* -------------------- VERSION = 1.00 -------------------- */
    --
    /* -------------------- DESCRIPCION --------------------
    || Listados de Emison de Polizas WEB
    */ -----------------------------------------------------
    --
    /* -------------------- VERSION = 1.00 -------------------- */
    --
    /* -------------------- MODIFICACIONES -----------------
        || 2021/11/30 - CARRIERHOUSE v.1.00
        || Creacion del Paquete.
        || -------------------------------------------------
        || 2022/02/25 - CARRIERHOUSE - RGUERRA v.1.01
        ||  - Se elimina la colimna CIA 
        ||  - Se elimina el prefijo de tipo de documento en la columna CEDULA
        ||  - Se agregar columna del tipo de documento
        ||  - Crear una columna llamada RUC 
        ||  - De la columna Número de póliza quitar la descripción de la modalidad del principio
        ||  - Reemplazar la columna ramo por columna modalidad 
        ||  - Se debe colocar una columna con el tipo de persona
        ||  - Agregar columna con el tipo de vehículo
        ||  - Se crea la funcion pi_datos_variables para optimizar el codigo
    */
    --
    g_tab_columns               dc_k_xml_format_xls_mca.t_tab_columns;
    g_tab_caption               dc_k_xml_format_xls_mca.t_tab_caption;
    g_tab_toptitle              dc_k_xml_format_xls_mca.t_tab_toptitle;
    g_tab_conditional_formats   dc_k_xml_format_xls_mca.t_tab_conditionalformats;
    g_tab_custom_styles         dc_k_xml_format_xls_mca.t_tab_customstyles;
    --
    g_cod_cia       a2000030.cod_cia%TYPE := 4;
    g_fec_proceso   DATE;
    g_nom_listado   VARCHAR2(100);
    g_cod_error     NUMBER;
    g_cod_agt       a1001332.cod_agt%TYPE;
    --
    g_id_fichero    utl_file.file_type;
    --
    g_directorio    VARCHAR2(200) := trn_k_global.mspool_dir;
    g_msg_error     VARCHAR2(2000);
    --
    CURSOR c_trae_polizas IS
        SELECT a.cod_ramo,
               a.cod_mon,
               a.cod_agt,
               a.cod_nivel3,
               a.num_poliza,
               a.num_spto,
               a.num_apli,
               a.num_spto_apli,
               a.cod_sector,
               a.tip_spto,
               a.mca_spto_anulado,
               a.num_spto_anulado,
               a.tip_coaseguro,
               a.fec_efec_spto,
               a.fec_vcto_spto,
               a.fec_efec_poliza,
               a.fec_vcto_poliza,
               a.tip_docum,
               a.cod_docum,
               a.cod_fracc_pago,
               a.mca_spto_tmp,
               nvl(a.fec_autorizacion, fec_actu) fec_dia,
               a.cod_spto,
               a.sub_cod_spto,
               a.val_mca_int,
               a.fec_actu,
               a.num_poliza_grupo,
               a.tip_rea,
               a.cod_usr,
               a.tip_gestor,
               a.cod_gestor,
               a.num_poliza_anterior,
               a.fec_emision_spto,
               a.txt_motivo_spto,
               a.cod_canal3,
               a.num_presupuesto,
               a.num_renovaciones,
               a.cod_ejecutivo
          FROM a2000030 a
         WHERE a.cod_cia + 0 = g_cod_cia
           AND a.fec_emision_spto BETWEEN to_date('01' || to_char(g_fec_proceso, 'MMYYYY'), 'DDMMYYYY') AND
                                          last_day(g_fec_proceso)
           AND nvl(a.mca_provisional, 'N') = trn.NO
           AND a.num_poliza IN ( SELECT x.num_poliza
                                   FROM x2000001_WEB x
                                  WHERE x.cod_cia = a.cod_cia
                                    AND x.cod_ramo = a.cod_ramo
                                    AND x.cod_agt = a.cod_agt
                               )
           AND a.tip_spto = 'XX' -- nueva emision
           AND a.cod_agt  = g_cod_agt
         ORDER BY a.num_poliza, a.num_spto;
    --
    /*
            SELECT a.cod_ramo,
                a.cod_mon,
                a.cod_agt,
                a.cod_nivel3,
                a.num_poliza,
                a.num_spto,
                a.num_apli,
                a.num_spto_apli,
                a.cod_sector,
                a.tip_spto,
                a.mca_spto_anulado,
                a.num_spto_anulado,
                a.tip_coaseguro,
                a.fec_efec_spto,
                a.fec_vcto_spto,
                a.fec_efec_poliza,
                a.fec_vcto_poliza,
                a.tip_docum,
                a.cod_docum,
                a.cod_fracc_pago,
                a.mca_spto_tmp,
                nvl(a.fec_autorizacion, fec_actu) fec_dia,
                a.cod_spto,
                a.sub_cod_spto,
                a.val_mca_int,
                a.fec_actu,
                a.num_poliza_grupo,
                a.tip_rea,
                a.cod_usr,
                a.tip_gestor,
                a.cod_gestor,
                a.num_poliza_anterior,
                a.fec_emision_spto,
                a.txt_motivo_spto,
                a.cod_canal3,
                a.num_presupuesto,
                a.num_renovaciones,
                a.cod_ejecutivo
        FROM a2000030 a
        WHERE a.cod_cia + 0 = g_cod_cia
            AND a.fec_emision_spto BETWEEN
                to_date('01' || to_char(g_fec_proceso, 'MMYYYY'), 'DDMMYYYY') AND
                last_day(g_fec_proceso)
            AND nvl(a.mca_provisional, 'N') = 'N'
            AND a.cod_ramo = nvl(g_cod_ramo, cod_ramo)
            AND a.tip_spto = nvl(g_tip_spto, tip_spto)
            AND a.cod_usr = nvl(g_cod_usr, cod_usr)
            AND a.cod_mon = nvl(g_cod_mon, cod_mon)
            AND (a.tip_gestor = g_tip_gestor OR g_tip_gestor IS NULL)
            AND (a.cod_gestor = g_cod_gestor OR g_cod_gestor IS NULL)
            AND (a.num_poliza = g_num_poliza OR g_num_poliza IS NULL)
        ORDER BY a.num_poliza, a.num_spto;
    */
    --
    PROCEDURE p_abrir_fichero(p_nom_fichero VARCHAR2) IS
    BEGIN
        --
        g_id_fichero := dc_k_xml_format_xls_mca.f_crea_archivo( g_directorio,
                                                                p_nom_fichero,
                                                                g_tab_custom_styles
                                                              );
        --
    END p_abrir_fichero;
    --
    PROCEDURE p_cerrar_fichero IS
    BEGIN
        --
        dc_k_xml_format_xls_mca.p_cerrar_archivo(g_id_fichero);
        --
    END p_cerrar_fichero;
    --
    PROCEDURE p_lista(  p_cod_cia           a2000030.cod_cia%TYPE,
                        p_fec_proceso_desde DATE,
                        p_fec_proceso_hasta DATE,
                        p_fec_proceso       DATE,
                        p_cod_agt           a1001332.cod_agt%TYPE
                     ) IS
        --
        l_txt_linea   VARCHAR2(3000);
        l_cant_cuotas NUMBER := 0;
        --
        PROCEDURE pp_cabecera IS
        BEGIN
            --
            g_tab_toptitle(1).toptitle := 'MAPFRE | Nicaragua. Reporte de Polizas Emitidas en PORTAL WEB Desde: ' || 
                                            to_char(p_fec_proceso_desde, 'MMYYYY') ||
                                            ' Hasta: ' ||
                                            to_char(p_fec_proceso_hasta, 'DDMMYYYY') ||
                                            ' AGENTE: ' || p_cod_agt;
            --
            g_tab_caption(1).span := 13;
            --
            g_tab_caption(1).title := 'NUMEROPOLIZA';
            --
            -- ! Se elimina la columna CIA
            -- g_tab_caption(2).title := 'CIA';
            --
            g_tab_caption(2).title := 'NOMBRES';
            g_tab_caption(3).title := 'APELLIDOS';
            --
            -- ! Se agrega columna del tipo de documento
            g_tab_caption(4).title := 'TIP. DOC.';
            --
            g_tab_caption(5).title := 'CEDULA';
            --
            -- ! Se agrega columna RUC
            g_tab_caption(6).title := 'RUC';
            --
            -- ! Se debe colocar una columna con el tipo de persona
            g_tab_caption(7).title := 'TIP. PERSONA';
            --
            g_tab_caption(8).title := 'DIRECCION';
            g_tab_caption(9).title := 'TEL1';
            g_tab_caption(10).title := 'CELULAR';
            g_tab_caption(11).title := 'FEMISION';
            g_tab_caption(12).title := 'FDESDE';
            g_tab_caption(13).title := 'FHASTA';
            --
            -- ! Se sustituye  la columna de RAMO por Modalidad
            g_tab_caption(14).title := 'MODALIDAD';
            --
            g_tab_caption(15).title := 'MARCA';
            g_tab_caption(16).title := 'MODELO';
            g_tab_caption(17).title := 'AÑO';
            g_tab_caption(18).title := 'COLOR';
            g_tab_caption(19).title := 'PLACA';
            g_tab_caption(20).title := 'MOTOR';
            g_tab_caption(21).title := 'CHASIS';
            --
            -- ! Agregar columna con el tipo de vehículo
            g_tab_caption(22).title := 'TIP. VEHICULO';
            --
            g_tab_caption(23).title := 'SUMAASEGURADA';
            g_tab_caption(24).title := 'PNETA';
            g_tab_caption(25).title := 'PTOTAL';
            g_tab_caption(26).title := 'IDAGENTE';
            g_tab_caption(27).title := 'IDEJECUTIVO';
            --
            FOR reg IN 1 .. g_tab_caption.count LOOP
                g_tab_columns(reg).ancho := '150';
                g_tab_columns(reg).ancho_auto := TRUE;
            END LOOP;
            --
            FOR reg IN 1 .. g_tab_toptitle.count LOOP
                --
                g_tab_toptitle(reg).span := g_tab_caption.count;
                --
            END LOOP;
            g_tab_caption(1).toptitle := g_tab_toptitle;
            --
            dc_k_xml_format_xls_mca.p_nueva_hoja(g_id_fichero,
                                                'Polizas Emitidas WEB',
                                                g_tab_caption,
                                                g_tab_columns);
            --
        END pp_cabecera;
        --
        PROCEDURE pp_detalle IS
            --
            l_nom_asegurado       VARCHAR2(200);
            l_ape_asegurado       VARCHAR2(200);
            l_nom_domicilio1      VARCHAR2(500);
            l_telefono            a1001331.tlf_numero%TYPE;
            l_celular             a1001331.tlf_movil%TYPE;
            l_nom_agt             VARCHAR2(200);
            l_primera_vez         VARCHAR(1) := 'S';
            l_cod_modalidad       a2000020.cod_campo%TYPE;
            --
            -- ! Se cambia por la descripcion de la modalidad
            l_nom_modalidad       g2990004.nom_modalidad%TYPE;
            l_imp_prima_neta      a2990700.imp_recibo%TYPE;
            l_val_cambio          a2990700.val_cambio%TYPE;
            l_total_recibos_ct    NUMBER := 0;
            l_total_recibo_pend   NUMBER := 0;
            l_total_recibos       NUMBER := 0;
            l_imp_comis           NUMBER := 0;
            l_total_prima_neta    NUMBER := 0;
            l_cod_marca           a2000020.val_campo%TYPE;
            l_cod_modelo          a2000020.val_campo%TYPE;
            l_marca_vehiculo      VARCHAR2(100);
            l_modelo_vehiculo     VARCHAR2(100);
            l_anio_vehiculo       a2000020.val_campo%TYPE;
            l_cod_color           a2000020.cod_campo%TYPE;
            l_des_color           a2100800.nom_color%TYPE;
            l_num_placa           a2000020.val_campo%TYPE;
            l_des_motor           a2000020.val_campo%TYPE;
            l_des_chasis          a2000020.val_campo%TYPE;
            -- ! Se agrega tipo de vehiculo
            l_cod_tipo           a2000020.cod_campo%TYPE;
            l_des_tipo           a2100100.nom_tip_vehi%TYPE;
            --
            l_suma_aseg           VARCHAR2(100);
            --
            PROCEDURE p_trata_fechas(p_fecha IN DATE,
                                    p_mes   IN OUT VARCHAR2,
                                    p_anio  IN OUT VARCHAR2) IS
                --
                l_mes VARCHAR2(2);
                --
            BEGIN
                --
                l_mes := to_char(p_fecha, 'MM');
                --
                IF l_mes = '01' THEN
                p_mes := 'ENERO';
                ELSIF l_mes = '02' THEN
                p_mes := 'FEBRERO';
                ELSIF l_mes = '03' THEN
                p_mes := 'MARZO';
                ELSIF l_mes = '04' THEN
                p_mes := 'ABRIL';
                ELSIF l_mes = '05' THEN
                p_mes := 'MAYO';
                ELSIF l_mes = '06' THEN
                p_mes := 'JUNIO';
                ELSIF l_mes = '07' THEN
                p_mes := 'JULIO';
                ELSIF l_mes = '08' THEN
                p_mes := 'AGOSTO';
                ELSIF l_mes = '09' THEN
                p_mes := 'SEPTIEMBRE';
                ELSIF l_mes = '10' THEN
                p_mes := 'OCTUBRE';
                ELSIF l_mes = '11' THEN
                p_mes := 'NOVIEMBRE';
                ELSIF l_mes = '12' THEN
                p_mes := 'DICIEMBRE';
                END IF;
                --
                p_anio := to_char(p_fecha, 'YYYY');
                --
            END p_trata_fechas;
            --
            -- datos variables
            FUNCTION pi_datos_variables(    p_reg          c_trae_polizas%ROWTYPE,
                                            p_cod_campo    a2000020.cod_campo%TYPE
                                       ) RETURN VARCHAR2 IS 
            BEGIN 
                --
                em_k_a2000020.p_lee_vigente(    g_cod_cia,
                                                p_reg.num_poliza,
                                                trn.cero,
                                                trn.uno,
                                                trn.uno,
                                                p_cod_campo,
                                                p_reg.cod_ramo
                                           );
                --                           
                RETURN em_k_a2000020.f_val_campo;
                --
                EXCEPTION
                    WHEN OTHERS THEN
                        RETURN NULL;
                --        
            END pi_datos_variables; 
            --
        BEGIN
            --
            l_txt_linea        := '';
            l_total_prima_neta := 0;
            --
            FOR reg IN c_trae_polizas LOOP
                --
                l_cant_cuotas         := 0;
                l_val_cambio          := 1;
                l_imp_prima_neta      := 0;
                l_total_recibos_ct    := 0;
                l_total_recibo_pend   := 0;
                l_total_recibos       := 0;
                l_imp_comis           := 0;
                l_marca_vehiculo      := NULL;
                l_modelo_vehiculo     := NULL;
                l_anio_vehiculo       := NULL;
                l_suma_aseg           := NULL;
                --
                --Crea nueva fila
                IF l_primera_vez = 'N' THEN
                    dc_k_xml_format_xls_mca.p_nueva_fila(g_id_fichero);
                END IF;
                --
                --
                l_cod_modalidad := NULL;
                l_nom_modalidad := NULL;
                --
                -- Modalidad
                BEGIN
                    --
                    em_k_a2000020.p_lee(    g_cod_cia,
                                            reg.num_poliza,
                                            0, --reg.num_spto,
                                            reg.num_apli,
                                            reg.num_spto_apli,
                                            1, -- num_riesgo OJO
                                            1,
                                            'COD_MODALIDAD',
                                            reg.cod_ramo
                                       );
                    --
                    l_cod_modalidad := em_k_a2000020.f_val_campo;
                    --
                    EXCEPTION
                        WHEN OTHERS THEN
                            l_nom_modalidad := NULL;
                END;
                --
                IF l_cod_modalidad IS NOT NULL THEN
                    --
                    BEGIN
                        em_k_g2990004.p_lee(    g_cod_cia,
                                                l_cod_modalidad,
                                                reg.fec_vcto_poliza
                                           );
                        -- ! Se modifica por la descripcion de la modalidad                   
                        l_nom_modalidad := em_k_g2990004.f_nom_modalidad;
                        --
                    EXCEPTION
                        WHEN OTHERS THEN
                        ptraza('modalidad',
                                'a',
                                'Error al obtener modalidad l_cod_modalidad ' ||
                                l_cod_modalidad || ' poiza ' || reg.num_poliza ||
                                ' reg.fec_vcto_poliza ' || reg.fec_vcto_poliza ||
                                ' error ' || sqlerrm);
                        l_nom_modalidad := ' ';
                    END;
                    --
                ELSE
                    --
                    dc_k_a1001800.p_lee(g_cod_cia, reg.cod_ramo);
                    l_nom_modalidad := dc_k_a1001800.f_abr_ramo;
                    --
                END IF;
                --
                -- numero de poliza y modalidad
                -- ! Se quita el prefijo de modalidad en la columna numero de poliza (l_nom_modalidad || '-' ||)
                dc_k_xml_format_xls_mca.p_escribe_datos(    g_id_fichero,
                                                            to_number(reg.num_poliza),
                                                            dc_k_xml_format_xls_mca.g_integer
                                                       );
                --
                l_primera_vez := 'N';
                --
                -- ! Se elimina la columna CIA
                -- dc_k_xml_format_xls_mca.p_escribe_datos( g_id_fichero, 'MAPFRE' );
                --
                -- nombre del asegurado
                BEGIN
                    --
                    dc_k_a1001399.p_lee(g_cod_cia, reg.tip_docum, reg.cod_docum);
                    --
                    l_nom_asegurado := upper(dc_k_a1001399.f_nom_tercero);
                    --
                    l_ape_asegurado := upper(   dc_k_a1001399.f_ape1_tercero || ' ' ||
                                                dc_k_a1001399.f_ape2_tercero
                                            );
                    --
                    EXCEPTION
                        WHEN OTHERS THEN
                            --
                            l_nom_asegurado := '';
                            l_ape_asegurado := '';
                            --
                END;
                --
                dc_k_xml_format_xls_mca.p_escribe_datos( g_id_fichero, l_nom_asegurado );
                dc_k_xml_format_xls_mca.p_escribe_datos( g_id_fichero, l_ape_asegurado );
                --
                -- ! Se agrega columna Tipo de Documento 
                -- ! Se elimina el prefijo "TIPO DOCUMENTO" para dif. RUC, reg.tip_docum || '-' || reg.cod_documX
                IF reg.tip_docum = 'RUC' THEN
                    dc_k_xml_format_xls_mca.p_escribe_datos(    g_id_fichero,
                                                                ''
                                                           );
                    dc_k_xml_format_xls_mca.p_escribe_datos(    g_id_fichero,
                                                                ''
                                                           );   
                    -- ! Se agrega la columna RUC
                    dc_k_xml_format_xls_mca.p_escribe_datos(    g_id_fichero,
                                                                reg.cod_docum
                                                           );  
                    -- ! Se debe colocar una columna con el tipo de persona
                    dc_k_xml_format_xls_mca.p_escribe_datos(    g_id_fichero,
                                                                'JURIDICO'
                                                           );
                ELSE                                           
                    dc_k_xml_format_xls_mca.p_escribe_datos(    g_id_fichero,
                                                                reg.tip_docum
                                                        );
                    dc_k_xml_format_xls_mca.p_escribe_datos(    g_id_fichero,
                                                                reg.cod_docum
                                                        );
                    dc_k_xml_format_xls_mca.p_escribe_datos(    g_id_fichero,
                                                                ''
                                                           ); 
                    -- ! Se debe colocar una columna con el tipo de persona
                    dc_k_xml_format_xls_mca.p_escribe_datos(    g_id_fichero,
                                                                'NATURAL'
                                                           );                                                                                                               
                END IF;                                         
                --
                BEGIN
                    --
                    dc_k_a1001331.p_lee(g_cod_cia, reg.tip_docum, reg.cod_docum);
                    l_nom_domicilio1 := dc_k_a1001331.f_nom_domicilio1 || ' ' ||
                                        dc_k_a1001331.f_nom_domicilio2 || ' ' ||
                                        dc_k_a1001331.f_nom_domicilio3;
                    l_telefono       := dc_k_a1001331.f_tlf_numero;
                    l_celular        := dc_k_a1001331.f_tlf_movil;
                    --
                    EXCEPTION
                        WHEN OTHERS THEN
                            l_telefono       := '';
                            l_nom_domicilio1 := '';
                            l_celular        := '';
                            --
                END;
                --
                dc_k_xml_format_xls_mca.p_escribe_datos( g_id_fichero, l_nom_domicilio1 );
                dc_k_xml_format_xls_mca.p_escribe_datos( g_id_fichero, l_telefono );
                dc_k_xml_format_xls_mca.p_escribe_datos( g_id_fichero, l_celular );
                dc_k_xml_format_xls_mca.p_escribe_datos( g_id_fichero, to_char(reg.fec_emision_spto, 'dd/mm/yyyy') );
                dc_k_xml_format_xls_mca.p_escribe_datos( g_id_fichero, to_char(reg.fec_efec_spto, 'dd/mm/yyyy') );
                dc_k_xml_format_xls_mca.p_escribe_datos( g_id_fichero, to_char(reg.fec_vcto_spto, 'dd/mm/yyyy') );
                --
                -- ! Se sustituye el valor del ramo a modalidad, (dc_k_a1001800.f_nom_ramo)
                -- dc_k_a1001800.p_lee( g_cod_cia, reg.cod_ramo) ;
                --
                dc_k_xml_format_xls_mca.p_escribe_datos( g_id_fichero, l_nom_modalidad );
                --
                -- Marca Vehiculo
                BEGIN
                    --
                    -- * Se optimiza el codigo
                    l_cod_marca := pi_datos_variables( p_reg => reg, p_cod_campo => 'COD_MARCA' );
                    --
                    IF l_cod_marca IS NOT NULL THEN
                        em_k_a2100400.p_lee( g_cod_cia, l_cod_marca, TRUNC(SYSDATE) );
                        l_marca_vehiculo := em_k_a2100400.f_nom_marca;
                    END IF;
                    --
                    EXCEPTION
                        WHEN OTHERS THEN
                            l_marca_vehiculo := ' ';
                    --        
                END;
                --
                dc_k_xml_format_xls_mca.p_escribe_datos(g_id_fichero, l_marca_vehiculo);
                --
                -- Modelo Vehiculo
                BEGIN
                    --
                    -- * Se optimiza el codigo
                    l_cod_modelo := pi_datos_variables( p_reg => reg, p_cod_campo => 'COD_MODELO' );
                    --
                    IF l_cod_modelo IS NOT NULL THEN
                        --
                        SELECT a.nom_modelo
                          INTO l_modelo_vehiculo
                          FROM a2100410 a
                         WHERE a.cod_cia     = g_cod_cia
                           AND a.cod_marca   = l_cod_marca
                           AND a.cod_modelo  = l_cod_modelo
                           AND a.fec_validez = ( SELECT MAX(b.fec_validez)
                                                   FROM a2100410 b
                                                  WHERE b.cod_cia = g_cod_cia
                                                    AND b.cod_marca = a.cod_marca
                                                    AND b.cod_modelo = a.cod_modelo
                                               );
                        --
                    END IF;
                    --
                    EXCEPTION
                        WHEN OTHERS THEN
                            l_modelo_vehiculo := ' ';
                    --        
                END;
                --
                dc_k_xml_format_xls_mca.p_escribe_datos(g_id_fichero, l_modelo_vehiculo);
                --
                -- Anio Vehiculo
                -- * Se optimiza el codigo
                l_anio_vehiculo := pi_datos_variables( p_reg => reg, p_cod_campo => 'COD_ANO' );
                --  
                dc_k_xml_format_xls_mca.p_escribe_datos(g_id_fichero, l_anio_vehiculo);
                --
                -- COLOR
                BEGIN
                    --
                    -- * Se optimiza el codigo
                    l_cod_color := pi_datos_variables( p_reg => reg, p_cod_campo => 'COD_COLOR' );
                    --
                    IF l_cod_color IS NOT NULL THEN
                        --
                        SELECT a.nom_color
                          INTO l_des_color
                          FROM a2100800 a
                         WHERE a.cod_color = l_cod_color;
                        --
                    END IF;
                    --
                    EXCEPTION
                        WHEN OTHERS THEN
                            l_des_color := ' ';
                    --        
                END;
                --  
                dc_k_xml_format_xls_mca.p_escribe_datos(g_id_fichero, l_des_color );
                --
                -- Placa
                l_num_placa := pi_datos_variables( p_reg => reg, p_cod_campo => 'NUM_PLACA' );
                --
                dc_k_xml_format_xls_mca.p_escribe_datos(g_id_fichero, l_num_placa);
                --
                -- Motor
                l_des_motor := pi_datos_variables( p_reg => reg, p_cod_campo => 'DES_MOTOR' );
                --
                dc_k_xml_format_xls_mca.p_escribe_datos(g_id_fichero, l_des_motor);
                --
                -- Chasis
                l_des_chasis := pi_datos_variables( p_reg => reg, p_cod_campo => 'DES_CHASIS' );
                --
                dc_k_xml_format_xls_mca.p_escribe_datos(g_id_fichero, l_des_chasis);
                --
                -- Tipo vehiculo
                BEGIN
                    --
                    -- * Se optimiza el codigo
                    l_cod_tipo := pi_datos_variables( p_reg => reg, p_cod_campo => 'COD_TIPO' );
                    --
                    IF l_cod_tipo IS NOT NULL THEN
                        --
                        SELECT a.nom_tip_vehi
                          INTO l_des_tipo
                          FROM a2100100 a
                         WHERE a.cod_cia      = g_cod_cia
                           AND a.cod_tip_vehi = l_cod_tipo
                           AND fec_validez = ( SELECT max( b.fec_validez )
                                                 FROM a2100100 b
                                                WHERE b.cod_cia         = g_cod_cia 
                                                  AND b.cod_tip_vehi    = l_cod_tipo
                                             );
                        --
                    END IF;
                    --
                    EXCEPTION
                        WHEN OTHERS THEN
                            l_des_tipo := ' ';
                    --        
                END;
                --
                dc_k_xml_format_xls_mca.p_escribe_datos(g_id_fichero, l_des_tipo);
                --
                -- Suma Asegurada Spto
                BEGIN
                SELECT to_char(sum(nvl(suma_aseg, 0)), '9999999.99')
                    INTO l_suma_aseg
                    FROM a2000040
                WHERE cod_cia = g_cod_cia
                    AND num_poliza = reg.num_poliza
                    AND num_spto = reg.num_spto;
                --
                EXCEPTION
                WHEN OTHERS THEN
                    l_suma_aseg := ' ';
                END;
                --
                dc_k_xml_format_xls_mca.p_escribe_datos(g_id_fichero, l_suma_aseg);
                --
                -- prima neta
                BEGIN
                --
                l_imp_prima_neta := 0;
                SELECT SUM(NVL(x.imp_spto, 0))
                    INTO l_imp_prima_neta
                    FROM (SELECT cod_cob, SUM(nvl(imp_spto, 0)) imp_spto
                            FROM a2100170
                        WHERE cod_cia = g_cod_cia
                            AND num_poliza = reg.num_poliza
                            AND num_spto = reg.num_spto
                            AND num_apli = reg.num_apli
                            AND num_spto_apli = reg.num_spto_apli
                            AND cod_ramo = reg.cod_ramo
                            AND cod_eco IN (1, 4, 5, 8)
                        GROUP BY cod_cob) x;
                --
                EXCEPTION
                WHEN OTHERS THEN
                    --
                    l_imp_prima_neta := 0;
                    --
                END;
                --
                l_total_prima_neta := l_total_prima_neta + nvl(l_imp_prima_neta, 0);
                --
                dc_k_xml_format_xls_mca.p_escribe_datos(g_id_fichero,
                                                        nvl(l_imp_prima_neta, 0),
                                                        dc_k_xml_format_xls_mca.g_number_decimal);
                -- total a pagar
                BEGIN
                SELECT SUM(a.imp_recibo)
                    INTO l_total_recibos
                    FROM a2990700 a
                WHERE a.cod_cia = g_cod_cia
                    AND a.num_poliza = reg.num_poliza
                    AND a.num_spto = reg.num_spto
                    AND a.num_apli = reg.num_apli
                    AND a.num_spto_apli = reg.num_spto_apli
                    AND a.num_recibo > 0;
                --
                EXCEPTION
                WHEN OTHERS THEN
                    l_total_recibos := 0;
                END;
                --
                dc_k_xml_format_xls_mca.p_escribe_datos(g_id_fichero,
                                                        nvl(l_total_recibos, 0),
                                                        dc_k_xml_format_xls_mca.g_number_decimal);
                --
                -- Agente
                /*
                    BEGIN
                    --
                    l_nom_agt := ' ';
                    dc_k_a1001332.p_lee(g_cod_cia, reg.cod_agt, trunc(SYSDATE));
                    dc_k_a1001399.p_lee(g_cod_cia,
                                        dc_k_a1001332.f_tip_docum,
                                        dc_k_a1001332.f_cod_docum);
                    --
                    l_nom_agt := reg.cod_agt || '-' ||
                                upper(dc_k_a1001399.f_nom_tercero || ' ' ||
                                        dc_k_a1001399.f_ape1_tercero || ' ' ||
                                        dc_k_a1001399.f_ape2_tercero);
                    --
                    EXCEPTION
                    WHEN OTHERS THEN
                        --
                        l_nom_agt := '';
                        --
                    END;
                */
                --
                dc_k_xml_format_xls_mca.p_escribe_datos(g_id_fichero, reg.cod_agt);--l_nom_agt);
                dc_k_xml_format_xls_mca.p_escribe_datos(g_id_fichero, ' '); -- idejecutivo??
                --     
            END LOOP;
            --
            --Colocar Auto Filtro
            g_tab_conditional_formats(1).range := 'R4C4';
            g_tab_conditional_formats(1).qualifier := 'Greater';
            g_tab_conditional_formats(1).value1 := '0';
            g_tab_conditional_formats(1).value2 := NULL;
            --Se cierra la Hoja de Excel
            dc_k_xml_format_xls_mca.p_cerrar_hoja(g_id_fichero,
                                                    1,
                                                    0,
                                                    g_tab_caption,
                                                    TRUE,
                                                    g_tab_conditional_formats);
            --
        END pp_detalle;
        --
        PROCEDURE pp_proceso IS
        BEGIN
            --
            pp_cabecera;
            --
            pp_detalle;
            --
        END pp_proceso;
        --
    BEGIN
        --
        trn_k_global.asigna('mca_ter_tar', 'N');
        --
        g_cod_cia     := p_cod_cia;
        g_fec_proceso := p_fec_proceso;
        g_nom_listado := 'em_k_lis_emi_poliza_web_' || p_cod_agt || '.' ||
                        trn_k_lis.ext_mspool || '.xml';
        trn_k_global.asigna('JBNOM_LISTADO', g_nom_listado);
        --
        p_abrir_fichero(g_nom_listado);
        --
        pp_proceso;
        --
        p_cerrar_fichero;
        --
        trn_k_global.asigna('mca_ter_tar', 'S');
        --
    END p_lista;
    --
    PROCEDURE p_lista_con_globales IS
    BEGIN
        --
        g_cod_agt     := trn_k_global.ref_f_global('JBCOD_AGT');
        g_fec_proceso := last_day(to_date(trn_k_global.devuelve('JBFEC_HASTA'), 'ddmmyyyy'));
        --
        p_lista(    p_cod_cia           =>  trn_k_global.devuelve('JBCOD_CIA'),
                    p_fec_proceso_desde =>  to_date(trn_k_global.devuelve('JBFEC_DESDE'), 'ddmmyyyy'),
                    p_fec_proceso_hasta =>  to_date(trn_k_global.devuelve('JBFEC_HASTA'), 'ddmmyyyy'),
                    p_fec_proceso       => g_fec_proceso,
                    p_cod_agt           => g_cod_agt
               );
        --
        EXCEPTION
            WHEN OTHERS THEN
                --
                g_cod_error := -20002;
                g_msg_error := '<p_lista_con_globales> ' || SQLERRM;
                --p_cerrar_fichero;
                --
                raise_application_error(g_cod_error, g_msg_error);
        --
    END p_lista_con_globales;
    --
END em_k_lis_emi_poliza_web_mni;

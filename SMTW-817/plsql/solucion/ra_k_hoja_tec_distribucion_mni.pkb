create or replace PACKAGE BODY ra_k_hoja_tec_distribucion_mni
AS
    --
    /* -------------------- VERSION = 1.01 -------------------- */
    --
    /* -------------------- DESCRIPCION -----------------------
    || Paquete para la manipulacion de la hoja tecnica de 
    || distribucion reaseguro de una poliza determinada
    */ --------------------------------------------------------
    --
    /* -------------------- MODIFICACIONES --------------------
    || 2021/04/21  - CARRIERHOUSE, RGUERRA - v 1.00
    || Creacion del Package
    || 2021/10/22  - CARRIERHOUSE, RGUERRA - v 1.01
    || Se modifica el cursor c_mvtos para filtrar por el spto
    || que elija el usuario
    */ --------------------------------------------------------
    --
    -- variables globales
    g_cod_cia           a2501600.cod_cia %TYPE;
    g_num_poliza        a2501600.num_poliza %TYPE;
    g_num_spto          a2501600.num_spto %TYPE;
    g_num_apli          a2501600.num_apli %TYPE         := 0;
    g_num_spto_apli     a2501600.num_spto_apli %TYPE    := 0;
    g_num_riesgo        a2501600.num_riesgo %TYPE;
    g_nom_riesgo        a2000031.nom_riesgo %TYPE;
    g_cod_secc_reas     a2501000.cod_secc_reas%TYPE;
    g_nom_secc_reas     a2500120.nom_secc_reas%TYPE;
    g_num_mov           a2501000.num_mov %TYPE;
    g_cod_usr           g1010120.cod_usr %TYPE;
    g_cod_idioma        g1010010.cod_idioma %TYPE;
    g_cod_mon_iso       a1000400.cod_mon_iso %TYPE;
    g_num_decimales     a1000400.num_decimales%TYPE;
    g_cod_ramo          a1001800.cod_ramo %TYPE;
    g_nom_ramo          a1001800.nom_ramo %TYPE;
    g_fec_mov           a2501600.fec_mov %TYPE;
    g_fec_efec          a2501600.fec_efec %TYPE;
    g_fec_vcto          a2501600.fec_vcto %TYPE;
    g_num_periodo       a2501000.num_periodo %TYPE;
    --
    -- se modifica para que tome el ultimo suplemento del riesgo valido
    -- cursores
    CURSOR c_mvtos IS
        SELECT DISTINCT a.num_riesgo, a.num_mov, a.cod_secc_reas, a.num_spto
          FROM a2501600 a
         WHERE a.cod_cia       = g_cod_cia
           AND a.num_poliza    = g_num_poliza
           AND a.num_spto      = ( SELECT max( c.num_spto ) 
                                    FROM a2000031 c
                                   WHERE c.cod_cia     = a.cod_cia
                                     AND c.num_poliza  = a.num_poliza
                                     AND c.num_riesgo  = a.num_riesgo
                                     AND c.mca_vigente = trn.SI
                                     AND c.mca_baja_riesgo = trn.NO
                                     AND c.num_spto = nvl( g_num_spto, c.num_spto )
                                 )
           AND a.num_apli      = g_num_apli
           AND a.num_spto_apli = g_num_spto_apli
           AND a.num_riesgo    = DECODE(g_num_riesgo, em.NUM_RIESGO_GEN, num_riesgo, g_num_riesgo)
         ORDER BY num_mov;
    --
    -- tablas pl/sql
    g_tabla_lista_detalle tab_lista_detalle := tab_lista_detalle();
    --
    -- recumeracion y establecimiento de los parametros globales
    PROCEDURE p_init_parametros IS 
    BEGIN 
        --
        g_cod_usr    := trn_k_global.ref_f_global('COD_USR');
        g_cod_idioma := trn_k_global.ref_f_global('COD_IDIOMA');
        --
        g_cod_cia    := trn_k_global.ref_f_global('JBCOD_CIA');
        g_num_poliza := trn_k_global.ref_f_global('JBNUM_POLIZA');
        g_num_spto   := trn_k_global.ref_f_global('JBNUM_SPTO');
		g_num_riesgo := trn_k_global.ref_f_global('JBNUM_RIESGO');
        --
        IF g_num_riesgo IS NULL THEN
            g_num_riesgo := em.NUM_RIESGO_GEN;
        END IF;
        --
        -- globales para los procesos a los que se dependen
        trn_k_global.asigna('COD_CIA', g_cod_cia);
        trn_k_global.asigna('COD_USR', g_cod_usr);
        trn_k_global.asigna('COD_IDIOMA', g_cod_idioma);
        trn_k_global.asigna('c_externo', 'M');
        trn_k_global.asigna('c_consulta', 'S');
        trn_k_global.asigna('c_fecha_consulta', to_char(sysdate, 'ddmmyyyy'));
        trn_k_global.asigna('c_num_poliza', g_num_poliza );
        trn_k_global.asigna('c_num_spto', g_num_spto);
        trn_k_global.asigna('c_num_apli', g_num_apli);
        trn_k_global.asigna('c_num_spto_apli', g_num_spto_apli);
        --
    END p_init_parametros;
    --
    -- inicializa las variables
    PROCEDURE p_init_proceso IS 
    BEGIN 
        --
        g_tabla_lista_detalle.delete;
        --
        g_cod_cia       := NULL;
        g_num_poliza    := NULL;
        g_num_spto      := NULL;
        g_num_apli      := 0;
        g_num_spto_apli := 0;
        g_num_riesgo    := NULL;
        --
    END p_init_proceso;
    --
    -- se establecen las globales segun sea el caso
    PROCEDURE p_establecer_globales IS 
    BEGIN 
        --
        trn_k_global.asigna('c_num_riesgo', g_num_riesgo);
        trn_k_global.asigna('c_num_periodo', g_num_periodo);
        trn_k_global.asigna('c_num_mov', g_num_mov);
        trn_k_global.asigna('c_cod_secc_reas', g_cod_secc_reas );  
        trn_k_global.asigna('c_num_spto', g_num_spto);
        -- 
    END p_establecer_globales; 
    --
    -- insertar en tabla pl/sql
    PROCEDURE p_inserta_detalle( p_registro typ_rec_detalle ) IS 
    BEGIN 
        --
        -- insertamos en la tabla pl/sql
        g_tabla_lista_detalle.extend;
        g_tabla_lista_detalle(g_tabla_lista_detalle.count) := p_registro;
        --
    END p_inserta_detalle;
    --
    -- calculo de Impuesto
    PROCEDURE p_calcula_impuesto( p_regip_registro IN OUT typ_rec_detalle ) IS 
        --
        l_cod_impto               g2500000.cod_imptos_munic %TYPE;
        l_pct_impto               a1001000.pct_impto %TYPE;
        l_imp_impto               a2501500.imp_prima %TYPE;
        l_pct_impto_rea           a1001000.pct_impto %TYPE;
        l_cod_impto_rea           g2500000.cod_imptos_dgs %TYPE;
        --
    BEGIN 
        -- 
        -- seleccionamos el codigo del impuesto de la seccion
        ra_k_a2500120.p_lee( g_cod_cia, p_regip_registro.cod_secc_reas );
        l_cod_impto := ra_k_a2500120.f_cod_impto;
        p_regip_registro.pct_impuesto := 0;
        --
        IF l_cod_impto IS NOT NULL THEN
            gc_k_a1001000_trn.p_lee( g_cod_cia, l_cod_impto, p_regip_registro.fec_mov );
            p_regip_registro.pct_impuesto := gc_k_a1001000_trn.f_pct_impto;
        ELSE
            --
            -- impuestos municipales
            l_cod_impto := dc_f_cod_imptos_munic(g_cod_cia);
            -- 
            IF l_cod_impto IS NOT NULL THEN
                l_pct_impto := dc_f_pct_impto(g_cod_cia, l_cod_impto, p_regip_registro.fec_efec);
                p_regip_registro.pct_impuesto := l_pct_impto;
            ELSE
                l_pct_impto                     := trn.CERO;
                p_regip_registro.pct_impuesto   := 0;
            END IF;   
            --
            -- impuesto de reaseguro
            ra_k_g2500000.p_lee( p_cod_cia => g_cod_cia );
            --
            l_cod_impto_rea := ra_k_g2500000.f_cod_imptos_dgs;
            --
            IF l_cod_impto_rea IS NOT NULL THEN
                l_pct_impto_rea                 := dc_f_pct_impto(g_cod_cia, l_cod_impto_rea, p_regip_registro.fec_vcto);
                p_regip_registro.pct_impuesto   := p_regip_registro.pct_impuesto + l_pct_impto_rea;
            ELSE
                l_pct_impto_rea := trn.CERO;
            END IF;
            --
        END IF;
        --
        p_regip_registro.imp_impuesto := round( nvl(p_regip_registro.imp_prima,0) * 
                                                nvl(p_regip_registro.pct_impuesto,0)  / 100, 5
                                              );
        --
    END p_calcula_impuesto;
    --
    -- lista los detalles del reaseguro que una poliza tiene asociada
    FUNCTION f_lista_detalle RETURN tab_lista_detalle PIPELINED IS
    BEGIN
        --
        FOR j IN 1 .. g_tabla_lista_detalle.COUNT LOOP
            --
            PIPE ROW(g_tabla_lista_detalle(j));
            --
        END LOOP;
        --
        RETURN;
        --
    END f_lista_detalle;
    --
    -- activa el paquete del reaseguro
    PROCEDURE p_activa_reaseguro IS
        --
        l_cod_ramo      a1001800.cod_ramo %TYPE;
        l_nom_ramo      a1001800.nom_ramo %TYPE;
        l_cod_mon_iso   a1000400.cod_mon_iso %TYPE;
        l_num_decimales a1000400.num_decimales%TYPE;
        l_num_poliza    a2501600.num_poliza %TYPE;
        l_num_spto      a2501600.num_spto %TYPE;
        l_num_apli      a2501600.num_apli %TYPE;
        l_num_spto_apli a2501600.num_spto_apli%TYPE;
        l_num_riesgo    a2501600.num_riesgo %TYPE;
        l_num_periodo   a2501000.num_periodo %TYPE;
        l_cambia_poliza VARCHAR2(1);
        l_cod_secc_reas a2501600.cod_secc_reas%TYPE;
        l_nom_secc_reas a2500120.nom_secc_reas%TYPE;
        l_nom_riesgo    a2000031.nom_riesgo %TYPE;
        l_num_mov       a2501600.num_mov %TYPE;
        l_fec_mov       a2501600.fec_mov %TYPE;
        l_fec_efec      a2501600.fec_efec %TYPE;
        l_fec_vcto      a2501600.fec_vcto %TYPE;
        --
    BEGIN 
        --
        ra_k_ac250001.p_inicio( l_cod_ramo, l_nom_ramo,
                                l_cod_mon_iso, l_num_decimales,
                                l_num_poliza, l_num_spto, l_num_apli, l_num_spto_apli, l_num_riesgo,
                                l_num_periodo, l_cambia_poliza, 
                                l_cod_secc_reas, l_nom_secc_reas, l_nom_riesgo,
                                l_num_mov, l_fec_mov, l_fec_efec, l_fec_vcto      
                              );
        --     
        -- asignamos a las globales
        g_cod_ramo      := l_cod_ramo;
        g_nom_ramo      := l_nom_ramo;
        g_cod_mon_iso   := l_cod_mon_iso;
        g_num_decimales := l_num_decimales;  
        g_num_periodo   := l_num_periodo; 
        g_nom_riesgo    := l_nom_riesgo;
        g_nom_secc_reas := l_nom_secc_reas;   
        g_fec_mov       := l_fec_mov;
        g_fec_efec      := l_fec_efec; 
        g_fec_vcto      := l_fec_vcto; 
        --
        trn_k_global.asigna ( 'c_cod_ramo', g_cod_ramo );
        --
    END p_activa_reaseguro;
    -- 
    -- devuelve el detalle del contrato para la distribucion
    PROCEDURE p_detalle_contrato( p_registro typ_rec_detalle  ) IS
        --
        l_cod_cia_rea           a2500150.cod_cia_rea%TYPE;
        l_nom_cia_rea           v1001390.nom_completo%TYPE;
        l_cod_broker            a2500150.cod_broker%TYPE;
        l_nom_broker            v1001390.nom_completo%TYPE;
        l_pct_participacion     a2500150.pct_participacion%TYPE;
        l_cap_cedido            a2501500.cap_cedido%TYPE;
        l_cap_cedido_spto       a2501500.cap_cedido_spto%TYPE;
        l_imp_prima             a2501500.imp_prima%TYPE;
        l_imp_prima_spto        a2501500.imp_prima_spto%TYPE;
        l_imp_prima_com         a2501500.imp_prima%TYPE;
        l_imp_prima_spto_com    a2501500.imp_prima_spto%TYPE;
        --
        l_cod_grupo         a1002080.cod_grupo %TYPE;
        l_nom_grupo         a2500310.nom_grupo %TYPE;
        l_imp_comision      a2501500.imp_prima_spto %TYPE;
        l_imp_comision_spto a2501500.com_facul_spto %TYPE;
        l_pct_comision      a2501500.pct_participacion%TYPE;
        --
        l_registro           typ_rec_detalle;
        --
    BEGIN 
        --
        l_registro          := p_registro;
        l_registro.k_origen := '3';  -- Contrato
        --
        ra_k_ac250001.p_query_reaseg_cont(  g_cod_cia, 
                                            p_registro.cod_contrato, 
                                            p_registro.cap_cedido, 
                                            p_registro.cap_cedido_spto, 
                                            p_registro.imp_prima, 
                                            p_registro.imp_prima_spto  
                                        );
        --
        LOOP
            --
            ra_k_ac250001.p_devuelve_reaseg_cont(   l_cod_cia_rea,
                                                    l_nom_cia_rea,
                                                    l_cod_broker,
                                                    l_nom_broker,
                                                    l_pct_participacion,
                                                    l_cap_cedido,
                                                    l_cap_cedido_spto,
                                                    l_imp_prima,
                                                    l_imp_prima_spto
                                                );
            --
            exit when l_cod_cia_rea is null;
            --
            -- asignamos los valores al registro detalle para inserta en table pl/sql
            l_registro.cod_cia_rea          := l_cod_cia_rea;
            l_registro.nom_cia_rea          := l_nom_cia_rea;
            l_registro.cod_broker           := l_cod_broker;
            l_registro.nom_broker           := l_nom_broker;
            l_registro.pct_participacion    := l_pct_participacion;
            l_registro.cap_cedido           := l_cap_cedido;
            l_registro.cap_cedido_spto      := l_cap_cedido_spto;
            l_registro.imp_prima            := l_imp_prima;
            l_registro.imp_prima_spto       := l_imp_prima_spto;
            --
            l_registro.num_riesgo          := g_num_riesgo;
            l_registro.nom_riesgo          := g_nom_riesgo;
            l_registro.num_mov             := g_num_mov;
            l_registro.fec_mov             := g_fec_mov;
            l_registro.fec_efec            := g_fec_efec;
            l_registro.fec_vcto            := g_fec_vcto; 
            l_registro.cod_secc_reas       := g_cod_secc_reas;
            l_registro.nom_secc_reas       := g_nom_secc_reas;
            l_registro.imp_prima_ret       := 0;
            l_registro.imp_prima_ced       := 0;
            l_registro.imp_prima_spto_ret  := 0;
            l_registro.imp_prima_spto_ced  := 0;
            l_registro.pct_ajuste          := 0;
            l_registro.prima_ajuste        := 0;
            l_registro.prima_ajuste_spto   := 0;
            --
            l_registro.ict_comision        := 0;
            l_registro.ict_comision_spto   := 0;
            l_registro.pct_comision        := 0;
            --
            l_registro.imp_prima_net       := 0;
            l_registro.imp_prima_spto_net  := 0;
            --
            p_inserta_detalle( l_registro );
            --
            BEGIN
                --
                ra_k_ac250001.p_query_com_grupo_cont(   g_cod_cia,
                                                        l_registro.cod_contrato,
                                                        l_registro.cod_cia_rea,
                                                        l_registro.cod_broker,
                                                        p_registro.imp_prima, 
                                                        p_registro.imp_prima_spto,  
                                                        l_pct_participacion
                                                    );
                --
                LOOP
                    --
                    ra_k_ac250001.p_devuelve_com_grupo_cont(    l_cod_grupo,
                                                                l_nom_grupo,
                                                                l_imp_comision,
                                                                l_imp_comision_spto,
                                                                l_pct_comision
                                                            ); 
                    ---   
                    exit when l_cod_grupo is null;
                    -- 
                    g_tabla_lista_detalle(g_tabla_lista_detalle.count).imp_prima            := round( nvl(p_registro.imp_prima,0) * nvl(l_pct_participacion,0) / 100, 5);
                    g_tabla_lista_detalle(g_tabla_lista_detalle.count).imp_prima_spto       := round( nvl(p_registro.imp_prima_spto,0) * nvl(l_pct_participacion,0) / 100, 5);
                    g_tabla_lista_detalle(g_tabla_lista_detalle.count).ict_comision         := l_imp_comision;
                    g_tabla_lista_detalle(g_tabla_lista_detalle.count).ict_comision_spto    := l_imp_comision_spto;
                    --
                    g_tabla_lista_detalle(g_tabla_lista_detalle.count).pct_comision         := l_imp_comision_spto;
                    g_tabla_lista_detalle(g_tabla_lista_detalle.count).pct_comision         := l_imp_comision;
                    --
                    p_calcula_impuesto( g_tabla_lista_detalle(g_tabla_lista_detalle.count) );
                    --
                END LOOP;
                --
                g_tabla_lista_detalle(g_tabla_lista_detalle.count).imp_prima_net := 
                        nvl(g_tabla_lista_detalle(g_tabla_lista_detalle.count).imp_prima,0) - 
                        nvl(g_tabla_lista_detalle(g_tabla_lista_detalle.count).ict_comision,0);
                        -- nvl(g_tabla_lista_detalle(g_tabla_lista_detalle.count).imp_impuesto,0);
                --
                g_tabla_lista_detalle(g_tabla_lista_detalle.count).imp_prima_spto_net   := 
                        nvl(g_tabla_lista_detalle(g_tabla_lista_detalle.count).imp_prima_spto,0) - 
                        nvl(g_tabla_lista_detalle(g_tabla_lista_detalle.count).ict_comision_spto,0);
                       -- nvl(g_tabla_lista_detalle(g_tabla_lista_detalle.count).imp_impuesto,0);
                --    
                EXCEPTION 
                    WHEN OTHERS THEN 
                        NULL;
            END;
            --
        END LOOP;
        --                                
        EXCEPTION 
            WHEN OTHERS THEN 
                NULL;                                
    END;
    --
    -- devuelve la distribucion de reaseguro
    PROCEDURE p_distribucion IS 
        --
        l_cod_contrato       a2501000.cod_contrato %TYPE;
        l_nom_contrato       a2500140.nom_contrato %TYPE;
        l_pct_participacion  a2501000.pct_participacion%TYPE;
        l_cap_cedido         a2501000.cap_cedido %TYPE;
        l_cap_cedido_spto    a2501000.cap_cedido_spto %TYPE;
        l_imp_prima          a2501000.imp_prima %TYPE;
        l_imp_prima_ret      a2501000.imp_prima %TYPE;
        l_imp_prima_ced      a2501000.imp_prima %TYPE;
        l_imp_prima_spto     a2501000.imp_prima_spto %TYPE;
        l_imp_prima_spto_ret a2501000.imp_prima_spto %TYPE;
        l_imp_prima_spto_ced a2501000.imp_prima_spto %TYPE;
        l_num_contrato       a2500140.num_contrato %TYPE;
        l_anio_contrato      a2500140.anio_contrato %TYPE;
        l_serie_contrato     a2500140.serie_contrato %TYPE;
        l_pct_ajuste         a2501610.pct_ajuste %TYPE;
        l_prima_ajuste       NUMBER;
        l_prima_ajuste_spto  NUMBER;
        --
        -- registro del detalle
        l_registro           typ_rec_detalle;
        --
    BEGIN         
        --
        l_registro.k_origen            := '1';  -- Distribucion
        -- se ejecutan las consultas de la distribucion
        ra_k_ac250001.p_query_distribucion( g_cod_cia,
                                            g_num_poliza,
                                            g_num_spto,
                                            g_num_apli,
                                            g_num_spto_apli,
                                            g_num_periodo,
                                            g_num_riesgo,
                                            g_cod_secc_reas,
                                            g_num_mov,
                                            g_cod_ramo
                                        );
        --
        -- obtenemos la distribucion
        LOOP
            ra_k_ac250001.p_devuelve_distribucion(  l_cod_contrato, l_nom_contrato,
                                                    l_pct_participacion, l_cap_cedido, l_cap_cedido_spto,
                                                    l_imp_prima, l_imp_prima_ret,
                                                    l_imp_prima_ced, l_imp_prima_spto,
                                                    l_imp_prima_spto_ret, l_imp_prima_spto_ced,
                                                    l_num_contrato, l_anio_contrato,
                                                    l_serie_contrato, l_pct_ajuste,
                                                    l_prima_ajuste, l_prima_ajuste_spto  
                                                );
            --                                
            EXIT WHEN l_cod_contrato IS NULL;
            --
            -- asignamos los valores al registro detalle para inserta en table pl/sql
            l_registro.num_riesgo          := g_num_riesgo;
            l_registro.nom_riesgo          := g_nom_riesgo;
            l_registro.num_mov             := g_num_mov;
            l_registro.fec_mov             := g_fec_mov;
            l_registro.fec_efec            := g_fec_efec;
            l_registro.fec_vcto            := g_fec_vcto; 
            l_registro.cod_secc_reas       := g_cod_secc_reas;
            l_registro.nom_secc_reas       := g_nom_secc_reas;
            l_registro.cod_contrato        := l_cod_contrato;
            l_registro.nom_contrato        := l_nom_contrato;
            l_registro.pct_participacion   := l_pct_participacion;
            l_registro.cap_cedido          := nvl( l_cap_cedido, 0);
            l_registro.cap_cedido_spto     := nvl( l_cap_cedido_spto,0);
            l_registro.imp_prima           := nvl( l_imp_prima,0);
            l_registro.imp_prima_ret       := nvl( l_imp_prima_ret,0);
            l_registro.imp_prima_ced       := nvl( l_imp_prima_ced,0);
            l_registro.imp_prima_spto      := nvl( l_imp_prima_spto,0);
            l_registro.imp_prima_spto_ret  := nvl( l_imp_prima_spto_ret,0);
            l_registro.imp_prima_spto_ced  := nvl( l_imp_prima_spto_ced,0);
            l_registro.pct_ajuste          := nvl( l_pct_ajuste,0);
            l_registro.prima_ajuste        := nvl( l_prima_ajuste,0);
            l_registro.prima_ajuste_spto   := nvl( l_prima_ajuste_spto,0);
            --
            p_inserta_detalle( l_registro );
            --
            p_detalle_contrato( l_registro  ) ;
            --
        END LOOP;
        --
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
                --     
    END p_distribucion;
    --
    -- devuelve el facultativo
    PROCEDURE p_facultativo IS 
        --
        l_cod_cia_rea       a2501500.cod_cia_facul %TYPE;
        l_nom_cia_rea       v1001390.nom_completo %TYPE;
        l_cod_broker        a2501500.cod_broker %TYPE;
        l_nom_broker        v1001390.nom_completo %TYPE;
        l_pct_participacion a2501500.pct_participacion%TYPE;
        l_cap_cedido        a2501500.cap_cedido %TYPE;
        l_cap_cedido_spto   a2501500.cap_cedido_spto %TYPE;
        l_imp_prima         a2501500.imp_prima %TYPE;
        l_imp_prima_spto    a2501500.imp_prima_spto %TYPE;
        l_imp_comision      a2501500.com_facul %TYPE;
        l_imp_comision_spto a2501500.com_facul_spto %TYPE;
        l_dep_facul         a2501500.dep_facul %TYPE;
        l_dep_facul_spto    a2501500.dep_facul_spto %TYPE;
        l_mca_calcula_impto a2990131.mca_calcula_impto%TYPE;
        l_pct_comision      a2501500.pct_participacion%TYPE;
        l_pct_ajuste        a2501610.pct_ajuste %TYPE;
        l_prima_ajuste      NUMBER;
        l_prima_ajuste_spto NUMBER;
        l_act_comis         a2990131.pct_comis %TYPE;
        --
        -- registro del detalle
        l_registro          typ_rec_detalle;
        --
    BEGIN 
        --
        l_registro.k_origen            := '2';  -- Facultativo
        --
        ra_k_ac250001.p_query_facultativo(  g_cod_cia,
                                            g_num_poliza, g_num_spto, g_num_apli, g_num_spto_apli,
                                            g_num_periodo, g_num_riesgo, 
                                            g_cod_secc_reas,
                                            g_num_mov
                                          );
        --
        LOOP
            ra_k_ac250001.p_devuelve_facultativo(   l_cod_cia_rea, l_nom_cia_rea,
                                                    l_cod_broker, l_nom_broker,
                                                    l_pct_participacion, l_cap_cedido, l_cap_cedido_spto,
                                                    l_imp_prima, l_imp_prima_spto,
                                                    l_imp_comision, l_imp_comision_spto,
                                                    l_dep_facul, l_dep_facul_spto,
                                                    l_mca_calcula_impto,
                                                    l_pct_comision,
                                                    l_pct_ajuste,
                                                    l_prima_ajuste,
                                                    l_prima_ajuste_spto,
                                                    l_act_comis
                                                );
            --                                 
            EXIT WHEN l_cod_cia_rea IS NULL;
            --
            -- asignamos los valores al registro detalle para inserta en table pl/sql
            l_registro.num_riesgo          := g_num_riesgo;
            l_registro.nom_riesgo          := g_nom_riesgo;
            l_registro.num_mov             := g_num_mov;
            l_registro.fec_mov             := g_fec_mov;
            l_registro.fec_efec            := g_fec_efec;
            l_registro.fec_vcto            := g_fec_vcto; 
            l_registro.cod_secc_reas       := g_cod_secc_reas;
            l_registro.nom_secc_reas       := g_nom_secc_reas;
            l_registro.cod_contrato        := '9999999999';
            l_registro.nom_contrato        := 'FACULTATIVO';
            l_registro.cod_cia_rea         := l_cod_cia_rea;
            l_registro.nom_cia_rea         := l_nom_cia_rea;
            l_registro.pct_participacion   := nvl(l_pct_participacion,0);
            l_registro.cap_cedido          := nvl( l_cap_cedido,0);
            l_registro.cap_cedido_spto     := nvl( l_cap_cedido_spto,0);
            l_registro.imp_prima           := nvl( l_imp_prima,0);
            l_registro.imp_prima_ret       := 0;
            l_registro.imp_prima_ced       := 0;
            l_registro.imp_prima_spto      := nvl( l_imp_prima_spto,0 );
            l_registro.imp_comision        := nvl( l_imp_comision,0 ); 
            l_registro.imp_comision_spto   := nvl( l_imp_comision_spto,0);
            --
            l_registro.imp_prima_spto_ret  := 0;
            l_registro.imp_prima_spto_ced  := 0;
            l_registro.pct_ajuste          := 0;
            l_registro.prima_ajuste        := 0;
            l_registro.prima_ajuste_spto   := 0;
            --
            p_inserta_detalle( l_registro );
            --
            p_calcula_impuesto( g_tabla_lista_detalle(g_tabla_lista_detalle.count) );
            --
        END LOOP;                                       
        -- 
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
                --                          
    END p_facultativo;
    --
    -- seleccionamos los movimientos
    PROCEDURE p_proc_hoja_tec_reaseguro IS 
    BEGIN 
        --
        -- seleccionamos y lo guardamos el la tabla pl/sql 
        -- los movimientos del reaseguro asociado a la poliza
        FOR r_mov IN c_mvtos LOOP 
            --
            g_num_riesgo    := r_mov.num_riesgo;
            g_cod_secc_reas := r_mov.cod_secc_reas;
            g_num_mov       := r_mov.num_mov;
            --
            -- el suplemento del riesgo para el reaseguro puede ser diferente al spto de la poliza
            g_num_spto      := r_mov.num_spto;
            --
            p_establecer_globales;
            --
            p_activa_reaseguro;
            --
            p_distribucion;
            --
            p_facultativo;
            --
        END LOOP;
        --
    END p_proc_hoja_tec_reaseguro;
    --
    -- RGUERRA, 20210421
    -- reporte xml (excel) hoja tecnica distribucion reaseguro
    -- Este procedimiento sera usado para el modo de tarea.
    PROCEDURE p_rep_hoja_tec_reaseguro IS
    BEGIN    
        --
        -- inicializamos los procesos
        p_init_proceso;
        --
        -- recumeracion y establecimiento de los parametros globales
        p_init_parametros;
        --
        p_proc_hoja_tec_reaseguro;
        --
    END p_rep_hoja_tec_reaseguro;

END ra_k_hoja_tec_distribucion_mni;
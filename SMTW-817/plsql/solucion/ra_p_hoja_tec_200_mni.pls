CREATE OR REPLACE PROCEDURE ra_p_hoja_tec_200_mni(p_cod_cia    a2000030.cod_cia%TYPE,
                                                  p_num_poliza a2000030.num_poliza%TYPE,
                                                  p_num_spto   a2000030.num_spto%TYPE,
                                                  p_num_riesgo a2501500.num_riesgo%TYPE,
                                                  p_num_mov    a2501600.num_mov%TYPE,
                                                  p_spto_nulo  VARCHAR2 DEFAULT 'S') IS
    --
    /* -------------------- VERSION = 1.03 -------------------- */
    --
    /* -------------------- MODIFICACIONES -----------------
    || 2021/06/18 - RGUERRA - 1.00 - (CARRIERHOUSE)
    || Creacion del Paquete.
    || 2021/10/06 - RGUERRA - 1.02 - (CARRIERHOUSE)
    || Se cambia el uso de cap_cedido --> cap_cedido_spto
    ||                     imp_prima  --> imp_prima_spto
    || Se agrega el parametro p_spto_nulo para indicar que el 
    || usuario no suministro el suplemento
    || 2021/10/25 - RGUERRA - 1.03 - (CARRIERHOUSE)
    || Se agrega nueva columna de porcentaje de Distribucion prima
    ||---------------------------------------------------------*/
    --
    g_cod_cia         a2000030.cod_cia%TYPE := p_cod_cia;
    g_num_riesgo      a2501500.num_riesgo%TYPE := p_num_riesgo;
    g_cod_ramo        a2000030.cod_ramo%TYPE;
	g_num_poliza      a2000030.num_poliza%TYPE := p_num_poliza;
    g_num_spto        a2000030.num_spto%TYPE := p_num_spto;
    g_tip_spto        a2000030.tip_spto%TYPE;
	g_num_mov         a2501600.num_mov%TYPE := p_num_mov;
    g_fec_efec_poliza date;
	g_fec_vcto_poliza date;
    --
    g_directorio    VARCHAR2(200);
    g_nom_fichero   VARCHAR2(80);
    g_nom_listado   VARCHAR2(50);
    g_id_fichero    utl_file.file_type;
    g_cod_mon_iso   a1000400.cod_mon_iso%TYPE;
    g_nom_modalidad g2990004.nom_modalidad%TYPE;
    g_nom_tip_spto  a2991800.nom_spto%TYPE;
    --
    -- acmululativas
    g_tot_sec_cap_cedido NUMBER := 0;
    g_tot_sec_prima      NUMBER;
    g_tot_sec_comision   NUMBER;
    g_tot_sec_prima_neta NUMBER;
    g_tot_sec_pct        NUMBER;
    g_tot_sec_pct_prima  NUMBER;
    g_loc_prima_neta     NUMBER;
    g_loc_pct            NUMBER;
    g_loc_pct_prima      NUMBER;
    g_tot_cap_cedido     NUMBER := 0;
    g_tot_prima          NUMBER := 0;
    g_tot_cedido         NUMBER := 0;
    g_tot_comision       NUMBER := 0;
    g_tot_prima_neta     NUMBER := 0;
    g_tot_pct            NUMBER := 0;
    g_tot_pct_prima      NUMBER := 0;
    --
    -- globales para excel
	g_tab_columns             dc_k_xml_format_xls_mca.t_tab_columns; -- formato de columnas
	g_tab_caption             dc_k_xml_format_xls_mca.t_tab_caption; -- cabecera de column
	g_tab_toptitle            dc_k_xml_format_xls_mca.t_tab_toptitle; -- cabeceras
	g_tab_conditional_formats dc_k_xml_format_xls_mca.t_tab_conditionalformats; -- formatos condicionales
	g_tab_custom_styles       dc_k_xml_format_xls_mca.t_tab_customstyles; -- estilos de columnas   
    g_reg_estilo              dc_k_xml_format_xls_mca.t_rec_customStyles;
    --
    -- errores
   	g_cod_error NUMBER;
   	g_msg_error VARCHAR2(2500);
    --
   	-- exceptiones
   	e_init_variable        EXCEPTION;
	e_init_proceso         EXCEPTION;
	e_error_tratar_archivo EXCEPTION;
    --
    -- riesgos
	CURSOR c_riesgos IS
		SELECT DISTINCT num_riesgo, nom_riesgo
		  FROM TABLE(ra_k_hoja_tec_distribucion_mni.f_lista_detalle)
		  WHERE num_riesgo = nvl(g_num_riesgo, num_riesgo)
        ORDER BY num_riesgo; 
    --
	-- movimientos
	CURSOR c_movimientos(p_num_riesgo a2501000.num_riesgo%TYPE) IS
		SELECT DISTINCT num_mov, fec_mov, fec_efec, fec_vcto
		  FROM TABLE(ra_k_hoja_tec_distribucion_mni.f_lista_detalle)
		 WHERE num_riesgo = p_num_riesgo
		   AND num_mov    = ( SELECT max(num_mov)
		                        FROM TABLE(ra_k_hoja_tec_distribucion_mni.f_lista_detalle)
                               WHERE num_riesgo = p_num_riesgo
                                 AND num_mov    = nvl(g_num_mov, num_mov)
                            )     
        ORDER BY num_mov;  
    --
	-- secciones 207 y 208
    CURSOR c_secciones_207_208(p_num_riesgo a2501000.num_riesgo%TYPE,
	                           p_num_mov    a2501000.num_mov%TYPE) IS
      	SELECT DISTINCT cod_secc_reas, nom_secc_reas 
          FROM TABLE(ra_k_hoja_tec_distribucion_mni.f_lista_detalle)
         WHERE num_riesgo = p_num_riesgo
		   AND num_mov    = nvl(p_num_mov, num_mov)
           AND cod_secc_reas IN (207, 208)
        ORDER BY cod_secc_reas;   
    --
	-- secciones miscelaneas
    CURSOR c_secciones_misc(p_num_riesgo a2501000.num_riesgo%TYPE,
	                        p_num_mov    a2501000.num_mov%TYPE) IS
      	SELECT DISTINCT cod_secc_reas, nom_secc_reas 
          FROM TABLE(ra_k_hoja_tec_distribucion_mni.f_lista_detalle)
         WHERE num_riesgo = p_num_riesgo
		   AND num_mov    = nvl(p_num_mov, num_mov)
           AND cod_secc_reas NOT IN (207, 208)
        ORDER BY cod_secc_reas;          
    --
    -- detalle de la seccion 207 Y 208
    CURSOR c_detalle_207_208(p_num_riesgo    a2501000.num_riesgo%TYPE,
		                     p_num_mov       a2501000.num_mov%TYPE,     
                             p_cod_secc_reas a2501000.cod_secc_reas%TYPE) IS
        SELECT cod_contrato, cod_cia_rea, nom_cia_rea, nom_contrato, pct_participacion,
               sum( imp_prima_spto ) imp_prima_spto,
               sum( ict_comision_spto ) ict_comision_spto,
               sum( cap_cedido_spto ) cap_cedido_spto
		  FROM TABLE(ra_k_hoja_tec_distribucion_mni.f_lista_detalle)
         WHERE k_origen = 3 
           AND num_riesgo = p_num_riesgo
		   AND num_mov    = nvl(p_num_mov, num_mov)
           AND cod_secc_reas = p_cod_secc_reas
        GROUP BY cod_contrato, cod_cia_rea, nom_cia_rea, nom_contrato, pct_participacion  
        ORDER BY cod_contrato asc, cod_cia_rea desc; 
    --
    -- detalle de la seccion 207 Y 208
    CURSOR c_detalle_misc(p_num_riesgo    a2501000.num_riesgo%TYPE,
		                  p_num_mov       a2501000.num_mov%TYPE,     
                          p_cod_secc_reas a2501000.cod_secc_reas%TYPE) IS
        SELECT cod_contrato, cod_cia_rea, nom_cia_rea, nom_contrato, pct_participacion,
               sum( imp_prima_spto ) imp_prima_spto,
               sum( ict_comision_spto ) ict_comision_spto,
               sum( cap_cedido_spto ) cap_cedido_spto,
               sum( 0 ) pct_comision
		  FROM TABLE(ra_k_hoja_tec_distribucion_mni.f_lista_detalle)
         WHERE k_origen IN (2, 3)
           AND num_riesgo    = p_num_riesgo
		   AND num_mov       = nvl(p_num_mov, num_mov)
           AND cod_secc_reas = p_cod_secc_reas
           AND cod_secc_reas NOT IN (207, 208)
        GROUP BY cod_contrato, cod_cia_rea, nom_cia_rea, nom_contrato, pct_participacion  
        ORDER BY cod_contrato asc, cod_cia_rea desc;      
    --
    -- acumulado de la seccion 207 y 208
    --      modificacion 2021/10/06 ver. 1.02, se agrega la suma cap_cedido_spto y imp_prima_spto
    CURSOR c_acumulado_207_208(p_num_riesgo    a2501000.num_riesgo%TYPE,
		                       p_num_mov       a2501000.num_mov%TYPE,     
                               p_cod_secc_reas a2501000.cod_secc_reas%TYPE) IS
        SELECT sum(decode(p_cod_secc_reas, 208, 0, cap_cedido)) cap_cedido, 
               sum(imp_prima) imp_prima,
               sum(decode(p_cod_secc_reas, 208, 0, cap_cedido_spto)) cap_cedido_spto,
               sum(imp_prima_spto) imp_prima_spto,
               sum(pct_participacion) pct_participacion
		  FROM TABLE(ra_k_hoja_tec_distribucion_mni.f_lista_detalle)
         WHERE k_origen = 1 
           AND num_riesgo    = p_num_riesgo
		   AND num_mov       = nvl(p_num_mov, num_mov)
           AND cod_secc_reas = p_cod_secc_reas
           AND cod_contrato <> 9999999
           AND nom_contrato <> 'FACULTATIVO';
    --
    -- detalle de la seccion 207 y 208 facultativo
    --      modificacion 2021/10/06 ver. 1.02, se agrega la suma cap_cedido_spto y imp_prima_spto
    CURSOR c_detalle_fac_207_208(p_num_riesgo    a2501000.num_riesgo%TYPE,
		                         p_num_mov       a2501000.num_mov%TYPE,     
                                 p_cod_secc_reas a2501000.cod_secc_reas%TYPE) IS
        SELECT cod_contrato, cod_cia_rea, nom_cia_rea, nom_contrato, pct_participacion,
               sum(decode(p_cod_secc_reas, 208, 0, cap_cedido)) cap_cedido,
               sum(imp_prima) imp_prima,
               sum(imp_comision_spto) imp_comision,
               sum(decode(p_cod_secc_reas, 208, 0, cap_cedido_spto)) cap_cedido_spto,
               sum(imp_prima_spto) imp_prima_spto,
               sum(ict_comision_spto) ict_comision_spto
		  FROM TABLE(ra_k_hoja_tec_distribucion_mni.f_lista_detalle)
         WHERE k_origen = 2
           AND num_riesgo    = p_num_riesgo
		   AND num_mov       = nvl(p_num_mov, num_mov)
           AND cod_secc_reas = p_cod_secc_reas
           AND nom_contrato = 'FACULTATIVO'
          GROUP BY cod_contrato, cod_cia_rea, nom_cia_rea, nom_contrato, pct_participacion;
    --
    -- acumulado de la seccion 207 y 208 FACULTATIVO
    --      modificacion 2021/10/06 ver. 1.02, se agrega la suma cap_cedido_spto y imp_prima_spto
    CURSOR c_acumulado_fac_207_208(p_num_riesgo    a2501000.num_riesgo%TYPE,
		                           p_num_mov       a2501000.num_mov%TYPE,     
                                   p_cod_secc_reas a2501000.cod_secc_reas%TYPE) IS
        SELECT sum(decode(p_cod_secc_reas, 208, 0, cap_cedido)) cap_cedido, 
               sum(imp_prima) imp_prima,
               sum(decode(p_cod_secc_reas, 208, 0, cap_cedido_spto)) cap_cedido_spto, 
               sum(imp_prima_spto) imp_prima_spto
		  FROM TABLE(ra_k_hoja_tec_distribucion_mni.f_lista_detalle)
         WHERE k_origen = 2 
           AND num_riesgo    = p_num_riesgo
		   AND num_mov       = nvl(p_num_mov, num_mov)
           AND cod_secc_reas = p_cod_secc_reas
           AND nom_contrato  = 'FACULTATIVO';    
    --
    -- acumulado de la seccion misc
    --      modificacion 2021/10/06 ver. 1.02, se agrega la suma cap_cedido_spto y imp_prima_spto
    CURSOR c_acumulado_misc(p_num_riesgo    a2501000.num_riesgo%TYPE,
		                    p_num_mov       a2501000.num_mov%TYPE,     
                            p_cod_secc_reas a2501000.cod_secc_reas%TYPE) IS
        SELECT sum(decode(p_cod_secc_reas, 208, 0, cap_cedido)) cap_cedido, 
               sum(imp_prima) imp_prima,
               sum(pct_participacion) pct_participacion,
               sum(decode(p_cod_secc_reas, 208, 0, cap_cedido_spto)) cap_cedido_spto, 
               sum(imp_prima_spto) imp_prima_spto
		  FROM TABLE(ra_k_hoja_tec_distribucion_mni.f_lista_detalle)
         WHERE k_origen IN (2,3) 
           AND num_riesgo    = p_num_riesgo
		   AND num_mov       = nvl(p_num_mov, num_mov)
           AND cod_secc_reas = p_cod_secc_reas
           AND cod_secc_reas NOT IN (207, 208)
        ORDER BY num_riesgo, num_mov;    
    --
    -- reaseguradores 
    --      modificacion 2021/10/06 ver. 1.02, se agrega la suma cap_cedido_spto y imp_prima_spto   
    CURSOR c_reaseguradora(p_num_riesgo a2501000.num_riesgo%TYPE,
		                   p_num_mov    a2501000.num_mov%TYPE) IS
        SELECT cod_cia_rea, 
               nom_cia_rea, 
               sum(cap_cedido) cap_cedido,
               sum(imp_prima) imp_prima,
               sum(imp_comision) imp_comision,
               (sum(imp_prima) - sum(imp_comision)) imp_prima_neta,
               sum(cap_cedido_spto) cap_cedido_spto,
               sum(imp_prima_spto) imp_prima_spto,
               sum(ict_comision_spto) ict_comision_spto,
               (sum(imp_prima_spto) - sum(ict_comision_spto)) imp_prima_neta_spto
          FROM (SELECT cod_secc_reas,
                       cod_cia_rea, 
                       nom_cia_rea, 
                       sum(decode(cod_secc_reas, 208, 0, cap_cedido)) cap_cedido,
                       sum(imp_prima) imp_prima,
                       sum(imp_comision_spto) imp_comision,
                       sum(decode(cod_secc_reas, 208, 0, cap_cedido_spto)) cap_cedido_spto,
                       sum(imp_prima_spto) imp_prima_spto,
                       sum(ict_comision_spto) ict_comision_spto
                  FROM TABLE(ra_k_hoja_tec_distribucion_mni.f_lista_detalle)      
                     WHERE k_origen = 2 -- facultativo 
                       AND num_riesgo   = p_num_riesgo
                       AND num_mov      = nvl(p_num_mov, num_mov)
                       AND cod_secc_reas IN (207, 208)
                       AND nom_contrato = 'FACULTATIVO'
                     GROUP BY cod_secc_reas, cod_cia_rea, nom_cia_rea)
          GROUP BY cod_cia_rea, nom_cia_rea;
    -- 
    -- agregamos estilos propios
    PROCEDURE p_agregar_estilo IS 
        --
        l_index number;
        --
    BEGIN 
        --
        l_index := g_tab_custom_styles.COUNT;
        --
        g_reg_estilo.id         := 's78a';
        g_reg_estilo.TYPE       := NULL;
        g_reg_estilo.format     := '_-* #,##0.00';
        g_reg_estilo.protection := FALSE;
        --
        g_reg_estilo.font.fName          := 'Arial';
        g_reg_estilo.font.fFamily        := 'Swiss';
        g_reg_estilo.font.fSize          := 10;
        g_reg_estilo.font.fColor         := NULL;
        g_reg_estilo.font.fBold          := FALSE;
        g_reg_estilo.font.fItalic        := FALSE;
        g_reg_estilo.font.fStrikeThrough := FALSE;
        g_reg_estilo.font.fUnderline     := NULL;
        g_reg_estilo.font.fPosition      := NULL;
        --
        g_reg_estilo.background.bColor        := NULL;
        g_reg_estilo.background.bPattern      := NULL;
        g_reg_estilo.background.bPatternColor := NULL;
        --
        l_index := l_index + 1;
        g_tab_custom_styles(l_index) := g_reg_estilo;
        --
        g_reg_estilo.id         := 's78b';
        g_reg_estilo.TYPE       := NULL;
        g_reg_estilo.format     := '_-* #,##0.00';
        g_reg_estilo.protection := FALSE;
        --
        g_reg_estilo.font.fName          := 'Arial';
        g_reg_estilo.font.fFamily        := 'Swiss';
        g_reg_estilo.font.fSize          := 10;
        g_reg_estilo.font.fColor         := NULL;
        g_reg_estilo.font.fBold          := TRUE;
        g_reg_estilo.font.fItalic        := FALSE;
        g_reg_estilo.font.fStrikeThrough := FALSE;
        g_reg_estilo.font.fUnderline     := NULL;
        g_reg_estilo.font.fPosition      := NULL;
        --
        g_reg_estilo.background.bColor        := '#F2F2F2';
        g_reg_estilo.background.bPattern      := 'Solid';
        g_reg_estilo.background.bPatternColor := NULL;
        --
        l_index := l_index + 1;
        g_tab_custom_styles(l_index) := g_reg_estilo;
        --
        g_reg_estilo.id         := 's78c';
        g_reg_estilo.TYPE       := NULL;
        g_reg_estilo.format     := 'Percent';
        g_reg_estilo.protection := FALSE;
        --
        g_reg_estilo.font.fName          := 'Arial';
        g_reg_estilo.font.fFamily        := 'Swiss';
        g_reg_estilo.font.fSize          := 10;
        g_reg_estilo.font.fColor         := NULL;
        g_reg_estilo.font.fBold          := TRUE;
        g_reg_estilo.font.fItalic        := FALSE;
        g_reg_estilo.font.fStrikeThrough := FALSE;
        g_reg_estilo.font.fUnderline     := NULL;
        g_reg_estilo.font.fPosition      := NULL;
        --
        g_reg_estilo.background.bColor        := NULL;
        g_reg_estilo.background.bPattern      := NULL;
        g_reg_estilo.background.bPatternColor := NULL;
        --
        l_index := l_index + 1;
        g_tab_custom_styles(l_index) := g_reg_estilo;
        --
        g_reg_estilo.id         := 's78d';
        g_reg_estilo.TYPE       := NULL;
        g_reg_estilo.format     := 'Percent';
        g_reg_estilo.protection := FALSE;
        --
        g_reg_estilo.font.fName          := 'Arial';
        g_reg_estilo.font.fFamily        := 'Swiss';
        g_reg_estilo.font.fSize          := 10;
        g_reg_estilo.font.fColor         := NULL;
        g_reg_estilo.font.fBold          := TRUE;
        g_reg_estilo.font.fItalic        := FALSE;
        g_reg_estilo.font.fStrikeThrough := FALSE;
        g_reg_estilo.font.fUnderline     := NULL;
        g_reg_estilo.font.fPosition      := NULL;
        --
        g_reg_estilo.background.bColor        := '#F2F2F2';
        g_reg_estilo.background.bPattern      := 'Solid';
        g_reg_estilo.background.bPatternColor := NULL;
        --
        l_index := l_index + 1;
        g_tab_custom_styles(l_index) := g_reg_estilo;
        --
    END p_agregar_estilo;      
    --
	-- devuelve error
	PROCEDURE p_devuelve_error(p_cod_error NUMBER, p_msg_error VARCHAR2) IS 
	BEGIN 
		--
		trn_k_global.asigna('mca_ter_tar', 'N');
		--
		g_cod_error := p_cod_error;
		g_msg_error := p_msg_error;
		raise_application_error(g_cod_error, g_msg_error);
		--
	END p_devuelve_error;
    --
	-- apertura de archivo
	PROCEDURE p_abrir_fichero IS
	BEGIN
		--
        p_agregar_estilo;
		g_id_fichero := dc_k_xml_format_xls_mca.f_crea_archivo(g_directorio,
                                                               g_nom_fichero,
                                                               g_tab_custom_styles);
		--
		EXCEPTION
			WHEN OTHERS THEN
                dbms_output.put_line(sqlerrm); 
				--
				RAISE e_error_tratar_archivo;
				--
	END p_abrir_fichero;
    --
	-- cierre de archivo 
	PROCEDURE p_cerrar_fichero IS
	BEGIN
			--
			dc_k_xml_format_xls_mca.p_cerrar_archivo(g_id_fichero);
			--
			EXCEPTION
				WHEN OTHERS THEN
				--
				RAISE e_error_tratar_archivo;
				--
	END p_cerrar_fichero;	
    --
    FUNCTION f_tasa_coberturas(p_num_riesgo a2501000.num_riesgo%TYPE)
      RETURN NUMBER IS 
		--
		l_num a2000040.tasa_cob%TYPE := 0;
		--
	BEGIN 
		--
		SELECT sum(tasa_cob) 
		  INTO l_num
  		  FROM a2000040
 		 WHERE cod_cia = g_cod_cia
   		   AND num_poliza = g_num_poliza
		   AND num_spto = g_num_spto
		   AND num_apli = 0
		   AND num_spto_apli = 0
		   AND num_riesgo = p_num_riesgo
           AND mca_vigente = 'S'
           AND mca_baja_cob = 'N';
		--   
		RETURN l_num;
		--
		EXCEPTION 
			WHEN OTHERS THEN 
				RETURN 0;
			--	
    END f_tasa_coberturas;       
    --
	-- devuelve el nombre de la modalidad
	FUNCTION f_nom_modalidad(p_cod_ramo    a2000020.cod_ramo%TYPE,
	                         p_fec_validez g2990004.fec_validez%TYPE,
							 p_num_riesgo  a2501000.num_riesgo%TYPE,
							 p_num_mov     a2501000.num_mov%TYPE)
      RETURN VARCHAR2 IS 
		--
		l_cod_modalidad a2000020.val_campo%TYPE;
		l_nom_modalidad g2990004.nom_modalidad%TYPE;
		--
	BEGIN 
		--
   		em_k_a2000020.p_lee(g_cod_cia,
                            g_num_poliza,
                            0,
                            0,
                            0, 
		                    p_num_riesgo,
                            p_num_mov,
                            'COD_MODALIDAD', 
							p_cod_ramo);
        l_cod_modalidad := em_k_a2000020.f_val_campo;
		--
		IF l_cod_modalidad IS NOT NULL THEN
			--
			em_k_g2990004.p_lee(g_cod_cia, l_cod_modalidad, p_fec_validez);
			l_nom_modalidad := em_k_g2990004.f_nom_cor_modalidad;
			--
		ELSE
			--
			dc_k_a1001800.p_lee(g_cod_cia, p_cod_ramo);
			l_nom_modalidad := dc_k_a1001800.f_abr_ramo;
			--
		END IF; 
		--
		RETURN l_nom_modalidad;
		--  
		EXCEPTION
            WHEN OTHERS THEN
                RETURN NULL;
                --
	END f_nom_modalidad;
    --
    -- devuelvel el maximo numero de movimiento
    FUNCTION f_max_num_mov(p_num_riesgo a2501000.num_riesgo%TYPE) RETURN NUMBER IS 
		--
		l_num a2501600.num_mov%TYPE := 0;
		--
	BEGIN 
		--
		SELECT max(num_mov) 
		  INTO l_num
  		  FROM a2501600
 		 WHERE cod_cia = g_cod_cia
   		   AND num_poliza = g_num_poliza
		   AND num_spto = g_num_spto
		   AND num_apli = 0
		   AND num_spto_apli = 0
		   AND num_riesgo = p_num_riesgo;
		--   
		RETURN l_num;
		--
		EXCEPTION 
			WHEN OTHERS THEN 
				RETURN g_num_mov;
			--	
	END f_max_num_mov;
    --
    -- calcula el importe total de la prima para seccion 207 y 208
    FUNCTION f_prima_total_207_208(p_num_riesgo a2501000.num_riesgo%TYPE,
                                   p_num_mov    a2501000.num_mov%TYPE) 
      RETURN NUMBER IS 
        --
        l_tot_cap_cedido     NUMBER := 0;
        l_tot_cap_cedido_fac NUMBER := 0;
        --
    BEGIN 
        --
        -- se sustituye imp_prima por imp_prima_spto, ver 1.02
        SELECT sum(imp_prima_spto)
          INTO l_tot_cap_cedido
		  FROM TABLE(ra_k_hoja_tec_distribucion_mni.f_lista_detalle)
         WHERE k_origen   = 3 
           AND num_riesgo = p_num_riesgo
           AND num_mov    <= nvl(p_num_mov, num_mov) 
           AND cod_secc_reas IN (207, 208); 
        --
        -- se sustituye imp_prima por imp_prima_spto, ver 1.02
        SELECT sum(imp_prima_spto)
          INTO l_tot_cap_cedido_fac
		  FROM TABLE(ra_k_hoja_tec_distribucion_mni.f_lista_detalle)
         WHERE k_origen = 2 
           AND num_riesgo   = p_num_riesgo
           AND num_mov     <= nvl(p_num_mov, num_mov)
           AND cod_secc_reas IN (207, 208)
           AND nom_contrato = 'FACULTATIVO'; 
        --   
        RETURN nvl(l_tot_cap_cedido, 0) + nvl(l_tot_cap_cedido_fac, 0);
        --
    END f_prima_total_207_208;
    --
    -- calcula el importe total de la prima para seccion 207 y 208
    --      modificacion 2021/10/06 ver. 1.02, se agrega la suma cap_cedido_spto y imp_prima_spto
    FUNCTION f_total_cedido(p_num_riesgo a2501000.num_riesgo%TYPE,
                            p_num_mov    a2501000.num_mov%TYPE) RETURN NUMBER IS 
        --
        l_tot_cap_cedido      NUMBER := 0;
        l_tot_cap_cedido_fac  NUMBER := 0;
        l_tot_cap_cedido_misc NUMBER := 0;
        --
    BEGIN 
        --
        SELECT sum(decode(cod_secc_reas, 208, 0, cap_cedido_spto))
          INTO l_tot_cap_cedido
		  FROM TABLE(ra_k_hoja_tec_distribucion_mni.f_lista_detalle)
         WHERE k_origen = 3 
           AND num_riesgo = p_num_riesgo
           AND num_mov   <= nvl(p_num_mov, num_mov)
           AND cod_secc_reas IN (207, 208)
           AND nom_contrato <> 'FACULTATIVO'; 
        --
        SELECT sum(decode(cod_secc_reas, 208, 0, cap_cedido_spto))
          INTO l_tot_cap_cedido_fac
		  FROM TABLE(ra_k_hoja_tec_distribucion_mni.f_lista_detalle)
         WHERE k_origen = 1 
           AND num_riesgo = p_num_riesgo
           AND num_mov   <= nvl(p_num_mov, num_mov)
           AND cod_secc_reas IN (207, 208)
           AND nom_contrato = 'FACULTATIVO'; 
        --
       SELECT sum(cap_cedido_spto)
          INTO l_tot_cap_cedido_misc
		  FROM TABLE(ra_k_hoja_tec_distribucion_mni.f_lista_detalle)
         WHERE k_origen = 3 
           AND num_riesgo = p_num_riesgo
		   AND num_mov   <= nvl(p_num_mov, num_mov)
           AND cod_secc_reas NOT IN (207, 208)
           AND imp_prima <> 0;    
        --
        RETURN nvl(l_tot_cap_cedido, 0) + nvl(l_tot_cap_cedido_fac, 0) + nvl(l_tot_cap_cedido_misc,0);
        --
    END f_total_cedido;
    --
    -- calcula el importe total de la prima misc
    --      modificacion 2021/10/06 ver. 1.02, se agrega la suma cap_cedido_spto y imp_prima_spto
    FUNCTION f_prima_total_misc(p_num_riesgo a2501000.num_riesgo%TYPE,
                                p_num_mov    a2501000.num_mov%TYPE) 
      RETURN NUMBER IS 
        --
         l_tot_prima NUMBER := 0;
        --
    BEGIN 
        --
        SELECT sum(imp_prima_spto)
          INTO l_tot_prima
		  FROM TABLE(ra_k_hoja_tec_distribucion_mni.f_lista_detalle)
         WHERE k_origen = 3 
           AND num_riesgo = p_num_riesgo
           AND num_mov   <= nvl(p_num_mov, num_mov)
           AND cod_secc_reas NOT IN (207, 208)
        ORDER BY num_riesgo, num_mov; 
        --
        RETURN l_tot_prima;
        --
    END f_prima_total_misc;    
    --
    -- calcula el porcentaje de participacion secciones 
    FUNCTION f_calcula_pct(p_imp_actual NUMBER) RETURN NUMBER IS 
        --
        l_resultado NUMBER;
        --
    BEGIN 
        --
        IF g_tot_cedido > 0 THEN
            l_resultado := p_imp_actual / g_tot_cedido * 100;
        ELSE
            l_resultado := 0;    
        END IF;
        --
        RETURN l_resultado;
        --
    END f_calcula_pct;
    --
    -- iniciar proceso
    PROCEDURE p_iniciar_proceso IS 
    BEGIN 
        --
        trn_k_global.asigna('MCA_TER_TAR', 'N');
        g_directorio  := trn_k_global.mspool_dir;
        g_nom_listado := 'list_hoja_tec_rea.' || g_num_poliza;
		g_nom_fichero := g_nom_listado || '.xml';
		trn_k_global.asigna('JBNOM_LISTADO', g_nom_listado);
        --
        -- abrimos el fichero
        p_abrir_fichero;
        --
        IF g_num_spto IS NULL THEN
			g_num_spto := em_k_a2000030.f_max_spto(g_cod_cia,
                                                   g_num_poliza,
                                                   NULL,
                                                   NULL,
                                                   NULL);
		END IF;
        --
		-- datos de la poliza
		em_k_a2000030.p_lee(g_cod_cia, g_num_poliza, g_num_spto, 0, 0);  
		g_fec_efec_poliza := em_k_a2000030.f_fec_efec_spto;
		g_fec_vcto_poliza := em_k_a2000030.f_fec_vcto_poliza;
		g_tip_spto        := em_k_a2000030.f_tip_spto;
		g_cod_ramo        := em_k_a2000030.f_cod_ramo;
        --            
      	-- establecemos el codigo de moneda
		dc_k_a1000400.p_lee(em_k_a2000030.f_cod_mon);
      	g_cod_mon_iso := dc_k_a1000400.f_cod_mon_iso;
        --
        -- nombre de la modalidad
		g_nom_modalidad := f_nom_modalidad(g_cod_ramo, g_fec_vcto_poliza, 1, 1);
        -- 
		-- buscamos la description del tipo suplemento
		IF g_tip_spto = 'XX' then
			g_nom_tip_spto := 'EMISION';
		ELSE
			-- 
			-- buscamos la descripcion del suplemento
			em_k_a2991800_trn.p_lee(g_cod_cia,
									em_k_a2000030.f_cod_spto,
									em_k_a2000030.f_sub_cod_spto,
                 				    NULL);
			--
			g_nom_tip_spto := em_k_a2991800_trn.f_nom_spto;
			--
		END IF;	
        --                                 
        trn_k_global.asigna('COD_USR', 'TRON2000');
        trn_k_global.asigna('COD_IDIOMA', 'ES');
        trn_k_global.asigna('JBCOD_CIA', p_cod_cia);
        trn_k_global.asigna('JBNUM_POLIZA', g_num_poliza);
        --
        IF p_spto_nulo = 'S' THEN
            trn_k_global.asigna('JBNUM_SPTO', NULL);
        ELSE
            trn_k_global.asigna('JBNUM_SPTO', g_num_spto);
        END IF;    
        --
        trn_k_global.asigna('JBNUM_RIESGO', g_num_riesgo);
        --
        ra_k_hoja_tec_distribucion_mni.p_rep_hoja_tec_reaseguro; 
        -- 
        EXCEPTION
			WHEN others THEN
				g_msg_error := SQLERRM;
				RAISE e_init_proceso;  
                --
    END p_iniciar_proceso;
    --
    -- finalizar proceso
    PROCEDURE p_finalizar_proceso IS 
    BEGIN 
        --
        p_cerrar_fichero;
        --
    END p_finalizar_proceso;
    --
    -- calculo prima neta
    FUNCTION f_prima_neta(p_prima NUMBER, p_comision NUMBER) RETURN NUMBER IS
        --               
    BEGIN 
        RETURN(nvl(p_prima, 0) - nvl(p_comision, 0));
    END f_prima_neta;                     
    --
    -- imprimir detalle
    PROCEDURE p_imprimir_detalle(p_nom_renglon          VARCHAR2,
                                 p_cap_cedido           NUMBER,
                                 p_prima                NUMBER,
                                 p_comision             NUMBER,
                                 p_prima_neta           NUMBER,
                                 p_porcentaje           NUMBER,
                                 p_resaltar             BOOLEAN := FALSE,
                                 p_form_numerico        BOOLEAN := FALSE,
                                 p_nom_reaseguradora    VARCHAR2 DEFAULT NULL,
                                 p_pct_participacion    NUMBER   DEFAULT NULL,
                                 p_pct_reaseguradora    NUMBER   DEFAULT NULL ) IS 
        --
        l_cap_cedido                VARCHAR2(15) := rpad( to_char( p_cap_cedido ,'999,999,999.99' ), 15, ' ');
        l_prima                     VARCHAR2(15) := rpad( to_char( p_prima ,'999,999,999.99' ), 15, ' ');
        l_comision                  VARCHAR2(15) := rpad( to_char( p_comision ,'999,999,999.99' ) , 15, ' ');
        l_prima_neta                VARCHAR2(15) := rpad( to_char( p_prima_neta ,'999,999,999.99' ) , 15, ' ');
        l_porcentaje                VARCHAR2(15) := rpad( to_char( p_porcentaje ,'999.999' ) , 7, ' ');
        l_pct_participacion         VARCHAR2(15) := rpad( to_char( p_pct_participacion ,'999.999' ) , 7, ' ');
        l_estilo_celda_numerico     VARCHAR2(04) := 's78a';
        l_estilo_celda_porcentual   VARCHAR2(04) := 's78c';
        --                        
    BEGIN 
        --
        dc_k_xml_format_xls_mca.p_nueva_fila(g_id_fichero);
        --
        IF p_resaltar THEN 
            l_estilo_celda_numerico   := 's78b';
            l_estilo_celda_porcentual := 's78d';
            dc_k_xml_format_xls_mca.p_escribe_datos(g_id_fichero,
                                                    p_nom_renglon,
                                                    dc_k_xml_format_xls_mca.g_text_bold);
        ELSE
            dc_k_xml_format_xls_mca.p_escribe_datos(g_id_fichero, p_nom_renglon);
        END IF;    
        --
        IF p_form_numerico THEN 
            --
            dc_k_xml_format_xls_mca.p_escribe_datos(g_id_fichero,p_cap_cedido,l_estilo_celda_numerico);
            dc_k_xml_format_xls_mca.p_escribe_datos(g_id_fichero,p_prima,l_estilo_celda_numerico);
            dc_k_xml_format_xls_mca.p_escribe_datos(g_id_fichero,p_comision,l_estilo_celda_numerico);
            dc_k_xml_format_xls_mca.p_escribe_datos(g_id_fichero,p_prima_neta,l_estilo_celda_numerico);
            --
            -- exception porcentual
            dc_k_xml_format_xls_mca.p_escribe_datos(g_id_fichero,
                                                    nvl((p_porcentaje/100),0),
                                                    l_estilo_celda_porcentual);   
            --
            -- nueva columna ver. 1.03                                        
            IF p_pct_participacion IS NOT NULL THEN     
                --                                   
                dc_k_xml_format_xls_mca.p_escribe_datos(g_id_fichero, nvl(p_pct_participacion/100,0), 
                                                        l_estilo_celda_porcentual);
            END IF;  
            --
            -- nueva columna ver. 1.03                                        
            IF p_pct_reaseguradora IS NOT NULL THEN     
                --                                   
                dc_k_xml_format_xls_mca.p_escribe_datos(g_id_fichero, nvl(p_pct_reaseguradora/100,0), 
                                                        l_estilo_celda_porcentual);
            END IF;                                            
            --
        ELSE    
            --   
            dc_k_xml_format_xls_mca.p_escribe_datos(g_id_fichero,l_cap_cedido, dc_k_xml_format_xls_mca.g_unformatted  );
            dc_k_xml_format_xls_mca.p_escribe_datos(g_id_fichero,l_prima, dc_k_xml_format_xls_mca.g_unformatted  );
            dc_k_xml_format_xls_mca.p_escribe_datos(g_id_fichero,l_comision, dc_k_xml_format_xls_mca.g_unformatted  );
            dc_k_xml_format_xls_mca.p_escribe_datos(g_id_fichero,l_prima_neta, dc_k_xml_format_xls_mca.g_unformatted  );
            dc_k_xml_format_xls_mca.p_escribe_datos(g_id_fichero,nvl(l_porcentaje,'0') ||'%', dc_k_xml_format_xls_mca.g_unformatted );
            --  
            -- nueva columna ver. 1.04
            IF p_pct_participacion IS NOT NULL THEN  
                dc_k_xml_format_xls_mca.p_escribe_datos(g_id_fichero,
                                                      nvl(l_pct_participacion,'0') ||'%', 
                                                      dc_k_xml_format_xls_mca.g_unformatted );
            END IF;  
            --  
        END IF;
        --    
        -- nueva columna ver. 1.04
        IF p_pct_participacion IS NULL THEN   
            dc_k_xml_format_xls_mca.p_escribe_datos(g_id_fichero,'', dc_k_xml_format_xls_mca.g_unformatted  );
        END IF;  
        --    
    END p_imprimir_detalle;
    --
    -- procesa los datos de las secciones 207 y 208
    --      modificacion 2021/10/06 ver. 1.02, se agrega la suma cap_cedido_spto y imp_prima_spto
    PROCEDURE p_procesar_207_208(p_num_riesgo a2501000.num_riesgo%TYPE,
	                             p_num_mov    a2501000.num_mov%TYPE) IS 
        --
        -- suma cedido
        CURSOR c_suma_cedido IS
        SELECT sum(decode(cod_secc_reas, 208, 0, cap_cedido_spto)),
               sum(decode(cod_secc_reas, 208, 0, imp_prima_spto))
		  FROM TABLE(ra_k_hoja_tec_distribucion_mni.f_lista_detalle)
         WHERE k_origen = 3 -- contrato
           AND num_riesgo = p_num_riesgo
           AND num_mov   <= nvl(p_num_mov, num_mov)
           AND cod_secc_reas IN (207, 208)
           AND nom_contrato <> 'FACULTATIVO'; 
        --
        -- suma cedido facultativo
        CURSOR c_suma_cedido_fac IS
        SELECT sum(decode(cod_secc_reas, 208, 0, cap_cedido_spto)),
               sum(decode(cod_secc_reas, 208, 0, imp_prima_spto))
		  FROM TABLE(ra_k_hoja_tec_distribucion_mni.f_lista_detalle)
         WHERE k_origen = 1 
           AND num_riesgo = p_num_riesgo
           AND num_mov   <= nvl(p_num_mov, num_mov)
           AND cod_secc_reas IN (207, 208)
           AND nom_contrato = 'FACULTATIVO';                       
        --                       
        l_nom_cia_rea        VARCHAR2(400);  
        l_salto_linea        BOOLEAN := TRUE;
        l_tot_cap_cedido     NUMBER := 0;
        l_tot_cap_cedido_fac NUMBER := 0;
        l_tot_pri_cedido     NUMBER := 0;
        l_tot_pri_cedido_fac NUMBER := 0;
        --                     
    BEGIN
        --
        OPEN c_suma_cedido;
        FETCH c_suma_cedido INTO l_tot_cap_cedido, l_tot_pri_cedido;
        CLOSE c_suma_cedido;
        --
        OPEN c_suma_cedido_fac;
        FETCH c_suma_cedido_fac INTO l_tot_cap_cedido_fac, l_tot_pri_cedido_fac;
        CLOSE c_suma_cedido_fac;
        --
        -- contrato
        FOR r_secciones IN c_secciones_207_208(p_num_riesgo, p_num_mov) LOOP
            --
            dc_k_xml_format_xls_mca.p_nueva_fila(g_id_fichero);
            dc_k_xml_format_xls_mca.p_escribe_datos(g_id_fichero,
                                                    'Secci' || chr(243) || 'n: ' ||
                                                    r_secciones.nom_secc_reas,
                                                    dc_k_xml_format_xls_mca.g_text_bold,
                                                    NULL,
                                                    NULL,
                                                    5);
            --
            -- detalle del reporte
            g_tot_sec_comision   := 0;
            g_tot_sec_prima_neta := 0; 
            g_tot_sec_pct        := 0;
            g_tot_sec_pct_prima  := 0;
            --
            -- detalle seccion 207 y 208
            FOR r_detalles IN c_detalle_207_208(p_num_riesgo,
                                                p_num_mov,
                                                r_secciones.cod_secc_reas) LOOP
                --
                IF r_secciones.cod_secc_reas = 208 THEN
                    r_detalles.cap_cedido_spto := 0;   
                END IF;
                --
                -- acumulados
                g_loc_prima_neta := f_prima_neta(r_detalles.imp_prima_spto,
                                                 r_detalles.ict_comision_spto);
                --
                -- % capital cedido
                IF (nvl(l_tot_cap_cedido, 0) + nvl(l_tot_cap_cedido_fac, 0)) > 0 THEN
                    g_loc_pct := r_detalles.cap_cedido_spto /
                                 (nvl(l_tot_cap_cedido, 0) +
                                 nvl(l_tot_cap_cedido_fac, 0)) * 100;
                ELSE
                    g_loc_pct := 0;    
                END IF;
                --
                -- % prima bruta v1.41
                IF (nvl(l_tot_pri_cedido, 0) + nvl(l_tot_pri_cedido_fac, 0)) > 0 THEN
                    g_loc_pct_prima := r_detalles.imp_prima_spto /
                                 (nvl(l_tot_pri_cedido, 0) +
                                 nvl(l_tot_pri_cedido_fac, 0)) * 100;
                ELSE
                    g_loc_pct_prima := 0;    
                END IF;
                --
                -- g_loc_pct               := f_calcula_pct( r_detalles.cap_cedido );
                g_tot_sec_comision   := g_tot_sec_comision +
                                        nvl(r_detalles.ict_comision_spto, 0);
                g_tot_sec_prima_neta := g_tot_sec_prima_neta + g_loc_prima_neta; 
                g_tot_sec_pct        := g_tot_sec_pct + g_loc_pct;
                g_tot_sec_pct_prima  := g_tot_sec_pct_prima + g_loc_pct_prima;
                --    
                g_tot_cap_cedido := g_tot_cap_cedido + r_detalles.cap_cedido_spto;
                g_tot_comision   := g_tot_comision +
                                    nvl(r_detalles.ict_comision_spto, 0);
                g_tot_prima_neta := g_tot_prima_neta + g_loc_prima_neta; 
                g_tot_pct        := g_tot_pct + g_loc_pct;  
                g_tot_pct_prima  := g_tot_pct_prima + g_loc_pct_prima;         
                --
                IF instr(upper(r_detalles.nom_contrato), 'CUOTA') > 0 THEN
					IF r_detalles.cod_cia_rea = '999999' THEN
						l_nom_cia_rea := ' Retenido';
					ELSE
						l_nom_cia_rea := nvl(r_detalles.nom_cia_rea, ' Cedido');
					END IF;
				ELSE
					l_nom_cia_rea := '';	
				END IF;
                --
                IF (nvl(r_detalles.cap_cedido_spto,0) + nvl(r_detalles.imp_prima_spto,0) + nvl(r_detalles.ict_comision_spto,0)) <> 0 THEN
                    p_imprimir_detalle(r_detalles.nom_contrato || ' ' || l_nom_cia_rea, 
                                    r_detalles.cap_cedido_spto, 
                                    r_detalles.imp_prima_spto, 
                                    r_detalles.ict_comision_spto, 
                                    g_loc_prima_neta,
                                    g_loc_pct,
                                    FALSE,
                                    TRUE,
                                    NULL,
                                    g_loc_pct_prima);
                END IF;
                --
            END LOOP;
            --
            -- total de la seccion 207 Y 208
            FOR r_acumulado IN c_acumulado_207_208(p_num_riesgo,
                                                   p_num_mov,
                                                   r_secciones.cod_secc_reas) LOOP
                --
                IF r_secciones.cod_secc_reas = 208 THEN
                    r_acumulado.cap_cedido_spto := 0;   
                END IF;
                --
                p_imprimir_detalle('Sub Totales: ' || r_secciones.cod_secc_reas,
                                   r_acumulado.cap_cedido_spto,
                                   r_acumulado.imp_prima_spto,
                                   g_tot_sec_comision,
                                   g_tot_sec_prima_neta,
                                   g_tot_sec_pct,
                                   TRUE,
                                   TRUE,
                                   NULL,
                                   g_tot_sec_pct_prima);
                --
                dc_k_xml_format_xls_mca.p_nueva_fila(g_id_fichero);
                l_salto_linea := FALSE;
                --  
            END LOOP;
            --
        END LOOP;
        --
        -- detalle del reporte
        g_tot_sec_cap_cedido := 0;
        g_tot_sec_prima      := 0;
        g_tot_sec_comision   := 0;
        g_tot_sec_prima_neta := 0;
        g_tot_sec_pct        := 0; 
        g_tot_sec_pct_prima  := 0;
        --
        -- facultativo
        FOR r_secciones IN c_secciones_207_208(p_num_riesgo, p_num_mov) LOOP
            --
            IF l_salto_linea THEN
                dc_k_xml_format_xls_mca.p_nueva_fila(g_id_fichero);
                l_salto_linea := FALSE;
            END IF;    
            --
            -- detalle facultativo 207 y 208
            FOR r_detalles IN c_detalle_fac_207_208(p_num_riesgo,
                                                    p_num_mov,
                                                    r_secciones.cod_secc_reas) LOOP
                --
                -- acumulados
                g_loc_prima_neta := f_prima_neta(r_detalles.imp_prima_spto,
                                                 r_detalles.imp_comision);
                --
                IF (nvl(l_tot_cap_cedido, 0) + nvl(l_tot_cap_cedido_fac, 0)) > 0 THEN
                    g_loc_pct := r_detalles.cap_cedido_spto /
                                 (nvl(l_tot_cap_cedido, 0) +
                                 nvl(l_tot_cap_cedido_fac, 0)) * 100;
                ELSE
                    g_loc_pct := 0;    
                END IF;
                --
                -- % prima bruta v1.41
                IF (nvl(l_tot_pri_cedido, 0) + nvl(l_tot_pri_cedido_fac, 0)) > 0 THEN
                    g_loc_pct_prima := r_detalles.imp_prima_spto /
                                 (nvl(l_tot_pri_cedido, 0) +
                                 nvl(l_tot_pri_cedido_fac, 0)) * 100;
                ELSE
                    g_loc_pct_prima := 0;    
                END IF;

                -- g_loc_pct               := f_calcula_pct( r_detalles.cap_cedido );
                g_tot_sec_comision   := g_tot_sec_comision +
                                        nvl(r_detalles.imp_comision, 0);
                g_tot_sec_prima_neta := g_tot_sec_prima_neta + g_loc_prima_neta; 
                g_tot_sec_pct        := g_tot_sec_pct + g_loc_pct;
                g_tot_sec_pct_prima  := g_tot_sec_pct_prima + g_loc_pct_prima;
                --
                IF r_secciones.cod_secc_reas = 208 THEN
                    r_detalles.cap_cedido_spto := 0;   
                END IF;
                g_tot_sec_cap_cedido := g_tot_sec_cap_cedido +
                                        r_detalles.cap_cedido_spto;
                g_tot_sec_prima      := g_tot_sec_prima + r_detalles.imp_prima_spto;
                --    
                g_tot_cap_cedido := g_tot_cap_cedido + r_detalles.cap_cedido_spto;
                g_tot_comision   := g_tot_comision +
                                    nvl(r_detalles.imp_comision, 0);
                g_tot_prima_neta := g_tot_prima_neta + g_loc_prima_neta; 
                g_tot_pct        := g_tot_pct + g_loc_pct;           
                --
                p_imprimir_detalle(r_detalles.nom_contrato || ' Secci' || chr(243) ||
                                   'n (' || r_secciones.cod_secc_reas || ')', 
                                   r_detalles.cap_cedido_spto, 
                                   r_detalles.imp_prima_spto, 
                                   r_detalles.imp_comision, 
                                   g_loc_prima_neta,
                                   g_loc_pct,
                                   FALSE,
                                   TRUE,
                                   NULL,
                                   g_loc_pct_prima);
            END LOOP;
           
        END LOOP;
        --
        IF g_tot_sec_prima > 0 THEN
            p_imprimir_detalle('Total Secci' || chr(243) || 'n Facultativo:',
                               g_tot_sec_cap_cedido,
                               g_tot_sec_prima,
                               g_tot_sec_comision,
                               g_tot_sec_prima_neta,
                               g_tot_sec_pct,
                               TRUE,
                               TRUE,
                               NULL,
                               g_tot_sec_pct_prima);
            --
            dc_k_xml_format_xls_mca.p_nueva_fila(g_id_fichero);
            --
        END IF;            
        --
        -- totales del mOvimiento 207, 208
        p_imprimir_detalle('Totales:',
                           g_tot_cap_cedido,
                           g_tot_prima,
                           g_tot_comision,
                           g_tot_prima_neta,
                           100, -- g_tot_pct,
                           TRUE,
                           TRUE);
        --
    END p_procesar_207_208;
    --
    -- procesa los datos de las secciones miscelaneos
    PROCEDURE p_procesar_misc(p_num_riesgo a2501000.num_riesgo%TYPE,
	                          p_num_mov    a2501000.num_mov%TYPE) IS 
        --
        CURSOR c_cedido_misc(p_cod_secc_reas a2501000.cod_secc_reas%TYPE) IS
        SELECT sum(cap_cedido_spto)
		  FROM TABLE(ra_k_hoja_tec_distribucion_mni.f_lista_detalle)
         WHERE k_origen IN (2,3)
           AND num_riesgo = p_num_riesgo
		   AND num_mov = nvl(p_num_mov,num_mov)
           AND cod_secc_reas = p_cod_secc_reas
           AND imp_prima <> 0;  
        -- 
        -- comision facultativo
        CURSOR c_com_fac_misc(p_cod_secc_reas a2501000.cod_secc_reas%TYPE) IS
        SELECT sum(ict_comision_spto)
		  FROM TABLE(ra_k_hoja_tec_distribucion_mni.f_lista_detalle)
         WHERE k_origen = 2 
           AND num_riesgo = p_num_riesgo
		   AND num_mov = nvl(p_num_mov,num_mov)
           AND cod_secc_reas = p_cod_secc_reas;                          
        --
        l_salto_linea         BOOLEAN := TRUE;
        l_nom_cia_rea         VARCHAR2(400);
        l_tot_cap_cedido_misc NUMBER := 0;
        l_com_factultativo    NUMBER := 0;
        --                     
    BEGIN 
        --
        FOR r_secciones IN c_secciones_misc(p_num_riesgo, p_num_mov) LOOP
            --
            l_tot_cap_cedido_misc := 0;
            --
            OPEN c_cedido_misc(r_secciones.cod_secc_reas);
            FETCH c_cedido_misc INTO l_tot_cap_cedido_misc;
            CLOSE c_cedido_misc;
            --
            IF l_salto_linea THEN
                dc_k_xml_format_xls_mca.p_nueva_fila(g_id_fichero);
                l_salto_linea := FALSE;
            END IF;    
            dc_k_xml_format_xls_mca.p_nueva_fila(g_id_fichero);
            dc_k_xml_format_xls_mca.p_escribe_datos(g_id_fichero,
                                                    'Secci' || chr(243) || 'n: ' ||
                                                    r_secciones.nom_secc_reas,
                                                    dc_k_xml_format_xls_mca.g_text_bold,
                                                    NULL,
                                                    NULL,
                                                    5);
            --
            IF g_tot_prima = 0 THEN
                g_tot_prima := f_prima_total_misc(p_num_riesgo, p_num_mov); 
            END IF;    
            --
            g_tot_sec_comision   := 0;
            g_tot_sec_prima_neta := 0;
            g_tot_sec_pct        := 0;
            --
            FOR r_detalles IN c_detalle_misc(p_num_riesgo,
                                             p_num_mov,
                                             r_secciones.cod_secc_reas) LOOP
                --
                -- acumulados
                g_loc_prima_neta := f_prima_neta(r_detalles.imp_prima_spto,
                                                 nvl(r_detalles.pct_comision, 0) + 
                                                 nvl(r_detalles.ict_comision_spto,0));
                --
                IF (nvl(l_tot_cap_cedido_misc, 0)) > 0 THEN
                    g_loc_pct := r_detalles.cap_cedido_spto /
                                 (nvl(l_tot_cap_cedido_misc, 0)) * 100;
                ELSE
                    g_loc_pct := 0;    
                END IF;
                -- g_loc_pct               := f_calcula_pct( r_detalles.cap_cedido );
                g_tot_sec_comision   := g_tot_sec_comision +
                                        nvl(r_detalles.pct_comision, 0) + 
                                        nvl(r_detalles.ict_comision_spto, 0);
                g_tot_sec_prima_neta := g_tot_sec_prima_neta + g_loc_prima_neta; 
                g_tot_sec_pct        := g_tot_sec_pct + g_loc_pct;
                --
                IF r_detalles.nom_cia_rea IS NOT NULL THEN
                    l_nom_cia_rea := r_detalles.nom_cia_rea;
                ELSE    
                    IF instr(upper(r_detalles.nom_contrato), 'CUOTA') > 0 THEN
                        IF r_detalles.cod_cia_rea = '999999' THEN
                            l_nom_cia_rea := ' Retenido';
                        ELSE
                            l_nom_cia_rea := nvl(r_detalles.nom_cia_rea, ' Cedido');
                        END IF;
                    ELSE
                        l_nom_cia_rea := '';	
                    END IF;
                END IF;    
                --
                -- g_tot_cap_cedido :=  g_tot_cap_cedido +  r_detalles.cap_cedido
                IF nvl(r_detalles.cap_cedido_spto,0) + nvl(r_detalles.imp_prima_spto,0) + nvl(r_detalles.ict_comision_spto,0) <> 0 THEN
                    --
                    p_imprimir_detalle(r_detalles.nom_contrato || ' ' || l_nom_cia_rea, 
                                    r_detalles.cap_cedido_spto, 
                                    r_detalles.imp_prima_spto, 
                                    nvl(r_detalles.pct_comision, 0) + nvl(r_detalles.ict_comision_spto,0), 
                                    g_loc_prima_neta,
                                    g_loc_pct,
                                    FALSE,
                                    TRUE,
                                    NULL,
                                    r_detalles.pct_participacion);
                END IF;                    
                --
            END LOOP;
            --
            -- total de la seccionmiscelaneos
            FOR r_acumulado IN c_acumulado_misc(p_num_riesgo,
                                                p_num_mov,
                                                r_secciones.cod_secc_reas) LOOP
                --
                IF r_secciones.cod_secc_reas = 208 THEN
                    r_acumulado.cap_cedido := 0;   
                END IF;
                --
                -- calculo de comision facultativo
                OPEN c_com_fac_misc( r_secciones.cod_secc_reas );
                FETCH c_com_fac_misc INTO l_com_factultativo;
                CLOSE c_com_fac_misc;
                --
                -- g_tot_sec_comision := g_tot_sec_comision + nvl(l_com_factultativo, 0);
                -- g_tot_sec_prima_neta := r_acumulado.imp_prima - nvl(g_tot_sec_comision, 0);
                p_imprimir_detalle('Sub Totales: '||r_secciones.cod_secc_reas,
                                   r_acumulado.cap_cedido_spto,
                                   r_acumulado.imp_prima_spto,
                                   g_tot_sec_comision,
                                   g_tot_sec_prima_neta,
                                   g_tot_sec_pct,
                                   TRUE,
                                   TRUE);
                --
                dc_k_xml_format_xls_mca.p_nueva_fila(g_id_fichero);
                l_salto_linea := FALSE;
                --
            END LOOP;
            --    
        END LOOP;
        --
    END p_procesar_misc;
    --
    PROCEDURE p_procesar_reaseguradoras(p_num_riesgo a2501000.num_riesgo%TYPE,
	                                    p_num_mov    a2501000.num_mov%TYPE) IS 
        --
        l_salto_linea    BOOLEAN := TRUE;   
        l_cap_cedido     NUMBER := 0;
        l_imp_prima      NUMBER := 0; 
        l_imp_comision   NUMBER := 0;
        l_imp_prima_neta NUMBER := 0;
        l_pct_imp_rea    NUMBER := 0;
        l_acu_pct_rea    NUMBER := 0;
        --                          
    BEGIN 
        --
        dc_k_xml_format_xls_mca.p_nueva_fila(g_id_fichero);
        --
        FOR r_reasegurador IN c_reaseguradora(p_num_riesgo, p_num_mov) LOOP
            --
            IF l_salto_linea THEN 
                dc_k_xml_format_xls_mca.p_nueva_fila(g_id_fichero);
                dc_k_xml_format_xls_mca.p_escribe_datos(g_id_fichero,
                                                        'REASEGURADORAS',
                                                        dc_k_xml_format_xls_mca.g_text_bold,
                                                        NULL,
                                                        NULL,
                                                        5);
                l_salto_linea := FALSE;
            END IF;
            --
            l_pct_imp_rea := 0;
            IF g_tot_cap_cedido > 0 THEN
                l_pct_imp_rea := r_reasegurador.cap_cedido_spto / g_tot_cap_cedido * 100;
                l_acu_pct_rea := l_acu_pct_rea + l_pct_imp_rea;
            END IF;
            --
            l_cap_cedido     := l_cap_cedido + r_reasegurador.cap_cedido_spto;
            l_imp_prima      := l_imp_prima + r_reasegurador.imp_prima_spto; 
            l_imp_comision   := l_imp_comision + r_reasegurador.imp_comision;
            l_imp_prima_neta := l_imp_prima_neta + (r_reasegurador.imp_prima_spto - r_reasegurador.imp_comision);
            --     
            p_imprimir_detalle(r_reasegurador.nom_cia_rea, 
                               r_reasegurador.cap_cedido_spto, 
                               r_reasegurador.imp_prima_spto, 
                               r_reasegurador.imp_comision, 
                               r_reasegurador.imp_prima_spto - r_reasegurador.imp_comision,
                               l_pct_imp_rea,
                               FALSE,
                               TRUE);
            --                         
        END LOOP;    
        --
        IF l_imp_prima > 0 THEN
            p_imprimir_detalle('Total Reaseguradoras:', 
                                l_cap_cedido, 
                                l_imp_prima, 
                                l_imp_comision, 
                                l_imp_prima_neta,
                                l_acu_pct_rea,
                                TRUE,
                                TRUE);
        END IF;                    
        --
    END p_procesar_reaseguradoras;
    --
	-- nombre del asegurado o tomador de la poliza
	FUNCTION f_nombre_asegurado RETURN VARCHAR2 IS
	    -- tercero de las polizas
		CURSOR c_asegurado IS 
			SELECT tip_docum, cod_docum 
			  FROM a2000060
			 WHERE cod_cia = g_cod_cia
			   AND num_poliza = g_num_poliza
			   AND num_apli = trn.CERO 
			   AND num_spto_apli = trn.CERO
			   AND tip_benef = 2
			   AND num_riesgo = 1
			   AND mca_vigente = trn.SI
			   AND mca_baja = trn.NO;
			--
		-- buscamos la poliza en registro web y se obtiene el agente
		l_nom_asegurado VARCHAR2(200) := '';
		l_tip_docum     a2000060.tip_docum%TYPE;
		l_cod_docum     a2000060.cod_docum%TYPE;
		--
	BEGIN
		--
		-- buscamos en los terceros de la poliza
		BEGIN 
			--
			OPEN c_asegurado;
			FETCH c_asegurado INTO l_tip_docum, l_cod_docum;
			CLOSE c_asegurado;
			--
			EXCEPTION 
				WHEN NO_DATA_FOUND THEN
					l_tip_docum := em_k_a2000030.f_tip_docum;
					l_cod_docum := em_k_a2000030.f_cod_docum;
				WHEN OTHERS THEN
					l_tip_docum := em_k_a2000030.f_tip_docum;
					l_cod_docum := em_k_a2000030.f_cod_docum;
			--
		END;			
		--
		dc_k_a1001399.p_lee(g_cod_cia, l_tip_docum, l_cod_docum);
		--
		l_nom_asegurado := upper(dc_k_a1001399.f_nom_tercero || ' ' ||
								 dc_k_a1001399.f_ape1_tercero || ' ' ||
								 dc_k_a1001399.f_ape2_tercero);
		--    
		RETURN l_nom_asegurado;
		--
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RETURN NULL;
				--
			WHEN OTHERS THEN
				RETURN NULL;
				--
	END f_nombre_asegurado;
    -- 
	-- ubicacion del riesgo
	FUNCTION f_ubicacion_riesgo(p_num_riesgo a2000020.num_riesgo%type)
      RETURN VARCHAR2 IS 
    	-- 
		l_desc_ubi  VARCHAR2(512);
		l_ok        BOOLEAN;
		l_val_campo a2000020.val_campo%TYPE;
        l_txt_campo a2000020.txt_campo%TYPE;
		l_cod_campo a2000020.cod_Campo%TYPE;
		--    
		l_txt_estado    a2000020.txt_campo%TYPE;
		l_txt_municipio a2000020.txt_campo%TYPE;
		l_txt_des_ubi   VARCHAR2(512);
		l_txt_des_ubi1  VARCHAR2(512);
		l_txt_des_ubi2  VARCHAR2(512);
		--
	BEGIN 
		--
		l_desc_ubi := '';
		--
		l_ok := em_k_a2000020.f_lee_riesgo_vigente(g_cod_cia,
                              					   p_num_poliza  => g_num_poliza,
                               					   p_num_apli    => 0,
                               					   p_num_riesgo  => p_num_riesgo,
                               					   p_num_periodo => 1,
                               					   p_cod_ramo    => g_cod_ramo,
                               					   p_tip_nivel   => 2);
		--										  
		IF l_ok THEN 
			--
			l_cod_campo := 'DES_UBI';
			em_k_a2000020.p_devuelve_dv_riesgo(l_cod_campo,
                                               l_val_campo,
                                               l_txt_campo);
			l_txt_des_ubi := nvl(l_val_campo, l_txt_campo);
			IF l_txt_des_ubi IS NOT NULL THEN
				l_desc_ubi := l_txt_des_ubi;
			END IF;	
			--
			l_cod_campo := 'DES_UBI1';
			em_k_a2000020.p_devuelve_dv_riesgo(l_cod_campo,
                                               l_val_campo,
                                               l_txt_campo);
			l_txt_des_ubi1 := nvl(l_val_campo, l_txt_campo);
			IF l_txt_des_ubi1 IS NOT NULL THEN
				--
				IF l_desc_ubi IS NOT NULL THEN
					l_desc_ubi := l_desc_ubi || l_txt_des_ubi1;
				ELSE
					l_desc_ubi := l_txt_des_ubi1;
				END IF;
				--	
			END IF;	
			--
			l_cod_campo := 'DES_UBI2';
			em_k_a2000020.p_devuelve_dv_riesgo(l_cod_campo, 
                                               l_val_campo,
                                               l_txt_campo);
			l_txt_des_ubi2 := nvl(l_val_campo, l_txt_campo);	
			IF l_txt_des_ubi2 IS NOT NULL THEN
				--
				IF l_desc_ubi IS NOT NULL THEN
					l_desc_ubi := l_desc_ubi || ' ' || l_txt_des_ubi2;
				ELSE
					l_desc_ubi := l_txt_des_ubi2;
				END IF;
				--	
			END IF;	
			--
		ELSE
			l_val_campo := NULL;
			l_txt_campo := NULL;
			l_desc_ubi  := NULL;
		END IF;							  
		--
		em_k_a2000020.p_devuelve_dv_riesgo('COD_ESTADO',
                                           l_val_campo,
                                           l_txt_estado);
		em_k_a2000020.p_devuelve_dv_riesgo('COD_MUNICIPIO',
                                           l_val_campo,
                                           l_txt_municipio);
		--
		IF l_txt_estado IS NOT NULL THEN
			l_txt_estado := l_txt_estado || ',';
		END IF;
		--
		IF l_txt_municipio IS NOT NULL THEN
			l_txt_municipio := l_txt_municipio || ',';
		END IF;
		--
		RETURN nvl(l_txt_estado, ' ') || ' ' || nvl(l_txt_municipio, ' ') || ' ' || l_desc_ubi;
		--
		EXCEPTION 
			WHEN OTHERS THEN
				RETURN NULL;
				--
	END f_ubicacion_riesgo;
    --
	-- cabecera del archivo excel
	PROCEDURE p_cabecera IS
		--
		l_desc_poliza varchar2(512);
		--
	BEGIN
		--
		g_tab_toptitle(1).toptitle := 'MAPFRE | Seguros Nicaragua, S.A.';
		g_tab_toptitle(2).toptitle := 'Distribuci' || chr(243) ||
                                      'n de Reaseguros de P' || chr(243) ||
                                      'liza';
		--
		g_tab_caption(2).span := 13;
		--
		g_tab_topTitle(3).topTitle := 'Contratante: ' || f_nombre_asegurado;
		g_tab_topTitle(4).topTitle := 'Moneda:' || g_cod_mon_iso;
		--
		IF g_nom_modalidad IS NOT NULL THEN
			l_desc_poliza := g_nom_modalidad || '-' || g_num_poliza;
		ELSE
		   	l_desc_poliza := g_num_poliza;	
		END IF;
		--
		g_tab_topTitle(5).topTitle := 'P' || chr(243) || 'liza No. ' ||
                                      l_desc_poliza || ' / ' || g_num_spto ||
			                          ' Tipo Spto: ' || g_nom_tip_spto ||
			                          ', Fechas Efecto: ' || 
                                      to_char(g_fec_efec_poliza, 'dd-mm-yyyy') ||
			                          ' Vcto.: ' ||
                                      to_char(g_fec_vcto_poliza, 'dd-mm-yyyy');
		--
		g_tab_caption(1).title := 'Distribuci' || chr(243) || 'n por Contrato';
		g_tab_caption(2).title := 'Suma Asegurada';
		g_tab_caption(3).title := 'Prima Bruta';
		g_tab_caption(4).title := 'Comisi' || chr(243) || 'n';
		g_tab_caption(5).title := 'Prima Neta';
		g_tab_caption(6).title := 'Porcentaje de Distribuci' || chr(243) || 'n de Suma Asegurada';
        g_tab_caption(7).title := 'Porcentaje de Distribuci' || chr(243) || 'n de Prima';
        g_tab_caption(8).title := 'Porcentaje de Participaci' || chr(243) || 'n Reaseguradora';
		--
		FOR i IN 1 .. g_tab_caption.count LOOP
			--
			IF i IN (1) THEN
				g_tab_columns(i).ancho := '150';
			ELSE
				g_tab_columns(i).ancho := '80';
			END IF;
			--		  
			g_tab_columns(i).ancho_auto := TRUE;
			--
		END LOOP;
		--
		FOR i IN 1 .. g_tab_toptitle.count LOOP
			g_tab_toptitle(i).span := g_tab_caption.count;
		END LOOP;

		g_tab_caption(1).toptitle := g_tab_toptitle;
		--
		dc_k_xml_format_xls_mca.p_nueva_hoja(g_id_fichero,
                                             'Dist. Reaseguro',
                                             g_tab_caption,
                                             g_tab_columns);
		--
		EXCEPTION 
			WHEN OTHERS THEN
				RAISE;
				--
	END p_cabecera;
    --
    -- datos del riesgo
    PROCEDURE p_datos_riesgo(p_nom_riesgo VARCHAR2) IS 
        --
        l_ubicacion VARCHAR2(512) := 'Ubicaci' || chr(243) || 'n: ' ||
                                     f_ubicacion_riesgo(g_num_riesgo);
        l_tasa_cob  VARCHAR2(512) := 'Tasa: ' ||
                                     to_char(f_tasa_coberturas(g_num_riesgo),
                                     '999,999,999.999');
        --
    BEGIN 
        --
        dc_k_xml_format_xls_mca.p_nueva_fila(g_id_fichero);
        dc_k_xml_format_xls_mca.p_escribe_datos(g_id_fichero,
                                                l_tasa_cob,
                                                dc_k_xml_format_xls_mca.g_text_bold,
                                                NULL,
                                                NULL,
                                                5);
        dc_k_xml_format_xls_mca.p_nueva_fila(g_id_fichero);
        dc_k_xml_format_xls_mca.p_escribe_datos(g_id_fichero,
                                                'Riesgo: ' || p_nom_riesgo,
                                                dc_k_xml_format_xls_mca.g_text_bold,
                                                NULL,
                                                NULL,
                                                5);
        dc_k_xml_format_xls_mca.p_nueva_fila(g_id_fichero);
        dc_k_xml_format_xls_mca.p_escribe_datos(g_id_fichero,
                                                l_ubicacion,
                                                NULL,
                                                NULL,
                                                NULL,
                                                5);
        --
    END p_datos_riesgo;
    --
    -- datos del movimiento
    PROCEDURE p_datos_movimiento(p_num_mov  a2501600.num_mov%TYPE, 
                                 p_fec_mov  DATE, 
                                 p_fec_efec DATE, 
                                 p_fec_vcto DATE) IS 
        --
        l_dato_movimiento VARCHAR2(512) := 'Movimiento: Nro. ' || p_num_mov ||
                                           ' Fecha: ' ||
                                           to_char(p_fec_mov, 'dd-mm-yyyy');                     
    BEGIN 
        --
        dc_k_xml_format_xls_mca.p_nueva_fila(g_id_fichero);
        dc_k_xml_format_xls_mca.p_escribe_datos(g_id_fichero,
                                                l_dato_movimiento,
                                                NULL,
                                                NULL,
                                                NULL,
                                                5);
        --
    END p_datos_movimiento;
    --
    -- detalle del reporte
    PROCEDURE p_detalle IS
        --
        l_num_mvto NUMBER;
        --
    BEGIN 
        --
        FOR r_riesgos IN c_riesgos LOOP 
            --
            g_num_riesgo := r_riesgos.num_riesgo;
            --
            -- imprime datos del riesgo
            p_datos_riesgo(r_riesgos.nom_riesgo);
            --
            -- ciclo de movimientos
            g_tot_cap_cedido := 0;
            g_tot_prima      := 0;
            g_tot_comision   := 0;
            g_tot_prima_neta := 0;
            g_tot_pct        := 0;
            --
            -- movimientos
            FOR r_movimientos IN c_movimientos(r_riesgos.num_riesgo) LOOP
                --
                g_tot_prima  := 0;
                g_tot_cedido := 0;
                --
                IF g_num_mov IS NULL THEN
                    l_num_mvto            := r_movimientos.num_mov;
                    r_movimientos.num_mov := NULL;
                END IF;
                --
                IF g_tot_prima = 0 THEN
                    g_tot_prima := f_prima_total_207_208(r_riesgos.num_riesgo,
                                                         r_movimientos.num_mov); 
                END IF;
                --
                IF g_tot_cedido = 0 THEN
                    g_tot_cedido := f_total_cedido(r_riesgos.num_riesgo,
                                                   r_movimientos.num_mov); 
                END IF; 
                --
                -- imprime el titulo del movimiento
                p_datos_movimiento(l_num_mvto, 
                                   r_movimientos.fec_mov, 
                                   r_movimientos.fec_efec, 
                                   r_movimientos.fec_vcto);
                --
                dc_k_xml_format_xls_mca.p_nueva_fila(g_id_fichero);
                dc_k_xml_format_xls_mca.p_escribe_datos(g_id_fichero,
                                                        'DISTRIBUCION',
                                                        dc_k_xml_format_xls_mca.g_text_bold,
                                                        NULL,
                                                        NULL,
                                                        5);
                --
                p_procesar_207_208(r_riesgos.num_riesgo, r_movimientos.num_mov);
                --
                g_tot_prima := 0;
                --
                -- secciones miscelaneas
                p_procesar_misc(r_riesgos.num_riesgo, r_movimientos.num_mov);
                --
                -- reaseguradoras
                p_procesar_reaseguradoras(r_riesgos.num_riesgo,
                                          r_movimientos.num_mov);
                --
            END LOOP;
            --
        END LOOP;
        --
        -- Se cierra la Hoja de Excel
      	dc_k_xml_format_xls_mca.p_cerrar_hoja(g_id_fichero,
                                              1,
                                              0,
                                              g_tab_caption,
                                              TRUE,
                                              g_tab_conditional_formats);
        --
    END p_detalle;
    --
    -- control de proceso
    PROCEDURE p_proceso IS 
    BEGIN 
        -- 
        p_cabecera;
        --
        p_detalle;
        --
    END p_proceso;
    --
BEGIN
    --
    p_iniciar_proceso;
    --
    p_proceso;
    --
    p_finalizar_proceso;
    --
	EXCEPTION
    	WHEN e_init_variable THEN
      		--
			p_devuelve_error(-20002,
                             '<ra_p_hoja_rec_200->Inicializando variables globales> ' ||
                             g_msg_error);
			--
		WHEN e_init_proceso THEN
      		--
			p_devuelve_error(-20003,
                             '<ra_p_hoja_rec_200->Inicializando Proceso> ' ||
                             g_msg_error);
			--	
		WHEN e_error_tratar_archivo THEN
      		-- 
			p_devuelve_error(-20004,
                             '<ra_p_hoja_rec_200->Al Tratar Archivo>  ' || sqlerrm);
			--
            /*
     	 	IF utl_file.is_open(l_id_fichero) THEN
        		utl_file.fclose(l_id_fichero);
      		END IF;  
            */
      		--
		WHEN others THEN
      		--
			p_devuelve_error(-20010, '<ra_p_hoja_rec_200> ' || sqlerrm);
			--
END ra_p_hoja_tec_200_mni;
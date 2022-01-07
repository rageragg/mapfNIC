CREATE or REPLACE PROCEDURE ra_p_hoja_tec_reaseguro_mni
IS
	--
	/* -------------------- DESCRIPCION --------------------
	|| Genera Hoja tecnica de Distribucion de Reaseguro
	|| Tema de Reaseguro
	*/ -----------------------------------------------------
	--
	/* -------------------- VERSION = 1.00 -------------------- */
	--
	/* -------------------- MODIFICACIONES --------------------
	|| CARRIERHOUSE RGUERRA - 13-04-2021 - 1.00
	|| Creacion
	|| Modificacion 23-04-2021, CARRIERHOUSE RGUERRA 
	*/ --------------------------------------------------------
	--
	-- parametros del reporte
	g_cod_cia          	a2000030.cod_cia%TYPE;
	g_cod_ramo			a2000030.cod_ramo%TYPE;
	g_num_poliza       	a2000030.num_poliza%TYPE;
	g_num_spto         	a2000030.num_spto%TYPE;
	g_num_riesgo       	a2501500.num_riesgo%TYPE;
	g_num_mov          	a2501600.num_mov%TYPE;
	g_spto_nulo         CHAR(1);
	--
	g_cod_error   		NUMBER;
	g_msg_error         VARCHAR2(4000);
  	--
	-- variables de error

	--
	-- globales para excel
	--
   	-- exceptiones
	e_init_proceso      EXCEPTION;
	e_init_variable		EXCEPTION;
	e_init_select_proc	EXCEPTION;	
	--
	-- devuelve error
	PROCEDURE p_devuelve_error( p_cod_error NUMBER, p_msg_error  VARCHAR2 ) IS 
	BEGIN 
		--
		trn_k_global.asigna('MCA_TER_TAR', 'N');
		--
		g_cod_error := p_cod_error;
		g_msg_error := p_msg_error;
		raise_application_error(g_cod_error, g_msg_error);
		--
	END p_devuelve_error;
	--
	-- Inicializa las variables
	PROCEDURE p_inicializar_variables
	IS 
	BEGIN
		--
		g_cod_cia    := trn_k_global.devuelve('JBCOD_CIA');
		g_num_poliza := trn_k_global.ref_f_global('JBNUM_POLIZA');
		g_num_spto   := trn_k_global.ref_f_global('JBNUM_SPTO');
		g_num_riesgo := trn_k_global.ref_f_global('JBNUM_RIESGO');
		g_num_mov    := trn_k_global.ref_f_global('JBNUM_MOV');
		--
		EXCEPTION
			WHEN others THEN
				-- dbms_output.put_line(sqlerrm);
				g_msg_error := SQLERRM;
				RAISE e_init_variable;   
			-- 
	END p_inicializar_variables;
	--
	PROCEDURE p_seleccionar_proceso IS 
	BEGIN 
		--
	 	IF g_num_spto IS NULL THEN
		    g_spto_nulo := 'S';
			g_num_spto := em_k_a2000030.f_max_spto(g_cod_cia, 
			                                        g_num_poliza, 
													NULL, 
													NULL, 
													NULL);
		ELSE
			g_spto_nulo := 'N';										
		END IF;
        --
		-- datos de la poliza
		em_k_a2000030.p_lee(g_cod_cia, g_num_poliza, g_num_spto, 0, 0);  
		g_cod_ramo := em_k_a2000030.f_cod_ramo;
		--
		IF g_cod_ramo = 200 THEN
			--
			ra_p_hoja_tec_200_mni(g_cod_cia,
			                      g_num_poliza,
								  g_num_spto,
								  g_num_riesgo,
								  g_num_mov,
								  g_spto_nulo);
			--
		ELSE 
			--
			ra_p_hoja_tec_XXX_mni(g_cod_cia,
			                      g_num_poliza,
								  g_num_spto,
								  g_num_riesgo,
								  g_num_mov,
								  g_spto_nulo); 	
			--
		END IF;
		--
		EXCEPTION
			WHEN others THEN
				--dbms_output.put_line(sqlerrm);
				g_msg_error := SQLERRM;
				RAISE e_init_select_proc;  
				--
	END p_seleccionar_proceso;
	--
BEGIN
	/*
	 * PRINCIPAL
	 */
	--
	-- indicador de proceso (TAREA)
	trn_k_global.asigna('MCA_TER_TAR', 'N');
	--
	-- inicializamos el proceso
	p_inicializar_variables;
	--
	-- seleccionamos el proceso a ejeutar
	p_seleccionar_proceso;
	--
	-- si todo resulto sin excepciones se termina la tarea
	trn_k_global.asigna('MCA_TER_TAR', 'S');
	--
	EXCEPTION
      	--
		WHEN e_init_variable THEN
      		--
			p_devuelve_error(-20002,
			                 '<ra_p_hoja_tec_reaseguro->Inicializando variables globales> ' ||
							 g_msg_error);
			--
		--
		WHEN e_init_select_proc THEN
      		--
			p_devuelve_error(-20003,
			                 '<ra_p_hoja_tec_reaseguro->Seleccionando proceso> ' ||
							 g_msg_error);
			--	
		WHEN others THEN
      		--
			p_devuelve_error(-20010, '<ra_p_hoja_tec_reaseguro> ' || sqlerrm);
			--
END ra_p_hoja_tec_reaseguro_mni;

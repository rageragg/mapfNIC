CREATE OR REPLACE PROCEDURE ts_p_obtiene_tramitador_mni(p_cod_cia             a1001339.cod_cia %TYPE,
                                                        p_cod_sector          a7001024_MNI.cod_sector %TYPE,
                                                        p_cod_ramo            a7001024_MNI.cod_ramo %TYPE,
                                                        p_num_poliza          a7001024_MNI.num_poliza %TYPE,
                                                        p_cod_nivel3          a1001339.cod_nivel3 %TYPE,
                                                        p_cod_tramitador_aper a1001339.cod_tramitador %TYPE,
                                                        p_tip_exp_aper        a7001024_MNI.tip_exp %TYPE,
                                                        p_cod_docum           IN OUT a1001339.cod_docum %TYPE,
                                                        p_tip_docum           IN OUT a1001339.tip_docum %TYPE,
                                                        p_cod_tramitador      IN OUT a1001339.cod_tramitador %TYPE
                                                       ) IS
    --
    /* -------------------- VERSION = 1.03 -------------------- */
    --
    /* -------------------- DESCRIPCION --------------------
    || Procedimiento obtencion del tramitador .
    || Tabla: A1001339
    || Se pasa el tramitador que esta abriendo el expediente por si no se quiere
    || modificar y en caso de querer modificarse se  Obtiene el tramitador con
    || menos carga de trabajo que haya para el sector,
    || o el ramo o la poliza o el expediente para la sucursal que estoy pasando.
    */ -----------------------------------------------------
    /* -------------------- MODIFICACIONES --------------------
    || JOHANNN   - 13/04/2009 - 1.03
    || Se modifican todos los queries para considerar cuando num_siniestros es
    || nulo.
    || Belen     - 02/04/2003 - 1.02
    || Modificado para que si el campo MAX_NUM_EXP es NULL, valide el n?mero de casos con 99999.
    || --
    || Maria     - 07/03/2003 - 1.01
    || Se incluye la condicion "and num_siniestros < max_num_exp" en
    || todos los accesos a la a1001339, a partir de ahora, ademas de
    || estar (A)ctivo, se le exigira esta condicion al tramitador.
    ||
    || Marta     - 29/04/2002
    || Creado para asignar los casos al tramitador directamente
    ||
    || MEGA SOFT - 20/10/2015 Version MNI
    || Se asigna tramitador dependiendo del primer expediente
    ||
    || MAPFRE Nicaragua - 06/06/2017 
    || Se realiza cambio para que se asigne el expediente al tramitrador que lo abre
    || en funcion de la marca asigna expediente de lo contrario ejecuta los criterios
    || de asiganacion
    ||
    || MAPFRE Nicaragua - 13/06/2017 
    || se asigna tramitador dependiendo del primer expediente
    || CARRIERHOUSE - 03/03/2021, RGUERRA
    || Se agrega nuevo criterio de seleccion de tramitador
    */ --------------------------------------------------------
    l_cod_mensaje g1010020.cod_mensaje%TYPE;
    l_txt_mensaje g1010020.txt_mensaje%TYPE;
    l_existe      BOOLEAN;
    l_hay_error EXCEPTION;
    l_contador NUMBER(5) := 0;
    --
    l_num_sini a7000900.num_sini%TYPE;
    --
    l_mca_asigna_esp VARCHAR2(1) := 'N';
    --
    l_comilla          char(1) := chr( 39 );
    l_max_spto         a2000030.num_spto%TYPE;
    l_cod_agt          a2000030.cod_agt%TYPE;
    l_num_poliza_grupo a2000030.num_poliza_grupo%TYPE;
    l_sql_stm          VARCHAR2(512) := 'SELECT COD_TRAMITADOR FROM A7001024_MNI WHERE ';
    --
    -- Cursor que permite armar las sentencias segun su prioridad
    CURSOR c_sentencias IS
        SELECT *
        FROM ( SELECT DISTINCT
                        DECODE( NVL(COD_CIA, 99), 99, 0, 1 ) COD_CIA,
                        DECODE( NVL(COD_SECTOR, 9999), 9999, 0, 2 ) COD_SECTOR,
                        DECODE( NVL(COD_RAMO, 999), 999, 0, 3 ) COD_RAMO,
                        DECODE( SUBSTR( NVL(NUM_POLIZA, '999999'), 0, 6), '999999', 0, 4 ) NUM_POLIZA,
                        DECODE( NVL(TIP_EXP, '999'), '999', 0, 5 ) TIP_EXP,
                        DECODE(SUBSTR( NVL(NUM_POLIZA_GRUPO, '999999'), 1,6), '999999', 0, 6 )  NUM_POLIZA_GRUPO, 
                        DECODE( NVL(COD_AGT, 999999), 999999, 0, 7 ) COD_AGT, 
                        DECODE( NVL(COD_NIVEL_TRAMITADOR, 9999), 9999, 0, 8 ) COD_NIVEL_TRAMITADOR,
                        (
                            DECODE( NVL(COD_CIA, 99), 99, 0, 1 ) +
                            DECODE( NVL(COD_SECTOR, 9999), 9999, 0, 2 ) +
                            DECODE( NVL(COD_RAMO, 999), 999, 0, 3 ) +
                            DECODE( SUBSTR( NVL(NUM_POLIZA, '999999'), 0, 6), '999999', 0, 4 ) +
                            DECODE( NVL(TIP_EXP, '999'), '999', 0, 5 ) +
                            DECODE( SUBSTR( NVL(NUM_POLIZA_GRUPO, '999999'), 1,6), '999999', 0, 6 ) + 
                            DECODE( NVL(COD_AGT, 999999), 999999, 0, 7 ) + 
                            DECODE( NVL(COD_NIVEL_TRAMITADOR, 9999), 9999, 0, 8 ) 
                        ) PRIORIDAD
                FROM A7001024_MNI
                WHERE COD_CIA = p_cod_cia
                ) 
            ORDER BY PRIORIDAD ASC;
    --  
    TYPE t_stm IS TABLE OF VARCHAR2(512);
    v_vector_especial  t_stm;
    v_vector_general   t_stm;
    v_campos_evaluar   t_stm;
    --
    c_criterio SYS_REFCURSOR;
    --
    -- Cuenta tramitadosres disponible por tipo de expediente
    CURSOR c_a1001339_tip_exp IS
        SELECT count(*)
          FROM a1001339 a
         WHERE a.cod_cia = p_cod_cia
           AND a.tip_estado = 'A'
           AND a.cod_nivel3 = p_cod_nivel3
           AND NVL(a.num_siniestros, 0) < NVL(a.max_num_exp, 99999)
           AND a.cod_tramitador IN
                (SELECT b.cod_tramitador
                    FROM a7001024_MNI b
                    WHERE b.cod_cia = a.cod_cia
                    AND b.cod_tramitador = a.cod_tramitador
                    AND b.tip_exp = p_tip_exp_aper
                );
    --
    -- Cuenta tramitadores disponibles por poliza
    CURSOR c_a1001339_num_poliza IS
        SELECT count(*)
          FROM a1001339 a
         WHERE a.cod_cia = p_cod_cia
           AND a.cod_nivel3 = p_cod_nivel3
           AND a.tip_estado = 'A'
           AND NVL(a.num_siniestros, 0) < NVL(a.max_num_exp, 99999)
           AND a.cod_tramitador IN
                (SELECT b.cod_tramitador
                    FROM a7001024_MNI b
                    WHERE b.cod_cia = a.cod_cia
                    AND b.cod_tramitador = a.cod_tramitador
                    AND b.num_poliza = p_num_poliza
                );
    --
    CURSOR c_a1001339_cod_ramo IS
        SELECT count(*)
          FROM a1001339 a
         WHERE a.cod_cia = p_cod_cia
           AND a.cod_tramitador IN
                (SELECT b.cod_tramitador
                    FROM a7001024_MNI b
                    WHERE b.cod_cia = a.cod_cia
                    AND b.cod_tramitador = a.cod_tramitador
                    AND b.cod_ramo = p_cod_ramo
                )
           AND a.cod_nivel3 = p_cod_nivel3
           AND a.tip_estado = 'A'
           AND NVL(a.num_siniestros, 0) < NVL(a.max_num_exp, 99999);
    --
    CURSOR c_a1001339_cod_sector IS
        SELECT count(*)
          FROM a1001339 a
         WHERE a.cod_cia = p_cod_cia
           AND a.cod_tramitador IN
                (SELECT b.cod_tramitador
                    FROM a7001024_MNI b
                    WHERE b.cod_cia = a.cod_cia
                    AND b.cod_tramitador = a.cod_tramitador
                    AND b.cod_sector = p_cod_sector
                )
           AND a.cod_nivel3 = p_cod_nivel3
           AND a.tip_estado = 'A'
           AND NVL(a.num_siniestros, 0) < NVL(a.max_num_exp, 99999);
    --     
    CURSOR c_a1001339_cod_tramitador IS
        SELECT a.tip_docum, a.cod_docum, a.cod_tramitador
          FROM a1001339 a
         WHERE a.cod_cia = p_cod_cia
           AND a.cod_nivel3 = p_cod_nivel3
           AND a.cod_tramitador NOT IN
                (SELECT b.cod_tramitador
                    FROM a7001024_MNI b
                    WHERE b.cod_cia = a.cod_cia
                    AND b.cod_tramitador = a.cod_tramitador
                )
           AND NVL(a.num_siniestros, 0) =
                (SELECT min(NVL(c.num_siniestros, 0))
                    FROM a1001339 c
                    WHERE c.cod_cia = p_cod_cia
                    AND c.cod_nivel3 = p_cod_nivel3
                    AND c.cod_tramitador NOT IN
                        (SELECT d.cod_tramitador
                            FROM a7001024_MNI d
                            WHERE d.cod_cia = c.cod_cia
                            AND d.cod_tramitador = c.cod_tramitador
                        )
                    AND c.tip_estado = 'A'
                    AND NVL(c.num_siniestros, 0) < NVL(c.max_num_exp, 99999)
                )
           AND a.tip_estado = 'A'
           AND NVL(a.num_siniestros, 0) < NVL(a.max_num_exp, 99999);
    --
    CURSOR c_a1001339_tramitador_exp IS
        SELECT a.tip_docum, a.cod_docum, a.cod_tramitador
          FROM a1001339 a
         WHERE a.cod_cia = p_cod_cia
           AND a.cod_tramitador IN
                (SELECT b.cod_tramitador
                    FROM a7001024_MNI b
                    WHERE b.cod_cia = a.cod_cia
                    AND b.cod_tramitador = a.cod_tramitador
                    AND b.tip_exp = p_tip_exp_aper
                )
           AND a.cod_nivel3 = p_cod_nivel3
           AND NVL(a.num_siniestros, 0) =
                (SELECT min(NVL(c.num_siniestros, 0))
                    FROM a1001339 c
                    WHERE c.cod_cia = p_cod_cia
                    AND c.cod_tramitador IN
                        (SELECT d.cod_tramitador
                            FROM a7001024_MNI d
                            WHERE d.cod_cia = c.cod_cia
                            AND d.cod_tramitador = c.cod_tramitador
                            AND d.tip_exp = p_tip_exp_aper)
                    AND c.cod_nivel3 = p_cod_nivel3
                    AND c.tip_estado = 'A'
                    AND NVL(c.num_siniestros, 0) < NVL(c.max_num_exp, 99999)
                )
           AND a.tip_estado = 'A'
           AND NVL(a.num_siniestros, 0) < NVL(a.max_num_exp, 99999);
    --
    CURSOR c_a1001339_tramitador_poliza IS
        SELECT a.tip_docum, a.cod_docum, a.cod_tramitador
          FROM a1001339 a
         WHERE a.cod_cia = p_cod_cia
           AND a.cod_tramitador IN
                (SELECT b.cod_tramitador
                    FROM a7001024_MNI b
                    WHERE b.cod_cia = a.cod_cia
                    AND b.cod_tramitador = a.cod_tramitador
                    AND b.num_poliza = p_num_poliza
                )
           AND a.cod_nivel3 = p_cod_nivel3
           AND NVL(a.num_siniestros, 0) =
                (SELECT min(NVL(c.num_siniestros, 0))
                    FROM a1001339 c
                    WHERE c.cod_cia = p_cod_cia
                    AND c.cod_tramitador IN
                        (SELECT d.cod_tramitador
                            FROM a7001024_MNI d
                            WHERE d.cod_cia = c.cod_cia
                            AND d.cod_tramitador = c.cod_tramitador
                            AND d.num_poliza = p_num_poliza)
                    AND c.cod_nivel3 = p_cod_nivel3
                    AND c.tip_estado = 'A'
                    AND NVL(c.num_siniestros, 0) < NVL(c.max_num_exp, 99999)
                )
           AND a.tip_estado = 'A'
           AND NVL(a.num_siniestros, 0) < NVL(a.max_num_exp, 99999);
    --
    CURSOR c_a1001339_tramitador_ramo IS
        SELECT a.tip_docum, a.cod_docum, a.cod_tramitador
          FROM a1001339 a
         WHERE a.cod_cia = p_cod_cia
           AND a.cod_tramitador IN
                (SELECT b.cod_tramitador
                    FROM a7001024_MNI b
                    WHERE b.cod_cia = a.cod_cia
                    AND b.cod_tramitador = a.cod_tramitador
                    AND b.cod_ramo = p_cod_ramo
                )
           AND a.cod_nivel3 = p_cod_nivel3
           AND NVL(a.num_siniestros, 0) =
                (SELECT min(NVL(c.num_siniestros, 0))
                    FROM a1001339 c
                    WHERE c.cod_cia = p_cod_cia
                    AND c.cod_tramitador IN
                        (SELECT d.cod_tramitador
                            FROM a7001024_MNI d
                            WHERE d.cod_cia = c.cod_cia
                            AND d.cod_tramitador = c.cod_tramitador
                            AND d.cod_ramo = p_cod_ramo)
                    AND c.cod_nivel3 = p_cod_nivel3
                    AND c.tip_estado = 'A'
                    AND NVL(c.num_siniestros, 0) < NVL(c.max_num_exp, 99999)
                )
           AND a.tip_estado = 'A'
           AND NVL(a.num_siniestros, 0) < NVL(a.max_num_exp, 99999);
    --     
    CURSOR c_a1001339_tramitador_sector IS
        SELECT a.tip_docum, a.cod_docum, a.cod_tramitador
          FROM a1001339 a
         WHERE a.cod_cia = p_cod_cia
           AND a.cod_tramitador IN
                (SELECT b.cod_tramitador
                    FROM a7001024_MNI b
                    WHERE b.cod_cia = a.cod_cia
                    AND b.cod_tramitador = a.cod_tramitador
                    AND b.cod_sector = p_cod_sector
                )
           AND a.cod_nivel3 = p_cod_nivel3
           AND NVL(a.num_siniestros, 0) =
                (SELECT min(NVL(c.num_siniestros, 0))
                    FROM a1001339 c
                    WHERE c.cod_cia = p_cod_cia
                    AND c.cod_tramitador IN
                        (SELECT d.cod_tramitador
                            FROM a7001024_MNI d
                            WHERE d.cod_cia = c.cod_cia
                            AND d.cod_tramitador = c.cod_tramitador
                            AND d.cod_sector = p_cod_sector)
                    AND c.cod_nivel3 = p_cod_nivel3
                    AND c.tip_estado = 'A'
                    AND NVL(c.num_siniestros, 0) < NVL(c.max_num_exp, 99999)
                )
           AND a.tip_estado = 'A'
           AND NVL(a.num_siniestros, 0) < NVL(a.max_num_exp, 99999);

    --
    -- RGUERRA 03/03/2021
    -- Devuelve la cantidad de sentencias posibles
    FUNCTION fp_cantidad_sentencia RETURN NUMBER IS
      --
      l_retult NUMBER := 0;
      --
    BEGIN
        --
        SELECT count(1) 
            INTO l_retult
            FROM A7001024_MNI
        WHERE COD_CIA = p_cod_cia;
        --
        RETURN l_retult;
        --
    END fp_cantidad_sentencia;   
    --
    -- RGUERRA 03/03/2021
    -- Formatear Sentencia
    FUNCTION fp_formato_stm( p_campo        VARCHAR2, 
                             p_tipo         CHAR DEFAULT 'C'
                           ) RETURN VARCHAR2 IS
        --
        l_result VARCHAR2(512);
        l_tipo   CHAR(1) := upper(p_tipo);
        --
    BEGIN 
        --
        IF l_tipo ='C' THEN
            l_result := ' = '||l_comilla||p_campo||l_comilla;
        ELSIF l_tipo = 'N' THEN
            l_result := ' = '||p_campo;
        END IF;  
        --
        RETURN l_result;
        --
    END fp_formato_stm;
    --
    -- Inicializa Vector de Campos
    PROCEDURE pp_init_vector_campos( p_cod_agt          a7001024_mni.cod_agt%TYPE,
                                     p_num_poliza_grupo a7001024_mni.num_poliza_grupo%TYPE
                                   ) IS 
    BEGIN 
        --
        -- vecotrs de campo
        v_campos_evaluar  := t_stm();
        v_campos_evaluar.extend(8);
        v_campos_evaluar(1) := 'COD_CIA '||fp_formato_stm(p_cod_cia, 'N');
        --
    END pp_init_vector_campos;
    --
    -- RGUERRA 03/03/2021
    -- Procedimiento que toma los datos de la poliza
    PROCEDURE pp_datos_poliza IS 
    BEGIN 
        -- max suplemento
        l_max_spto := em_k_a2000030_trn.f_max_spto( p_cod_cia, p_num_poliza, null, null, null );
        -- buscamos los datos de la poliza
        em_k_a2000030_trn.p_lee( p_cod_cia, p_num_poliza, l_max_spto,  0, 0);
        l_cod_agt          := em_k_a2000030_trn.f_cod_agt;
        l_num_poliza_grupo := em_k_a2000030_trn.f_num_poliza_grupo;
        --
    END pp_datos_poliza;
    --
    -- RGUERRA 03/03/2021
    -- Procedimiento para inicializar el vector de sentencias
    -- para el cursor dinamico
    PROCEDURE pp_init_vectores_stm( p_cod_agt          a7001024_mni.cod_agt%TYPE,
                                    p_num_poliza_grupo a7001024_mni.num_poliza_grupo%TYPE
                                  ) IS
        --
        i           NUMBER := 1;
        l_cant_smt  NUMBER := fp_cantidad_sentencia;
        l_stm_act   VARCHAR2(512);
        l_stm_aNT   VARCHAR2(512);
        --
    BEGIN
        -- Inicializamos el vector de campo para las sentencias
         pp_init_vector_campos(p_cod_agt, p_num_poliza_grupo );
        --
        IF l_cant_smt > 0 THEN
            --
            v_vector_general := t_stm();
            l_stm_act := NULL;
            l_stm_ant := NULL;
            --
            FOR v_sentencias IN c_sentencias  LOOP
                --
                v_vector_general.EXTEND;
                IF v_sentencias.COD_CIA <> 0 THEN
                    l_stm_act := v_campos_evaluar(1);
                END IF;
                --
                IF v_sentencias.COD_SECTOR <> 0 THEN
                    IF l_stm_act IS NOT NULL THEN
                        IF p_cod_sector IS NULL THEN
                            v_campos_evaluar(2) := 'COD_SECTOR <> COD_SECTOR';
                        ELSE
                            v_campos_evaluar(2) := 'COD_SECTOR '||fp_formato_stm(p_cod_sector, 'N');
                        END IF;    
                        l_stm_act := l_stm_act||' AND '|| v_campos_evaluar(2);
                    END IF;  
                END IF;
                --
                IF v_sentencias.COD_RAMO <> 0 THEN
                    IF l_stm_act IS NOT NULL THEN
                        IF p_cod_sector IS NULL THEN
                            v_campos_evaluar(3) := 'COD_RAMO <> COD_RAMO';
                        ELSE
                            v_campos_evaluar(3) := 'COD_RAMO '||fp_formato_stm(p_cod_ramo, 'N');
                        END IF;    
                        l_stm_act := l_stm_act||' AND '|| v_campos_evaluar(3);
                    END IF;  
                END IF;
                --
                IF v_sentencias.NUM_POLIZA <> 0 THEN
                    IF l_stm_act IS NOT NULL THEN
                        IF p_num_poliza IS NULL THEN
                            v_campos_evaluar(4) := 'NUM_POLIZA <> NUM_POLIZA ';
                        ELSE
                            v_campos_evaluar(4) := 'NUM_POLIZA '||fp_formato_stm(p_num_poliza, 'C');
                        END IF;    
                        l_stm_act := l_stm_act||' AND '|| v_campos_evaluar(4);
                    END IF;  
                END IF;
                --
                IF v_sentencias.TIP_EXP <> 0 THEN
                    IF l_stm_act IS NOT NULL THEN
                        IF p_tip_exp_aper IS NULL THEN 
                             v_campos_evaluar(5) := 'TIP_EXP <> TIP_EXP';
                        ELSE
                            v_campos_evaluar(5) := 'TIP_EXP '||fp_formato_stm(p_tip_exp_aper, 'C');
                        END IF;    
                        l_stm_act := l_stm_act||' AND '|| v_campos_evaluar(5);
                    END IF;  
                END IF;
                --
                IF v_sentencias.NUM_POLIZA_GRUPO <> 0 THEN
                    IF l_stm_act IS NOT NULL THEN
                        IF p_num_poliza_grupo IS NULL THEN  
                            v_campos_evaluar(6) := 'NUM_POLIZA_GRUPO <> NUM_POLIZA_GRUPO ';
                        ELSE
                            v_campos_evaluar(6) := 'NUM_POLIZA_GRUPO '||fp_formato_stm(p_num_poliza_grupo, 'C');
                        END IF;     
                        l_stm_act := l_stm_act||' AND '|| v_campos_evaluar(6);
                    END IF;  
                END IF;
                --
                IF v_sentencias.COD_AGT <> 0 THEN
                    IF l_stm_act IS NOT NULL THEN
                        IF p_cod_agt IS NULL THEN
                           v_campos_evaluar(7) := 'COD_AGT <> COD_AGT'; 
                        ELSE
                           v_campos_evaluar(7) := 'COD_AGT '||fp_formato_stm(p_cod_agt, 'N');
                        END IF;
                        l_stm_act := l_stm_act||' AND '|| v_campos_evaluar(7);
                    END IF;  
                END IF;
                --
                IF v_sentencias.COD_NIVEL_TRAMITADOR <> 0 THEN
                    IF l_stm_act IS NOT NULL THEN
                        IF p_cod_nivel3 IS NULL THEN
                            v_campos_evaluar(8) := 'COD_NIVEL_TRAMITADOR <> COD_NIVEL_TRAMITADOR';
                        ELSE
                            v_campos_evaluar(8) := 'COD_NIVEL_TRAMITADOR '||fp_formato_stm(p_cod_nivel3, 'N');
                        END IF;
                        l_stm_act := l_stm_act||' AND '|| v_campos_evaluar(8);
                    END IF;  
                END IF;
                --
                IF NVL(l_stm_act,'STM') != NVL(l_stm_ant,'STM') THEN
                    v_vector_general(v_vector_general.COUNT) := l_stm_act;
                    l_stm_ant := l_stm_act;
                    l_stm_act := NULL;
                ELSE
                    v_vector_general(v_vector_general.COUNT) := '*';
                END IF;    
                --
            END LOOP;
            --
        END IF;
        --   
    END pp_init_vectores_stm;
    --
    -- RGUERRA 03/03/2021
    -- Function que devuelve la sentecia segun la prioridad especial de ejecucion
    FUNCTION pp_determinar_tramitador RETURN NUMBER IS
        --
        l_encontrado    BOOLEAN := FALSE;
        l_sql_ejecutado VARCHAR2(512);
        --
    BEGIN
        -- vector principal
        FOR i IN REVERSE 1..v_vector_general.count LOOP
            --
            dbms_output.put_line('Ejecutando:' ||l_sql_stm||v_vector_general(i));
            --
            IF v_vector_general(i) != '*' THEN
                p_cod_tramitador := p_cod_tramitador_aper;
                --
                OPEN c_criterio for l_sql_stm||v_vector_general(i);
                FETCH c_criterio INTO p_cod_tramitador;
                l_encontrado := c_criterio%FOUND;
                --
                IF l_encontrado THEN
                    --
                    l_sql_ejecutado := l_sql_stm||v_vector_general(i);
                    --
                END IF;
                --
                CLOSE c_criterio;
                EXIT WHEN l_encontrado;
                --
            END IF;  
            --
        END LOOP;  
        --
        dbms_output.put_line('SQL:' ||l_sql_ejecutado);
        --
        RETURN NVL(p_cod_tramitador,p_cod_tramitador_aper);
        --
    END pp_determinar_tramitador;
    --
    -- RGUERRA 03/03/2021
    -- Procedimiento que toma los datos del siniestro
    PROCEDURE pp_datos_siniestro IS 
    BEGIN 
        --
        ts_k_a7001000.p_lee_a7001000( p_cod_cia  => p_cod_cia,
                                      p_num_sini => l_num_sini,
                                      p_num_exp  => 1 -- Expediente inicial
                                     ); 
        --
        p_cod_tramitador := ts_k_a7001000.f_cod_tramitador;
        --
        ts_k_a1001339.p_lee_cod_tramitador(p_cod_cia, p_cod_tramitador_aper);
        --
        p_tip_docum := ts_k_a1001339.f_tip_docum;
        p_cod_docum := ts_k_a1001339.f_cod_docum;
        --
        EXCEPTION
            WHEN OTHERS THEN
            p_cod_tramitador := NULL;
            --
    END pp_datos_siniestro;
    --
    -- RGUERRA 03/03/2021
    -- Procedimiento que toma los datos de Tramitador
    PROCEDURE pp_datos_tramitador( p_tramitador a1001339.cod_tramitador %TYPE) IS 
    BEGIN
        --
        ts_k_a1001339.p_lee_cod_tramitador(p_cod_cia, p_tramitador);
        --
        p_tip_docum      := ts_k_a1001339.f_tip_docum;
        p_cod_docum      := ts_k_a1001339.f_cod_docum;
        p_cod_tramitador := p_tramitador;
        --
        EXCEPTION
            WHEN OTHERS THEN
                dbms_output.put_line('pp_datos_tramitador: ' || sqlerrm);
                l_existe := FALSE;
            --
    END pp_datos_tramitador;
    --
BEGIN
    --
    -- busca la configuracion
    ss_k_g1010107.p_lee('DEFECTO', 'DEFECTO', 'MCA_ASIGNA_ESP');
    l_mca_asigna_esp := ss_k_g1010107.f_txt_valor_variable;
    --
    -- determina el numero de siniestro
    l_num_sini       := trn_k_global.devuelve('NUM_SINI');
    --
    -- Seleccionamos los datos del siniestro
    pp_datos_siniestro;
    --
    IF l_mca_asigna_esp = 'N' THEN
        --
        IF p_cod_tramitador IS NULL THEN
            --
            -- Se mira si para la oficina tramitadora hay algun tramitador que tramite ese tipo de expediente
            OPEN c_a1001339_tip_exp;
            FETCH c_a1001339_tip_exp INTO l_contador;
            l_existe := c_a1001339_tip_exp%found;
            CLOSE c_a1001339_tip_exp;
            --
            IF l_contador > 0 THEN
                --
                OPEN c_a1001339_tramitador_exp;
                FETCH c_a1001339_tramitador_exp INTO p_tip_docum, p_cod_docum, p_cod_tramitador;
                l_existe := c_a1001339_tramitador_exp%found;
                CLOSE c_a1001339_tramitador_exp;
                --
            ELSE
                --
                OPEN c_a1001339_num_poliza;
                FETCH c_a1001339_num_poliza INTO l_contador;
                l_existe := c_a1001339_num_poliza%found;
                CLOSE c_a1001339_num_poliza;
                --
                IF l_contador > 0 THEN
                    --
                    OPEN c_a1001339_tramitador_poliza;
                    FETCH c_a1001339_tramitador_poliza INTO p_tip_docum, p_cod_docum, p_cod_tramitador;
                    l_existe := c_a1001339_tramitador_poliza%found;
                    CLOSE c_a1001339_tramitador_poliza;
                    --
                ELSE
                    --
                    l_contador := 0;
                    OPEN c_a1001339_cod_ramo;
                    FETCH c_a1001339_cod_ramo INTO l_contador;
                    l_existe := c_a1001339_cod_ramo%found;
                    CLOSE c_a1001339_cod_ramo;
                    --
                    IF l_contador > 0 THEN
                        --
                        OPEN c_a1001339_tramitador_ramo;
                        FETCH c_a1001339_tramitador_ramo INTO p_tip_docum, p_cod_docum, p_cod_tramitador;
                        l_existe := c_a1001339_tramitador_ramo%found;
                        CLOSE c_a1001339_tramitador_ramo;
                        --
                    ELSE
                        --
                        l_contador := 0;
                        OPEN c_a1001339_cod_sector;
                        FETCH c_a1001339_cod_sector INTO l_contador;
                        l_existe := c_a1001339_cod_sector%found;
                        --
                        CLOSE c_a1001339_cod_sector;
                        --
                        IF l_contador > 0 THEN
                            --
                            OPEN c_a1001339_tramitador_sector;
                            FETCH c_a1001339_tramitador_sector INTO p_tip_docum, p_cod_docum, p_cod_tramitador;
                            l_existe := c_a1001339_tramitador_sector%found;
                            CLOSE c_a1001339_tramitador_sector;
                            --
                        ELSE
                            --
                            OPEN c_a1001339_cod_tramitador;
                            FETCH c_a1001339_cod_tramitador INTO p_tip_docum, p_cod_docum, p_cod_tramitador;
                            l_existe := c_a1001339_cod_tramitador%found;
                            CLOSE c_a1001339_cod_tramitador;
                            --
                        END IF;
                        --
                    END IF;
                    --
                END IF;
            --
            END IF;
            --
        END IF;
        --
    ELSE
        --
        -- Seleccionamos los datos de la poliza
        pp_datos_poliza;
        --
        -- Inicializamos el vector de sentencias
        pp_init_vectores_stm(l_cod_agt, l_num_poliza_grupo );
        --
        -- Realizamos la nueva evaluacion
        p_cod_tramitador := pp_determinar_tramitador;
        IF p_cod_tramitador IS NULL THEN
            -- Si no se logra determinar el tramitador se evalua por defecto
            pp_datos_tramitador(p_cod_tramitador_aper);
        ELSE
            pp_datos_tramitador(p_cod_tramitador); 
        END IF;
        --
    END IF;
    --     
    IF NOT l_existe THEN
        --
        l_cod_mensaje := 20001; -- CODIGO INEXISTENTE
        l_txt_mensaje := ss_f_mensaje(l_cod_mensaje);
        l_txt_mensaje := l_txt_mensaje;
        RAISE l_hay_error;
        --
    END IF;
    --
    EXCEPTION
        WHEN l_hay_error THEN
        RAISE_APPLICATION_ERROR(-l_cod_mensaje, l_txt_mensaje);
        --
END ts_p_obtiene_tramitador_mni;

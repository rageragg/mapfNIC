declare
    --
    p_cod_cia             a7001024_mni.cod_cia %TYPE         := 4;
    p_cod_sector          a7001024_mni.cod_sector %TYPE      := 3;
    p_cod_ramo            a7001024_mni.cod_ramo %TYPE        := 301;
    p_cod_nivel3          a1001339.cod_nivel3 %TYPE          := 1001;
    p_tip_exp_aper        a7001024_mni.tip_exp%TYPE          := 'RDV';
    p_cod_agt             a7001024_mni.cod_agt%TYPE          := 319791; 
    p_num_poliza_grupo    a7001024_mni.num_poliza_grupo%TYPE := '3010002';
    p_num_poliza          a7001024_mni.num_poliza %TYPE      := '3011001600274';
    p_cod_tramitador_aper a1001339.cod_tramitador %TYPE      := 14;
    --
    p_cod_docum           a1001339.cod_docum %TYPE;
    p_tip_docum           a1001339.tip_docum %TYPE;
    p_cod_tramitador      a1001339.cod_tramitador%TYPE; 
    --
    l_comilla   char(1) := chr( 39 );
    --
    CURSOR c_sentencias
    IS
    SELECT *
      FROM ( SELECT DISTINCT
              DECODE( NVL(COD_CIA, 99), 99, 0, 1 ) COD_CIA,
              DECODE( NVL(COD_SECTOR, 9999), 9999, 0, 2 ) COD_SECTOR,
              DECODE( NVL(COD_RAMO, 999), 999, 0, 3 ) COD_RAMO,
              DECODE( NVL(NUM_POLIZA, '9999999999999'), '9999999999999', 0, 4 ) NUM_POLIZA,
              DECODE( NVL(TIP_EXP, '999'), '999', 0, 5 ) TIP_EXP,
              DECODE( NVL(NUM_POLIZA_GRUPO, '9999999999999'), '9999999999999', 0, 6 )  NUM_POLIZA_GRUPO, 
              DECODE( NVL(COD_AGT, 999999), 999999, 0, 7 ) COD_AGT, 
              DECODE( NVL(COD_NIVEL_TRAMITADOR, 9999), 9999, 0, 8 ) COD_NIVEL_TRAMITADOR,
              (
                  DECODE( NVL(COD_CIA, 99), 99, 0, 1 ) +
                  DECODE( NVL(COD_SECTOR, 9999), 9999, 0, 2 ) +
                  DECODE( NVL(COD_RAMO, 999), 999, 0, 3 ) +
                  DECODE( NVL(NUM_POLIZA, '9999999999999'), '9999999999999', 0, 4 ) +
                  DECODE( NVL(TIP_EXP, '999'), '999', 0, 5 ) +
                  DECODE( NVL(NUM_POLIZA_GRUPO, '9999999999999'), '9999999999999', 0, 6 ) + 
                  DECODE( NVL(COD_AGT, 999999), 999999, 0, 7 ) + 
                  DECODE( NVL(COD_NIVEL_TRAMITADOR, 9999), 9999, 0, 8 ) 
              ) PRIORIDAD
          FROM A7001024_MNI
        WHERE COD_CIA = p_cod_cia
      ) 
      ORDER BY PRIORIDAD ASC;
    --
    TYPE t_stm IS TABLE OF VARCHAR2(512);
    v_vector_principal t_stm;
    v_vector_especial  t_stm;
    v_campos_evaluar   t_stm;
    v_vector_general   t_stm;
    --
    c_criterio SYS_REFCURSOR;
    --
    -- Devuelve la cantidad de sentencias posibles
    FUNCTION fp_cantidad_sentencia RETURN NUMBER
    IS
      l_retult NUMBER := 0;
    BEGIN
      --
      SELECT count(1)
        INTO l_retult
        FROM A7001024_MNI
       WHERE COD_CIA = p_cod_cia;
       --
      RETURN l_retult;
    END fp_cantidad_sentencia;
    -- 
    -- formatea los campos de la consulta
    FUNCTION fp_formato_stm(p_campo VARCHAR2, 
                            p_tipo CHAR DEFAULT 'C',
                            p_obligatorio BOOLEAN DEFAULT FALSE) RETURN VARCHAR2
    IS 
      l_result VARCHAR2(512);
      l_tipo   CHAR(1) := upper(p_tipo);
    BEGIN 
      IF p_campo IS NULL THEN
        IF p_obligatorio THEN
          l_result := 'IS NOT NULL';
        ELSE
          l_result := 'IS NULL';
        END IF;
      ELSE
        IF l_tipo ='C' THEN
           l_result := ' = '||l_comilla||p_campo||l_comilla;
        ELSIF l_tipo = 'N' THEN
           l_result := ' = '||p_campo;
        END IF;   
      END IF;
      RETURN l_result;
    END fp_formato_stm;
    --
    PROCEDURE pp_init_vectores_stm
    IS
      i          NUMBER := 1;
      l_idx      NUMBER := 0;
      l_cant_smt NUMBER := fp_cantidad_sentencia;
      l_stm_act  VARCHAR2(512);
      l_stm_aNT  VARCHAR2(512);
    BEGIN
      -- vecotrs de campo
      v_campos_evaluar  := t_stm();
      v_campos_evaluar.extend(8);
      v_campos_evaluar(1) := 'COD_CIA '||fp_formato_stm(p_cod_cia, 'N',  TRUE);
      v_campos_evaluar(2) := 'COD_SECTOR '||fp_formato_stm(p_cod_sector, 'N',  TRUE);
      v_campos_evaluar(3) := 'COD_RAMO '||fp_formato_stm(p_cod_ramo, 'N',  TRUE);
      v_campos_evaluar(4) := 'NUM_POLIZA '||fp_formato_stm(p_num_poliza, 'C',  TRUE);
      v_campos_evaluar(5) := 'TIP_EXP '||fp_formato_stm(p_tip_exp_aper, 'C',  TRUE);
      v_campos_evaluar(6) := 'NUM_POLIZA_GRUPO '||fp_formato_stm(p_num_poliza_grupo, 'C',  TRUE);
      v_campos_evaluar(7) := 'COD_AGT '||fp_formato_stm(p_cod_agt, 'N',  TRUE);
      v_campos_evaluar(8) := 'COD_NIVEL_TRAMITADOR '||fp_formato_stm(p_cod_nivel3, 'N',  TRUE);
      --
      IF l_cant_smt > 0 THEN
        v_vector_general := t_stm();
        l_stm_act := NULL;
        l_stm_ant := NULL;
        FOR v_sentencias IN c_sentencias
        LOOP
          v_vector_general.EXTEND;
          IF v_sentencias.COD_CIA <> 0 THEN
            l_stm_act := v_campos_evaluar(1);
          END IF;
          --
          IF v_sentencias.COD_SECTOR <> 0 THEN
            IF l_stm_act IS NOT NULL THEN
              l_stm_act := l_stm_act||' AND '|| v_campos_evaluar(2);
            END IF;  
          END IF;
          --
          IF v_sentencias.COD_RAMO <> 0 THEN
            IF l_stm_act IS NOT NULL THEN
              l_stm_act := l_stm_act||' AND '|| v_campos_evaluar(3);
            END IF;  
          END IF;
          --
          IF v_sentencias.NUM_POLIZA <> 0 THEN
            IF l_stm_act IS NOT NULL THEN
              l_stm_act := l_stm_act||' AND '|| v_campos_evaluar(4);
            END IF;  
          END IF;
          --
          IF v_sentencias.TIP_EXP <> 0 THEN
            IF l_stm_act IS NOT NULL THEN
              l_stm_act := l_stm_act||' AND '|| v_campos_evaluar(5);
            END IF;  
          END IF;
          --
          IF v_sentencias.NUM_POLIZA_GRUPO <> 0 THEN
            IF l_stm_act IS NOT NULL THEN
              l_stm_act := l_stm_act||' AND '|| v_campos_evaluar(6);
            END IF;  
          END IF;
          --
          IF v_sentencias.COD_AGT <> 0 THEN
            IF l_stm_act IS NOT NULL THEN
              l_stm_act := l_stm_act||' AND '|| v_campos_evaluar(7);
            END IF;  
          END IF;
          --
          IF v_sentencias.COD_NIVEL_TRAMITADOR <> 0 THEN
            IF l_stm_act IS NOT NULL THEN
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
      END IF;
      -- vector de sentencias
      v_vector_principal := t_stm();
      v_vector_principal.extend(8);
      v_vector_principal(i) := 'COD_CIA = '||p_cod_cia||' AND '||'COD_SECTOR = '||p_cod_sector||' AND '||'COD_RAMO = '||p_cod_ramo;
      i := i + 1;
      v_vector_principal(i) := v_vector_principal(i-1)||' AND COD_NIVEL_TRAMITADOR = '||p_cod_nivel3;
      i := i + 1;
      v_vector_principal(i) := v_vector_principal(i-1)||' AND TIP_EXP = '||l_comilla||p_tip_exp_aper||l_comilla;
      i := i + 1;
      v_vector_principal(i) := v_vector_principal(i-1)||' AND '||'COD_AGT = '||p_cod_agt;
      i := i + 1;
      v_vector_principal(i) := v_vector_principal(2)||' AND '||'COD_AGT = '||p_cod_agt;
      i := i + 1;
      v_vector_principal(i) := v_vector_principal(i-1)||' AND '||'NUM_POLIZA_GRUPO = '||l_comilla||p_num_poliza_grupo||l_comilla;
      i := i + 1;
      v_vector_principal(i) := v_vector_principal(2)||' AND TIP_EXP = '||l_comilla||p_tip_exp_aper||l_comilla||' AND '||'NUM_POLIZA_GRUPO = '||l_comilla||p_num_poliza_grupo||l_comilla;
      i := i + 1;
      v_vector_principal(i) := v_vector_principal(i-1)||' AND '||'NUM_POLIZA = '||l_comilla||p_num_poliza||l_comilla;
      --
      -- Especiales
      v_vector_especial := t_stm();
      v_vector_especial.extend(2);
      i := 1;
      v_vector_especial(i) := v_vector_principal(2)||' AND '||'COD_AGT = '||p_cod_agt;
      i := i + 1;
      v_vector_especial(i) := v_vector_principal(2)||' AND TIP_EXP = '||l_comilla||p_tip_exp_aper||l_comilla||' AND '||'NUM_POLIZA_GRUPO = '||l_comilla||p_num_poliza_grupo||l_comilla;
   
    END pp_init_vectores_stm;
    --
    -- Verifica
    FUNCTION fp_stm_nivel_principal( p_nivel NUMBER ) RETURN VARCHAR2
    IS
      l_stm VARCHAR2(512) := 'COD_CIA IS NULL';
    BEGIN
      IF p_nivel >= 1 and p_nivel <= v_vector_principal.count THEN
        l_stm := v_vector_principal(p_nivel);
      END IF;
      --
      RETURN l_stm;
    END fp_stm_nivel_principal;
    --
    FUNCTION fp_stm_nivel_especial( p_nivel NUMBER ) RETURN VARCHAR2
    IS
      l_stm VARCHAR2(512) := 'COD_CIA IS NULL';
    BEGIN
      IF p_nivel >= 1 and p_nivel <= v_vector_especial.count THEN
        l_stm := v_vector_especial(p_nivel);
      END IF;
      --
      RETURN l_stm;
    END fp_stm_nivel_especial;
    --
    FUNCTION pp_determinar_tramitador RETURN NUMBER
    IS
      l_encontrado BOOLEAN := FALSE;
    BEGIN
      -- vector principal
      FOR i IN REVERSE 2..v_vector_general.count
      LOOP
          IF v_vector_general(i) != '*' THEN
            dbms_output.put_line( 'Principal sql : '||I||' '||v_vector_general(i) );
            p_cod_tramitador := p_cod_tramitador_aper;
            OPEN c_criterio for 'SELECT COD_TRAMITADOR FROM A7001024_MNI WHERE '||v_vector_general(i);
            FETCH c_criterio INTO p_cod_tramitador;
            l_encontrado := c_criterio%FOUND;
            CLOSE c_criterio;
            EXIT WHEN l_encontrado;
          END IF;  
      END LOOP; 
      --
      IF NOT l_encontrado THEN
        -- vector especial
        FOR i IN REVERSE 1..v_vector_especial.count
        LOOP
            dbms_output.put_line( 'Especial sql : '||I||' '||fp_stm_nivel_especial(i) );
            p_cod_tramitador := null;
            OPEN c_criterio for 'SELECT COD_TRAMITADOR FROM A7001024_MNI WHERE '||fp_stm_nivel_especial(i);
            FETCH c_criterio INTO p_cod_tramitador;
            l_encontrado := c_criterio%FOUND;
            CLOSE c_criterio;
            EXIT WHEN l_encontrado;
        END LOOP; 
      END IF;  
      --
      RETURN NVL(p_cod_tramitador,p_cod_tramitador_aper);
      --
    END pp_determinar_tramitador;
    --
BEGIN
  pp_init_vectores_stm;
  dbms_output.put_line( pp_determinar_tramitador );
END;
declare
   p_cod_docum        a1001339.cod_docum %TYPE;
   p_tip_docum        a1001339.tip_docum %TYPE;
   p_cod_tramitador   a1001339.cod_tramitador %TYPE;
   --
    TYPE t_tramitador IS TABLE OF VARCHAR2(30);
    lt_tramitador t_tramitador;
   --
   CURSOR c_tramitadores
   IS
   SELECT a.tip_docum, a.cod_docum, a.cod_tramitador,
      CURSOR(SELECT CAST(b.ROWID AS VARCHAR2(30))
              FROM a7001024 b
             WHERE b.cod_cia = a.cod_cia
               AND b.cod_tramitador = a.cod_tramitador
             ) list 
      FROM a1001339 a
     WHERE a.cod_cia = 4
       AND a.cod_nivel3 = 1001
       AND a.tip_estado = 'A'
       AND NVL(a.num_siniestros, 0) < NVL(a.max_num_exp, 99999);
       
  l_lst SYS_REFCURSOR;
  
BEGIN
  OPEN c_tramitadores;
  FETCH c_tramitadores INTO p_tip_docum, p_cod_docum, p_cod_tramitador, l_lst;
  LOOP
    EXIT WHEN c_tramitadores%NOTFOUND;
    dbms_output.put_line(p_tip_docum||', '||p_cod_docum||', '||p_cod_tramitador);
    FETCH l_lst BULK COLLECT INTO lt_tramitador; 
    IF NVL(lt_tramitador.COUNT,0) > 0 THEN
       FOR i IN 1..lt_tramitador.COUNT 
       LOOP
          dbms_output.put_line('Tramistadores Asociados, '||lt_tramitador(i));
       END LOOP;
    END IF;
    --
    FETCH c_tramitadores INTO p_tip_docum, p_cod_docum, p_cod_tramitador, l_lst;
  END LOOP;
  CLOSE c_tramitadores;
END;
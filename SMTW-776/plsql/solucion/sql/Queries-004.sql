 SELECT a.tip_docum, a.cod_docum, a.cod_tramitador
      FROM a1001339 a
     WHERE a.cod_cia = 4
       AND a.tip_estado = 'A'
       AND NVL(a.num_siniestros, 0) < NVL(a.max_num_exp, 99999)
       AND a.cod_tramitador = 440637
       AND a.cod_nivel3 = 1001
       AND NVL(a.num_siniestros, 0) =
           (SELECT min(NVL(c.num_siniestros, 0))
              FROM a1001339 c
             WHERE c.cod_cia = 4
               AND c.cod_tramitador = 440637
               AND c.cod_nivel3 = 1001
               AND c.tip_estado = 'A'
               AND NVL(c.num_siniestros, 0) < NVL(c.max_num_exp, 99999)
            );
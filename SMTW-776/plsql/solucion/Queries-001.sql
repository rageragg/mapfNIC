 SELECT c.*
        FROM A2000030 c
       WHERE c.cod_cia = 4
         AND c.cod_sector = 3
         AND c.cod_ramo = 301
         AND c.mca_poliza_anulada = 'N'
         AND c.tip_spto != 'SM'
         AND c.num_poliza = '3011001600274'
         AND c.num_spto = (SELECT MAX(num_spto)
                             FROM a2000030 e
                            WHERE e.cod_cia = c.cod_cia
                              AND e.num_poliza = c.num_poliza
                              AND e.mca_spto_anulado = 'N'
                              AND e.tip_spto != 'SM'
                              AND e.fec_efec_spto <= SYSDATE)
         AND TRUNC(SYSDATE) BETWEEN c.fec_efec_poliza AND c.fec_vcto_poliza;
 --
 select * from user_tab_comments where comments like '%%' and table_name like '_700%';
-- DATOS FIJOS DEL SINIESTRO 
SELECT * FROM A7000900 WHERE COD_CIA = 4 AND NUM_SINI = 100130120001526;
-- DATOS GENERALES DEL SINIESTRO AUTOS
SELECT * FROM A7000950 WHERE COD_CIA = 4 AND NUM_SINI = 100130120001526;
-- CAUSAS DEL  SINIESTRO
SELECT * FROM A7000930 WHERE COD_CIA = 4 AND NUM_SINI = 100130120001526;
-- DOCUMENTOS DEL SINIESTRO
SELECT * FROM A7000905 WHERE COD_CIA = 4 AND NUM_SINI = 100130120001526;
-- CRITERIOS DE ASIGNACION DE TRAMITADORES
SELECT * FROM a7001024 WHERE COD_CIA = 4 AND COD_RAMO = 301;
-- TERCER NIVEL DE ESTRUCTURA COMERCIAL
SELECT * FROM a1000702;
-- DATOS DEL EXPEDIENTE
SELECT * FROM A7001000 WHERE COD_CIA = 4 AND NUM_SINI = 100130120001526;
-- DATOS DEL TRAMIRADOR
select * from a1001339 where cod_usr_tramitador = 'AREASME';


select * from g1010107 where txt_nombre_variable = 'MCA_ASIGNA_ESP';

SELECT *
  FROM a7001024_mni
 WHERE cod_cia    = 4
   AND cod_sector = 3
   AND cod_ramo   = 301
   AND num_poliza = CASE WHEN regexp_like( num_poliza, '^[99999]','i') 
                         THEN num_poliza
                         ELSE '3011001600274'
                    END
   AND tip_exp = CASE WHEN regexp_like( num_poliza, '^[999]','i') 
                         THEN tip_exp
                         ELSE 'RDV'
                    END 
   AND NVL(num_poliza_grupo,'999999') = CASE WHEN num_poliza_grupo IS NULL
                                       THEN '999999' 
                                       ELSE NULL
                                  END
   AND NVL(cod_agt,9999) = CASE WHEN cod_agt IS NULL
                                THEN 9999 
                                ELSE 3239
                           END
   AND NVL(cod_nivel_tramitador,9999) = CASE WHEN cod_nivel_tramitador IS NULL
                                             THEN 9999 
                                             ELSE 1001
                                        END;                         





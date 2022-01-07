declare 
  TYPE CurTyp IS REF CURSOR;

  g_cod_cia   CONSTANT x2000000_web.val_campo%TYPE := 4;
  g_cod_ramo  CONSTANT a1001800.cod_ramo%TYPE      := 301;
  
  c_datos     CurTyp;
  
  l_identificacion      VARCHAR2(128) := '5612310860003H';
  l_placa               VARCHAR2(128);
  l_numeroCotizacion    VARCHAR2(128) := NULL; -- '3011001976611';
  
  l_num_cotizacion      p2000030.num_poliza%TYPE; 
  l_fec_validez         p2000030.fec_validez%TYPE;
  l_fec_efec_poliza     p2000030.fec_efec_poliza%TYPE;
  l_fec_vcto_poliza     p2000030.fec_vcto_poliza%TYPE;
  l_tip_docum           p2000030.tip_docum%TYPE;
  l_cod_docum           p2000030.cod_docum%TYPE;
  l_num_placa           p2000020.val_campo%TYPE;
 
  l_stm         VARCHAR2(4000);
  l_stm_select  VARCHAR2(512) := 'select a.num_poliza num_cotizacion, a.fec_validez, a.fec_efec_poliza, a.fec_vcto_poliza, a.tip_docum, a.cod_docum, b.val_campo num_placa';
  l_stm_from    VARCHAR2(512) := 'from p2000030 a, p2000020 b';
  l_stm_where   VARCHAR2(512) := 'where a.cod_cia = '||g_cod_cia||' and a.cod_ramo = ' || g_cod_ramo || ' and b.cod_cia = a.cod_cia and b.cod_ramo = a.cod_ramo and b.num_poliza = a.num_poliza';

begin
  l_stm := l_stm_select ||' '|| l_stm_from ||' '|| l_stm_where;
  IF l_numeroCotizacion IS NOT NULL THEN
    --
    l_stm := l_stm || ' and b.cod_campo like :A and a.num_poliza = :B';
    OPEN c_datos FOR l_stm USING 'NUM_PLACA', l_numeroCotizacion; 
    --
  ELSIF l_placa IS NOT NULL THEN   
    --
    l_stm := l_stm || ' and b.cod_campo like :A and b.val_campo  = :B';
    OPEN c_datos FOR l_stm USING 'NUM_PLACA', l_placa; 
    --
  ELSIF l_identificacion IS NOT NULL THEN   
    --
    l_stm := l_stm || ' and b.cod_campo like :A and a.cod_docum  = :B';
    OPEN c_datos FOR l_stm USING 'NUM_PLACA', l_identificacion; 
    --    
  END IF;
  --
  IF c_datos%ISOPEN THEN
    LOOP
       --
      FETCH c_datos INTO l_num_cotizacion, l_fec_validez, l_fec_efec_poliza, l_fec_vcto_poliza, l_tip_docum, l_cod_docum, l_num_placa;
      EXIT WHEN c_datos%NOTFOUND;
      dbms_output.put_line(l_num_placa);
      --
    END LOOP;
    CLOSE c_datos;
  END IF;
  --
end;

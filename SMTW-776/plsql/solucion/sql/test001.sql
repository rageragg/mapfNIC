declare
   p_cod_cia             a1001339.cod_cia %TYPE        := 4;
   p_num_sini            a7000900.num_sini%TYPE        := 100330117000049;
   --
   p_cod_sector          a7001024.cod_sector %TYPE     := 3;
   p_cod_ramo            a7001024.cod_ramo %TYPE       := 301;
   p_num_poliza          a7001024.num_poliza %TYPE     := '3011001971179';
   p_cod_nivel3          a1001339.cod_nivel3 %TYPE     := '';
   p_cod_tramitador_aper a1001339.cod_tramitador %TYPE := 440657;
   p_tip_exp_aper        a7001024.tip_exp %TYPE;
   p_cod_docum           a1001339.cod_docum %TYPE;
   p_tip_docum           a1001339.tip_docum %TYPE;
   p_cod_tramitador      a1001339.cod_tramitador%TYPE;
   --
   l_max_spto            a2000030.num_spto%TYPE;
   l_cod_agt             a2000030.cod_agt%TYPE;
   --
   cursor c_criterio
   is
   select *
    from a7001024
   where cod_cia    = p_cod_cia
     and cod_sector = nvl(p_cod_sector,cod_sector)
     and cod_ramo   = nvl(p_cod_ramo,cod_ramo)
     and num_poliza = nvl(p_num_poliza,num_poliza);
   --  
begin
  --
  dbms_output.put_line(p_cod_sector||', '||p_cod_ramo||', '||p_num_poliza||', '||p_cod_nivel3);
  --
  trn_k_global.asigna('COD_USR', 'TRONBACH' );
  --
  ss_k_g1010107.p_lee('DEFECTO', 'DEFECTO', 'MCA_ASIGNA_ESP');
  if ss_k_g1010107.f_txt_valor_variable = 'S' then
     -- se lee el expediente
     ts_k_a7001000.p_lee_a7001000(p_cod_cia  => p_cod_cia, p_num_sini => p_num_sini, p_num_exp  => 1);
     -- obtenemos el tramitador inicial
     p_tip_exp_aper   := ts_k_a7001000.f_tip_exp;
     dbms_output.put_line('Tipo Expediente: ' ||p_tip_exp_aper);
     -- leemos los datos del tramitador
     ts_k_a1001339.p_lee_cod_tramitador(p_cod_cia, p_cod_tramitador_aper);
     p_tip_docum  := ts_k_a1001339.f_tip_docum;
     p_cod_docum  := ts_k_a1001339.f_cod_docum;
     p_cod_nivel3 := ts_k_a1001339.f_cod_nivel3;
     dbms_output.put_line('Nivel3 Apertura : ' ||p_cod_nivel3);
     dbms_output.put_line('Tramitador: ' ||p_tip_docum ||', '||p_cod_docum);
     -- max suplemento
     l_max_spto := em_k_a2000030_trn.f_max_spto( p_cod_cia, p_num_poliza, null, null, null );
     -- buscamos los datos de la poliza
     em_k_a2000030_trn.p_lee( p_cod_cia, p_num_poliza, l_max_spto,  0, 0);
     l_cod_agt := em_k_a2000030_trn.f_cod_agt;
     dbms_output.put_line('Agente: ' ||l_cod_agt);
     -- 
     trn_k_global.asigna('NUM_SINI', p_num_sini );
     -- probamos el procedimiento actual
     ts_p_obtiene_tramitador_mni(p_cod_cia, 
                                 p_cod_sector, 
                                 p_cod_ramo,
                                 p_num_poliza, 
                                 p_cod_nivel3, 
                                 p_cod_tramitador_aper,
                                 p_tip_exp_aper, 
                                 p_cod_docum, 
                                 p_tip_docum,
                                 p_cod_tramitador
                                );
     dbms_output.put_line('Tramitador Seleccionado: ' ||p_cod_tramitador);                           
     
  end if;   
end;
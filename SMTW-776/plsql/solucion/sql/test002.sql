declare
   p_cod_cia             a1001339.cod_cia %TYPE        := 4;
   p_num_sini            a7000900.num_sini%TYPE        := 100130121000623;
   --
   p_cod_agt             a7000900.cod_agt%TYPE;
   p_cod_sector          a7001024.cod_sector %TYPE;
   p_cod_ramo            a7001024.cod_ramo %TYPE;
   p_num_poliza          a7001024.num_poliza %TYPE;
   p_cod_nivel3          a1001339.cod_nivel3 %TYPE;
   p_cod_tramitador_aper a1001339.cod_tramitador %TYPE;
   p_tip_exp_aper        a7001024.tip_exp %TYPE;
   p_cod_docum           a1001339.cod_docum %TYPE;
   p_tip_docum           a1001339.tip_docum %TYPE;
   p_cod_tramitador      a1001339.cod_tramitador%TYPE;
   --
   l_max_spto NUMBER;
begin
  --
  ss_k_g1010107.p_lee('DEFECTO', 'DEFECTO', 'MCA_ASIGNA_ESP');
  trn_k_global.asigna('COD_USR', 'TRONBACH' );
  --
  ts_k_a7000900.p_lee_a7000900( p_cod_cia, p_num_sini );
  p_cod_sector := ts_k_a7000900.f_cod_sector;
  p_cod_ramo   := ts_k_a7000900.f_cod_ramo;
  p_num_poliza := ts_k_a7000900.f_num_poliza;
  p_cod_nivel3 := ts_k_a7000900.f_cod_nivel3;
  p_cod_agt    := ts_k_a7000900.f_cod_agt;
  --
  dc_k_a1001332_trn.p_lee(p_cod_cia   => p_cod_cia,
                   p_cod_agt     => p_cod_agt,
                   p_fec_validez => sysdate
                );
  --
  l_max_spto := em_k_a2000030_trn.f_max_spto( p_cod_cia, p_num_poliza, null, null, null );
  em_k_a2000030_trn.p_lee( p_cod_cia, p_num_poliza, l_max_spto,  0, 0);
  --
  dbms_output.put_line('Siniestro      : ' ||p_num_sini);
  dbms_output.put_line('Codigo Sector  : ' ||p_cod_sector);
  dbms_output.put_line('Codigo Ramo    : ' ||p_cod_ramo);
  dbms_output.put_line('Poliza         : ' ||p_num_poliza);
  dbms_output.put_line('Grupo          : ' ||em_k_a2000030_trn.f_num_poliza_grupo);
  dbms_output.put_line('Nivel Sini     : ' ||p_cod_nivel3);
  dbms_output.put_line('Agente         : ' ||p_cod_agt);
  dbms_output.put_line('Nivel Agente   : ' ||dc_k_a1001332_trn.f_cod_nivel3);
  --
  ts_k_a7001000.p_lee_a7001000( p_cod_cia  => p_cod_cia, p_num_sini => p_num_sini, p_num_exp  => 1);
  p_cod_tramitador := ts_k_a7001000.f_cod_tramitador;
  p_tip_exp_aper   := ts_k_a7001000.f_tip_exp;
  p_cod_nivel3     := ts_k_a7001000.f_cod_nivel3;
  --
  dbms_output.put_line('Tramitador     : ' ||p_cod_tramitador);
  dbms_output.put_line('Tipo Expediente: ' ||p_tip_exp_aper);
  dbms_output.put_line('Nivel Exp      : ' ||p_cod_nivel3);
  --
  ts_k_a1001339.p_lee_cod_tramitador(p_cod_cia, p_cod_tramitador);
  p_tip_docum := ts_k_a1001339.f_tip_docum;
  p_cod_docum := ts_k_a1001339.f_cod_docum;
  dbms_output.put_line('Tramitador: ' ||p_tip_docum ||', '||p_cod_docum);
  --
   ss_k_g1010107.p_lee('DEFECTO', 'DEFECTO', 'MCA_ASIGNA_ESP');
  dbms_output.put_line('Modo (MCA_ASIGNA_ESP): ' ||ss_k_g1010107.f_txt_valor_variable );
  --
  -- 
  trn_k_global.asigna('NUM_SINI', p_num_sini );
  -- probamos el procedimiento actual
  p_cod_tramitador_aper := p_cod_tramitador;
  --
  ts_p_obtiene_tramitador_mni(  p_cod_cia, p_cod_sector, p_cod_ramo,
                                p_num_poliza, ts_k_a7000900.f_cod_nivel3, p_cod_tramitador_aper,
                                p_tip_exp_aper, p_cod_docum, p_tip_docum,
                                p_cod_tramitador
                              );
  dbms_output.put_line('Tramitador Seleccionado: ' ||p_cod_tramitador); 
  --
  exception 
    when others then
         dbms_output.put_line(sqlerrm);
end;
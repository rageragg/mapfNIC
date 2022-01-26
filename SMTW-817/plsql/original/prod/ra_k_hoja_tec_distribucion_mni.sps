CREATE OR REPLACE PACKAGE ra_k_hoja_tec_distribucion_mni
AS
    --
    /* -------------------- VERSION = 1.00 -------------------- */
    --
    /* -------------------- DESCRIPCION -----------------------
    || Paquete para la manipulacion de la hoja tecnica de 
    || distribucion reaseguro de una poliza determinada
    */ --------------------------------------------------------
    --
    /* -------------------- MODIFICACIONES --------------------
    || 2021/04/21  - CARRIERHOUSE, RGUERRA - v 1.00
    || Creacion del Package
    || 2021/10/22  - CARRIERHOUSE, RGUERRA - v 1.01
    || Se modifica el cursor c_mvtos para filtrar por el spto
    || que elija el usuario
    */ --------------------------------------------------------
    --
    -- tipo detalle del reporte 
    TYPE typ_rec_detalle IS RECORD (
        k_origen            CHAR(1),
        num_riesgo          a2501000.num_riesgo%TYPE,
        nom_riesgo          a2000031.nom_riesgo %TYPE,
        num_mov             a2501000.num_mov%TYPE,
        fec_mov             a2501600.fec_mov%TYPE,
        fec_efec            a2501600.fec_efec%TYPE,
        fec_vcto            a2501600.fec_vcto%TYPE,
        cod_secc_reas       a2501000.cod_secc_reas%TYPE,        -- codigo de la seccion
        nom_secc_reas       a2500120.nom_secc_reas%TYPE,        -- nombre de la seccion
        cod_cia_rea         a2501500.cod_cia_facul%TYPE,        -- cia reaseguradora
        nom_cia_rea         v1001390.nom_completo%TYPE,         -- nombre de reaseguradora
        cod_contrato        a2501000.cod_contrato%TYPE,         -- codigo del contrato
        nom_contrato        a2500140.nom_contrato%TYPE,         -- nombre del contrato
        pct_participacion   a2501000.pct_participacion%TYPE     := 0,   -- % participacion
        cap_cedido          a2501000.cap_cedido%TYPE            := 0,   -- capital cedido
        cap_cedido_spto     a2501000.cap_cedido_spto%TYPE       := 0,   -- capital cedido suplemento
        imp_prima           a2501000.imp_prima%TYPE             := 0,   -- prima
        imp_prima_ret       a2501000.imp_prima%TYPE             := 0,   -- prima retenida
        imp_prima_ced       a2501000.imp_prima%TYPE             := 0,   -- prima cedida
        imp_prima_spto      a2501000.imp_prima_spto%TYPE        := 0,   -- prima del suplemento
        imp_prima_spto_ret  a2501000.imp_prima_spto%TYPE        := 0,   -- prima retenida del suplemento
        imp_prima_spto_ced  a2501000.imp_prima_spto%TYPE        := 0,   -- prima cedida del suplemento
        pct_ajuste          a2501610.pct_ajuste%TYPE            := 0,   -- % ajuste
        prima_ajuste        NUMBER                              := 0,
        prima_ajuste_spto   NUMBER                              := 0,
        imp_comision        a2501500.com_facul %TYPE            := 0,
        imp_comision_spto   a2501500.com_facul_spto %TYPE       := 0,
        -- acumulado contrato
        cod_broker        a2500150.cod_broker%TYPE,             -- broker del contrato
        nom_broker        v1001390.nom_completo%TYPE,           -- nombre del broker
        ict_comision      a2501500.imp_prima_spto %TYPE         := 0,   -- importe comision del contrato (acumulado)
        ict_comision_spto a2501500.com_facul_spto %TYPE         := 0,   -- importe comision del contrato suplemento (acumulado)
        pct_comision      a2501500.pct_participacion%TYPE       := 0,   -- porcentaje en proporcion a la prima
        --
        imp_prima_net      a2501000.imp_prima%TYPE              := 0,   -- prima neta
        imp_prima_spto_net a2501000.imp_prima_spto%TYPE         := 0,   -- prima del suplemento neta
        pct_impuesto       NUMBER                               := 0,
        imp_impuesto       NUMBER                               := 0 
        --
    );
    --
    -- tabla de secciones
    TYPE tab_lista_detalle IS TABLE OF typ_rec_detalle;
    --
    -- lista las secciones que una poliza tiene asociada
    FUNCTION f_lista_detalle RETURN tab_lista_detalle PIPELINED;
    --
    -- RGUERRA, 20210421
    -- reporte xml (excel) hoja tecnica distribucion reaseguro
    -- Este procedimiento sera usado para el modo de tarea.
    PROCEDURE p_rep_hoja_tec_reaseguro;

END ra_k_hoja_tec_distribucion_mni;
/

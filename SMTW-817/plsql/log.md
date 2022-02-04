# Registro de Actividades Resaltantes
### Fecha       Descripcion
* 07/12/2021    Se coloca al control github esta solicitud
* 10/12/2022    Se analiza expediente en JIRA
* 10/12/2022    Se realizan comparaciones con respaldo y SCV, (sin diferencia)
* 18/01/2022    Se realiza respaldo de los objetos en INTNI, ya se haran las pruebas en dicho ambiente, se realizan las comparaciones
* 26/01/2022    Se reconfigura en el ambiente INT el reaseguro.
* 26/01/2022    Se modifica el proceso RA_P_HOJA_TEC_200_MNI, en el procedimiento P_PROCESAR_207_208, ver 1.41
* 26/01/2022    Se modifica el proceso RA_P_HOJA_TEC_XXX_MNI, en el procedimiento P_PROCESAR_207_208, ver 1.41
* 01/02/2022    Se agrega columna PORCENTAJE PARTICIPACION REASEGURADORA en el proceso RA_P_HOJA_TEC_200_MNI.p_imprimir_detalle v 1.42
* 04/02/2022    Se agrega columna PORCENTAJE PARTICIPACION REASEGURADORA en el proceso RA_P_HOJA_TEC_XXX_MNI.p_imprimir_detalle v 1.42
                
### Objetos Relacionados
- ra_k_hoja_tec_distribucion_mni, Paquete de Procesamiento de datos
- ra_p_hoja_tec_200_mni, Construye reporte .XML (Excel) de la hoja tecnica ramo 200
- ra_p_hoja_tec_reaseguro_mni. Procedimiento Principal de la Tarea
- ra_p_hoja_tec_XXX_mni, Construye reporte .XML (Excel) de la hoja tecnica todos los ramos
- Tarea asociada: MNIRA0105

### Revisiones
### Fecha       Numero
* 26/10/2021    1601, *** caso SMTW-731 ***
>Se requiere incluir una nueva columna "Porcentaje Distribución de Prima".
Asimismo cambiar el nombre de la columna de "Porcentaje de participación" por "Porcentaje Distribución Suma Asegurada".
Aplicar para todos los ramos

* 25/10/2021    1600, *** caso SMYW-717 ***
>Por instrucciones de Alejandro Narváez solicita que a la HOJA TECNICA DE FIANZA (REASEGURO), se agregue una columna después del porcentaje de participación, específicamente en la columna G, que refleje el nombre del REASGURADOR en el porcentaje de participación. Adjunto modelo de hoja técnica de Fianza.
>Se aplica la suma algebraica

* 30/10/2021    N/A, *** caso SMTW-702 *** 
>Esta imprimiendo la comision acumulada del reaesgurador, y debe ser la del spto, igual que las primas. Ver imagen de un caso de PRODUCCION
NO muestra la lista de reaseguradores para las pólizas facultativas de los ramos. Solo funciona para INCENDIO.
>Ver caso de correo adjunto de una póliza RC de PRODUCCION
En las pruebas del producto SEGURO BANCARIO en DES, reportan la misma incidencia.
Contact is VIP No

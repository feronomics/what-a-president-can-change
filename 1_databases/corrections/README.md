# Datos permanentes de corrección

Esta carpeta contiene insumos del pipeline, no resultados regenerables.

1_recovered_months.csv conserva las 109 observaciones verificadas: MEM enero de 2008 (7 filas), MINTRAB mayo de 2006 (51) y junio de 2006 (51). Se extrajeron de SICOIN_consolidated_corregido.xlsx después de comprobar que todos los otros registros coincidían con nuestra base. Archivo_Origen conserva las referencias a los PDF indicadas por el archivo suministrado.

El master usa únicamente este CSV para recuperar o validar los tres bloques. No lee SICOIN_consolidated_corregido.xlsx ni errors_in_database.docx. El Excel de comparación puede eliminarse; este CSV debe permanecer en el repositorio.

La justificación original está archivada en archive/cleaning/errors_in_database.docx. El documento identifica duplicación de MCD 2024–2025, duplicación de febrero y ausencia de enero en MEM 2008, los meses ausentes de MINTRAB 2006 y el valor incorrecto de mayo de 2005. La corrección autorizada de ese último monto es Q7,052,675.82 → Q528,851.91 para Recreación en Guatemala.

La carpeta archive está ignorada por Git. Por ello, esta nota y los informes y registros de corrección en 3_output/2_tables/9_data_audit y 10_fixed_review también documentan la justificación y el historial.

No se añadieron registros de CONAP. El faltante julio–diciembre de 2011 permanece pendiente. No se imputó gasto de planilla de MIDES en 2012.

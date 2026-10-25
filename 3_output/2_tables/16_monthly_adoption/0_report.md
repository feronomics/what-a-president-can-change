# Adopción y recálculo de las bases mensuales

Fecha: 24 de octubre de 2026.

Se adoptaron las 16 bases mensuales nuevas en `1_databases/programs/by ministry`. Las fuentes anteriores, su consolidada y una copia de los resultados previos están en `archive/2026-10-24_monthly_previous`. Se verificaron los hashes de las 16 fuentes archivadas para confirmar que conservan exactamente los archivos anteriores.

El único master, `2_scripts/0_master.R`, ejecutó la consolidación mensual y anual, estimó nuevamente los índices y regeneró todas las etapas de análisis 1–8. Se actualizaron 40 gráficos principales y 31 gráficos de sensibilidad con deuda; se comprobó que todos fueron escritos durante esta ejecución. Las tablas, modelos de determinantes y pruebas de quiebre también fueron regenerados.

## Comprobaciones

- La nueva consolidada tiene 306,632 filas y coincide con todos los valores y el orden de las 16 fuentes activas.
- CONAP tiene doce meses en 2011 y Q89,580,207.52 ejecutados.
- Los nueve casos de la revisión anterior coinciden con el gasto total anual de planilla al centavo.
- Hay 318 identidades de programa; se estiman 229 índices y se mantienen 89 series sin índice conforme a las reglas existentes.
- El modelo de determinantes utiliza 228 programas completos: 100 estables y 128 volátiles.
- La auditoría independiente de fuentes, consolidación y planilla también terminó correctamente.

## Casos conservados para revisar después

Los registros de MICIVI con regiones incompletas no fueron reparados ni eliminados. Las 30 repeticiones exactas adicionales, de montos cero, permanecen en la base y se registran en `7_retained_micivi_duplicates.csv`. El preprocesamiento evita eliminarlas automáticamente porque no se ha resuelto la pérdida de identificación regional. Las fuentes anteriores están disponibles en el archivo para investigarlo posteriormente.

MEM y MINTRAB conservan todos los datos sustantivos de la entrega nueva; el preprocesamiento restaura únicamente la procedencia PDF de los meses recuperados previamente, después de verificar su correspondencia. La recuperación no agregó filas nuevas en esta ejecución.

El registro de ejecución conserva dos advertencias de `geom_line()` por omisión de una fila sin valor o fuera del rango en cada caso; no hubo errores de ejecución y se verificaron los 71 archivos gráficos. Las advertencias están en `2_warnings.txt` y el registro completo en `3_pipeline.log`.

## Evidencia

- `1_file_manifest.csv`: hashes de las fuentes anteriores y de la entrega adoptada antes del preprocesamiento de procedencia.
- `4_source_validation.csv`: las 16 fuentes coinciden con la consolidada.
- `5_nine_cases.csv`: diferencias de los nueve casos, todas cero al centavo.
- `6_conap_2011.csv`: cobertura mensual y ejecución de CONAP.
- `7_retained_micivi_duplicates.csv`: registros pendientes conservados.
- `8_validation.log`: comprobaciones de adopción y auditoría independiente.

Las tablas y gráficas actuales permanecen en sus carpetas habituales de `3_output`. Los reportes de revisión anteriores se conservan como evidencia histórica.

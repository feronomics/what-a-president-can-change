# Correcciones aplicadas a las bases

Fecha: 23 de octubre de 2026.

Se leyó errors_in_database.docx. Se corrigieron los duplicados y el monto confirmado de MINTRAB; posteriormente se recuperaron 109 observaciones mensuales desde SICOIN_consolidated_corregido.xlsx. CONAP no fue modificado.

## Cambios realizados

- Se eliminaron 1,630 filas mensuales repetidas: MCD 1,275; MEM 7; MICIVI 224; MINEDUC 24; Secretarías 100. MCD incluye los bloques duplicados de todos los meses de 2024–2025 y otras repeticiones completas.
- Se eliminaron 85 filas repetidas del detalle anual de gasto por grupo. Sus montos de ejecución eran cero; se conservaron los registros con diferencias en sus campos.
- MINTRAB, mayo de 2005, Guatemala, Servicios de recreación a los trabajadores del Estado: ejecución corregida de Q7,052,675.82 a Q528,851.91 conforme al informe suministrado.
- Se reconstruyeron las bases consolidadas y se recalcularon los análisis, incluidas las alternativas con deuda.
- La limpieza redujo la base de 307,954 a 306,324 filas. La recuperación posterior de 109 observaciones la lleva a 306,433 filas. El detalle anual pasa de 11,967 a 11,882 filas; conserva 1,354 registros de programa-año.

## Criterio de duplicación

Coincidencia de todos los campos de la fila, comparando los montos a precisión de centavos para evitar diferencias de representación numérica. Se conserva la primera copia y todos sus valores originales. Compartir nombre o código no basta para eliminar una fila. Los registros de CONAP quedan exceptuados de la limpieza.

## Pendiente

- Completado: enero de 2008 de MEM (7 filas).
- Completado: mayo y junio de 2006 de MINTRAB (51 filas cada mes).
- Revisar la ejecución anual cero de MIDES en 2012.
- Revisar CONAP cuando se autorice.
- Verificar diferencias restantes entre ejecución mensual sumada y ejecución anual por grupos.
- Los montos negativos mensuales se conservan como posibles ajustes contables.

Enero de MEM y mayo–junio de MINTRAB ya fueron recuperados desde la base corregida suministrada. CONAP sigue sin julio–diciembre de 2011. La revisión por ministerio agregado no detecta ese faltante interno de Secretarías.

## Evidencia y reproducción

Las tablas 1–20 de esta carpeta corresponden a la auditoría posterior a la limpieza. Los archivos 21_corrections registran cada fila eliminada o monto corregido con archivo, hoja y fila Excel original.

Las copias exactas de los 17 libros modificados se guardaron en archive/2026-10-23_source_corrections. La auditoría anterior se conserva en archive/2026-10-23_audit_before_corrections. La carpeta archive está excluida de Git.

0_correct_sources.R corre automáticamente desde el único master, antes de los dos scripts de consolidación. Es idempotente: una nueva ejecución no vuelve a descontar las mismas filas. 9_data_audit.R es una revisión independiente y no cambia las bases.

Verificación posterior: cero filas completas duplicadas en las tablas de auditoría mensual y de planilla; todas las fuentes coinciden con las consolidadas; el valor MINTRAB fue comprobado; los registros CONAP coinciden con el respaldo; los tres meses antes faltantes ya están recuperados; una segunda pasada propone cero eliminaciones.

## Actualización de planilla: 24 de octubre de 2026

Las cifras de planilla descritas arriba corresponden a las fuentes anteriores, ahora archivadas. Se adoptaron 15 archivos corregidos (14 ministerios y Secretarías), con 15,868 filas de detalle y 3,184 registros anuales por unidad y programa. La consolidación conserva exactamente los datos de las 15 fuentes. La observación de MIDES 2012 ya está cubierta por las fuentes nuevas. Los nueve casos de revisión por programa siguen documentados; Reconstrucción N7 de MIDES 2016 permanece sin enlace automático. CONAP en la base mensual no fue modificado. Véase ../14_payroll_adoption/0_report.md para el estado actual.

# Revisión de la última versión de planilla

La revisión compara los quince archivos individuales recién reemplazados en la raíz de 1_databases con las tablas guardadas de la versión revisada anteriormente. No sustituye las bases activas del pipeline ni ejecuta los modelos.

## Qué quedó resuelto

- Se completaron 500 filas que antes tenían Programa_Final vacío: ocho de MICIVI y 492 de Secretarías.
- Las filas sin ese nombre común bajaron de 547 a 47. Todas las 47 restantes tienen ejecución cero. Ya no queda una fila con gasto positivo y Programa_Final vacío.
- En MICIVI 2010, código 24, los Q104,420,062.56 ahora tienen el nombre SERVICIOS DE URBANIZACION Y DESARROLLO DE COMUNIDADES URBANAS Y RURALES.
- Las 487 filas de Secretarías que antes no identificaban la institución y la unidad ejecutora ahora tienen ambos campos completos. Esto confirma que los campos están llenos, no una verificación contra cada documento original.
- Se verificó la presencia de cada nombre final en la misma institución agregada y año de la base mensual. La única excepción es MIDES 2016, código 96, RECONSTRUCCION N7, que ya estaba entre los casos pendientes.

## Qué no quedó resuelto

Las nueve diferencias de montos identificadas en la revisión anterior siguen exactamente iguales. Completar un nombre no modifica cuánto dinero figura bajo él. Por tanto, las nuevas etiquetas resuelven los campos vacíos con gasto, pero no determinan por sí solas cuál es la distribución correcta del gasto entre programas.

Ahora pueden observarse once comparaciones pendientes al incluir Secretarías y el programa recién nombrado: las nueve anteriores, el programa de urbanización de MICIVI 2010 recién vinculado y CONAP 2011. No son dos cambios nuevos en los montos: antes faltaban nombres para comparar esos registros.

- MICIVI 2010, urbanización: la nueva planilla anual suma Q104,420,062.56 frente a Q59,300,123.92 bajo ese nombre en la base mensual; diferencia aproximada Q45.12 millones. Revisar asignación o alcance.
- CONAP 2011: la fuente anual suma aproximadamente Q89.58 millones y la mensual Q43.38 millones. La diferencia sigue asociada al semestre mensual ausente que ya habíamos identificado. No se modificó CONAP.
- Reconstrucción N7 de MIDES 2016 sigue sin contraparte con ese nombre en la mensual.

Los casos completos están en 5_remaining_amount_discrepancies.csv; 11_previous_nine_cases.csv conserva el estado de los nueve originales. La revisión de montos sigue usando 0.5% como margen, no una exigencia de igualdad exacta.

## Qué cambió en las cifras

Comparando las 3,174 combinaciones de ministerio, año, código y nombre original, no hay cambios de ejecución ni servicios personales a precisión de centavos, ni combinaciones añadidas o eliminadas. Cambió la asignación del nombre final en 86 de esas combinaciones. Los resúmenes individuales siguen conciliando con sus detalles y no se detectaron duplicados completos.

## Evidencia

- 1_name_coverage.csv: nombres faltantes antes y ahora, por institución.
- 2_before_vs_latest.csv y 3_label_changes.csv: cambios respecto a la versión anterior.
- 4_program_amounts.csv y 5_remaining_amount_discrepancies.csv: contraste por nombre con la base mensual.
- 6_still_missing_names.csv: las 47 filas restantes, todas con gasto cero.
- 8_names_without_monthly_counterpart.csv: Reconstrucción N7.
- 9_secretariat_metadata.csv: identificación de institución y unidad, ahora completa.
- 10_internal_summary_check.csv: detalle frente a resúmenes.
- 11_previous_nine_cases.csv: persistencia de las nueve diferencias anteriores.

El reporte extenso preparado con la versión anterior describe el estado previo; para decidir sobre estos archivos recién reemplazados debe usarse esta revisión actualizada. Las fuentes activas y el master no se modificaron.

# Revisión de las nuevas bases mensuales

Fecha: 24 de octubre de 2026. Revisión únicamente: no se reemplazaron fuentes activas ni se recalcularon los análisis.

## Resultado

1. **CONAP: sí se completó 2011.** La base anterior tenía enero–junio; la nueva tiene enero–diciembre. Se agregaron 90 filas de julio–diciembre, por Q46,201,572.20 ejecutados. El total anual pasa de Q43,378,635.32 a Q89,580,207.52. En Secretarías no se modificó ningún registro anterior: el único cambio es esta incorporación.
2. **Los nueve casos coinciden ahora al centavo.** La suma de ejecución mensual de cada programa y año coincide con el gasto total anual de las bases nuevas de planilla. Esto incluye Reconstrucción N7 de MIDES, que ahora aparece con Q688,961.08. La comparación es entre gasto total anual y ejecución mensual sumada; no compara solo servicios personales. Que coincidan los totales no verifica por sí solo la exactitud de cada comprobante original.
3. **El resto no es completamente idéntico.** Doce bases conservan todos los valores sustantivos. Hay cambios solo en MICIVI 2010, MIDES 2016, MINECO 2004 y Secretarías 2011. Algunos cambios adicionales de MICIVI requieren atención antes de adoptar la nueva versión.

## Comparación de los nueve casos

| Caso | Ministerio/año | Programa abreviado | Nueva ejecución anual | Diferencia con planilla |
|---|---|---|---:|---:|
| A01 | MICIVI 2010 | Vivienda | Q428,359,322.39 | Q0.00 |
| A02 | MICIVI 2010 | Reconstrucción Stan | Q350,246,782.41 | Q0.00 |
| A03 | MICIVI 2010 | Información sismológica y climática | Q49,600,068.98 | Q0.00 |
| A04 | MICIVI 2010 | Radiodifusión y televisión | Q7,982,971.27 | Q0.00 |
| A05 | MICIVI 2010 | Urbanización y bienes inmuebles | Q60,974,448.76 | Q0.00 |
| A06 | MICIVI 2010 | Telefonía | Q6,698,788.05 | Q0.00 |
| A07 | MIDES 2016 | Desastres y calamidades | Q1,831,550.00 | Q0.00 |
| A08 | MIDES 2016 | Reconstrucción N7 | Q688,961.08 | Q0.00 |
| A09 | MINECO 2004 | Servicios registrales | Q12,911,594.21 | Q0.00 |

Los nombres completos y los valores anteriores están en `5_nine_cases.csv`.

## Otros cambios encontrados

### MICIVI 2010

- La base pasa de 41,716 a 41,825 filas: 109 filas más. Hay 461 filas anteriores que dejan de coincidir y 570 filas nuevas o modificadas. No deben interpretarse como 1,031 observaciones diferentes: una modificación aparece una vez como registro anterior y otra como registro nuevo.
- El total anual de ejecución, asignado y vigente no cambia. Sí cambia su distribución entre programas y algunas etiquetas territoriales.
- Además de los seis casos anteriores, Servicios de urbanización y desarrollo de comunidades urbanas y rurales recibe Q45,119,938.64 adicionales. Este aumento completa la redistribución entre los montos de Telefonía, Stan y Urbanización. No representa gasto adicional del ministerio.
- Aparecen 174 filas nuevas o modificadas bajo Reconstrucción por Agatha y Pacaya; tienen ejecución cero. El aumento neto de filas del ministerio es 109, porque también hay sustituciones de registros previos.
- **Pérdida de información territorial:** 30 registros de Infraestructura vial, que distinguían las regiones III, IV, V, VI y VII, ahora dicen solamente `MULTIDEPARTAMENTAL REGION`. Sus importes no cambian, pero desaparece la distinción territorial. Otras filas modificadas también usan esa etiqueta incompleta.
- **Duplicados exactos:** la nueva base MICIVI contiene 30 filas repetidas en exceso, dentro del programa de reconstrucción Agatha/Pacaya. Sus valores asignado, vigente y ejecutado son cero. No inflan el gasto, pero deben revisarse; no se deben eliminar automáticamente como si se hubiera comprobado que son repeticiones de origen, porque parte del problema podría ser la pérdida de etiquetas territoriales.

### MIDES 2016

Se reclasifican 36 filas, por Q688,961.08, de Desastres y calamidades a Reconstrucción N7. Los totales anuales de ejecución, asignado y vigente se conservan. Fuera de estas filas, MIDES es idéntico.

### MINECO 2004

Cambian cuatro montos de ejecución; no cambian asignado ni vigente:

| Mes | Programa | Antes | Nuevo | Aumento |
|---|---|---:|---:|---:|
| Febrero | Servicios registrales | Q372,840.09 | Q506,840.09 | Q134,000.00 |
| Mayo | Servicios registrales | Q423,835.02 | Q477,522.36 | Q53,687.34 |
| Mayo | Micro, pequeña y mediana empresa | Q90,760.17 | Q123,161.75 | Q32,401.58 |
| Mayo | Asistencia y protección al consumidor | Q180,846.58 | Q188,026.58 | Q7,180.00 |

El aumento anual de ejecución es Q227,268.92. De este, Q187,687.34 resuelve el caso A09; los otros Q39,581.58 son cambios adicionales en los otros dos programas. Se constató el cambio, no se verificó contra documentos originales.

### MEM y MINTRAB: procedencia de los registros

Sus datos sustantivos son idénticos, incluidas las observaciones recuperadas previamente. Sin embargo, las nuevas versiones no contienen `Archivo_Origen`, que existe en nuestras bases activas y conserva la procedencia de las recuperaciones. Al adoptar las bases conviene preservar esa información; no es un cambio de gasto.

## Alcance y comprobaciones

Se compararon las 16 nuevas fuentes con las 16 activas, independientemente del orden de las filas y conservando la cantidad de repeticiones. Se revisaron todas las columnas sustantivas, incluidos nombres originales, estandarizados y finales, año, mes, entidad, departamento y los tres montos. Las columnas de procedencia se revisaron aparte. Las doce fuentes sin cambios coinciden también con los valores numéricos originales, sin depender de un margen porcentual.

La consolidada activa coincide exactamente con las fuentes activas anteriores. Por tanto, esa es también la referencia de datos de nuestro análisis actual. No se afirma que los resultados analíticos sean idénticos al adoptar las nuevas fuentes: cambiarán las series afectadas y deberán recalcularse.

La base nueva tiene 306,632 filas frente a 306,433 anteriores. Se conservan sin cambio 305,932 filas; 501 filas previas se modifican o sustituyen y hay 700 filas nuevas o modificadas. El incremento neto de 199 corresponde a MICIVI (+109) y CONAP (+90).

**Recomendación:** los objetivos de completar CONAP y resolver las nueve diferencias se cumplen. Antes de sustituir las fuentes activas, revisar la pérdida de regiones y los duplicados de MICIVI; preservar la procedencia de MEM/MINTRAB. No se modificó ninguna base ni resultado de análisis durante esta revisión.

## Evidencia

- `1_source_comparison.csv`: comparación completa por archivo.
- `2_changed_rows.csv`: todas las filas que difieren, con su versión anterior/nueva.
- `3_conap_rows.csv` y `4_conap_coverage.csv`: registros y cobertura de CONAP.
- `5_nine_cases.csv`: comparación de los nueve casos.
- `6_totals.json`: totales y verificación de la consolidada anterior.
- `7_annual_amount_changes.csv`: cambios netos en montos por ministerio/año. Asignado y vigente aquí son sumas de celdas mensuales para verificar diferencias, no medidas de presupuesto anual.
- `8_new_micivi_duplicates.csv`: grupos duplicados, número de copias y exceso.
- `9_program_changes.csv`: variaciones de montos por programa/año.

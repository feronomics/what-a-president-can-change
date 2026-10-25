# Revisión de las nuevas bases de planilla

Fecha: 23 de octubre de 2026. Revisión exclusivamente comparativa: no se movieron ni modificaron archivos fuente, no se cambió el master y no se recalcularon los modelos o gráficos del estudio.

## Conclusión

Los archivos nuevos corrigen problemas importantes de la versión actualmente utilizada. Los cambios agregados de monto son relativamente pequeños, pero la identificación de programas cambia sustancialmente y mejora la conciliación con las bases mensuales. No deben interpretarse como una simple actualización de cifras: al integrarlos será necesario revisar los enlaces de programas y recalcular determinantes. Esta revisión no anticipa el sentido de los nuevos coeficientes.

Se revisaron 16 archivos nuevos: 14 ministerios, un archivo de gasto de Secretarías y un consolidado. La comparación monetaria entre versiones mantiene el mismo universo de 14 ministerios y 2004–2025; Secretarías se examina por separado porque antes solo teníamos su archivo de conteos/roster.

## Qué cambió

### Comprometido y devengado

La versión anterior usaba montos que coinciden con la columna Comprometido del archivo nuevo en los 13 ministerios distintos de MAGA. En las 10,942 filas de esos ministerios que se pudieron emparejar unívocamente por ministerio, año, grupo, asignado y vigente, esa coincidencia se verifica. En MAGA, los 823 emparejamientos únicos conservan el mismo Devengado.

Esto confirma la consistencia de la explicación suministrada con ambas versiones; no constituye una verificación independiente de cada PDF original, que no se proporcionó para esta revisión. Comprometido registra obligaciones presupuestarias; devengado reconoce el gasto asociado a la recepción o cumplimiento de bienes, servicios u obligaciones. No deben usarse indistintamente. El monto de servicios personales también cambia en muchos registros.

Entre los 11,765 emparejamientos únicos de los 14 ministerios, 2,638 cambian de devengado en más de un centavo. Las filas monetariamente indistinguibles se consideran ambiguas y no se fuerzan a un emparejamiento individual.

### Identificación de programas

En 2004–2016, los archivos antiguos de 13 ministerios utilizaban etiquetas como GASTOS DE FUNCIONAMIENTO o DEUDA PÚBLICA en lugar del programa real. La nueva versión recupera códigos y nombres específicos. Los programas-año identificados aumentan de 1,354 a 2,475. En los emparejamientos únicos, cambian 6,037 códigos/nombres de programa. Se normalizaron ceros iniciales solo para comparar, sin tratar 01 y 1 como programas diferentes.

Los 14 ministerios pasan de 11,882 filas de detalle actuales a 11,967 nuevas. Las nuevas filas no presentan duplicados completos. La versión antigua había perdido identidad de programa en muchas filas; no debe interpretarse que toda diferencia de número de filas sea un duplicado reintroducido.

### MIDES 2012

La fuente anterior registraba ejecución cero. La nueva registra Q1,100.386 millones, coincidiendo con la suma mensual actual, y Q33.321 millones de servicios personales, aproximadamente 3.03% del total. Esto sí aporta el desglose que faltaba para ese año. La nota del archivo indica que sustituyó un reporte enero–febrero por uno enero–diciembre.

## Cuánto cambian los montos

Acumulado 2004–2025, únicamente los mismos 14 ministerios. Cifras en millones de quetzales nominales; no incluye Secretarías ni deuda pública.

| Medida | Versión actual | Versión nueva | Cambio |
|---|---:|---:|---:|
| Gasto total registrado | 759,066.25 | 757,325.07 | −0.229% |
| Servicios personales | 390,071.81 | 389,602.60 | −0.120% |
| Servicios personales / gasto total | 51.388% | 51.445% | +0.056 puntos porcentuales |

El pequeño cambio agregado no refleja la importancia de corregir identidades de programa. Solo entre 1,154 programas-año con código y nombre comparables y proporción calculable, 17 cambian más de un punto porcentual de planilla; el cambio máximo es 4.90 puntos. Los programas antiguos colapsados en etiquetas genéricas no pueden incluirse en una comparación individual válida.

Cambios acumulados de gasto por ministerio:

| Ministerio | Cambio del total registrado |
|---|---:|
| MAGA | 0.000% |
| MARN | −0.325% |
| MCD | −1.580% |
| MEM | −0.044% |
| MICIVI | −0.309% |
| MIDES | +4.418% |
| MINDEF | −0.001% |
| MINECO | −0.028% |
| MINEDUC | −0.430% |
| MINEX | −0.029% |
| MINFIN | −0.015% |
| MINGOB | −0.658% |
| MINTRAB | −0.511% |
| MSPAS | −0.346% |

## Comprobaciones satisfactorias

- Los totales anuales nuevos de los 14 ministerios coinciden con los mensuales actuales dentro de 0.5% en los 300 ministerios-año. Antes lo hacían 238 de 300. La diferencia máxima nueva es 0.181%, MINECO 2004. Esta comprobación usa los meses ya recuperados de MEM y MINTRAB; la nota suministrada que aún menciona enero ausente de MEM quedó desactualizada respecto a nuestra base actual.
- Los 14 archivos individuales coinciden con sus registros en el consolidado nuevo en todos sus campos comunes.
- Los resúmenes de programa nuevos concilian con su detalle y con la hoja anual del consolidado dentro de redondeo numérico insignificante.
- No se detectaron montos de devengado negativos, faltantes o no finitos, años inválidos ni duplicados completos en los nuevos detalles.

## Aspectos que quedan por revisar

### Nombres armonizados

La presencia de Programa_Final no implica que todos sus enlaces estén verificados. El consolidado documenta 2,382 programas-año enlazados por monto, 68 por nombre y 25 sin enlace. La cobertura nominal de nombres finales en los ministerios representa 99.986% de su gasto, pero esa cobertura no demuestra que cada asignación sea correcta.

Al sumar por Programa_Final y contrastar con la base mensual aparecen nueve discrepancias superiores al criterio de 0.5% o sin contraparte: seis en MICIVI 2010, dos en MIDES 2016 y una en MINECO 2004. Son señales para revisar etiquetas, alcance y fuentes, no una demostración automática de que la nueva contabilidad esté equivocada. Algunos desajustes de MICIVI se compensan entre programas: el total ministerial puede cuadrar aunque el reparto por programa no cuadre. Evidencia completa: 18_harmonized_amount_check.csv.

Además, siete filas con gasto positivo de MICIVI 2010, por Q104.42 millones, carecen de Programa_Final. Otras filas ministeriales sin nombre final tienen devengado cero. Los casos con gasto positivo deben revisarse antes de integrarlos a los determinantes.

### Secretarías

El archivo nuevo es información de gasto real, no el conteo/roster antiguo. Contiene 3,901 filas de detalle, Q35,542.17 millones de gasto y Q12,793.02 millones de servicios personales acumulados. No debe confundirse con una corrección comparable del archivo previo de conteos.

El consolidado nuevo solo contiene los 14 ministerios: **no incluye Secretarías**, aunque sí se suministró su archivo individual. Su integración requerirá tratar Unidad_ejecutora y Secretaria correctamente; no comparte exactamente el esquema de los ministerios.

Secretarías tiene 502 filas sin nombre final, con Q4,547.41 millones de gasto; 461 de esas filas tienen gasto positivo. Su cobertura de armonización necesita más trabajo que la de los ministerios.

Sus totales anuales coinciden con las bases mensuales en 21 de 22 años, salvo 2011, cuando la base anual registra aproximadamente Q46.20 millones adicionales. Para CONAP en 2011 la nueva fuente anual registra Q89.58 millones frente a Q43.38 millones en la mensual, coherente con el semestre que ya identificamos como ausente. Esto permite contrastar el total anual, pero no recuperar los seis montos mensuales faltantes. No se modificó CONAP.

## Implicación para el estudio

La principal mejora esperable es identificar programas anteriores a 2017 y ampliar/revisar su enlace con planilla. La correlación y el logit actuales usan la fuente anterior y deberán recalcularse al adoptar la nueva. Esta revisión no ejecutó esa adopción ni los modelos, ni modificó los índices mensuales de volatilidad.

## Archivos de evidencia

- 2_annual_comparison.csv: comparación ministerio-año.
- 3_ministry_totals.csv y 21_national_same_scope.csv: comparación acumulada comparable.
- 4_program_identity_changes.csv y 22_program_counts.csv: identidades de programa.
- 7_unique_row_matches.csv y 8_row_match_profile.csv: emparejamientos unívocos y cambios de columnas.
- 9_monthly_reconciliation.csv: contraste con ejecución mensual.
- 10_summary_reconciliation.csv, 12_individual_vs_consolidated.csv, 13_consolidated_summary.csv y 20_secretariat_summary_check.csv: comprobaciones internas.
- 18_harmonized_amount_check.csv y 19_missing_harmonized_names.csv: etiquetas que requieren revisión.
- 23_validation_summary.csv y 24_conap_annual_only.csv: resumen y contraste CONAP.

Reproducir desde la raíz con source("2_scripts/2_analysis/11_payroll_review.R", encoding = "UTF-8"). El script es independiente del master y únicamente lee las fuentes y escribe tablas de revisión.

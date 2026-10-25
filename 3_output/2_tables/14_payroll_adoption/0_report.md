# Adopción de las bases corregidas de planilla

Fecha: 24 de octubre de 2026.

Se movieron las quince bases corregidas a 1_databases/payroll/by ministry: catorce ministerios y Secretarías. Las bases anteriores, el archivo de conteos/roster de Secretarías y la consolidada anterior están en archive/2026-10-24_payroll_previous. También se conservaron allí los resultados anteriores de determinantes. La carpeta archive está excluida de Git.

La consolidación nueva contiene 15,868 filas de detalle y 3,184 registros anuales de unidad/programa. Se verificaron todos los valores de cada archivo individual contra su porción consolidada. Los hashes de los archivos antes y después del movimiento permiten comprobar su identidad.

El lector conserva Comprometido y Devengado separados, utiliza Devengado en las proporciones de planilla y mantiene unidad ejecutora e institución para Secretarías. La nueva columna Programa_Final se conserva como dato fuente y se valida contra el nombre final mensual del mismo grupo y año.

No se forzó la correspondencia de Reconstrucción N7, MIDES 2016; queda sin enlace y registrado en 4_pending_links.csv. Las nueve diferencias de montos continúan pendientes de revisión y no fueron alteradas para hacerlas coincidir.

Se reconstruyó la consolidada y se actualizaron las cuatro gráficas y tablas de determinantes. La muestra completa es de 228 programas, 100 estables y 128 volátiles. La ejecución final de esos análisis no produjo advertencias. No se modificaron la base mensual, los modelos SARIMA, CONAP mensual ni las otras etapas de análisis.

El único master sigue siendo 2_scripts/0_master.R. El lector de planilla ya acepta el formato nuevo y Secretarías; no requiere los archivos anteriores. Las reglas de nombres previamente aprobadas solo se usan como respaldo cuando el nombre final suministrado está vacío.

Archivos de comprobación: 1_file_manifest.csv; 2_source_validation.csv; 3_analysis_warnings.txt; 4_pending_links.csv.

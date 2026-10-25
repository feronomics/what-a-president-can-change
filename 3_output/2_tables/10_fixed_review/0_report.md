# Comparación con la base corregida suministrada

Fecha: 23 de octubre de 2026.

## Respuestas

1. **Las correcciones anteriores coinciden.** Antes de recuperar observaciones, los 306,324 registros de nuestra base ya estaban presentes en SICOIN_consolidated_corregido.xlsx con los mismos campos. Esto incluye la limpieza de duplicados y el monto corregido de MINTRAB de mayo de 2005.
2. **Los demás registros también coinciden.** No se encontraron filas existentes eliminadas o modificadas por la base suministrada. La comparación considera la multiplicidad de las filas y todos los campos, incluidos nombres y procedencia. Los montos se comparan a precisión de centavos.
3. **Se recuperaron los únicos 109 registros adicionales disponibles:** MEM, enero de 2008, 7 filas; MINTRAB, mayo de 2006, 51; MINTRAB, junio de 2006, 51. Se incorporaron en sus archivos individuales y en la consolidada.

Después de la recuperación, ambos archivos contienen 306,433 registros coincidentes, sin registros exclusivos de ninguna versión.

## Reproducción y evidencia

- 0_correct_sources.R importa únicamente los tres bloques aprobados desde 1_databases/corrections/1_recovered_months.csv, extraído del archivo corregido. No depende del Excel ni del documento Word. Conserva las referencias PDF de Archivo_Origen; el append mantiene esa procedencia cuando está disponible.
- Los registros existentes no se sobrescriben. Si un mes ya está presente, el script exige que coincida con el bloque de referencia; una discrepancia detiene el proceso en vez de duplicar o sustituir datos silenciosamente.
- Los respaldos previos de MEM y MINTRAB están en archive/2026-10-23_recovered_months.
- 6_before_counts.csv y 7_initial_differences.csv documentan la comparación inicial; 5_recovered_rows.csv registra las observaciones importadas.
- 1_current_only.csv y 2_fixed_only.csv quedan vacíos después de la recuperación; 3_counts.csv registra el resultado final. 10_fixed_review.R reproduce esta comparación.
- 9_validation.txt confirma coincidencia completa, reconciliación de las 16 fuentes con la consolidada, ausencia de duplicados completos, recuperación idempotente y conservación de CONAP.
- Se ejecutó el master completo, incluidas las versiones sin deuda y con deuda.

## Lo que el archivo no resuelve

La base suministrada es mensual y no contiene gasto por grupo de objeto ni servicios personales. No proporciona una corrección para el gasto anual de planilla de MIDES en 2012, que sigue en cero en esa fuente. No se imputó planilla a partir de la ejecución mensual total.

Tampoco añade registros de CONAP. Los demás desacuerdos con las bases anuales quedan pendientes de información que los resuelva.

## CONAP

CONAP significa Consejo Nacional de Áreas Protegidas. Es una institución pública dependiente de la Presidencia, encargada de la conservación de áreas protegidas y biodiversidad. En nuestros archivos está agrupada dentro de Secretarías; no es un programa nuevo ni un ministerio que deba excluirse.

El problema concreto es de cobertura: para CONAP en 2011 solo aparecen enero–junio, y faltan julio–diciembre. Los otros organismos de Secretarías sí pueden tener registros en esos meses, por lo que una revisión del agregado Secretarías no identifica este faltante interno.

Esos meses ausentes no demuestran que CONAP gastara cero. Pueden subestimar la ejecución de 2011 y afectar la trayectoria y ponderación de los programas involucrados. La corrección requeriría recuperar los registros originales de ese semestre; no duplicar los primeros seis meses ni inventar cifras. No se modificó CONAP y la decisión queda pendiente del usuario.

Referencia institucional: https://conap.gob.gt/sobre-conap/
Cobertura observada: 8_conap_coverage.csv.

El documento original de errores se conserva en archive/cleaning/errors_in_database.docx. La justificación compartida también está en 1_databases/corrections/README.md; archive no se versiona.

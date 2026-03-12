# Análisis de la despoblación municipal en España (2003–2022): tendencias demográficas
Este proyecto analiza la evolución demográfica de más de 8.000 municipios españoles entre 2003 y 2022 con el objetivo de identificar tendencias asociadas a la pérdida de población.

# Objetivo del proyecto
Analizar qué características demográficas presentan los municipios que pierden población en España entre 2003 y 2022.
El objetivo es identificar tendencias demográficas asociadas a la despoblación municipal para comprender mejor qué tipos de municipios presentan mayor vulnerabilidad demográfica.

# Contexto del negocio
La despoblación rural es un desafío relevante en España, especialmente en municipios pequeños.
Las administraciones públicas necesitan entender qué municipios presentan mayor riesgo de pérdida de población y qué características demográficas se asocian a este fenómeno.
Este tipo de análisis puede ayudar a orientar políticas públicas de desarrollo territorial, atracción de población o planificación de servicios.

# Dataset
El proyecto combina diferentes datasets demográficos municipales para construir un dataset final a nivel de municipio.

## Dataset base

dataset_maestro_municipios

**Formato longitudinal:**
- municipio – año

**Periodo analizado:**
- 2003–2022

## Dataset final de análisis
- perfil_renta

**Formato:**
- 1 municipio = 1 fila

**Variables principales:**
| Variable              | Descripción                                      |
| --------------------- | ------------------------------------------------ |
| pob_2003              | Población municipal en 2003                      |
| pob_2022              | Población municipal en 2022                      |
| cambio_poblacion_pct  | Cambio porcentual de población entre 2003 y 2022 |
| pct_mayor65_medio     | Porcentaje medio de población mayor de 65 años   |
| pct_extranjeros_medio | Porcentaje medio de población extranjera         |
| renta_media_periodo   | Renta media municipal durante el periodo         |

**Variable adicional creada:**
- evolucion

**Categorías:**
- pierde población
- gana o mantiene población

## Fuente de datos
Datos procedentes de fuentes estadísticas públicas como el Instituto Nacional de Estadística (INE) y otros organismos oficiales como el Centro Nacional de Información Geográfica (CNIG)

## Notas sobre calidad del dato

El dataset original se encontraba fragmentado en diferentes fuentes y formatos, por lo que fue necesario realizar varias transformaciones:
- estandarización de códigos municipales
- agregación de datos anuales a nivel municipal
- cálculo de indicadores medios durante el periodo
Algunos indicadores económicos disponibles a nivel municipal son limitados, lo que condiciona el alcance del análisis.

## Preguntas clave

El análisis se estructura alrededor de las siguientes preguntas:

1. ¿Los municipios pequeños presentan mayor envejecimiento poblacional?
2. ¿Existe una relación entre envejecimiento y pérdida de población?
3. ¿Puede la población extranjera actuar como factor de estabilización demográfica?
4. ¿Existe relación entre nivel de renta municipal y despoblación?

## Proceso de análisis
El proyecto sigue una metodología típica de análisis de datos.

**Limpieza de datos**
- revisión de valores nulos
- validación de tipos de datos
- detección de duplicados
- comprobación de consistencia temporal

**Análisis exploratorio (EDA)**
Exploración inicial de:
- evolución de población municipal
- distribución de municipios por tamaño
- envejecimiento poblacional
- presencia de población extranjera

**Feature Engineering**
Creación de variables agregadas a nivel municipal:
- cambio porcentual de población
- porcentaje medio de población mayor de 65 años
- porcentaje medio de población extranjera
- renta media municipal

**Análisis SQL**
Construcción de una tabla de perfil municipal que consolida los indicadores demográficos.
Posteriormente se analizan distintas hipótesis sobre la despoblación.

**Visualización**
El análisis se presenta mediante un dashboard interactivo en Tableau que permite explorar los resultados por municipio.
El dashboard incluye:
- mapa de evolución poblacional
- comparación entre municipios
- análisis de envejecimiento
- análisis de inmigración
- buscador interactivo por municipio

## Resultados / Insights
El análisis muestra varias tendencias relevantes:

- Los municipios pequeños presentan mayores niveles de envejecimiento poblacional.

- Existe una asociación entre mayor envejecimiento y mayor pérdida de población.

- Los municipios con mayor porcentaje de población extranjera tienden a mostrar menor pérdida de población, lo que sugiere que la inmigración puede actuar como factor de estabilización demográfica.

Se exploró también la relación entre renta municipal y despoblación. Sin embargo, los datos disponibles no permiten extraer conclusiones sólidas sobre este factor, ya que sería necesario incorporar más variables económicas para interpretar adecuadamente esta relación.

## Recomendaciones de negocio / políticas públicas
A partir de los resultados del análisis se pueden plantear varias líneas de actuación.

- **Priorizar municipios con alto envejecimiento**:
Estos municipios presentan mayor riesgo de pérdida de población, por lo que podrían ser prioritarios en políticas de atracción de población joven.
- **Focalizar intervenciones en municipios pequeños**:
Los municipios de menor tamaño muestran mayor vulnerabilidad demográfica, por lo que podrían beneficiarse especialmente de políticas de desarrollo territorial.

## Limitaciones
El análisis presenta varias limitaciones:
- Los resultados muestran asociaciones estadísticas, no relaciones causales.

- El análisis se centra principalmente en variables demográficas.
Sería necesario incorporar más variables económicas y de servicios (empleo, infraestructuras, servicios públicos) para comprender mejor el fenómeno de la despoblación.

## Próximos pasos
El proyecto podría ampliarse incorporando:
- datos de empleo local
- acceso a servicios sanitarios y educativos
- conectividad digital
- movilidad laboral

Esto permitiría analizar factores estructurales adicionales que influyen en la despoblación municipal.

## Cómo replicar el proyecto
El repositorio incluye:

- notebooks de limpieza en Python
- consultas SQL utilizadas en el análisis

Repositorio: https://github.com/eliomartinezcastano-stack/despoblacion_municipios_es
Dashboard explorador de municipios: https://public.tableau.com/app/profile/elio.mart.nez/viz/Exploradordemunicipios/Buscadormunicipio

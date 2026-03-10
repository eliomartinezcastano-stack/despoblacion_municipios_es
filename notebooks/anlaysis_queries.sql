-- =========================================================
-- PROYECTO DESPOBLACIÓN MUNICIPAL
-- Análisis SQL de hipótesis
-- Tablas necesarias ya cargadas en MySQL:
--   1. dataset_maestro_municipios
--   2. renta_limpio
-- =========================================================


-- =========================================================
-- 0. PREPARACIÓN DEL ENTORNO
-- =========================================================

CREATE DATABASE IF NOT EXISTS despoblacion_municipal;

USE despoblacion_municipal;

-- Comprobar tablas disponibles
SHOW TABLES;

-- Revisar estructura de las tablas
DESCRIBE dataset_maestro_municipios;
DESCRIBE renta_limpio;

-- Comprobar algunas filas de cada tabla
SELECT * 
FROM dataset_maestro_municipios
LIMIT 10;

SELECT * 
FROM renta_limpio
LIMIT 10;


-- =========================================================
-- H1. TAMAÑO DEL MUNICIPIO Y ENVEJECIMIENTO
-- Hipótesis:
-- Los municipios pequeños presentan mayores niveles de
-- envejecimiento que los municipios de mayor tamaño.
-- =========================================================

-- ---------------------------------------------------------
-- 1. Crear tabla perfil_municipios
-- Incluye:
--   - población inicial (2003)
--   - población final (2022)
--   - porcentaje medio de mayores de 65 años
-- ---------------------------------------------------------
DROP TABLE IF EXISTS perfil_municipios;

CREATE TABLE perfil_municipios AS
SELECT
    codigo_municipio,
    municipio,
    MAX(CASE WHEN periodo = 2003 THEN poblacion END) AS pob_2003,
    MAX(CASE WHEN periodo = 2022 THEN poblacion END) AS pob_2022,
    ROUND(AVG(porcentaje_mayor_65), 2) AS pct_mayor65_medio
FROM dataset_maestro_municipios
GROUP BY codigo_municipio, municipio;

-- Comprobación rápida
SELECT *
FROM perfil_municipios
LIMIT 10;

-- ---------------------------------------------------------
-- 2. Resumen H1 por tamaño municipal
-- Clasificación a partir de la población inicial (2003)
-- ---------------------------------------------------------
SELECT
    CASE
        WHEN pob_2003 < 1000 THEN '<1.000'
        WHEN pob_2003 >= 1000 AND pob_2003 < 5000 THEN '1.000-5.000'
        WHEN pob_2003 >= 5000 AND pob_2003 < 20000 THEN '5.000-20.000'
        WHEN pob_2003 >= 20000 AND pob_2003 < 100000 THEN '20.000-100.000'
        WHEN pob_2003 >= 100000 THEN '>100.000'
    END AS tamano_municipio,
    COUNT(*) AS num_municipios,
    ROUND(AVG(pct_mayor65_medio), 2) AS pct_mayor65_medio
FROM perfil_municipios
WHERE pob_2003 IS NOT NULL
GROUP BY
    CASE
        WHEN pob_2003 < 1000 THEN '<1.000'
        WHEN pob_2003 >= 1000 AND pob_2003 < 5000 THEN '1.000-5.000'
        WHEN pob_2003 >= 5000 AND pob_2003 < 20000 THEN '5.000-20.000'
        WHEN pob_2003 >= 20000 AND pob_2003 < 100000 THEN '20.000-100.000'
        WHEN pob_2003 >= 100000 THEN '>100.000'
    END
ORDER BY
    CASE
        WHEN tamano_municipio = '<1.000' THEN 1
        WHEN tamano_municipio = '1.000-5.000' THEN 2
        WHEN tamano_municipio = '5.000-20.000' THEN 3
        WHEN tamano_municipio = '20.000-100.000' THEN 4
        WHEN tamano_municipio = '>100.000' THEN 5
    END;


-- =========================================================
-- H2. ENVEJECIMIENTO Y DESPOBLACIÓN
-- Hipótesis:
-- Los municipios con mayor porcentaje de población mayor
-- de 65 años tienden a perder población con mayor frecuencia.
-- =========================================================

-- ---------------------------------------------------------
-- 1. Añadir variables de cambio poblacional
-- ---------------------------------------------------------
ALTER TABLE perfil_municipios
ADD COLUMN cambio_poblacion INT,
ADD COLUMN cambio_poblacion_pct FLOAT;

-- ---------------------------------------------------------
-- 2. Calcular cambio poblacional absoluto y porcentual
-- ---------------------------------------------------------
SET SQL_SAFE_UPDATES = 0;

UPDATE perfil_municipios
SET
    cambio_poblacion = pob_2022 - pob_2003,
    cambio_poblacion_pct = ROUND(((pob_2022 - pob_2003) / pob_2003) * 100, 2)
WHERE pob_2003 IS NOT NULL
  AND pob_2022 IS NOT NULL;

SET SQL_SAFE_UPDATES = 1;

-- Comprobación rápida
SELECT *
FROM perfil_municipios
LIMIT 10;

-- ---------------------------------------------------------
-- 3. Resumen H2 por tramos de envejecimiento
-- ---------------------------------------------------------
SELECT
    CASE
        WHEN pct_mayor65_medio < 20 THEN '<20%'
        WHEN pct_mayor65_medio >= 20 AND pct_mayor65_medio < 30 THEN '20-30%'
        WHEN pct_mayor65_medio >= 30 AND pct_mayor65_medio < 40 THEN '30-40%'
        WHEN pct_mayor65_medio >= 40 THEN '>40%'
    END AS nivel_envejecimiento,
    COUNT(*) AS num_municipios,
    ROUND(AVG(cambio_poblacion_pct), 2) AS cambio_poblacion_pct
FROM perfil_municipios
WHERE pct_mayor65_medio IS NOT NULL
  AND cambio_poblacion_pct IS NOT NULL
GROUP BY
    CASE
        WHEN pct_mayor65_medio < 20 THEN '<20%'
        WHEN pct_mayor65_medio >= 20 AND pct_mayor65_medio < 30 THEN '20-30%'
        WHEN pct_mayor65_medio >= 30 AND pct_mayor65_medio < 40 THEN '30-40%'
        WHEN pct_mayor65_medio >= 40 THEN '>40%'
    END
ORDER BY
    CASE
        WHEN nivel_envejecimiento = '<20%' THEN 1
        WHEN nivel_envejecimiento = '20-30%' THEN 2
        WHEN nivel_envejecimiento = '30-40%' THEN 3
        WHEN nivel_envejecimiento = '>40%' THEN 4
    END;

-- ---------------------------------------------------------
-- 4. Correlación de Pearson entre envejecimiento
--    y cambio poblacional porcentual
-- ---------------------------------------------------------
SELECT
    ROUND(
        (
            (COUNT(*) * SUM(pct_mayor65_medio * cambio_poblacion_pct) -
             SUM(pct_mayor65_medio) * SUM(cambio_poblacion_pct))
            /
            SQRT(
                (COUNT(*) * SUM(POW(pct_mayor65_medio, 2)) - POW(SUM(pct_mayor65_medio), 2)) *
                (COUNT(*) * SUM(POW(cambio_poblacion_pct, 2)) - POW(SUM(cambio_poblacion_pct), 2))
            )
        ),
        4
    ) AS correlacion_pearson
FROM perfil_municipios
WHERE pct_mayor65_medio IS NOT NULL
  AND cambio_poblacion_pct IS NOT NULL;


-- =========================================================
-- H3. INMIGRACIÓN COMO FACTOR DE RESILIENCIA
-- Hipótesis:
-- Los municipios con mayor presencia de población extranjera
-- presentan menores tasas de pérdida de población.
-- =========================================================

-- ---------------------------------------------------------
-- 1. Recrear perfil_municipios incluyendo
--    pct_extranjeros_medio
-- ---------------------------------------------------------
DROP TABLE IF EXISTS perfil_municipios;

CREATE TABLE perfil_municipios AS
SELECT
    codigo_municipio,
    municipio,
    MAX(CASE WHEN periodo = 2003 THEN poblacion END) AS pob_2003,
    MAX(CASE WHEN periodo = 2022 THEN poblacion END) AS pob_2022,
    ROUND(AVG(porcentaje_mayor_65), 2) AS pct_mayor65_medio,
    ROUND(AVG(porcentaje_extranjeros), 2) AS pct_extranjeros_medio
FROM dataset_maestro_municipios
GROUP BY codigo_municipio, municipio;

-- ---------------------------------------------------------
-- 2. Añadir de nuevo las variables de cambio poblacional
-- ---------------------------------------------------------
ALTER TABLE perfil_municipios
ADD COLUMN cambio_poblacion INT,
ADD COLUMN cambio_poblacion_pct FLOAT;

-- ---------------------------------------------------------
-- 3. Calcular cambio poblacional absoluto y porcentual
-- ---------------------------------------------------------
SET SQL_SAFE_UPDATES = 0;

UPDATE perfil_municipios
SET
    cambio_poblacion = pob_2022 - pob_2003,
    cambio_poblacion_pct = ROUND(((pob_2022 - pob_2003) / pob_2003) * 100, 2)
WHERE pob_2003 IS NOT NULL
  AND pob_2022 IS NOT NULL;

SET SQL_SAFE_UPDATES = 1;

-- Comprobación rápida
SELECT *
FROM perfil_municipios
LIMIT 10;

-- ---------------------------------------------------------
-- 4. Resumen H3 por tramos de porcentaje de extranjeros
-- ---------------------------------------------------------
SELECT
    CASE
        WHEN pct_extranjeros_medio < 5 THEN '<5%'
        WHEN pct_extranjeros_medio >= 5 AND pct_extranjeros_medio < 10 THEN '5-10%'
        WHEN pct_extranjeros_medio >= 10 AND pct_extranjeros_medio < 20 THEN '10-20%'
        WHEN pct_extranjeros_medio >= 20 THEN '>20%'
    END AS nivel_extranjeros,
    COUNT(*) AS num_municipios,
    ROUND(AVG(cambio_poblacion_pct), 2) AS cambio_poblacion_pct
FROM perfil_municipios
WHERE pct_extranjeros_medio IS NOT NULL
  AND cambio_poblacion_pct IS NOT NULL
GROUP BY
    CASE
        WHEN pct_extranjeros_medio < 5 THEN '<5%'
        WHEN pct_extranjeros_medio >= 5 AND pct_extranjeros_medio < 10 THEN '5-10%'
        WHEN pct_extranjeros_medio >= 10 AND pct_extranjeros_medio < 20 THEN '10-20%'
        WHEN pct_extranjeros_medio >= 20 THEN '>20%'
    END
ORDER BY
    CASE
        WHEN nivel_extranjeros = '<5%' THEN 1
        WHEN nivel_extranjeros = '5-10%' THEN 2
        WHEN nivel_extranjeros = '10-20%' THEN 3
        WHEN nivel_extranjeros = '>20%' THEN 4
    END;

-- ---------------------------------------------------------
-- 5. Correlación de Pearson entre porcentaje medio de
--    extranjeros y cambio poblacional porcentual
-- ---------------------------------------------------------
SELECT
    ROUND(
        (
            (COUNT(*) * SUM(pct_extranjeros_medio * cambio_poblacion_pct) -
             SUM(pct_extranjeros_medio) * SUM(cambio_poblacion_pct))
            /
            SQRT(
                (COUNT(*) * SUM(POW(pct_extranjeros_medio, 2)) - POW(SUM(pct_extranjeros_medio), 2)) *
                (COUNT(*) * SUM(POW(cambio_poblacion_pct, 2)) - POW(SUM(cambio_poblacion_pct), 2))
            )
        ),
        4
    ) AS correlacion_pearson
FROM perfil_municipios
WHERE pct_extranjeros_medio IS NOT NULL
  AND cambio_poblacion_pct IS NOT NULL;


-- =========================================================
-- H4. RENTA Y DESPOBLACIÓN
-- Hipótesis:
-- Los municipios con menor renta presentan mayores pérdidas
-- de población.
-- =========================================================

-- ---------------------------------------------------------
-- 1. Crear tabla perfil_renta uniendo perfil_municipios
--    con renta_limpio
-- ---------------------------------------------------------
DROP TABLE IF EXISTS perfil_renta;

CREATE TABLE perfil_renta AS
SELECT
    p.codigo_municipio,
    p.municipio,
    p.pob_2003,
    p.pob_2022,
    p.cambio_poblacion,
    p.cambio_poblacion_pct,
    p.pct_mayor65_medio,
    p.pct_extranjeros_medio,
    r.renta_media
FROM perfil_municipios p
LEFT JOIN renta_limpio r
    ON p.codigo_municipio = r.codigo_municipio;

-- Comprobación rápida
SELECT *
FROM perfil_renta
LIMIT 10;

-- ---------------------------------------------------------
-- 2. Resumen H4 por tramos de renta
-- ---------------------------------------------------------
SELECT
    CASE
        WHEN renta_media < 10000 THEN '<10.000'
        WHEN renta_media >= 10000 AND renta_media < 15000 THEN '10.000-15.000'
        WHEN renta_media >= 15000 AND renta_media < 20000 THEN '15.000-20.000'
        WHEN renta_media >= 20000 THEN '>20.000'
    END AS nivel_renta,
    COUNT(*) AS num_municipios,
    ROUND(AVG(cambio_poblacion_pct), 2) AS cambio_poblacion_pct
FROM perfil_renta
WHERE renta_media IS NOT NULL
GROUP BY
    CASE
        WHEN renta_media < 10000 THEN '<10.000'
        WHEN renta_media >= 10000 AND renta_media < 15000 THEN '10.000-15.000'
        WHEN renta_media >= 15000 AND renta_media < 20000 THEN '15.000-20.000'
        WHEN renta_media >= 20000 THEN '>20.000'
    END
ORDER BY
    CASE
        WHEN nivel_renta = '<10.000' THEN 1
        WHEN nivel_renta = '10.000-15.000' THEN 2
        WHEN nivel_renta = '15.000-20.000' THEN 3
        WHEN nivel_renta = '>20.000' THEN 4
    END;

-- ---------------------------------------------------------
-- 3. Correlación de Pearson entre renta media
--    y cambio poblacional porcentual
-- ---------------------------------------------------------
SELECT
    ROUND(
        (
            (COUNT(*) * SUM(renta_media * cambio_poblacion_pct) -
             SUM(renta_media) * SUM(cambio_poblacion_pct))
            /
            SQRT(
                (COUNT(*) * SUM(POW(renta_media, 2)) - POW(SUM(renta_media), 2)) *
                (COUNT(*) * SUM(POW(cambio_poblacion_pct, 2)) - POW(SUM(cambio_poblacion_pct), 2))
            )
        ),
        4
    ) AS correlacion_renta
FROM perfil_renta
WHERE renta_media IS NOT NULL
  AND cambio_poblacion_pct IS NOT NULL;

-- =========================================================
-- ANÁLISIS CONJUNTO DE FACTORES
-- Objetivo:
-- Analizar cómo cambia la evolución de la población cuando
-- se combinan dos factores demográficos:
--   1) nivel de envejecimiento
--   2) presencia de población extranjera
-- Esto permite observar si la despoblación se relaciona con
-- la interacción de ambos factores.
-- =========================================================

SELECT
    -- Clasificación del nivel de envejecimiento municipal
    CASE
        WHEN pct_mayor65_medio < 30 THEN 'envejecimiento bajo'
        ELSE 'envejecimiento alto'
    END AS nivel_envejecimiento,

    -- Clasificación de la presencia de población extranjera
    CASE
        WHEN pct_extranjeros_medio < 5 THEN 'extranjeros bajos'
        ELSE 'extranjeros altos'
    END AS nivel_extranjeros,

    -- Número de municipios en cada grupo
    COUNT(*) AS num_municipios,

    -- Cambio medio de población (%) en cada combinación
    ROUND(AVG(cambio_poblacion_pct), 2) AS cambio_poblacion_pct

FROM perfil_municipios

GROUP BY
    nivel_envejecimiento,
    nivel_extranjeros;

-- =========================================================
-- PERFIL COMPARADO DE MUNICIPIOS SEGÚN SU EVOLUCIÓN
-- Objetivo:
-- Comparar las características medias de los municipios que
-- ganan población frente a los que pierden población.
-- =========================================================

SELECT
    CASE
        WHEN cambio_poblacion_pct < 0 THEN 'pierden población'
        ELSE 'ganan o mantienen población'
    END AS evolucion_demografica,

    COUNT(*) AS num_municipios,
    ROUND(AVG(pob_2003), 2) AS pob_2003_media,
    ROUND(AVG(pct_mayor65_medio), 2) AS pct_mayor65_medio,
    ROUND(AVG(pct_extranjeros_medio), 2) AS pct_extranjeros_medio,
    ROUND(AVG(cambio_poblacion_pct), 2) AS cambio_poblacion_pct_medio

FROM perfil_municipios
WHERE pob_2003 IS NOT NULL
  AND cambio_poblacion_pct IS NOT NULL
GROUP BY
    CASE
        WHEN cambio_poblacion_pct < 0 THEN 'pierden población'
        ELSE 'ganan o mantienen población'
    END;

-- =========================================================
-- CLASIFICACIÓN DE MUNICIPIOS SEGÚN EVOLUCIÓN DEMOGRÁFICA
-- Objetivo:
-- Crear una variable que permita distinguir entre municipios
-- que pierden población y municipios que ganan o mantienen
-- población durante el periodo analizado.
--
-- Esta variable facilitará la visualización y el análisis
-- posterior en Tableau.
-- =========================================================

SELECT
    *,
    CASE
        WHEN cambio_poblacion_pct < 0 THEN 'pierde población'
        ELSE 'gana población'
    END AS evolucion

FROM perfil_renta;
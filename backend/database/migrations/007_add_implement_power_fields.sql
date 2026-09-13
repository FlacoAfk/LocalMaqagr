-- Migration: 007_add_implement_power_fields.sql
-- Campos para el cálculo de potencia requerida por implemento (Tabla 1 de Chaparro)
-- y la corrección de pérdida de potencia Zoz & Grisso (2003):
--   - implement.n_tines: cantidad de rejillas (subsolador, arado cincel)
--   - terrain.soil_condition: condición del suelo para la Fig. 47 de Zoz & Grisso
--   - tractor.has_turbo: tractor turboalimentado (sin pérdidas atmosféricas)
--   - query.query_type: ampliar el CHECK a los tipos de cálculo reales
--     ('implement_power' y los tipos directos 'direct_*' que ya se insertan)

ALTER TABLE implement
ADD COLUMN IF NOT EXISTS n_tines INTEGER;

ALTER TABLE terrain
ADD COLUMN IF NOT EXISTS soil_condition VARCHAR(10) CHECK (soil_condition IN ('bueno', 'medio', 'malo'));

ALTER TABLE tractor
ADD COLUMN IF NOT EXISTS has_turbo BOOLEAN NOT NULL DEFAULT FALSE;

-- query.query_type: reemplazar el CHECK original (solo 'power_loss', 'minimum_power',
-- 'recommendation') por la lista completa de tipos que insertan los controladores.
DO $$
DECLARE
    legacy_check TEXT;
BEGIN
    -- Idempotencia: si el constraint nuevo ya existe, no hay nada que hacer
    IF EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conrelid = 'query'::regclass
          AND conname = 'query_query_type_valid'
    ) THEN
        RETURN;
    END IF;

    -- El CHECK original es un constraint de columna sin nombre explícito
    -- (Postgres lo nombra 'query_query_type_check'): se busca por definición
    SELECT conname INTO legacy_check
    FROM pg_constraint
    WHERE conrelid = 'query'::regclass
      AND contype = 'c'
      AND pg_get_constraintdef(oid) LIKE '%query_type%'
    LIMIT 1;

    IF legacy_check IS NOT NULL THEN
        EXECUTE format('ALTER TABLE query DROP CONSTRAINT %I', legacy_check);
    END IF;

    ALTER TABLE query
    ADD CONSTRAINT query_query_type_valid
    CHECK (query_type IN (
        'power_loss', 'direct_power_loss',
        'minimum_power', 'direct_minimum_power',
        'recommendation', 'implement_power'
    ));
END $$;

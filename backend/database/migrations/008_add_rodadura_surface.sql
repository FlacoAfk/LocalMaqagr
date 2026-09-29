-- Migration: 008_add_rodadura_surface.sql
-- Superficie de rodadura del terreno para el coeficiente ρ de la cadena V3
-- del profesor (lámina 26 de la expo "Potencia disponible y requerida"):
--   P_ROD = W·V·(ρ·cosα + senα)/274,4
-- Valores: concreto | carretable | arcilloso_humedo | arcilloso_seco | limoso | arena_suelta

ALTER TABLE terrain
ADD COLUMN IF NOT EXISTS superficie_rodadura VARCHAR(20) CHECK (superficie_rodadura IN ('concreto', 'carretable', 'arcilloso_humedo', 'arcilloso_seco', 'limoso', 'arena_suelta'));

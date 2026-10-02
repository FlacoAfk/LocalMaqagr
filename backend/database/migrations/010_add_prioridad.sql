-- 010: Prioridad de catálogo — tractores curados con ficha oficial del fabricante
-- aparecen primero en el catálogo.
ALTER TABLE tractor ADD COLUMN IF NOT EXISTS prioridad BOOLEAN DEFAULT FALSE;

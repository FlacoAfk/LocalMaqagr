-- 009: Enlace a la ficha técnica en PDF (prueba Nebraska) por tractor.
-- Se guarda solo el LINK (no el archivo) para no incrementar el peso del instalador.
ALTER TABLE tractor ADD COLUMN IF NOT EXISTS ficha_pdf_url VARCHAR(500);

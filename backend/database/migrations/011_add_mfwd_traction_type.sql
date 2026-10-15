-- Preserve the four tractor driveline categories used by the UI and power model.
ALTER TABLE tractor
  DROP CONSTRAINT IF EXISTS tractor_traction_type_check;

ALTER TABLE tractor
  ADD CONSTRAINT tractor_traction_type_check
  CHECK (traction_type IN ('4x2', 'mfwd', '4x4', 'track'));

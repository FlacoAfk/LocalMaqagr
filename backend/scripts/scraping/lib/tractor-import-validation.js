const VALID_TRACTION_TYPES = new Set(['4x2', 'mfwd', '4x4', 'track']);

export const validateTractorImportRecord = (record) => {
  const problems = [];

  if (!record.name || record.name.length > 150) problems.push('name inválido');
  if (!record.brand) problems.push('sin brand');
  if (!record.model) problems.push('sin model');
  if (record.engine_power_hp == null) problems.push('sin engine_power_hp');
  if (record.weight_kg == null) problems.push('sin weight_kg');
  if (record.traction_force_kn == null) problems.push('sin traction_force_kn');
  if (!VALID_TRACTION_TYPES.has(record.traction_type)) {
    problems.push(`traction_type inválido: ${record.traction_type}`);
  }
  if (record.image_url && !/^(https?:\/\/|\/uploads\/)/.test(record.image_url)) {
    problems.push('image_url inválida');
  }

  return problems;
};

// 0,85 = ec. 29 de Zoz & Grisso ("PTO power = (0.85)(Flywheel power)"); el profesor:
// "no siempre el 85 % de P_b". El 246,88 de la hoja H2 exige 0,85 (no 0,86).
const DEFAULT_TDP_RATIO = 0.85;

const TRACTION_TYPE_ALIASES = new Map([
  ["4x2", "4x2"],
  ["2wd", "4x2"],
  ["mfwd", "mfwd"],
  ["4x4", "4x4"],
  ["4wd", "4x4"],
  ["track", "track"],
  ["tracks", "track"],
  ["belt", "track"],
  ["oruga", "track"],
  ["orugas", "track"],
]);

/** Updates tractor power fields without coupling a manual TDP edit back to gross power. */
export function updateTractorPowerFields(previous, name, value) {
  const next = { ...previous, [name]: value };

  if (name === "pb") {
    const grossPower = Number(value);
    next.pmax_tdp = value !== "" && Number.isFinite(grossPower) && grossPower > 0
      ? String(+(grossPower * DEFAULT_TDP_RATIO).toFixed(1))
      : "";
  }

  return next;
}

/** Estimates TDP only when the gross power is known. */
export function getEstimatedTdp(grossPowerValue) {
  const grossPower = Number(grossPowerValue);
  if (grossPowerValue === "" || !Number.isFinite(grossPower) || grossPower <= 0) return "";
  return String(+(grossPower * DEFAULT_TDP_RATIO).toFixed(1));
}

/** Normalizes catalog traction values to the codes used by the calculation service. */
export function normalizeTractorTractionType(value) {
  const normalized = String(value ?? "").trim().toLowerCase();
  return TRACTION_TYPE_ALIASES.get(normalized) ?? "4x2";
}

/** Reads either the API camelCase field or the raw database snake_case field. */
export function getTractorTractionType(tractor) {
  return normalizeTractorTractionType(tractor?.tractionType || tractor?.traction_type);
}

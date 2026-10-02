// 0,85 = ec. 29 de Zoz & Grisso ("PTO power = (0.85)(Flywheel power)"); el profesor:
// "no siempre el 85 % de P_b". El 246,88 de la hoja H2 exige 0,85 (no 0,86).
const DEFAULT_TDP_RATIO = 0.85;

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

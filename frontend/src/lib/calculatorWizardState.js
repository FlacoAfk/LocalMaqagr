export function getAvailableTractorPower(netPowerHp, grossPowerHp) {
  return netPowerHp ?? grossPowerHp ?? 100;
}

export function createImplementWizardForm() {
  return {
    implement_type: "",
    working_width_m: "",
    working_depth_cm: "",
    weight_kg: "",
    working_speed_kmh: "",
    power_requirement_hp: "",
    n_tines: "",
    tiro: "",
    draft_unit: "kg/m",
    n_surcos: "",
    implement_weight_kg: "",
    soil_type: "",
    slope_percentage: "",
  };
}

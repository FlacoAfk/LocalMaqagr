/**
 * Schemas globales de Swagger/OpenAPI
 * Define todos los modelos de datos, respuestas y errores
 */

export const schemas = {
  // ==========================================
  // RESPUESTAS GLOBALES
  // ==========================================
  SuccessResponse: {
    type: 'object',
    properties: {
      success: {
        type: 'boolean',
        example: true,
      },
      message: {
        type: 'string',
        example: 'Operación exitosa',
      },
      data: {
        type: 'object',
        description: 'Datos de la respuesta (varía según el endpoint)',
      },
    },
  },

  ErrorResponse: {
    type: 'object',
    properties: {
      success: {
        type: 'boolean',
        example: false,
      },
      code: {
        type: 'string',
        example: 'VALIDATION_ERROR',
        description: 'Código estable para manejo de errores en frontend',
      },
      message: {
        type: 'string',
        example: 'Error en la operación',
      },
      errors: {
        type: 'array',
        items: { type: 'string' },
        description: 'Lista detallada de errores (opcional)',
        example: ['Campo requerido faltante', 'Formato inválido'],
      },
    },
  },

  PaginatedResponse: {
    type: 'object',
    properties: {
      success: {
        type: 'boolean',
        example: true,
      },
      data: {
        type: 'array',
        items: { type: 'object' },
      },
      pagination: {
        type: 'object',
        properties: {
          total: { type: 'integer', example: 50 },
          limit: { type: 'integer', example: 10 },
          page: { type: 'integer', example: 1 },
          pages: { type: 'integer', example: 5 },
        },
      },
    },
  },

  // ==========================================
  // AUTH SCHEMAS
  // ==========================================
  UserRegister: {
    type: 'object',
    required: ['name', 'email', 'password'],
    properties: {
      name: {
        type: 'string',
        minLength: 1,
        example: 'Juan Pérez',
        description: 'Nombre completo del usuario',
      },
      email: {
        type: 'string',
        format: 'email',
        example: 'juan@example.com',
        description: 'Email único del usuario',
      },
      password: {
        type: 'string',
        minLength: 8,
        example: 'MiPassword123!',
        description: 'Contraseña segura (mín. 8 caracteres, mayúscula, minúscula, número y carácter especial)',
      },
    },
  },

  UserLogin: {
    type: 'object',
    required: ['email', 'password'],
    properties: {
      email: {
        type: 'string',
        format: 'email',
        example: 'juan@example.com',
      },
      password: {
        type: 'string',
        example: 'MiPassword123!',
      },
    },
  },

  UserProfile: {
    type: 'object',
    properties: {
      user_id: { type: 'integer', example: 1 },
      name: { type: 'string', example: 'Juan Pérez' },
      email: { type: 'string', format: 'email', example: 'juan@example.com' },
      role_id: { type: 'integer', example: 2 },
      role_name: { type: 'string', example: 'user' },
      status: { type: 'string', enum: ['active', 'inactive', 'suspended'], example: 'active' },
      registration_date: { type: 'string', format: 'date-time' },
      last_session: { type: 'string', format: 'date-time', nullable: true },
    },
  },

  UpdateProfile: {
    type: 'object',
    properties: {
      name: {
        type: 'string',
        example: 'Juan Pérez Actualizado',
        description: 'Nuevo nombre (opcional)',
      },
      email: {
        type: 'string',
        format: 'email',
        example: 'nuevo@example.com',
        description: 'Nuevo email (opcional)',
      },
    },
  },

  ChangePassword: {
    type: 'object',
    required: ['currentPassword', 'newPassword'],
    properties: {
      currentPassword: {
        type: 'string',
        example: 'MiPasswordActual123!',
        description: 'Contraseña actual del usuario',
      },
      newPassword: {
        type: 'string',
        minLength: 8,
        example: 'NuevaPassword456!',
        description: 'Nueva contraseña segura',
      },
    },
  },

  AuthResponse: {
    type: 'object',
    properties: {
      token: {
        type: 'string',
        example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
        description: 'Token JWT para autenticación',
      },
      user: {
        type: 'object',
        properties: {
          id: { type: 'integer', example: 1 },
          name: { type: 'string', example: 'Juan Pérez' },
          email: { type: 'string', example: 'juan@example.com' },
        },
      },
      role: {
        type: 'string',
        enum: ['admin', 'user', 'operator'],
        example: 'user',
      },
      role_id: { type: 'integer', example: 2 },
    },
  },

  LoginResponse: {
    type: 'object',
    properties: {
      token: {
        type: 'string',
        example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
      },
      user: {
        type: 'object',
        properties: {
          id: { type: 'integer', example: 1 },
          name: { type: 'string', example: 'Juan Pérez' },
          email: { type: 'string', example: 'juan@example.com' },
        },
      },
      role: {
        type: 'string',
        enum: ['admin', 'user', 'operator'],
        example: 'user',
      },
      role_id: { type: 'integer', example: 2 },
    },
  },

  // ==========================================
  // TRACTOR SCHEMAS
  // ==========================================
  Tractor: {
    type: 'object',
    properties: {
      tractor_id: { type: 'integer', example: 1 },
      name: { type: 'string', example: 'John Deere 6130M' },
      brand: { type: 'string', example: 'John Deere' },
      model: { type: 'string', example: '6130M' },
      image_url: { type: 'string', format: 'uri', example: '/uploads/tractors/example.jpg', nullable: true },
      model_year: { type: 'integer', example: 2024, nullable: true },
      engine_power_hp: { type: 'number', format: 'float', example: 130.0 },
      price: { type: 'number', format: 'float', example: 85000.0, nullable: true },
      weight_kg: { type: 'number', format: 'float', example: 5200.0 },
      traction_force_kn: { type: 'number', format: 'float', example: 45.5, nullable: true },
      traction_type: { type: 'string', enum: ['4x2', '4x4', 'track'], example: '4x4' },
      tire_type: { type: 'string', example: 'radial', nullable: true },
      tire_width_mm: { type: 'number', format: 'float', example: 540, nullable: true },
      tire_diameter_mm: { type: 'number', format: 'float', example: 1600, nullable: true },
      tire_pressure_psi: { type: 'number', format: 'float', example: 15.0, nullable: true },
      status: { type: 'string', enum: ['available', 'maintenance', 'inactive'], example: 'available' },
    },
  },

  TractorCreate: {
    type: 'object',
    required: ['brand', 'model', 'engine_power_hp', 'traction_type'],
    properties: {
      name: { type: 'string', example: 'John Deere 6130M' },
      brand: { type: 'string', example: 'John Deere' },
      model: { type: 'string', example: '6130M' },
      image_url: { type: 'string', format: 'uri', example: '/uploads/tractors/example.jpg' },
      model_year: { type: 'integer', example: 2024 },
      engine_power_hp: { type: 'number', format: 'float', example: 130.0, description: 'Potencia del motor en HP (debe ser positivo)' },
      price: { type: 'number', format: 'float', example: 85000.0, description: 'Precio de referencia del tractor (debe ser positivo)' },
      weight_kg: { type: 'number', format: 'float', example: 5200.0, description: 'Peso en kg (debe ser positivo)' },
      traction_force_kn: { type: 'number', format: 'float', example: 45.5 },
      traction_type: { type: 'string', enum: ['4x2', '4x4', 'track'], example: '4x4' },
      tire_type: { type: 'string', example: 'radial' },
      tire_width_mm: { type: 'number', format: 'float', example: 540 },
      tire_diameter_mm: { type: 'number', format: 'float', example: 1600 },
      tire_pressure_psi: { type: 'number', format: 'float', example: 15.0 },
      status: { type: 'string', enum: ['available', 'maintenance', 'inactive'], default: 'available' },
    },
  },

  TractorUpdate: {
    type: 'object',
    properties: {
      name: { type: 'string', example: 'John Deere 6130M Updated' },
      brand: { type: 'string', example: 'John Deere' },
      model: { type: 'string', example: '6130M' },
      image_url: { type: 'string', format: 'uri', example: '/uploads/tractors/example.jpg' },
      model_year: { type: 'integer', example: 2025 },
      engine_power_hp: { type: 'number', format: 'float', example: 135.0 },
      price: { type: 'number', format: 'float', example: 87000.0 },
      weight_kg: { type: 'number', format: 'float', example: 5300.0 },
      traction_force_kn: { type: 'number', format: 'float', example: 46.0 },
      traction_type: { type: 'string', enum: ['4x2', '4x4', 'track'] },
      tire_type: { type: 'string' },
      tire_width_mm: { type: 'number', format: 'float' },
      tire_diameter_mm: { type: 'number', format: 'float' },
      tire_pressure_psi: { type: 'number', format: 'float' },
      status: { type: 'string', enum: ['available', 'maintenance', 'inactive'] },
    },
  },

  // ==========================================
  // IMPLEMENT SCHEMAS
  // ==========================================
  Implement: {
    type: 'object',
    properties: {
      implement_id: { type: 'integer', example: 1 },
      implement_name: { type: 'string', example: 'Arado de discos 3 cuerpos' },
      brand: { type: 'string', example: 'Baldan' },
      image_url: { type: 'string', format: 'uri', example: '/uploads/implements/example.jpg', nullable: true },
      power_requirement_hp: { type: 'number', format: 'float', example: 85.0 },
      working_width_m: { type: 'number', format: 'float', example: 1.2 },
      soil_type: { type: 'string', example: 'clay', description: 'Tipo de suelo compatible' },
      working_depth_cm: { type: 'number', format: 'float', example: 30.0 },
      weight_kg: { type: 'number', format: 'float', example: 450.0 },
      implement_type: {
        type: 'string',
        enum: [
          'plow', 'harrow', 'seeder', 'sprayer', 'harvester', 'cultivator', 'mower', 'trailer', 'other',
          'arado_disco_vertedera', 'subsolador', 'arado_cincel', 'implemento_rotativo',
          'rastrillo_simple_discos', 'rastrillo_pulidor', 'rastrillo_californiano',
          'rastra_pesada_26', 'rastra_pesada_24',
        ],
        example: 'plow',
      },
      status: { type: 'string', enum: ['available', 'maintenance', 'inactive'], example: 'available' },
    },
  },

  ImplementCreate: {
    type: 'object',
    required: ['implement_name', 'implement_type'],
    properties: {
      implement_name: { type: 'string', example: 'Arado de discos 3 cuerpos' },
      brand: { type: 'string', example: 'Baldan' },
      image_url: { type: 'string', format: 'uri', example: '/uploads/implements/example.jpg' },
      power_requirement_hp: { type: 'number', format: 'float', example: 85.0 },
      working_width_m: { type: 'number', format: 'float', example: 1.2 },
      soil_type: { type: 'string', example: 'clay' },
      working_depth_cm: { type: 'number', format: 'float', example: 30.0 },
      weight_kg: { type: 'number', format: 'float', example: 450.0 },
      implement_type: {
        type: 'string',
        enum: [
          'plow', 'harrow', 'seeder', 'sprayer', 'harvester', 'cultivator', 'mower', 'trailer', 'other',
          'arado_disco_vertedera', 'subsolador', 'arado_cincel', 'implemento_rotativo',
          'rastrillo_simple_discos', 'rastrillo_pulidor', 'rastrillo_californiano',
          'rastra_pesada_26', 'rastra_pesada_24',
        ],
        example: 'plow',
      },
      status: { type: 'string', enum: ['available', 'maintenance', 'inactive'], default: 'available' },
    },
  },

  ImplementUpdate: {
    type: 'object',
    properties: {
      implement_name: { type: 'string', example: 'Arado actualizado' },
      brand: { type: 'string', example: 'Baldan' },
      image_url: { type: 'string', format: 'uri', example: '/uploads/implements/example.jpg' },
      power_requirement_hp: { type: 'number', format: 'float', example: 90.0 },
      working_width_m: { type: 'number', format: 'float', example: 1.4 },
      soil_type: { type: 'string', example: 'loam' },
      working_depth_cm: { type: 'number', format: 'float', example: 35.0 },
      weight_kg: { type: 'number', format: 'float', example: 470.0 },
      implement_type: {
        type: 'string',
        enum: [
          'plow', 'harrow', 'seeder', 'sprayer', 'harvester', 'cultivator', 'mower', 'trailer', 'other',
          'arado_disco_vertedera', 'subsolador', 'arado_cincel', 'implemento_rotativo',
          'rastrillo_simple_discos', 'rastrillo_pulidor', 'rastrillo_californiano',
          'rastra_pesada_26', 'rastra_pesada_24',
        ],
      },
      status: { type: 'string', enum: ['available', 'maintenance', 'inactive'] },
    },
  },

  // ==========================================
  // TERRAIN SCHEMAS
  // ==========================================
  Terrain: {
    type: 'object',
    properties: {
      terrain_id: { type: 'integer', example: 1 },
      user_id: { type: 'integer', example: 1 },
      name: { type: 'string', example: 'Parcela Norte' },
      altitude_meters: { type: 'number', format: 'float', example: 2500.0 },
      slope_percentage: { type: 'number', format: 'float', example: 15.0 },
      soil_type: { type: 'string', example: 'clay', description: 'Tipo de suelo: clay, loam, sand, firm, soft' },
      temperature_celsius: { type: 'number', format: 'float', example: 18.0, nullable: true },
      status: { type: 'string', enum: ['active', 'inactive'], example: 'active' },
    },
  },

  TerrainCreate: {
    type: 'object',
    required: ['name', 'altitude_meters', 'slope_percentage', 'soil_type'],
    properties: {
      name: {
        type: 'string',
        example: 'Parcela Norte',
        description: 'Nombre descriptivo del terreno',
      },
      altitude_meters: {
        type: 'number',
        format: 'float',
        example: 2500.0,
        description: 'Altitud en metros sobre el nivel del mar',
      },
      slope_percentage: {
        type: 'number',
        format: 'float',
        example: 15.0,
        description: 'Pendiente del terreno en porcentaje',
      },
      soil_type: {
        type: 'string',
        example: 'clay',
        description: 'Tipo de suelo (clay, loam, sand, firm, soft)',
      },
      temperature_celsius: {
        type: 'number',
        format: 'float',
        example: 18.0,
        description: 'Temperatura promedio en °C (opcional)',
        nullable: true,
      },
      status: {
        type: 'string',
        enum: ['active', 'inactive'],
        default: 'active',
      },
    },
  },

  TerrainUpdate: {
    type: 'object',
    properties: {
      name: { type: 'string', example: 'Parcela Norte Actualizada' },
      altitude_meters: { type: 'number', format: 'float', example: 2600.0 },
      slope_percentage: { type: 'number', format: 'float', example: 12.0 },
      soil_type: { type: 'string', example: 'loam' },
      temperature_celsius: { type: 'number', format: 'float', example: 20.0 },
      status: { type: 'string', enum: ['active', 'inactive'] },
    },
  },

  // ==========================================
  // CALCULATION SCHEMAS
  // ==========================================
  PowerLossRequest: {
    type: 'object',
    required: ['tractor_id', 'terrain_id', 'working_speed_kmh'],
    properties: {
      tractor_id: {
        type: 'integer',
        example: 1,
        description: 'ID del tractor',
      },
      terrain_id: {
        type: 'integer',
        example: 1,
        description: 'ID del terreno',
      },
      working_speed_kmh: {
        type: 'number',
        format: 'float',
        example: 7.5,
        description: 'Velocidad de trabajo en km/h',
      },
      carried_objects_weight_kg: {
        type: 'number',
        format: 'float',
        example: 500,
        default: 0,
        description: 'Peso de objetos transportados en kg (default: 0)',
      },
      slippage_percent: {
        type: 'number',
        format: 'float',
        example: 10,
        default: 10,
        description: 'Porcentaje de deslizamiento (default: 10%)',
      },
    },
  },

  DirectPowerLossRequest: {
    type: 'object',
    required: ['engine_power_hp', 'weight_kg', 'soil_type', 'altitude_m', 'ambient_temperature_c', 'slope_percent', 'slippage_percent'],
    properties: {
      engine_power_hp: {
        type: 'number',
        format: 'float',
        example: 130.0,
        description: 'Potencia del motor en HP',
      },
      weight_kg: {
        type: 'number',
        format: 'float',
        example: 5200.0,
        description: 'Peso del tractor en kg',
      },
      soil_type: {
        type: 'string',
        example: 'clay',
        description: 'Tipo de suelo (clay, loam, sandy, rocky, firm, soft)',
      },
      altitude_m: {
        type: 'number',
        format: 'float',
        example: 2500.0,
        description: 'Altitud en metros sobre el nivel del mar',
      },
      ambient_temperature_c: {
        type: 'number',
        format: 'float',
        example: 25.0,
        description: 'Temperatura ambiente en grados Celsius',
      },
      slope_percent: {
        type: 'number',
        format: 'float',
        example: 15.0,
        description: 'Pendiente del terreno en porcentaje',
      },
      slippage_percent: {
        type: 'number',
        format: 'float',
        example: 10.0,
        description: 'Porcentaje de deslizamiento',
      },
      has_turbo: {
        type: 'boolean',
        example: false,
        description: 'Si el tractor tiene turbo, se ignora la perdida por altitud y temperatura',
      },
      working_speed_kmh: {
        type: 'number',
        format: 'float',
        example: 7.0,
        default: 7,
        description: 'Velocidad de trabajo en km/h (default: 7)',
      },
      carried_objects_weight_kg: {
        type: 'number',
        format: 'float',
        example: 0,
        default: 0,
        description: 'Peso de objetos transportados en kg (default: 0)',
      },
    },
  },

  DirectMinimumPowerRequest: {
    type: 'object',
    required: ['power_requirement_hp', 'soil_type', 'slope_percentage'],
    properties: {
      power_requirement_hp: {
        type: 'number',
        format: 'float',
        example: 85.0,
        description: 'Potencia requerida por el implemento en HP',
      },
      soil_type: {
        type: 'string',
        example: 'clay',
        description: 'Tipo de suelo (clay, loam, sandy, rocky, firm, soft)',
      },
      slope_percentage: {
        type: 'number',
        format: 'float',
        example: 15.0,
        description: 'Pendiente del terreno en porcentaje',
      },
      working_depth_m: {
        type: 'number',
        format: 'float',
        example: 0.25,
        default: 0.25,
        description: 'Profundidad de trabajo en metros (default: 0.25, max: 1.0)',
      },
    },
  },

  // ==========================================
  // IMPLEMENT POWER SCHEMAS (Tabla 1 Chaparro + Zoz & Grisso)
  // ==========================================
  DirectImplementPowerRequest: {
    type: 'object',
    description: 'Datos del cálculo directo de potencia por implemento (Tabla 1 — Chaparro). '
      + 'Modos de respuesta según los datos del tractor: '
      + '(a) sin engine_power_hp → la respuesta incluye solo power_required_hp, power_kind, detail y warnings; '
      + '(b) con engine_power_hp (opcionalmente traction_type y soil_condition) → agrega available_power_hp, '
      + 'pto_available_power_hp, margin_hp, is_adequate, classification, losses y zoz.',
    required: ['implement_type', 'working_width_m', 'soil_type'],
    properties: {
      implement_type: {
        type: 'string',
        enum: [
          'arado_disco_vertedera',
          'subsolador',
          'arado_cincel',
          'implemento_rotativo',
          'rastrillo_simple_discos',
          'rastrillo_pulidor',
          'rastrillo_californiano',
          'rastra_pesada_26',
          'rastra_pesada_24',
        ],
        example: 'rastra_pesada_26',
        description: 'Tipo de implemento según la Tabla 1 de Chaparro',
      },
      working_width_m: {
        type: 'number',
        format: 'float',
        example: 3.0,
        description: 'Ancho de trabajo en metros (0.1 a 50)',
      },
      working_depth_cm: {
        type: 'number',
        format: 'float',
        example: 15.0,
        description: 'Profundidad de trabajo en cm (0 a 100). Requerida para arado_disco_vertedera, subsolador y arado_cincel',
      },
      working_speed_kmh: {
        type: 'number',
        format: 'float',
        example: 7.5,
        description: 'Velocidad de trabajo en km/h (> 0 y < 40). Requerida para implementos de tiro (drawbar); no aplica a implemento_rotativo',
      },
      n_tines: {
        type: 'integer',
        example: 5,
        description: 'Cantidad de rejillas (1 a 20). Requerida para subsolador y arado_cincel',
      },
      soil_type: {
        type: 'string',
        example: 'arcilla',
        description: 'Tipo de suelo: arena/arenoso/sand, limo/silt, arcilla/arcilloso/clay. franco/loam se mapea a limo con advertencia',
      },
      engine_power_hp: {
        type: 'number',
        format: 'float',
        example: 100.0,
        description: 'Potencia bruta del motor del tractor en HP. Opcional: sin este campo la respuesta incluye solo la potencia requerida por el implemento (modo a)',
      },
      traction_type: {
        type: 'string',
        example: '4x2',
        description: "Tipo de tracción del tractor: '4x2'/'2wd', 'mfwd', '4x4'/'4wd', 'track'/'oruga'/'belt' (default: 2WD)",
      },
      soil_condition: {
        type: 'string',
        enum: ['bueno', 'medio', 'malo'],
        example: 'bueno',
        default: 'medio',
        description: "Condición del suelo para la corrección Zoz & Grisso (Fig. 47)",
      },
      has_turbo: {
        type: 'boolean',
        example: true,
        default: false,
        description: 'Si el tractor tiene turbo, se ignoran las pérdidas por altitud y temperatura',
      },
      altitude_m: {
        type: 'number',
        format: 'float',
        example: 0,
        default: 0,
        description: 'Altitud en metros sobre el nivel del mar (default: 0)',
      },
      ambient_temperature_c: {
        type: 'number',
        format: 'float',
        example: 15.0,
        default: 15,
        description: 'Temperatura ambiente en °C (default: 15)',
      },
      total_weight_kg: {
        type: 'number',
        format: 'float',
        example: 0,
        default: 0,
        description: 'Peso total del tractor en kg (default: 0, sin pérdida por rodadura)',
      },
      slope_percent: {
        type: 'number',
        format: 'float',
        example: 0,
        default: 0,
        description: 'Pendiente del terreno en porcentaje (default: 0)',
      },
    },
  },

  DirectImplementPowerResponse: {
    type: 'object',
    description: 'Respuesta del cálculo directo de potencia por implemento, con dos modos: '
      + '(a) sin datos del tractor (sin engine_power_hp) → data incluye solo power_required_hp, power_kind, detail y warnings; '
      + '(b) con engine_power_hp (+ traction_type, soil_condition) → agrega available_power_hp, pto_available_power_hp, '
      + 'margin_hp, is_adequate, classification, losses y zoz.',
    properties: {
      success: { type: 'boolean', example: true },
      message: { type: 'string', example: 'Cálculo directo de potencia por implemento realizado con éxito' },
      data: {
        type: 'object',
        description: 'Modo (a) sin tractor: solo potencia requerida. Modo (b) con tractor: agrega la comparación contra la potencia disponible y la clasificación.',
        properties: {
          power_required_hp: { type: 'number', format: 'float', example: 82.13, description: 'Potencia requerida por el implemento (Tabla 1)' },
          power_kind: { type: 'string', enum: ['drawbar', 'pto'], example: 'drawbar', description: "Barra de tiro (drawbar) o toma de fuerza (pto)" },
          available_power_hp: { type: 'number', format: 'float', example: 47.1, description: 'Potencia neta disponible en la barra de tiro (ruta Zoz). Solo en modo (b), con datos del tractor' },
          pto_available_power_hp: { type: 'number', format: 'float', example: 45.22, description: 'Potencia disponible en la TDF (eje × eficiencia Fig. 47). Solo en modo (b), con datos del tractor' },
          margin_hp: { type: 'number', format: 'float', example: -35.03, description: 'Diferencia disponible − requerida (según power_kind). Solo en modo (b), con datos del tractor' },
          is_adequate: { type: 'boolean', example: false, description: 'true si margin_hp >= 0. Solo en modo (b), con datos del tractor' },
          classification: { type: 'string', enum: ['ADECUADO', 'NO_ADECUADO', 'SOBREPOTENCIADO'], example: 'NO_ADECUADO', description: 'SOBREPOTENCIADO cuando el excedente supera el 25%. Solo en modo (b), con datos del tractor' },
          detail: { type: 'object', description: 'Desglose del cálculo: familia, coeficiente, constantes usadas, fuerza de tiro, etc.' },
          warnings: { type: 'array', items: { type: 'string' }, description: 'Advertencias (mapeo de suelo, velocidad fuera de rango 4-10 km/h)' },
          losses: { type: 'object', description: 'Desglose de pérdidas (altitud, temperatura, transmisión Zoz, rodadura, pendiente). Solo en modo (b), con datos del tractor' },
          zoz: { type: 'object', description: 'Detalle de la corrección Zoz & Grisso: condición de suelo, tipo de tractor, pérdida de eje, eficiencia TDF. Solo en modo (b), con datos del tractor' },
        },
      },
    },
  },

  ImplementPowerRequest: {
    type: 'object',
    required: ['tractor_id', 'terrain_id'],
    properties: {
      tractor_id: {
        type: 'integer',
        example: 1,
        description: 'ID del tractor',
      },
      terrain_id: {
        type: 'integer',
        example: 1,
        description: 'ID del terreno',
      },
      implement_id: {
        type: 'integer',
        example: 1,
        description: 'ID del implemento. Opcional si se envían los parámetros explícitos del implemento (implement_type, working_width_m, ...)',
      },
      implement_type: {
        type: 'string',
        enum: [
          'arado_disco_vertedera',
          'subsolador',
          'arado_cincel',
          'implemento_rotativo',
          'rastrillo_simple_discos',
          'rastrillo_pulidor',
          'rastrillo_californiano',
          'rastra_pesada_26',
          'rastra_pesada_24',
        ],
        example: 'rastra_pesada_26',
        description: 'Tipo de implemento (requerido si no se envía implement_id)',
      },
      working_width_m: {
        type: 'number',
        format: 'float',
        example: 3.0,
        description: 'Ancho de trabajo en metros, 0.1 a 50 (requerido si no se envía implement_id)',
      },
      working_depth_cm: {
        type: 'number',
        format: 'float',
        example: 15.0,
        description: 'Profundidad en cm, 0 a 100 (requerida para arado_disco_vertedera, subsolador y arado_cincel si no se envía implement_id)',
      },
      n_tines: {
        type: 'integer',
        example: 5,
        description: 'Cantidad de rejillas, 1 a 20 (requerida para subsolador y arado_cincel si no se envía implement_id)',
      },
      working_speed_kmh: {
        type: 'number',
        format: 'float',
        example: 7.5,
        description: 'Velocidad de trabajo en km/h (> 0 y < 40). Requerida para implementos de tiro (drawbar)',
      },
      soil_condition: {
        type: 'string',
        enum: ['bueno', 'medio', 'malo'],
        example: 'medio',
        description: "Condición del suelo (fallback si el terreno no tiene soil_condition; default: 'medio')",
      },
      carried_objects_weight_kg: {
        type: 'number',
        format: 'float',
        example: 0,
        default: 0,
        description: 'Peso de objetos transportados en kg (default: 0)',
      },
      has_turbo: {
        type: 'boolean',
        example: true,
        description: 'Si el tractor tiene turbo (prioridad sobre la columna has_turbo de la BD)',
      },
    },
  },

  ImplementPowerResponse: {
    type: 'object',
    properties: {
      success: { type: 'boolean', example: true },
      message: { type: 'string', example: 'Cálculo de potencia por implemento realizado con éxito' },
      data: {
        type: 'object',
        properties: {
          queryId: { type: 'integer', example: 12, nullable: true, description: 'ID de la consulta persistida (null si la persistencia fue omitida)' },
          power_required_hp: { type: 'number', format: 'float', example: 82.13 },
          power_kind: { type: 'string', enum: ['drawbar', 'pto'], example: 'drawbar' },
          available_power_hp: { type: 'number', format: 'float', example: 47.1, description: 'Potencia neta en la barra de tiro (ruta Zoz)' },
          pto_available_power_hp: { type: 'number', format: 'float', example: 45.22, description: 'Potencia disponible en la TDF' },
          margin_hp: { type: 'number', format: 'float', example: -35.03 },
          is_adequate: { type: 'boolean', example: false },
          classification: { type: 'string', enum: ['ADECUADO', 'NO_ADECUADO', 'SOBREPOTENCIADO'], example: 'NO_ADECUADO' },
          detail: { type: 'object', description: 'Desglose del cálculo de potencia requerida (Tabla 1)' },
          warnings: { type: 'array', items: { type: 'string' } },
          losses: { type: 'object', description: 'Desglose de pérdidas de potencia' },
          zoz: { type: 'object', description: 'Detalle de la corrección Zoz & Grisso (Fig. 43 y 47)' },
          implement: {
            type: 'object',
            properties: {
              id: { type: 'integer', example: 1, nullable: true },
              type: { type: 'string', example: 'rastra_pesada_26' },
              name: { type: 'string', example: 'Rastra pesada de 26 discos' },
            },
          },
          terrain: {
            type: 'object',
            properties: {
              id: { type: 'integer', example: 1 },
              name: { type: 'string', example: 'Parcela Norte' },
              soil_type: { type: 'string', example: 'Arcilla' },
              soil_condition: { type: 'string', example: 'medio' },
            },
          },
          tractor: {
            type: 'object',
            properties: {
              id: { type: 'integer', example: 1 },
              brand: { type: 'string', example: 'John Deere' },
              model: { type: 'string', example: '5075E' },
              traction_type: { type: 'string', example: '4x4' },
              engine_power_hp: { type: 'number', format: 'float', example: 75.0 },
              hasTurbo: { type: 'boolean', example: false },
            },
          },
        },
      },
    },
  },

  PowerLossResponse: {
    type: 'object',
    properties: {
      success: { type: 'boolean', example: true },
      message: { type: 'string', example: 'Cálculo realizado con éxito' },
      data: {
        type: 'object',
        properties: {
          queryId: { type: 'integer', example: 1 },
          tractor: {
            type: 'object',
            properties: {
              brand: { type: 'string', example: 'John Deere' },
              model: { type: 'string', example: '6130M' },
            },
          },
          terrain: {
            type: 'object',
            properties: {
              name: { type: 'string', example: 'Parcela Norte' },
              soil_type: { type: 'string', example: 'clay' },
            },
          },
          losses: {
            type: 'object',
            properties: {
              slope_loss_hp: { type: 'number', format: 'float', example: 5.2 },
              altitude_loss_hp: { type: 'number', format: 'float', example: 8.1 },
              rolling_resistance_loss_hp: { type: 'number', format: 'float', example: 12.3 },
              slippage_loss_hp: { type: 'number', format: 'float', example: 6.7 },
              total_loss_hp: { type: 'number', format: 'float', example: 32.3 },
            },
          },
          net_power_hp: { type: 'number', format: 'float', example: 97.7 },
          engine_power_hp: { type: 'number', format: 'float', example: 130.0 },
          efficiency_percentage: { type: 'number', format: 'float', example: 75.15 },
        },
      },
    },
  },

  MinimumPowerRequest: {
    type: 'object',
    required: ['implement_id', 'terrain_id'],
    properties: {
      implement_id: {
        type: 'integer',
        example: 1,
        description: 'ID del implemento agrícola',
      },
      terrain_id: {
        type: 'integer',
        example: 1,
        description: 'ID del terreno',
      },
      working_depth_m: {
        type: 'number',
        format: 'float',
        example: 0.3,
        description: 'Profundidad de trabajo en metros (opcional, máx 1.0). Si no se provee, usa la del implemento.',
      },
    },
  },

  MinimumPowerResponse: {
    type: 'object',
    properties: {
      success: { type: 'boolean', example: true },
      message: { type: 'string', example: 'Cálculo de potencia mínima completado' },
      data: {
        type: 'object',
        properties: {
          queryId: { type: 'integer', example: 5 },
          implement: {
            type: 'object',
            properties: {
              id: { type: 'integer', example: 1 },
              name: { type: 'string', example: 'Arado de discos' },
              type: { type: 'string', example: 'plow' },
            },
          },
          terrain: {
            type: 'object',
            properties: {
              id: { type: 'integer', example: 1 },
              name: { type: 'string', example: 'Parcela Norte' },
              soil_type: { type: 'string', example: 'clay' },
            },
          },
          powerRequirement: {
            type: 'object',
            properties: {
              minimum_power_hp: { type: 'number', format: 'float', example: 95.5 },
              factors: { type: 'object' },
            },
          },
          compatibleTractors: {
            type: 'array',
            items: {
              type: 'object',
              properties: {
                tractor_id: { type: 'integer' },
                name: { type: 'string' },
                brand: { type: 'string' },
                model: { type: 'string' },
                engine_power_hp: { type: 'number', format: 'float' },
                suitability: {
                  type: 'object',
                  properties: {
                    score: { type: 'string', enum: ['OPTIMAL', 'OVERPOWERED', 'INSUFFICIENT'] },
                    label: { type: 'string' },
                    color: { type: 'string' },
                    utilizationPercent: { type: 'integer' },
                    isCompatible: { type: 'boolean' },
                  },
                },
              },
            },
          },
        },
      },
    },
  },

  // ==========================================
  // RECOMMENDATION SCHEMAS
  // ==========================================
  RecommendationRequest: {
    type: 'object',
    required: ['terrain_id', 'implement_id'],
    properties: {
      terrain_id: {
        type: 'integer',
        example: 1,
        description: 'ID del terreno (debe pertenecer al usuario autenticado)',
      },
      implement_id: {
        type: 'integer',
        example: 1,
        description: 'ID del implemento agrícola',
      },
      working_depth_m: {
        type: 'number',
        format: 'float',
        example: 0.25,
        description: 'Profundidad de trabajo en metros (opcional)',
      },
      work_type: {
        type: 'string',
        enum: ['tillage', 'planting', 'harvesting', 'transport', 'general'],
        example: 'tillage',
        description: 'Tipo de trabajo agrícola',
      },
    },
  },

  RecommendationResponse: {
    type: 'object',
    properties: {
      success: { type: 'boolean', example: true },
      message: { type: 'string', example: 'Recomendaciones generadas exitosamente' },
      data: {
        type: 'object',
        properties: {
          queryId: { type: 'integer', example: 10 },
          implement: {
            type: 'object',
            properties: {
              id: { type: 'integer' },
              name: { type: 'string' },
              brand: { type: 'string' },
              type: { type: 'string' },
            },
          },
          terrain: {
            type: 'object',
            properties: {
              id: { type: 'integer' },
              name: { type: 'string' },
              soil_type: { type: 'string' },
              slope_percentage: { type: 'number', format: 'float' },
            },
          },
          powerRequirement: {
            type: 'object',
            properties: {
              minimum_power_hp: { type: 'number', format: 'float' },
              factors: { type: 'object' },
            },
          },
          terrainAnalysis: {
            type: 'object',
            description: 'Análisis detallado del terreno (clasificación de pendiente, tipo de suelo)',
          },
          recommendations: {
            type: 'array',
            items: {
              type: 'object',
              properties: {
                rank: { type: 'integer', example: 1 },
                tractor: {
                  type: 'object',
                  properties: {
                    id: { type: 'integer' },
                    name: { type: 'string', example: 'John Deere 6130M' },
                    brand: { type: 'string', example: 'John Deere' },
                    model: { type: 'string', example: '6130M' },
                    engine_power_hp: { type: 'number', format: 'float', example: 130.0 },
                    traction_type: { type: 'string', example: '4x4' },
                    weight_kg: { type: 'number', format: 'float', example: 5200.0 },
                  },
                },
                score: {
                  type: 'object',
                  properties: {
                    total: { type: 'number', format: 'float', example: 87.5 },
                    breakdown: { type: 'object' },
                  },
                },
                compatibility: { type: 'object' },
                classification: {
                  type: 'object',
                  properties: {
                    label: { type: 'string', enum: ['OPTIMAL', 'GOOD', 'ACCEPTABLE', 'OVERPOWERED'] },
                  },
                },
                explanation: {
                  type: 'string',
                  example: 'Alta eficiencia energética (85% utilización). Ajuste óptimo de potencia.',
                },
              },
            },
          },
          summary: { type: 'object', description: 'Resumen estadístico de las recomendaciones' },
        },
      },
    },
  },

  RecommendationHistory: {
    type: 'object',
    properties: {
      recommendation_id: { type: 'integer', example: 1 },
      user_id: { type: 'integer', example: 1 },
      terrain_id: { type: 'integer', example: 1 },
      tractor_id: { type: 'integer', example: 3, nullable: true },
      implement_id: { type: 'integer', example: 2, nullable: true },
      compatibility_score: { type: 'number', format: 'float', example: 87.5, nullable: true },
      observations: { type: 'string', nullable: true },
      work_type: { type: 'string', example: 'tillage', nullable: true },
      recommendation_date: { type: 'string', format: 'date-time' },
      terrain_name: { type: 'string', example: 'Parcela Norte' },
      soil_type: { type: 'string', example: 'clay' },
      tractor_name: { type: 'string', example: 'John Deere 6130M', nullable: true },
      tractor_brand: { type: 'string', example: 'John Deere', nullable: true },
      implement_name: { type: 'string', example: 'Arado de discos', nullable: true },
      implement_type: { type: 'string', example: 'plow', nullable: true },
    },
  },

  // ==========================================
  // ROLE SCHEMAS
  // ==========================================
  Role: {
    type: 'object',
    properties: {
      role_id: { type: 'integer', example: 1 },
      role_name: { type: 'string', example: 'admin' },
      description: { type: 'string', example: 'Administrador del sistema', nullable: true },
      status: { type: 'string', enum: ['active', 'inactive'], example: 'active' },
      created_at: { type: 'string', format: 'date-time' },
      updated_at: { type: 'string', format: 'date-time' },
    },
  },

  RoleCreate: {
    type: 'object',
    required: ['role_name'],
    properties: {
      role_name: {
        type: 'string',
        minLength: 2,
        example: 'moderator',
        description: 'Nombre del rol (mín. 2 caracteres)',
      },
      description: {
        type: 'string',
        example: 'Moderador del sistema',
        description: 'Descripción del rol (opcional)',
      },
    },
  },

  RoleUpdate: {
    type: 'object',
    properties: {
      role_name: {
        type: 'string',
        minLength: 2,
        example: 'moderator_updated',
      },
      description: {
        type: 'string',
        example: 'Descripción actualizada',
      },
      status: {
        type: 'string',
        enum: ['active', 'inactive'],
      },
    },
  },
};

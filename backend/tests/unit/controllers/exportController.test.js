import { beforeEach, describe, expect, jest, test } from '@jest/globals';

const mockPoolQuery = jest.fn();
const mockCsvParse = jest.fn();
const parserInstances = [];
const pdfInstances = [];

class FakeJson2CsvParser {
  constructor(options) {
    this.options = options;
    parserInstances.push(this);
  }

  parse(rows) {
    return mockCsvParse(rows, this.options);
  }
}

class FakePDFDocument {
  constructor() {
    this.page = { width: 595, height: 842 };
    this.y = 0;
    this.textCalls = [];
    this.pipedTo = null;
    this.ended = false;
    pdfInstances.push(this);
  }

  pipe(target) {
    this.pipedTo = target;
    return this;
  }

  rect() { return this; }
  roundedRect() { return this; }
  fill() { return this; }
  fillAndStroke() { return this; }
  circle() { return this; }
  save() { return this; }
  restore() { return this; }
  clip() { return this; }
  strokeColor() { return this; }
  lineWidth() { return this; }
  moveTo() { return this; }
  lineTo() { return this; }
  stroke() { return this; }
  bezierCurveTo() { return this; }
  closePath() { return this; }
  fontSize() { return this; }
  fillColor() { return this; }

  text(content, x, y) {
    this.textCalls.push(String(content));
    if (typeof y === 'number') {
      this.y = y + 14;
    } else if (typeof x === 'number') {
      this.y = x + 14;
    } else {
      this.y += 14;
    }
    return this;
  }

  addPage() {
    this.page = { width: 595, height: 842 };
    this.y = 0;
    return this;
  }

  heightOfString(value) {
    return Math.max(12, Math.ceil(String(value).length / 28) * 12);
  }

  end() {
    this.ended = true;
    return this;
  }
}

jest.unstable_mockModule('../../../src/config/db.js', () => ({
  __esModule: true,
  pool: {
    query: mockPoolQuery,
  },
}));

jest.unstable_mockModule('pdfkit', () => ({
  __esModule: true,
  default: FakePDFDocument,
}));

jest.unstable_mockModule('json2csv', () => ({
  __esModule: true,
  Parser: FakeJson2CsvParser,
}));

const controller = await import('../../../src/controllers/exportController.js');
const {
  exportTractorsCatalog,
  exportUserRecommendationsPdf,
} = controller;

const createMockRes = () => {
  const res = {};
  res.setHeader = jest.fn();
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  res.send = jest.fn().mockReturnValue(res);
  return res;
};

const callHandler = async (handler, req, res, next = jest.fn()) => {
  handler(req, res, next);
  await new Promise((resolve) => setImmediate(resolve));
  return next;
};

describe('exportController', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockPoolQuery.mockReset();
    mockCsvParse.mockReset();
    parserInstances.length = 0;
    pdfInstances.length = 0;
  });

  test('exportTractorsCatalog valida formato requerido csv', async () => {
    const req = { query: { format: 'pdf' } };
    const res = createMockRes();

    await callHandler(exportTractorsCatalog, req, res);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({
      success: false,
      message: 'Formato inválido. Use format=csv',
    });
    expect(mockPoolQuery).not.toHaveBeenCalled();
  });

  test('exportTractorsCatalog genera CSV y envía headers de descarga', async () => {
    const req = { query: { format: 'csv' } };
    const res = createMockRes();
    mockPoolQuery.mockResolvedValueOnce({
      rows: [
        { name: '5075E', brand: 'John Deere', power: 75, year: 2024, price: 120000 },
      ],
    });
    mockCsvParse.mockReturnValue('name,brand,power,year,price\n5075E,John Deere,75,2024,120000');

    await callHandler(exportTractorsCatalog, req, res);

    expect(parserInstances[0].options).toEqual({
      fields: ['name', 'brand', 'power', 'year', 'price'],
    });
    expect(mockCsvParse).toHaveBeenCalledWith([
      { name: '5075E', brand: 'John Deere', power: 75, year: 2024, price: 120000 },
    ], {
      fields: ['name', 'brand', 'power', 'year', 'price'],
    });
    expect(res.setHeader).toHaveBeenCalledWith('Content-Type', 'text/csv; charset=utf-8');
    expect(res.setHeader).toHaveBeenCalledWith(
      'Content-Disposition',
      expect.stringMatching(/^attachment; filename="tractors-catalog-\d{4}-\d{2}-\d{2}\.csv"$/),
    );
    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.send).toHaveBeenCalledWith('name,brand,power,year,price\n5075E,John Deere,75,2024,120000');
  });

  test('exportUserRecommendationsPdf valida formato requerido pdf', async () => {
    const req = { query: { format: 'csv' }, user: { user_id: 3 } };
    const res = createMockRes();

    await callHandler(exportUserRecommendationsPdf, req, res);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({
      success: false,
      message: 'Formato inválido. Use format=pdf',
    });
  });

  test('exportUserRecommendationsPdf exige usuario autenticado', async () => {
    const req = { query: { format: 'pdf' } };
    const res = createMockRes();

    await callHandler(exportUserRecommendationsPdf, req, res);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith({
      success: false,
      message: 'Usuario no autenticado',
    });
    expect(mockPoolQuery).not.toHaveBeenCalled();
  });

  test('exportUserRecommendationsPdf genera empty state cuando no hay recomendaciones', async () => {
    const req = {
      query: { format: 'pdf' },
      user: { user_id: 7 },
    };
    const res = createMockRes();
    mockPoolQuery
      .mockResolvedValueOnce({
        rows: [{ user_id: 7, name: 'Ana', email: 'ana@test.com' }],
      })
      .mockResolvedValueOnce({
        rows: [],
      });

    await callHandler(exportUserRecommendationsPdf, req, res);

    expect(res.setHeader).toHaveBeenCalledWith('Content-Type', 'application/pdf');
    expect(res.setHeader).toHaveBeenCalledWith(
      'Content-Disposition',
      expect.stringMatching(/^attachment; filename="recommendations-7-\d{4}-\d{2}-\d{2}\.pdf"$/),
    );
    expect(pdfInstances).toHaveLength(1);
    expect(pdfInstances[0].pipedTo).toBe(res);
    expect(pdfInstances[0].ended).toBe(true);
    expect(pdfInstances[0].textCalls).toEqual(
      expect.arrayContaining([
        'Reporte de Recomendaciones',
        'Sin recomendaciones registradas',
      ]),
    );
  });

  test('exportUserRecommendationsPdf recorre tarjetas, badges y observaciones en reporte poblado', async () => {
    const req = {
      query: { format: 'pdf' },
      user: { userId: 12 },
    };
    const res = createMockRes();
    mockPoolQuery
      .mockResolvedValueOnce({
        rows: [{ user_id: 12, name: 'Luis', email: 'luis@test.com' }],
      })
      .mockResolvedValueOnce({
        rows: [
          {
            recommendation_id: 1,
            recommendation_date: '2026-03-21T10:00:00.000Z',
            work_type: 'siembra',
            compatibility_score: 86,
            observations: JSON.stringify({
              explanation: 'Listo para trabajar',
              classification: { label: 'OPTIMAL', description: 'Ajuste ideal' },
            }),
            terrain_name: 'Lote A',
            soil_type: 'loam',
            tractor_name: '6130M',
            tractor_brand: 'John Deere',
            tractor_model: '6130M',
            engine_power_hp: 130,
            implement_name: 'Sembradora',
            implement_brand: 'Agro',
          },
          {
            recommendation_id: 2,
            recommendation_date: '2026-03-20T10:00:00.000Z',
            work_type: 'labranza',
            compatibility_score: 65,
            observations: 'Observación libre',
            terrain_name: 'Lote B',
            soil_type: 'clay',
            tractor_name: 'MX120',
            tractor_brand: 'Case',
            tractor_model: 'MX120',
            engine_power_hp: 120,
            implement_name: 'Arado',
            implement_brand: 'Campo',
          },
          {
            recommendation_id: 3,
            recommendation_date: '2026-03-19T10:00:00.000Z',
            work_type: 'transporte',
            compatibility_score: 40,
            observations: null,
            terrain_name: 'Lote C',
            soil_type: 'sandy',
            tractor_name: 'NH90',
            tractor_brand: 'New Holland',
            tractor_model: 'NH90',
            engine_power_hp: 90,
            implement_name: 'Remolque',
            implement_brand: 'Cargo',
          },
          {
            recommendation_id: 4,
            recommendation_date: '2026-03-18T10:00:00.000Z',
            work_type: 'general',
            compatibility_score: null,
            observations: JSON.stringify({}),
            terrain_name: 'Lote D',
            soil_type: 'rocky',
            tractor_name: null,
            tractor_brand: null,
            tractor_model: null,
            engine_power_hp: null,
            implement_name: null,
            implement_brand: null,
          },
        ],
      });

    await callHandler(exportUserRecommendationsPdf, req, res);

    expect(pdfInstances).toHaveLength(1);
    expect(pdfInstances[0].ended).toBe(true);
    expect(pdfInstances[0].textCalls).toEqual(
      expect.arrayContaining([
        'Reporte de Recomendaciones',
        'Recomendaciones registradas',
        'Recomendacion 1',
        'Alta compatibilidad',
        'Compatibilidad media',
        'Revisar ajuste',
        'Sin score',
        'Listo para trabajar',
        'Observación libre',
        'Sin observaciones adicionales registradas.',
      ]),
    );
  });
});

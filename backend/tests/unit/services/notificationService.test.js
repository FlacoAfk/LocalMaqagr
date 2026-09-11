import { beforeEach, describe, expect, jest, test } from '@jest/globals';

const mockCreate = jest.fn();
const mockPoolQuery = jest.fn();
const mockLoggerInfo = jest.fn();
const mockLoggerError = jest.fn();

jest.unstable_mockModule('../../../src/models/Notification.js', () => ({
  __esModule: true,
  default: {
    create: mockCreate,
  },
}));

jest.unstable_mockModule('../../../src/config/db.js', () => ({
  __esModule: true,
  pool: {
    query: mockPoolQuery,
  },
}));

jest.unstable_mockModule('../../../src/utils/logger.js', () => ({
  __esModule: true,
  default: {
    info: mockLoggerInfo,
    error: mockLoggerError,
  },
}));

const service = await import('../../../src/services/notificationService.js');
const {
  NOTIFICATION_TYPES,
  createNotification,
  notifyRecommendationCreated,
  notifySystemMaintenance,
  notifyTractorAvailable,
  notifyUsersAboutNewTractor,
} = service;

describe('notificationService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('createNotification retorna notificación creada y registra log informativo', async () => {
    const notification = { notification_id: 20 };
    mockCreate.mockResolvedValue(notification);

    const result = await createNotification(
      7,
      NOTIFICATION_TYPES.RECOMMENDATION,
      'Nueva recomendación disponible',
      'Contenido',
      { recommendationId: 20 },
    );

    expect(mockCreate).toHaveBeenCalledWith({
      userId: 7,
      type: NOTIFICATION_TYPES.RECOMMENDATION,
      title: 'Nueva recomendación disponible',
      message: 'Contenido',
      data: { recommendationId: 20 },
    });
    expect(result).toBe(notification);
    expect(mockLoggerInfo).toHaveBeenCalledWith('Notificación creada', {
      userId: 7,
      type: NOTIFICATION_TYPES.RECOMMENDATION,
      notificationId: 20,
    });
  });

  test('createNotification captura errores silenciosamente', async () => {
    mockCreate.mockRejectedValue(new Error('insert failed'));

    const result = await createNotification(5, 'system', 'Titulo', 'Mensaje');

    expect(result).toBeNull();
    expect(mockLoggerError).toHaveBeenCalledWith('Error creando notificación', {
      userId: 5,
      type: 'system',
      error: 'insert failed',
    });
  });

  test('notifyRecommendationCreated y notifyTractorAvailable delegan con payload correcto', async () => {
    mockCreate.mockResolvedValue({ notification_id: 1 });

    await notifyRecommendationCreated(9, 123);
    await notifyTractorAvailable(8, 45, 'MX-120');

    expect(mockCreate).toHaveBeenNthCalledWith(1, {
      userId: 9,
      type: NOTIFICATION_TYPES.RECOMMENDATION,
      title: 'Nueva recomendación disponible',
      message: 'Se generó una nueva recomendación de tractor y/o implemento (Query ID: 123)',
      data: { recommendationId: 123 },
    });
    expect(mockCreate).toHaveBeenNthCalledWith(2, {
      userId: 8,
      type: NOTIFICATION_TYPES.TRACTOR_AVAILABLE,
      title: 'Tractor disponible',
      message: 'El tractor MX-120 ahora se encuentra disponible.',
      data: { tractorId: 45 },
    });
  });

  test('notifySystemMaintenance retorna 0 cuando no hay usuarios y ejecuta batch insert cuando sí los hay', async () => {
    const emptyResult = await notifySystemMaintenance([], 'Mantenimiento', 'Se realizará mantenimiento');
    expect(emptyResult).toBe(0);
    expect(mockPoolQuery).not.toHaveBeenCalled();

    mockPoolQuery.mockResolvedValueOnce({ rowCount: 2 });

    const result = await notifySystemMaintenance(
      [11, 12],
      'Mantenimiento',
      'Se realizará mantenimiento',
    );

    expect(result).toBe(2);
    expect(mockPoolQuery).toHaveBeenCalledWith(
      expect.stringContaining('INSERT INTO notification'),
      [
        11,
        NOTIFICATION_TYPES.SYSTEM,
        'Mantenimiento',
        'Se realizará mantenimiento',
        12,
        NOTIFICATION_TYPES.SYSTEM,
        'Mantenimiento',
        'Se realizará mantenimiento',
      ],
    );
    expect(mockLoggerInfo).toHaveBeenCalledWith(
      'Notificación de sistema enviada masivamente a 2 usuarios',
    );
  });

  test('notifySystemMaintenance captura errores y retorna 0', async () => {
    mockPoolQuery.mockRejectedValueOnce(new Error('bulk failed'));

    const result = await notifySystemMaintenance([1, 2, 3], 'Aviso', 'Mensaje');

    expect(result).toBe(0);
    expect(mockLoggerError).toHaveBeenCalledWith('Error en envío masivo de notificaciones', {
      userCount: 3,
      error: 'bulk failed',
    });
  });

  test('notifyUsersAboutNewTractor no hace nada con tractores menores a 90 HP', async () => {
    await notifyUsersAboutNewTractor({
      tractor_id: 1,
      name: 'Ligero',
      engine_power_hp: 89,
    });

    expect(mockPoolQuery).not.toHaveBeenCalled();
    expect(mockCreate).not.toHaveBeenCalled();
  });

  test('notifyUsersAboutNewTractor consulta usuarios activos y crea notificaciones individuales', async () => {
    mockPoolQuery.mockResolvedValueOnce({
      rows: [{ user_id: 101 }, { user_id: 202 }],
    });
    mockCreate.mockResolvedValue({ notification_id: 1 });

    await notifyUsersAboutNewTractor({
      id: 77,
      name: 'Potente 120',
      engine_power_hp: 120,
    });

    expect(mockPoolQuery).toHaveBeenCalledWith(expect.stringContaining('SELECT DISTINCT u.user_id'));
    expect(mockCreate).toHaveBeenCalledTimes(2);
    expect(mockCreate).toHaveBeenNthCalledWith(1, {
      userId: 101,
      type: NOTIFICATION_TYPES.TRACTOR_AVAILABLE,
      title: 'Tractor disponible',
      message: 'El tractor Potente 120 ahora se encuentra disponible.',
      data: { tractorId: 77 },
    });
    expect(mockCreate).toHaveBeenNthCalledWith(2, {
      userId: 202,
      type: NOTIFICATION_TYPES.TRACTOR_AVAILABLE,
      title: 'Tractor disponible',
      message: 'El tractor Potente 120 ahora se encuentra disponible.',
      data: { tractorId: 77 },
    });
    expect(mockLoggerInfo).toHaveBeenCalledWith(
      'Notificaciones por nuevo tractor enviadas a 2 usuarios.',
    );
  });

  test('notifyUsersAboutNewTractor captura errores de consulta', async () => {
    mockPoolQuery.mockRejectedValueOnce(new Error('select failed'));

    await notifyUsersAboutNewTractor({
      tractor_id: 88,
      name: 'Fuerte',
      engine_power_hp: 150,
    });

    expect(mockLoggerError).toHaveBeenCalledWith(
      'Error evaluando usuarios para notificar sobre tractor',
      { error: 'select failed' },
    );
  });
});

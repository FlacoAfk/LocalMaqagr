/**
 * FIX-004: Coverage para adminUserController.js (getAllUsers / getUserById / updateUser)
 *
 * Aditivo: archivo nuevo; mockea pool (config/db.js) y logger.
 * response.util se usa REAL (sin efectos secundarios).
 */
import { describe, test, expect, jest, beforeEach } from '@jest/globals';

const mockPoolQuery = jest.fn();

jest.unstable_mockModule('../../../src/config/db.js', () => ({
  pool: { query: mockPoolQuery },
  __esModule: true,
}));

jest.unstable_mockModule('../../../src/utils/logger.js', () => ({
  default: {
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn(),
  },
  __esModule: true,
}));

const { getAllUsers, getUserById, updateUser } = await import('../../../src/controllers/adminUserController.js');

const createMockRes = () => {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
};

const callHandler = async (handler, req, res) => {
  handler(req, res, jest.fn());
  await new Promise((resolve) => setImmediate(resolve));
};

describe('adminUserController (FIX-004)', () => {
  beforeEach(() => {
    mockPoolQuery.mockReset();
  });

  describe('getAllUsers', () => {
    test('devuelve todos los usuarios', async () => {
      mockPoolQuery.mockResolvedValue({ rows: [{ user_id: 1, name: 'Ana' }] });
      const res = createMockRes();

      await callHandler(getAllUsers, {}, res);

      expect(mockPoolQuery).toHaveBeenCalledTimes(1);
      expect(res.status).toHaveBeenCalledWith(200);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ success: true, data: [{ user_id: 1, name: 'Ana' }] })
      );
    });

    test('devuelve lista vacía cuando no hay usuarios', async () => {
      mockPoolQuery.mockResolvedValue({ rows: [] });
      const res = createMockRes();

      await callHandler(getAllUsers, {}, res);

      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ success: true, data: [] })
      );
    });
  });

  describe('getUserById', () => {
    test('rechaza id no numérico', async () => {
      const res = createMockRes();

      await callHandler(getUserById, { params: { id: 'abc' } }, res);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ message: 'ID de usuario inválido' })
      );
      expect(mockPoolQuery).not.toHaveBeenCalled();
    });

    test('rechaza id <= 0', async () => {
      const res = createMockRes();

      await callHandler(getUserById, { params: { id: '0' } }, res);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(mockPoolQuery).not.toHaveBeenCalled();
    });

    test('404 si el usuario no existe', async () => {
      mockPoolQuery.mockResolvedValue({ rows: [] });
      const res = createMockRes();

      await callHandler(getUserById, { params: { id: '5' } }, res);

      expect(res.status).toHaveBeenCalledWith(404);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ message: 'Usuario no encontrado' })
      );
    });

    test('devuelve el usuario encontrado', async () => {
      mockPoolQuery.mockResolvedValue({ rows: [{ user_id: 5, name: 'Luis' }] });
      const res = createMockRes();

      await callHandler(getUserById, { params: { id: '5' } }, res);

      expect(mockPoolQuery).toHaveBeenCalledWith(expect.stringContaining('WHERE u.user_id = $1'), [5]);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ success: true, data: { user_id: 5, name: 'Luis' } })
      );
    });
  });

  describe('updateUser', () => {
    test('rechaza id inválido', async () => {
      const res = createMockRes();

      await callHandler(updateUser, { params: { id: 'x' }, body: {} }, res);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(mockPoolQuery).not.toHaveBeenCalled();
    });

    test('rechaza role_id inválido', async () => {
      const res = createMockRes();

      await callHandler(updateUser, { params: { id: '3' }, body: { role_id: 9 } }, res);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ message: 'Rol inválido' })
      );
    });

    test('rechaza status inválido', async () => {
      const res = createMockRes();

      await callHandler(updateUser, { params: { id: '3' }, body: { status: 'banned' } }, res);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ message: 'Estado inválido' })
      );
    });

    test('404 si el usuario a actualizar no existe', async () => {
      mockPoolQuery.mockResolvedValueOnce({ rows: [] });
      const res = createMockRes();

      await callHandler(updateUser, { params: { id: '3' }, body: { name: 'X' } }, res);

      expect(res.status).toHaveBeenCalledWith(404);
    });

    test('impide que un admin se degrade a sí mismo', async () => {
      mockPoolQuery.mockResolvedValueOnce({ rows: [{ user_id: 3 }] });
      const res = createMockRes();
      const req = { params: { id: '3' }, body: { role_id: 2 }, user: { user_id: 3 } };

      await callHandler(updateUser, req, res);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          message: 'Acción no permitida',
          errors: ['No puedes cambiar tu propio rol de administrador'],
        })
      );
    });

    test('400 si no hay campos para actualizar', async () => {
      mockPoolQuery.mockResolvedValueOnce({ rows: [{ user_id: 3 }] });
      const res = createMockRes();
      const req = { params: { id: '3' }, body: {}, user: { user_id: 9 } };

      await callHandler(updateUser, req, res);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ message: 'No hay datos para actualizar' })
      );
    });

    test('actualiza usuario y enriquece con role_name', async () => {
      mockPoolQuery
        .mockResolvedValueOnce({ rows: [{ user_id: 3 }] }) // exists
        .mockResolvedValueOnce({
          rows: [{ user_id: 3, name: 'Luis', email: 'l@x.com', role_id: 1, status: 'active' }],
        }) // UPDATE RETURNING
        .mockResolvedValueOnce({ rows: [{ role_name: 'admin' }] }); // role lookup
      const res = createMockRes();
      const req = { params: { id: '3' }, body: { name: 'Luis', email: 'LUIS@X.COM', role_id: 1, status: 'active' }, user: { user_id: 9 } };

      await callHandler(updateUser, req, res);

      expect(mockPoolQuery).toHaveBeenCalledTimes(3);
      // email se normaliza a minúsculas en el UPDATE
      expect(mockPoolQuery.mock.calls[1][1]).toContain('luis@x.com');
      expect(res.status).toHaveBeenCalledWith(200);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: true,
          data: expect.objectContaining({
            user_id: 3,
            role_name: 'admin',
          }),
        })
      );
    });

    test('usa fallback "unknown" si el role no tiene role_name', async () => {
      mockPoolQuery
        .mockResolvedValueOnce({ rows: [{ user_id: 3 }] })
        .mockResolvedValueOnce({ rows: [{ user_id: 3, role_id: 2 }] })
        .mockResolvedValueOnce({ rows: [] });
      const res = createMockRes();
      const req = { params: { id: '3' }, body: { status: 'inactive' }, user: { user_id: 9 } };

      await callHandler(updateUser, req, res);

      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ role_name: 'unknown' }),
        })
      );
    });

    test('actualiza solo un subconjunto de campos (role_id)', async () => {
      mockPoolQuery
        .mockResolvedValueOnce({ rows: [{ user_id: 3 }] })
        .mockResolvedValueOnce({ rows: [{ user_id: 3, role_id: 2 }] })
        .mockResolvedValueOnce({ rows: [{ role_name: 'user' }] });
      const res = createMockRes();
      const req = { params: { id: '3' }, body: { role_id: 2 }, user: { user_id: 9 } };

      await callHandler(updateUser, req, res);

      const updateSql = mockPoolQuery.mock.calls[1][0];
      expect(updateSql).toContain('role_id = $1');
      expect(updateSql).not.toContain('name =');
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ data: expect.objectContaining({ role_name: 'user' }) })
      );
    });
  });
});

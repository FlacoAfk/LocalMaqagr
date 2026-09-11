import { beforeEach, describe, expect, jest, test } from '@jest/globals';

const mockFindByName = jest.fn();
const mockFindById = jest.fn();
const mockCreate = jest.fn();
const mockUpdate = jest.fn();
const mockPoolQuery = jest.fn();

jest.unstable_mockModule('../../../src/models/Role.js', () => ({
  __esModule: true,
  default: {
    findByName: mockFindByName,
    findById: mockFindById,
    create: mockCreate,
    update: mockUpdate,
  },
}));

jest.unstable_mockModule('../../../src/config/db.js', () => ({
  __esModule: true,
  pool: {
    query: mockPoolQuery,
  },
}));

const controller = await import('../../../src/controllers/roleController.js');
const {
  getAllRoles,
  createRole,
  updateRole,
  deleteRole,
} = controller;

const createMockReq = ({ query, body, params } = {}) => ({
  query: query || {},
  body: body || {},
  params: params || {},
});

const createMockRes = () => {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
};

const callHandler = async (handler, req, res, next = jest.fn()) => {
  handler(req, res, next);
  await new Promise((resolve) => setImmediate(resolve));
  return next;
};

describe('roleController', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('getAllRoles devuelve roles activos con paginación', async () => {
    const req = createMockReq({
      query: { page: '2', limit: '3' },
    });
    const res = createMockRes();

    mockPoolQuery
      .mockResolvedValueOnce({ rows: [{ count: '7' }] })
      .mockResolvedValueOnce({
        rows: [{ role_id: 2, role_name: 'user', status: 'active' }],
      });

    await callHandler(getAllRoles, req, res);

    expect(mockPoolQuery).toHaveBeenNthCalledWith(
      1,
      'SELECT COUNT(*) FROM role WHERE status = $1',
      ['active'],
    );
    expect(mockPoolQuery).toHaveBeenNthCalledWith(
      2,
      expect.stringContaining('FROM role'),
      [3, 3],
    );
    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({
      success: true,
      message: 'Roles obtenidos exitosamente',
      data: {
        roles: [{ role_id: 2, role_name: 'user', status: 'active' }],
        pagination: {
          currentPage: 2,
          totalPages: 3,
          totalItems: 7,
          itemsPerPage: 3,
        },
      },
    });
  });

  test('createRole valida nombre requerido y longitud mínima', async () => {
    let req = createMockReq({ body: {} });
    let res = createMockRes();
    await callHandler(createRole, req, res);
    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({
      success: false,
      message: 'El nombre del rol es requerido',
    });

    req = createMockReq({ body: { role_name: 'a' } });
    res = createMockRes();
    await callHandler(createRole, req, res);
    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({
      success: false,
      message: 'El nombre del rol debe tener al menos 2 caracteres',
    });
  });

  test('createRole responde conflicto si ya existe el rol', async () => {
    const req = createMockReq({
      body: { role_name: 'admin' },
    });
    const res = createMockRes();
    mockFindByName.mockResolvedValue({ role_id: 1, role_name: 'admin' });

    await callHandler(createRole, req, res);

    expect(mockFindByName).toHaveBeenCalledWith('admin');
    expect(res.status).toHaveBeenCalledWith(409);
    expect(res.json).toHaveBeenCalledWith({
      success: false,
      message: 'Ya existe un rol con ese nombre',
    });
  });

  test('createRole crea el rol con status active y description null por defecto', async () => {
    const req = createMockReq({
      body: { role_name: 'auditor' },
    });
    const res = createMockRes();
    const role = { role_id: 4, role_name: 'auditor', description: null };

    mockFindByName.mockResolvedValue(null);
    mockCreate.mockResolvedValue(role);

    await callHandler(createRole, req, res);

    expect(mockCreate).toHaveBeenCalledWith({
      role_name: 'auditor',
      description: null,
      status: 'active',
    });
    expect(res.status).toHaveBeenCalledWith(201);
    expect(res.json).toHaveBeenCalledWith({
      success: true,
      message: 'Rol creado exitosamente',
      data: {
        role,
      },
    });
  });

  test('updateRole valida id, existencia y payload mínimo', async () => {
    let req = createMockReq({ params: { id: 'abc' } });
    let res = createMockRes();
    await callHandler(updateRole, req, res);
    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({
      success: false,
      message: 'ID de rol inválido',
    });

    req = createMockReq({ params: { id: '5' }, body: { role_name: 'qa' } });
    res = createMockRes();
    mockFindById.mockResolvedValueOnce(null);
    await callHandler(updateRole, req, res);
    expect(res.status).toHaveBeenCalledWith(404);
    expect(res.json).toHaveBeenCalledWith({
      success: false,
      message: 'Rol no encontrado',
    });

    req = createMockReq({ params: { id: '5' }, body: {} });
    res = createMockRes();
    mockFindById.mockResolvedValueOnce({ role_id: 5, role_name: 'qa' });
    await callHandler(updateRole, req, res);
    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({
      success: false,
      message: 'Debe proporcionar al menos un campo para actualizar',
    });
  });

  test('updateRole valida nombre duplicado y status inválido', async () => {
    let req = createMockReq({
      params: { id: '7' },
      body: { role_name: 'a' },
    });
    let res = createMockRes();
    mockFindById.mockResolvedValueOnce({ role_id: 7, role_name: 'ops' });
    await callHandler(updateRole, req, res);
    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({
      success: false,
      message: 'El nombre del rol debe tener al menos 2 caracteres',
    });

    req = createMockReq({
      params: { id: '7' },
      body: { role_name: 'admin' },
    });
    res = createMockRes();
    mockFindById.mockResolvedValueOnce({ role_id: 7, role_name: 'ops' });
    mockFindByName.mockResolvedValueOnce({ role_id: 1, role_name: 'admin' });
    await callHandler(updateRole, req, res);
    expect(res.status).toHaveBeenCalledWith(409);
    expect(res.json).toHaveBeenCalledWith({
      success: false,
      message: 'Ya existe otro rol con ese nombre',
    });

    req = createMockReq({
      params: { id: '7' },
      body: { status: 'archived' },
    });
    res = createMockRes();
    mockFindById.mockResolvedValueOnce({ role_id: 7, role_name: 'ops' });
    await callHandler(updateRole, req, res);
    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({
      success: false,
      message: 'Estado inválido. Debe ser "active" o "inactive"',
    });
  });

  test('updateRole actualiza el rol cuando el nombre pertenece al mismo rol', async () => {
    const req = createMockReq({
      params: { id: '9' },
      body: { role_name: 'analyst', description: 'Lectura', status: 'inactive' },
    });
    const res = createMockRes();
    const updatedRole = { role_id: 9, role_name: 'analyst', status: 'inactive' };

    mockFindById.mockResolvedValueOnce({ role_id: 9, role_name: 'analyst' });
    mockFindByName.mockResolvedValueOnce({ role_id: 9, role_name: 'analyst' });
    mockUpdate.mockResolvedValueOnce(updatedRole);

    await callHandler(updateRole, req, res);

    expect(mockUpdate).toHaveBeenCalledWith(9, {
      role_name: 'analyst',
      description: 'Lectura',
      status: 'inactive',
    });
    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({
      success: true,
      message: 'Rol actualizado exitosamente',
      data: {
        role: updatedRole,
      },
    });
  });

  test('deleteRole valida id, existencia, protección del admin y usuarios asignados', async () => {
    let req = createMockReq({ params: { id: 'xyz' } });
    let res = createMockRes();
    await callHandler(deleteRole, req, res);
    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({
      success: false,
      message: 'ID de rol inválido',
    });

    req = createMockReq({ params: { id: '8' } });
    res = createMockRes();
    mockFindById.mockResolvedValueOnce(null);
    await callHandler(deleteRole, req, res);
    expect(res.status).toHaveBeenCalledWith(404);
    expect(res.json).toHaveBeenCalledWith({
      success: false,
      message: 'Rol no encontrado',
    });

    req = createMockReq({ params: { id: '1' } });
    res = createMockRes();
    mockFindById.mockResolvedValueOnce({ role_id: 1, role_name: 'admin' });
    await callHandler(deleteRole, req, res);
    expect(res.status).toHaveBeenCalledWith(403);
    expect(res.json).toHaveBeenCalledWith({
      success: false,
      message: 'No se puede eliminar el rol de administrador',
    });

    req = createMockReq({ params: { id: '3' } });
    res = createMockRes();
    mockFindById.mockResolvedValueOnce({ role_id: 3, role_name: 'operator' });
    mockPoolQuery.mockResolvedValueOnce({ rows: [{ count: '2' }] });
    await callHandler(deleteRole, req, res);
    expect(mockPoolQuery).toHaveBeenCalledWith(
      'SELECT COUNT(*) FROM users WHERE role_id = $1 AND status = $2',
      [3, 'active'],
    );
    expect(res.status).toHaveBeenCalledWith(409);
    expect(res.json).toHaveBeenCalledWith({
      success: false,
      message: 'No se puede eliminar el rol porque tiene usuarios asignados',
    });
  });

  test('deleteRole inactiva el rol cuando no tiene usuarios activos', async () => {
    const req = createMockReq({ params: { id: '4' } });
    const res = createMockRes();
    const deletedRole = { role_id: 4, status: 'inactive' };

    mockFindById.mockResolvedValueOnce({ role_id: 4, role_name: 'auditor' });
    mockPoolQuery.mockResolvedValueOnce({ rows: [{ count: '0' }] });
    mockUpdate.mockResolvedValueOnce(deletedRole);

    await callHandler(deleteRole, req, res);

    expect(mockUpdate).toHaveBeenCalledWith(4, {
      status: 'inactive',
    });
    expect(res.json).toHaveBeenCalledWith({
      success: true,
      message: 'Rol eliminado exitosamente',
      data: {
        role: deletedRole,
      },
    });
  });
});

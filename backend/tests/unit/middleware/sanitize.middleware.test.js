import { describe, expect, jest, test } from '@jest/globals';
import { sanitizeInputs } from '../../../src/middleware/sanitize.middleware.js';

describe('sanitize.middleware', () => {
  test('sanitiza body, arrays y objetos anidados', () => {
    const req = {
      body: {
        name: "<script>alert('x')</script>",
        nested: {
          note: "O'Hara; --",
        },
        tags: ["<img src=x onerror=alert(1)>", 7, true],
      },
      query: {
        search: '<b>tractor</b>',
      },
      params: {
        id: "1'; DROP TABLE users; --",
      },
    };
    const next = jest.fn();

    sanitizeInputs(req, {}, next);

    expect(req.body).toEqual({
      name: "&lt;script&gt;alert(''x'')&lt;/script&gt;",
      nested: {
        note: "O''Hara",
      },
      tags: ['<img src>', 7, true],
    });
    expect(req.query.search).toBe('<b>tractor</b>');
    expect(req.params.id).toBe("1'' DROP TABLE users");
    expect(next).toHaveBeenCalled();
  });

  test('tolera query y params readonly sin lanzar error', () => {
    const query = {};
    Object.defineProperty(query, 'term', {
      value: "<script>alert('x')</script>",
      enumerable: true,
      writable: false,
      configurable: true,
    });

    const params = {};
    Object.defineProperty(params, 'id', {
      value: "1'; DROP TABLE users; --",
      enumerable: true,
      writable: false,
      configurable: true,
    });

    const req = {
      body: null,
      query,
      params,
    };
    const next = jest.fn();

    expect(() => sanitizeInputs(req, {}, next)).not.toThrow();
    expect(req.query.term).toBe("<script>alert('x')</script>");
    expect(req.params.id).toBe("1'; DROP TABLE users; --");
    expect(next).toHaveBeenCalled();
  });

  test('deja intactos valores no string y soporta request vacía', () => {
    const req = {
      body: {
        quantity: 5,
        active: false,
        empty: null,
      },
    };
    const next = jest.fn();

    sanitizeInputs(req, {}, next);

    expect(req.body).toEqual({
      quantity: 5,
      active: false,
      empty: null,
    });
    expect(next).toHaveBeenCalled();
  });
});

/**
 * Middleware de Autenticación
 * Verifica JWT y permisos de usuario
 */

import { verifyToken } from '../utils/jwt.util.js';
import { ROLE_NAME_TO_ID } from '../utils/role.util.js';
import { pool } from '../config/db.js';

const normalizeRoleToId = (role) => {
    if (typeof role === 'number') return role;
    if (typeof role === 'string') {
        return ROLE_NAME_TO_ID[role.toLowerCase()];
    }
    return undefined;
};

const normalizeRoleLabel = (role) => {
    if (typeof role === 'string') {
        const normalized = role.toLowerCase();
        if (normalized === 'admin') return 'administrador';
        return normalized;
    }
    if (typeof role === 'number') return `role_id ${role}`;
    return 'desconocido';
};

/**
 * Verifica que el token JWT sea válido
 * Extrae token del header: Authorization: Bearer <token>
 * Agrega datos del usuario a req.user
 */
export const verifyTokenMiddleware = async (req, res, next) => {
    const unauthorized = () => res.status(401).json({
        success: false,
        code: 'UNAUTHORIZED',
        message: 'Token inválido o expirado'
    });

    const authHeader = req.headers['authorization'];

    if (!authHeader) {
        return res.status(401).json({
            success: false,
            code: 'UNAUTHORIZED',
            message: 'Token no proporcionado'
        });
    }

    const token = typeof authHeader === 'string'
        ? /^Bearer ([^\s]+)$/i.exec(authHeader)?.[1]
        : undefined;

    if (!token) {
        return res.status(401).json({
            success: false,
            code: 'UNAUTHORIZED',
            message: 'Formato de token inválido'
        });
    }

    let decoded;
    try {
        decoded = verifyToken(token);
    } catch (error) {
        return unauthorized();
    }

    try {
        const result = await pool.query(
            'SELECT role_id, status FROM users WHERE user_id = $1',
            [decoded.user_id],
        );
        const currentUser = result.rows[0];

        if (
            !currentUser ||
            currentUser.status !== 'active' ||
            Number(currentUser.role_id) !== Number(decoded.role_id)
        ) {
            return unauthorized();
        }

        req.user = decoded;
        return next();
    } catch (error) {
        return next(error);
    }
};

/**
 * Valida que el usuario autenticado tenga alguno de los roles requeridos
 * Debe usarse después de verifyTokenMiddleware
 */
export const requireRole = (requiredRoles) => {
    const requiredList = Array.isArray(requiredRoles) ? requiredRoles : [requiredRoles];
    const requiredRoleIds = requiredList.map(normalizeRoleToId).filter((roleId) => roleId !== undefined);

    return (req, res, next) => {
        if (!req.user) {
            return res.status(401).json({
                success: false,
                code: 'UNAUTHORIZED',
                message: 'No autenticado'
            });
        }

        // Fallback defensivo: en caso de configuración inválida del middleware
        if (requiredRoleIds.length === 0) {
            return res.status(500).json({
                success: false,
                code: 'INTERNAL_ERROR',
                message: 'Configuración de roles inválida'
            });
        }

        if (!requiredRoleIds.includes(req.user.role_id)) {
            const rolesLabel = requiredList.map(normalizeRoleLabel).join(' o ');
            return res.status(403).json({
                success: false,
                code: 'FORBIDDEN',
                message: `Acceso denegado: se requiere rol de ${rolesLabel}`
            });
        }

        next();
    };
};

/**
 * Verifica si el usuario tiene rol de administrador (role_id = 1)
 * Debe usarse después de verifyTokenMiddleware
 */
export const isAdmin = requireRole('admin');

/**
 * Verifica si existe una sesión activa (usuario autenticado)
 * Alias de verifyTokenMiddleware para mayor claridad semántica
 */
export const isAuthenticated = (req, res, next) => {
    return verifyTokenMiddleware(req, res, next);
};

export default { verifyTokenMiddleware, requireRole, isAdmin, isAuthenticated };

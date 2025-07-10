import { Router } from 'express';
import {
  getCompanyConfig,
  getCompanyInfo,
  updateCompanyConfig,
  getConfigHealth
} from '../controllers/company.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

/**
 * @route GET /api/company/info
 * @desc Obtener información pública de la empresa
 * @access Public
 */
router.get('/info', getCompanyInfo);

/**
 * @route GET /api/company/config
 * @desc Obtener configuración completa de la empresa
 * @access Private (requiere autenticación)
 */
router.get('/config', authenticate, getCompanyConfig);

/**
 * @route PUT /api/company/config
 * @desc Actualizar configuración de la empresa
 * @access Private (requiere autenticación y permisos de admin)
 */
router.put('/config', authenticate, updateCompanyConfig);

/**
 * @route GET /api/company/health
 * @desc Verificar estado de salud de la configuración
 * @access Private (requiere autenticación)
 */
router.get('/health', authenticate, getConfigHealth);

export default router;

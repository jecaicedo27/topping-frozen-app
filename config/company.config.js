/**
 * Configuración de la empresa
 * Este archivo se genera automáticamente durante la instalación
 */

module.exports = {
  // Información básica de la empresa
  company: {
    name: process.env.COMPANY_NAME || 'TOPPING FROZEN',
    domain: process.env.COMPANY_DOMAIN || 'localhost',
    logo: process.env.COMPANY_LOGO || '/assets/logo.png',
    primaryColor: process.env.COMPANY_PRIMARY_COLOR || '#007bff',
    secondaryColor: process.env.COMPANY_SECONDARY_COLOR || '#6c757d'
  },

  // Configuración de la aplicación
  app: {
    title: process.env.APP_TITLE || 'Sistema de Pedidos',
    description: process.env.APP_DESCRIPTION || 'Sistema de gestión de pedidos y logística',
    version: process.env.APP_VERSION || '1.0.0'
  },

  // Configuración de base de datos específica de la empresa
  database: {
    prefix: process.env.DB_PREFIX || 'company_',
    name: process.env.DB_NAME || 'topping_frozen_db'
  },

  // Configuración de características habilitadas
  features: {
    multiTenant: process.env.MULTI_TENANT === 'true',
    customBranding: process.env.CUSTOM_BRANDING === 'true',
    advancedReporting: process.env.ADVANCED_REPORTING === 'true'
  },

  // Configuración de contacto
  contact: {
    email: process.env.COMPANY_EMAIL || 'admin@company.com',
    phone: process.env.COMPANY_PHONE || '+57 300 000 0000',
    address: process.env.COMPANY_ADDRESS || 'Dirección de la empresa'
  }
};

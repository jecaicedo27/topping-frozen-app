import { Request, Response } from 'express';
import dotenv from 'dotenv';

// Cargar variables de entorno
dotenv.config();

// Interfaz para la configuración de la empresa
interface CompanyConfig {
  company: {
    name: string;
    domain: string;
    logo: string;
    primaryColor: string;
    secondaryColor: string;
  };
  app: {
    title: string;
    description: string;
    version: string;
  };
  database: {
    prefix: string;
    name: string;
  };
  features: {
    multiTenant: boolean;
    customBranding: boolean;
    advancedReporting: boolean;
  };
  contact: {
    email: string;
    phone: string;
    address: string;
  };
}

// Configuración por defecto
const defaultConfig: CompanyConfig = {
  company: {
    name: 'TOPPING FROZEN',
    domain: 'localhost',
    logo: '/assets/logo.png',
    primaryColor: '#007bff',
    secondaryColor: '#6c757d'
  },
  app: {
    title: 'Sistema de Pedidos',
    description: 'Sistema de gestión de pedidos y logística',
    version: '1.0.0'
  },
  database: {
    prefix: 'company_',
    name: 'topping_frozen_db'
  },
  features: {
    multiTenant: false,
    customBranding: true,
    advancedReporting: true
  },
  contact: {
    email: 'admin@company.com',
    phone: '+57 300 000 0000',
    address: 'Dirección de la empresa'
  }
};

// Función para obtener la configuración desde variables de entorno
const getConfigFromEnv = (): CompanyConfig => {
  return {
    company: {
      name: process.env.COMPANY_NAME || defaultConfig.company.name,
      domain: process.env.COMPANY_DOMAIN || defaultConfig.company.domain,
      logo: process.env.COMPANY_LOGO || defaultConfig.company.logo,
      primaryColor: process.env.COMPANY_PRIMARY_COLOR || defaultConfig.company.primaryColor,
      secondaryColor: process.env.COMPANY_SECONDARY_COLOR || defaultConfig.company.secondaryColor
    },
    app: {
      title: process.env.APP_TITLE || defaultConfig.app.title,
      description: process.env.APP_DESCRIPTION || defaultConfig.app.description,
      version: process.env.APP_VERSION || defaultConfig.app.version
    },
    database: {
      prefix: process.env.DB_PREFIX || defaultConfig.database.prefix,
      name: process.env.DB_NAME || defaultConfig.database.name
    },
    features: {
      multiTenant: process.env.MULTI_TENANT === 'true',
      customBranding: process.env.CUSTOM_BRANDING !== 'false',
      advancedReporting: process.env.ADVANCED_REPORTING !== 'false'
    },
    contact: {
      email: process.env.COMPANY_EMAIL || defaultConfig.contact.email,
      phone: process.env.COMPANY_PHONE || defaultConfig.contact.phone,
      address: process.env.COMPANY_ADDRESS || defaultConfig.contact.address
    }
  };
};

// Controlador para obtener la configuración de la empresa
export const getCompanyConfig = async (req: Request, res: Response) => {
  try {
    const config = getConfigFromEnv();
    
    res.status(200).json({
      success: true,
      data: config,
      message: 'Configuración de la empresa obtenida exitosamente'
    });
  } catch (error) {
    console.error('Error al obtener configuración de la empresa:', error);
    res.status(500).json({
      success: false,
      message: 'Error interno del servidor',
      error: process.env.NODE_ENV === 'development' ? error : undefined
    });
  }
};

// Controlador para obtener información básica de la empresa (público)
export const getCompanyInfo = async (req: Request, res: Response) => {
  try {
    const config = getConfigFromEnv();
    
    // Solo devolver información pública
    const publicInfo = {
      company: {
        name: config.company.name,
        domain: config.company.domain,
        logo: config.company.logo,
        primaryColor: config.company.primaryColor,
        secondaryColor: config.company.secondaryColor
      },
      app: {
        title: config.app.title,
        description: config.app.description,
        version: config.app.version
      },
      contact: {
        email: config.contact.email,
        phone: config.contact.phone,
        address: config.contact.address
      },
      features: {
        customBranding: config.features.customBranding
      }
    };
    
    res.status(200).json({
      success: true,
      data: publicInfo,
      message: 'Información pública de la empresa obtenida exitosamente'
    });
  } catch (error) {
    console.error('Error al obtener información de la empresa:', error);
    res.status(500).json({
      success: false,
      message: 'Error interno del servidor',
      error: process.env.NODE_ENV === 'development' ? error : undefined
    });
  }
};

// Controlador para actualizar la configuración de la empresa (solo admin)
export const updateCompanyConfig = async (req: Request, res: Response) => {
  try {
    // TODO: Implementar validación de permisos de administrador
    // TODO: Implementar actualización de variables de entorno o base de datos
    
    res.status(501).json({
      success: false,
      message: 'Funcionalidad de actualización no implementada aún'
    });
  } catch (error) {
    console.error('Error al actualizar configuración de la empresa:', error);
    res.status(500).json({
      success: false,
      message: 'Error interno del servidor',
      error: process.env.NODE_ENV === 'development' ? error : undefined
    });
  }
};

// Controlador para obtener el estado de salud de la configuración
export const getConfigHealth = async (req: Request, res: Response) => {
  try {
    const config = getConfigFromEnv();
    
    // Verificar que las configuraciones críticas estén presentes
    const healthChecks = {
      companyName: !!config.company.name,
      domain: !!config.company.domain,
      database: !!config.database.name,
      jwtSecret: !!process.env.JWT_SECRET,
      dbConnection: !!process.env.DB_HOST && !!process.env.DB_USER
    };
    
    const isHealthy = Object.values(healthChecks).every(check => check);
    
    res.status(isHealthy ? 200 : 503).json({
      success: isHealthy,
      data: {
        status: isHealthy ? 'healthy' : 'unhealthy',
        checks: healthChecks,
        timestamp: new Date().toISOString()
      },
      message: isHealthy ? 'Configuración saludable' : 'Problemas en la configuración'
    });
  } catch (error) {
    console.error('Error al verificar salud de la configuración:', error);
    res.status(500).json({
      success: false,
      message: 'Error interno del servidor',
      error: process.env.NODE_ENV === 'development' ? error : undefined
    });
  }
};

export default {
  getCompanyConfig,
  getCompanyInfo,
  updateCompanyConfig,
  getConfigHealth
};

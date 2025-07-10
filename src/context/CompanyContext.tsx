import React, { createContext, useContext, useEffect, useState } from 'react';

// Tipos para la configuración de la empresa
export interface CompanyConfig {
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

// Contexto de la empresa
const CompanyContext = createContext<{
  config: CompanyConfig;
  isLoading: boolean;
  updateConfig: (newConfig: Partial<CompanyConfig>) => void;
}>({
  config: defaultConfig,
  isLoading: true,
  updateConfig: () => {}
});

// Hook para usar el contexto de la empresa
export const useCompany = () => {
  const context = useContext(CompanyContext);
  if (!context) {
    throw new Error('useCompany debe ser usado dentro de un CompanyProvider');
  }
  return context;
};

// Proveedor del contexto de la empresa
export const CompanyProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [config, setConfig] = useState<CompanyConfig>(defaultConfig);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    // Cargar configuración desde variables de entorno o API
    const loadConfig = async () => {
      try {
        // Intentar cargar desde el backend
        const response = await fetch('/api/company/config');
        if (response.ok) {
          const serverConfig = await response.json();
          setConfig(serverConfig);
        } else {
          // Si no hay configuración del servidor, usar variables de entorno
          const envConfig: CompanyConfig = {
            company: {
              name: process.env.REACT_APP_COMPANY_NAME || defaultConfig.company.name,
              domain: process.env.REACT_APP_COMPANY_DOMAIN || defaultConfig.company.domain,
              logo: process.env.REACT_APP_COMPANY_LOGO || defaultConfig.company.logo,
              primaryColor: process.env.REACT_APP_COMPANY_PRIMARY_COLOR || defaultConfig.company.primaryColor,
              secondaryColor: process.env.REACT_APP_COMPANY_SECONDARY_COLOR || defaultConfig.company.secondaryColor
            },
            app: {
              title: process.env.REACT_APP_TITLE || defaultConfig.app.title,
              description: process.env.REACT_APP_DESCRIPTION || defaultConfig.app.description,
              version: process.env.REACT_APP_VERSION || defaultConfig.app.version
            },
            database: {
              prefix: process.env.REACT_APP_DB_PREFIX || defaultConfig.database.prefix,
              name: process.env.REACT_APP_DB_NAME || defaultConfig.database.name
            },
            features: {
              multiTenant: process.env.REACT_APP_MULTI_TENANT === 'true',
              customBranding: process.env.REACT_APP_CUSTOM_BRANDING !== 'false',
              advancedReporting: process.env.REACT_APP_ADVANCED_REPORTING !== 'false'
            },
            contact: {
              email: process.env.REACT_APP_COMPANY_EMAIL || defaultConfig.contact.email,
              phone: process.env.REACT_APP_COMPANY_PHONE || defaultConfig.contact.phone,
              address: process.env.REACT_APP_COMPANY_ADDRESS || defaultConfig.contact.address
            }
          };
          setConfig(envConfig);
        }
      } catch (error) {
        console.warn('No se pudo cargar la configuración de la empresa, usando configuración por defecto:', error);
        setConfig(defaultConfig);
      } finally {
        setIsLoading(false);
      }
    };

    loadConfig();
  }, []);

  // Aplicar colores personalizados al CSS
  useEffect(() => {
    if (config.features.customBranding) {
      const root = document.documentElement;
      root.style.setProperty('--primary-color', config.company.primaryColor);
      root.style.setProperty('--secondary-color', config.company.secondaryColor);
      
      // Actualizar el título de la página
      document.title = `${config.app.title} - ${config.company.name}`;
      
      // Actualizar meta description
      const metaDescription = document.querySelector('meta[name="description"]');
      if (metaDescription) {
        metaDescription.setAttribute('content', config.app.description);
      }
    }
  }, [config]);

  const updateConfig = (newConfig: Partial<CompanyConfig>) => {
    setConfig(prevConfig => ({
      ...prevConfig,
      ...newConfig,
      company: { ...prevConfig.company, ...newConfig.company },
      app: { ...prevConfig.app, ...newConfig.app },
      database: { ...prevConfig.database, ...newConfig.database },
      features: { ...prevConfig.features, ...newConfig.features },
      contact: { ...prevConfig.contact, ...newConfig.contact }
    }));
  };

  return (
    <CompanyContext.Provider value={{ config, isLoading, updateConfig }}>
      {children}
    </CompanyContext.Provider>
  );
};

export default CompanyContext;

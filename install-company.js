#!/usr/bin/env node

/**
 * Script de instalación para configurar la aplicación para una empresa específica
 * Permite personalizar el dominio, nombre de la empresa y otras configuraciones
 */

const fs = require('fs');
const path = require('path');
const readline = require('readline');

// Crear interfaz para entrada de usuario
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

// Función para hacer preguntas al usuario
function askQuestion(question) {
  return new Promise((resolve) => {
    rl.question(question, (answer) => {
      resolve(answer.trim());
    });
  });
}

// Función para validar dominio
function isValidDomain(domain) {
  const domainRegex = /^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$/;
  return domainRegex.test(domain) || domain === 'localhost';
}

// Función para validar email
function isValidEmail(email) {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

// Función para generar archivo .env
function generateEnvFile(config) {
  const envContent = `# Configuración de la Empresa
COMPANY_NAME=${config.companyName}
COMPANY_DOMAIN=${config.domain}
COMPANY_EMAIL=${config.email}
COMPANY_PHONE=${config.phone}
COMPANY_ADDRESS=${config.address}
COMPANY_LOGO=${config.logo}
COMPANY_PRIMARY_COLOR=${config.primaryColor}
COMPANY_SECONDARY_COLOR=${config.secondaryColor}

# Configuración de la Aplicación
APP_TITLE=${config.appTitle}
APP_DESCRIPTION=${config.appDescription}
APP_VERSION=1.0.0

# Configuración de Base de Datos
DB_HOST=${config.dbHost}
DB_USER=${config.dbUser}
DB_PASSWORD=${config.dbPassword}
DB_NAME=${config.dbName}
DB_PORT=${config.dbPort}
DB_PREFIX=${config.dbPrefix}

# Configuración JWT
JWT_SECRET=${config.jwtSecret}

# Configuración del Servidor
NODE_ENV=production
PORT=${config.port}
FRONTEND_URL=https://${config.domain}

# Características
MULTI_TENANT=${config.multiTenant}
CUSTOM_BRANDING=true
ADVANCED_REPORTING=${config.advancedReporting}

# Configuración de Archivos
MAX_FILE_SIZE=5242880
UPLOAD_PATH=uploads/receipts
`;

  return envContent;
}

// Función para generar archivo HTML personalizado
function generateCustomHTML(config) {
  const htmlContent = `<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${config.appTitle} - ${config.companyName}</title>
  <meta name="description" content="${config.appDescription}">
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">
  <style>
    :root {
      --primary-color: ${config.primaryColor};
      --secondary-color: ${config.secondaryColor};
    }
  </style>
</head>
<body>
  <div id="root"></div>
</body>
</html>`;

  return htmlContent;
}

// Función para generar configuración de webpack personalizada
function generateWebpackConfig(config) {
  const webpackContent = `const HtmlWebpackPlugin = require('html-webpack-plugin');
const path = require('path');

module.exports = {
  entry: './src/index.tsx',
  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: 'bundle.[contenthash].js',
    publicPath: '/',
    clean: true
  },
  resolve: {
    extensions: ['.tsx', '.ts', '.js', '.jsx']
  },
  module: {
    rules: [
      {
        test: /\\.(ts|tsx)$/,
        use: 'ts-loader',
        exclude: /node_modules/
      },
      {
        test: /\\.css$/,
        use: ['style-loader', 'css-loader']
      },
      {
        test: /\\.(png|jpg|jpeg|gif|svg)$/,
        type: 'asset/resource'
      }
    ]
  },
  plugins: [
    new HtmlWebpackPlugin({
      template: './public/index.html',
      title: '${config.appTitle} - ${config.companyName}',
      meta: {
        description: '${config.appDescription}'
      }
    })
  ],
  devServer: {
    port: 3000,
    historyApiFallback: true,
    hot: true
  }
};`;

  return webpackContent;
}

// Función principal de instalación
async function installCompany() {
  console.log('🚀 Bienvenido al instalador de la aplicación de gestión empresarial');
  console.log('Este asistente te ayudará a configurar la aplicación para tu empresa.\n');

  try {
    // Recopilar información de la empresa
    const companyName = await askQuestion('📝 Nombre de la empresa: ');
    if (!companyName) {
      throw new Error('El nombre de la empresa es obligatorio');
    }

    let domain;
    do {
      domain = await askQuestion('🌐 Dominio de la empresa (ej: miempresa.com o localhost): ');
      if (!isValidDomain(domain)) {
        console.log('❌ Dominio inválido. Por favor ingresa un dominio válido.');
      }
    } while (!isValidDomain(domain));

    let email;
    do {
      email = await askQuestion('📧 Email de contacto de la empresa: ');
      if (!isValidEmail(email)) {
        console.log('❌ Email inválido. Por favor ingresa un email válido.');
      }
    } while (!isValidEmail(email));

    const phone = await askQuestion('📞 Teléfono de la empresa: ');
    const address = await askQuestion('📍 Dirección de la empresa: ');

    // Configuración de la aplicación
    const appTitle = await askQuestion(`📱 Título de la aplicación [Sistema de Pedidos]: `) || 'Sistema de Pedidos';
    const appDescription = await askQuestion(`📄 Descripción de la aplicación [Sistema de gestión de pedidos y logística]: `) || 'Sistema de gestión de pedidos y logística';

    // Configuración de colores
    const primaryColor = await askQuestion('🎨 Color primario (hex) [#007bff]: ') || '#007bff';
    const secondaryColor = await askQuestion('🎨 Color secundario (hex) [#6c757d]: ') || '#6c757d';

    // Configuración de base de datos
    console.log('\n📊 Configuración de Base de Datos:');
    const dbHost = await askQuestion('🖥️  Host de la base de datos [localhost]: ') || 'localhost';
    const dbUser = await askQuestion('👤 Usuario de la base de datos [root]: ') || 'root';
    const dbPassword = await askQuestion('🔒 Contraseña de la base de datos: ');
    const dbName = await askQuestion(`💾 Nombre de la base de datos [${companyName.toLowerCase().replace(/\s+/g, '_')}_db]: `) || `${companyName.toLowerCase().replace(/\s+/g, '_')}_db`;
    const dbPort = await askQuestion('🔌 Puerto de la base de datos [3306]: ') || '3306';
    const dbPrefix = await askQuestion(`🏷️  Prefijo de tablas [${companyName.toLowerCase().replace(/\s+/g, '_')}_]: `) || `${companyName.toLowerCase().replace(/\s+/g, '_')}_`;

    // Configuración del servidor
    const port = await askQuestion('🚪 Puerto del servidor [5000]: ') || '5000';

    // Generar JWT Secret
    const jwtSecret = require('crypto').randomBytes(64).toString('hex');

    // Características adicionales
    const multiTenant = await askQuestion('🏢 ¿Habilitar multi-tenant? (y/n) [n]: ') || 'n';
    const advancedReporting = await askQuestion('📊 ¿Habilitar reportes avanzados? (y/n) [y]: ') || 'y';

    const logo = '/assets/logo.png';

    const config = {
      companyName,
      domain,
      email,
      phone,
      address,
      appTitle,
      appDescription,
      primaryColor,
      secondaryColor,
      dbHost,
      dbUser,
      dbPassword,
      dbName,
      dbPort,
      dbPrefix,
      port,
      jwtSecret,
      multiTenant: multiTenant.toLowerCase() === 'y' ? 'true' : 'false',
      advancedReporting: advancedReporting.toLowerCase() === 'y' ? 'true' : 'false',
      logo
    };

    console.log('\n⚙️ Generando archivos de configuración...');

    // Crear archivo .env principal
    fs.writeFileSync('.env', generateEnvFile(config));
    console.log('✅ Archivo .env creado');

    // Crear archivo .env para backend
    const backendEnvContent = `# Server Configuration
PORT=${config.port}
NODE_ENV=production

# Database Configuration
DB_HOST=${config.dbHost}
DB_USER=${config.dbUser}
DB_PASSWORD=${config.dbPassword}
DB_NAME=${config.dbName}
DB_PORT=${config.dbPort}

# JWT Configuration
JWT_SECRET=${config.jwtSecret}

# Company Configuration
COMPANY_NAME=${config.companyName}
COMPANY_DOMAIN=${config.domain}
`;

    fs.writeFileSync('backend/.env', backendEnvContent);
    console.log('✅ Archivo backend/.env creado');

    // Actualizar HTML personalizado
    fs.writeFileSync('public/index.html', generateCustomHTML(config));
    console.log('✅ Archivo public/index.html actualizado');

    // Crear archivo de configuración de empresa
    const companyConfigContent = `/**
 * Configuración específica de ${config.companyName}
 * Generado automáticamente el ${new Date().toISOString()}
 */

module.exports = {
  company: {
    name: '${config.companyName}',
    domain: '${config.domain}',
    logo: '${config.logo}',
    primaryColor: '${config.primaryColor}',
    secondaryColor: '${config.secondaryColor}'
  },
  app: {
    title: '${config.appTitle}',
    description: '${config.appDescription}',
    version: '1.0.0'
  },
  database: {
    prefix: '${config.dbPrefix}',
    name: '${config.dbName}'
  },
  features: {
    multiTenant: ${config.multiTenant},
    customBranding: true,
    advancedReporting: ${config.advancedReporting}
  },
  contact: {
    email: '${config.email}',
    phone: '${config.phone}',
    address: '${config.address}'
  }
};`;

    fs.writeFileSync('config/company.config.js', companyConfigContent);
    console.log('✅ Archivo config/company.config.js actualizado');

    // Crear script de inicio personalizado
    const startScript = `#!/bin/bash

echo "🚀 Iniciando ${config.companyName} - ${config.appTitle}"
echo "🌐 Dominio: ${config.domain}"
echo "🔧 Puerto: ${config.port}"

# Verificar que existe la configuración
if [ ! -f ".env" ]; then
    echo "❌ Error: Archivo .env no encontrado. Ejecuta 'node install-company.js' primero."
    exit 1
fi

# Instalar dependencias si es necesario
if [ ! -d "node_modules" ]; then
    echo "📦 Instalando dependencias del frontend..."
    npm install
fi

if [ ! -d "backend/node_modules" ]; then
    echo "📦 Instalando dependencias del backend..."
    cd backend && npm install && cd ..
fi

# Construir la aplicación
echo "🔨 Construyendo la aplicación..."
npm run build

# Inicializar base de datos
echo "🗄️ Inicializando base de datos..."
cd backend && npm run init-db && cd ..

# Iniciar la aplicación
echo "▶️ Iniciando servidor..."
cd backend && npm start
`;

    fs.writeFileSync('start-company.sh', startScript);
    fs.chmodSync('start-company.sh', '755');
    console.log('✅ Script start-company.sh creado');

    // Crear archivo README personalizado
    const readmeContent = `# ${config.companyName} - ${config.appTitle}

${config.appDescription}

## Información de la Empresa

- **Empresa:** ${config.companyName}
- **Dominio:** ${config.domain}
- **Email:** ${config.email}
- **Teléfono:** ${config.phone}
- **Dirección:** ${config.address}

## Configuración

Esta aplicación ha sido configurada específicamente para ${config.companyName}.

### Características Habilitadas

- Multi-tenant: ${config.multiTenant === 'true' ? 'Sí' : 'No'}
- Reportes Avanzados: ${config.advancedReporting === 'true' ? 'Sí' : 'No'}
- Branding Personalizado: Sí

### Base de Datos

- **Host:** ${config.dbHost}
- **Puerto:** ${config.dbPort}
- **Base de Datos:** ${config.dbName}
- **Prefijo de Tablas:** ${config.dbPrefix}

## Instalación y Uso

### Requisitos Previos

- Node.js 16 o superior
- MySQL 8.0 o superior
- npm o yarn

### Instalación

1. Clona este repositorio
2. Ejecuta el instalador: \`node install-company.js\`
3. Inicia la aplicación: \`./start-company.sh\`

### Desarrollo

\`\`\`bash
# Instalar dependencias
npm install
cd backend && npm install && cd ..

# Modo desarrollo
npm run dev
\`\`\`

### Producción

\`\`\`bash
# Construir aplicación
npm run build

# Iniciar servidor
./start-company.sh
\`\`\`

## Soporte

Para soporte técnico, contacta a:
- Email: ${config.email}
- Teléfono: ${config.phone}

---

Aplicación configurada el ${new Date().toLocaleDateString('es-ES')}
`;

    fs.writeFileSync('README-COMPANY.md', readmeContent);
    console.log('✅ Archivo README-COMPANY.md creado');

    console.log('\n🎉 ¡Instalación completada exitosamente!');
    console.log('\n📋 Resumen de la configuración:');
    console.log(`   Empresa: ${config.companyName}`);
    console.log(`   Dominio: ${config.domain}`);
    console.log(`   Aplicación: ${config.appTitle}`);
    console.log(`   Base de Datos: ${config.dbName}`);
    console.log(`   Puerto: ${config.port}`);

    console.log('\n🚀 Próximos pasos:');
    console.log('1. Asegúrate de que MySQL esté ejecutándose');
    console.log('2. Crea la base de datos si no existe');
    console.log('3. Ejecuta: ./start-company.sh');
    console.log(`4. Accede a: http://${config.domain}:${config.port}`);

    console.log('\n📚 Documentación adicional en README-COMPANY.md');

  } catch (error) {
    console.error('\n❌ Error durante la instalación:', error.message);
    process.exit(1);
  } finally {
    rl.close();
  }
}

// Ejecutar instalación
if (require.main === module) {
  installCompany();
}

module.exports = { installCompany };

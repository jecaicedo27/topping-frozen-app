export enum UserRole {
  ADMIN = 'admin',
  FACTURACION = 'facturacion',
  CARTERA = 'cartera',
  LOGISTICA = 'logistica',
  MENSAJERO = 'mensajero',
  REGULAR = 'regular'
}

export enum DeliveryMethod {
  DOMICILIO = 'Domicilio',
  RECOGIDA_TIENDA = 'Recogida en tienda',
  ENVIO_NACIONAL = 'Envío nacional',
  ENVIO_INTERNACIONAL = 'Envío internacional'
}

export enum PaymentMethod {
  EFECTIVO = 'Efectivo',
  TRANSFERENCIA = 'Transferencia bancaria',
  TARJETA_CREDITO = 'Tarjeta de crédito',
  PAGO_ELECTRONICO = 'Pago electrónico'
}

export enum PaymentStatus {
  PENDIENTE = 'Pendiente por cobrar',
  PAGADO = 'Pagado',
  CREDITO_APROBADO = 'Crédito aprobado'
}

export interface User {
  id: string;
  name: string;
  role: UserRole;
}

export interface UserContextType {
  userRole: UserRole;
  setUserRole: (role: UserRole) => void;
}

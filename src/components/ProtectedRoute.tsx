import React, { ReactNode } from 'react';
import { Navigate, Outlet } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { UserRole } from '../types/user';

interface ProtectedRouteProps {
  allowedRoles?: UserRole[];
  children?: ReactNode;
}

const ProtectedRoute: React.FC<ProtectedRouteProps> = ({ allowedRoles, children }) => {
  const { authState } = useAuth();
  const { isAuthenticated, user, loading } = authState;

  // Show loading indicator while checking authentication
  if (loading) {
    return (
      <div className="d-flex justify-content-center align-items-center" style={{ height: '100vh' }}>
        <div className="spinner-border text-primary" role="status">
          <span className="visually-hidden">Cargando...</span>
        </div>
      </div>
    );
  }

  // If not authenticated, redirect to login
  if (!isAuthenticated || !user) {
    return <Navigate to="/login" replace />;
  }

  // If roles are specified, check if user has required role
  if (allowedRoles && allowedRoles.length > 0) {
    if (!allowedRoles.includes(user.role)) {
      // If user doesn't have required role, redirect to dashboard
      return <Navigate to="/" replace />;
    }
  }

  // If authenticated and has required role, render the children or outlet
  return children ? <>{children}</> : <Outlet />;
};

export default ProtectedRoute;

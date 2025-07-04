import React from 'react';
import { Navbar, Container, Nav, NavDropdown, Button } from 'react-bootstrap';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { UserRole } from '../types/user';

const Navigation: React.FC = () => {
  const { authState, logout } = useAuth();
  const { user } = authState;
  const location = useLocation();
  const navigate = useNavigate();

  const isActive = (path: string) => location.pathname === path;

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  return (
    <Navbar bg="dark" variant="dark" expand="lg" className="mb-3" expanded={true}>
      <Container>
        <Navbar.Brand as={Link} to="/">TOPPING FROZEN</Navbar.Brand>
        <Navbar.Toggle aria-controls="basic-navbar-nav" />
        <Navbar.Collapse id="basic-navbar-nav">
          <Nav className="me-auto">
            <Nav.Link as={Link} to="/" active={isActive('/')}>
              <i className="bi bi-speedometer2"></i> Dashboard
            </Nav.Link>
            
            {(user?.role === UserRole.ADMIN || user?.role === UserRole.FACTURACION) && (
              <Nav.Link as={Link} to="/facturacion" active={isActive('/facturacion')}>
                <i className="bi bi-receipt"></i> Facturación
              </Nav.Link>
            )}
            
            {(user?.role === UserRole.ADMIN || user?.role === UserRole.CARTERA || user?.role === UserRole.FACTURACION) && (
              <Nav.Link as={Link} to="/cartera" active={isActive('/cartera')}>
                <i className="bi bi-wallet2"></i> Cartera
              </Nav.Link>
            )}
            
            {(user?.role === UserRole.ADMIN || user?.role === UserRole.LOGISTICA) && (
              <Nav.Link as={Link} to="/logistica" active={isActive('/logistica')}>
                <i className="bi bi-box-seam"></i> Logística
              </Nav.Link>
            )}
            
            {(user?.role === UserRole.ADMIN || user?.role === UserRole.MENSAJERO) && (
              <Nav.Link as={Link} to="/mensajero" active={isActive('/mensajero')}>
                <i className="bi bi-bicycle"></i> Mensajero
              </Nav.Link>
            )}
          </Nav>
          
          {/* User Menu */}
          <div className="d-flex align-items-center">
            <NavDropdown 
              title={
                <>
                  <i className="bi bi-person-circle me-1"></i>
                  {user?.name || 'Usuario'}
                </>
              } 
              id="user-dropdown"
              className="me-2"
            >
              <NavDropdown.Item disabled>
                <small className="text-muted">Rol: {user?.role}</small>
              </NavDropdown.Item>
              <NavDropdown.Divider />
              <NavDropdown.Item onClick={handleLogout}>
                <i className="bi bi-box-arrow-right me-2"></i>
                Cerrar Sesión
              </NavDropdown.Item>
            </NavDropdown>
            
            {/* Separate Logout Button */}
            <Button 
              variant="outline-light" 
              size="sm" 
              onClick={handleLogout}
              className="d-flex align-items-center"
            >
              <i className="bi bi-box-arrow-right me-2"></i>
              Cerrar Sesión
            </Button>
          </div>
        </Navbar.Collapse>
      </Container>
    </Navbar>
  );
};

export default Navigation;

import React, { useState, useEffect } from 'react';
import { Container, Row, Col, Card, Form, Button, Alert, Spinner } from 'react-bootstrap';
import { useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { LoginCredentials } from '../types/auth';

const Login: React.FC = () => {
  const [credentials, setCredentials] = useState<LoginCredentials>({
    username: '',
    password: ''
  });
  const [validated, setValidated] = useState(false);
  const { authState, login } = useAuth();
  const { loading, error, isAuthenticated } = authState;
  const navigate = useNavigate();
  const location = useLocation();

  // Redirect if already authenticated
  useEffect(() => {
    if (isAuthenticated) {
      const from = (location.state as any)?.from?.pathname || '/';
      navigate(from, { replace: true });
    }
  }, [isAuthenticated, navigate, location]);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setCredentials(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    
    const form = e.currentTarget;
    if (form.checkValidity() === false) {
      e.stopPropagation();
      setValidated(true);
      return;
    }
    
    setValidated(true);
    
    const success = await login(credentials);
    if (success) {
      // Login successful, redirect will happen in useEffect
    }
  };

  return (
    <Container>
      <Row className="justify-content-center mt-5">
        <Col md={6} lg={5}>
          <Card className="shadow-sm">
            <Card.Body className="p-4">
              <div className="text-center mb-4">
                <h2 className="mb-3">TOPPING FROZEN</h2>
                <h4>Iniciar Sesión</h4>
                <p className="text-muted">Sistema de Gestión de Pedidos</p>
              </div>
              
              {error && (
                <Alert variant="danger" className="mb-4">
                  {error}
                </Alert>
              )}
              
              <Form noValidate validated={validated} onSubmit={handleSubmit}>
                <Form.Group className="mb-3">
                  <Form.Label>Usuario</Form.Label>
                  <Form.Control
                    type="text"
                    name="username"
                    value={credentials.username}
                    onChange={handleChange}
                    placeholder="Ingrese su nombre de usuario"
                    required
                    disabled={loading}
                  />
                  <Form.Control.Feedback type="invalid">
                    Por favor ingrese su nombre de usuario
                  </Form.Control.Feedback>
                </Form.Group>
                
                <Form.Group className="mb-4">
                  <Form.Label>Contraseña</Form.Label>
                  <Form.Control
                    type="password"
                    name="password"
                    value={credentials.password}
                    onChange={handleChange}
                    placeholder="Ingrese su contraseña"
                    required
                    disabled={loading}
                  />
                  <Form.Control.Feedback type="invalid">
                    Por favor ingrese su contraseña
                  </Form.Control.Feedback>
                </Form.Group>
                
                <div className="d-grid gap-2">
                  <Button variant="primary" type="submit" disabled={loading}>
                    {loading ? (
                      <>
                        <Spinner
                          as="span"
                          animation="border"
                          size="sm"
                          role="status"
                          aria-hidden="true"
                          className="me-2"
                        />
                        Iniciando sesión...
                      </>
                    ) : (
                      'Iniciar Sesión'
                    )}
                  </Button>
                </div>
              </Form>
              
              <div className="mt-4 text-center">
                <div className="alert alert-info mb-0">
                  <strong>Usuarios de prueba:</strong>
                  <ul className="mb-0 mt-2 text-start">
                    <li>Usuario: <code>admin</code> - Rol: Administrador</li>
                    <li>Usuario: <code>facturacion</code> - Rol: Facturación</li>
                    <li>Usuario: <code>cartera</code> - Rol: Cartera</li>
                    <li>Usuario: <code>logistica</code> - Rol: Logística</li>
                    <li>Usuario: <code>mensajero</code> - Rol: Mensajero</li>
                    <li>Usuario: <code>regular</code> - Rol: Usuario Regular</li>
                  </ul>
                  <p className="mt-2 mb-0">Contraseña para todos: <code>123456</code></p>
                </div>
              </div>
            </Card.Body>
          </Card>
        </Col>
      </Row>
    </Container>
  );
};

export default Login;

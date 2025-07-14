import React from 'react';
import { Container, Row, Col, Card, Button } from 'react-bootstrap';
import { Link } from 'react-router-dom';

const NotFound: React.FC = () => {
  return (
    <Container>
      <Row className="justify-content-center mt-5">
        <Col md={8} lg={6}>
          <Card className="shadow-sm text-center">
            <Card.Body className="p-5">
              <div className="mb-4">
                <i className="bi bi-exclamation-triangle text-warning" style={{ fontSize: '4rem' }}></i>
              </div>
              <Card.Title as="h2">Página No Encontrada</Card.Title>
              <Card.Text className="mb-4">
                Lo sentimos, la página que estás buscando no existe o ha sido movida.
              </Card.Text>
              <Link to="/" className="btn btn-primary">
                <i className="bi bi-house-door me-2"></i>
                Volver al Inicio
              </Link>
            </Card.Body>
          </Card>
        </Col>
      </Row>
    </Container>
  );
};

export default NotFound;

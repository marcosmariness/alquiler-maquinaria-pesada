abstract class ServicioAlquiler {
  double calcularPrecio();
  DateTime getFechaInicio();
  int getDias();
}

// Interfaces específicas para el patrón Decorator
abstract class ITractor extends ServicioAlquiler {}
abstract class IMaquina extends ServicioAlquiler {}

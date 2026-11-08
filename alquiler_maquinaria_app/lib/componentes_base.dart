import 'servicio_alquiler.dart';

class TractorBase implements ITractor {
  final int id;
  final String nombre;
  final double precioBaseDia;
  final DateTime fechaInicio;
  final int dias;

  TractorBase({
    required this.id,
    required this.nombre,
    required this.precioBaseDia,
    required this.fechaInicio,
    required this.dias,
  });

  @override
  double calcularPrecio() => precioBaseDia * dias;

  @override
  DateTime getFechaInicio() => fechaInicio;

  @override
  int getDias() => dias;
}

class MaquinaBase implements IMaquina {
  final int id;
  final String nombre;
  final double precioBaseDia;
  final DateTime fechaInicio;
  final int dias;

  MaquinaBase({
    required this.id,
    required this.nombre,
    required this.precioBaseDia,
    required this.fechaInicio,
    required this.dias,
  });

  @override
  double calcularPrecio() => precioBaseDia * dias;

  @override
  DateTime getFechaInicio() => fechaInicio;

  @override
  int getDias() => dias;
}

class AccesorioSuelto implements ServicioAlquiler {
  final int id;
  final String nombre;
  final double precioBaseDia;
  final DateTime fechaInicio;
  final int dias;

  AccesorioSuelto({
    required this.id,
    required this.nombre,
    required this.precioBaseDia,
    required this.fechaInicio,
    required this.dias,
  });

  @override
  double calcularPrecio() => precioBaseDia * dias;

  @override
  DateTime getFechaInicio() => fechaInicio;

  @override
  int getDias() => dias;
}

import 'servicio_alquiler.dart';
import 'estrategia_envio.dart';

class Paquete implements ServicioAlquiler {
  final List<ServicioAlquiler> elementos = [];
  
  // Por defecto, aplicamos la estrategia estándar
  EstrategiaEnvio estrategia = EnvioEstandar();

  void addElemento(ServicioAlquiler e) => elementos.add(e);
  void removeElemento(ServicioAlquiler e) => elementos.remove(e);
  void clear() => elementos.clear();

  @override
  double calcularPrecio() {
    double total = 0;
    for (var e in elementos) {
      total += e.calcularPrecio();
    }
    return total;
  }

  double getCosteEnvio() {
    return estrategia.calcularCosteEnvio(elementos.length, calcularPrecio());
  }

  double getGranTotal() => calcularPrecio() + getCosteEnvio();

  // Métodos obligatorios por la interfaz general
  @override
  DateTime getFechaInicio() => elementos.isNotEmpty ? elementos.first.getFechaInicio() : DateTime.now();
  
  @override
  int getDias() => elementos.isNotEmpty ? elementos.first.getDias() : 0;
}

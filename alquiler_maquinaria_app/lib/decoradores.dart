import 'servicio_alquiler.dart';

// --- DECORADORES DE TRACTOR ---
abstract class TractorDecorator implements ITractor {
  final ITractor tractorEnvuelto;
  TractorDecorator(this.tractorEnvuelto);

  @override
  DateTime getFechaInicio() => tractorEnvuelto.getFechaInicio();

  @override
  int getDias() => tractorEnvuelto.getDias();
}

class ConRemolque extends TractorDecorator {
  final double precioRemolqueDia = 40.0;
  ConRemolque(super.tractorEnvuelto);

  @override
  double calcularPrecio() {
    return tractorEnvuelto.calcularPrecio() + (precioRemolqueDia * getDias());
  }
}

class ConGpsAgricola extends TractorDecorator {
  final double precioGpsDia = 15.0;
  ConGpsAgricola(super.tractorEnvuelto);

  @override
  double calcularPrecio() {
    return tractorEnvuelto.calcularPrecio() + (precioGpsDia * getDias());
  }
}

// --- DECORADORES DE MÁQUINA ---
abstract class MaquinaDecorator implements IMaquina {
  final IMaquina maquinaEnvuelta;
  MaquinaDecorator(this.maquinaEnvuelta);

  @override
  DateTime getFechaInicio() => maquinaEnvuelta.getFechaInicio();

  @override
  int getDias() => maquinaEnvuelta.getDias();
}

class ConSeguroPremium extends MaquinaDecorator {
  final double precioSeguroDia = 25.0;
  ConSeguroPremium(super.maquinaEnvuelta);

  @override
  double calcularPrecio() {
    return maquinaEnvuelta.calcularPrecio() + (precioSeguroDia * getDias());
  }
}

class ConOperario extends MaquinaDecorator {
  final double precioOperarioDia = 100.0;
  ConOperario(super.maquinaEnvuelta);

  @override
  double calcularPrecio() {
    return maquinaEnvuelta.calcularPrecio() + (precioOperarioDia * getDias());
  }
}

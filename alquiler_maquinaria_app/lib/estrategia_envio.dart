// --- PATRÓN STRATEGY ---
abstract class EstrategiaEnvio {
  double calcularCosteEnvio(int numItems, double precioTotal);
}

class EnvioEstandar implements EstrategiaEnvio {
  @override
  double calcularCosteEnvio(int numItems, double precioTotal) => 50.0 + (numItems * 10.0);
}

class EnvioUrgente implements EstrategiaEnvio {
  @override
  double calcularCosteEnvio(int numItems, double precioTotal) => 120.0 + (numItems * 15.0);
}

class RecogidaEnTienda implements EstrategiaEnvio {
  @override
  double calcularCosteEnvio(int numItems, double precioTotal) => 0.0;
}


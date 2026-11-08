// Pruebas unitarias de patrones de diseño y lógica de negocio en Flutter
import 'package:flutter_test/flutter_test.dart';
import 'package:alquiler_maquinaria_app/servicio_alquiler.dart';
import 'package:alquiler_maquinaria_app/componentes_base.dart';
import 'package:alquiler_maquinaria_app/decoradores.dart';
import 'package:alquiler_maquinaria_app/estrategia_envio.dart';
import 'package:alquiler_maquinaria_app/composite.dart';

void main() {
  
  // =========================================================================
  // GRUPO DE PRUEBAS: Lógica de Negocio y Patrones de Diseño
  // =========================================================================
  group('Pruebas de Patrones de Diseño (Lógica de Negocio en Flutter)', () {
    
    // ----------------------------------------------------
    // Test 1: Patrón Decorator aplicado a un Tractor
    // ----------------------------------------------------
    test('Patrón Decorator - Cálculo correcto con remolque y GPS', () {
      // 1. Instanciamos el componente concreto (Tractor base)
      ITractor tractor = TractorBase(
        id: 1,
        nombre: "John Deere 6R",
        precioBaseDia: 150.0,
        fechaInicio: DateTime.now(),
        dias: 2,
      ); // 150.0 * 2 días = 300.0€
      
      // 2. Aplicamos dinámicamente los decoradores envolviendo el objeto original
      tractor = ConRemolque(tractor);      // Extra Remolque (+40€/día * 2 días = +80.0€)
      tractor = ConGpsAgricola(tractor);   // Extra GPS (+15€/día * 2 días = +30.0€)
      
      // 3. Verificación: El método calcularPrecio() se resuelve de forma recursiva a través
      // de la cadena de decoradores: 300.0€ (base) + 80.0€ (remolque) + 30.0€ (GPS) = 410.0€
      expect(tractor.calcularPrecio(), 410.0);
    });

    // ----------------------------------------------------
    // Test 2: Patrón Strategy aplicado a los métodos de entrega
    // ----------------------------------------------------
    test('Patrón Strategy - Cálculo de gastos de envío', () {
      final estandar = EnvioEstandar();
      final urgente = EnvioUrgente();
      final recogida = RecogidaEnTienda();

      // >> Verificación Estrategia Estándar:
      //    Fórmula: 50.0€ (base) + (2 items * 10.0€) = 70.0€
      expect(estandar.calcularCosteEnvio(2, 500.0), 70.0);

      // >> Verificación Estrategia Urgente:
      //    Fórmula: 120.0€ (base) + (3 items * 15.0€) = 165.0€
      expect(urgente.calcularCosteEnvio(3, 1000.0), 165.0);

      // >> Verificación Estrategia Recogida:
      //    Fórmula: Siempre es 0.0€
      expect(recogida.calcularCosteEnvio(5, 2000.0), 0.0);
    });

    // ----------------------------------------------------
    // Test 3: Patrón Composite (Carrito de Compras / Paquete global)
    // ----------------------------------------------------
    test('Patrón Composite - Carrito de la compra global (Paquete)', () {
      // 1. Instanciamos el contenedor Composite (el carrito global)
      final carrito = Paquete();
      
      // 2. Creamos dos artículos individuales (elementos hoja)
      final tractor = TractorBase(
        id: 1,
        nombre: "John Deere",
        precioBaseDia: 100.0,
        fechaInicio: DateTime.now(),
        dias: 2,
      ); // Subtotal: 200.0€
      
      final maquina = MaquinaBase(
        id: 2,
        nombre: "Hormigonera",
        precioBaseDia: 50.0,
        fechaInicio: DateTime.now(),
        dias: 2,
      ); // Subtotal: 100.0€
      
      // 3. Añadimos ambos elementos al carrito de manera uniforme gracias a la interfaz común
      carrito.addElemento(tractor);
      carrito.addElemento(maquina);
      
      // 4. Verificaciones del Composite:
      // - El precio acumulativo sumado recursivamente debe ser 300.0€
      expect(carrito.calcularPrecio(), 300.0);
      
      // - El envío estándar por defecto para 2 artículos debe ser 70.0€
      expect(carrito.getCosteEnvio(), 70.0);
      
      // - El total global debe ser 370.0€ (300.0€ alquiler + 70.0€ envío)
      expect(carrito.getGranTotal(), 370.0);
      
      // 5. Verificación de intercambio de Estrategia dentro del Composite:
      // - Cambiamos la estrategia de envío a Recogida en Tienda
      carrito.estrategia = RecogidaEnTienda();
      expect(carrito.getCosteEnvio(), 0.0);      // El envío debe bajar a 0.0€
      expect(carrito.getGranTotal(), 300.0);     // El gran total debe pasar a ser exactamente 300.0€
    });
  });
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'servicio_alquiler.dart';
import 'componentes_base.dart';
import 'decoradores.dart';
import 'estrategia_envio.dart';
import 'composite.dart';
import 'login_screen.dart';

class ClienteDashboard extends StatefulWidget {
  final String email;
  const ClienteDashboard({super.key, required this.email});

  @override
  State<ClienteDashboard> createState() => _ClienteDashboardState();
}

class _ClienteDashboardState extends State<ClienteDashboard> {
  List<dynamic> _articulosBack = [];
  bool _cargando = false;

  // Historial de alquileres del cliente
  List<dynamic> _misAlquileres = [];
  bool _cargandoHistorial = false;

  // El carrito de la compra global
  final Paquete _carrito = Paquete();

  @override
  void initState() {
    super.initState();
    _cargarCatalogo();
    _cargarMisAlquileres();
  }

  Future<void> _cargarMisAlquileres() async {
    setState(() { _cargandoHistorial = true; });
    final url = Uri.parse('http://localhost:3000/reservas?email=${Uri.encodeComponent(widget.email)}');
    try {
      final respuesta = await http.get(url);
      if (respuesta.statusCode == 200) {
        setState(() { _misAlquileres = jsonDecode(respuesta.body); });
      }
    } catch (e) {
      _mostrarSnack('Error al cargar historial', Colors.red);
    } finally {
      setState(() { _cargandoHistorial = false; });
    }
  }

  Future<void> _cancelarAlquiler(int id) async {
    final url = Uri.parse('http://localhost:3000/reservas/$id');
    try {
      final respuesta = await http.delete(url);
      if (respuesta.statusCode == 200) {
        _mostrarSnack('Reserva cancelada con éxito', Colors.green);
        _cargarMisAlquileres();
        _cargarCatalogo();
      } else {
        final err = jsonDecode(respuesta.body);
        _mostrarSnack(err['error'] ?? 'No se pudo cancelar', Colors.red);
      }
    } catch (e) {
      _mostrarSnack('Error de red al cancelar', Colors.red);
    }
  }

  void _confirmarCancelacion(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar alquiler'),
        content: const Text('¿Seguro que quieres cancelar esta reserva futura? Las fechas se liberarán.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('No')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () { Navigator.pop(ctx); _cancelarAlquiler(id); },
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> _cargarCatalogo() async {
    setState(() { _cargando = true; });
    final url = Uri.parse('http://localhost:3000/articulos');
    try {
      final respuesta = await http.get(url);
      if (respuesta.statusCode == 200) {
        setState(() { _articulosBack = jsonDecode(respuesta.body); });
      }
    } catch (e) {
      _mostrarSnack('Error al conectar con el servidor', Colors.red);
    } finally {
      setState(() { _cargando = false; });
    }
  }

  Future<void> _checkoutFinal() async {
    if (_carrito.elementos.isEmpty) {
      _mostrarSnack('El carrito está vacío', Colors.orange);
      return;
    }

    final url = Uri.parse('http://localhost:3000/reservas');
    List<Map<String, dynamic>> elementosJson = [];
    
    for (int i = 0; i < _carrito.elementos.length; i++) {
      // Extraemos el elemento usando el índice i del bucle
      final itemEnCarrito = _carrito.elementos[i];
      
      elementosJson.add({
        'articulo_id': _obtenerIdReal(itemEnCarrito), 
        'dias': itemEnCarrito.getDias(),
        'decoradores': [] 
      });
    }

    String tipoEnvioStr = "Estandar";
    if (_carrito.estrategia is EnvioUrgente) tipoEnvioStr = "Urgente";
    if (_carrito.estrategia is RecogidaEnTienda) tipoEnvioStr = "Recogida";

    try {
      final respuesta = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fecha_inicio': _carrito.getFechaInicio().toString().split(' ')[0],
          'fecha_fin': _carrito.getFechaInicio().add(Duration(days: _carrito.getDias())).toString().split(' ')[0],
          'tipo_envio': tipoEnvioStr,
          'elementos': elementosJson,
          'email': widget.email,
        }),
      );

      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(respuesta.body);
        _mostrarSnack(datos['mensaje'] ?? '¡Reserva confirmada!', Colors.green);
        setState(() { _carrito.clear(); });
        _cargarCatalogo();
        _cargarMisAlquileres(); // Actualizamos también el historial
      } else {
        final err = jsonDecode(respuesta.body);
        _mostrarSnack(err['error'] ?? 'Conflicto en la reserva', Colors.red);
      }
    } catch (e) {
      _mostrarSnack('Error de red al procesar reserva', Colors.red);
    }
  }

  // Ver el carrito detallado, eliminar y editar productos
  void _verCarritoDetallado() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.shopping_cart, color: Colors.green),
              const SizedBox(width: 10),
              Text('Tu Carrito (${_carrito.elementos.length})'),
            ],
          ),
          content: _carrito.elementos.isEmpty
              ? const SizedBox(
                  height: 100,
                  child: Center(child: Text('El carrito está vacío', style: TextStyle(color: Colors.grey))),
                )
              : SizedBox(
                  width: double.maxFinite,
                  height: 320,
                  child: ListView.builder(
                    itemCount: _carrito.elementos.length,
                    itemBuilder: (context, index) {
                      final item = _carrito.elementos[index];
                      
                      String nombreMostrar = "Maquinaria";
                      String categoriaEstimada = "AccesorioSuelto";
                      
                      if (item is TractorBase) { nombreMostrar = item.nombre; categoriaEstimada = "Tractor"; }
                      if (item is MaquinaBase) { nombreMostrar = item.nombre; categoriaEstimada = "Maquina"; }
                      if (item is AccesorioSuelto) { nombreMostrar = item.nombre; categoriaEstimada = "AccesorioSuelto"; }
                      
                      if (item.runtimeType.toString().contains('Decorator') || item.runtimeType.toString().startsWith('Con')) {
                        nombreMostrar = "Equipo Configurado";
                        if (item.runtimeType.toString().contains('Tractor') || item.runtimeType.toString().startsWith('ConRemolque') || item.runtimeType.toString().startsWith('ConGps')) {
                          categoriaEstimada = "Tractor";
                        } else {
                          categoriaEstimada = "Maquina";
                        }
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(nombreMostrar, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text('${item.getDias()} días • Total: ${item.calcularPrecio().toStringAsFixed(2)}€'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Botón para editar elemento del carrito
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                onPressed: () {       
                                  final mockItem = {
                                    'id': _obtenerIdReal(item), // Mantenemos su ID real
                                    'nombre': nombreMostrar,
                                    'categoria': categoriaEstimada,
                                    'precio_base_dia': 100.0 
                                  };
                                  
                                  for (var back in _articulosBack) {
                                    if (_obtenerIdReal(item) == back['id']) {
                                      mockItem['precio_base_dia'] = back['precio_base_dia'];
                                      mockItem['nombre'] = back['nombre'];
                                    }
                                  }
                                  _configurarProducto(mockItem, itemAEliminar: item);
                                },
                              ),
                              // Botón para eliminar elemento del carrito
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                onPressed: () {
                                  setState(() { _carrito.removeElemento(item); });
                                  setModalState(() {}); 
                                  if (_carrito.elementos.isEmpty) Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }

  // Función para configurar y validar, con soporte para editar
  void _configurarProducto(dynamic item, {ServicioAlquiler? itemAEliminar}) {
    final String diasIniciales = itemAEliminar != null ? itemAEliminar.getDias().toString() : "3";
    final TextEditingController diasCtrl = TextEditingController(text: diasIniciales);
    
    DateTime fechaSeleccionada = itemAEliminar != null ? itemAEliminar.getFechaInicio() : DateTime.now();

    // Extraemos los periodos ocupados del artículo para bloquear en el calendario
    final List periodosItem = item['alquiler_periodos'] ?? [];
    final List<Map<String, DateTime>> rangosOcupados = [];
    for (var p in periodosItem) {
      final inicio = DateTime.tryParse(p['fecha_inicio'] ?? '');
      final fin = DateTime.tryParse(p['fecha_fin'] ?? '');
      if (inicio != null && fin != null) {
        rangosOcupados.add({'inicio': inicio, 'fin': fin});
      }
    }

    // Función que comprueba si un día está dentro de algún rango ocupado
    bool esDiaOcupado(DateTime dia) {
      final diaLimpio = DateTime(dia.year, dia.month, dia.day);
      for (var rango in rangosOcupados) {
        final ini = DateTime(rango['inicio']!.year, rango['inicio']!.month, rango['inicio']!.day);
        final fin = DateTime(rango['fin']!.year, rango['fin']!.month, rango['fin']!.day);
        if (!diaLimpio.isBefore(ini) && !diaLimpio.isAfter(fin)) {
          return true;
        }
      }
      return false;
    }

    // Función que comprueba si un rango de fechas se solapa con algún periodo ocupado
    bool rangoSeSolapa(DateTime desde, DateTime hasta) {
      for (var rango in rangosOcupados) {
        final ini = DateTime(rango['inicio']!.year, rango['inicio']!.month, rango['inicio']!.day);
        final fin = DateTime(rango['fin']!.year, rango['fin']!.month, rango['fin']!.day);
        // Hay solapamiento si: desde <= fin && hasta >= ini
        if (!desde.isAfter(fin) && !hasta.isBefore(ini)) {
          return true;
        }
      }
      return false;
    }

    bool extra1 = false; 
    bool extra2 = false; 
    
    if (itemAEliminar != null) {
      String claseStr = itemAEliminar.runtimeType.toString();
      if (claseStr.contains('ConRemolque') || claseStr.contains('ConSeguroPremium')) extra1 = true;
      if (claseStr.contains('ConGpsAgricola') || claseStr.contains('ConOperario')) extra2 = true;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(itemAEliminar != null ? 'Modificar Alquiler' : 'Alquilar ${item['nombre']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Precio base: ${item['precio_base_dia']}€/día', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 15),
                
                TextField(
                  controller: diasCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Días de alquiler personalizados',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_view_day),
                  ),
                ),
                const SizedBox(height: 15),

                Card(
                  color: Colors.grey[100],
                  child: ListTile(
                    leading: const Icon(Icons.date_range, color: Colors.green),
                    title: const Text('Fecha de inicio:', style: TextStyle(fontSize: 14)),
                    subtitle: Text(
                      "${fechaSeleccionada.day}/${fechaSeleccionada.month}/${fechaSeleccionada.year}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    trailing: ElevatedButton(
                      onPressed: () async {
                        // Buscamos una fecha inicial que no esté bloqueada y que no sea en el pasado
                        final hoyStr = DateTime.now();
                        final hoyNormalizado = DateTime(hoyStr.year, hoyStr.month, hoyStr.day);
                        
                        DateTime fechaInicialCalendario = fechaSeleccionada;
                        if (fechaInicialCalendario.isBefore(hoyNormalizado)) {
                          fechaInicialCalendario = hoyNormalizado;
                        }
                        
                        if (esDiaOcupado(fechaInicialCalendario)) {
                          // Si la fecha actual está ocupada, buscamos la siguiente libre
                          for (int i = 0; i < 365; i++) {
                            final candidata = hoyNormalizado.add(Duration(days: i));
                            if (!esDiaOcupado(candidata)) {
                              fechaInicialCalendario = candidata;
                              break;
                            }
                          }
                        }
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: fechaInicialCalendario,
                          firstDate: hoyNormalizado, 
                          lastDate: hoyNormalizado.add(const Duration(days: 365)),
                          // Bloqueamos las fechas ocupadas en el calendario
                          selectableDayPredicate: (DateTime dia) {
                            return !esDiaOcupado(dia);
                          },
                          helpText: 'Las fechas en gris están ocupadas',
                        );
                        if (picked != null && picked != fechaSeleccionada) {
                          setDialogState(() { fechaSeleccionada = picked; });
                        }
                      },
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10)),
                      child: const Text('Cambiar'),
                    ),
                  ),
                ),
                if (rangosOcupados.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 15, color: Colors.orange[700]),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Las fechas en gris del calendario están ocupadas y no se pueden seleccionar.',
                            style: TextStyle(fontSize: 11, color: Colors.orange[700], fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const Divider(height: 25),
                const Text('¿Añadir extras?', style: TextStyle(fontWeight: FontWeight.bold)),
                if (item['categoria'] == 'Tractor') ...[
                  CheckboxListTile(
                    title: const Text('Remolque (+40€/día)'),
                    value: extra1,
                    onChanged: (v) => setDialogState(() { extra1 = v!; }),
                  ),
                  CheckboxListTile(
                    title: const Text('GPS Agrícola (+15€/día)'),
                    value: extra2,
                    onChanged: (v) => setDialogState(() { extra2 = v!; }),
                  ),
                ],
                if (item['categoria'] == 'Maquina') ...[
                  CheckboxListTile(
                    title: const Text('Seguro Premium (+25€/día)'),
                    value: extra1,
                    onChanged: (v) => setDialogState(() { extra1 = v!; }),
                  ),
                  CheckboxListTile(
                    title: const Text('Operario Profesional (+100€/día)'),
                    value: extra2,
                    onChanged: (v) => setDialogState(() { extra2 = v!; }),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                int? diasInput = int.tryParse(diasCtrl.text);
                
                if (diasInput == null || diasInput <= 0 || diasInput > 365) {
                  _mostrarSnack('Valida los días ingresados (1-365).', Colors.red);
                  return;
                }

                // Validamos que el rango completo (fecha inicio + días) no se solape
                final fechaFin = fechaSeleccionada.add(Duration(days: diasInput - 1));
                if (rangoSeSolapa(fechaSeleccionada, fechaFin)) {
                  _mostrarSnack('⚠️ El rango de fechas seleccionado se solapa con un periodo ya ocupado.', Colors.red);
                  return;
                }

                double precioBase = double.parse(item['precio_base_dia'].toString());
                ServicioAlquiler objetoFinal;

                if (item['categoria'] == 'Tractor') {
                  ITractor tractor = TractorBase(
                    id: item['id'], nombre: item['nombre'], precioBaseDia: precioBase, fechaInicio: fechaSeleccionada, dias: diasInput
                  );
                  if (extra1) tractor = ConRemolque(tractor);
                  if (extra2) tractor = ConGpsAgricola(tractor);
                  objetoFinal = tractor;
                } else if (item['categoria'] == 'Maquina') {
                  IMaquina maquina = MaquinaBase(
                    id: item['id'], nombre: item['nombre'], precioBaseDia: precioBase, fechaInicio: fechaSeleccionada, dias: diasInput
                  );
                  if (extra1) maquina = ConSeguroPremium(maquina);
                  if (extra2) maquina = ConOperario(maquina);
                  objetoFinal = maquina;
                } else {
                  objetoFinal = AccesorioSuelto(
                    id: item['id'], nombre: item['nombre'], precioBaseDia: precioBase, fechaInicio: fechaSeleccionada, dias: diasInput
                  );
                }

                setState(() { 
                  if (itemAEliminar != null) {
                    _carrito.removeElemento(itemAEliminar);
                  }
                  _carrito.addElemento(objetoFinal); 
                });
                
                Navigator.pop(context);
                _mostrarSnack(itemAEliminar != null ? '¡Alquiler modificado con éxito!' : '¡Añadido con éxito!', Colors.green);
              },
              child: Text(itemAEliminar != null ? 'Guardar Cambios' : 'Añadir al Carrito'),
            )
          ],
        ),
      ),
    );
  }

  void _mostrarSnack(String m, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: c));
  }

  // Widget que construye la pestaña "Mis Alquileres"
  Widget _buildHistorialTab() {
    if (_cargandoHistorial) return const Center(child: CircularProgressIndicator());
    if (_misAlquileres.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('Aún no tienes alquileres registrados.', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }
    final hoy = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return RefreshIndicator(
      onRefresh: _cargarMisAlquileres,
      child: ListView.builder(
        itemCount: _misAlquileres.length,
        itemBuilder: (context, index) {
          final contrato = _misAlquileres[index];
          final articulo = contrato['articulo'] ?? {'nombre': 'Equipo eliminado', 'categoria': '-'};
          final fechaIn = DateTime.tryParse(contrato['fecha_inicio'] ?? '');
          final esFuturo = fechaIn != null && fechaIn.isAfter(hoy);
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: Icon(
                esFuturo ? Icons.upcoming_rounded : Icons.history,
                color: esFuturo ? Colors.green : Colors.grey,
                size: 36,
              ),
              title: Text(articulo['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${articulo['categoria']}'),
                  Text('Del ${contrato['fecha_inicio']} al ${contrato['fecha_fin']}'),
                ],
              ),
              isThreeLine: true,
              trailing: esFuturo
                  ? ElevatedButton.icon(
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text('Cancelar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      onPressed: () => _confirmarCancelacion(contrato['id']),
                    )
                  : Chip(
                      label: Text(fechaIn != null && fechaIn.isAfter(hoy.subtract(const Duration(days:1))) ? 'En curso' : 'Pasado'),
                      backgroundColor: Colors.grey[200],
                      labelStyle: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Tienda Alquiler'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, size: 28),
                onPressed: _verCarritoDetallado,
              ),
              if (_carrito.elementos.isNotEmpty)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${_carrito.elementos.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()))
          )
        ],
        bottom: const TabBar(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amber,
          tabs: [
            Tab(icon: Icon(Icons.store), text: 'Catálogo'),
            Tab(icon: Icon(Icons.history), text: 'Mis Alquileres'),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          // PESTAÑA 1: Catálogo original
          _cargando
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(
                      flex: 3,
                      child: ListView.builder(
                        itemCount: _articulosBack.length,
                        itemBuilder: (context, idx) {
                          final item = _articulosBack[idx];
                          final List periodos = item['alquiler_periodos'] ?? [];
                          final hoy = DateTime.now();
                          final periodosActivos = periodos.where((p) {
                            final fechaFin = DateTime.tryParse(p['fecha_fin'] ?? '');
                            return fechaFin != null && fechaFin.isAfter(hoy.subtract(const Duration(days: 1)));
                          }).toList();
                          final bool tieneOcupacion = periodosActivos.isNotEmpty;

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: tieneOcupacion
                                  ? const BorderSide(color: Colors.orange, width: 1.5)
                                  : BorderSide.none,
                            ),
                            child: ExpansionTile(
                              leading: Icon(
                                tieneOcupacion ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                                color: tieneOcupacion ? Colors.orange : Colors.green,
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(item['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                  if (tieneOcupacion)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.red.shade300),
                                      ),
                                      child: Text(
                                        'Ocupado (${periodosActivos.length})',
                                        style: TextStyle(color: Colors.red[700], fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Text('${item['categoria']} • ${item['precio_base_dia']}€/día'),
                              trailing: ElevatedButton(
                                onPressed: () => _configurarProducto(item),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                child: const Text('Configurar'),
                              ),
                              children: [
                                if (periodosActivos.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: Row(
                                      children: [
                                        Icon(Icons.event_available, color: Colors.green, size: 20),
                                        SizedBox(width: 8),
                                        Text('✅ Disponible en todas las fechas',
                                            style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  )
                                else
                                  ..._construirPeriodosOcupados(periodosActivos),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Artículos en carrito: ${_carrito.elementos.length}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              DropdownButton<String>(
                                value: _carrito.estrategia is EnvioEstandar ? 'Estandar' : (_carrito.estrategia is EnvioUrgente ? 'Urgente' : 'Recogida'),
                                items: const [
                                  DropdownMenuItem(value: 'Estandar', child: Text('Envío Estándar')),
                                  DropdownMenuItem(value: 'Urgente', child: Text('Envío Urgente 24h')),
                                  DropdownMenuItem(value: 'Recogida', child: Text('Recogida en Tienda')),
                                ],
                                onChanged: (val) {
                                  setState(() {
                                    if (val == 'Estandar') _carrito.estrategia = EnvioEstandar();
                                    if (val == 'Urgente') _carrito.estrategia = EnvioUrgente();
                                    if (val == 'Recogida') _carrito.estrategia = RecogidaEnTienda();
                                  });
                                },
                              )
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal Alquiler:'), Text('${_carrito.calcularPrecio().toStringAsFixed(2)}€')]),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Gastos de Gestión/Envío:'), Text('${_carrito.getCosteEnvio().toStringAsFixed(2)}€')]),
                          const Divider(),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('TOTAL:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text('${_carrito.getGranTotal().toStringAsFixed(2)}€', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green))]),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _checkoutFinal,
                            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(45), backgroundColor: Colors.green[700], foregroundColor: Colors.white),
                            child: const Text('Confirmar Alquiler', style: TextStyle(fontSize: 16)),
                          )
                        ],
                      ),
                    )
                  ],
                ),

          // PESTAÑA 2: Historial de alquileres del cliente
          _buildHistorialTab(),
        ],
      ),
    ));
  }

  // Construye la lista de widgets con los periodos de ocupación de un artículo
  List<Widget> _construirPeriodosOcupados(List periodosActivos) {
    return [
      const Padding(
        padding: EdgeInsets.only(left: 16, top: 8, bottom: 4),
        child: Row(
          children: [
            Icon(Icons.block, color: Colors.red, size: 18),
            SizedBox(width: 6),
            Text('Fechas no disponibles:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 13)),
          ],
        ),
      ),
      ...periodosActivos.map((p) {
        final inicio = DateTime.tryParse(p['fecha_inicio'] ?? '');
        final fin = DateTime.tryParse(p['fecha_fin'] ?? '');
        final inicioStr = inicio != null
            ? '${inicio.day.toString().padLeft(2, '0')}/${inicio.month.toString().padLeft(2, '0')}/${inicio.year}'
            : '?';
        final finStr = fin != null
            ? '${fin.day.toString().padLeft(2, '0')}/${fin.month.toString().padLeft(2, '0')}/${fin.year}'
            : '?';
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Icon(Icons.date_range, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                '$inicioStr  →  $finStr',
                style: TextStyle(fontSize: 13, color: Colors.grey[800]),
              ),
            ],
          ),
        );
      }),
      const SizedBox(height: 8),
    ];
  }

  int _obtenerIdReal(ServicioAlquiler item) {
    if (item is TractorBase) return item.id;
    if (item is MaquinaBase) return item.id;
    if (item is AccesorioSuelto) return item.id;
    if (item is TractorDecorator) return _obtenerIdReal(item.tractorEnvuelto);
    if (item is MaquinaDecorator) return _obtenerIdReal(item.maquinaEnvuelta);
    return _articulosBack.first['id']; 
  }
}

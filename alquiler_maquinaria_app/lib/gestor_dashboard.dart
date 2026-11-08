import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';

class GestorDashboard extends StatefulWidget {
  const GestorDashboard({super.key});

  @override
  State<GestorDashboard> createState() => _GestorDashboardState();
}

class _GestorDashboardState extends State<GestorDashboard> {
  List<dynamic> _articulos = [];
  List<dynamic> _alquileres = []; // lista para las reservas activas
  bool _cargandoArticulos = false;
  bool _cargandoAlquileres = false;
  
  final String _tokenGestor = "Token gestor-secret-key";

  @override
  void initState() {
    super.initState();
    _cargarArticulos();
    _cargarAlquileres(); // Cargamos los alquileres
  }

  // GET /articulos
  Future<void> _cargarArticulos() async {
    setState(() { _cargandoArticulos = true; });
    final url = Uri.parse('http://localhost:3000/articulos');
    try {
      final respuesta = await http.get(url);
      if (respuesta.statusCode == 200) {
        setState(() { _articulos = jsonDecode(respuesta.body); });
      }
    } catch (e) {
      _mostrarMensaje('Error al cargar catálogo', Colors.red);
    } finally {
      setState(() { _cargandoArticulos = false; });
    }
  }

  // GET /reservas
  Future<void> _cargarAlquileres() async {
    setState(() { _cargandoAlquileres = true; });
    final url = Uri.parse('http://localhost:3000/reservas');
    try {
      final respuesta = await http.get(url);
      if (respuesta.statusCode == 200) {
        setState(() { _alquileres = jsonDecode(respuesta.body); });
      }
    } catch (e) {
      _mostrarMensaje('Error al cargar historial de reservas', Colors.red);
    } finally {
      setState(() { _cargandoAlquileres = false; });
    }
  }

  // POST /articulos
  Future<void> _crearArticulo(String nombre, String categoria, double precio) async {
    final url = Uri.parse('http://localhost:3000/articulos');
    try {
      final respuesta = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'Authorization': _tokenGestor},
        body: jsonEncode({
          'articulo': {'nombre': nombre, 'categoria': categoria, 'precio_base_dia': precio}
        }),
      );
      if (respuesta.statusCode == 201) {
        _mostrarMensaje('¡Artículo creado con éxito!', Colors.green);
        _cargarArticulos();
      }
    } catch (e) {
      _mostrarMensaje('Error de red', Colors.red);
    }
  }

  // PATCH /articulos/:id
  Future<void> _editarArticulo(int id, String nombre, String categoria, double precio) async {
    final url = Uri.parse('http://localhost:3000/articulos/$id');
    try {
      final respuesta = await http.patch(
        url,
        headers: {'Content-Type': 'application/json', 'Authorization': _tokenGestor},
        body: jsonEncode({
          'articulo': {'nombre': nombre, 'categoria': categoria, 'precio_base_dia': precio}
        }),
      );
      if (respuesta.statusCode == 200) {
        _mostrarMensaje('¡Artículo actualizado!', Colors.green);
        _cargarArticulos();
      }
    } catch (e) {
      _mostrarMensaje('Error de red', Colors.red);
    }
  }

  // DELETE /articulos/:id
  Future<void> _borrarArticulo(int id) async {
    final url = Uri.parse('http://localhost:3000/articulos/$id');
    try {
      final respuesta = await http.delete(url, headers: {'Authorization': _tokenGestor});
      if (respuesta.statusCode == 200) {
        _mostrarMensaje('Artículo eliminado', Colors.orange);
        _cargarArticulos();
      }
    } catch (e) {
      _mostrarMensaje('Error de red', Colors.red);
    }
  }

  void _mostrarMensaje(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje), backgroundColor: color));
  }

  void _abrirFormularioCrear() {
    final nombreCtrl = TextEditingController();
    final precioCtrl = TextEditingController();
    String categoriaSeleccionada = 'Tractor';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nuevo Servicio Alquiler'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
              TextField(controller: precioCtrl, decoration: const InputDecoration(labelText: 'Precio por día (€)'), keyboardType: TextInputType.number),
              const SizedBox(height: 15),
              DropdownButton<String>(
                value: categoriaSeleccionada,
                isExpanded: true,
                items: ['Tractor', 'Maquina', 'AccesorioSuelto'].map((String value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                onChanged: (val) => setDialogState(() { categoriaSeleccionada = val!; }),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (nombreCtrl.text.isNotEmpty && precioCtrl.text.isNotEmpty) {
                  _crearArticulo(nombreCtrl.text, categoriaSeleccionada, double.parse(precioCtrl.text));
                  Navigator.pop(context);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _abrirFormularioEditar(dynamic articulo) {
    final nombreCtrl = TextEditingController(text: articulo['nombre']);
    final precioCtrl = TextEditingController(text: articulo['precio_base_dia'].toString());
    String categoriaSeleccionada = articulo['categoria'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Editar ${articulo['nombre']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
              TextField(controller: precioCtrl, decoration: const InputDecoration(labelText: 'Precio por día (€)'), keyboardType: TextInputType.number),
              const SizedBox(height: 15),
              DropdownButton<String>(
                value: categoriaSeleccionada,
                isExpanded: true,
                items: ['Tractor', 'Maquina', 'AccesorioSuelto'].map((String value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                onChanged: (val) => setDialogState(() { categoriaSeleccionada = val!; }),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (nombreCtrl.text.isNotEmpty && precioCtrl.text.isNotEmpty) {
                  _editarArticulo(articulo['id'], nombreCtrl.text, categoriaSeleccionada, double.parse(precioCtrl.text));
                  Navigator.pop(context);
                }
              },
              child: const Text('Actualizar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Tres pestañas: Catálogo, Reservas Activas e Historial
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel de Gestión (Admin)'),
          backgroundColor: Colors.blueGrey,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _cargarArticulos();
                _cargarAlquileres();
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
            )
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.amber,
            tabs: [
              Tab(icon: Icon(Icons.inventory), text: 'Catálogo Stock'),
              Tab(icon: Icon(Icons.assignment), text: 'Alquileres Activos'),
              Tab(icon: Icon(Icons.history), text: 'Histórico de alquileres'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // PESTAÑA 1: CRUD del catálogo
            _cargandoArticulos
                ? const Center(child: CircularProgressIndicator())
                : _articulos.isEmpty
                    ? const Center(child: Text('No hay maquinaria.'))
                    : ListView.builder(
                        itemCount: _articulos.length,
                        itemBuilder: (context, index) {
                          final item = _articulos[index];
                          IconData icono = Icons.construction;
                          if (item['categoria'] == 'Tractor') icono = Icons.agriculture;
                          if (item['categoria'] == 'AccesorioSuelto') icono = Icons.build_circle;

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              leading: Icon(icono, color: Colors.blueGrey, size: 36),
                              title: Text(item['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${item['categoria']} • ${item['precio_base_dia']}€/día'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _abrirFormularioEditar(item)),
                                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _borrarArticulo(item['id'])),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

            // PESTAÑA 2: listado de reservas activas
            _construirListaAlquileres(soloActivos: true),

            // PESTAÑA 3: Historial de alquileres
            _construirListaAlquileres(soloActivos: false),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton(
              onPressed: _abrirFormularioCrear,
              backgroundColor: Colors.blueGrey,
              child: const Icon(Icons.add, color: Colors.white),
            );
          },
        ),
      ),
    );
  }

  Widget _construirListaAlquileres({required bool soloActivos}) {
    if (_cargandoAlquileres) {
      return const Center(child: CircularProgressIndicator());
    }

    final hoy = DateTime.now();
    final listaMostrar = soloActivos 
        ? _alquileres.where((contrato) {
            final fechaFin = DateTime.tryParse(contrato['fecha_fin'] ?? '');
            return fechaFin != null && fechaFin.isAfter(hoy.subtract(const Duration(days: 1)));
          }).toList()
        : _alquileres;

    if (listaMostrar.isEmpty) {
      return Center(
        child: Text(soloActivos 
            ? 'No hay alquileres activos en este momento.' 
            : 'No hay ningún alquiler registrado en el sistema.')
      );
    }

    return ListView.builder(
      itemCount: listaMostrar.length,
      itemBuilder: (context, index) {
        final contrato = listaMostrar[index];
        final articulo = contrato['articulo'] ?? {'nombre': 'Equipo Eliminado', 'categoria': 'Desconocido'};
        
        // Formateo de fechas
        String fechaIn = contrato['fecha_inicio'] ?? '';
        String fechaFin = contrato['fecha_fin'] ?? '';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: soloActivos ? Colors.amber[50] : Colors.grey[100],
          child: ListTile(
            leading: Icon(
              soloActivos ? Icons.assignment_turned_in : Icons.history, 
              color: soloActivos ? Colors.orange : Colors.grey, 
              size: 36
            ),
            title: Text(articulo['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Categoría: ${articulo['categoria']}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Desde: $fechaIn', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                Text('Hasta: $fechaFin', style: TextStyle(fontSize: 12, color: soloActivos ? Colors.red : Colors.black54, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }
}

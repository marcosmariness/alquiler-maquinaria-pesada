import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'gestor_dashboard.dart';
import 'cliente_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controladores para capturar lo que escribe el usuario
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _cargando = false;

  // Conectar con Ruby on Rails
  Future<void> _iniciarSesion() async {
    setState(() { _cargando = true; });

    // Configura la URL de tu backend local de Rails
    final url = Uri.parse('http://localhost:3000/login');

    try {
      final respuesta = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );

      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(respuesta.body);
        final String rol = datos['rol'];

        if (!mounted) return;

        if (rol == 'administrador') {
          // Redirigir a la pantalla del Gestor
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Bienvenido Gestor!')),
          );
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const GestorDashboard()));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('¡Bienvenido Cliente! Compras activadas.')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ClienteDashboard(email: datos['email'] ?? ''),
            ),
          );
        }
      } else {
        final errorDatos = jsonDecode(respuesta.body);
        _mostrarError(errorDatos['error'] ?? 'Error al iniciar sesión');
      }
    } catch (e) {
      _mostrarError('No se pudo conectar con el servidor de Rails. ¿Está encendido?');
    } finally {
      setState(() { _cargando = false; });
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alquiler de Maquinaria')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.agriculture, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            Text('Identifícate', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Correo Electrónico', border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder()),
              obscureText: true,
            ),
            const SizedBox(height: 25),
            _cargando
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _iniciarSesion,
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: Colors.green, foregroundColor: Colors.white),
                    child: const Text('Entrar', style: TextStyle(fontSize: 18)),
                  ),
          ],
        ),
      ),
    );
  }
}

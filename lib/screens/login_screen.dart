import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final String? errorExterno;
  const LoginScreen({super.key, this.errorExterno});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _nombre = TextEditingController();
  bool _crear = false;
  bool _cargando = false;
  String? _error;

  @override
  void dispose() { _email.dispose(); _password.dispose(); _nombre.dispose(); super.dispose(); }

  Future<void> _enviar() async {
    if (_email.text.trim().isEmpty || _password.text.length < 6 || (_crear && _nombre.text.trim().isEmpty)) {
      setState(() => _error = 'Completá los datos. La contraseña debe tener al menos 6 caracteres.');
      return;
    }
    setState(() { _cargando = true; _error = null; });
    try {
      if (_crear) {
        await authService.crearCuenta(email: _email.text, password: _password.text, nombre: _nombre.text);
        if (mounted) setState(() => _error = 'Cuenta creada. Si Supabase solicita confirmación, revisá tu correo y luego iniciá sesión.');
      } else {
        await authService.iniciarSesion(_email.text, _password.text);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Icon(Icons.warehouse, size: 58, color: Color(0xFF1E3A8A)),
                const SizedBox(height: 10),
                const Text('TRICON WMS', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const Text('Acceso seguro al sistema', textAlign: TextAlign.center),
                const SizedBox(height: 26),
                if (_crear) TextField(controller: _nombre, decoration: const InputDecoration(labelText: 'Nombre completo', border: OutlineInputBorder())),
                if (_crear) const SizedBox(height: 12),
                TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Correo', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: _password, obscureText: true, onSubmitted: (_) => _enviar(), decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder())),
                if ((_error ?? widget.errorExterno) != null) ...[
                  const SizedBox(height: 12),
                  Text(_error ?? widget.errorExterno!, style: TextStyle(color: _error?.startsWith('Cuenta creada') == true ? Colors.green : Colors.red)),
                ],
                const SizedBox(height: 18),
                FilledButton.icon(onPressed: _cargando ? null : _enviar, icon: _cargando ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(_crear ? Icons.person_add : Icons.login), label: Text(_crear ? 'Crear cuenta' : 'Ingresar')),
                TextButton(onPressed: _cargando ? null : () => setState(() { _crear = !_crear; _error = null; }), child: Text(_crear ? 'Ya tengo cuenta' : 'Crear primera cuenta o aceptar invitación')),
                if (_crear) const Text('La primera cuenta se convierte en Owner. Las siguientes requieren una invitación previa.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.black54)),
              ]),
            ),
          ),
        ),
      ),
    ),
  );
}

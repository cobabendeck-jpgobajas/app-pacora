import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../services/api_client.dart';

/// Ajustes minimos de la version MVP: la URL del backend. El Plan de
/// Ejecucion (seccion 8, riesgos) aun no define si el backend correra en
/// un servidor local de la planta o en la nube, asi que esto no puede
/// quedar fijo en el codigo -- el encargado de TI de la planta debe
/// poder apuntar la app al servidor correcto sin recompilarla.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlCtrl = TextEditingController();
  bool _cargando = true;
  bool _probando = false;
  String? _resultadoPrueba;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final url = await AppConfig.getBaseUrl();
    _urlCtrl.text = url;
    setState(() => _cargando = false);
  }

  Future<void> _guardar() async {
    await AppConfig.setBaseUrl(_urlCtrl.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dirección del servidor guardada.')),
    );
  }

  Future<void> _probarConexion() async {
    await _guardar();
    setState(() {
      _probando = true;
      _resultadoPrueba = null;
    });
    final error = await ApiClient().probarConexionDetallada();
    if (!mounted) return;
    setState(() {
      _probando = false;
      _resultadoPrueba = error == null
          ? 'Conexión exitosa con el servidor.'
          : 'No se pudo conectar. Detalle técnico: $error';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Dirección del servidor (API, Fase 3)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _urlCtrl,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        hintText: 'http://192.168.1.50:8000',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _probando ? null : _probarConexion,
                            child: _probando
                                ? const SizedBox(
                                    height: 16, width: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('Probar conexión'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: _guardar,
                            child: const Text('Guardar'),
                          ),
                        ),
                      ],
                    ),
                    if (_resultadoPrueba != null) ...[
                      const SizedBox(height: 12),
                      Text(_resultadoPrueba!),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}

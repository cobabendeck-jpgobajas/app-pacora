import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/muestra.dart';
import '../services/connectivity_service.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';
import '../widgets/estado_chip.dart';
import 'capture_screen.dart';
import 'result_screen.dart';
import 'settings_screen.dart';

/// Pantalla principal: historial de muestras (predichas + en cola) y el
/// boton para capturar una nueva. Sincroniza la cola offline
/// automaticamente en cuanto detecta que volvio la conexion, y tambien
/// permite forzarlo a mano.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _connectivity = ConnectivityService();
  final _sync = SyncService();
  List<Muestra> _muestras = [];
  bool _cargando = true;
  bool _sincronizando = false;
  StreamSubscription<bool>? _conexionSub;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
    _conexionSub = _connectivity.onStatusChange.listen((hayRed) {
      if (hayRed) _sincronizar();
    });
  }

  @override
  void dispose() {
    _conexionSub?.cancel();
    super.dispose();
  }

  Future<void> _cargarHistorial() async {
    final muestras = await DatabaseService.instance.listAll();
    if (!mounted) return;
    setState(() {
      _muestras = muestras;
      _cargando = false;
    });
  }

  Future<void> _sincronizar() async {
    if (_sincronizando) return;
    setState(() => _sincronizando = true);
    final enviadas = await _sync.sincronizarPendientes(
      onProgreso: (_) => _cargarHistorial(),
    );
    await _cargarHistorial();
    if (!mounted) return;
    setState(() => _sincronizando = false);
    if (enviadas > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Se sincronizaron $enviadas muestra(s) pendiente(s).')),
      );
    }
  }

  int get _pendientesCount =>
      _muestras.where((m) => m.estado == EstadoMuestra.enCola || m.estado == EstadoMuestra.error).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dosificación — Aguas Manantiales de Pácora'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarHistorial,
        child: Column(
          children: [
            if (_pendientesCount > 0) _buildBannerCola(),
            Expanded(child: _buildLista()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CaptureScreen()),
          );
          _cargarHistorial();
        },
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Nueva muestra'),
      ),
    );
  }

  Widget _buildBannerCola() {
    return Container(
      width: double.infinity,
      color: Colors.orange.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text('$_pendientesCount muestra(s) esperando conexión'),
          ),
          TextButton(
            onPressed: _sincronizando ? null : _sincronizar,
            child: _sincronizando
                ? const SizedBox(
                    height: 14, width: 14,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Sincronizar ahora'),
          ),
        ],
      ),
    );
  }

  Widget _buildLista() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_muestras.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Todavía no hay muestras. Toca "Nueva muestra" para capturar la primera.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 90),
      itemCount: _muestras.length,
      itemBuilder: (context, i) {
        final m = _muestras[i];
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(m.imagePath),
              width: 52, height: 52, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
            ),
          ),
          title: Text(
            m.dosisPredichaMgL != null
                ? '${m.dosisPredichaMgL!.toStringAsFixed(0)} mg/L'
                : 'Sin predicción aún',
          ),
          subtitle: Text(DateFormat('d MMM y, HH:mm', 'es').format(m.creadoEn)),
          trailing: EstadoChip(estado: m.estado),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ResultScreen(muestra: m)),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  runApp(const AppPacora());
}

/// App movil (version minima viable, Fase 4 del Plan de Ejecucion):
/// captura guiada de la foto de la muestra de agua, prediccion de la
/// dosis de sulfato de aluminio via la API de la Fase 3, y cola offline
/// para cuando no hay señal en la planta.
class AppPacora extends StatelessWidget {
  const AppPacora({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dosificación Pácora',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

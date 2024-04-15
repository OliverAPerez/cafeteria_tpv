import 'package:cafeteria_tpv/firebase_options.dart';
import 'package:cafeteria_tpv/pages/side_bar.dart';
import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Crea una Future para Firebase.initializeApp()

    return MaterialApp(
      title: 'Cafetería TPV',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FutureBuilder(
        future: _initialization,
        builder: (context, snapshot) {
          // Comprueba si Firebase ha terminado de inicializarse. Si no, muestra un indicador de carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          // Si Firebase ha terminado de inicializarse, muestra la aplicación
          return const MainPage();
        },
      ),
    );
  }
}

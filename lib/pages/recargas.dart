import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Recargas extends StatefulWidget {
  const Recargas({super.key});

  @override
  _RecargasState createState() => _RecargasState();
}

class _RecargasState extends State<Recargas> {
  late TextEditingController _searchController;
  late Stream<QuerySnapshot> _usersStream;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    // Verificar si Firebase ya está inicializado antes de acceder a Firestore
    if (Firebase.apps.isEmpty) {
      // Si Firebase no está inicializado, inicializarlo antes de acceder a Firestore
      Firebase.initializeApp().then((_) {
        _usersStream = FirebaseFirestore.instance.collection('Users').snapshots();
      }).catchError((error) {
        // Manejar el error si la inicialización de Firebase falla
        print("Error durante la inicialización de Firebase: $error");
      });
    } else {
      // Si Firebase ya está inicializado, acceder directamente a Firestore
      _usersStream = FirebaseFirestore.instance.collection('Users').snapshots();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildUserCard(DocumentSnapshot user) {
    final formatCurrency = NumberFormat.simpleCurrency(); // Para formatear el saldo

    return LayoutBuilder(
      builder: (context, constraints) {
        return Card(
          elevation: 3, // Reduce este número para menos sombra
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), // Reduce este número para esquinas menos redondeadas
          ),
          child: Padding(
            padding: const EdgeInsets.all(10), // Reduce este número para menos relleno dentro de la tarjeta
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                CircleAvatar(
                  radius: constraints.maxWidth * 0.1, // Ajusta el radio del avatar en función del ancho de la pantalla
                  backgroundImage: user['image'] != null && user['image'].isNotEmpty ? NetworkImage(user['image']) : null,
                  child: user['image'] != null && user['image'].isNotEmpty ? null : const Icon(Icons.person, size: 40),
                ),
                const SizedBox(height: 10),
                Text(
                  user['nombre'] ?? 'Nombre no disponible',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  user['email'] ?? 'Email no disponible',
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Saldo:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user['saldo'] != null ? formatCurrency.format(user['saldo']) : 'Saldo no disponible',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recargas'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar usuario',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _usersStream = FirebaseFirestore.instance.collection('Users').where('nombre', isGreaterThanOrEqualTo: value).where('nombre', isLessThan: '${value}z').snapshots();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _usersStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final users = snapshot.data!.docs;
                if (users.isEmpty) {
                  return const Center(child: Text('No se encontraron usuarios'));
                }
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5, // Aumenta este número para más tarjetas en una fila
                    crossAxisSpacing: 4, // Reduce este número para menos espacio entre tarjetas
                    mainAxisSpacing: 4, // Reduce este número para menos espacio entre tarjetas
                  ),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    return _buildUserCard(users[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

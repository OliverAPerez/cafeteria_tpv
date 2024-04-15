import 'package:cafeteria_tpv/widgets/menu/menu_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  final String? category;

  const HomePage({super.key, this.category});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? selectedCategory;
  double totalCuenta = 0.0;
  final List<String> categories = ['Cafe', 'Bebidas', 'Bocadillos', 'Snacks', 'Bolleria'];

  @override
  void initState() {
    super.initState();

    selectedCategory = widget.category ?? categories.first;

    // Verificar si Firebase ya está inicializado antes de acceder a Firestore
    if (Firebase.apps.isEmpty) {
      // Si Firebase no está inicializado, inicializarlo antes de acceder a Firestore
      Firebase.initializeApp().then((_) {
        setState(() {
          // Aquí puedes realizar cualquier acción que dependa de Firebase
          // Por ejemplo, aquí puedes cargar los datos de Firestore
        });
      }).catchError((error) {
        // Manejar el error si la inicialización de Firebase falla
        print("Error durante la inicialización de Firebase: $error");
      });
    } else {
      // Si Firebase ya está inicializado, puedes realizar cualquier acción que dependa de Firebase
      // Por ejemplo, aquí puedes cargar los datos de Firestore
    }
  }

  Future<List<DocumentSnapshot>> getItems(String category) async {
    var snapshot = await FirebaseFirestore.instance.collection('Productos').doc('tipos').collection(category).get();
    return snapshot.docs;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 14,
          child: Column(
            children: [
              _topMenu(
                title: 'Cafetería EPM',
                subTitle: '14 Abril 2024',
                action: _search(),
              ),
              Container(
                height: 50,
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedCategory == categories[index] ? const Color.fromRGBO(4, 94, 59, 0.733) : Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 1,
                        ),
                        onPressed: () {
                          setState(() {
                            selectedCategory = categories[index];
                          });
                        },
                        child: Text(
                          categories[index],
                          style: TextStyle(
                            color: selectedCategory == categories[index] ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Sección del grid de ítems
              Expanded(
                child: FutureBuilder<List<DocumentSnapshot>>(
                  future: getItems(selectedCategory!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: GridView.builder(
                          physics: const ScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            childAspectRatio: 6 / 9,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: snapshot.data!.length,
                          itemBuilder: (BuildContext context, int index) {
                            final itemData = snapshot.data![index].data() as Map<String, dynamic>;
                            return MenuItem(
                              name: itemData['nombre'] ?? 'Nombre no disponible',
                              price: (itemData['precio'] as num?)?.toDouble() ?? 0.0,
                              imageUrl: itemData['image'] as String?,
                              stock: itemData['stock'] as int? ?? 0,
                              isFavorite: itemData['isFavorite'] as bool? ?? false,
                              toggleFavorite: () {
                                final user = FirebaseAuth.instance.currentUser;
                                if (user != null) {
                                  FirebaseFirestore.instance
                                      .collection('Users')
                                      .doc(user.uid)
                                      .collection('favoritos')
                                      .add({
                                        'nombre': itemData['nombre'],
                                        'precio': itemData['precio'],
                                        'image': itemData['image'],
                                        'stock': itemData['stock'],
                                        'isFavorite': true,
                                      })
                                      .then((value) => Fluttertoast.showToast(msg: 'Producto añadido a favoritos'))
                                      .catchError((error) => Fluttertoast.showToast(msg: 'Error al añadir el producto a favoritos: $error'));
                                } else {
                                  Fluttertoast.showToast(msg: 'Necesitas iniciar sesión para añadir productos a favoritos');
                                }
                              },
                              addToCart: () {
                                final user = FirebaseAuth.instance.currentUser;
                                if (user != null) {
                                  final productData = {
                                    'nombre': itemData['nombre'],
                                    'precio': itemData['precio'],
                                    'image': itemData['image'],
                                    'isFavorite': itemData['isFavorite'],
                                  };

                                  FirebaseFirestore.instance
                                      .collection('Carrito')
                                      .doc(user.uid)
                                      .collection('Productos')
                                      .add(productData)
                                      .then((value) => Fluttertoast.showToast(msg: 'Producto añadido al carrito'))
                                      .catchError((error) => Fluttertoast.showToast(msg: 'Error al añadir el producto: $error'));
                                } else {
                                  Fluttertoast.showToast(msg: 'Necesitas iniciar sesión para añadir productos al carrito');
                                }
                              },
                            );
                          },
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(flex: 1, child: Container()),
        Expanded(
          flex: 5,
          child: Column(
            children: [
              _topMenu(
                title: 'Pedidos',
                subTitle: DateFormat('dd MMMM yyyy').format(DateTime.now()), // Fecha actual
                action: Container(),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: const Color(0xff1f2029),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 30),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('Carrito').doc('cafeteriatpv').collection('Productos').snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData || snapshot.data == null) {
                              // Comprueba si snapshot.data es null
                              return const Center(child: CircularProgressIndicator());
                            } else {
                              final products = snapshot.data!.docs
                                  .map((doc) {
                                    if (doc.data() != null) {
                                      return doc.data() as Map<String, dynamic>;
                                    } else {
                                      return null;
                                    }
                                  })
                                  .where((item) => item != null)
                                  .toList();

                              totalCuenta = 0.0; // Asegúrate de restablecer totalCuenta a 0 antes de calcular el nuevo total
                              return ListView.builder(
                                itemCount: products.length,
                                itemBuilder: (context, index) {
                                  final product = products[index];
                                  final double precio = product?['precio'] as double? ?? 0.0;
                                  totalCuenta += precio;
                                  return ListTile(
                                    title: Text(product?['nombre']),
                                    subtitle: Text('Precio: $precio'),
                                  );
                                },
                              );
                            }
                          },
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.deepOrange,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            final cartRef = FirebaseFirestore.instance.collection('Carrito').doc(user.uid).collection('Productos');
                            final orderRef = FirebaseFirestore.instance.collection('Pedidos').doc('cafeteriatpv').collection('historialpedidos');

                            final cartSnapshot = await cartRef.get();
                            for (final product in cartSnapshot.docs) {
                              await orderRef.add(product.data());
                              await product.reference.delete();
                            }
                          }
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [Icon(Icons.print, size: 16), SizedBox(width: 6), Text('Imprimir recibo')],
                        ),
                      ),
                      Text(
                        'Total: $totalCuenta', // Muestra el total de la cuenta
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

//#region ITEM ORDER
  Widget _itemOrder({
    required String image,
    required String title,
    required String qty,
    required String price,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xff1f2029),
      ),
      child: Row(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: AssetImage(image),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
              ],
            ),
          ),
          Text(
            '$qty x',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

//#region ITEM ORDER
  Widget _item({
    required String image,
    required String title,
    required String price,
    required String item,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 20, bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xff1f2029),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 130,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: AssetImage(image),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                price,
                style: const TextStyle(
                  color: Colors.deepOrange,
                  fontSize: 20,
                ),
              ),
              Text(
                item,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

// #region TOP MENU
  Widget _itemTab({required String icon, required String title, required bool isActive}) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 26),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xff1f2029),
        border: isActive ? Border.all(color: Colors.deepOrangeAccent, width: 3) : Border.all(color: const Color(0xff1f2029), width: 3),
      ),
      child: Row(
        children: [
          Image.asset(
            icon,
            width: 38,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          )
        ],
      ),
    );
  }

  double calculateTotal(List<QueryDocumentSnapshot> cartItems) {
    double total = 0.0;
    for (var item in cartItems) {
      final data = item.data();
      if (data != null && (data as Map<String, dynamic>).containsKey('precio')) {
        double itemTotal = (data)['precio'].toDouble();
        total += itemTotal;
      }
    }
    return total;
  }

  // #region pedidoItem
  Widget _pedidoItem({
    required String image,
    required String title,
    required String qty,
    required String price,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xff1f2029),
      ),
      child: Row(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: AssetImage(image),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
              ],
            ),
          ),
          Text(
            '$qty x',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

// #region TOP MENU
  Widget _topMenu({
    required String title,
    required String subTitle,
    required Widget action,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subTitle,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 10,
              ),
            ),
          ],
        ),
        Expanded(flex: 1, child: Container(width: double.infinity)),
        Expanded(flex: 5, child: action),
      ],
    );
  }

// #region SEARCH
  Widget _search() {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        width: double.infinity,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: const Color(0xff1f2029),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.search,
              color: Colors.white54,
            ),
            SizedBox(width: 10),
            Text(
              'Buscar',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            )
          ],
        ));
  }
}

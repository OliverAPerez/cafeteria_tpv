import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FirebaseLogicWidget extends StatefulWidget {
  final Widget Function(CollectionReference cartRef) builder;

  const FirebaseLogicWidget({super.key, required this.builder});

  @override
  _FirebaseLogicWidgetState createState() => _FirebaseLogicWidgetState();
}

class _FirebaseLogicWidgetState extends State<FirebaseLogicWidget> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late CollectionReference _cartRef;

  @override
  void initState() {
    super.initState();
    _initializeCart();
  }

  Future<void> _initializeCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _cartRef = _firestore.collection('Carrito').doc(user.uid).collection('Productos');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(_cartRef);
  }
}

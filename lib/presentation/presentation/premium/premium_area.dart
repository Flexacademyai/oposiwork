
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PremiumArea extends StatelessWidget {
  final Widget premiumChild;
  final Widget freeChild;

  const PremiumArea({required this.premiumChild, required this.freeChild});

  Future<bool> isPremiumUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return doc.exists && (doc.data()?['premium'] == true);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: isPremiumUser(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        return snapshot.data! ? premiumChild : freeChild;
      },
    );
  }
}

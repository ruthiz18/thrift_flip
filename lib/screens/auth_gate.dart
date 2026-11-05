import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../repositories/auction_repository.dart';
import '../repositories/photo_repository.dart';
import '../state/auction_state.dart';
import 'auction_home_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }
        // Signed in: one brain for this user, given to the home screen.
        return ChangeNotifierProvider<AuctionState>(
          create: (_) =>
              AuctionState(AuctionRepository(user.uid), PhotoRepository()),
          child: const AuctionHomeScreen(),
        );
      },
    );
  }
}
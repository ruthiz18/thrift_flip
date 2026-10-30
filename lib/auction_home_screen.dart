import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'auction.dart';
import 'auction_form_screen.dart';

class AuctionHomeScreen extends StatelessWidget {
  const AuctionHomeScreen({super.key});

  Future<void> _delete(BuildContext context, Auction auction) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this auction?'),
        content: Text(auction.title),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (sure == true) {
      await auctions().doc(auction.id).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Thrift Flip'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: auctions().orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load auctions.\n${snapshot.error}',
                    textAlign: TextAlign.center),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!.docs.map(Auction.fromDoc).toList();
          if (items.isEmpty) {
            return const Center(child: Text('No auctions yet'));
          }
          final uid = FirebaseAuth.instance.currentUser?.uid;
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) {
              final a = items[i];
              final mine = a.sellerId == uid;
              return ListTile(
                title: Text(a.title),
                subtitle: Text(a.description),
                trailing: Text('${a.currentBid}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                onTap: mine
                    ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => AuctionFormScreen(auction: a)),
                        )
                    : null,
                onLongPress: mine ? () => _delete(context, a) : null,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'New auction',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AuctionFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

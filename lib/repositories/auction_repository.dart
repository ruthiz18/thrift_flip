import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/auction.dart';

class AuctionRepository {
  AuctionRepository(this.uid);

  final String uid;

  // auctions/{auctionId}: one shared collection, every listing carries its sellerId.
  CollectionReference<Map<String, dynamic>> get _auctions =>
      FirebaseFirestore.instance.collection('auctions');

  // Bids on one listing: auctions/{auctionId}/bids
  CollectionReference<Map<String, dynamic>> bidsFor(String auctionId) =>
      _auctions.doc(auctionId).collection('bids');

  // The pipe: this seller's listings now, and again after every change.
  // Sorted here so the query needs no composite index.
  Stream<List<Auction>> watchMine() =>
      _auctions.where('sellerId', isEqualTo: uid).snapshots().map((snapshot) {
        final items = snapshot.docs.map(Auction.fromDoc).toList();
        items.sort((a, b) => (b.createdAt ?? DateTime.now())
            .compareTo(a.createdAt ?? DateTime.now()));
        return items;
      });

  Future<void> add(Auction auction) =>
      _auctions.add({...auction.toMap(), 'sellerId': uid});

  // Only title and description can change after an auction is created.
  Future<void> update(String id, Auction auction) =>
      _auctions.doc(id).update({
        'title': auction.title,
        'description': auction.description,
      });

  Future<void> delete(String id) => _auctions.doc(id).delete();

  // Sample listings for a brand new account.
  Future<void> addSamples() async {
    final endsAt = DateTime.now().add(const Duration(days: 3));
    final samples = [
      Auction(
          title: 'Vintage denim jacket',
          description: 'Lightly worn, size M',
          startingPrice: 5000,
          endsAt: endsAt),
      Auction(
          title: 'Leather ankle boots',
          description: 'Size 40, great condition',
          startingPrice: 8000,
          endsAt: endsAt),
      Auction(
          title: 'Retro sports jersey',
          description: '90s style, size L',
          startingPrice: 3000,
          endsAt: endsAt),
    ];
    final batch = FirebaseFirestore.instance.batch();
    for (final a in samples) {
      batch.set(_auctions.doc(), {...a.toMap(), 'sellerId': uid});
    }
    await batch.commit();
  }
}

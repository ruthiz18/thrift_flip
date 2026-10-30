import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Auction {
  Auction({
    this.id = '',
    required this.title,
    required this.description,
    required this.startingPrice,
    int? currentBid,
    String? sellerId,
    this.endsAt,
    this.createdAt,
  })  : currentBid = currentBid ?? startingPrice,
        sellerId = sellerId ?? '';

  final String id;
  final String title;
  final String description;
  final int startingPrice;
  final int currentBid;
  final String sellerId;
  final DateTime? endsAt;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'startingPrice': startingPrice,
        'currentBid': currentBid,
        'sellerId': FirebaseAuth.instance.currentUser!.uid,
        if (endsAt != null) 'endsAt': Timestamp.fromDate(endsAt!),
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory Auction.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Auction(
      id: doc.id,
      title: data['title'] as String,
      description: data['description'] as String,
      startingPrice: (data['startingPrice'] as num).toInt(),
      currentBid: (data['currentBid'] as num).toInt(),
      sellerId: data['sellerId'] as String,
      endsAt: (data['endsAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

// All listings, visible to every signed-in user: auctions/{auctionId}
CollectionReference<Map<String, dynamic>> auctions() =>
    FirebaseFirestore.instance.collection('auctions');

// Bids on one listing: auctions/{auctionId}/bids
CollectionReference<Map<String, dynamic>> bidsFor(String auctionId) =>
    auctions().doc(auctionId).collection('bids');

// Sample listings, written once when a new account is created
Future<void> addSampleAuctions() async {
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
    batch.set(auctions().doc(), a.toMap());
  }
  await batch.commit();
}

import 'package:cloud_firestore/cloud_firestore.dart';

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

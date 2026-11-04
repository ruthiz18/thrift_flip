import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/auction.dart';
import '../repositories/auction_repository.dart';

class AuctionState extends ChangeNotifier {
  AuctionState(this._repo) {
    // Born: open the pipe to the backend, once.
    _subscription = _repo.watchMine().listen(
      (list) {
        _auctions = list;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _loading = false;
        _error = 'Could not load your auctions.';
        notifyListeners();
      },
    );
  }

  final AuctionRepository _repo;
  StreamSubscription<List<Auction>>? _subscription;

  // The data: private, so only the brain can change it.
  List<Auction> _auctions = [];
  bool _loading = true;
  String? _error;

  // Read-only views for the screens.
  List<Auction> get auctions => _auctions;
  bool get loading => _loading;
  String? get error => _error;

  // Never saved, computed every time it is read: listings still open for bids.
  int get activeCount => _auctions
      .where((a) => a.endsAt == null || a.endsAt!.isAfter(DateTime.now()))
      .length;

  // Actions: the brain hands the job to the repository.
  Future<void> add(Auction auction) => _repo.add(auction);
  Future<void> edit(String id, Auction auction) => _repo.update(id, auction);
  Future<void> remove(Auction auction) => _repo.delete(auction.id);
  Future<void> addSamples() => _repo.addSamples();

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

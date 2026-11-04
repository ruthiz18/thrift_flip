import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/auction.dart';
import '../repositories/auction_repository.dart';

class AuctionState extends ChangeNotifier {
  AuctionState(this._repo) {
    debugPrint('Brain born for ${_repo.uid}');
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

  // What the user chose to see: 'all', 'active' or 'ended', plus a search text.
  String _filter = 'all';
  String _query = '';
  String get filter => _filter;

  void setFilter(String value) {
    _filter = value;
    notifyListeners();
  }

  void setQuery(String value) {
    _query = value.trim().toLowerCase();
    notifyListeners();
  }

  bool _isActive(Auction a) =>
      a.endsAt == null || a.endsAt!.isAfter(DateTime.now());

  // Never saved, computed every time it is read: listings still open for bids.
  int get activeCount => _auctions.where(_isActive).length;

  // The list the screens draw: the filter and the search applied to _auctions.
  List<Auction> get visible {
    var list = _auctions.where(
      (a) =>
          a.title.toLowerCase().contains(_query) ||
          a.description.toLowerCase().contains(_query),
    );
    if (_filter == 'active') list = list.where(_isActive);
    if (_filter == 'ended') list = list.where((a) => !_isActive(a));
    return list.toList();
  }

  // Actions: the brain hands the job to the repository.
  Future<void> add(Auction auction) => _repo.add(auction);
  Future<void> edit(String id, Auction auction) => _repo.update(id, auction);
  Future<void> remove(Auction auction) => _repo.delete(auction.id);
  Future<void> addSamples() => _repo.addSamples();

  @override
  void dispose() {
    debugPrint('Brain disposed: pipe closed');
    _subscription?.cancel();
    super.dispose();
  }
}

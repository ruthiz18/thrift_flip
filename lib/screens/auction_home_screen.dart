import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/auction.dart';
import '../state/auction_state.dart';
import 'auction_form_screen.dart';

class AuctionHomeScreen extends StatelessWidget {
  const AuctionHomeScreen({super.key});

  Future<void> _delete(BuildContext context, Auction auction) async {
    final state = context.read<AuctionState>(); // read BEFORE the await
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this auction?'),
        content: Text(auction.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (sure == true) {
      await state.remove(auction);
    }
  }

  // Open the form and hand it the SAME brain.
  void _openForm(BuildContext context, Auction? auction) {
    final state = context.read<AuctionState>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<AuctionState>.value(
          value: state,
          child: AuctionFormScreen(auction: auction),
        ),
      ),
    );
  }

  String _timeLeft(DateTime? endsAt) {
    if (endsAt == null) return 'Open';
    final left = endsAt.difference(DateTime.now());
    if (left.isNegative) return 'Ended';
    if (left.inDays >= 1) return '${left.inDays}d left';
    if (left.inHours >= 1) return '${left.inHours}h left';
    return '${left.inMinutes}m left';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final state = context.watch<AuctionState>();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thrift Flip',
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              user.email ?? '',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _body(context, state, user),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, null),
        icon: const Icon(Icons.add),
        label: const Text('New auction'),
      ),
    );
  }

  Widget _body(BuildContext context, AuctionState state, User user) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(state.error!, textAlign: TextAlign.center),
        ),
      );
    }
    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.auctions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: scheme.outline),
            const SizedBox(height: 12),
            Text('No auctions yet', style: text.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Tap New auction to list your first item',
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }
    final items = state.visible;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: TextField(
            onChanged: (text) => context.read<AuctionState>().setQuery(text),
            decoration: const InputDecoration(
              hintText: 'Search your listings',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              for (final f in ['all', 'active', 'ended']) ...[
                ChoiceChip(
                  label: Text(f.toUpperCase()),
                  selected: state.filter == f,
                  onSelected: (_) => context.read<AuctionState>().setFilter(f),
                ),
                const SizedBox(width: 8),
              ],
              const Spacer(),
              Text(
                '${state.activeCount} active',
                style: text.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('Nothing matches this filter.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final a = items[i];
                    final mine = a.sellerId == user.uid;
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: mine ? () => _openForm(context, a) : null,
                        onLongPress: mine ? () => _delete(context, a) : null,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: scheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  Icons.checkroom_outlined,
                                  color: scheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      a.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: text.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      a.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: text.bodySmall?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.schedule,
                                          size: 14,
                                          color: scheme.outline,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _timeLeft(a.endsAt),
                                          style: text.labelSmall?.copyWith(
                                            color: scheme.outline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Current bid',
                                    style: text.labelSmall?.copyWith(
                                      color: scheme.outline,
                                    ),
                                  ),
                                  Text(
                                    '${a.currentBid}',
                                    style: text.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: scheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

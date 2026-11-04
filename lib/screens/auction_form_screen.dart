import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/auction.dart';
import '../state/auction_state.dart';

class AuctionFormScreen extends StatefulWidget {
  const AuctionFormScreen({super.key, this.auction});

  // null = create a new auction, otherwise edit this one
  final Auction? auction;

  @override
  State<AuctionFormScreen> createState() => _AuctionFormScreenState();
}

class _AuctionFormScreenState extends State<AuctionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.auction?.title);
  late final _description =
      TextEditingController(text: widget.auction?.description);
  late final _price = TextEditingController(
      text: widget.auction?.startingPrice.toString());
  bool _busy = false;
  String? _error;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final state = context.read<AuctionState>(); // read BEFORE any await
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auction = Auction(
        title: _title.text.trim(),
        description: _description.text.trim(),
        startingPrice: int.parse(_price.text.trim()),
        endsAt: DateTime.now().add(const Duration(days: 3)),
      );
      if (widget.auction == null) {
        await state.add(auction);
      } else {
        await state.edit(widget.auction!.id, auction);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not save: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.auction != null;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Edit auction' : 'New auction')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              TextFormField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                    labelText: 'Title', prefixIcon: Icon(Icons.title)),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Enter a title' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _description,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                    labelText: 'Description', alignLabelWithHint: true),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Enter a description' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _price,
                enabled: !editing,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Starting price',
                  prefixIcon: const Icon(Icons.payments_outlined),
                  helperText:
                      editing ? 'The starting price cannot be changed' : null,
                ),
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  return n == null || n <= 0 ? 'Enter a price above 0' : null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_error!,
                      style: TextStyle(color: scheme.onErrorContainer)),
                ),
              ],
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5))
                    : Text(editing ? 'Save changes' : 'Create auction'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

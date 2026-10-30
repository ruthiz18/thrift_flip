import 'package:flutter/material.dart';

import 'auction.dart';

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
        await auctions().add(auction.toMap());
      } else {
        await auctions().doc(widget.auction!.id).update({
          'title': auction.title,
          'description': auction.description,
        });
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
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Edit auction' : 'New auction')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(
                    labelText: 'Title', border: OutlineInputBorder()),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Enter a title' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _description,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Description', border: OutlineInputBorder()),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Enter a description' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _price,
                enabled: !editing,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Starting price', border: OutlineInputBorder()),
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  return n == null || n <= 0 ? 'Enter a price above 0' : null;
                },
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: Text(editing ? 'Save changes' : 'Create auction'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

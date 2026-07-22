import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/stok.dart';
import '../../../core/services/api_service.dart';
import '../models/cart_item.dart';
import '../widgets/cart_sheet.dart';

class KasirScreen extends StatefulWidget {
  const KasirScreen({super.key});

  @override
  State<KasirScreen> createState() => _KasirScreenState();
}

class _KasirScreenState extends State<KasirScreen> {
  final _apiService = ApiService();
  final _searchController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  bool _isLoading = true;
  String? _errorMessage;
  List<Stok> _stokList = [];
  String _searchQuery = '';

  final Map<String, int> _cartQty = {};

  @override
  void initState() {
    super.initState();
    _loadStok();
    _searchController.addListener(() {
      setState(
        () => _searchQuery = _searchController.text.trim().toLowerCase(),
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStok() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final raw = await _apiService.getKasirStok();
      final stokList = raw
          .map((json) => Stok.fromJson(json as Map<String, dynamic>))
          .toList();

      if (!mounted) return;
      setState(() => _stokList = stokList);
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Gagal memuat data stok.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Stok> get _filteredStok {
    if (_searchQuery.isEmpty) return _stokList;
    return _stokList
        .where((stok) => stok.nama.toLowerCase().contains(_searchQuery))
        .toList();
  }

  List<CartItem> get _cartItems {
    return _cartQty.entries.map((entry) {
      final stok = _stokList.firstWhere((s) => s.id == entry.key);
      return CartItem(stok: stok, qty: entry.value);
    }).toList();
  }

  num get _cartTotal => _cartItems.fold(0, (sum, item) => sum + item.subtotal);

  int get _cartItemCount => _cartQty.values.fold(0, (sum, qty) => sum + qty);

  void _addToCart(Stok stok) {
    final currentQty = _cartQty[stok.id] ?? 0;
    if (currentQty >= stok.stok) return;
    setState(() => _cartQty[stok.id] = currentQty + 1);
  }

  void _decreaseFromCart(Stok stok) {
    final currentQty = _cartQty[stok.id] ?? 0;
    if (currentQty <= 1) {
      setState(() => _cartQty.remove(stok.id));
    } else {
      setState(() => _cartQty[stok.id] = currentQty - 1);
    }
  }

  void _removeFromCart(String stokId) {
    setState(() => _cartQty.remove(stokId));
    Navigator.of(context).pop();
    _openCartSheet();
  }

  Future<void> _openCartSheet() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CartSheet(
        items: _cartItems,
        currencyFormat: _currencyFormat,
        onRemove: _removeFromCart,
        onCheckout: _handleCheckout,
      ),
    );

    if (result == true) {
      setState(() => _cartQty.clear());
      await _loadStok();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi berhasil disimpan')),
      );
    }
  }

  Future<void> _handleCheckout() async {
    final items = _cartItems;
    if (items.isEmpty) return;

    await _apiService.createTransaksi(
      barang: items
          .map((item) => {'stok_id': item.stok.id, 'qty': item.qty})
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Kasir')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari barang...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
              ),
            ),
          ),
          Expanded(child: _buildBody(theme, colorScheme)),
          if (_cartItemCount > 0) _buildCartBar(theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme, ColorScheme colorScheme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _stokList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _loadStok,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = _filteredStok;

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty
              ? 'Belum ada data stok'
              : 'Barang tidak ditemukan',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStok,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: filtered.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final stok = filtered[index];
          final qty = _cartQty[stok.id] ?? 0;
          final isOutOfStock = stok.stok <= 0;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stok.nama,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currencyFormat.format(stok.harga),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isOutOfStock ? 'Stok habis' : 'Sisa stok: ${stok.stok}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isOutOfStock
                              ? colorScheme.error
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isOutOfStock)
                  const SizedBox.shrink()
                else if (qty == 0)
                  IconButton.filled(
                    onPressed: () => _addToCart(stok),
                    icon: const Icon(Icons.add_rounded),
                  )
                else
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _decreaseFromCart(stok),
                        icon: const Icon(Icons.remove_circle_outline_rounded),
                      ),
                      Text(
                        '$qty',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        onPressed: qty >= stok.stok
                            ? null
                            : () => _addToCart(stok),
                        icon: const Icon(Icons.add_circle_outline_rounded),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCartBar(ThemeData theme, ColorScheme colorScheme) {
    return SafeArea(
      top: false,
      child: Material(
        color: theme.cardColor,
        elevation: 8,
        child: InkWell(
          onTap: _openCartSheet,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.shopping_cart_rounded,
                        color: colorScheme.primary,
                      ),
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: colorScheme.error,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            '$_cartItemCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        _currencyFormat.format(_cartTotal),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

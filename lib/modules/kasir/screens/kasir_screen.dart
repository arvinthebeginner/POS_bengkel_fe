import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/stok.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/neumorphic.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../riwayat/screens/riwayat_screen.dart';
import '../../stok/screens/stok_screen.dart';
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Kasir',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: NeumorphicTextField(
                controller: _searchController,
                hintText: 'Cari barang...',
                prefixIcon: Icons.search_rounded,
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.onSurfaceVariant,
                        ),
                        onPressed: _searchController.clear,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildBody()),
            if (_cartItemCount > 0) _buildCartBar(),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentTab: AppTab.kasir,
        onTap: (tab) => handleAppTabTap(
          context,
          tab,
          current: AppTab.kasir,
          dashboard: (_) => const DashboardScreen(),
          kasir: (_) => const KasirScreen(),
          stok: (_) => const StokScreen(),
          riwayat: (_) => const RiwayatScreen(),
        ),
      ),
    );
  }

  Widget _buildBody() {
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
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error,
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
          style: const TextStyle(color: AppColors.secondary),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStok,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20, 0, 20, _cartItemCount > 0 ? 16 : 140),
        itemCount: filtered.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final stok = filtered[index];
          final qty = _cartQty[stok.id] ?? 0;
          final isOutOfStock = stok.stok <= 0;

          return NeumorphicBox(
            borderRadius: 20,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stok.nama,
                        style: const TextStyle(
                          color: AppColors.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currencyFormat.format(stok.harga),
                        style: const TextStyle(
                          color: AppColors.primaryContainer,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isOutOfStock ? 'Stok habis' : 'Stok: ${stok.stok}',
                        style: TextStyle(
                          color: isOutOfStock
                              ? AppColors.errorText
                              : AppColors.secondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isOutOfStock)
                  const SizedBox.shrink()
                else if (qty == 0)
                  NeumorphicIconButton(
                    icon: Icons.add_rounded,
                    onPressed: () => _addToCart(stok),
                    size: 44,
                  )
                else
                  NeumorphicBox(
                    style: NeumorphicStyle.pressed,
                    borderRadius: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _decreaseFromCart(stok),
                          icon: const Icon(
                            Icons.remove_rounded,
                            size: 18,
                            color: AppColors.secondary,
                          ),
                        ),
                        Text(
                          '$qty',
                          style: const TextStyle(
                            color: AppColors.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          onPressed: qty >= stok.stok
                              ? null
                              : () => _addToCart(stok),
                          icon: const Icon(
                            Icons.add_rounded,
                            size: 18,
                            color: AppColors.primaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCartBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: GestureDetector(
        onTap: _openCartSheet,
        child: NeumorphicBox(
          borderRadius: 22,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  NeumorphicBox(
                    style: NeumorphicStyle.pressed,
                    width: 44,
                    height: 44,
                    borderRadius: 22,
                    child: const Icon(
                      Icons.shopping_cart_rounded,
                      color: AppColors.primaryContainer,
                    ),
                  ),
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryContainer,
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total ($_cartItemCount item)',
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _currencyFormat.format(_cartTotal),
                      style: const TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/stok.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/neumorphic.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../kasir/screens/kasir_screen.dart';
import '../../riwayat/screens/riwayat_screen.dart';
import '../widgets/stok_form_sheet.dart';

class StokScreen extends StatefulWidget {
  const StokScreen({super.key});

  @override
  State<StokScreen> createState() => _StokScreenState();
}

class _StokScreenState extends State<StokScreen> {
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

  List<Stok> get _filteredStok {
    if (_searchQuery.isEmpty) return _stokList;
    return _stokList
        .where((stok) => stok.nama.toLowerCase().contains(_searchQuery))
        .toList();
  }

  Future<void> _loadStok() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final raw = await _apiService.getStok();
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

  Future<void> _openForm({Stok? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StokFormSheet(existing: existing),
    );

    if (saved == true) {
      _loadStok();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Stok',
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
          ],
        ),
      ),
      floatingActionButton: NeumorphicFab(
        icon: Icons.add_rounded,
        tooltip: 'Tambah',
        onPressed: () => _openForm(),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentTab: AppTab.stok,
        onTap: (tab) => handleAppTabTap(
          context,
          tab,
          current: AppTab.stok,
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
      return _ErrorState(message: _errorMessage!, onRetry: _loadStok);
    }

    final filtered = _filteredStok;

    if (filtered.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadStok,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: _EmptyState(isSearching: _searchQuery.isNotEmpty),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStok,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 140),
        itemCount: filtered.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final stok = filtered[index];
          return _StokCard(
            stok: stok,
            currencyFormat: _currencyFormat,
            onTap: () => _openForm(existing: stok),
          );
        },
      ),
    );
  }
}

class _StokCard extends StatelessWidget {
  const _StokCard({
    required this.stok,
    required this.currencyFormat,
    required this.onTap,
  });

  final Stok stok;
  final NumberFormat currencyFormat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = stok.stok <= 0;
    final isLowStock = !isOutOfStock && stok.stok <= 5;

    final Color pillFill;
    final Color pillText;
    if (isOutOfStock) {
      pillFill = AppColors.errorFill;
      pillText = AppColors.errorText;
    } else if (isLowStock) {
      pillFill = AppColors.warningFill;
      pillText = AppColors.warningText;
    } else {
      pillFill = AppColors.successFill;
      pillText = AppColors.successText;
    }
    final pillLabel = '${stok.stok} Pcs';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: NeumorphicBox(
          borderRadius: 20,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              NeumorphicBox(
                width: 48,
                height: 48,
                borderRadius: 24,
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
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
                    const SizedBox(height: 2),
                    Text(
                      stok.kategori,
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currencyFormat.format(stok.harga),
                      style: const TextStyle(
                        color: AppColors.primaryContainer,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: pillFill,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  pillLabel,
                  style: TextStyle(
                    color: pillText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isSearching});

  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NeumorphicBox(
              width: 88,
              height: 88,
              borderRadius: 44,
              child: Icon(
                isSearching
                    ? Icons.search_off_rounded
                    : Icons.inventory_2_outlined,
                size: 36,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isSearching ? 'Barang tidak ditemukan' : 'Belum ada data stok',
              style: const TextStyle(
                color: AppColors.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isSearching
                  ? 'Coba kata kunci lain'
                  : 'Tekan tombol "+" untuk menambahkan item pertama',
              style: const TextStyle(color: AppColors.secondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NeumorphicBox(
              width: 80,
              height: 80,
              borderRadius: 40,
              child: const Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: AppColors.errorText,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: AppColors.onSurface, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onRetry,
                child: NeumorphicBox(
                  borderRadius: 16,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        size: 18,
                        color: AppColors.errorText,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Coba Lagi',
                        style: TextStyle(
                          color: AppColors.errorText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

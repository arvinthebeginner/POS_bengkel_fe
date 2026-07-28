import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/transaksi.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/fading_edges.dart';
import '../../../core/widgets/neumorphic.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../kasir/screens/kasir_screen.dart';
import '../../stok/screens/stok_screen.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  final _apiService = ApiService();
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  // Format tanggal numerik saja (tidak butuh nama bulan lokal),
  // jadi aman dipakai tanpa initializeDateFormatting().
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  bool _isLoading = true;
  String? _errorMessage;
  List<Transaksi> _riwayat = [];

  @override
  void initState() {
    super.initState();
    _loadRiwayat();
  }

  Future<void> _loadRiwayat() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final raw = await _apiService.getTransaksi();
      final riwayat = raw
          .map((json) => Transaksi.fromJson(json as Map<String, dynamic>))
          .toList()
          // Terbaru di atas.
          .reversed
          .toList();

      if (!mounted) return;
      setState(() => _riwayat = riwayat);
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Gagal memuat riwayat transaksi.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                      'Riwayat Transaksi',
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
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentTab: AppTab.riwayat,
        onTap: (tab) => handleAppTabTap(
          context,
          tab,
          current: AppTab.riwayat,
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

    if (_errorMessage != null && _riwayat.isEmpty) {
      return _ErrorState(message: _errorMessage!, onRetry: _loadRiwayat);
    }

    if (_riwayat.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadRiwayat,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: const _EmptyState(),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRiwayat,
      child: FadingEdges(
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          itemCount: _riwayat.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final transaksi = _riwayat[index];
            return _TransaksiCard(
              transaksi: transaksi,
              currencyFormat: _currencyFormat,
              dateFormat: _dateFormat,
            );
          },
        ),
      ),
    );
  }
}

class _TransaksiCard extends StatefulWidget {
  const _TransaksiCard({
    required this.transaksi,
    required this.currencyFormat,
    required this.dateFormat,
  });

  final Transaksi transaksi;
  final NumberFormat currencyFormat;
  final DateFormat dateFormat;

  @override
  State<_TransaksiCard> createState() => _TransaksiCardState();
}

class _TransaksiCardState extends State<_TransaksiCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final transaksi = widget.transaksi;
    final totalQty = transaksi.barang.fold<int>(
      0,
      (sum, item) => sum + item.qty,
    );

    return NeumorphicBox(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                children: [
                  NeumorphicBox(
                    style: NeumorphicStyle.pressed,
                    width: 44,
                    height: 44,
                    borderRadius: 14,
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaksi.kode,
                          style: const TextStyle(
                            color: AppColors.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${transaksi.tanggal != null ? widget.dateFormat.format(transaksi.tanggal!) : 'Tanggal tidak diketahui'} • $totalQty item',
                          style: const TextStyle(
                            color: AppColors.secondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.currencyFormat.format(transaksi.total),
                        style: const TextStyle(
                          color: AppColors.primaryContainer,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(
                          Icons.expand_more_rounded,
                          size: 18,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: NeumorphicBox(
                style: NeumorphicStyle.pressed,
                borderRadius: 14,
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: transaksi.barang
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.nama} x${item.qty}',
                                  style: const TextStyle(
                                    color: AppColors.onSurface,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Text(
                                widget.currencyFormat.format(item.subtotal),
                                style: const TextStyle(
                                  color: AppColors.secondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
            sizeCurve: Curves.easeOut,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 36,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Belum ada transaksi',
              style: TextStyle(
                color: AppColors.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Transaksi dari halaman Kasir akan muncul di sini',
              style: TextStyle(color: AppColors.secondary, fontSize: 13),
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

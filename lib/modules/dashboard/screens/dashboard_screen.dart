import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/transaksi.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/neumorphic.dart';
import '../../auth/screens/login_screen.dart';
import '../../kasir/screens/kasir_screen.dart';
import '../../riwayat/screens/riwayat_screen.dart';
import '../../stok/screens/stok_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _apiService = ApiService();
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  bool _isLoading = true;
  String? _errorMessage;
  String _username = '';
  int _totalStok = 0;
  int _totalTransaksi = 0;
  List<Transaksi> _recentTransaksi = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _apiService.getMe(),
        _apiService.getStok(),
        _apiService.getTransaksi(),
      ]);

      final me = results[0] as Map<String, dynamic>;
      final stok = results[1] as List<dynamic>;
      final transaksiRaw = results[2] as List<dynamic>;
      final transaksi = transaksiRaw
          .map((json) => Transaksi.fromJson(json as Map<String, dynamic>))
          .toList()
          .reversed
          .toList();

      if (!mounted) return;
      setState(() {
        _username = me['username'] as String? ?? '-';
        _totalStok = stok.length;
        _totalTransaksi = transaksi.length;
        _recentTransaksi = transaksi.take(2).toList();
      });
    } on UnauthorizedException {
      if (!mounted) return;
      _goToLogin();
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(
        () => _errorMessage = 'Gagal memuat data. Tarik untuk coba lagi.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _handleLogout() async {
    await _apiService.logout();
    if (!mounted) return;
    _goToLogin();
  }

  Future<void> _openStok() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const StokScreen()));
    _loadDashboard();
  }

  Future<void> _openKasir() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const KasirScreen()));
    _loadDashboard();
  }

  void _openRiwayat() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RiwayatScreen()));
  }

  String _activityLabel(Transaksi transaksi) {
    if (transaksi.barang.isEmpty) return 'Transaksi';
    final first = transaksi.barang.first;
    if (transaksi.barang.length == 1) return first.nama;
    return '${first.nama} +${transaksi.barang.length - 1} lainnya';
  }

  String _activityCode(Transaksi transaksi) {
    final id = transaksi.id;
    final suffix = id.length >= 4 ? id.substring(id.length - 4) : id;
    return 'TRX-$suffix'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ---------- Header ----------
                Row(
                  children: [
                    NeumorphicBox(
                      width: 48,
                      height: 48,
                      borderRadius: 24,
                      padding: const EdgeInsets.all(8),
                      child: Image.asset('assets/icon/app_icon.png'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selamat datang,',
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            _isLoading ? 'Memuat...' : _username,
                            style: const TextStyle(
                              color: AppColors.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    NeumorphicIconButton(
                      icon: Icons.logout_rounded,
                      onPressed: _handleLogout,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.errorFill,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.errorText,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppColors.errorText),
                          ),
                        ),
                      ],
                    ),
                  ),

                // ---------- Stat cards ----------
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.inventory_2_outlined,
                        label: 'Total Item',
                        sublabel: 'Stok',
                        value: _isLoading ? '-' : '$_totalStok',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.receipt_long_outlined,
                        label: 'Total',
                        sublabel: 'Transaksi',
                        value: _isLoading ? '-' : '$_totalTransaksi',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ---------- Menu Cepat ----------
                const Text(
                  'Menu Cepat',
                  style: TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MenuTile(
                        icon: Icons.point_of_sale_rounded,
                        label: 'Kasir',
                        onTap: _openKasir,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MenuTile(
                        icon: Icons.inventory_2_rounded,
                        label: 'Stok',
                        onTap: _openStok,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MenuTile(
                        icon: Icons.history_rounded,
                        label: 'Riwayat',
                        onTap: _openRiwayat,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ---------- Aktivitas Terakhir ----------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Aktivitas Terakhir',
                      style: TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    GestureDetector(
                      onTap: _openRiwayat,
                      child: const Text(
                        'Lihat Semua',
                        style: TextStyle(
                          color: AppColors.primaryContainer,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (!_isLoading && _recentTransaksi.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Belum ada transaksi',
                      style: TextStyle(color: AppColors.secondary),
                    ),
                  )
                else
                  Column(
                    children: _recentTransaksi
                        .map(
                          (t) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ActivityCard(
                              label: _activityLabel(t),
                              code: _activityCode(t),
                              time: t.tanggal != null
                                  ? DateFormat('HH:mm').format(t.tanggal!)
                                  : '-',
                              amount: _currencyFormat.format(t.total),
                            ),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentTab: AppTab.beranda,
        onTap: (tab) => handleAppTabTap(
          context,
          tab,
          current: AppTab.beranda,
          dashboard: (_) => const DashboardScreen(),
          kasir: (_) => const KasirScreen(),
          stok: (_) => const StokScreen(),
          riwayat: (_) => const RiwayatScreen(),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String sublabel;
  final String value;

  @override
  Widget build(BuildContext context) {
    return NeumorphicBox(
      borderRadius: 24,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.secondary, size: 22),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(color: AppColors.secondary, fontSize: 12),
          ),
          Text(
            sublabel,
            style: const TextStyle(color: AppColors.secondary, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.onSurface,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: NeumorphicBox(
          borderRadius: 20,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primaryContainer, size: 26),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.label,
    required this.code,
    required this.time,
    required this.amount,
  });

  final String label;
  final String code;
  final String time;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return NeumorphicBox(
      borderRadius: 18,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          NeumorphicBox(
            style: NeumorphicStyle.pressed,
            width: 40,
            height: 40,
            borderRadius: 20,
            child: const Icon(
              Icons.receipt_long_rounded,
              color: AppColors.secondary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$code • $time',
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: const TextStyle(
                  color: AppColors.primaryContainer,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.successFill,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'SUKSES',
                  style: TextStyle(
                    color: AppColors.successText,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


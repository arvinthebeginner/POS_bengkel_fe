import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/neumorphic.dart';
import '../models/cart_item.dart';

/// Bottom sheet review keranjang sebelum bayar. Setelah pembayaran berhasil,
/// sheet yang sama bertukar tampilan menjadi struk pembelian.
/// Mengembalikan `true` lewat Navigator.pop kalau transaksi berhasil dibuat.
class CartSheet extends StatefulWidget {
  const CartSheet({
    super.key,
    required this.items,
    required this.currencyFormat,
    required this.onRemove,
    required this.onCheckout,
  });

  final List<CartItem> items;
  final NumberFormat currencyFormat;
  final ValueChanged<String> onRemove;
  final Future<void> Function() onCheckout;

  @override
  State<CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends State<CartSheet> {
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _showReceipt = false;
  DateTime? _paidAt;

  num get _total => widget.items.fold(0, (sum, item) => sum + item.subtotal);

  Future<void> _handleCheckout() async {
    if (widget.items.isEmpty) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await widget.onCheckout();
      if (!mounted) return;
      setState(() {
        _showReceipt = true;
        _paidAt = DateTime.now();
      });
    } catch (e) {
      setState(
        () => _errorMessage = e is Exception
            ? e.toString().replaceFirst('Exception: ', '')
            : 'Gagal memproses transaksi. Coba lagi.',
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: _showReceipt ? _buildReceipt() : _buildCart(),
        ),
      ),
    );
  }

  Widget _buildCart() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _DragHandle(),
        const Text(
          'Keranjang',
          style: TextStyle(
            color: AppColors.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        if (widget.items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'Keranjang kosong',
                style: TextStyle(color: AppColors.secondary),
              ),
            ),
          )
        else
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: widget.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = widget.items[index];
                return NeumorphicBox(
                  style: NeumorphicStyle.pressed,
                  borderRadius: 16,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.stok.nama,
                              style: const TextStyle(
                                color: AppColors.onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.qty} x ${widget.currencyFormat.format(item.stok.harga)}',
                              style: const TextStyle(
                                color: AppColors.secondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        widget.currencyFormat.format(item.subtotal),
                        style: const TextStyle(
                          color: AppColors.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => widget.onRemove(item.stok.id),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: AppColors.errorText,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total',
              style: TextStyle(
                color: AppColors.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              widget.currencyFormat.format(_total),
              style: const TextStyle(
                color: AppColors.primaryContainer,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: AppColors.errorFill,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 18,
                  color: AppColors.errorText,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: AppColors.errorText,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        NeumorphicPrimaryButton(
          label: 'Konfirmasi Pembayaran',
          isLoading: _isSubmitting,
          onPressed: widget.items.isEmpty ? null : _handleCheckout,
        ),
      ],
    );
  }

  Widget _buildReceipt() {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _DragHandle(),
        Center(
          child: NeumorphicBox(
            width: 72,
            height: 72,
            borderRadius: 36,
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.successText,
              size: 36,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Pembayaran Berhasil',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _paidAt != null ? dateFormat.format(_paidAt!) : '',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.secondary, fontSize: 12),
        ),
        const SizedBox(height: 20),
        NeumorphicBox(
          style: NeumorphicStyle.pressed,
          borderRadius: 18,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Pratama Motor',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                'Struk Pembelian',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.secondary, fontSize: 11),
              ),
              const SizedBox(height: 12),
              const _DashedDivider(),
              const SizedBox(height: 12),
              ...widget.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.stok.nama,
                              style: const TextStyle(
                                color: AppColors.onSurface,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${item.qty} x ${widget.currencyFormat.format(item.stok.harga)}',
                              style: const TextStyle(
                                color: AppColors.secondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        widget.currencyFormat.format(item.subtotal),
                        style: const TextStyle(
                          color: AppColors.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const _DashedDivider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    widget.currencyFormat.format(_total),
                    style: const TextStyle(
                      color: AppColors.primaryContainer,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        NeumorphicPrimaryButton(
          label: 'Selesai',
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// Garis putus-putus ala kertas struk kasir, memisahkan bagian item dan total.
class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const dashWidth = 6.0;
          const dashSpace = 4.0;
          final dashCount = (constraints.maxWidth / (dashWidth + dashSpace))
              .floor();
          return Row(
            children: List.generate(
              dashCount,
              (_) => Padding(
                padding: const EdgeInsets.only(right: dashSpace),
                child: Container(
                  width: dashWidth,
                  height: 1,
                  color: AppColors.secondary.withValues(alpha: 0.4),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

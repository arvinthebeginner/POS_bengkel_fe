import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/stok.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/neumorphic.dart';

class StokFormSheet extends StatefulWidget {
  const StokFormSheet({super.key, this.existing});

  final Stok? existing;

  @override
  State<StokFormSheet> createState() => _StokFormSheetState();
}

class _StokFormSheetState extends State<StokFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  late final _namaController = TextEditingController(
    text: widget.existing?.nama,
  );
  late final _kategoriController = TextEditingController(
    text: widget.existing?.kategori,
  );
  late final _hargaController = TextEditingController(
    text: widget.existing?.harga.toString(),
  );
  late final _stokController = TextEditingController(
    text: widget.existing?.stok.toString(),
  );

  bool _isSaving = false;
  bool _isDeleting = false;
  String? _errorMessage;

  bool get _isEditMode => widget.existing != null;

  @override
  void dispose() {
    _namaController.dispose();
    _kategoriController.dispose();
    _hargaController.dispose();
    _stokController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final nama = _namaController.text.trim();
      final kategori = _kategoriController.text.trim();
      final harga = num.parse(_hargaController.text.trim());
      final stok = int.parse(_stokController.text.trim());

      if (_isEditMode) {
        await _apiService.updateStok(
          stokId: widget.existing!.id,
          nama: nama,
          kategori: kategori,
          harga: harga,
          stok: stok,
        );
      } else {
        await _apiService.createStok(
          nama: nama,
          kategori: kategori,
          harga: harga,
          stok: stok,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Gagal menyimpan. Coba lagi.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus stok?'),
        content: Text(
          'Item "${widget.existing!.nama}" akan dihapus permanen dan tidak bisa dikembalikan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorText),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });

    try {
      await _apiService.deleteStok(widget.existing!.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Gagal menghapus. Coba lagi.');
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _isSaving || _isDeleting;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    _isEditMode ? 'Edit Stok' : 'Tambah Stok',
                    style: const TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _FieldLabel('Nama Barang'),
                  NeumorphicTextField(
                    controller: _namaController,
                    hintText: 'Contoh: Oli Mesin 10W-40',
                    prefixIcon: Icons.inventory_2_outlined,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const _FieldLabel('Kategori'),
                  NeumorphicTextField(
                    controller: _kategoriController,
                    hintText: 'Contoh: Sparepart',
                    prefixIcon: Icons.category_outlined,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Kategori tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _FieldLabel('Harga'),
                            NeumorphicTextField(
                              controller: _hargaController,
                              hintText: '0',
                              prefixIcon: Icons.payments_outlined,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Wajib diisi';
                                }
                                if (num.tryParse(value.trim()) == null) {
                                  return 'Harus angka';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _FieldLabel('Jumlah'),
                            NeumorphicTextField(
                              controller: _stokController,
                              hintText: '0',
                              prefixIcon: Icons.numbers_outlined,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _handleSubmit(),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Wajib diisi';
                                }
                                if (int.tryParse(value.trim()) == null) {
                                  return 'Harus angka';
                                }
                                return null;
                              },
                            ),
                          ],
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
                  const SizedBox(height: 24),
                  if (_isEditMode) ...[
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: isBusy ? null : _handleDelete,
                        child: NeumorphicBox(
                          borderRadius: 18,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Center(
                            child: _isDeleting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.errorText,
                                    ),
                                  )
                                : const Text(
                                    'Hapus',
                                    style: TextStyle(
                                      color: AppColors.errorText,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  NeumorphicPrimaryButton(
                    label: _isEditMode ? 'Simpan Perubahan' : 'Tambah Stok',
                    isLoading: _isSaving,
                    onPressed: isBusy ? null : _handleSubmit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

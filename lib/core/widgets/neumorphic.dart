import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum NeumorphicStyle { raised, pressed }

/// A soft-shadow surface matching the "Kinetic Tactility" design system:
/// raised surfaces sit above the background, pressed surfaces sink into it.
class NeumorphicBox extends StatelessWidget {
  const NeumorphicBox({
    super.key,
    required this.child,
    this.style = NeumorphicStyle.raised,
    this.borderRadius = 20,
    this.padding,
    this.margin,
    this.width,
    this.height,
  });

  final Widget child;
  final NeumorphicStyle style;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final isRaised = style == NeumorphicStyle.raised;

    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isRaised
              ? [const Color(0xFFEDF3F4), const Color(0xFFD8E1E3)]
              : [const Color(0xFFD8E1E3), const Color(0xFFEDF3F4)],
        ),
        boxShadow: isRaised
            ? const [
                BoxShadow(
                  color: AppColors.neuLight,
                  offset: Offset(-6, -6),
                  blurRadius: 12,
                ),
                BoxShadow(
                  color: AppColors.neuShadow,
                  offset: Offset(6, 6),
                  blurRadius: 12,
                ),
              ]
            : const [
                BoxShadow(
                  color: AppColors.neuShadow,
                  offset: Offset(2, 2),
                  blurRadius: 4,
                ),
              ],
      ),
      child: child,
    );
  }
}

/// Full-width primary call-to-action button — the one saturated red element
/// per screen in this design system.
class NeumorphicPrimaryButton extends StatelessWidget {
  const NeumorphicPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.borderRadius = 18,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: isLoading ? null : onPressed,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryContainer.withValues(alpha: 0.35),
                offset: const Offset(0, 6),
                blurRadius: 16,
              ),
            ],
          ),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}

/// A pill-shaped "pressed into the surface" text field, used for search bars
/// and form inputs throughout the design system. On focus, it sinks deeper
/// into the surface (stronger inset shadow) rather than showing a border.
class NeumorphicTextField extends StatefulWidget {
  const NeumorphicTextField({
    super.key,
    this.controller,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.textInputAction,
    this.onFieldSubmitted,
    this.validator,
  });

  final TextEditingController? controller;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldValidator<String>? validator;

  @override
  State<NeumorphicTextField> createState() => _NeumorphicTextFieldState();
}

class _NeumorphicTextFieldState extends State<NeumorphicTextField> {
  final _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isFocused ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isFocused
                ? const [Color(0xFFC7D0D3), Color(0xFFEEF4F5)]
                : const [Color(0xFFD8E1E3), Color(0xFFEDF3F4)],
          ),
          boxShadow: _isFocused
              ? const [
                  BoxShadow(
                    color: AppColors.neuShadow,
                    offset: Offset(5, 5),
                    blurRadius: 10,
                  ),
                  BoxShadow(
                    color: Color(0x99FFFFFF),
                    offset: Offset(-3, -3),
                    blurRadius: 6,
                  ),
                ]
              : const [
                  BoxShadow(
                    color: AppColors.neuShadow,
                    offset: Offset(2, 2),
                    blurRadius: 4,
                  ),
                ],
        ),
        child: TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          obscureText: widget.obscureText,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onFieldSubmitted,
          validator: widget.validator,
          cursorColor: AppColors.primaryContainer,
          style: const TextStyle(color: AppColors.onSurface),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: const TextStyle(color: AppColors.secondary),
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    color: _isFocused
                        ? AppColors.primaryContainer
                        : AppColors.onSurfaceVariant,
                  )
                : null,
            suffixIcon: widget.suffixIcon,
          ),
        ),
      ),
    );
  }
}

/// A small circular raised icon button (nav icons, header actions).
class NeumorphicIconButton extends StatelessWidget {
  const NeumorphicIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 40,
    this.iconColor = AppColors.primary,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: NeumorphicBox(
          width: size,
          height: size,
          borderRadius: size / 2,
          child: Icon(icon, color: iconColor, size: size * 0.5),
        ),
      ),
    );
  }
}

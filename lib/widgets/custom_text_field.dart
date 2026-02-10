import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aman_enterprises/core/theme/app_theme.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? label;
  final String? hintText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final int maxLines;
  final bool enabled;

  const CustomTextField({
    super.key,
    required this.controller,
    this.label,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.enabled = true,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _isFocused = false;
  bool _hasError = false;
  String? _errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTextStyles.labelText.copyWith(
              color: _hasError
                  ? Colors.red
                  : (_isFocused ? AppColors.primaryGreen : AppColors.textLight),
            ),
          ),
          const SizedBox(height: 8),
        ],
        
        Focus(
          onFocusChange: (focused) {
            setState(() => _isFocused = focused);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: widget.enabled
                  ? (_isFocused
                      ? AppColors.primaryGreen.withAlpha(13)
                      : Colors.white)
                  : AppColors.border.withAlpha(128),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              border: Border.all(
                color: _hasError
                    ? Colors.red
                    : (_isFocused
                        ? AppColors.primaryGreen
                        : AppColors.border),
                width: _isFocused ? 2 : 1,
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: AppColors.primaryGreen.withAlpha(26),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: TextFormField(
              controller: widget.controller,
              keyboardType: widget.keyboardType,
              obscureText: widget.obscureText,
              textCapitalization: widget.textCapitalization,
              inputFormatters: widget.inputFormatters,
              maxLines: widget.maxLines,
              enabled: widget.enabled,
              style: AppTextStyles.inputText,
              onChanged: (value) {
                widget.onChanged?.call(value);
                if (_hasError && widget.validator != null) {
                  final error = widget.validator!(value);
                  setState(() {
                    _hasError = error != null;
                    _errorText = error;
                  });
                }
              },
              validator: (value) {
                final error = widget.validator?.call(value);
                setState(() {
                  _hasError = error != null;
                  _errorText = error;
                });
                return error;
              },
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: AppTextStyles.hintText,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: widget.prefixIcon != null ? 0 : 16,
                  vertical: 16,
                ),
                prefixIcon: widget.prefixIcon != null
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Icon(
                          widget.prefixIcon,
                          color: _isFocused
                              ? AppColors.primaryGreen
                              : AppColors.textLight,
                          size: AppDimensions.iconMedium,
                        ),
                      )
                    : null,
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 56,
                  minHeight: 56,
                ),
                suffixIcon: widget.suffixIcon != null
                    ? GestureDetector(
                        onTap: widget.onSuffixTap,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Icon(
                            widget.suffixIcon,
                            color: _isFocused
                                ? AppColors.primaryGreen
                                : AppColors.textLight,
                            size: AppDimensions.iconMedium,
                          ),
                        ),
                      )
                    : null,
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 56,
                  minHeight: 56,
                ),
              ),
            ),
          ),
        ),
        
        // Error Text
        if (_hasError && _errorText != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  _errorText!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

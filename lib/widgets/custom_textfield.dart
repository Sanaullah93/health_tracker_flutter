import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String hintText;
  final IconData icon;
  final Color iconColor;
  final Color focusedColor;
  final bool isPassword;
  final bool? isPasswordHidden;
  final VoidCallback? onPasswordToggle;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int? maxLines;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final String? errorText;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final String? labelText;
  final EdgeInsetsGeometry? contentPadding;
  final Color backgroundColor;
  final bool showIcon;

  const CustomTextField({
    super.key,
    this.controller,
    required this.hintText,
    required this.icon,
    this.iconColor = Colors.grey,
    this.focusedColor = Colors.blue,
    this.isPassword = false,
    this.isPasswordHidden,
    this.onPasswordToggle,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.onChanged,
    this.enabled = true,
    this.errorText,
    this.textInputAction,
    this.focusNode,
    this.labelText,
    this.contentPadding,
    this.backgroundColor = Colors.white,
    this.showIcon = true,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Text(
              widget.labelText!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: widget.backgroundColor,
            border: Border.all(
              color: _isFocused
                  ? widget.focusedColor.withOpacity(0.3)
                  : Colors.transparent,
              width: 1,
            ),
            boxShadow: [
              if (_isFocused)
                BoxShadow(
                  color: widget.focusedColor.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 15,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: widget.controller,
            obscureText: widget.isPassword && (widget.isPasswordHidden ?? true),
            validator: widget.validator,
            keyboardType: widget.keyboardType,
            maxLines: widget.maxLines,
            onChanged: widget.onChanged,
            enabled: widget.enabled,
            textInputAction: widget.textInputAction,
            focusNode: _focusNode,
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: widget.showIcon
                  ? Padding(
                      padding: EdgeInsets.only(left: 16, right: 12),
                      child: Icon(
                        widget.icon,
                        color: _isFocused
                            ? widget.focusedColor
                            : widget.iconColor,
                        size: 22,
                      ),
                    )
                  : null,
              suffixIcon: widget.isPassword && widget.onPasswordToggle != null
                  ? Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: IconButton(
                        icon: Icon(
                          (widget.isPasswordHidden ?? true)
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: _isFocused
                              ? widget.focusedColor
                              : Color(0xFF94A3B8),
                          size: 22,
                        ),
                        onPressed: widget.onPasswordToggle,
                        splashRadius: 20,
                      ),
                    )
                  : null,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding:
                  widget.contentPadding ??
                  EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              errorText: widget.errorText,
              errorStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.red.shade500,
              ),
            ),
            cursorColor: widget.focusedColor,
            cursorWidth: 2,
            cursorHeight: 20,
          ),
        ),
      ],
    );
  }
}

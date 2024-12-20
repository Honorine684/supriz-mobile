// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

class ourButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final double fontSize;
  final FontWeight fontWeight;
  final bool isLoading;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final double borderRadius;
  final bool isDisabled;
  final ButtonStyle? style;

  const ourButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 45.0,
    this.fontSize = 16.0,
    this.fontWeight = FontWeight.w600,
    this.isLoading = false,
    this.prefixIcon,
    this.suffixIcon,
    this.borderRadius = 10.0,
    this.isDisabled = false,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? MediaQuery.of(context).size.width,
      height: height,
      child: ElevatedButton(
        onPressed: isDisabled || isLoading ? null : onPressed,
        style: style ?? ElevatedButton.styleFrom(
          backgroundColor: isDisabled
              ? Colors.grey.shade300
              : backgroundColor ?? Color(0xFF005792),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
        ),
        child: isLoading
            ? _buildLoadingIndicator()
            : _buildButtonContent(),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation<Color>(
          textColor ?? Colors.white,
        ),
      ),
    );
  }

  Widget _buildButtonContent() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (prefixIcon != null) ...[
          Icon(
            prefixIcon,
            color: textColor ?? Colors.white,
            size: fontSize + 4,
          ),
          SizedBox(width: 8),
        ],
        Text(
          text,
          style: TextStyle(
            color: isDisabled
                ? Colors.grey
                : textColor ?? Colors.white,
            fontSize: fontSize,
            fontWeight: fontWeight,
          ),
        ),
        if (suffixIcon != null) ...[
          SizedBox(width: 8),
          Icon(
            suffixIcon,
            color: textColor ?? Colors.white,
            size: fontSize + 4,
          ),
        ],
      ],
    );
  }
}
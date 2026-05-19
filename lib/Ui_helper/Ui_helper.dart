import 'package:flutter/material.dart';

class UiHelper {
  static CustomTextButton({
    required BuildContext context,
    required String text,
    required VoidCallback callBack,
  }) {
    return TextButton(
      onPressed: callBack,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  static CustomImage({required String imgurl}) {
    return Image.asset('assets/Images/$imgurl');
  }

  static Widget CustomTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String text,
    required bool tohide,
    required TextInputType textinputtype,
    required IconData prefixIcon,
    Widget? suffixIcon,
    Function(String)? onChanged,
  }) {
    return Container(
      width: 343,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1.0,
          ),
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: tohide,
        keyboardType: textinputtype,
        onChanged: onChanged,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: text,
          hintStyle: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          prefixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                prefixIcon,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
              SizedBox(width: 12),
              Container(
                height: 20,
                width: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              SizedBox(width: 12),
            ],
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

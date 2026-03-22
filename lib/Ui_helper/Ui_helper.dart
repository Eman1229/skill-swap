import 'package:flutter/material.dart';
class UiHelper{
  static CustomTextButton({required String text, required VoidCallback callBack}){
    return TextButton(onPressed: callBack,
        child: Text(text,style: TextStyle(fontSize: 12,
            color: Color(0XFF0F172A)
        ),
        )
        );
  }
  static CustomImage({required String imgurl}){
    return Image.asset('assets/Images/$imgurl');
  }
  static Widget CustomTextField({
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
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white24, width: 1.0),
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: tohide,
        keyboardType: textinputtype,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: text,
          hintStyle: const TextStyle(fontSize: 14, color: Colors.white70),
          prefixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(prefixIcon, color: Colors.white70, size: 20),
              const SizedBox(width: 12),
              Container(height: 20, width: 1, color: Colors.white24),
              const SizedBox(width: 12),
            ],
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

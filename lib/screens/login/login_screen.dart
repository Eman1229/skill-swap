import 'package:provider/provider.dart';
import 'package:skill_swap/providers/language_provider.dart';
import 'package:flutter/material.dart';
class LoginScreen extends StatelessWidget{
  @override
  Widget build (BuildContext context){
    context.watch<LanguageProvider>();
    return Scaffold(
        body:Center(),
    );
}}
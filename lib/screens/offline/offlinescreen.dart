import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:skill_swap/Ui_helper/Ui_helper.dart';
import 'package:skill_swap/screens/onboarding1/onboarding1.dart';

 class OfflineScreen extends StatefulWidget {

   @override
   State<OfflineScreen> createState() => _OfflineScreenState();
 }
 class _OfflineScreenState extends State<OfflineScreen>{
   @override
     Widget build (BuildContext context){
    return Scaffold(
       body: Center(
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             UiHelper.CustomImage(imgurl: "nowifi.png"),
             Text("You are Offline",style:TextStyle(fontFamily: "Nunito",color: Colors.white,fontWeight: FontWeight.w400,fontSize: 32),),
             Text("No Internet connection found. Check",style: TextStyle(fontFamily: "Inter",fontSize: 14,color: Color(0XFF888888)),),
             SizedBox(
               height: 4,
             ),
             Text("your connection or try again.",style: TextStyle(fontFamily: "Inter",fontSize: 14,color: Color(0XFF888888)),),
           ],
         ),
       ),
    );
  }


}

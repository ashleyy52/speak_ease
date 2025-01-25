import 'package:flutter/material.dart';
class forgot extends StatelessWidget {
  const forgot({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //backgroundColor: Color(0xFF078173),
      body:

      Container(
        decoration: BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff4a9591), Color(0xff043941)],
        ),),
        child: Center(

          child: Column(
            children: [
              SizedBox(height: 200,),
              Center(child: Text("NI THENJ!",style: TextStyle(fontSize: 50,
              fontWeight: FontWeight.bold),)),
              SizedBox(height: 40,),
              Image.asset("assets/images/tenj.png",height: 450,)
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/image/news.jpg',
              fit: BoxFit.cover,
              width: width * .9,
              height: height * .5,
            ),
            SizedBox(height: height * 0.04),
            Text(
              'HABER PUSULASI',
              style: GoogleFonts.anton(letterSpacing: .6, color: Colors.grey.shade700),
            ),
            SizedBox(height: height * 0.04),
            SpinKitChasingDots(
              color: Colors.black,
              size: 40,
            )
          ],
        ),
      ),
    );
  }
}

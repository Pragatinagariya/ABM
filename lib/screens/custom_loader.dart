import 'package:flutter/material.dart';

class CustomLoader extends StatelessWidget {
  const CustomLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withOpacity(0.5),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
      // child: Center(
      //   child: SizedBox(
      //     height: 45,
      //     width: 45,
      //     child: Image.asset("assets/loader.gif"),
      //   ),
      // ),
    );
  }
}

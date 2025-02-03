import 'package:flutter/material.dart';

Widget loadingScreenWidget(BuildContext context) {
  final size = MediaQuery.of(context).size;

  return Container(
    color: Colors.black.withOpacity(.6),
    width: size.width,
    height: size.height,
    child: Center(
      child: SizedBox(
        height: 45,
        width: 45,
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      ),
    ),
  );
}

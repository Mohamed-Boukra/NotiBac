import 'package:flutter/material.dart';

class TopSlantClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final slant = size.height * 0.35;
    final path = Path();
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height - slant);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class BottomSlantClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final slant = size.height * 0.18;
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, slant);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

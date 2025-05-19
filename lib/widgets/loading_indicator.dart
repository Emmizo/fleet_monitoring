import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LoadingIndicator extends StatelessWidget {
  final Color color;
  final double size;
  const LoadingIndicator({Key? key, this.color = Colors.blue, this.size = 48})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(child: SpinKitFadingCircle(color: color, size: size));
  }
}

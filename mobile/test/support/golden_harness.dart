import 'package:flutter/material.dart';

class GoldenViewport {
  const GoldenViewport({required this.name, required this.size});

  final String name;
  final Size size;
}

const goldenViewports = [
  GoldenViewport(name: '360dp', size: Size(360, 800)),
  GoldenViewport(name: '720dp', size: Size(720, 1280)),
  GoldenViewport(name: '1280dp', size: Size(1280, 800)),
];

const goldenTextScales = [1.0, 2.0];

String goldenFileName(
  String component,
  String state,
  GoldenViewport viewport,
  double textScale,
) {
  final scale = textScale.toStringAsFixed(1).replaceAll('.', '_');
  final width = viewport.name.replaceAll('dp', '');
  return '${component}_${state}_${width}dp_text_$scale';
}

BoxConstraints goldenViewportConstraints(GoldenViewport viewport) {
  return BoxConstraints.tight(viewport.size);
}

BoxConstraints goldenSheetConstraints(GoldenViewport viewport) {
  return BoxConstraints(
    minWidth: viewport.size.width,
    maxWidth: viewport.size.width,
  );
}

Widget withDisabledAnimations(Widget child) {
  return Builder(
    builder: (context) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: TickerMode(enabled: false, child: child),
      );
    },
  );
}

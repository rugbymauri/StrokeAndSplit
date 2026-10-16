import 'package:flutter/widgets.dart';

/// The layout of the live display, chosen by the shape of the available
/// space rather than the orientation of the device (ui-design, Design D2).
enum LiveLayout {
  portrait,
  landscape;

  /// Landscape when wider than high, so a wide laptop window works like a phone on its side.
  static LiveLayout of(Size size) => size.width > size.height ? landscape : portrait;
}

/// Builds [builder] with the layout for the space it is given.
class LiveLayoutBuilder extends StatelessWidget {
  const LiveLayoutBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, LiveLayout layout) builder;

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) => builder(context, LiveLayout.of(constraints.biggest)));
}

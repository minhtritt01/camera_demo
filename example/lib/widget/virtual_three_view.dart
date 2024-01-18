import 'package:flutter/material.dart';

class VirtualThreeView extends StatefulWidget {
  final Widget child;
  final AlignmentGeometry alignment;
  final double width;
  final double height;

  const VirtualThreeView({
    Key? key,
    required this.child,
    required this.alignment,
    required this.width,
    required this.height,
  }) : super(key: key);

  @override
  State<VirtualThreeView> createState() => _VirtualThreeViewState();
}

class _VirtualThreeViewState extends State<VirtualThreeView> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      child: Container(
        decoration: BoxDecoration(),
        clipBehavior: Clip.hardEdge,
        child: OverflowBox(
          alignment: widget.alignment,
          minWidth: widget.width * 1.6,
          maxWidth: widget.width * 1.6,
          minHeight: widget.height * 1.6,
          maxHeight: widget.height * 1.6,
          child: widget.child,
        ),
      ),
    );
  }
}

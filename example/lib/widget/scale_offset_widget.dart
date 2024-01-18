import 'package:flutter/material.dart';
import 'package:vsdk_example/widget/scale_offset_gesture_detector.dart';

class ScaleOffsetView extends StatefulWidget {
  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;
  final ValueNotifier<ScaleOffset> notifier;
  final ValueNotifier<ScaleOffset>? buttonNotifier;
  final bool isSquare;
  final bool supportBinocular;
  final bool supportScale;

  const ScaleOffsetView(
      {Key? key,
      required this.child,
      required this.notifier,
      this.buttonNotifier,
      this.isSquare = false,
      this.supportBinocular = false,
      this.supportScale = true})
      : super(key: key);

  @override
  ScaleOffsetViewState createState() => ScaleOffsetViewState();
}

class ScaleOffsetViewState extends State<ScaleOffsetView> {
  void _handleChange() {
    print("------supportBinocular----${widget.supportBinocular}---------");
    if (widget.supportBinocular == true) {
      if (widget.supportScale == false) {
        return;
      }
      var scale = widget.notifier.value.scale;
      if (scale > _switchValue) {
        if (_isUpdate) {
          _isUpdate = false;
          widget.notifier.value.scale = _switchValue;
          setState(() {});
        }
        return;
      } else {
        _isUpdate = true;
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  var _isUpdate = true;

  var _switchValue = 16 / 9.0;

  @override
  void initState() {
    try {
      widget.notifier.addListener(_handleChange);
      widget.buttonNotifier?.addListener(_handleChange);
    } catch (e) {}
    super.initState();
  }

  @override
  void dispose() {
    try {
      widget.notifier.removeListener(_handleChange);
      widget.buttonNotifier?.removeListener(_handleChange);
    } catch (e) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ScaleOffset scaleOffset = widget.notifier.value;
    final double scaleValue = scaleOffset.scale;
    double offsetX = scaleOffset.offsetX;
    double offsetY = scaleOffset.offsetY;

    double width = MediaQuery.of(context).size.width;
    double height = width * 9 / 16;

    double scaleValueY = scaleValue;
    double scaleValueX = scaleValue;
    if (MediaQuery.of(context).orientation == Orientation.portrait &&
        widget.isSquare == true) {
      offsetY = scaleValue * height > width ? offsetY : 0;
      scaleValueY = scaleValue * 0.5625;
    }
    if (widget.supportBinocular == true) {
      if (widget.supportScale == true) {
        if (MediaQuery.of(context).orientation == Orientation.landscape) {
          scaleValueX = scaleValueX > _switchValue ? _switchValue : scaleValueX;
          scaleValueY = scaleValueY > _switchValue ? _switchValue : scaleValueY;
        } else {
          scaleValueX = scaleValueX > _switchValue ? _switchValue : scaleValueX;
          scaleValueY = scaleValueY > 1.0 ? 1.0 : scaleValueY;
        }
      } else {
        scaleValueX = 1.0;
        scaleValueY = 1.0;
      }
      offsetX = 0.0;
      offsetY = 0.0;
    }
    //print("scaleValueX: $scaleValueX, scaleValueY: $scaleValueY, $offsetX, $offsetY");
    final Matrix4 transform = Matrix4.identity()
      ..scale(scaleValueX, scaleValueY, 1.0);
    return Container(
      child: Transform(
        transform: transform,
        alignment: Alignment(offsetX, offsetY),
        child: widget.child,
      ),
      decoration: BoxDecoration(color: Colors.transparent),
      clipBehavior: Clip.hardEdge,
    );
  }
}

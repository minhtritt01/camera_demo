import 'dart:ui';

import 'package:flutter/material.dart';

import 'dart:ui' as ui;

class FocalPointBWidget extends StatefulWidget {
  final double originalX;
  final double originalY;
  final Function(int xPercent, int yPercent)? onLongPressEndListener;
  final Function(int xPercent, int yPercent)? onPressEndListener;
  final Function()? onLongPressStartListener;
  final Function()? onTapListener;
  final Function()? onListenerRet;
  final Color normalColor;
  final Color selectedColor;
  final bool isActivate;
  final bool isReSet;
  final ui.Image? image;

  FocalPointBWidget(this.originalX, this.originalY, this.selectedColor,
      {this.onLongPressStartListener,
      this.onLongPressEndListener,
      this.onPressEndListener,
      this.onTapListener,
      this.onListenerRet,
      this.image,
      this.normalColor = Colors.white,
      this.isReSet = false,
      this.isActivate = true});

  @override
  _FocalPointBWidgetState createState() => _FocalPointBWidgetState();
}

class _FocalPointBWidgetState extends State<FocalPointBWidget> {
  double centerX = 0.0;
  double centerY = 0.0;
  late Color selectedLineColor;
  Color lineColor = Colors.white;
  ui.Image? image;
  bool isReSet = false;

  @override
  void initState() {
    centerX = widget.originalX;
    centerY = widget.originalY;
    image = widget.image;
    isReSet = widget.isReSet;
    selectedLineColor = widget.selectedColor;
    lineColor = Colors.white;

    super.initState();
  }

  _parser(Offset offset) {
    double maxX = MediaQuery.of(context).size.width;
    double maxY = maxX * 9 / 16;

    ///centerX = offset.dx > (maxX - 30) ? (maxX - 30) : offset.dx;
    ///centerY = offset.dy > (maxY - 0) ? (maxY - 0) : offset.dy;

    if (offset.dx > (maxX - 30)) {
      centerX = maxX - 30;
    } else if (offset.dx < (30)) {
      centerX = 30;
    } else {
      centerX = offset.dx;
    }

    if (offset.dy > (maxY - 30)) {
      centerY = maxY - 30;
    } else if (offset.dy < 30) {
      centerY = 30;
    } else {
      centerY = offset.dy;
    }

    if (centerX < 0) {
      centerX = 0;
    }

    if (centerY < 0) {
      centerY = 0;
    }

    lineColor = selectedLineColor;

    setState(() {});
  }

  _parserLongPressEnd(Offset offset) {
    double maxX = MediaQuery.of(context).size.width - 40;
    double maxY = maxX * 9 / 16;

    if (offset.dx > (maxX - 30)) {
      centerX = maxX - 30;
    } else if (offset.dx < (30)) {
      centerX = 30;
    } else {
      centerX = offset.dx;
    }

    if (offset.dy > (maxY - 30)) {
      centerY = maxY - 30;
    } else if (offset.dy < 30) {
      centerY = 30;
    } else {
      centerY = offset.dy;
    }

    if (centerX < 0) {
      centerX = 0;
    }

    if (centerY < 0) {
      centerY = 0;
    }

    lineColor = Colors.white;

    if (widget.onLongPressEndListener != null) {
      widget.onLongPressEndListener!(
          (centerX / maxX * 100).toInt(), (centerY / maxY * 100).toInt());
    }

    setState(() {});
  }

  _parserPressEnd(Offset offset) {
    double maxX = MediaQuery.of(context).size.width;
    double maxY = maxX * 9 / 16;

    if (offset.dx > (maxX - 30)) {
      centerX = maxX - 30;
    } else if (offset.dx < (30)) {
      centerX = 30;
    } else {
      centerX = offset.dx;
    }

    if (offset.dy > (maxY - 5)) {
      centerY = maxY - 5;
    } else if (offset.dy < 30) {
      centerY = 30;
    } else {
      centerY = offset.dy;
    }

    if (centerX < 0) {
      centerX = 0;
    }

    if (centerY < 0) {
      centerY = 0;
    }

    lineColor = Colors.white;

    if (widget.onPressEndListener != null) {
      ///print('onPressEndListener centerX::${centerX}  maxX::${maxX}');
      widget.onPressEndListener!(
          (centerX / maxX * 100).toInt(), (centerY / maxY * 100).toInt());
    }

    setState(() {});
  }

  _parserLongPressStart(Offset offset) {
    double maxX = MediaQuery.of(context).size.width - 40;
    double maxY = maxX * 9 / 16;

    if (offset.dx > (maxX - 30)) {
      centerX = maxX - 30;
    } else if (offset.dx < (30)) {
      centerX = 30;
    } else {
      centerX = offset.dx;
    }

    if (offset.dy > (maxY - 30)) {
      centerY = maxY - 30;
    } else if (offset.dy < 30) {
      centerY = 30;
    } else {
      centerY = offset.dy;
    }

    if (centerX < 0) {
      centerX = 0;
    }

    if (centerY < 0) {
      centerY = 0;
    }

    lineColor = Colors.white;

    if (widget.onLongPressStartListener != null) {
      widget.onLongPressStartListener!();
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    double containerWidth = MediaQuery.of(context).size.width - 40;
    double containerHeight = containerWidth * 9 / 16;

    print('widget.isReSet${widget.isReSet}');
    print('widget.isReSet centerX$centerX  ');
    print('widget.isReSet centerY$centerY ');
    if (widget.isReSet) {
      centerX = (MediaQuery.of(context).size.width) / 2;
      centerY = (MediaQuery.of(context).size.width) / 2 * 9 / 16;
      if (widget.onPressEndListener != null) {
        widget.onPressEndListener!(50, 50);
      }
    }
    return GestureDetector(
      onTap: () {
        if (widget.onTapListener != null) {
          widget.onTapListener!();
        }
      },
      onHorizontalDragStart: (a) => {},
      onHorizontalDragUpdate: (a) => {},
      onHorizontalDragEnd: (a) => {},
      onVerticalDragStart: (a) => {},
      onVerticalDragUpdate: (a) => {},
      onVerticalDragEnd: (a) => {},
      child: Listener(
        onPointerUp: (d) => _parserPressEnd(d.localPosition),
        onPointerMove: (d) => _parser(d.localPosition),
        onPointerDown: (d) => _parser(d.localPosition),
        child: Container(
            width: containerWidth,
            height: containerHeight,
            child: OverflowBox(
              child: CustomPaint(
                painter: _HandleView(
                    centerX: centerX,
                    centerY: centerY,
                    maxX: containerWidth,
                    maxY: containerHeight,
                    image: image,
                    isRet: widget.isReSet,
                    lineColor: lineColor),
              ),
              minWidth: containerWidth,
              minHeight: containerHeight,
              maxWidth: containerWidth + 100,
              maxHeight: containerHeight + 100,
            )),
      ),
    );
  }

// double get maxR => zoneR + handleR;
}

///画板
class _HandleView extends CustomPainter {
  var _paint = Paint();
  var centerX;
  var centerY;
  var maxX;
  var maxY;
  ui.Image? image;
  Color lineColor;
  bool isRet;
  var _centerpaint = Paint();

  _HandleView(
      {this.centerX,
      this.centerY,
      this.maxX,
      this.maxY,
      this.image,
      this.isRet = false,
      this.lineColor = Colors.white}) {
    _paint
      ..color = Colors.white
      // ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    _centerpaint
      ..color = Colors.red
      ..isAntiAlias = true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // canvas.translate(maxR, maxR);
    _paint.strokeWidth = 1.5;
    _paint.style = PaintingStyle.stroke;

    print("isRet$isRet");
    _centerpaint.style = PaintingStyle.stroke;
    _centerpaint.strokeWidth = 1.5;
    _paint.color = lineColor;
    print('centerX ::$centerX  centerY::$centerY');
    print('maxX$maxX  maxY$maxY');
    int numx = (maxX / 10).toInt();
    int numy = (maxY / 10).toInt() + 1;
    canvas.drawCircle(Offset(centerX, centerY), 15, _paint);
    canvas.drawCircle(Offset(centerX, centerY), 20, _paint);

    canvas.drawPoints(
        PointMode.lines,
        [
          Offset(centerX - 25, centerY),
          Offset(centerX - 10, centerY),
          Offset(centerX, centerY - 25),
          Offset(centerX, centerY - 10)
        ],
        _paint);

    canvas.drawPoints(
        PointMode.lines,
        [
          Offset(centerX + 10, centerY),
          Offset(centerX + 25, centerY),
          Offset(centerX, centerY + 10),
          Offset(centerX, centerY + 25)
        ],
        _paint);
    List<Offset> pointx = [];
    for (int a = 0; a < numx; a++) {
      ///水平虚线
      double linex = a * 10.toDouble() + 20;
      if (linex < centerX - 30 || linex > centerX + 30) {
        pointx.add(Offset(linex, centerY));
        pointx.add(Offset(linex + 5.0, centerY));
      }
    }
    canvas.drawPoints(PointMode.lines, pointx, _paint);

    List<Offset> pointY = [];
    for (int y = 0; y < numy; y++) {
      ///垂直虚线
      double liney = y * 10.toDouble() + 20;
      if (liney < centerY - 30 || liney > centerY + 30) {
        pointY.add(Offset(centerX, liney));
        pointY.add(Offset(centerX, liney + 5));
      }
    }
    canvas.drawPoints(PointMode.lines, pointY, _paint);
    canvas.clipRRect(RRect.fromRectAndRadius(
        Rect.fromCircle(center: Offset(centerX, centerY - 75), radius: 31),
        Radius.circular(31)));

    if (image != null) {
      print(
          'fromLTRB ::left${centerX - 50}  topY::${centerY - 50} right${centerX + 50} boom${centerY + 50} imagew ${image!.width} imageH${image!.height}');
      print(
          'fromLTRB16/9 ::left${centerX * (16 / 9) - 50}  topY::${centerY * (16 / 9) - 50} right${centerX * (16 / 9) + 50} boom${centerY * (16 / 9) + 50} imagew ${image!.width} imageH${image!.height}');

      canvas.drawImageRect(
          image!,
          /*    Rect.fromLTRB(centerX * (16 / 9) - 25, centerY * (16 / 9) - 25,
              centerX * (16 / 9) + 50, centerY * (16 / 9) + 50),*/
          Rect.fromCircle(
              center: Offset(
                  centerX * (16 / 9) - 20, centerY * (16 / 9) - (20 * 9 / 16)),
              radius: 30),
          Rect.fromCircle(center: Offset(centerX, centerY - 75), radius: 30),
          _paint);
    }
    canvas.drawPoints(
        PointMode.lines,
        [
          Offset(centerX - 5, centerY - 75),
          Offset(centerX + 5, centerY - 75),
          Offset(centerX, centerY - 80),
          Offset(centerX, centerY - 70)
        ],
        _centerpaint);

    _paint.strokeWidth = 1.5;
    canvas.drawCircle(Offset(centerX, centerY - 75), 30, _paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

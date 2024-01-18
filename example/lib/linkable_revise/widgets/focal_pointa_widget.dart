import 'dart:ui';

import 'package:flutter/material.dart';

class FocalPointAWidget extends StatefulWidget {
  final double originalX;
  final double originalY;
  final Function(int xPercent, int yPercent)? onLongPressEndListener;
  final Function(int xPercent, int yPercent)? onPressEndListener;
  final Function()? onLongPressStartListener;
  final Function()? onTapListener;
  final Color normalColor;
  final Color selectedColor;
  final bool isActivate;

  FocalPointAWidget(this.originalX, this.originalY, this.selectedColor,
      {this.onLongPressStartListener,
      this.onLongPressEndListener,
      this.onPressEndListener,
      this.onTapListener,
      this.normalColor = Colors.white,
      this.isActivate = true});

  @override
  _FocalPointAWidgetState createState() => _FocalPointAWidgetState();
}

class _FocalPointAWidgetState extends State<FocalPointAWidget> {
  double centerX = 0.0;
  double centerY = 0.0;
  late Color selectedLineColor;
  Color lineColor = Colors.white;

  @override
  void initState() {
    centerX = widget.originalX;
    centerY = widget.originalY;
    selectedLineColor = widget.selectedColor;
    lineColor = Colors.white;

    super.initState();
  }

  _parser(Offset offset) {
    double maxX = MediaQuery.of(context).size.width;
    double maxY = maxX * 9 / 16;

    centerX = offset.dx > (maxX - 0) ? (maxX - 0) : offset.dx;
    centerY = offset.dy > (maxY - 0) ? (maxY - 0) : offset.dy;

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
    double maxX = MediaQuery.of(context).size.width;
    double maxY = maxX * 9 / 16;

    centerX = offset.dx > (maxX - 0) ? (maxX - 0) : offset.dx;
    centerY = offset.dy > (maxY - 0) ? (maxY - 0) : offset.dy;

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
    double maxX = MediaQuery.of(context).size.width - 40;
    double maxY = maxX * 9 / 16;

    centerX = offset.dx > (maxX - 0) ? (maxX - 0) : offset.dx;
    centerY = offset.dy > (maxY - 0) ? (maxY - 0) : offset.dy;

    if (centerX < 0) {
      centerX = 0;
    }

    if (centerY < 0) {
      centerY = 0;
    }

    lineColor = Colors.white;

    if (widget.onPressEndListener != null) {
      widget.onPressEndListener!(
          (centerX / maxX * 100).toInt(), (centerY / maxY * 100).toInt());
    }

    setState(() {});
  }

  _parserLongPressStart(Offset offset) {
    double maxX = MediaQuery.of(context).size.width;
    double maxY = maxX * 9 / 16;

    centerX = offset.dx > (maxX - 0) ? (maxX - 0) : offset.dx;
    centerY = offset.dy > (maxY - 0) ? (maxY - 0) : offset.dy;

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
      onLongPressStart: (a) => _parserLongPressStart(a.localPosition),
      onLongPressMoveUpdate: (a) => _parser(a.localPosition),
      onLongPressEnd: (a) => _parserLongPressEnd(a.localPosition),
      child: Listener(
        /*  onPointerUp: (d) => _parserPressEnd(d.localPosition),
        onPointerMove: (d) => _parser(d.localPosition),
        onPointerDown: (d) => _parser(d.localPosition),*/
        child: Container(
          width: containerWidth,
          height: containerHeight,
          child: CustomPaint(
            painter: _HandleView(
                centerX: centerX,
                centerY: centerY,
                maxX: containerWidth,
                maxY: containerHeight,
                lineColor: lineColor),
          ),
        ),
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
  Color lineColor;
  var _centerpaint = Paint();

  _HandleView(
      {this.centerX,
      this.centerY,
      this.maxX,
      this.maxY,
      this.lineColor = Colors.white}) {
    _paint
      ..color = Colors.white
      // ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    _centerpaint
      ..color = Colors.red
      ..isAntiAlias = true;
  }

  // double get maxR => zoneR + handleR;

  @override
  void paint(Canvas canvas, Size size) {
    // canvas.translate(maxR, maxR);
    _paint.strokeWidth = 1.5;
    _paint.style = PaintingStyle.stroke;

    _paint.color = lineColor;
    _centerpaint.style = PaintingStyle.stroke;
    _centerpaint.strokeWidth = 1.5;
    print('centerX ::$centerX  centerY::$centerY');
    print('maxX$maxX  maxY$maxY');

    int numx = (maxX / 10).toInt();
    int numy = (maxY / 10).toInt() + 1;

    ///print('numx:${numx}  numy:${numy}');
    //canvas.drawCircle(Offset(centerX, centerY), 15, _paint);
    canvas.drawCircle(Offset(centerX, centerY), 45, _paint);

    canvas.drawPoints(
        PointMode.lines,
        [
          Offset(centerX - 50, centerY),
          Offset(centerX - 40, centerY),
          Offset(centerX, centerY - 50),
          Offset(centerX, centerY - 40)
        ],
        _paint);

    canvas.drawPoints(
        PointMode.lines,
        [
          Offset(centerX + 50, centerY),
          Offset(centerX + 40, centerY),
          Offset(centerX, centerY + 50),
          Offset(centerX, centerY + 40)
        ],
        _paint);

    canvas.drawPoints(
        PointMode.lines,
        [
          Offset(centerX - 5, centerY),
          Offset(centerX + 5, centerY),
          Offset(centerX, centerY - 5),
          Offset(centerX, centerY + 5)
        ],
        _centerpaint);

/*    canvas.drawPoints(
        PointMode.lines,
        [
          Offset(centerX - 10, centerY-10),
          Offset(centerX + 40, centerY),
          Offset(centerX, centerY + 50),
          Offset(centerX, centerY + 40)
        ],
        _paint);*/

    /*  canvas.drawPoints(
        PointMode.lines,
        [
          Offset(centerX + 30, centerY - 30),
          Offset(centerX + 15, centerY - 10),
          Offset(centerX + 35, centerY - 15),
          Offset(centerX + 15, centerY - 10),

          */ /*   Offset(centerX + 15, centerY - 30),
          Offset(centerX + 15, centerY + 20),*/ /*
          */ /*  Offset(centerX - 15, centerY - 30),
          Offset(centerX + 20, centerY + 70)*/ /*
        ],
        _paint);*/

/*    List<Offset> pointx = [];
    for (int a = 0; a < numx; a++) {
      ///水平虚线
      double linex = a * 10.toDouble();
      if (linex < centerX - 30 || linex > centerX + 30) {
        pointx.add(Offset(linex, centerY));
        pointx.add(Offset(linex + 5.0, centerY));
      }
    }
    canvas.drawPoints(PointMode.lines, pointx, _paint);*/

    /* List<Offset> pointY = [];
    for (int y = 0; y < numy; y++) {
      ///垂直虚线
      double liney = y * 10.toDouble();
      if (liney < centerY - 30 || liney > centerY + 30) {
        pointY.add(Offset(centerX, liney));
        pointY.add(Offset(centerX, liney + 5));
      }
    }
    canvas.drawPoints(PointMode.lines, pointY, _paint);*/
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

import 'package:flutter/material.dart';

class FocalPointWidget extends StatefulWidget {
  final double originalX;
  final double originalY;
  final Function(int xPercent, int yPercent)? onDragEndListener;
  final Function()? onDragStartListener;
  final Function()? onTapListener;
  final Function()? onTapDownListener;
  final Color normalColor;
  final Color selectedColor;
  final bool isActivate;

  FocalPointWidget(this.originalX, this.originalY, this.selectedColor,
      {this.onDragStartListener,
      this.onDragEndListener,
      this.onTapListener,
      this.onTapDownListener,
      this.normalColor = Colors.white,
      this.isActivate = true});

  @override
  _FocalPointWidgetState createState() => _FocalPointWidgetState();
}

class _FocalPointWidgetState extends State<FocalPointWidget> {
  double centerX = 0.0;
  double centerY = 0.0;
  bool isFromCenter = false;
  late Color selectedLineColor;
  Color lineColor = Colors.white;

  @override
  void initState() {
    centerX = widget.originalX;
    centerY = widget.originalY;
    selectedLineColor = widget.selectedColor;
    lineColor = Colors.white;

    // print('==>>这里调用initState :${widget.originalX} ${widget.originalY}');

    super.initState();
  }

  _parser(Offset offset) {
    // if (!isFromCenter) return;

    double maxX = MediaQuery.of(context).size.width;
    double maxY = maxX * 9 / 16;
    if (MediaQuery.of(context).orientation == Orientation.landscape) {
      maxY = MediaQuery.of(context).size.height;
    }

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

  _parserDragEnd() {
    // if (!isFromCenter) return;

    double maxX = MediaQuery.of(context).size.width;
    double maxY = maxX * 9 / 16;
    if (MediaQuery.of(context).orientation == Orientation.landscape) {
      maxY = MediaQuery.of(context).size.height;
    }

    // centerX = offset.dx > (maxX - 0) ? (maxX - 0) : offset.dx;
    // centerY = offset.dy > (maxY - 0) ? (maxY - 0) : offset.dy;

    if (centerX < 0) {
      centerX = 0;
    }

    if (centerY < 0) {
      centerY = 0;
    }

    lineColor = Colors.white;

    if (widget.onDragEndListener != null) {
      widget.onDragEndListener!(
          (centerX / maxX * 100).toInt(), (centerY / maxY * 100).toInt());
    }

    setState(() {});
  }

  _parserDragStart(Offset offset) {
    double maxX = MediaQuery.of(context).size.width;
    double maxY = maxX * 9 / 16;
    if (MediaQuery.of(context).orientation == Orientation.landscape) {
      maxY = MediaQuery.of(context).size.height;
    }

    //需要在中心区域 才响应
    // if (offset.dx > centerX - 25 &&
    //     offset.dx < centerX + 25 &&
    //     offset.dy > centerY - 25 &&
    //     offset.dy < centerY + 25) {
    //   isFromCenter = true;
    centerX = offset.dx > (maxX - 0) ? (maxX - 0) : offset.dx;
    centerY = offset.dy > (maxY - 0) ? (maxY - 0) : offset.dy;

    if (centerX < 0) {
      centerX = 0;
    }

    if (centerY < 0) {
      centerY = 0;
    }

    lineColor = Colors.white;

    if (widget.onDragStartListener != null) {
      widget.onDragStartListener!();
    }

    setState(() {});
    // } else {
    //   isFromCenter = false;
    // }
  }

  @override
  Widget build(BuildContext context) {
    double containerWidth = MediaQuery.of(context).size.width;
    double containerHeight = containerWidth * 9 / 16;
    if (MediaQuery.of(context).orientation == Orientation.landscape) {
      containerHeight = MediaQuery.of(context).size.height;
    }

    return GestureDetector(
      onTap: () {
        // if (widget.onTapListener != null) {
        //   widget.onTapListener();
        // }
      },
      onTapDown: (a) => () {},
      child: Listener(
        onPointerUp: (d) => _parserDragEnd(),
        onPointerMove: (d) => _parser(d.localPosition),
        onPointerDown: (d) => _parserDragStart(d.localPosition),
        child: Container(
          color: Colors.transparent,
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
}

///画板
class _HandleView extends CustomPainter {
  var _paint = Paint();
  var centerX;
  var centerY;
  var maxX;
  var maxY;
  Color lineColor;

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
  }

  @override
  void paint(Canvas canvas, Size size) {
    // canvas.translate(maxR, maxR);
    _paint.strokeWidth = 1.5;
    _paint.style = PaintingStyle.stroke;

    _paint.color = lineColor;

    canvas.drawCircle(Offset(centerX, centerY), 10, _paint);
    canvas.drawCircle(Offset(centerX, centerY), 15, _paint);
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(centerX, centerY), width: 50, height: 50),
        _paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

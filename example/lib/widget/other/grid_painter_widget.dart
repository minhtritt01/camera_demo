import 'package:flutter/material.dart';

class GridPainter extends StatefulWidget {
  final double width;
  final double height;
  final Function onSave;
  final List<List<int>> gridState;

  GridPainter(this.width, this.height, this.onSave, this.gridState);

  @override
  _GridPainterState createState() => _GridPainterState();
}

class _GridPainterState extends State<GridPainter> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: widget.width,
          height: widget.height,
          child: GestureDetector(
            onPanUpdate: (DragUpdateDetails details) {
              RenderBox renderBox = context.findRenderObject() as RenderBox;
              Offset localPosition =
                  renderBox.globalToLocal(details.globalPosition);
              int row = (localPosition.dy / (widget.height / 18)).floor();
              int col = (localPosition.dx / (widget.width / 22)).floor();
              if (row >= 0 && col >= 0 && row < 18 && col < 22) {
                setState(() {
                  widget.gridState[row][col] = 0;
                });
              }
            },
            child: CustomPaint(
              painter: GridPainterCustom(widget.gridState),
              size: Size.infinite,
            ),
          ),
        ),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
                onTap: () {
                  widget.onSave(widget.gridState);
                },
                child: button("保存")),
            GestureDetector(
                onTap: () {
                  clearArea();
                },
                child: button("清除")),
          ],
        )
      ],
    );
  }

  Widget button(String name) {
    return Container(
        width: 100,
        height: 40,
        decoration: BoxDecoration(
            border: Border.all(color: Colors.grey, width: 1.0),
            borderRadius: BorderRadius.all(Radius.circular(8))),
        alignment: Alignment.center,
        child: Text(name));
  }

  void clearArea() {
    widget.gridState.forEach((row) {
      row.fillRange(0, row.length, 1);
    });
    setState(() {});
  }
}

class GridPainterCustom extends CustomPainter {
  final List<List<int>> gridState;

  GridPainterCustom(this.gridState);

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制网格
    Paint gridPaint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    double cellWidth = size.width / 22;
    double cellHeight = size.height / 18;

    for (int i = 0; i <= 22; i++) {
      double dx = i * cellWidth;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), gridPaint);
    }

    for (int i = 0; i <= 18; i++) {
      double dy = i * cellHeight;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }

    // 填充手指涂抹区域
    Paint fillPaint = Paint()..color = Colors.blue;
    for (int i = 0; i < gridState.length; i++) {
      for (int j = 0; j < gridState[i].length; j++) {
        if (gridState[i][j] == 0) {
          canvas.drawRect(
              Rect.fromLTWH(
                  j * cellWidth, i * cellHeight, cellWidth, cellHeight),
              fillPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

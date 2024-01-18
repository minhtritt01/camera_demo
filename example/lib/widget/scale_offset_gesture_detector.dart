import 'package:flutter/cupertino.dart';
import 'dart:math';
import 'dart:async';
import '../model/device_model.dart';

enum DragDirection {
  none,
  up,
  down,
  left,
  right,
}

class Drag {
  DragDirection verticalDrag;
  DragDirection horizontalDrag;

  Drag(this.verticalDrag, this.horizontalDrag);
}

class ScaleOffset {
  double _scale;
  double _offsetX;
  double _offsetY;
  late String status;

  double get scale => _scale;

  set scale(double value) {
    value = max(value, 1.0);
    _scale = value;
  }

  ScaleOffset({double scale = 1.0, double offsetX = 0.0, double offsetY = 0.0})
      : _scale = scale,
        _offsetX = offsetX,
        _offsetY = offsetY;

  ScaleOffset copy({double? scale, double? offsetX, double? offsetY}) {
    return ScaleOffset(
        scale: scale ?? this.scale,
        offsetX: offsetX ?? this.offsetX,
        offsetY: offsetY ?? this.offsetY);
  }

  double get offsetX => _offsetX;

  set offsetX(double value) {
    value = max(value, -1.0);
    value = min(value, 1.0);
    _offsetX = value;
  }

  double get offsetY => _offsetY;

  set offsetY(double value) {
    value = max(value, -1.0);
    value = min(value, 1.0);
    _offsetY = value;
  }
}

class ScaleOffsetGestureDetectorDouble extends StatelessWidget {
  final Widget child;
  final GestureTapCallback onTap;
  final ValueNotifier<ScaleOffset> scaleNotifier;
  final ValueNotifier<Drag> dragNotifier;
  final GestureTapCallback onDoubleTap;
  final bool supportBinocular;
  final DeviceModel? deviceModel;

  const ScaleOffsetGestureDetectorDouble(
      {Key? key,
      required this.child,
      required this.scaleNotifier,
      required this.onTap,
      required this.dragNotifier,
      required this.onDoubleTap,
      required this.supportBinocular,
      required this.deviceModel})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    double _scaleValue = 1.0;
    double _offsetX = 1.0;
    double _offsetY = 1.0;
    late Offset _startOffset;
    late Offset _centerOffset;
    bool? _scaleStartFlag;
    bool? _dragStartFlag;
    DateTime? _startTime;

    int tempX = 0;
    int tempY = 0;

    var start = (ScaleStartDetails details) {
      // if(supportBinocular == true){
      //   return;
      // }
      _scaleStartFlag = true;
      _scaleValue = scaleNotifier.value.scale;
      _dragStartFlag = true;
      _offsetX = scaleNotifier.value.offsetX;
      _offsetY = scaleNotifier.value.offsetY;
      _startOffset = details.localFocalPoint;
      _startTime = DateTime.now();
    };
    var end = (ScaleEndDetails details) {
      // if(supportBinocular == true){
      //   return;
      // }
      _scaleStartFlag = false;
    };

    var update = (ScaleUpdateDetails details) {
      // if(supportBinocular == true){
      //   return;
      // }
      if (_scaleStartFlag == true && details.scale != 1.0) {
        double scale;
        if (details.scale > 1.0) {
          scale = _scaleValue + details.scale - 1.0;
        } else {
          scale = _scaleValue * details.scale;
        }
        scaleNotifier.value.scale = scale;

        scaleNotifier.notifyListeners();
      } else if (_scaleStartFlag == true && _centerOffset != null) {
        if (scaleNotifier.value.scale == 1.0) {
          if (_dragStartFlag == false || dragNotifier == null) {
            return;
          }
          Offset offset = _startOffset - details.localFocalPoint;
          DragDirection? vDrag;
          DragDirection? hDrag;
          if (offset.distance < -50 || offset.distance > 50) {
            if (offset.direction > -1.0 && offset.direction < 1.0)
              hDrag = DragDirection.left;
            if (offset.direction > 2.0 || offset.direction < -2.0)
              hDrag = DragDirection.right;

            if (offset.direction > 0.5 && offset.direction < 2.5)
              vDrag = DragDirection.up;
            if (offset.direction > -2.5 && offset.direction < -0.5)
              vDrag = DragDirection.down;
          }
          if (vDrag != null || hDrag != null) {
            Duration duration = DateTime.now().difference(_startTime!);
            if (duration.inSeconds == 0 && duration.inMilliseconds < 200) {
              _dragStartFlag = false;
              dragNotifier.value.verticalDrag = vDrag!;
              dragNotifier.value.horizontalDrag = hDrag!;
              dragNotifier.notifyListeners();
            }
          }
        } else {
          double x, y;
          Offset offset = _startOffset - details.localFocalPoint;
          x = offset.dx / _centerOffset.dx;
          y = offset.dy / _centerOffset.dy;
          scaleNotifier.value.offsetX = _offsetX + x;
          scaleNotifier.value.offsetY = _offsetY + y;
          scaleNotifier.notifyListeners();
        }
      }
    };

    return LayoutBuilder(builder: (context, constraints) {
      _centerOffset = Offset(
          constraints.constrainWidth() / 2, constraints.constrainHeight() / 2);
      return Listener(
        child: GestureDetector(
          child: child,
          onTap: onTap,
          onDoubleTap: () async {
            if (tempX == null || tempX == 'null') {
              print('=>> 识别null');
              return;
            }
            if (deviceModel != null) {
              Future.delayed(Duration(milliseconds: 500), () {
                print(
                    '=>> 识别到双击Width()${constraints.constrainWidth()} height${constraints.constrainHeight()} 相对x${tempX}相对y${tempY}');
                // Get.find<IDeviceSettingProvider>().videoDoubleTap(
                //     deviceModel,
                //     constraints.constrainWidth().toInt(),
                //     constraints.constrainHeight().toInt(),
                //     tempX,
                //     tempY);
              });
            } else {
              print('=>> 识别到双击 deviceModel == null');
            }

            scaleNotifier.value.scale = 1.0;
            scaleNotifier.notifyListeners();
          },
          onVerticalDragStart: (details) {
            print('=>> onVerticalDragStart');
            start(ScaleStartDetails(
                focalPoint: details.globalPosition,
                localFocalPoint: details.localPosition,
                pointerCount: 1));
          },
          onVerticalDragUpdate: (details) {
            print('=>> onVerticalDragUpdate');
            update(ScaleUpdateDetails(
                focalPoint: details.globalPosition,
                localFocalPoint: details.localPosition,
                pointerCount: 1));
          },
          onVerticalDragEnd: (details) {
            print('=>> onVerticalDragEnd');
            end(ScaleEndDetails(velocity: details.velocity, pointerCount: 1));
          },
          // onTapDown: (TapDownDetails details) {
          //   Offset localPosition = details.localPosition;
          //   double x = localPosition.dx;
          //   double y = localPosition.dy;
          //   tempX = x.toInt();
          //   tempY = y.toInt();
          //   print("=>>点击onTapDown:$x,$y");
          //   print("=>>点击onTapDown:tempX$tempX,tempY$tempY");
          // },
          onScaleEnd: end,
          onScaleUpdate: update,
          onScaleStart: start,
          // onTapUp: (details) {
          //   tempX = details.localPosition.dx.toInt();
          //   tempY = details.localPosition.dy.toInt();
          //   print(
          //       '=>> 点击onTapUp localPosition.dx${details.localPosition.dx} localPosition y${details.localPosition.dy}');
          //   print(
          //       '=>> 点击onTapUp globalPosition.dx${details.globalPosition.dx} globalPosition y${details.globalPosition.dy}');
          // },
        ),
        onPointerUp: (PointerUpEvent event) {
          tempX = event.localPosition.dx.toInt();
          tempY = event.localPosition.dy.toInt();
          //判断距离差
          print("=>>点击onPointerUp:tempX$tempX,tempY$tempY");
          //print("距离:$detal 结束:$position 开始:$_downY");
        },
        onPointerDown: (PointerDownEvent event) {
          tempX = event.localPosition.dx.toInt();
          tempY = event.localPosition.dy.toInt();
          print("=>>点击onPointerDown:tempX$tempX,tempY$tempY");
        },
      );
    });
  }
}

class ScaleOffsetGestureDetector extends StatelessWidget {
  final Widget child;
  final GestureTapCallback onTap;
  final ValueNotifier<ScaleOffset> scaleNotifier;
  final ValueNotifier<Drag> dragNotifier;
  final GestureTapCallback onDoubleTap;
  final bool supportBinocular;
  final bool dragEnable;

  const ScaleOffsetGestureDetector(
      {Key? key,
      required this.child,
      required this.scaleNotifier,
      required this.onTap,
      required this.dragNotifier,
      required this.onDoubleTap,
      required this.supportBinocular,
      this.dragEnable = true})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    double _scaleValue = 1.0;
    double _offsetX = 1.0;
    double _offsetY = 1.0;
    late Offset _startOffset;
    late Offset _centerOffset;
    bool _scaleStartFlag = false;
    bool _dragStartFlag = false;
    DateTime? _startTime;

    var start = (ScaleStartDetails details) {
      if (supportBinocular == true) {
        scaleNotifier.value.status = 'start';
      }
      _scaleStartFlag = true;
      _scaleValue = scaleNotifier.value.scale;
      _dragStartFlag = true;
      _offsetX = scaleNotifier.value.offsetX;
      _offsetY = scaleNotifier.value.offsetY;
      _startOffset = details.localFocalPoint;
      _startTime = DateTime.now();
    };
    var end = (ScaleEndDetails details) {
      if (supportBinocular == true) {
        scaleNotifier.value.status = 'end';
        scaleNotifier.notifyListeners();
      }
      _scaleStartFlag = false;
    };

    var update = (ScaleUpdateDetails details) {
      if (supportBinocular == true) {
        scaleNotifier.value.status = 'update';
      }
      if (_scaleStartFlag == true && details.scale != 1.0) {
        double scale;
        if (details.scale > 1.0) {
          scale = _scaleValue + details.scale - 1.0;
        } else {
          scale = _scaleValue * details.scale;
        }
        scaleNotifier.value.scale = scale;

        scaleNotifier.notifyListeners();
      } else if (_scaleStartFlag == true && _centerOffset != null) {
        if (scaleNotifier.value.scale == 1.0 || supportBinocular == true) {
          if (_dragStartFlag == false || dragNotifier == null) {
            return;
          }
          Offset offset = _startOffset - details.localFocalPoint;
          DragDirection? vDrag;
          DragDirection? hDrag;
          if (offset.distance < -50 || offset.distance > 50) {
            if (offset.direction > -1.0 && offset.direction < 1.0)
              hDrag = DragDirection.left;
            if (offset.direction > 2.0 || offset.direction < -2.0)
              hDrag = DragDirection.right;

            if (offset.direction > 0.5 && offset.direction < 2.5)
              vDrag = DragDirection.up;
            if (offset.direction > -2.5 && offset.direction < -0.5)
              vDrag = DragDirection.down;
          }
          if (vDrag != null || hDrag != null) {
            Duration duration = DateTime.now().difference(_startTime!);
            if (duration.inSeconds == 0 && duration.inMilliseconds < 200) {
              _dragStartFlag = false;
              dragNotifier.value.verticalDrag = vDrag!;
              dragNotifier.value.horizontalDrag = hDrag!;
              dragNotifier.notifyListeners();
            }
          }
        } else {
          double x, y;
          Offset offset = _startOffset - details.localFocalPoint;
          x = offset.dx / _centerOffset.dx;
          y = offset.dy / _centerOffset.dy;
          scaleNotifier.value.offsetX = _offsetX + x;
          scaleNotifier.value.offsetY = _offsetY + y;
          scaleNotifier.notifyListeners();
        }
      }
    };

    return LayoutBuilder(builder: (context, constraints) {
      double width = constraints.constrainWidth();
      double height = constraints.constrainHeight();
      if (height.isInfinite == true && width.isInfinite == false) {
        height = width * 9 / 16;
      }
      _centerOffset = Offset(width / 2, height / 2);
      return dragEnable == true
          ? GestureDetector(
              child: child,
              onTap: onTap,
              onDoubleTap: () {
                print('=>>识别到双击~~~~~~~~~~~~~~~~~~~');
                scaleNotifier.value.scale = 1.0;
                scaleNotifier.notifyListeners();
                if (onDoubleTap != null) {
                  onDoubleTap();
                }
              },
              onVerticalDragStart: (details) {
                start(ScaleStartDetails(
                    focalPoint: details.globalPosition,
                    localFocalPoint: details.localPosition,
                    pointerCount: 1));
              },
              onVerticalDragUpdate: (details) {
                update(ScaleUpdateDetails(
                    focalPoint: details.globalPosition,
                    localFocalPoint: details.localPosition,
                    pointerCount: 1));
              },
              onVerticalDragEnd: (details) {
                end(ScaleEndDetails(
                    velocity: details.velocity, pointerCount: 1));
              },
              onScaleEnd: end,
              onScaleUpdate: update,
              onScaleStart: start,
            )
          : GestureDetector(
              child: child,
              onTap: onTap,
              onDoubleTap: () {
                print('=>>识别到双击~~~~~~~~~~~~~~~~~~~');
                scaleNotifier.value.scale = 1.0;
                scaleNotifier.notifyListeners();
                if (onDoubleTap != null) {
                  onDoubleTap();
                }
              },
              onScaleEnd: end,
              onScaleUpdate: update,
              onScaleStart: start,
            );
    });
  }
}

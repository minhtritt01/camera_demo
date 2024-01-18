import 'package:flutter/material.dart';
import 'app_extension.dart';

class AppPlayerSlider extends StatefulWidget {
  const AppPlayerSlider(
      {super.key,
      required this.totalValue,
      required this.currentValue,
      required this.onChanged});

  final int totalValue;
  final int currentValue;
  final ValueChanged<double> onChanged;

  @override
  _AppPlayerSliderState createState() => _AppPlayerSliderState();
}

class _AppPlayerSliderState extends State<AppPlayerSlider> {
  late int _sliderValue;
  late int _startValue;
  late bool _isChanged;

  @override
  Widget build(BuildContext context) {
    int total = widget.totalValue;
    int sec = widget.currentValue;
    if (_sliderValue != null) {
      if (_sliderValue > total) {
        _sliderValue = total;
      }
      if (_sliderValue < 0) {
        _sliderValue = 0;
      }
    }
    return Slider(
      activeColor: Theme.of(context).primaryColor,
      onChangeStart: (value) {
        _isChanged = false;
        _startValue = value.floor();
        _sliderValue = _startValue;
      },
      onChangeEnd: (value) {
        if (_isChanged != true && _sliderValue == _startValue) {
          return;
        }
        _sliderValue = 0;
        if (widget.onChanged != null) widget.onChanged(value);
      },
      onChanged: (value) {
        _isChanged = true;
        setState(() {
          _sliderValue = value.floor();
        });
      },
      label: total == 0
          ? null
          : "${((_sliderValue ?? sec) ~/ 60).toStringDigits(2)}:${((_sliderValue ?? sec) % 60).toStringDigits(2)}",
      value: (_sliderValue ?? sec).ceilToDouble(),
      divisions: total == 0 ? null : total,
      min: 0,
      max: total.ceilToDouble(),
    );
  }
}

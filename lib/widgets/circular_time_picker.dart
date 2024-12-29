import 'package:flutter/material.dart';
import 'dart:math' as math;

class CircularTimePicker extends StatefulWidget {
  final TimeOfDay initialTime;
  final void Function(TimeOfDay) onTimeChanged;
  final Color? accentColor;
  final Color? backgroundColor;
  final bool use24HourFormat;

  const CircularTimePicker({
    super.key,
    required this.initialTime,
    required this.onTimeChanged,
    this.accentColor,
    this.backgroundColor,
    this.use24HourFormat = true,
  });

  @override
  State<CircularTimePicker> createState() => _CircularTimePickerState();
}

class _CircularTimePickerState extends State<CircularTimePicker> {
  late TimeOfDay _selectedTime;
  bool _isHourMode = true;

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.initialTime;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveAccentColor = widget.accentColor ?? theme.colorScheme.primary;
    final effectiveBackgroundColor = widget.backgroundColor ?? theme.colorScheme.surface;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Display de la hora seleccionada
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TimeDisplay(
                value: _formatHour(_selectedTime.hour),
                isSelected: _isHourMode,
                onTap: () => setState(() => _isHourMode = true),
                color: effectiveAccentColor,
              ),
              Text(
                ':',
                style: TextStyle(
                  fontSize: 48,
                  color: effectiveAccentColor,
                ),
              ),
              _TimeDisplay(
                value: _selectedTime.minute.toString().padLeft(2, '0'),
                isSelected: !_isHourMode,
                onTap: () => setState(() => _isHourMode = false),
                color: effectiveAccentColor,
              ),
              if (!widget.use24HourFormat) ...[
                const SizedBox(width: 12),
                _AmPmSwitch(
                  isAm: _selectedTime.hour < 12,
                  onChanged: _handleAmPmChanged,
                  color: effectiveAccentColor,
                ),
              ],
            ],
          ),
        ),
        // Selector circular
        SizedBox(
          height: 300,
          width: 300,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: effectiveBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
              _CircularPicker(
                selectedValue: _isHourMode ? _selectedTime.hour : _selectedTime.minute,
                maxValue: _isHourMode ? (widget.use24HourFormat ? 23 : 11) : 59,
                onValueChanged: (value) {
                  setState(() {
                    if (_isHourMode) {
                      if (!widget.use24HourFormat && _selectedTime.hour >= 12) {
                        value += 12;
                      }
                      _selectedTime = TimeOfDay(hour: value, minute: _selectedTime.minute);
                    } else {
                      _selectedTime = TimeOfDay(hour: _selectedTime.hour, minute: value);
                    }
                    widget.onTimeChanged(_selectedTime);
                  });
                },
                accentColor: effectiveAccentColor,
                isHourMode: _isHourMode,
                use24HourFormat: widget.use24HourFormat,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatHour(int hour) {
    if (widget.use24HourFormat) {
      return hour.toString().padLeft(2, '0');
    }
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return displayHour.toString();
  }

  void _handleAmPmChanged(bool isAm) {
    setState(() {
      final currentHour = _selectedTime.hour;
      final newHour = isAm
          ? (currentHour >= 12 ? currentHour - 12 : currentHour)
          : (currentHour < 12 ? currentHour + 12 : currentHour);
      
      _selectedTime = TimeOfDay(hour: newHour, minute: _selectedTime.minute);
      widget.onTimeChanged(_selectedTime);
    });
  }
}

class _TimeDisplay extends StatelessWidget {
  final String value;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _TimeDisplay({
    required this.value,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
        ),
        child: Text(
          value,
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _AmPmSwitch extends StatelessWidget {
  final bool isAm;
  final ValueChanged<bool> onChanged;
  final Color color;

  const _AmPmSwitch({
    required this.isAm,
    required this.onChanged,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AmPmButton(
          text: 'AM',
          isSelected: isAm,
          onTap: () => onChanged(true),
          color: color,
        ),
        const SizedBox(height: 4),
        _AmPmButton(
          text: 'PM',
          isSelected: !isAm,
          onTap: () => onChanged(false),
          color: color,
        ),
      ],
    );
  }
}

class _AmPmButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _AmPmButton({
    required this.text,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: isSelected ? color : Colors.transparent,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}

class _CircularPicker extends StatefulWidget {
  final int selectedValue;
  final int maxValue;
  final ValueChanged<int> onValueChanged;
  final Color accentColor;
  final bool isHourMode;
  final bool use24HourFormat;

  const _CircularPicker({
    required this.selectedValue,
    required this.maxValue,
    required this.onValueChanged,
    required this.accentColor,
    required this.isHourMode,
    required this.use24HourFormat,
  });

  @override
  State<_CircularPicker> createState() => _CircularPickerState();
}

class _CircularPickerState extends State<_CircularPicker> {
  // ignore: unused_field
  late double _startAngle;
  late double _currentAngle;

  @override
  void initState() {
    super.initState();
    _updateAngle();
  }

  @override
  void didUpdateWidget(_CircularPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedValue != widget.selectedValue) {
      _updateAngle();
    }
  }

  void _updateAngle() {
    _currentAngle = _startAngle = (widget.selectedValue * 360 / (widget.maxValue + 1)) * (math.pi / 180);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      child: CustomPaint(
        size: const Size(300, 300),
        painter: _CircularPickerPainter(
          selectedValue: widget.selectedValue,
          maxValue: widget.maxValue,
          accentColor: widget.accentColor,
          isHourMode: widget.isHourMode,
          use24HourFormat: widget.use24HourFormat,
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    final box = context.findRenderObject() as RenderBox;
    final center = box.size.center(Offset.zero);
    final position = details.localPosition;
    _startAngle = (math.atan2(position.dy - center.dy, position.dx - center.dx) + math.pi * 2) % (math.pi * 2);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final box = context.findRenderObject() as RenderBox;
    final center = box.size.center(Offset.zero);
    final position = details.localPosition;
    _currentAngle = (math.atan2(position.dy - center.dy, position.dx - center.dx) + math.pi * 2) % (math.pi * 2);

    final anglePercent = _currentAngle / (math.pi * 2);
    final newValue = (anglePercent * (widget.maxValue + 1)).round() % (widget.maxValue + 1);

    if (newValue != widget.selectedValue) {
      widget.onValueChanged(newValue);
    }
  }
}

class _CircularPickerPainter extends CustomPainter {
  final int selectedValue;
  final int maxValue;
  final Color accentColor;
  final bool isHourMode;
  final bool use24HourFormat;

  _CircularPickerPainter({
    required this.selectedValue,
    required this.maxValue,
    required this.accentColor,
    required this.isHourMode,
    required this.use24HourFormat,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Dibujar números
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int i = 0; i <= maxValue; i++) {
      final angle = (i * 360 / (maxValue + 1)) * (math.pi / 180);
      final offset = Offset(
        center.dx + (radius - 30) * math.cos(angle),
        center.dy + (radius - 30) * math.sin(angle),
      );

      String text;
      if (isHourMode) {
        if (use24HourFormat) {
          text = i.toString();
        } else {
          text = (i == 0 ? 12 : i).toString();
        }
      } else {
        text = i.toString().padLeft(2, '0');
      }

      textPainter.text = TextSpan(
        text: text,
        style: TextStyle(
          color: i == selectedValue ? accentColor : Colors.grey,
          fontSize: 16,
          fontWeight: i == selectedValue ? FontWeight.bold : FontWeight.normal,
        ),
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        offset.translate(-textPainter.width / 2, -textPainter.height / 2),
      );
    }

    // Dibujar indicador
    final paint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    final angle = (selectedValue * 360 / (maxValue + 1)) * (math.pi / 180);
    final markerOffset = Offset(
      center.dx + (radius - 30) * math.cos(angle),
      center.dy + (radius - 30) * math.sin(angle),
    );

    canvas.drawCircle(markerOffset, 16, paint);

    // Dibujar línea al centro
    paint.strokeWidth = 2;
    paint.style = PaintingStyle.stroke;
    canvas.drawLine(center, markerOffset, paint);
  }

  @override
  bool shouldRepaint(covariant _CircularPickerPainter oldDelegate) {
    return oldDelegate.selectedValue != selectedValue ||
           oldDelegate.accentColor != accentColor;
  }
}
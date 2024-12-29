import 'package:flutter/material.dart';

class CustomNumpad extends StatelessWidget {
  final Function(String) onNumberTap;
  final VoidCallback onDeleteTap;
  final VoidCallback onDoneTap;
  final bool showDoneButton;
  final String? doneButtonText;
  final Color? numberColor;
  final Color? iconColor;
  final Color? doneButtonColor;

  const CustomNumpad({
    super.key,
    required this.onNumberTap,
    required this.onDeleteTap,
    required this.onDoneTap,
    this.showDoneButton = true,
    this.doneButtonText,
    this.numberColor,
    this.iconColor,
    this.doneButtonColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveNumberColor = numberColor ?? theme.colorScheme.primary;
    final effectiveIconColor = iconColor ?? theme.colorScheme.primary;
    final effectiveDoneButtonColor = doneButtonColor ?? theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumberButton('1', effectiveNumberColor),
              _buildNumberButton('2', effectiveNumberColor),
              _buildNumberButton('3', effectiveNumberColor),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumberButton('4', effectiveNumberColor),
              _buildNumberButton('5', effectiveNumberColor),
              _buildNumberButton('6', effectiveNumberColor),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumberButton('7', effectiveNumberColor),
              _buildNumberButton('8', effectiveNumberColor),
              _buildNumberButton('9', effectiveNumberColor),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSpecialButton(
                icon: Icons.backspace,
                onTap: onDeleteTap,
                color: effectiveIconColor,
              ),
              _buildNumberButton('0', effectiveNumberColor),
              if (showDoneButton)
                _buildSpecialButton(
                  icon: Icons.check,
                  onTap: onDoneTap,
                  color: effectiveDoneButtonColor,
                  text: doneButtonText,
                )
              else
                const SizedBox(width: 70),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumberButton(String number, Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onNumberTap(number),
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 70,
          height: 70,
          alignment: Alignment.center,
          child: Text(
            number,
            style: TextStyle(
              fontSize: 32,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    String? text,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 70,
          height: 70,
          alignment: Alignment.center,
          child: text != null
              ? Text(
                  text,
                  style: TextStyle(
                    fontSize: 18,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
        ),
      ),
    );
  }
}

// Widget de ejemplo para mostrar cómo se usa el CustomNumpad
class TimeInputWithNumpad extends StatefulWidget {
  final void Function(TimeOfDay) onTimeSelected;

  const TimeInputWithNumpad({
    super.key,
    required this.onTimeSelected,
  });

  @override
  State<TimeInputWithNumpad> createState() => _TimeInputWithNumpadState();
}

class _TimeInputWithNumpadState extends State<TimeInputWithNumpad> {
  String _input = '';

  void _handleNumberInput(String number) {
    if (_input.length < 4) {
      setState(() {
        _input += number;
      });
    }
  }

  void _handleDelete() {
    if (_input.isNotEmpty) {
      setState(() {
        _input = _input.substring(0, _input.length - 1);
      });
    }
  }

  void _handleDone() {
    if (_input.length == 4) {
      final hours = int.parse(_input.substring(0, 2));
      final minutes = int.parse(_input.substring(2, 4));
      
      if (hours < 24 && minutes < 60) {
        widget.onTimeSelected(TimeOfDay(hour: hours, minute: minutes));
      } else {
        // Mostrar error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hora inválida. Use formato 24h (0000-2359)'),
          ),
        );
      }
    }
  }

  String get formattedTime {
    if (_input.isEmpty) return '--:--';
    
    final paddedInput = _input.padRight(4, '-');
    return '${paddedInput.substring(0, 2)}:${paddedInput.substring(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            formattedTime,
            style: Theme.of(context).textTheme.displayMedium,
          ),
        ),
        CustomNumpad(
          onNumberTap: _handleNumberInput,
          onDeleteTap: _handleDelete,
          onDoneTap: _handleDone,
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import '../models/alarm.dart';

class AlarmListItem extends StatelessWidget {
  final Alarm alarm;
  final VoidCallback onTap;
  final Function(bool) onToggle;
  final VoidCallback onDelete;

  const AlarmListItem({
    super.key,
    required this.alarm,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(alarm.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        onTap: onTap,
        leading: _buildTimeDisplay(context),
        title: Text(
          alarm.name.isEmpty ? 'Alarma' : alarm.name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: _buildSubtitle(context),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (alarm.requireGame)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Icon(
                  _getGameIcon(),
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            Switch(
              value: alarm.isEnabled,
              onChanged: onToggle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeDisplay(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatTime(alarm.time),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    final TextStyle subtitleStyle = Theme.of(context).textTheme.bodySmall!;
    
    if (alarm.isOneTime) {
      return Text(
        'Una vez',
        style: subtitleStyle,
      );
    }

    final List<String> days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    final List<Widget> dayWidgets = [];

    for (int i = 0; i < 7; i++) {
      dayWidgets.add(
        Text(
          days[i],
          style: subtitleStyle.copyWith(
            color: alarm.weekDays[i]
                ? Theme.of(context).colorScheme.primary
                : subtitleStyle.color,
            fontWeight: alarm.weekDays[i] ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      );

      if (i < 6) {
        dayWidgets.add(const Text(' · '));
      }
    }

    return Row(
      children: dayWidgets,
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  IconData _getGameIcon() {
    if (alarm.selectedGame == 'math') {
      return Icons.calculate;
    } else if (alarm.selectedGame == 'memory') {
      return Icons.grid_view;
    }
    return Icons.games;
  }
}

// Widget de ejemplo para el badge de dificultad
class DifficultyBadge extends StatelessWidget {
  final String difficulty;
  final Color? backgroundColor;
  final Color? textColor;

  const DifficultyBadge({
    super.key,
    required this.difficulty,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBackgroundColor = backgroundColor ?? theme.colorScheme.secondary;
    final effectiveTextColor = textColor ?? theme.colorScheme.onSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        difficulty,
        style: TextStyle(
          color: effectiveTextColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Helper widget for displaying an info box with styled background and icon
class PreviewBox extends StatelessWidget {
  final String text;
  final Color? color;

  const PreviewBox({
    super.key,
    required this.text,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgColor.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: bgColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: bgColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper widget for operator selection chips
class OperatorChip extends StatelessWidget {
  final String operator;
  final String label;
  final String selectedOperator;
  final VoidCallback onTap;

  const OperatorChip({
    super.key,
    required this.operator,
    required this.label,
    required this.selectedOperator,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = operator == selectedOperator;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.primary.withAlpha(50) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor.withAlpha(50),
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  operator,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Theme.of(context).colorScheme.primary : null,
                  ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper widget for negation toggle
class NegationToggle extends StatelessWidget {
  final bool isNegated;
  final VoidCallback onTap;
  final bool enabled;

  const NegationToggle({
    super.key,
    required this.isNegated,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: !enabled
                ? Colors.grey.withAlpha(20)
                : isNegated
                    ? Theme.of(context).colorScheme.error.withAlpha(50)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: !enabled
                  ? Colors.grey.withAlpha(50)
                  : isNegated
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).dividerColor.withAlpha(50),
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.not_interested,
                  size: 20,
                  color: !enabled
                      ? Colors.grey.withAlpha(128)
                      : isNegated
                          ? Theme.of(context).colorScheme.error
                          : Colors.grey,
                ),
                Text(
                  'Negate',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: !enabled
                        ? Colors.grey.withAlpha(128)
                        : isNegated
                            ? Theme.of(context).colorScheme.error
                            : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

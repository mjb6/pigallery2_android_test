import 'package:flutter/material.dart';
import 'search_filter_helpers.dart';

class ResolutionPickerDialog extends StatefulWidget {
  const ResolutionPickerDialog({super.key});

  @override
  State<ResolutionPickerDialog> createState() => _ResolutionPickerDialogState();
}

class _ResolutionPickerDialogState extends State<ResolutionPickerDialog> {
  late int resolutionValue;
  late String operator;
  late bool negated;

  @override
  void initState() {
    super.initState();
    resolutionValue = 10;
    operator = '=';
    negated = false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Resolution Filter',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Search by image resolution in megapixels',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // Resolution value section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withAlpha(128),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).dividerColor.withAlpha(50)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Resolution',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$resolutionValue MP',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Slider(
                      value: resolutionValue.toDouble(),
                      min: 1,
                      max: 50,
                      divisions: 49,
                      label: '$resolutionValue MP',
                      onChanged: (value) => setState(() => resolutionValue = value.toInt()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Operator section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Comparison',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withAlpha(128),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).dividerColor.withAlpha(50)),
                    ),
                    child: GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      children: [
                        OperatorChip(
                          operator: '=',
                          label: 'Equal',
                          selectedOperator: operator,
                          onTap: () => setState(() => operator = '='),
                        ),
                        OperatorChip(
                          operator: '>',
                          label: 'Greater',
                          selectedOperator: operator,
                          onTap: () => setState(() => operator = '>'),
                        ),
                        OperatorChip(
                          operator: '<',
                          label: 'Less',
                          selectedOperator: operator,
                          onTap: () => setState(() => operator = '<'),
                        ),
                        OperatorChip(
                          operator: '>=',
                          label: 'Greater or equal',
                          selectedOperator: operator,
                          onTap: () => setState(() => operator = '>='),
                        ),
                        OperatorChip(
                          operator: '<=',
                          label: 'Less or equal',
                          selectedOperator: operator,
                          onTap: () => setState(() => operator = '<='),
                        ),
                        NegationToggle(
                          isNegated: negated,
                          onTap: () => setState(() => negated = !negated),
                          enabled: operator != '=',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  PreviewBox(
                    text: 'resolution${negated && operator != '=' ? '!' : ''}$operator$resolutionValue',
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () =>
                        Navigator.pop(context, (resolution: resolutionValue.toDouble(), operator: operator, negated: negated)),
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

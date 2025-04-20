import 'package:expense_tracker/helpers/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplitOptions extends StatefulWidget {
  final List<Map<String, String>> members;
  final Map<String, double> initialSplits;
  final String splitType;

  const SplitOptions({
    super.key,
    required this.members,
    required this.initialSplits,
    required this.splitType,
  });

  @override
  State<SplitOptions> createState() => _SplitOptionsState();
}

class _SplitOptionsState extends State<SplitOptions> {
  late Map<String, double> _splits;
  late String _splitType;
  final Map<String, TextEditingController> _controllers = {};
  late double _totalAmount;

  @override
  void initState() {
    super.initState();
    _splits = Map.from(widget.initialSplits);
    _splitType = widget.splitType;
    _totalAmount = Get.arguments['amount'] as double? ?? 0.0;
    for (var member in widget.members) {
      final uid = member['uid']!;
      _controllers[uid] = TextEditingController(
        text: (_splits[uid] ?? 0.0).toStringAsFixed(2),
      );
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateEqualSplit() {
    final share = 1.0 / widget.members.length;
    setState(() {
      _splits = {
        for (final member in widget.members) member['uid']!: share,
      };
      _splitType = 'equal';
      for (var uid in _controllers.keys) {
        _controllers[uid]!.text = share.toStringAsFixed(2);
      }
    });
  }

  void _updateAmountSplit(String userId, String value) {
    final amount = double.tryParse(value) ?? 0.0;
    setState(() {
      _splits[userId] = amount;
      _splitType = 'unequal';
    });
  }

  void _handleDone() {
    if (_splitType == 'unequal') {
      final totalEntered = _splits.values.fold(0.0, (sum, val) => sum + val);
      if ((totalEntered - _totalAmount).abs() > 0.01) {
        showErrorMessage(
          'Invalid Split',
          'The total must equal ${_totalAmount.toStringAsFixed(2)}',
        );
        return;
      }
    }
    Get.back(result: {
      'splits': _splits,
      'splitType': _splitType,
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Split Options'),
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          actions: [
            TextButton(
              onPressed: _handleDone,
              child: const Text('Done'),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _updateEqualSplit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _splitType == 'equal'
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      child: const Text('Equally'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _splitType = 'unequal';
                          final share = _totalAmount / widget.members.length;
                          _splits = {
                            for (final member in widget.members) member['uid']!: share,
                          };
                          for (var uid in _controllers.keys) {
                            _controllers[uid]!.text = share.toStringAsFixed(2);
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _splitType == 'unequal'
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      child: const Text('Unequally'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_splitType == 'unequal')
                ...widget.members.map((member) {
                  final userId = member['uid']!;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member['name']!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _controllers[userId],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) => _updateAmountSplit(userId, value),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
} 
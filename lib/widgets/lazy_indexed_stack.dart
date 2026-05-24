import 'package:flutter/material.dart';

/// [IndexedStack] that only builds tab children after they are first selected.
///
/// Preserves state for visited tabs while avoiding heavy off-tab init (e.g. maps).
class LazyIndexedStack extends StatefulWidget {
  const LazyIndexedStack({
    super.key,
    required this.index,
    required this.itemCount,
    required this.itemBuilder,
  });

  final int index;
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  late Set<int> _visited = {widget.index};

  @override
  void didUpdateWidget(LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.itemCount != oldWidget.itemCount) {
      _visited = _visited.where((i) => i < widget.itemCount).toSet();
    }
    if (widget.index != oldWidget.index ||
        widget.itemCount != oldWidget.itemCount) {
      _visited = {..._visited, widget.index};
    }
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.index,
      children: List.generate(widget.itemCount, (i) {
        if (!_visited.contains(i)) {
          return const SizedBox.shrink();
        }
        return widget.itemBuilder(context, i);
      }),
    );
  }
}

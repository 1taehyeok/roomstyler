import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class PreviewShareScreen extends StatelessWidget {
  const PreviewShareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('결과물 미리보기/공유')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: AspectRatio(
              aspectRatio: 16/9,
              child: Container(
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: const Center(child: Text('최종 렌더(샘플)')),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('A')),
              ButtonSegment(value: 1, label: Text('B')),
            ],
            selected: const {0}, // TODO: A/B 비교
            onSelectionChanged: (_) {},
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            icon: const Icon(Icons.share),
            label: const Text('공유하기'),
            onPressed: () => Share.share('내 인테리어 결과물!'),
          ),
        ],
      ),
    );
  }
}

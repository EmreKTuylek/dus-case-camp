import 'package:flutter/material.dart';
import '../models/case_model.dart';
import '../utils/time_utils.dart'; // Will create simple utility

class ChapterList extends StatelessWidget {
  final List<Chapter> chapters;
  final Function(int) onChapterTap;

  const ChapterList({
    super.key,
    required this.chapters,
    required this.onChapterTap,
  });

  String _formatTime(int seconds) {
    final duration = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    if (chapters.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Chapters',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 50,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: chapters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final chapter = chapters[index];
              return ActionChip(
                label: Text(
                    '${_formatTime(chapter.timestampSeconds)} ${chapter.label}'),
                onPressed: () => onChapterTap(chapter.timestampSeconds),
                avatar: const Icon(Icons.bookmark_border, size: 16),
              );
            },
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Offline/Hive/chapter.dart';
import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/widgets/custom_widgets/anymex_button.dart';
import 'package:anymex/widgets/custom_widgets/anymex_dialog.dart';
import 'package:anymex/utils/performance.dart';

/// Comprehensive reading statistics and progress tracking
class ReadingStatsManager {
  static ReadingStatsManager? _instance;
  static ReadingStatsManager get instance => _instance ??= ReadingStatsManager._();
  
  ReadingStatsManager._();
  
  Future<ReadingStats> getReadingStats(String mediaId) async {
    final offlineStorage = Get.find<OfflineStorageController>();
    final media = offlineStorage.getMedia(mediaId);
    
    if (media == null) {
      return ReadingStats.empty();
    }
    
    final chapters = media.chapters ?? [];
    final readChapters = chapters.where((ch) => ch.lastReadTime != null).toList();
    
    int totalPagesRead = 0;
    int totalChaptersRead = readChapters.length;
    Duration totalTimeSpent = Duration.zero;
    
    for (final chapter in readChapters) {
      if (chapter.pageNumber != null && chapter.totalPages != null) {
        totalPagesRead += chapter.pageNumber!;
        totalTimeSpent += Duration(
          milliseconds: chapter.lastReadTime! - (chapter.firstReadTime ?? chapter.lastReadTime!),
        );
      }
    }
    
    return ReadingStats(
      mediaId: mediaId,
      totalPagesRead: totalPagesRead,
      totalChaptersRead: totalChaptersRead,
      totalTimeSpent: totalTimeSpent,
      averageReadingSpeed: totalPagesRead > 0 ? totalTimeSpent.inMinutes / totalPagesRead : 0.0,
      lastReadDate: readChapters.isNotEmpty 
          ? DateTime.fromMillisecondsSinceEpoch(readChapters.last.lastReadTime!)
          : null,
      readingStreak: _calculateReadingStreak(readChapters),
    );
  }
  
  int _calculateReadingStreak(List<Chapter> readChapters) {
    if (readChapters.isEmpty) return 0;
    
    int streak = 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    for (final chapter in readChapters.reversed) {
      if (chapter.lastReadTime == null) continue;
      
      final readDate = DateTime.fromMillisecondsSinceEpoch(chapter.lastReadTime!);
      final readDay = DateTime(readDate.year, readDate.month, readDate.day);
      
      final difference = today.difference(readDay).inDays;
      if (difference <= 1) {
        streak++;
        today = readDay;
      } else {
        break;
      }
    }
    
    return streak;
  }
}

class ReadingStats {
  final String mediaId;
  final int totalPagesRead;
  final int totalChaptersRead;
  final Duration totalTimeSpent;
  final double averageReadingSpeed;
  final DateTime? lastReadDate;
  final int readingStreak;
  
  const ReadingStats({
    required this.mediaId,
    required this.totalPagesRead,
    required this.totalChaptersRead,
    required this.totalTimeSpent,
    required this.averageReadingSpeed,
    this.lastReadDate,
    required this.readingStreak,
  });
  
  static ReadingStats empty() {
    return const ReadingStats(
      mediaId: '',
      totalPagesRead: 0,
      totalChaptersRead: 0,
      totalTimeSpent: Duration.zero,
      averageReadingSpeed: 0.0,
      lastReadDate: null,
      readingStreak: 0,
    );
  }
}

/// Reading goals and achievements system
class ReadingGoalsManager {
  static ReadingGoalsManager? _instance;
  static ReadingGoalsManager get instance => _instance ??= ReadingGoalsManager._();
  
  ReadingGoalsManager._();
  
  final List<ReadingGoal> _goals = [];
  
  void addGoal(ReadingGoal goal) {
    _goals.add(goal);
  }
  
  List<ReadingGoal> getActiveGoals() {
    return _goals.where((goal) => !goal.isCompleted).toList();
  }
  
  List<Achievement> checkAchievements(ReadingStats stats) {
    final achievements = <Achievement>[];
    
    // Check for various achievements
    if (stats.totalPagesRead >= 1000) {
      achievements.add(Achievement(
        id: 'page_master',
        title: 'Page Master',
        description: 'Read 1000 pages',
        icon: Icons.auto_stories,
        unlockedAt: DateTime.now(),
      ));
    }
    
    if (stats.totalChaptersRead >= 50) {
      achievements.add(Achievement(
        id: 'chapter_explorer',
        title: 'Chapter Explorer',
        description: 'Read 50 chapters',
        icon: Icons.book,
        unlockedAt: DateTime.now(),
      ));
    }
    
    if (stats.readingStreak >= 30) {
      achievements.add(Achievement(
        id: 'dedicated_reader',
        title: 'Dedicated Reader',
        description: '30 day reading streak',
        icon: Icons.local_fire_department,
        unlockedAt: DateTime.now(),
      ));
    }
    
    return achievements;
  }
}

class ReadingGoal {
  final String id;
  final String title;
  final String description;
  final int target;
  final int current;
  final DateTime deadline;
  final bool isCompleted;
  
  ReadingGoal({
    required this.id,
    required this.title,
    required this.description,
    required this.target,
    required this.current,
    required this.deadline,
    required this.isCompleted,
  });
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final DateTime unlockedAt;
  
  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.unlockedAt,
  });
}

/// Comprehensive reading statistics screen
class ReadingStatsScreen extends StatefulWidget {
  final Media media;
  
  const ReadingStatsScreen({
    Key? key,
    required this.media,
  }) : super(key: key);

  @override
  State<ReadingStatsScreen> createState() => _ReadingStatsScreenState();
}

class _ReadingStatsScreenState extends State<ReadingStatsScreen> {
  ReadingStats? _stats;
  List<Achievement> _achievements = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadStats();
  }
  
  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    
    try {
      _stats = await ReadingStatsManager.instance.getReadingStats(widget.media.id);
      _achievements = ReadingGoalsManager.instance.checkAchievements(_stats!);
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading Statistics'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _isLoading
          ? _buildLoadingView()
          : _buildContentView(),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildContentView() {
    if (_stats == null) {
      return _buildEmptyView();
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewCard(),
          const SizedBox(height: 16),
          _buildProgressCard(),
          const SizedBox(height: 16),
          _buildTimeStatsCard(),
          const SizedBox(height: 16),
          _buildAchievementsCard(),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.auto_stories_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No reading data available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reading Overview',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              'Total Pages Read',
              '${_stats!.totalPagesRead}',
              Icons.auto_stories,
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              'Total Chapters Read',
              '${_stats!.totalChaptersRead}',
              Icons.book,
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              'Reading Streak',
              '${_stats!.readingStreak} days',
              Icons.local_fire_department,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildProgressBar(
              'Chapters Completed',
              _stats!.totalChaptersRead,
              widget.media.chapters?.length ?? 0,
            ),
            const SizedBox(height: 12),
            Text(
              '${_stats!.totalChaptersRead} of ${widget.media.chapters?.length ?? 0} chapters completed',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Time Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              'Total Time Spent',
              _formatDuration(_stats!.totalTimeSpent),
              Icons.access_time,
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              'Average Speed',
              '${_stats!.averageReadingSpeed.toStringAsFixed(1)} min/page',
              Icons.speed,
            ),
            if (_stats!.lastReadDate != null) ...[
              const SizedBox(height: 12),
              _buildStatRow(
                'Last Read',
                _formatDate(_stats!.lastReadDate!),
                Icons.calendar_today,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Achievements',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (_achievements.isEmpty)
              const Text(
                'Keep reading to unlock achievements!',
                style: TextStyle(color: Colors.grey),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _achievements.map((achievement) => _buildAchievementChip(achievement)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(String label, int current, int total) {
    final progress = total > 0 ? current / total : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 4),
        Text(
          '${(progress * 100).toInt()}%',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildAchievementChip(Achievement achievement) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            achievement.icon,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  achievement.title,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  achievement.description,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../projects/providers/project_provider.dart';
import '../../projects/models/project_model.dart';
import '../../tasks/models/task_model.dart';
import '../../tasks/providers/task_provider.dart';
import '../../../shared/widgets/common_widgets.dart';

class DeadlinesScreen extends StatefulWidget {
  const DeadlinesScreen({super.key});

  @override
  State<DeadlinesScreen> createState() => _DeadlinesScreenState();
}

class _DeadlinesScreenState extends State<DeadlinesScreen> {
  List<TaskModel> _tasks = [];
  List<ProjectModel> _projects = [];
  bool _loading = true;
  String _searchQuery = '';
  String _projectFilter = 'All Projects';
  String _statusFilter = 'All Status';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid =
        context.read<AuthProvider>().user?.uid ?? '';
    final pp = context.read<ProjectProvider>();
    await pp.loadUserProjects(uid);

    final projects = pp.projects;
    final ids = projects.map((p) => p.id).toList();

    final tasks =
        await context.read<TaskProvider>().getTasksForProjects(ids);

    if (mounted) {
      setState(() {
        _projects = projects;
        _tasks = tasks;
        _loading = false;
      });
    }
  }

  List<String> get _projectFilterOptions =>
      ['All Projects', ..._projects.map((p) => p.title)];

  List<String> get _statusFilterOptions =>
      ['All Status', 'To Do', 'In Progress', 'Done'];

  List<TaskModel> get _filtered {
    List<TaskModel> list = _tasks;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((t) =>
              t.title.toLowerCase().contains(q) ||
              t.projectName.toLowerCase().contains(q))
          .toList();
    }
    if (_projectFilter != 'All Projects') {
      list = list
          .where((t) => t.projectName == _projectFilter)
          .toList();
    }
    if (_statusFilter != 'All Status') {
      list = list.where((t) => t.status == _statusFilter).toList();
    }
    // Sort by due date ascending
    list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Purple header
            Container(
              color: AppColors.primary,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Deadlines',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Upcoming tasks across all projects',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 16, 16, 12),
                              child: AppSearchBar(
                                hint: 'Search deadlines...',
                                onChanged: (v) =>
                                    setState(() => _searchQuery = v),
                              ),
                            ),
                          ),
                          // Project filter chips
                          SliverToBoxAdapter(
                            child: FilterChipRow(
                              options: _projectFilterOptions,
                              selected: _projectFilter,
                              onSelected: (v) =>
                                  setState(() => _projectFilter = v),
                            ),
                          ),
                          const SliverToBoxAdapter(
                              child: SizedBox(height: 8)),
                          // Status filter chips
                          SliverToBoxAdapter(
                            child: FilterChipRow(
                              options: _statusFilterOptions,
                              selected: _statusFilter,
                              onSelected: (v) =>
                                  setState(() => _statusFilter = v),
                            ),
                          ),
                          const SliverToBoxAdapter(
                              child: SizedBox(height: 16)),
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16),
                            sliver: _filtered.isEmpty
                                ? const SliverToBoxAdapter(
                                    child: _EmptyDeadlines())
                                : SliverList(
                                    delegate:
                                        SliverChildBuilderDelegate(
                                      (ctx, i) {
                                        final task = _filtered[i];
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(
                                                  bottom: 10),
                                          child: _DeadlineCard(
                                              task: task),
                                        );
                                      },
                                      childCount: _filtered.length,
                                    ),
                                  ),
                          ),
                          const SliverToBoxAdapter(
                              child: SizedBox(height: 20)),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeadlineCard extends StatelessWidget {
  final TaskModel task;
  const _DeadlineCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isOverdue = task.dueDate.isBefore(now) && !task.isDone;
    final dateColor =
        isOverdue ? AppColors.deadlinePastText : AppColors.primary;
    final dateBg =
        isOverdue ? AppColors.deadlinePast : AppColors.deadlineNormal;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: dateBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 12, color: dateColor),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(task.dueDate),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: dateColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.folder_outlined,
                  size: 13, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                task.projectName,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              InitialsAvatar(
                  initials: task.assigneeInitials, radius: 11),
              const SizedBox(width: 6),
              Text(
                task.assigneeName,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              const Spacer(),
              StatusBadge(status: task.status),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }
}

class _EmptyDeadlines extends StatelessWidget {
  const _EmptyDeadlines();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.avatarBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.event_available_outlined,
                color: AppColors.primary, size: 36),
          ),
          const SizedBox(height: 16),
          const Text(
            'No deadlines found',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'All caught up!',
            style: TextStyle(
                fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

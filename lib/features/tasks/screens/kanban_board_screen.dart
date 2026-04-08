import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../projects/models/project_model.dart';
import '../../projects/screens/add_member_screen.dart';
import '../../tasks/models/task_model.dart';
import '../../tasks/providers/task_provider.dart';
import '../../tasks/screens/task_details_screen.dart';
import '../../tasks/screens/add_edit_task_screen.dart';
import '../../../shared/widgets/common_widgets.dart';

class KanbanBoardScreen extends StatefulWidget {
  final ProjectModel project;
  const KanbanBoardScreen({super.key, required this.project});

  @override
  State<KanbanBoardScreen> createState() => _KanbanBoardScreenState();
}

class _KanbanBoardScreenState extends State<KanbanBoardScreen> {
  String _selectedFilter = 'Everyone';
  String _searchQuery = '';

  List<String> _filterOptions(List<TaskModel> tasks) {
    final names = tasks.map((t) => t.assigneeName.split(' ').first).toSet();
    return ['Everyone', ...names];
  }

  List<TaskModel> _filtered(List<TaskModel> all) {
    List<TaskModel> list = all;
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((t) =>
              t.title.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    if (_selectedFilter != 'Everyone') {
      list = list
          .where((t) =>
              t.assigneeName.startsWith(_selectedFilter))
          .toList();
    }
    return list;
  }

  int _completed(List<TaskModel> tasks) =>
      tasks.where((t) => t.isDone).length;

  int _inProgress(List<TaskModel> tasks) =>
      tasks.where((t) => t.status == 'In Progress').length;

  int _pending(List<TaskModel> tasks) =>
      tasks.where((t) => t.status == 'To Do').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<TaskModel>>(
        stream: context
            .read<TaskProvider>()
            .watchProjectTasks(widget.project.id),
        builder: (context, snapshot) {
          final allTasks = snapshot.data ?? [];
          final filtered = _filtered(allTasks);

          final todoTasks =
              filtered.where((t) => t.status == 'To Do').toList();
          final inProgressTasks =
              filtered.where((t) => t.status == 'In Progress').toList();
          final doneTasks =
              filtered.where((t) => t.isDone).toList();

          final total = allTasks.length;
          final done = _completed(allTasks);
          final progress = total == 0 ? 0.0 : done / total;

          return CustomScrollView(
            slivers: [
              // Custom purple header
              SliverAppBar(
                expandedHeight: 110,
                pinned: true,
                backgroundColor: AppColors.primary,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                actions: [
                  IconButton(
                    tooltip: 'Add Member',
                    icon: const Icon(Icons.person_add_outlined,
                        color: Colors.white),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            AddMemberScreen(project: widget.project),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  title: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.project.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Text(
                        'Kanban Board',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Progress card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _ProgressCard(
                    progress: progress,
                    completed: done,
                    inProgress: _inProgress(allTasks),
                    pending: _pending(allTasks),
                  ),
                ),
              ),
              // Search
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: AppSearchBar(
                    hint: 'Search tasks...',
                    onChanged: (v) =>
                        setState(() => _searchQuery = v),
                  ),
                ),
              ),
              // Member chips
              SliverToBoxAdapter(
                child: FilterChipRow(
                  options: _filterOptions(allTasks),
                  selected: _selectedFilter,
                  onSelected: (v) =>
                      setState(() => _selectedFilter = v),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              // Kanban columns
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      if (todoTasks.isNotEmpty ||
                          _selectedFilter == 'Everyone')
                        _KanbanColumn(
                          status: 'To Do',
                          tasks: todoTasks,
                          project: widget.project,
                          dotColor: AppColors.textMuted,
                        ),
                      if (inProgressTasks.isNotEmpty ||
                          _selectedFilter == 'Everyone')
                        _KanbanColumn(
                          status: 'In Progress',
                          tasks: inProgressTasks,
                          project: widget.project,
                          dotColor: AppColors.primary,
                        ),
                      if (doneTasks.isNotEmpty ||
                          _selectedFilter == 'Everyone')
                        _KanbanColumn(
                          status: 'Done',
                          tasks: doneTasks,
                          project: widget.project,
                          dotColor: const Color(0xFF059669),
                        ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                AddEditTaskScreen(project: widget.project),
          ),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final double progress;
  final int completed;
  final int inProgress;
  final int pending;

  const _ProgressCard({
    required this.progress,
    required this.completed,
    required this.inProgress,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Overall Progress',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary)),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.progressBarBg,
              color: AppColors.progressBar,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _statBadge('$completed completed', const Color(0xFF059669)),
              const SizedBox(width: 8),
              _statBadge('$inProgress in progress', AppColors.primary),
              const SizedBox(width: 8),
              _statBadge('$pending pending', AppColors.textMuted),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBadge(String label, Color color) => Text(
        label,
        style: TextStyle(fontSize: 12, color: color),
      );
}

class _KanbanColumn extends StatelessWidget {
  final String status;
  final List<TaskModel> tasks;
  final ProjectModel project;
  final Color dotColor;

  const _KanbanColumn({
    required this.status,
    required this.tasks,
    required this.project,
    required this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                status,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.badgeToDo,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${tasks.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddEditTaskScreen(
                        project: project,
                        initialStatus: status),
                  ),
                ),
                child: const Icon(Icons.add,
                    color: AppColors.textSecondary, size: 22),
              ),
            ],
          ),
        ),
        ...tasks.map(
          (task) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _TaskCard(task: task),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TaskDetailsScreen(task: task),
        ),
      ),
      child: Container(
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
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                StatusBadge(status: task.status),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                InitialsAvatar(
                    initials: task.assigneeInitials, radius: 12),
                const SizedBox(width: 6),
                Text(
                  task.assigneeName,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                const Spacer(),
                const Icon(Icons.calendar_today_outlined,
                    size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  _formatShortDate(task.dueDate),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatShortDate(DateTime d) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }
}

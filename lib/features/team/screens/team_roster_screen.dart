import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../projects/providers/project_provider.dart';
import '../../projects/models/project_model.dart';
import '../../projects/services/project_service.dart';
import '../../../shared/widgets/common_widgets.dart';

class TeamRosterScreen extends StatefulWidget {
  const TeamRosterScreen({super.key});

  @override
  State<TeamRosterScreen> createState() => _TeamRosterScreenState();
}

class _TeamRosterScreenState extends State<TeamRosterScreen> {
  List<Map<String, dynamic>> _allMembers = [];
  List<ProjectModel> _userProjects = [];
  bool _loading = true;
  String _searchQuery = '';
  String _roleFilter = 'All Roles';
  List<String> _roles = ['All Roles'];
  StreamSubscription<List<ProjectModel>>? _sub;

  @override
  void initState() {
    super.initState();
    _subscribeToProjects();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _subscribeToProjects() {
    final uid = context.read<AuthProvider>().user?.uid ?? '';
    _sub = context
        .read<ProjectProvider>()
        .watchUserProjects(uid)
        .listen((projects) {
      _userProjects = projects;
      _loadMembersFromProjects(projects);
    });
  }

  Future<void> _loadMembersFromProjects(List<ProjectModel> projects) async {
    final allMemberIds = <String>{};
    for (final p in projects) {
      allMemberIds.addAll(p.memberIds);
    }

    if (allMemberIds.isEmpty) {
      if (mounted) {
        setState(() {
          _allMembers = [];
          _loading = false;
        });
      }
      return;
    }

    final members =
        await ProjectService().getProjectMembers(allMemberIds.toList());

    final roles = members
        .map((m) => m['role'] as String? ?? '')
        .where((r) => r.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    if (mounted) {
      setState(() {
        _allMembers = members;
        _roles = ['All Roles', ...roles];
        _loading = false;
      });
    }
  }

  /// Returns project names shared between the current user and [memberUid].
  List<String> _sharedProjectNames(String memberUid) {
    return _userProjects
        .where((p) => p.memberIds.contains(memberUid))
        .map((p) => p.title)
        .toList();
  }

  List<Map<String, dynamic>> get _filtered {
    List<Map<String, dynamic>> list = _allMembers;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((m) =>
              (m['fullName'] as String? ?? '').toLowerCase().contains(q) ||
              (m['studentId'] as String? ?? '').toLowerCase().contains(q))
          .toList();
    }
    if (_roleFilter != 'All Roles') {
      list =
          list.where((m) => (m['role'] as String?) == _roleFilter).toList();
    }
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
              width: double.infinity,
              color: AppColors.primary,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Team Roster',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_allMembers.length} member${_allMembers.length == 1 ? '' : 's'} across ${_userProjects.length} project${_userProjects.length == 1 ? '' : 's'}',
                    style: const TextStyle(
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
                  : CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 16, 16, 12),
                            child: AppSearchBar(
                              hint: 'Search by name or ID...',
                              onChanged: (v) =>
                                  setState(() => _searchQuery = v),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: FilterChipRow(
                            options: _roles,
                            selected: _roleFilter,
                            onSelected: (v) =>
                                setState(() => _roleFilter = v),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 16)),
                        SliverPadding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          sliver: _filtered.isEmpty
                              ? const SliverToBoxAdapter(child: _EmptyTeam())
                              : SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (ctx, i) {
                                      final m = _filtered[i];
                                      final uid = m['uid'] as String? ?? '';
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                            bottom: 10),
                                        child: _MemberCard(
                                          member: m,
                                          sharedProjects:
                                              _sharedProjectNames(uid),
                                        ),
                                      );
                                    },
                                    childCount: _filtered.length,
                                  ),
                                ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 20)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final Map<String, dynamic> member;
  final List<String> sharedProjects;
  const _MemberCard({required this.member, required this.sharedProjects});

  String get _initials {
    final name = (member['fullName'] as String? ?? '').trim();
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '??';
  }

  @override
  Widget build(BuildContext context) {
    final name = member['fullName'] as String? ?? '';
    final role = member['role'] as String? ?? '';
    final studentId = member['studentId'] as String? ?? '';

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
            children: [
              InitialsAvatar(initials: _initials, radius: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (studentId.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.badgeToDo,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    studentId,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          if (sharedProjects.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, thickness: 1),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.folder_outlined,
                    size: 13, color: AppColors.textMuted),
                const SizedBox(width: 5),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: sharedProjects
                        .map(
                          (title) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.avatarBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyTeam extends StatelessWidget {
  const _EmptyTeam();

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
            child: const Icon(Icons.people_outline,
                color: AppColors.primary, size: 36),
          ),
          const SizedBox(height: 16),
          const Text(
            'No team members found',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

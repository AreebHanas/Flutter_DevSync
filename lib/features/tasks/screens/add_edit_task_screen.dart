import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../projects/models/project_model.dart';
import '../../projects/services/project_service.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../../../shared/widgets/common_widgets.dart';

const List<String> _statuses = ['To Do', 'In Progress', 'Done'];

class AddEditTaskScreen extends StatefulWidget {
  final ProjectModel? project;
  final TaskModel? existingTask;
  final String? initialStatus;

  const AddEditTaskScreen({
    super.key,
    this.project,
    this.existingTask,
    this.initialStatus,
  });

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  late String _status;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  String? _assignedTo;
  String? _assigneeName;
  String? _assigneeInitials;
  String? _assigneeRole;

  List<Map<String, dynamic>> _members = [];
  bool _loadingMembers = true;
  bool _saving = false;

  bool get isEditing => widget.existingTask != null;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus ??
        widget.existingTask?.status ??
        'To Do';
    if (isEditing) {
      final t = widget.existingTask!;
      _titleCtrl.text = t.title;
      _dueDate = t.dueDate;
      _assignedTo = t.assignedTo;
      _assigneeName = t.assigneeName;
      _assigneeInitials = t.assigneeInitials;
      _assigneeRole = t.assigneeRole;
    }
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    List<String> memberIds;
    if (widget.project != null) {
      memberIds = widget.project!.memberIds;
    } else if (isEditing) {
      final proj = await ProjectService()
          .getProject(widget.existingTask!.projectId);
      memberIds = proj.memberIds;
    } else {
      memberIds = [];
    }
    if (!mounted) return;
    final members = await ProjectService().getProjectMembers(memberIds);
    setState(() {
      _members = members;
      _loadingMembers = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_assignedTo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an assignee')),
      );
      return;
    }
    setState(() => _saving = true);
    final tp = context.read<TaskProvider>();

    if (isEditing) {
      final updated = widget.existingTask!.copyWith(
        title: _titleCtrl.text.trim(),
        status: _status,
        dueDate: _dueDate,
        assignedTo: _assignedTo,
        assigneeName: _assigneeName,
        assigneeInitials: _assigneeInitials,
        assigneeRole: _assigneeRole,
      );
      await tp.updateTask(
          oldTask: widget.existingTask!, newTask: updated);
    } else {
      final proj = widget.project!;
      final newTask = TaskModel(
        id: '',
        projectId: proj.id,
        projectName: proj.title,
        title: _titleCtrl.text.trim(),
        status: _status,
        dueDate: _dueDate,
        assignedTo: _assignedTo!,
        assigneeName: _assigneeName!,
        assigneeInitials: _assigneeInitials!,
        assigneeRole: _assigneeRole!,
      );
      await tp.addTask(newTask);
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Task' : 'New Task'),
        backgroundColor: AppColors.primary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Task Title'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                      hintText: 'Enter task description'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 18),
                _label('Status'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(),
                  items: _statuses
                      .map((s) => DropdownMenuItem(
                          value: s,
                          child: Row(
                            children: [
                              StatusBadge(status: s),
                            ],
                          )))
                      .toList(),
                  onChanged: (v) => setState(() => _status = v!),
                ),
                const SizedBox(height: 18),
                _label('Due Date'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            color: AppColors.textMuted, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          '${_dueDate.year}-${_dueDate.month.toString().padLeft(2, '0')}-${_dueDate.day.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _label('Assign To'),
                const SizedBox(height: 8),
                _loadingMembers
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<String>(
                        value: _assignedTo,
                        hint: const Text('Select team member'),
                        decoration: const InputDecoration(),
                        items: _members
                            .map((m) => DropdownMenuItem<String>(
                                  value: m['uid'] as String,
                                  child: Text(
                                    m['fullName'] as String? ?? '',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ))
                            .toList(),
                        onChanged: (uid) {
                          if (uid == null) return;
                          final member = _members.firstWhere(
                              (m) => m['uid'] == uid);
                          final name =
                              member['fullName'] as String? ?? '';
                          final parts = name.trim().split(' ');
                          final initials = parts.length >= 2
                              ? '${parts[0][0]}${parts[1][0]}'
                                  .toUpperCase()
                              : name.isNotEmpty
                                  ? name[0].toUpperCase()
                                  : '??';
                          setState(() {
                            _assignedTo = uid;
                            _assigneeName = name;
                            _assigneeInitials = initials;
                            _assigneeRole =
                                member['role'] as String? ?? '';
                          });
                        },
                      ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white))
                        : Text(isEditing ? 'Save Changes' : 'Add Task'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      );
}

import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' as m;

import '../../../core/components/app_components.dart';
import '../../../core/domain/value_objects.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/localization/localization.dart';
import '../domain/candidates.dart';

class CandidateFilters extends StatefulWidget {
  const CandidateFilters({
    super.key,
    required this.initial,
    required this.dictionaries,
    required this.apply,
  });
  final CandidateFilter initial;
  final Dictionaries dictionaries;
  final ValueChanged<CandidateFilter> apply;
  @override
  State<CandidateFilters> createState() => _CandidateFiltersState();
}

class _CandidateFiltersState extends State<CandidateFilters> {
  late final _skill = TextEditingController(text: widget.initial.skill);
  late final _salary = TextEditingController(
    text: widget.initial.maxSalary?.amount.toString(),
  );
  late String _discipline = widget.initial.discipline ?? '';
  late String _level = widget.initial.minLevel ?? '';
  late String _team = widget.initial.teamRole ?? '';
  late String _grade = widget.initial.grade?.name ?? '';
  late String _format = widget.initial.workFormat?.name ?? '';
  late bool _verified = widget.initial.verifiedOnly;
  AppFailure? _failure;
  @override
  void dispose() {
    _skill.dispose();
    _salary.dispose();
    super.dispose();
  }

  Map<String, String> _options(String group) => {
    '': context.l.all,
    for (final option in widget.dictionaries.options(group))
      option.code: context.referenceLabel(option.code, fallback: option.label),
  };
  void _apply() {
    try {
      final amount = _salary.text.trim().isEmpty
          ? null
          : int.tryParse(_salary.text);
      if (_salary.text.trim().isNotEmpty && amount == null) {
        throw const AppFailure(FailureKind.validation, 'invalid_salary');
      }
      widget.apply(
        CandidateFilter(
          discipline: _discipline.isEmpty ? null : _discipline,
          minLevel: _level.isEmpty ? null : _level,
          teamRole: _team.isEmpty ? null : _team,
          grade: Grade.values.where((g) => g.name == _grade).firstOrNull,
          workFormat: WorkFormat.values
              .where((f) => f.name == _format)
              .firstOrNull,
          skill: _skill.text.trim().isEmpty ? null : _skill.text.trim(),
          maxSalary: amount == null ? null : Salary(amount),
          verifiedOnly: _verified,
        ),
      );
    } on AppFailure catch (error) {
      setState(() => _failure = error);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AppSectionHeader(title: context.l.filters),
      AppSelect<String>(
        label: context.l.discipline,
        value: _discipline,
        options: _options('disciplines'),
        onChanged: (v) => setState(() => _discipline = v ?? ''),
      ),
      const SizedBox(height: 16),
      AppSelect<String>(
        label: context.l.level,
        value: _level,
        options: _options('verification_levels'),
        onChanged: (v) => setState(() => _level = v ?? ''),
      ),
      const SizedBox(height: 16),
      AppSelect<String>(
        label: context.l.grade,
        value: _grade,
        options: {
          '': context.l.all,
          for (final grade in Grade.values)
            grade.name: context.gradeLabel(grade),
        },
        onChanged: (v) => setState(() => _grade = v ?? ''),
      ),
      const SizedBox(height: 16),
      AppSelect<String>(
        label: context.l.teamRole,
        value: _team,
        options: _options('team_roles'),
        onChanged: (v) => setState(() => _team = v ?? ''),
      ),
      const SizedBox(height: 16),
      AppSelect<String>(
        label: context.l.workFormat,
        value: _format,
        options: {
          '': context.l.all,
          for (final f in WorkFormat.values) f.name: context.formatLabel(f),
        },
        onChanged: (v) => setState(() => _format = v ?? ''),
      ),
      const SizedBox(height: 16),
      AppTextField(label: context.l.skill, controller: _skill),
      const SizedBox(height: 16),
      AppTextField(
        label: context.l.maxSalary,
        controller: _salary,
        keyboardType: TextInputType.number,
      ),
      m.CheckboxListTile(
        value: _verified,
        title: Text(context.l.verifiedOnly),
        contentPadding: EdgeInsets.zero,
        onChanged: (v) => setState(() => _verified = v ?? false),
      ),
      if (_failure != null) Text(context.failureLabel(_failure!)),
      AppButton(label: context.l.apply, onPressed: _apply),
      const SizedBox(height: 8),
      AppButton(
        label: context.l.clear,
        secondary: true,
        onPressed: () {
          setState(() {
            _discipline = '';
            _level = '';
            _team = '';
            _grade = '';
            _format = '';
            _skill.clear();
            _salary.clear();
            _verified = false;
          });
          widget.apply(const CandidateFilter());
        },
      ),
    ],
  );
}

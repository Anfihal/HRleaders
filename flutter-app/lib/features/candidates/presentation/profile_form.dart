import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart' as m;

import '../../../core/components/app_components.dart';
import '../../../core/domain/value_objects.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/localization/localization.dart';
import '../../../core/presentation/resource_state.dart';
import '../domain/candidates.dart';
import 'profile_bloc.dart';

class ProfileForm extends StatefulWidget {
  const ProfileForm({super.key, required this.profile});
  final Candidate profile;
  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  late final _name = TextEditingController(text: widget.profile.name);
  late final _headline = TextEditingController(text: widget.profile.headline);
  late final _city = TextEditingController(text: widget.profile.city);
  late final _salary = TextEditingController(
    text: widget.profile.salary?.amount.toString(),
  );
  late final _skills = TextEditingController(
    text: widget.profile.skills.join(', '),
  );
  late final _about = TextEditingController(text: widget.profile.about);
  late final _fsp = TextEditingController(text: widget.profile.fspId);
  late String _grade = widget.profile.grade?.name ?? '';
  late String _format = widget.profile.workFormat?.name ?? '';
  late String _team = widget.profile.teamRole ?? '';
  late bool _available = widget.profile.openToOffers;
  AppFailure? _failure;
  @override
  void dispose() {
    for (final c in [_name, _headline, _city, _salary, _skills, _about, _fsp]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    try {
      final amount = _salary.text.isEmpty ? null : int.tryParse(_salary.text);
      if (_salary.text.isNotEmpty && amount == null) {
        throw const AppFailure(FailureKind.validation, 'invalid_salary');
      }
      context.read<ProfileBloc>().save(
        ProfileDraft(
          name: _name.text,
          headline: _headline.text,
          city: _city.text,
          salary: amount == null ? null : Salary(amount),
          skills: _skills.text
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList(),
          about: _about.text,
          fspId: _fsp.text.trim().isEmpty ? null : _fsp.text.trim(),
          openToOffers: _available,
          grade: Grade.values.where((g) => g.name == _grade).firstOrNull,
          workFormat: WorkFormat.values
              .where((f) => f.name == _format)
              .firstOrNull,
          teamRole: _team.isEmpty ? null : _team,
        ),
      );
    } on AppFailure catch (error) {
      setState(() => _failure = error);
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<ProfileBloc, ResourceState<Candidate>>(
    listener: (context, state) {
      if (state.saved) Navigator.of(context).pop();
    },
    builder: (context, state) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(label: context.l.fullName, controller: _name),
        const SizedBox(height: 16),
        AppTextField(label: context.l.headline, controller: _headline),
        const SizedBox(height: 16),
        AppTextField(label: context.l.city, controller: _city),
        const SizedBox(height: 16),
        BlocBuilder<ResourceBloc<Dictionaries>, ResourceState<Dictionaries>>(
          builder: (context, state) => ResourceView(
            state: state,
            retry: context.read<ResourceBloc<Dictionaries>>().load,
            builder: (dictionaries) => AppSelect<String>(
              label: context.l.teamRole,
              value: _team,
              options: {
                '': context.l.all,
                if (_team.isNotEmpty)
                  _team: dictionaries.label('team_roles', _team),
                for (final option in dictionaries.options('team_roles'))
                  option.code: option.label,
              },
              onChanged: (value) => setState(() => _team = value ?? ''),
            ),
          ),
        ),
        const SizedBox(height: 16),
        AppSelect<String>(
          label: context.l.grade,
          value: _grade,
          options: {
            '': context.l.all,
            for (final g in Grade.values) g.name: context.gradeLabel(g),
          },
          onChanged: (v) => setState(() => _grade = v ?? ''),
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
        AppTextField(
          label: context.l.salaryExpectation,
          controller: _salary,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        AppTextField(label: context.l.skills, controller: _skills),
        const SizedBox(height: 16),
        AppTextField(label: context.l.about, controller: _about, lines: 3),
        const SizedBox(height: 16),
        AppTextField(label: context.l.fspId, controller: _fsp),
        m.CheckboxListTile(
          value: _available,
          title: Text(context.l.availability),
          onChanged: (v) => setState(() => _available = v ?? false),
        ),
        if (_failure != null || state.failure != null)
          Text(context.failureLabel(_failure ?? state.failure!)),
        AppButton(label: context.l.save, onPressed: _save, busy: state.busy),
        const SizedBox(height: 8),
        AppButton(
          label: context.l.cancel,
          secondary: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}

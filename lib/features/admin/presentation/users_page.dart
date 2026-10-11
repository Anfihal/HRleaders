import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/components/app_components.dart';
import '../../../core/components/app_data_table.dart';
import '../../../core/di/app_dependencies.dart';
import '../../../core/localization/localization.dart';
import '../../../core/presentation/resource_state.dart';
import '../../auth/domain/auth.dart';
import '../domain/admin.dart';
import 'users_bloc.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});
  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<UsersBloc, ResourceState<List<AdminUser>>>(
    builder: (context, state) {
      final canManage = context.read<AppDependencies>().auth.current!.user.can(
        Permission.manageUsers,
      );
      Widget action(AdminUser entry) => AppButton(
        label: entry.blocked ? context.l.unblock : context.l.block,
        secondary: true,
        onPressed: canManage && !state.busy
            ? () =>
                  context.read<UsersBloc>().block(entry.user.id, !entry.blocked)
            : null,
      );
      return ListView(
        children: [
          AppSectionHeader(title: context.l.users),
          ResourceView(
            state: state,
            retry: context.read<UsersBloc>().load,
            builder: (users) => AppDataTable<AdminUser>(
              items: users,
              columns: [
                context.l.fullName,
                context.l.role,
                context.l.active,
                context.l.settings,
              ],
              cells: (entry) => [
                Text(entry.user.name),
                Text(context.roleLabel(entry.user.role)),
                AppBadge(
                  label: entry.blocked ? context.l.blocked : context.l.active,
                ),
                action(entry),
              ],
              mobileCard: (entry) => AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(entry.user.name),
                    Text(context.roleLabel(entry.user.role)),
                    const SizedBox(height: 12),
                    AppBadge(
                      label: entry.blocked
                          ? context.l.blocked
                          : context.l.active,
                    ),
                    const SizedBox(height: 12),
                    action(entry),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

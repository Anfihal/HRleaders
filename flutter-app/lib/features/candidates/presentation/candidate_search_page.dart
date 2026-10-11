import 'package:flutter/widgets.dart' hide Page;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/components/app_components.dart';
import '../../../core/domain/value_objects.dart';
import '../../../core/localization/localization.dart';
import '../../../core/presentation/resource_state.dart';
import '../domain/candidates.dart';
import 'candidate_search_bloc.dart';
import 'candidate_card.dart';
import 'candidate_filters.dart';

class CandidateSearchPage extends StatelessWidget {
  const CandidateSearchPage({super.key});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth > 850;
      Widget filters({bool sheet = false}) =>
          BlocBuilder<ResourceBloc<Dictionaries>, ResourceState<Dictionaries>>(
            builder: (context, state) => ResourceView(
              state: state,
              retry: context.read<ResourceBloc<Dictionaries>>().load,
              builder: (dictionaries) => CandidateFilters(
                initial: context.read<CandidateSearchBloc>().filter,
                dictionaries: dictionaries,
                apply: (filter) {
                  context.read<CandidateSearchBloc>().add(
                    SearchRequested(filter),
                  );
                  if (sheet) Navigator.of(context).pop();
                },
              ),
            ),
          );
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (wide)
            SizedBox(
              width: 276,
              child: SingleChildScrollView(child: filters()),
            ),
          if (wide) const SizedBox(width: 24),
          Expanded(
            child:
                BlocBuilder<
                  CandidateSearchBloc,
                  ResourceState<Page<Candidate>>
                >(
                  builder: (context, state) {
                    final bloc = context.read<CandidateSearchBloc>();
                    final items = state.value?.items ?? [];
                    return CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AppSectionHeader(
                                title: context.l.candidates,
                                subtitle: state.value == null
                                    ? context.l.loading
                                    : context.number(state.value!.total),
                                actions: [
                                  if (!wide)
                                    AppButton(
                                      label: context.l.filters,
                                      secondary: true,
                                      onPressed: () => appBottomSheet(
                                        context,
                                        MultiBlocProvider(
                                          providers: [
                                            BlocProvider.value(value: bloc),
                                            BlocProvider.value(
                                              value: context
                                                  .read<
                                                    ResourceBloc<Dictionaries>
                                                  >(),
                                            ),
                                          ],
                                          child: filters(sheet: true),
                                        ),
                                      ),
                                    ),
                                  AppButton(
                                    label: context.l.refresh,
                                    secondary: true,
                                    onPressed: state.busy
                                        ? null
                                        : () => bloc.add(
                                            const RefreshCandidates(),
                                          ),
                                  ),
                                ],
                              ),
                              if (state.busy) const AppLoadingState(),
                              if (state.failure != null)
                                AppErrorState(
                                  failure: state.failure!,
                                  retry: () =>
                                      bloc.add(const RefreshCandidates()),
                                ),
                              if (state.phase == ResourcePhase.empty)
                                AppEmptyState(
                                  message: context.l.emptyCandidates,
                                ),
                            ],
                          ),
                        ),
                        SliverList.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: CandidateCard(
                              candidate: items[index],
                              open: () => context.go(
                                '/employer/candidates/${items[index].id.value}',
                              ),
                            ),
                          ),
                        ),
                        if (state.value?.hasMore ?? false)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: AppButton(
                                label: context.l.nextPage,
                                busy: state.busy,
                                onPressed: () => bloc.add(const LoadNextPage()),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
          ),
        ],
      );
    },
  );
}

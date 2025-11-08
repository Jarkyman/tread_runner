import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'analytics_service.dart';
import '../preferences/user_preferences_repository.dart';

class AnalyticsConsentCubit extends Cubit<AnalyticsConsentState> {
  AnalyticsConsentCubit({
    required UserPreferencesRepository preferencesRepository,
    required AnalyticsService analyticsService,
    required bool initialConsent,
  })  : _preferencesRepository = preferencesRepository,
        _analyticsService = analyticsService,
        super(
          AnalyticsConsentState(
            shareUsageData: initialConsent,
            isSaving: false,
          ),
        );

  final UserPreferencesRepository _preferencesRepository;
  final AnalyticsService _analyticsService;

  Future<void> setShareUsageData(bool enabled) async {
    if (state.shareUsageData == enabled) {
      return;
    }
    emit(state.copyWith(isSaving: true));
    await _preferencesRepository.setShareUsageData(enabled);
    await _analyticsService.setUserConsent(enabled);
    emit(state.copyWith(shareUsageData: enabled, isSaving: false));
  }
}

class AnalyticsConsentState extends Equatable {
  const AnalyticsConsentState({
    required this.shareUsageData,
    required this.isSaving,
  });

  final bool shareUsageData;
  final bool isSaving;

  AnalyticsConsentState copyWith({
    bool? shareUsageData,
    bool? isSaving,
  }) {
    return AnalyticsConsentState(
      shareUsageData: shareUsageData ?? this.shareUsageData,
      isSaving: isSaving ?? this.isSaving,
    );
  }

  @override
  List<Object?> get props => [shareUsageData, isSaving];
}

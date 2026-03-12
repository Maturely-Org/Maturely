import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsState {
  final bool maskSensitiveData;
  final bool useBiometrics;

  const SettingsState({
    this.maskSensitiveData = false,
    this.useBiometrics = false,
  });

  SettingsState copyWith({
    bool? maskSensitiveData,
    bool? useBiometrics,
  }) {
    return SettingsState(
      maskSensitiveData: maskSensitiveData ?? this.maskSensitiveData,
      useBiometrics: useBiometrics ?? this.useBiometrics,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState());

  void toggleMasking() {
    state = state.copyWith(maskSensitiveData: !state.maskSensitiveData);
  }

  void toggleBiometrics() {
    state = state.copyWith(useBiometrics: !state.useBiometrics);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

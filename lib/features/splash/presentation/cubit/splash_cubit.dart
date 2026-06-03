import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  SplashCubit() : super(const SplashLoading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      await Future<void>.delayed(const Duration(seconds: 2));
      emit(const SplashReady());
    } catch (e) {
      emit(SplashError(e.toString()));
    }
  }
}

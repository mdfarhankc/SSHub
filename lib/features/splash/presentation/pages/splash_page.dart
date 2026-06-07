import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sshub/features/splash/presentation/cubit/splash_cubit.dart';
import 'package:sshub/features/ssh/presentation/pages/home_page.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});
  static const route = "/";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<SplashCubit, SplashState>(
        listener: (context, state) {
          if (state is SplashReady) {
            Navigator.pushReplacementNamed(context, HomePage.route);
          }
        },
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

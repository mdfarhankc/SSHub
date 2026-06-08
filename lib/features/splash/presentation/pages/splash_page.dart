import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sshub/features/ssh/presentation/bloc/server_list_bloc.dart';
import 'package:sshub/features/ssh/presentation/pages/home_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  static const route = "/";

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    if (_loaded(context.read<ServerListBloc>().state)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _goHome());
    }
  }

  bool _loaded(ServerListState state) =>
      state.status == ServerListStatus.success ||
      state.status == ServerListStatus.failure;

  void _goHome() {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.pushReplacementNamed(context, HomePage.route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: BlocListener<ServerListBloc, ServerListState>(
        listenWhen: (_, current) => _loaded(current),
        listener: (_, _) => _goHome(),
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Image.asset("assets/icon/icon.png", width: 160, height: 160),
          ),
        ),
      ),
    );
  }
}

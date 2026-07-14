import 'package:flutter/material.dart';
import 'login.dart';
import 'channel_setup.dart';
import 'api_service.dart';
import 'core/theme/app_theme.dart';
import 'main_scaffold.dart';

void main() {
  ApiService.startHealthCheck();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TeleStore',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const InitializerWidget(),
    );
  }
}

class InitializerWidget extends StatefulWidget {
  const InitializerWidget({super.key});

  @override
  State<InitializerWidget> createState() => _InitializerWidgetState();
}

class _InitializerWidgetState extends State<InitializerWidget> {
  @override
  void initState() {
    super.initState();
    _checkLoginState();
  }

  Future<void> _checkLoginState() async {
    // Wait for the next frame so Navigator is ready
    await Future.delayed(Duration.zero);
    
    final userId = await ApiService.getUserId();
    final channelId = await ApiService.getChannelId();
    
    if (!mounted) return;
    
    if (userId == null || userId.isEmpty) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } else if (channelId == null || channelId.isEmpty) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const ChannelSetupPage()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScaffold()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

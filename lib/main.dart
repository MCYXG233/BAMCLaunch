import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'core/core.dart';
import 'core/performance/memory_optimizer.dart';
import 'ui/theme/theme.dart';
import 'ui/components/progress/pixel_loading_animation.dart';
import 'ui/pages/components/minecraft_xp_bar_demo_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final platformAdapter = PlatformAdapterFactory.getInstance();
  final logDirectory = Directory(platformAdapter.logsDirectory);
  if (!logDirectory.existsSync()) {
    await logDirectory.create(recursive: true);
  }

  final logFilePath =
      '${logDirectory.path}${Platform.pathSeparator}${DateTime.now().toIso8601String().replaceAll(':', '-')}.log';

  await logger.initialize(logFilePath);
  ExceptionHandler().initialize();
  ErrorReportService().initialize(
    enableReporting: true,
  );

  runZonedGuarded(() async {
    runApp(const MyApp());
  }, (error, stackTrace) {
    ExceptionHandler.handleZoneError(error, stackTrace);
    ErrorReportService().sendReportFromException(
      error,
      stackTrace,
      isAnonymous: true,
    );
    logger.error('Global error caught: $error');
    logger.error('Stack trace: $stackTrace');
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await WindowManagerService.getInstance().initialize();
    MemoryOptimizer().startOptimization();
    await accountManager.initialize();
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BAMCLauncher',
      theme: BamcTheme.lightTheme,
      home: _isLoading
          ? const LoadingScreen(message: '正在启动BAMCLauncher...')
          : const MinecraftXpBarDemoPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

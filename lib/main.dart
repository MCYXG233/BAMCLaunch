import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'core/core.dart';
import 'core/performance/memory_optimizer.dart';
import 'ui/theme/theme.dart';
import 'ui/components/layout/main_layout.dart' hide logger;

void main() async {
  // 初始化Flutter绑定
  WidgetsFlutterBinding.ensureInitialized();

  // 创建日志文件路径
  final platformAdapter = PlatformAdapterFactory.getInstance();
  final logDirectory = Directory(platformAdapter.logsDirectory);
  if (!logDirectory.existsSync()) {
    await logDirectory.create(recursive: true);
  }

  final logFilePath =
      '${logDirectory.path}${Platform.pathSeparator}${DateTime.now().toIso8601String().replaceAll(':', '-')}.log';

  // 初始化日志系统
  await (logger as dynamic).initialize(logFilePath);

  // 初始化异常处理器
  ExceptionHandler().initialize();

  // 初始化错误报告服务
  ErrorReportService().initialize(
    enableReporting: true,
    // 这里可以配置实际的错误报告端点
    // reportEndpoint: 'https://api.bamclauncher.com/error-report',
    // apiKey: 'your_api_key_here',
  );

  // 全局异常捕获
  runZonedGuarded(() async {
    // 初始化窗口管理器
    await WindowManagerService.getInstance().initialize();

    // 启动内存优化器
    MemoryOptimizer().startOptimization();

    runApp(const MyApp());
  }, (error, stackTrace) {
    ExceptionHandler.handleZoneError(error, stackTrace);

    // 发送错误报告
    ErrorReportService().sendReportFromException(
      error,
      stackTrace,
      isAnonymous: true,
    );

    print('Global error caught: $error');
    print('Stack trace: $stackTrace');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BAMCLauncher',
      theme: BamcTheme.lightTheme,
      home: const MainLayout(),
      debugShowCheckedModeBanner: false,
    );
  }
}

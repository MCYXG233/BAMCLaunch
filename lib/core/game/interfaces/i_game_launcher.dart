import '../models/game_launch_models.dart';
import 'dart:io';

abstract class IGameLauncher {
  Future<JavaDetectionResult> detectJava();

  Future<String> optimizeJvmParameters(String gameVersion, int memoryMb);

  Future<Process> launchGame(GameLaunchConfig config);

  Stream<String> getGameOutput();

  Stream<ProcessSignal> getProcessSignals();

  Stream<GameLaunchStatus> getLaunchStatus();

  Future<void> killProcess();

  bool get isProcessRunning;

  Future<CrashAnalysis> analyzeLastCrash();

  void dispose();
}

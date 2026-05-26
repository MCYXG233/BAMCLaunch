import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../ui/theme/colors.dart';
import '../ui/theme/typography.dart';
import 'fps_monitor.dart';
import 'memory_monitor.dart';

class HUDOverlay extends StatefulWidget {
  final Widget child;
  final bool showFPS;
  final bool showMemory;
  final bool showPosition;
  final HUDPosition position;
  final HUDTheme theme;
  
  const HUDOverlay({
    super.key,
    required this.child,
    this.showFPS = true,
    this.showMemory = true,
    this.showPosition = false,
    this.position = HUDPosition.topRight,
    this.theme = HUDTheme.dark,
  });
  
  @override
  State<HUDOverlay> createState() => _HUDOverlayState();
}

class _HUDOverlayState extends State<HUDOverlay> {
  final FPSMonitor _fpsMonitor = FPSMonitor();
  final MemoryMonitor _memoryMonitor = MemoryMonitor();
  
  FPSData? _fpsData;
  MemoryData? _memoryData;
  Offset _gamePosition = Offset.zero;
  
  @override
  void initState() {
    super.initState();
    _startMonitoring();
  }
  
  @override
  void dispose() {
    _fpsMonitor.dispose();
    _memoryMonitor.dispose();
    super.dispose();
  }
  
  void _startMonitoring() {
    _fpsMonitor.start();
    _fpsMonitor.fpsStream.listen((data) {
      if (mounted) {
        setState(() => _fpsData = data);
      }
    });
    
    _memoryMonitor.start();
    _memoryMonitor.memoryStream.listen((data) {
      if (mounted) {
        setState(() => _memoryData = data);
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        _buildHUDOverlay(),
      ],
    );
  }
  
  Widget _buildHUDOverlay() {
    final isTop = widget.position == HUDPosition.topLeft || 
                  widget.position == HUDPosition.topRight;
    final isRight = widget.position == HUDPosition.topRight || 
                    widget.position == HUDPosition.bottomRight;
    
    return Positioned(
      top: isTop ? 16 : null,
      bottom: !isTop ? 16 : null,
      right: isRight ? 16 : null,
      left: !isRight ? 16 : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (widget.showFPS && _fpsData != null) 
            _buildFPSWidget(),
          if (widget.showMemory && _memoryData != null)
            _buildMemoryWidget(),
          if (widget.showPosition)
            _buildPositionWidget(),
        ],
      ),
    );
  }
  
  Widget _buildFPSWidget() {
    final fps = _fpsData!.currentFPS;
    Color fpsColor;
    
    if (fps >= 55) {
      fpsColor = BAColors.success;
    } else if (fps >= 30) {
      fpsColor = BAColors.warning;
    } else {
      fpsColor = BAColors.danger;
    }
    
    return _HUDPanel(
      theme: widget.theme,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.speed, color: fpsColor, size: 16),
          const SizedBox(width: 8),
          Text(
            '${fps.toStringAsFixed(1)} FPS',
            style: BATypography.caption.copyWith(
              color: fpsColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMemoryWidget() {
    final memory = _memoryData!;
    final usagePercent = memory.usagePercentage;
    
    Color memoryColor;
    if (usagePercent < 60) {
      memoryColor = BAColors.success;
    } else if (usagePercent < 85) {
      memoryColor = BAColors.warning;
    } else {
      memoryColor = BAColors.danger;
    }
    
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: _HUDPanel(
        theme: widget.theme,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.memory, color: memoryColor, size: 16),
            const SizedBox(width: 8),
            Text(
              '${memory.usedMemoryFormatted} / ${memory.totalMemoryFormatted}',
              style: BATypography.caption.copyWith(
                color: memoryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPositionWidget() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: _HUDPanel(
        theme: widget.theme,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on, color: BAColors.primary, size: 16),
            const SizedBox(width: 8),
            Text(
              'X: ${_gamePosition.dx.toStringAsFixed(1)} Y: ${_gamePosition.dy.toStringAsFixed(1)}',
              style: BATypography.caption.copyWith(
                color: BAColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HUDPanel extends StatelessWidget {
  final Widget child;
  final HUDTheme theme;
  
  const _HUDPanel({
    required this.child,
    required this.theme,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

enum HUDPosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

class HUDTheme {
  final Color backgroundColor;
  final Color borderColor;
  final Color shadowColor;
  final Color textColor;
  
  const HUDTheme({
    required this.backgroundColor,
    required this.borderColor,
    required this.shadowColor,
    required this.textColor,
  });
  
  static const dark = HUDTheme(
    backgroundColor: Color(0xCC1A1A2E),
    borderColor: Color(0xFF2A2A4A),
    shadowColor: Color(0x80000000),
    textColor: Color(0xFFFFFFFF),
  );
  
  static const light = HUDTheme(
    backgroundColor: Color(0xCCF5F7FA),
    borderColor: Color(0xFFD0D0E0),
    shadowColor: Color(0x30000000),
    textColor: Color(0xFF1A1A2E),
  );
  
  static const game = HUDTheme(
    backgroundColor: Color(0x00000000),
    borderColor: Color(0x40FFFFFF),
    shadowColor: Color(0x40000000),
    textColor: Color(0xFFFFFFFF),
  );
}

class MiniFPSWidget extends StatelessWidget {
  final FPSData fpsData;
  final bool compact;
  
  const MiniFPSWidget({
    super.key,
    required this.fpsData,
    this.compact = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final fps = fpsData.currentFPS;
    Color fpsColor;
    
    if (fps >= 55) {
      fpsColor = const Color(0xFF00FF00);
    } else if (fps >= 30) {
      fpsColor = const Color(0xFFFFFF00);
    } else {
      fpsColor = const Color(0xFFFF0000);
    }
    
    if (compact) {
      return Text(
        '${fps.toStringAsFixed(0)}',
        style: TextStyle(
          color: fpsColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          shadows: const [
            Shadow(
              color: Colors.black,
              blurRadius: 2,
            ),
          ],
        ),
      );
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FPS: ${fps.toStringAsFixed(1)}',
          style: TextStyle(
            color: fpsColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            shadows: const [
              Shadow(color: Colors.black, blurRadius: 2),
            ],
          ),
        ),
        if (fpsData.averageFPS > 0)
          Text(
            'Avg: ${fpsData.averageFPS.toStringAsFixed(1)}',
            style: TextStyle(
              color: fpsColor.withOpacity(0.7),
              fontSize: 12,
              shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
            ),
          ),
      ],
    );
  }
}

class MiniMemoryWidget extends StatelessWidget {
  final MemoryData memoryData;
  final bool compact;
  
  const MiniMemoryWidget({
    super.key,
    required this.memoryData,
    this.compact = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final usagePercent = memoryData.usagePercentage;
    Color memoryColor;
    
    if (usagePercent < 60) {
      memoryColor = const Color(0xFF00FF00);
    } else if (usagePercent < 85) {
      memoryColor = const Color(0xFFFFFF00);
    } else {
      memoryColor = const Color(0xFFFF0000);
    }
    
    if (compact) {
      return Text(
        '${memoryData.usedMemoryFormatted}',
        style: TextStyle(
          color: memoryColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          shadows: const [
            Shadow(color: Colors.black, blurRadius: 2),
          ],
        ),
      );
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MEM: ${memoryData.usedMemoryFormatted}',
          style: TextStyle(
            color: memoryColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            shadows: const [
              Shadow(color: Colors.black, blurRadius: 2),
            ],
          ),
        ),
        Text(
          'Max: ${memoryData.totalMemoryFormatted}',
          style: TextStyle(
            color: memoryColor.withOpacity(0.7),
            fontSize: 12,
            shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
          ),
        ),
      ],
    );
  }
}

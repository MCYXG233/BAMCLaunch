import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/logger.dart';

/// 自定义乐器
class CustomInstrument {
  final String name;
  final String soundFile;
  final int pitch;
  final bool pressKey;

  CustomInstrument({
    required this.name,
    required this.soundFile,
    required this.pitch,
    this.pressKey = true,
  });
}

/// 音符层
class NoteLayer {
  final int id;
  final String name;
  final bool locked;
  final int volume;
  final int panning;

  NoteLayer({
    required this.id,
    required this.name,
    this.locked = false,
    this.volume = 100,
    this.panning = 0,
  });
}

/// 音符
class Note {
  final int tick;
  final int layer;
  final int instrument;
  final int key;
  final int velocity;
  final int panning;
  final int pitch;

  Note({
    required this.tick,
    required this.layer,
    required this.instrument,
    required this.key,
    this.velocity = 100,
    this.panning = 0,
    this.pitch = 0,
  });
}

/// 循环头部标记
class LoopHeader {
  final int startTick;
  final int endTick;
  final int totalLoops;

  LoopHeader({
    this.startTick = 0,
    this.endTick = 0,
    this.totalLoops = 0,
  });
}

/// NBS 文件
class NbsFile {
  final int version;
  final int vanillaInstrumentsCount;
  final int songLength;
  final int layerCount;
  final String songName;
  final String songAuthor;
  final String originalAuthor;
  final String description;
  final double tempo;
  final bool autoSaving;
  final int autoSavingDuration;
  final int timeSignature;
  final int minutesSpent;
  final int leftClicks;
  final int rightClicks;
  final int blocksAdded;
  final int blocksRemoved;
  final String midiFile;
  final bool loopEnabled;
  final LoopHeader loopHeader;
  final List<CustomInstrument> customInstruments;
  final List<NoteLayer> noteLayers;
  final List<Note> notes;

  NbsFile({
    required this.version,
    required this.vanillaInstrumentsCount,
    required this.songLength,
    required this.layerCount,
    required this.songName,
    required this.songAuthor,
    required this.originalAuthor,
    required this.description,
    required this.tempo,
    required this.autoSaving,
    required this.autoSavingDuration,
    required this.timeSignature,
    required this.minutesSpent,
    required this.leftClicks,
    required this.rightClicks,
    required this.blocksAdded,
    required this.blocksRemoved,
    required this.midiFile,
    required this.loopEnabled,
    required this.loopHeader,
    required this.customInstruments,
    required this.noteLayers,
    required this.notes,
  });

  Duration get totalDuration => Duration(
    milliseconds: (songLength * 1000 / tempo * 60).round(),
  );
}

/// NBS 文件解析器
class NbsParser {
  static final Logger _logger = Logger('NBS');

  /// 解析 NBS 文件
  static Future<NbsFile?> parse(String path) async {
    try {
      final file = File(path);
      final bytes = await file.readAsBytes();
      return parseBytes(bytes);
    } catch (e) {
      _logger.error('Failed to parse NBS file', e);
      return null;
    }
  }

  /// 从字节解析
  static NbsFile? parseBytes(Uint8List bytes) {
    try {
      final reader = ByteData.sublistView(bytes);
      int offset = 0;

      // 读取头部
      final length = _readShort(reader, offset);
      offset += 2;

      final hasLength = length > 0;
      final int nbsVersion;

      if (hasLength) {
        nbsVersion = _readByte(reader, offset);
        offset += 1;
      } else {
        nbsVersion = 0;
      }

      final vanillaInstrumentsCount = _readByte(reader, offset);
      offset += 1;

      int songLength = 0;
      if (nbsVersion >= 3) {
        songLength = _readShort(reader, offset);
        offset += 2;
      } else {
        songLength = length;
      }

      final layerCount = _readShort(reader, offset);
      offset += 2;

      final songName = _readString(reader, offset);
      offset += 4 + utf8.encode(songName).length;

      final songAuthor = _readString(reader, offset);
      offset += 4 + utf8.encode(songAuthor).length;

      final originalAuthor = _readString(reader, offset);
      offset += 4 + utf8.encode(originalAuthor).length;

      final description = _readString(reader, offset);
      offset += 4 + utf8.encode(description).length;

      final tempo = _readShort(reader, offset) / 100.0;
      offset += 2;

      final autoSaving = _readByte(reader, offset) == 1;
      offset += 1;

      final autoSavingDuration = _readByte(reader, offset);
      offset += 1;

      final timeSignature = _readByte(reader, offset);
      offset += 1;

      final minutesSpent = _readInt(reader, offset);
      offset += 4;

      final leftClicks = _readInt(reader, offset);
      offset += 4;

      final rightClicks = _readInt(reader, offset);
      offset += 4;

      final blocksAdded = _readInt(reader, offset);
      offset += 4;

      final blocksRemoved = _readInt(reader, offset);
      offset += 4;

      final midiFile = _readString(reader, offset);
      offset += 4 + utf8.encode(midiFile).length;

      final loopEnabled = _readByte(reader, offset) == 1;
      offset += 1;

      final loopStartTick = _readByte(reader, offset);
      offset += 1;

      final loopEndTick = _readByte(reader, offset);
      offset += 1;

      final totalLoops = _readByte(reader, offset);
      offset += 1;

      final loopHeader = LoopHeader(
        startTick: loopStartTick,
        endTick: loopEndTick,
        totalLoops: totalLoops,
      );

      // 读取音符
      final List<Note> notes = [];
      int tick = -1;
      while (true) {
        final jump = _readShort(reader, offset);
        offset += 2;

        if (jump == 0) {
          break;
        }

        tick += jump;

        int layer = -1;
        while (true) {
          final jumpLayer = _readShort(reader, offset);
          offset += 2;

          if (jumpLayer == 0) {
            break;
          }

          layer += jumpLayer;

          final instrument = _readByte(reader, offset);
          offset += 1;

          final key = _readByte(reader, offset);
          offset += 1;

          int velocity = 100;
          int panning = 0;
          int pitch = 0;

          if (nbsVersion >= 4) {
            velocity = _readByte(reader, offset);
            offset += 1;

            panning = _readByte(reader, offset);
            offset += 1;

            pitch = _readShort(reader, offset);
            offset += 2;
          }

          notes.add(Note(
            tick: tick,
            layer: layer,
            instrument: instrument,
            key: key,
            velocity: velocity,
            panning: panning,
            pitch: pitch,
          ));
        }
      }

      // 读取层
      final List<NoteLayer> layers = [];
      for (int i = 0; i < layerCount; i++) {
        final name = _readString(reader, offset);
        offset += 4 + utf8.encode(name).length;

        if (nbsVersion >= 4) {
          final locked = _readByte(reader, offset) == 1;
          offset += 1;

          final volume = _readByte(reader, offset);
          offset += 1;

          final panning = _readByte(reader, offset);
          offset += 1;

          layers.add(NoteLayer(
            id: i,
            name: name,
            locked: locked,
            volume: volume,
            panning: panning,
          ));
        } else {
          layers.add(NoteLayer(id: i, name: name));
        }
      }

      // 读取自定义乐器
      final customInstrumentsCount = _readByte(reader, offset);
      offset += 1;

      final customInstruments = <CustomInstrument>[];
      for (int i = 0; i < customInstrumentsCount; i++) {
        final name = _readString(reader, offset);
        offset += 4 + utf8.encode(name).length;

        final soundFile = _readString(reader, offset);
        offset += 4 + utf8.encode(soundFile).length;

        final pitch = _readByte(reader, offset);
        offset += 1;

        final pressKey = _readByte(reader, offset) == 1;
        offset += 1;

        customInstruments.add(CustomInstrument(
          name: name,
          soundFile: soundFile,
          pitch: pitch,
          pressKey: pressKey,
        ));
      }

      return NbsFile(
        version: nbsVersion,
        vanillaInstrumentsCount: vanillaInstrumentsCount,
        songLength: songLength,
        layerCount: layerCount,
        songName: songName,
        songAuthor: songAuthor,
        originalAuthor: originalAuthor,
        description: description,
        tempo: tempo,
        autoSaving: autoSaving,
        autoSavingDuration: autoSavingDuration,
        timeSignature: timeSignature,
        minutesSpent: minutesSpent,
        leftClicks: leftClicks,
        rightClicks: rightClicks,
        blocksAdded: blocksAdded,
        blocksRemoved: blocksRemoved,
        midiFile: midiFile,
        loopEnabled: loopEnabled,
        loopHeader: loopHeader,
        customInstruments: customInstruments,
        noteLayers: layers,
        notes: notes,
      );
    } catch (e) {
      _logger.error('Failed to parse NBS bytes', e);
      return null;
    }
  }

  static int _readByte(ByteData data, int offset) =>
      data.getUint8(offset);

  static int _readShort(ByteData data, int offset) =>
      data.getInt16(offset, Endian.little);

  static int _readInt(ByteData data, int offset) =>
      data.getInt32(offset, Endian.little);

  static String _readString(ByteData data, int offset) {
    final length = _readInt(data, offset);
    if (length == 0) return '';
    final start = offset + 4;
    final bytes = Uint8List.view(data.buffer, start, length);
    return utf8.decode(bytes);
  }
}

/// NBS 播放器状态
enum NbsPlayerState {
  stopped,
  playing,
  paused,
}

/// NBS 音乐播放器
class NbsPlayer extends ChangeNotifier {
  final Logger _logger = Logger('NBSPlayer');

  NbsFile? _currentFile;
  int _currentTick = 0;
  Timer? _timer;
  NbsPlayerState _state = NbsPlayerState.stopped;
  double _volume = 0.7;
  bool _looping = false;
  final Map<int, Note> _activeNotes = {};

  NbsFile? get currentFile => _currentFile;
  NbsPlayerState get state => _state;
  int get currentTick => _currentTick;
  double get volume => _volume;
  bool get looping => _looping;

  Duration get position => _currentFile != null
      ? Duration(milliseconds: (_currentTick / _currentFile!.tempo * 1000).round())
      : Duration.zero;

  Duration get totalDuration => _currentFile?.totalDuration ?? Duration.zero;

  /// 加载文件
  Future<bool> loadFile(String path) async {
    final file = await NbsParser.parse(path);
    if (file != null) {
      _currentFile = file;
      _currentTick = 0;
      notifyListeners();
      _logger.info('Loaded: ${file.songName}');
      return true;
    }
    return false;
  }

  /// 播放
  void play() {
    if (_currentFile == null || _state == NbsPlayerState.playing) {
      return;
    }

    _state = NbsPlayerState.playing;
    _startTimer();
    notifyListeners();
  }

  /// 暂停
  void pause() {
    _state = NbsPlayerState.paused;
    _stopTimer();
    notifyListeners();
  }

  /// 停止
  void stop() {
    _state = NbsPlayerState.stopped;
    _currentTick = 0;
    _stopTimer();
    _releaseAllNotes();
    notifyListeners();
  }

  /// 设置音量
  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    notifyListeners();
  }

  /// 循环
  void setLooping(bool value) {
    _looping = value;
    notifyListeners();
  }

  /// 跳转到
  void seekTo(Duration position) {
    if (_currentFile == null) return;
    final tick = (position.inMilliseconds * _currentFile!.tempo / 1000).round();
    _currentTick = tick.clamp(0, _currentFile!.songLength);
    notifyListeners();
  }

  /// 开始定时器
  void _startTimer() {
    _stopTimer();
    if (_currentFile == null) return;

    final interval = Duration(milliseconds: (1000 / _currentFile!.tempo).round());
    _timer = Timer.periodic(interval, _onTick);
  }

  /// 停止定时器
  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// 定时器回调
  void _onTick(Timer timer) {
    if (_state != NbsPlayerState.playing) {
      return;
    }

    _playCurrentTick();

    _currentTick++;

    if (_currentTick >= _currentFile!.songLength) {
      if (_looping && _currentFile!.loopEnabled) {
        _currentTick = _currentFile!.loopHeader.startTick;
      } else {
        stop();
      }
    }

    notifyListeners();
  }

  /// 播放当前 tick 的音符
  void _playCurrentTick() {
    if (_currentFile == null) return;

    final notes = _currentFile!.notes
        .where((note) => note.tick == _currentTick)
        .toList();

    for (final note in notes) {
      _playNote(note);
    }
  }

  /// 播放单个音符
  void _playNote(Note note) {
    // 实际项目中，这里应该集成音频播放库
    // 如 just_audio 或 audioplayers
    // 现在作为占位
    _activeNotes[note.tick * 1000 + note.layer] = note;
    _logger.debug('Playing note: tick=${note.tick}, inst=${note.instrument}, key=${note.key}');
  }

  /// 释放所有音符
  void _releaseAllNotes() {
    _activeNotes.clear();
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}

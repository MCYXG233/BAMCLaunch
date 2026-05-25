import 'package:flutter_test/flutter_test.dart';
import 'package:bamclaunch/src/task/index.dart';

/// 测试用的简单任务
class SimpleTask extends Task<int> {
  final int value;
  final Duration? delay;
  final bool shouldFail;

  SimpleTask(this.value, {this.delay, this.shouldFail = false, String? id})
    : super(id: id);

  @override
  Future<int> execute(TaskContext context) async {
    if (delay != null) {
      await Future.delayed(delay!);
    }
    context.checkCancelled();
    if (shouldFail) {
      throw Exception('测试失败');
    }
    return value;
  }
}

/// 带进度报告的测试任务
class ProgressTask extends Task<double> {
  final int steps;

  ProgressTask(this.steps, {String? id}) : super(id: id);

  @override
  Future<double> execute(TaskContext context) async {
    for (int i = 1; i <= steps; i++) {
      await Future.delayed(const Duration(milliseconds: 10));
      context.checkCancelled();
      context.onProgress(
        TaskProgress(progress: i / steps, stage: '步骤 $i/$steps'),
      );
    }
    return 1.0;
  }
}

void main() {
  group('TaskStatus', () {
    test('枚举值正确', () {
      expect(TaskStatus.values, hasLength(5));
      expect(TaskStatus.waiting, isNotNull);
      expect(TaskStatus.running, isNotNull);
      expect(TaskStatus.success, isNotNull);
      expect(TaskStatus.failed, isNotNull);
      expect(TaskStatus.cancelled, isNotNull);
    });
  });

  group('TaskProgress', () {
    test('创建进度信息', () {
      final progress = TaskProgress(progress: 0.5, stage: '测试阶段', detail: '详情');
      expect(progress.progress, equals(0.5));
      expect(progress.stage, equals('测试阶段'));
      expect(progress.detail, equals('详情'));
    });

    test('进度值超出范围会断言失败', () {
      expect(
        () => TaskProgress(progress: -0.1),
        throwsA(isA<AssertionError>()),
      );
      expect(() => TaskProgress(progress: 1.1), throwsA(isA<AssertionError>()));
    });
  });

  group('TaskContext', () {
    test('进度回调正常工作', () {
      final progressList = <TaskProgress>[];
      final context = TaskContext(
        onProgress: (progress) => progressList.add(progress),
      );

      context.onProgress(TaskProgress(progress: 0.5));
      expect(progressList, hasLength(1));
      expect(progressList.first.progress, equals(0.5));
    });

    test('取消功能正常工作', () {
      final context = TaskContext();
      expect(context.isCancelled, isFalse);

      context.cancel();
      expect(context.isCancelled, isTrue);
      expect(
        () => context.checkCancelled(),
        throwsA(isA<TaskCancelledException>()),
      );
    });
  });

  group('Task', () {
    test('基本任务执行', () async {
      final task = SimpleTask(42);
      final result = await task.run();

      expect(result, equals(42));
      expect(task.isSuccess, isTrue);
      expect(task.status, equals(TaskStatus.success));
      expect(task.result, equals(42));
    });

    test('任务失败处理', () async {
      final task = SimpleTask(0, shouldFail: true);

      expect(() async => await task.run(), throwsA(isA<Exception>()));
      // 使用 future 等待完成，然后检查状态
      try {
        await task.future;
      } catch (_) {
        // 忽略异常
      }
      expect(task.isFailed, isTrue);
      expect(task.status, equals(TaskStatus.failed));
      expect(task.error, isNotNull);
    });

    test('任务取消', () async {
      final task = SimpleTask(42, delay: const Duration(milliseconds: 100));

      // 直接设置状态为 cancelled
      task.cancel();
      expect(task.isCancelled, isTrue);

      // 尝试运行应该抛出异常
      expect(() async => await task.run(), throwsA(isA<StateError>()));
    });

    test('任务依赖', () async {
      final task1 = SimpleTask(1);
      final task2 = SimpleTask(2);
      final task3 = SimpleTask(3);

      task2.addDependency(task1);
      task3.addDependency(task2);

      final result3 = await task3.run();

      expect(result3, equals(3));
      expect(task1.isSuccess, isTrue);
      expect(task2.isSuccess, isTrue);
      expect(task3.isSuccess, isTrue);
    });

    test('thenApply 链式操作', () async {
      final task = SimpleTask(21);
      final resultTask = task.thenApply((value) => value * 2);

      final result = await resultTask.run();

      expect(result, equals(42));
    });

    test('thenCompose 链式操作', () async {
      final task1 = SimpleTask(21);
      final resultTask = task1.thenCompose((value) => SimpleTask(value * 2));

      final result = await resultTask.run();

      expect(result, equals(42));
    });

    test('Task.all 并行执行', () async {
      final tasks = [SimpleTask(1), SimpleTask(2), SimpleTask(3)];

      final allTask = Task.all(tasks);
      final results = await allTask.run();

      expect(results, equals([1, 2, 3]));
    });

    test('Task.sequentially 顺序执行', () async {
      final tasks = [SimpleTask(1), SimpleTask(2), SimpleTask(3)];

      final seqTask = Task.sequentially(tasks);
      final results = await seqTask.run();

      expect(results, equals([1, 2, 3]));
    });

    test('进度报告', () async {
      final progressList = <TaskProgress>[];
      final context = TaskContext(
        onProgress: (progress) => progressList.add(progress),
      );

      final task = ProgressTask(5);
      await task.run(context);

      expect(progressList, hasLength(5));
      expect(progressList.last.progress, equals(1.0));
    });

    test('任务ID生成', () {
      final task1 = SimpleTask(1);
      final task2 = SimpleTask(2);

      expect(task1.id, startsWith('task_'));
      expect(task2.id, startsWith('task_'));
      expect(task1.id, isNot(equals(task2.id)));
    });

    test('自定义任务ID', () {
      final task = SimpleTask(42, id: 'custom_id');
      expect(task.id, equals('custom_id'));
    });
  });
}

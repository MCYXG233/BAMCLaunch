export 'i_logger.dart';
export 'logger_impl.dart' hide LoggerImpl;
export 'exception_handler.dart';
export 'crash_analyzer.dart';
export 'error_report_service.dart';
export 'models/exception_models.dart';

import 'i_logger.dart';
import 'logger_impl.dart';

final ILogger logger = LoggerImpl();

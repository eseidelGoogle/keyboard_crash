import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart' as logging;
import 'package:logging_appenders/logging_appenders.dart';
import 'dart:developer' as developer;

import 'src/app.dart';

StreamSubscription<logging.LogRecord>? _logs;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  logging.hierarchicalLoggingEnabled = true;
  logging.Logger.root
    ..clearListeners()
    ..level = logging.Level.ALL;
  await _logs?.cancel();
  _logs = logging.Logger.root.onRecord.listen(
    PrintAppender(
      formatter: const ColorFormatter(),
    ),
  );
  final log = logging.Logger('main');
  log.info('Running app init');

  runApp(const MyApp());
}

void onRecord(logging.LogRecord record) {
  var level = record.level;
  var tag = record.loggerName;
  var message = record.message;
  var error = record.error;
  var stackTrace = record.stackTrace ?? StackTrace.current;

  developer.log(
    message,
    level: level.value,
    name: tag,
    stackTrace: stackTrace,
    error: error,
  );
}

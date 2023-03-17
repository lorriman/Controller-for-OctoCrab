import 'package:logging/logging.dart';


class LogLine{

  LogLine(this.level, this.line);

  final Level level;
  final String line;

}

final log = Logger('OctoCrab log');
final List<LogLine> logLines=[];
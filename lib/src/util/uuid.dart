import 'package:uuid/uuid.dart';
import 'package:uuid/uuid_util.dart';

final _uuid = Uuid(options: {'grng': UuidUtil.cryptoRNG()});

String uuid() => _uuid.v4();

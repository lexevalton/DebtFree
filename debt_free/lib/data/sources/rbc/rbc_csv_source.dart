import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../../../domain/entities/transaction.dart';
import '../transaction_source.dart';
import 'rbc_csv_parser.dart';

class RbcCsvSource implements TransactionSource {
  final RbcCsvParser _parser;

  RbcCsvSource({RbcCsvParser? parser}) : _parser = parser ?? RbcCsvParser();

  @override
  String get sourceName => 'RBC CSV File Import';

  @override
  Future<List<Transaction>> fetchTransactions() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      allowMultiple: true,
    );

    if (result == null || result.files.isEmpty) return [];

    final contents = <String>[];
    for (final file in result.files) {
      if (file.path == null) continue;
      contents.add(await File(file.path!).readAsString());
    }
    return _parser.parseMultipleContents(contents);
  }
}

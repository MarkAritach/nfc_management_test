import 'package:flutter/material.dart';

class NfcRecordList extends StatelessWidget {
  final List<String> records;

  const NfcRecordList({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const Center(child: Text('ยังไม่มีข้อมูล'));
    }

    return ListView.builder(
      itemCount: records.length,
      itemBuilder: (context, index) {
        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Text('${index + 1}')),
            title: Text(records[index]),
          ),
        );
      },
    );
  }
}
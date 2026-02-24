import 'package:flutter/material.dart';
import '../controller/nfc_write_controller.dart';
import '../controller/nfc_read_controller.dart'; // Import NfcScanStatus
import '../widgets/nfc_status_card.dart';

class NfcWritePage extends StatefulWidget {
  const NfcWritePage({super.key});

  @override
  State<NfcWritePage> createState() => _NfcWritePageState();
}

class _NfcWritePageState extends State<NfcWritePage> {
  final _controller = NfcWriteController();
  final _textController = TextEditingController();
  String _selectedType = 'Text';

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    super.dispose();
  }

  bool get _isWriting => _controller.status == NfcWriteStatus.writing;

  void _handleWrite() {
    final text = _textController.text.trim();

    if (_selectedType == 'Text') {
      _controller.writeText(text);
    } else if (_selectedType == 'URL') {
      _controller.writeUrl(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NFC Writer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NfcStatusCard(
              status: _mapWriteStatusToScanStatus(_controller.status),
              message: _controller.statusMessage,
            ),
            const SizedBox(height: 24),

            // Type Selector
            const Text(
              'ประเภทข้อมูล',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'Text',
                  label: Text('Text'),
                  icon: Icon(Icons.text_fields),
                ),
                ButtonSegment(
                  value: 'URL',
                  label: Text('URL'),
                  icon: Icon(Icons.link),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (Set<String> selection) {
                setState(() {
                  _selectedType = selection.first;
                  _controller.reset();
                });
              },
            ),

            const SizedBox(height: 24),

            // Input Field
            TextField(
              controller: _textController,
              maxLines: _selectedType == 'Text' ? 5 : 1,
              decoration: InputDecoration(
                labelText: _selectedType == 'Text' ? 'ข้อความ' : 'URL',
                hintText: _selectedType == 'Text'
                    ? 'กรอกข้อความที่ต้องการเขียน...'
                    : 'https://example.com',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(
                  _selectedType == 'Text' ? Icons.message : Icons.link,
                ),
              ),
              keyboardType: _selectedType == 'URL'
                  ? TextInputType.url
                  : TextInputType.multiline,
            ),

            const SizedBox(height: 24),

            // Write Button
            ElevatedButton.icon(
              onPressed: _isWriting ? _controller.stopWrite : _handleWrite,
              icon: Icon(_isWriting ? Icons.stop : Icons.nfc),
              label: Text(_isWriting ? 'Stop' : 'Write to Tag'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isWriting ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),

            const SizedBox(height: 12),

            // Clear Button
            OutlinedButton.icon(
              onPressed: _isWriting
                  ? null
                  : () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('ยืนยันการลบข้อมูล'),
                          content: const Text(
                            'คุณต้องการลบข้อมูลทั้งหมดใน NFC Tag หรือไม่?\n\nTag จะกลายเป็นว่างเปล่า',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('ยกเลิก'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _controller.clearTag();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('ลบข้อมูล'),
                            ),
                          ],
                        ),
                      );
                    },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Clear Tag'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Colors.red),
              ),
            ),

            const SizedBox(height: 16),

            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'วิธีใช้งาน',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('1. เลือกประเภทข้อมูล (Text หรือ URL)'),
                  const Text('2. กรอกข้อมูลที่ต้องการเขียน'),
                  const Text('3. กดปุ่ม "Write to Tag"'),
                  const Text('4. นำ NFC Tag มาแตะที่โทรศัพท์'),
                  const SizedBox(height: 8),
                  Text(
                    'หมายเหตุ: Tag ต้องสามารถเขียนได้เท่านั้น',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  NfcScanStatus _mapWriteStatusToScanStatus(NfcWriteStatus writeStatus) {
    switch (writeStatus) {
      case NfcWriteStatus.idle:
        return NfcScanStatus.idle;
      case NfcWriteStatus.writing:
        return NfcScanStatus.scanning;
      case NfcWriteStatus.success:
        return NfcScanStatus.success;
      case NfcWriteStatus.error:
        return NfcScanStatus.error;
    }
  }
}

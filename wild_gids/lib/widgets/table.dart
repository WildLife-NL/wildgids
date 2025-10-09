import 'package:flutter/material.dart';

class OverzichtTable extends StatefulWidget {
  @override
  _OverzichtTableState createState() => _OverzichtTableState();
}

class _OverzichtTableState extends State<OverzichtTable> {
  bool editMode = false;

  final List<String> categories = ['Baby', 'Jong', 'Volwassen', 'Unknown'];
  final List<IconData> icons = [
    Icons.female,
    Icons.male,
    Icons.help_outline,
  ];

  List<List<String>> values = [
    ['1', '', '', ''],
    ['', '', '', ''],
    ['', '', '', ''],
    ['', '', '', ''],
  ];

  Widget _buildCell(int row, int col) {
    if (!editMode) {
      return Center(
        child: Text(
          values[row][col],
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    } else {
      return TextFormField(
        initialValue: values[row][col],
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'type..',
          hintStyle: TextStyle(fontSize: 14),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        ),
        style: TextStyle(fontSize: 16),
        onChanged: (val) {
          setState(() {
            values[row][col] = val;
          });
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 360, // fixed width to avoid overflow cutting right side
        child: Card(
          margin: const EdgeInsets.all(20),
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Het Overzicht',
                      style: TextStyle(fontSize: 20),
                    ),
                    IconButton(
                      icon: Icon(editMode ? Icons.check : Icons.edit),
                      tooltip: editMode ? 'Bevestigen' : 'Bewerken',
                      onPressed: () {
                        setState(() {
                          editMode = !editMode;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Table(
                  border: TableBorder.all(
                    color: const Color.fromARGB(255, 27, 82, 30),
                    width: 2,
                  ),
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  columnWidths: {
                    0: const FixedColumnWidth(120),
                    for (int i = 1; i <= 4; i++) i: const FixedColumnWidth(30),
                  },
                  children: [
                    TableRow(
                      decoration:
                          BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                      children: [
                        const Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'Leeftijdscategorie',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        for (final icon in icons)
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 8.0),
                            child: Icon(icon, color: Colors.black87),
                          ),
                      ],
                    ),
                    for (int row = 0; row < categories.length; row++)
                      TableRow(
                        decoration: row.isOdd
                            ? BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8))
                            : null,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              categories[row],
                              style: const TextStyle(fontSize: 15),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          for (int col = 0; col < icons.length; col++)
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 4.0, vertical: 2.0),
                              child: _buildCell(row, col),
                            ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:material_ui/material_ui.dart';

Future<String?> mostrarDialogoTexto(
  BuildContext context, {
  required String title,
  required String label,
  String initialValue = '',
  int maxLength = 80,
  int maxLines = 1,
}) => showDialog<String>(
  context: context,
  builder: (_) => _DialogoTexto(
    title: title,
    label: label,
    initialValue: initialValue,
    maxLength: maxLength,
    maxLines: maxLines,
  ),
);

class _DialogoTexto extends StatefulWidget {
  const _DialogoTexto({
    required this.title,
    required this.label,
    required this.initialValue,
    required this.maxLength,
    required this.maxLines,
  });

  final String title;
  final String label;
  final String initialValue;
  final int maxLength;
  final int maxLines;

  @override
  State<_DialogoTexto> createState() => _DialogoTextoState();
}

class _DialogoTextoState extends State<_DialogoTexto> {
  late final TextEditingController controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      controller: controller,
      autofocus: true,
      maxLength: widget.maxLength,
      maxLines: widget.maxLines,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(labelText: widget.label),
      onSubmitted: widget.maxLines == 1
          ? (value) => Navigator.pop(context, value)
          : null,
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, controller.text),
        child: const Text('Salvar'),
      ),
    ],
  );
}

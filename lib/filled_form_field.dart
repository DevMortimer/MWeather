import 'package:flutter/material.dart';

class FilledFormField extends StatefulWidget {
  const FilledFormField({
    Key? key,
    required this.locationController,
    this.onSubmit,
    this.prefixIcon,
    this.helperText,
    this.labelText,
  }) : super(key: key);

  final TextEditingController locationController;
  final void Function(String)? onSubmit;
  final Icon? prefixIcon;
  final String? helperText;
  final String? labelText;

  @override
  State<FilledFormField> createState() => _FilledFormFieldState();
}

class _FilledFormFieldState extends State<FilledFormField> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.locationController,
      autofillHints: const [AutofillHints.location],
      decoration: InputDecoration(
        border: const UnderlineInputBorder(),
        filled: true,
        prefixIcon: const Icon(Icons.location_city),
        suffixIcon: widget.locationController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.cancel),
                onPressed: () {
                  widget.locationController.clear();
                  setState(() {});
                },
              )
            : null,
        helperText: widget.helperText,
        labelText: widget.labelText,
      ),
      onFieldSubmitted: widget.onSubmit,
      onChanged: (String val) => setState(() {}),
    );
  }
}

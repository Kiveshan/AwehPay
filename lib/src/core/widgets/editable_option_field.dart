import 'package:flutter/material.dart';

class EditableOptionField extends StatefulWidget {
  const EditableOptionField({
    super.key,
    required this.label,
    required this.controller,
    required this.options,
    this.prefixIcon,
    this.readOnly = false,
    this.onOptionSelected,
  });

  final String label;
  final TextEditingController controller;
  final List<String> options;
  final IconData? prefixIcon;
  final bool readOnly;
  final ValueChanged<String>? onOptionSelected;

  @override
  State<EditableOptionField> createState() => _EditableOptionFieldState();
}

class _EditableOptionFieldState extends State<EditableOptionField> {
  late final FocusNode _focusNode;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            color: Color(0xFF272A2F),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final fieldWidth = constraints.maxWidth;

            return RawAutocomplete<String>(
              textEditingController: widget.controller,
              focusNode: _focusNode,
              optionsBuilder: (textEditingValue) {
                if (widget.readOnly) {
                  return const Iterable<String>.empty();
                }

                if (_showAll) {
                  return widget.options;
                }

                final query = textEditingValue.text.toLowerCase().trim();

                if (query.isEmpty) {
                  return widget.options;
                }

                return widget.options.where(
                  (option) => option.toLowerCase().contains(query),
                );
              },
              fieldViewBuilder: (
                context,
                textEditingController,
                focusNode,
                onFieldSubmitted,
              ) {
                return Container(
                  height: 44,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFC9CED6)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      if (widget.prefixIcon != null) ...[
                        const SizedBox(width: 12),
                        Icon(
                          widget.prefixIcon,
                          color: const Color(0xFF272A2F),
                          size: 20,
                        ),
                      ],
                      Expanded(
                        child: TextField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          readOnly: widget.readOnly,
                          onChanged: (_) {
                            if (_showAll) setState(() => _showAll = false);
                          },
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 12),
                            isDense: true,
                          ),
                          style: const TextStyle(
                            color: Color(0xFF272A2F),
                            fontSize: 16,
                          ),
                        ),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (focusNode.hasFocus) {
                            focusNode.unfocus();
                          } else {
                            setState(() => _showAll = true);
                            focusNode.requestFocus();
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFF272A2F),
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    color: Colors.white,
                    child: SizedBox(
                      width: fieldWidth,
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final option = options.elementAt(index);

                          return ListTile(
                            dense: true,
                            title: Text(
                              option,
                              style: const TextStyle(
                                color: Color(0xFF272A2F),
                                fontSize: 14,
                              ),
                            ),
                            onTap: () {
                              onSelected(option);
                              widget.onOptionSelected?.call(option);
                            },
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

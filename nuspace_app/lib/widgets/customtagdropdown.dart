import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nuspace_app/constants.dart';

class CustomTagDropdown extends StatefulWidget {
  final List<Map<String, String>> allTags;
  final List<String> selectedTags;
  final Future<void> Function({bool loadMore}) fetchTags;
  final Function(List<String> selectedTags) onSelectionChanged;
  final Future<void> Function(String newTag) onCreateTag;
  final FormFieldValidator<List<String>>? validator;
  final bool hasNextPage;

  const CustomTagDropdown({
    super.key,
    required this.allTags,
    required this.selectedTags,
    required this.fetchTags,
    required this.onSelectionChanged,
    required this.onCreateTag,
    required this.hasNextPage,
    this.validator,
  });

  @override
  State<CustomTagDropdown> createState() => _CustomTagDropdownState();
}

class _CustomTagDropdownState extends State<CustomTagDropdown> {
  final ScrollController _scrollController = ScrollController();
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() async {
    // Trigger load more when reaching near bottom
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50) {
      if (widget.hasNextPage && !_loadingMore) {
        setState(() => _loadingMore = true);
        await widget.fetchTags(loadMore: true);
        setState(() => _loadingMore = false);
      }
    }
  }

  void _handleTagTap(Map<String, String> tag) {
    final value = tag['label']!;
    final selected = List<String>.from(widget.selectedTags);

    if (selected.contains(value)) {
      selected.remove(value);
    } else {
      if (selected.length >= 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You can select up to 5 tags only")),
        );
        return;
      }
      selected.add(value);
    }

    widget.onSelectionChanged(selected);
  }

  InlineSpan _highlightText(
    String text,
    String query, {
    bool disabled = false,
  }) {
    final defaultStyle = TextStyle(
      color: disabled ? Colors.grey : Colors.black,
    );

    if (query.isEmpty) return TextSpan(text: text, style: defaultStyle);

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final startIndex = lowerText.indexOf(lowerQuery);
    if (startIndex == -1) return TextSpan(text: text, style: defaultStyle);

    final endIndex = startIndex + lowerQuery.length;
    return TextSpan(
      children: [
        TextSpan(text: text.substring(0, startIndex), style: defaultStyle),
        TextSpan(
          text: text.substring(startIndex, endIndex),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: disabled ? Colors.grey : Colors.blue,
          ),
        ),
        TextSpan(text: text.substring(endIndex), style: defaultStyle),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormField<List<String>>(
      initialValue: widget.selectedTags,
      validator: (value) {
        if (widget.selectedTags.isEmpty) {
          return "Please select at least one tag";
        }
        return null;
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                String localQuery = '';
                bool creatingTag = false;
                final localScrollController = ScrollController();

                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24.r),
                    ),
                  ),
                  builder: (_) {
                    bool localHasNextPage = widget.hasNextPage;
                    bool localLoadingMore = false;

                    return FractionallySizedBox(
                      heightFactor: 0.5,
                      child: StatefulBuilder(
                        builder: (context, setStateModal) {
                          // Filter and sort tags by search query
                          final filteredTags =
                              widget.allTags
                                  .where(
                                    (tag) => tag['label']!
                                        .toLowerCase()
                                        .contains(localQuery.toLowerCase()),
                                  )
                                  .toList()
                                ..sort((a, b) {
                                  final aLabel = a['label']!.toLowerCase();
                                  final bLabel = b['label']!.toLowerCase();
                                  final query = localQuery.toLowerCase();

                                  bool aExact = aLabel == query;
                                  bool bExact = bLabel == query;
                                  bool aStarts = aLabel.startsWith(query);
                                  bool bStarts = bLabel.startsWith(query);

                                  if (aExact && !bExact) return -1;
                                  if (!aExact && bExact) return 1;
                                  if (aStarts && !bStarts) return -1;
                                  if (!aStarts && bStarts) return 1;
                                  return aLabel.compareTo(bLabel);
                                });

                          return Padding(
                            padding: EdgeInsets.only(
                              left: 16,
                              right: 16,
                              top: 16,
                              bottom:
                                  MediaQuery.of(context).viewInsets.bottom + 16,
                            ),
                            child: Column(
                              children: [
                                // Search Field
                                TextField(
                                  style: const TextStyle(color: Colors.black),
                                  decoration: const InputDecoration(
                                    hintText: "Search or create tag...",
                                    hintStyle: TextStyle(color: Colors.black54),
                                    prefixIcon: Icon(
                                      Icons.search,
                                      color: Colors.black,
                                    ),
                                  ),
                                  onChanged:
                                      (val) =>
                                          setStateModal(() => localQuery = val),
                                ),
                                const SizedBox(height: 12),

                                // Tag List
                                Expanded(
                                  child: ListView.builder(
                                    key: ValueKey(localQuery),
                                    controller: localScrollController,
                                    itemCount: filteredTags.length + 1,
                                    itemBuilder: (context, index) {
                                      if (index < filteredTags.length) {
                                        final tag = filteredTags[index];
                                        final isSelected = widget.selectedTags
                                            .contains(tag['label']);
                                        final label = tag['label'] ?? '';

                                        final isDisabled =
                                            !isSelected &&
                                            widget.selectedTags.length >= 5;

                                        return Tooltip(
                                          message:
                                              isDisabled
                                                  ? "Max 5 tags selected"
                                                  : "",
                                          child: ListTile(
                                            title: RichText(
                                              text: _highlightText(
                                                label,
                                                localQuery,
                                                disabled: isDisabled,
                                              ),
                                            ),
                                            trailing: Icon(
                                              isSelected
                                                  ? Icons.check_circle
                                                  : Icons.circle_outlined,
                                              color:
                                                  isDisabled
                                                      ? Colors.grey
                                                      : isSelected
                                                      ? Colors.green
                                                      : Colors.black,
                                            ),
                                            onTap:
                                                isDisabled
                                                    ? null
                                                    : () {
                                                      _handleTagTap(tag);

                                                      field.didChange(
                                                        widget.selectedTags,
                                                      );

                                                      setStateModal(() {});
                                                    },
                                            enabled: !isDisabled,
                                          ),
                                        );
                                      } else {
                                        // Load more button at the end
                                        if (!localHasNextPage) {
                                          return const SizedBox();
                                        }
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8.0,
                                          ),
                                          child: Center(
                                            child:
                                                _loadingMore
                                                    ? const CircularProgressIndicator()
                                                    : ElevatedButton(
                                                      style:
                                                          ElevatedButton.styleFrom(
                                                            backgroundColor:
                                                                nuBlue,
                                                            foregroundColor:
                                                                whitetheme,
                                                          ),
                                                      onPressed: () async {
                                                        setStateModal(
                                                          () =>
                                                              _loadingMore =
                                                                  true,
                                                        );
                                                        await widget.fetchTags(
                                                          loadMore: true,
                                                        );

                                                        // small delay to ensure parent setState completes
                                                        await Future.delayed(
                                                          const Duration(
                                                            milliseconds: 100,
                                                          ),
                                                        );

                                                        setStateModal(() {
                                                          localLoadingMore =
                                                              false;
                                                          localHasNextPage =
                                                              widget
                                                                  .hasNextPage;
                                                        });
                                                        print(
                                                          "Printing fetch tags in custom tag dropdown ${widget.fetchTags}",
                                                        );
                                                      },
                                                      child: const Text(
                                                        "Load more tags",
                                                      ),
                                                    ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),

                                // Create Tag Button
                                if (localQuery.isNotEmpty &&
                                    !filteredTags.any(
                                      (t) =>
                                          t['label']!.toLowerCase() ==
                                          localQuery.toLowerCase(),
                                    ))
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12.0),
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: nuBlue,
                                        foregroundColor: whitetheme,
                                      ),
                                      onPressed:
                                          creatingTag
                                              ? null
                                              : () async {
                                                setStateModal(
                                                  () => creatingTag = true,
                                                );
                                                await widget.onCreateTag(
                                                  localQuery.trim(),
                                                );
                                                setStateModal(() {
                                                  creatingTag = false;
                                                  localQuery = '';
                                                });
                                              },
                                      icon: const Icon(Icons.add),
                                      label:
                                          creatingTag
                                              ? const SizedBox(
                                                height: 16,
                                                width: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                              )
                                              : Text(
                                                'Create tag "$localQuery"',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: "Tags (Maximum of 5 tags)",
                  errorText: field.errorText,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide(
                      color: const Color(0x9C000000),
                      width: 1.5.sp,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide(color: nuBlue, width: 2.sp),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide(color: nuBlue, width: 1.5.sp),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: BorderSide(
                      color: Colors.red.shade400, // Error state border color
                      width: 1.5.sp,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: BorderSide(
                      color: Colors.red.shade900, // Error color when focused
                      width: 2.sp,
                    ),
                  ),
                ),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children:
                      widget.selectedTags.map((value) {
                        final label =
                            widget.allTags.firstWhere(
                              (t) => t['label'] == value,
                              orElse: () => {'label': 'Unknown'},
                            )['label'] ??
                            'Unknown';
                        return Chip(
                          backgroundColor: nuBlue,
                          label: Text(
                            label,
                            style: const TextStyle(color: Colors.white),
                          ),
                          deleteIconColor: whitetheme,
                          onDeleted: () {
                            final updated = List<String>.from(
                              widget.selectedTags,
                            )..remove(value);
                            widget.onSelectionChanged(updated);
                            field.didChange(updated);
                          },
                        );
                      }).toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

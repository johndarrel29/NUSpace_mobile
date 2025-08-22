import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nuspace_app/constants.dart';
import 'package:nuspace_app/utils/image_utils.dart';
import 'package:nuspace_app/widgets/customfont.dart';

class CustomForm extends StatefulWidget {
  final Map<String, dynamic> formJSON;
  final Function(Map<String, dynamic>) onSubmit;

  const CustomForm({super.key, required this.formJSON, required this.onSubmit});

  @override
  State<CustomForm> createState() => _CustomFormState();
}

class _CustomFormState extends State<CustomForm> {
  final _formKey = GlobalKey<FormState>();
  int _currentPage = 0;
  Map<String, Map<String, dynamic>> responses = {};

  // Build minimal form structure with student answers
  Map<String, dynamic> buildMinimalFormWithResponses() {
    final formJSON = widget.formJSON['formJSON'] as Map<String, dynamic>;
    final pages = formJSON['pages'] as List<dynamic>;

    final pagesWithAnswers =
        pages.map((page) {
          final pageName = page['name'] ?? 'page_${pages.indexOf(page)}';
          final pageElements =
              (page['elements'] as List<dynamic>).map((el) {
                final elementName = el['name'];
                final studentAnswer = responses[pageName]?[elementName];

                if (studentAnswer is Map && studentAnswer.containsKey('type')) {
                  // Add 'name' here so backend knows which file corresponds
                  return {
                    ...studentAnswer, // keep type + answer
                    'name': elementName, // <-- add this line
                  };
                }
                return {
                  'type': el['type'],
                  'name': elementName,
                  'answer': studentAnswer,
                };
              }).toList();

          return {
            'name': pageName,
            'title': page['title'],
            'description': page['description'],
            'elements': pageElements,
          };
        }).toList();

    return {'pages': pagesWithAnswers};
  }

  @override
  Widget build(BuildContext context) {
    final formJSON = widget.formJSON['formJSON'] as Map<String, dynamic>;
    final pages = formJSON['pages'] as List<dynamic>;
    final elements = pages[_currentPage]['elements'] as List<dynamic>;
    final pageName = pages[_currentPage]['name'] ?? 'page_$_currentPage';

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 5.h),
              LinearProgressIndicator(value: (_currentPage + 1) / pages.length),
              SizedBox(height: 12.h),

              CustomFont(
                text: pages[_currentPage]['title'] ?? "",
                fontSize: 18.r,
                fontWeight: FontWeight.bold,
              ),
              SizedBox(height: 5.h),
              if (pages[_currentPage]['description'] != null)
                CustomFont(
                  text: pages[_currentPage]['description'],
                  fontSize: 16.r,
                ),

              SizedBox(height: 20.h),

              //render dynamic elements
              ...elements.map(
                (el) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: _buildElement(el, pageName),
                ),
              ),

              SizedBox(height: 20.h),

              //navigation buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: nuBlue),
                      onPressed: () {
                        setState(() {
                          _currentPage--;
                        });
                      },
                      child: CustomFont(
                        text: "Back",
                        fontSize: 14.r,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),

                  Spacer(),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: nuBlue),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        //if not last page then go next page
                        if (_currentPage < pages.length - 1) {
                          setState(() {
                            _currentPage++;
                          });
                        } else {
                          //last page then submit
                          final minimalForm = buildMinimalFormWithResponses();
                          widget.onSubmit(minimalForm);
                        }
                      }
                    },
                    child: CustomFont(
                      text:
                          _currentPage == pages.length - 1 ? "Submit" : "Next",
                      fontSize: 14.r,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildElement(Map<String, dynamic> element, String pageName) {
    final name = element['name'];
    final title = element['title'] ?? name;
    bool isRequired = element['isRequired'] ?? false;

    //ensure the page entry exists in responses
    responses[pageName] = responses[pageName] ?? {};

    switch (element['type']) {
      case 'text': //single-line input (Text)
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CustomFont(
                  text: title,
                  fontSize: 16.r,
                  fontWeight: FontWeight.w500,
                ),
                if (isRequired) ...[
                  SizedBox(width: 5.w),
                  CustomFont(
                    text: "*",
                    fontSize: 16.r,
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ],
            ),
            SizedBox(height: 10.h),
            TextFormField(
              key: ValueKey(name),
              initialValue: responses[pageName]![name] ?? "",
              style: TextStyle(fontSize: 14.r),
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(width: 1.r),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: nuBlue, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Colors.red, width: 1),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Colors.red, width: 2),
                ),
                errorStyle: TextStyle(fontSize: 12.r),
              ),
              validator: (value) {
                if (isRequired && (value == null || value.isEmpty)) {
                  return "This field is required";
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  responses[pageName]![name] = value;
                });
              },
            ),
          ],
        );

      case 'comment': //multi-line (long text)
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CustomFont(
                  text: title,
                  fontSize: 16.r,
                  fontWeight: FontWeight.w500,
                ),
                if (isRequired) ...[
                  SizedBox(width: 5.w),
                  CustomFont(
                    text: "*",
                    fontSize: 16.r,
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ],
            ),
            SizedBox(height: 10.h),
            TextFormField(
              key: ValueKey(name),
              initialValue: responses[pageName]?[name] ?? "",
              style: TextStyle(fontSize: 14.r),
              maxLines: 4,
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(width: 1.r),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: nuBlue, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Colors.red, width: 1),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Colors.red, width: 2),
                ),
                errorStyle: TextStyle(fontSize: 12.r),
              ),
              validator: (value) {
                if (isRequired && (value == null || value.isEmpty)) {
                  return "This field is required";
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  responses[pageName]![name] = value;
                });
              },
            ),
          ],
        );

      case 'radiogroup': //radio button group
        return FormField<String>(
          initialValue: responses[pageName]?[name]?['answer'],
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return "This field is required";
            }
            return null;
          },
          builder: (formFieldState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CustomFont(
                      text: title,
                      fontSize: 16.r,
                      fontWeight: FontWeight.w500,
                    ),
                    if (isRequired) ...[
                      SizedBox(width: 5.w),
                      CustomFont(
                        text: "*",
                        fontSize: 16.r,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 5.h),
                ...List<Widget>.from(
                  (element['choices'] ?? []).map(
                    (choice) => RadioListTile(
                      key: ValueKey("$name-$choice"),
                      radioScaleFactor: 1.r,
                      activeColor: nuBlue,
                      title: CustomFont(text: choice, fontSize: 16.r),
                      value: choice,
                      groupValue: formFieldState.value,
                      onChanged: (value) {
                        setState(() {
                          responses[pageName]![name] = {
                            'type': element['type'],
                            'answer': value,
                          };
                        });
                        formFieldState.didChange(value);
                      },
                    ),
                  ),
                ),

                if (formFieldState.hasError)
                  Padding(
                    padding: EdgeInsets.only(top: 4.h, left: 12.w),
                    child: CustomFont(
                      text: formFieldState.errorText!,
                      fontSize: 12.r,
                      color: Colors.red.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            );
          },
        );

      case 'rating': // rating scale
        final rateValues = element['rateValues'];
        final rateMax = element['rateMax'] ?? 5;
        final rateMin = element['rateMin'] ?? 1;

        return FormField<int>(
          validator: (value) {
            if (isRequired && (responses[pageName]?[name]?['answer'] == null)) {
              return 'This question is required';
            }
            return null;
          },
          builder: (field) {
            final currentValue = responses[pageName]?[name]?['answer'];

            if (rateValues != null &&
                rateValues is List &&
                rateValues.isNotEmpty) {
              // Custom labels (SurveyJS style)
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CustomFont(
                        text: title,
                        fontSize: 16.r,
                        fontWeight: FontWeight.w500,
                      ),
                      if (isRequired) ...[
                        SizedBox(width: 5.w),
                        CustomFont(
                          text: "*",
                          fontSize: 16.r,
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Wrap(
                    spacing: 8.w,
                    children:
                        rateValues.map<Widget>((v) {
                          final int value = v is Map ? v['value'] : v;
                          final String label =
                              v is Map
                                  ? (v['text'] ?? value.toString())
                                  : value.toString();
                          final isSelected = currentValue == value;

                          return ChoiceChip(
                            label: CustomFont(
                              text: label,
                              fontSize: 14.r,
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                            backgroundColor: Colors.grey.shade200,
                            showCheckmark: false,
                            selectedColor: nuBlue,
                            selected: isSelected,
                            onSelected: (_) {
                              setState(() {
                                responses[pageName]![name] = {
                                  'type': element['type'],
                                  'answer': value,
                                };
                                field.didChange(
                                  value,
                                ); // important for validation
                              });
                            },
                          );
                        }).toList(),
                  ),
                  if (field.hasError)
                    Padding(
                      padding: EdgeInsets.only(top: 5.h),
                      child: CustomFont(
                        text: field.errorText ?? '',
                        fontSize: 12.r,
                        color: Colors.red.shade900,
                      ),
                    ),
                ],
              );
            } else {
              // Fallback: numeric slider
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CustomFont(
                        text: title,
                        fontSize: 16.r,
                        fontWeight: FontWeight.w500,
                      ),
                      if (isRequired) ...[
                        SizedBox(width: 5.w),
                        CustomFont(
                          text: "*",
                          fontSize: 16.r,
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ],
                    ],
                  ),
                  Slider(
                    min: rateMin.toDouble(),
                    max: rateMax.toDouble(),
                    divisions: rateMax - rateMin,
                    value: (currentValue ?? rateMin).toDouble(),
                    label: currentValue?.toString() ?? '',
                    onChanged: (value) {
                      setState(() {
                        responses[pageName]![name] = {
                          'type': element['type'],
                          'answer': value.round(),
                        };
                        field.didChange(value.round()); // tell FormField
                      });
                    },
                  ),
                  if (field.hasError)
                    Padding(
                      padding: EdgeInsets.only(top: 5.h),
                      child: CustomFont(
                        text: field.errorText ?? '',
                        fontSize: 12.r,
                        color: Colors.red.shade900,
                      ),
                    ),
                ],
              );
            }
          },
        );

      case 'checkbox': // multi-select
        return FormField<List<String>>(
          initialValue: List<String>.from(
            responses[pageName]?[name]?['answer'] ?? [],
          ),
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return "Please select at least one option";
            }
            return null;
          },
          builder: (formFieldState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CustomFont(
                      text: title,
                      fontSize: 16.r,
                      fontWeight: FontWeight.w500,
                    ),
                    if (isRequired) ...[
                      SizedBox(width: 5.w),
                      CustomFont(
                        text: "*",
                        fontSize: 16.r,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 10.h),
                ...List<Widget>.from(
                  (element['choices'] ?? []).map((choice) {
                    final current = List<String>.from(
                      formFieldState.value ?? [],
                    );
                    final isChecked = current.contains(choice);

                    return CheckboxListTile(
                      key: ValueKey("$name-$choice"),
                      checkboxScaleFactor: 1.r,
                      activeColor: nuBlue,
                      title: CustomFont(text: choice, fontSize: 16.r),
                      value: isChecked,
                      onChanged: (checked) {
                        final updated = List<String>.from(current);
                        if (checked == true) {
                          updated.add(choice);
                        } else {
                          updated.remove(choice);
                        }

                        setState(() {
                          responses[pageName]![name] = {
                            'type': element['type'],
                            'answer': updated,
                          };
                        });
                        formFieldState.didChange(updated);
                      },
                    );
                  }),
                ),

                if (formFieldState.hasError)
                  Padding(
                    padding: EdgeInsets.only(top: 4.h, left: 12.w),
                    child: CustomFont(
                      text: formFieldState.errorText!,
                      fontSize: 12.r,
                      color: Colors.red.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            );
          },
        );

      case 'dropdown': //single-select dropdown
        return Column(
          children: [
            Row(
              children: [
                CustomFont(
                  text: title,
                  fontSize: 16.r,
                  fontWeight: FontWeight.w500,
                ),
                if (isRequired) ...[
                  SizedBox(width: 5.w),
                  CustomFont(
                    text: "*",
                    fontSize: 16.r,
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ],
            ),
            SizedBox(height: 10.h),
            DropdownButtonFormField<String>(
              style: TextStyle(fontSize: 14.r),
              decoration: InputDecoration(
                hintText: "Choose...",
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(width: 1.r),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: nuBlue, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Colors.red, width: 1),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Colors.red, width: 2),
                ),
                errorStyle: TextStyle(fontSize: 12.r),
              ),
              value: responses[pageName]?[name]?['answer'] as String?,
              dropdownColor: Colors.white,
              items:
                  (element['choices'] as List<dynamic>)
                      .map<DropdownMenuItem<String>>(
                        (choice) => DropdownMenuItem<String>(
                          value: choice,
                          child: CustomFont(
                            text: choice,
                            fontSize: 16.r,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                setState(() {
                  responses[pageName]![name] = {
                    'type': element['type'],
                    'answer': value,
                  };
                });
              },
              validator: (value) {
                if (isRequired && value == null) {
                  return "This field is required";
                }
                return null;
              },
            ),
          ],
        );

      case 'tagbox': //multi-select dropdown
        return FormField<List<String>>(
          initialValue:
              ((responses[pageName]?[name]?['answer'] ?? []) as List)
                  .map((e) => e.toString())
                  .toList(),
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return "Please select at least one option";
            }
            return null;
          },
          builder: (formFieldState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CustomFont(
                      text: title,
                      fontSize: 16.r,
                      fontWeight: FontWeight.w500,
                    ),
                    if (isRequired) ...[
                      SizedBox(width: 5.w),
                      CustomFont(
                        text: "*",
                        fontSize: 16.r,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 10.h),

                Wrap(
                  spacing: 8.w,
                  children:
                      (element['choices'] ?? []).map<Widget>((choice) {
                        final selected =
                            (responses[pageName]?[name]?['answer'] ?? [])
                                .contains(choice);
                        return FilterChip(
                          selectedColor: nuBlue,
                          backgroundColor: Colors.grey.shade200,
                          showCheckmark: false,
                          label: CustomFont(
                            text: choice,
                            fontSize: 14.r,
                            color: selected ? Colors.white : Colors.black,
                          ),
                          selected: selected,
                          onSelected: (val) {
                            setState(() {
                              final current = List<String>.from(
                                responses[pageName]?[name]?['answer'] ?? [],
                              );
                              if (val) {
                                current.add(choice);
                              } else {
                                current.remove(choice);
                              }
                              responses[pageName]![name] = {
                                'type': element['type'],
                                'answer': current,
                              };
                            });
                            formFieldState.didChange(
                              responses[pageName]![name]?['answer'],
                            );
                          },
                        );
                      }).toList(),
                ),

                if (formFieldState.hasError)
                  Padding(
                    padding: EdgeInsets.only(top: 4.h, left: 4.w),
                    child: CustomFont(
                      text: formFieldState.errorText!,
                      fontSize: 12.r,
                      color: Colors.red.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            );
          },
        );

      case 'file': // file upload (image picker with compression)
        return FormField<String>(
          validator: (value) {
            if (isRequired &&
                (responses[pageName]?[name] == null ||
                    responses[pageName]?[name]!.isEmpty)) {
              return 'This field is required';
            }
            return null;
          },
          builder: (field) {
            final filePath = responses[pageName]?[name]?['answer'];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CustomFont(
                      text: title,
                      fontSize: 16.r,
                      fontWeight: FontWeight.w500,
                    ),
                    if (isRequired) ...[
                      SizedBox(width: 5.w),
                      CustomFont(
                        text: "*",
                        fontSize: 16.r,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 10.h),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: nuBlue),
                  onPressed: () async {
                    print("picking image..");
                    final pickedFile = await ImageHelper.pickImageFromGallery();

                    if (pickedFile != null) {
                      // compress it
                      final compressedFile = await ImageHelper.compressImage(
                        pickedFile,
                      );

                      if (compressedFile != null) {
                        setState(() {
                          responses[pageName]![name] = {
                            'type': element['type'],
                            'answer': compressedFile.path,
                          };
                        });
                        field.didChange(compressedFile.path);
                      }
                    }
                  },
                  child: CustomFont(
                    text: "Upload Image",
                    fontSize: 14.r,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                if (filePath != null) ...[
                  SizedBox(height: 8.h),
                  Image.file(
                    File(filePath),
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                  SizedBox(height: 8.h),
                  CustomFont(text: filePath, fontSize: 14.r),
                ],
                if (field.hasError)
                  Padding(
                    padding: EdgeInsets.only(top: 5.h),
                    child: CustomFont(
                      text: field.errorText ?? "",
                      fontSize: 12.r,
                      color: Colors.red.shade900,
                    ),
                  ),
              ],
            );
          },
        );

      default:
        return SizedBox();
    }
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mime/mime.dart';
import 'package:nuspace_app/screens/authentication/rsocreation_verification.dart';
import 'package:nuspace_app/widgets/customdialog.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../config/config.dart';
import '../../constants.dart';
import '../../services/api_service.dart';
import '../../services/connectivity_service.dart';
import '../../utils/image_utils.dart';
import '../../utils/internalserverdialog.dart';
import '../../widgets/custombutton.dart';
import '../../widgets/customdropdown.dart';
import '../../widgets/customfont.dart';
import '../../widgets/customtagdropdown.dart';
import '../../widgets/customtextformfield.dart';
import '../../widgets/snackbarhelper.dart';

class CreateRSOScreen extends StatefulWidget {
  const CreateRSOScreen({super.key});

  @override
  State<CreateRSOScreen> createState() => _CreateRSOScreenState();
}

class _CreateRSOScreenState extends State<CreateRSOScreen> {
  final TextEditingController _rsonamecontroller = TextEditingController();
  final TextEditingController _rsoacronymcontroller = TextEditingController();
  final TextEditingController _rsodescriptioncontroller =
      TextEditingController();

  final _formKey = GlobalKey<FormState>();
  List<String> selectedTags = []; //to store tag names/labels
  List<Map<String, String>> allTags = [];
  List<Map<String, dynamic>> rsoAdvisers = [];
  bool _loadingScreen = false;

  bool _isLoading = false;
  String? _errormessage,
      selectedCollege,
      selectedCategory,
      selectedAdviserLabel,
      selectedAdviserId;
  File? _selectedImage;

  int limit = 25;
  int page = 1;
  bool hasNextPage = true;

  late ConnectivityService connectivityService;

  final List<Map<String, dynamic>> collegesWithIcons = [
    {"label": "CCIT", "icon": Icons.computer},
    {"label": "CBA", "icon": Icons.business},
    {"label": "COA", "icon": Icons.account_balance},
    {"label": "COE", "icon": Icons.engineering},
    {"label": "CAH", "icon": Icons.medical_services},
    {"label": "CEAS", "icon": Icons.school},
    {"label": "CTHM", "icon": Icons.travel_explore},
  ];

  final List<Map<String, dynamic>> categoryOptions = [
    {"label": "Professional & Affiliates", "icon": Icons.groups},
    {"label": "Professional", "icon": Icons.work},
    {"label": "Special Interest", "icon": Icons.star},
    {"label": "Office Aligned Organization", "icon": Icons.apartment},
  ];

  @override
  void dispose() {
    _rsonamecontroller.dispose();
    _rsoacronymcontroller.dispose();
    _rsodescriptioncontroller.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    connectivityService = Provider.of<ConnectivityService>(
      context,
      listen: false,
    );
    fetchRSOAdvisers();
    fetchTagsChoices();
  }

  Future<void> fetchRSOAdvisers() async {
    setState(() {
      _loadingScreen = true;
      _errormessage = null;
    });

    //check for internet connection
    if (!connectivityService.isConnected) {
      print("No Internet Connection");
      SnackbarHelper.showConnectivityStatus(false);
      setState(() => _loadingScreen = false);
      return;
    }

    try {
      final response = await apiRequest((accessToken) {
        return http
            .get(
              Uri.parse('${AppConfig.baseUrl}/api/student/user/fetch-advisers'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': accessToken,
              },
            )
            .timeout(Duration(seconds: 20));
      }, context: mounted ? context : null);

      if (response == null) return; //session expired

      final responseData = jsonDecode(response.body);
      print("Response data: $responseData");
      if (response.statusCode == 200 && responseData['success'] == true) {
        final List<dynamic> advisersData = responseData['advisers'] ?? [];

        setState(() {
          rsoAdvisers =
              advisersData.map((adviser) {
                final fullName =
                    '${adviser['firstName']} ${adviser['middleName'] ?? ''} ${adviser['lastName']}'
                        .replaceAll(RegExp(r'\s+'), ' ')
                        .trim();

                return {
                  'label': fullName,
                  'value': adviser['_id'], // store the id for backend use
                  'icon': Icons.person, // optional
                };
              }).toList();

          _errormessage = null;
        });

        print(
          "Fetched ${rsoAdvisers.length} unassigned RSO advisers: $rsoAdvisers",
        );
      } else {
        print(
          "error code ${response.statusCode} and message ${responseData['message']}",
        );
        setState(() {
          rsoAdvisers = [];
          _errormessage = responseData['message'];
        });
      }
    } on TimeoutException {
      // Handle Timeout (Server Down)
      print("Server Timeout! Navigating to Internal Server Error screen.");
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const InternalServerDialog(),
        );
      }
    } catch (e, stackTrace) {
      SnackbarHelper.showSnackbar(
        "An error occurred. Please try again.",
        backgroundColor: Colors.red,
      );
      print("Error in login $e");
      print("stacktrace: $stackTrace");
    } finally {
      if (mounted) {
        setState(() => _loadingScreen = false);
      }
    }
  }

  //logic for tags fetch
  Future<void> fetchTagsChoices({bool loadMore = false}) async {
    print("printing selected Tags: $selectedTags");
    if (loadMore) {
      page++; // increment page only if loading more
    } else {
      page = 1; // reset to first page if it's a fresh fetch
      allTags.clear(); // clear old tags if not loading more
    }

    setState(() {
      _errormessage = null;
    });

    //check for internet connection
    if (!connectivityService.isConnected) {
      print("No Internet Connection");
      SnackbarHelper.showConnectivityStatus(false);
      return;
    }

    try {
      final response = await apiRequest((accessToken) {
        return http
            .get(
              Uri.parse(
                '${AppConfig.baseUrl}/api/tags/tagsChoices?page=$page&limit=$limit',
              ),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': accessToken,
              },
            )
            .timeout(Duration(seconds: 20));
      }, context: mounted ? context : null);

      if (response == null) return; //session expired

      final responseData = jsonDecode(response.body);
      print("Response data: $responseData");
      if (response.statusCode == 200 && responseData['success'] == true) {
        final newTags = List<Map<String, String>>.from(
          responseData['tags'].map(
            (tag) => {
              'label': tag['label'].toString(),
              'value': tag['value'].toString(),
            },
          ),
        );

        if (mounted) {
          setState(() {
            if (loadMore) {
              allTags.addAll(newTags);
            } else {
              // Merge selected tags into newTags
              // Keep previously fetched tags (including pages > 1)
              final existingTagMap = {
                for (var tag in allTags) tag['value']!: tag['label']!,
              };

              // Merge newTags from API
              for (var tag in newTags) {
                existingTagMap[tag['value']!] = tag['label']!;
              }

              // Build merged allTags
              allTags =
                  existingTagMap.entries
                      .map((e) => {'value': e.key, 'label': e.value})
                      .toList();
            }

            hasNextPage = responseData['pagination']?['hasNextPage'] ?? false;
          });
        }
      } else {
        print(
          "error code ${response.statusCode} and message ${responseData['message']}",
        );
        setState(() {
          allTags = [];
          _errormessage = responseData['message'];
        });
      }
    } on TimeoutException {
      // Handle Timeout (Server Down)
      print("Server Timeout! Navigating to Internal Server Error screen.");
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const InternalServerDialog(),
        );
      }
    } catch (e, stackTrace) {
      SnackbarHelper.showSnackbar(
        "An error occurred. Please try again.",
        backgroundColor: Colors.red,
      );
      print("Error in login $e");
      print("stacktrace: $stackTrace");
    }
  }

  //create new Tag
  Future<void> createTag(String newTag) async {
    //check for internet connection
    if (!connectivityService.isConnected) {
      print("No Internet Connection");
      SnackbarHelper.showConnectivityStatus(false);
      return;
    }

    try {
      final response = await apiRequest((accessToken) {
        return http
            .post(
              Uri.parse('${AppConfig.baseUrl}/api/tags/createTags'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': accessToken,
              },
              body: jsonEncode({'tag': newTag}),
            )
            .timeout(Duration(seconds: 20));
      }, context: mounted ? context : null);

      if (response == null) return;

      final responseData = jsonDecode(response.body);
      print("Create tag response: $responseData");

      if (response.statusCode == 200 && responseData['success'] == true) {
        final createdTag = {
          'label': responseData['tag']['tag'].toString(), // display label
          'value': responseData['tag']['_id'].toString(), // ObjectId
        };

        // Add new tag to allTags and select it
        setState(() {
          allTags.insert(0, createdTag); // show new tag at the top
          selectedTags.add(createdTag['label']!); // automatically select
        });

        SnackbarHelper.showSnackbar(
          "New Tag created successfully!",
          backgroundColor: Colors.green,
        );
      } else {
        // Error message from server
        SnackbarHelper.showSnackbar(
          responseData['message'] ?? "Failed to create tag",
          backgroundColor: Colors.red,
        );
      }
    } on TimeoutException {
      // Handle Timeout (Server Down)
      print("Server Timeout! Navigating to Internal Server Error screen.");
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const InternalServerDialog(),
        );
      }
    } catch (e, stackTrace) {
      SnackbarHelper.showSnackbar(
        "An error occurred. Please try again.",
        backgroundColor: Colors.red,
      );
      print("Error in login $e");
      print("stacktrace: $stackTrace");
    }
  }

  //logic for submit application
  Future<void> submitRSOApplication() async {
    //check for internet connection
    if (!connectivityService.isConnected) {
      print("No Internet Connection");
      SnackbarHelper.showConnectivityStatus(false);
      setState(() => _isLoading = false);
      return;
    }
    //fetch token
    final token = await storage.read(key: "auth_token");
    if (token == null) {
      print("No auth token found, navigating to landing screen!");
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/landingScreen', (route) => false);
        SnackbarHelper.showSnackbar(
          "Token expired or not found",
          backgroundColor: Colors.red,
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    //fetch email
    final email = await storage.read(key: "user_email");

    //send email code
    final sendCodeResponse = await http.post(
      Uri.parse('${AppConfig.baseUrl}/api/auth/send-email-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"email": email}),
    );

    final sendCodeDecoded = jsonDecode(sendCodeResponse.body);
    if (sendCodeResponse.statusCode != 200 ||
        sendCodeDecoded['success'] != true) {
      SnackbarHelper.showSnackbar(
        "Failed to send verification code.",
        backgroundColor: Colors.red,
      );
      setState(() => _isLoading = false);
      return;
    }

    //go to verification screen and wait for confirmation
    final verified = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => RSOCreationVerification(email: email)),
    );

    if (verified != true) {
      //user did not verify, stop submission
      SnackbarHelper.showSnackbar(
        "Email verification is required to submit the RSO application.",
        backgroundColor: Colors.red,
      );
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = false);

    if (!_formKey.currentState!.validate()) return;

    if (selectedAdviserId == null) {
      SnackbarHelper.showSnackbar("Please select an adviser");
      return;
    }

    if (selectedCategory == null) {
      SnackbarHelper.showSnackbar("Please select a category");
      return;
    }

    if (_selectedImage == null) {
      SnackbarHelper.showSnackbar("Please select an image/logo");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uri = Uri.parse(
        '${AppConfig.baseUrl}/api/student/rso/new-rso/application',
      );

      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = token;

      //attach non-file fields
      request.fields['RSO_name'] = _rsonamecontroller.text.trim();
      request.fields['RSO_acronym'] = _rsoacronymcontroller.text.trim();
      request.fields['RSO_description'] = _rsodescriptioncontroller.text.trim();
      request.fields['RSO_category'] = selectedCategory!;
      request.fields['RSO_Adviser'] = selectedAdviserId!;
      request.fields['RSO_tags'] = jsonEncode(selectedTags); // tag IDs list

      if (selectedCollege != null) {
        request.fields['RSO_College'] = selectedCollege!;
      }

      // Attach logo/image file
      if (_selectedImage != null) {
        final mimeType = lookupMimeType(_selectedImage!.path) ?? 'image/jpeg';
        final mimeParts = mimeType.split('/');
        final contentType =
            (mimeParts.length == 2)
                ? MediaType(mimeParts[0], mimeParts[1])
                : MediaType('image', 'jpeg');

        request.files.add(
          await http.MultipartFile.fromPath(
            'RSO_image',
            _selectedImage!.path,
            contentType: contentType,
          ),
        );
      }

      print("Submitting RSO Application fields: ${request.fields}");

      //send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final decoded = jsonDecode(response.body);
      print("Printing decoded $decoded");

      if (response.statusCode == 201 && decoded['success'] == true) {
        if (mounted) {
          String userRole = decoded['presRole'];
          await storage.write(key: "user_role", value: userRole);

          showDialog(
            context: context,
            builder:
                (_) => SuccessDialog(
                  title: "RSO Application Submitted",
                  message:
                      "Your RSO application has been successfully submitted.\nYou can now access the web application to send your documents.",
                  onClose: () {
                    Navigator.of(context).pop(); // close the dialog
                    Navigator.pop(
                      context,
                      userRole,
                    ); // go back or redirect after closing
                  },
                ),
          );
        }
      } else {
        print("Error response submit: ${decoded['message']}");
        SnackbarHelper.showSnackbar(
          decoded['message'] ?? "Failed to submit RSO application",
          backgroundColor: Colors.red,
        );
      }
    } on TimeoutException {
      print("Server Timeout! Navigating to Internal Server Error screen.");
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const InternalServerDialog(),
        );
      }
    } catch (e, stack) {
      print("Error submitting RSO: $e");
      print("Stacktrace: $stack");
      SnackbarHelper.showSnackbar(
        "An unexpected error occurred. Please try again.",
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whitetheme,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        centerTitle: true,
        scrolledUnderElevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () async {
            FocusScope.of(context).unfocus(); // First dismiss keyboard
            await Future.delayed(
              const Duration(milliseconds: 300),
            ); // Wait for keyboard to fully close

            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          icon: Icon(Icons.arrow_back, size: 24.r),
        ),
        backgroundColor: whitetheme,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                "assets/images/nuspace_whitelogo.png",
                color: nuBlue,
                height: 30.r,
                width: 30.r,
              ),
              SizedBox(width: 5.w),
              CustomFont(
                text: "NU",
                fontSize: 22.r,
                color: nuGold,
                useGoogleFont: false,
                fontFamily: 'ClanOT',
                fontWeight: FontWeight.bold,
              ),
              CustomFont(
                text: "Space",
                fontSize: 22.r,
                color: nuBlue,
                useGoogleFont: false,
                fontFamily: 'ClanOT',
                fontWeight: FontWeight.bold,
              ),
            ],
          ),
        ),
      ),
      body:
          _loadingScreen
              ? Center(
                child: Semantics(
                  label: 'Loading screen, please wait',
                  child: CircularProgressIndicator(
                    color: nuBlue,
                    strokeAlign: 5,
                  ),
                ),
              )
              : !connectivityService.isConnected
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.wifi_off,
                      color: Colors.grey.shade600,
                      size: 50.r,
                    ),
                    CustomFont(
                      text: "Connect to Internet",
                      fontSize: 16.r,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
              )
              : GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 20.h,
                  ),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.manual,
                      child: Column(
                        children: [
                          Center(
                            child: CustomFont(
                              text: "RSO Application",
                              fontSize: 24.r,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          SizedBox(height: 20.h),
                          CustomTextFormField(
                            labelText: "RSO Name",
                            hintText: "Ex. Junior Philippine Computer Society",
                            controller: _rsonamecontroller,
                            height: 10.r,
                            width: 20.r,
                            prefixIcon: Icons.apartment,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please enter RSO name";
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20.h),
                          CustomTextFormField(
                            labelText: "RSO Acronym",
                            hintText: "Ex. JPCS",
                            controller: _rsoacronymcontroller,
                            height: 10.r,
                            width: 20.r,
                            prefixIcon: Icons.apartment,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please enter RSO Acronym";
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20.h),
                          CustomDropDownMenu(
                            labelText: "Select Adviser",
                            options: rsoAdvisers,
                            selectedValue: selectedAdviserLabel,
                            onChanged: (value) {
                              setState(() {
                                selectedAdviserLabel = value;
                                selectedAdviserId =
                                    rsoAdvisers.firstWhere(
                                      (a) => a["label"] == value,
                                    )["value"];

                                print(
                                  "Selected adviser id: $selectedAdviserId",
                                );
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please enter RSO Adviser";
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 20.h),
                          CustomTextFormField(
                            labelText: "RSO Description",
                            hintText: "",
                            controller: _rsodescriptioncontroller,
                            height: 10.r,
                            width: 20.r,
                            isMultiline: true,
                            maxLine: 3,
                            prefixIcon: Icons.apartment,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please enter RSO Description";
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20.h),

                          CustomDropDownMenu(
                            labelText: "Select Category",
                            options: categoryOptions,
                            selectedValue: selectedCategory,
                            onChanged: (value) {
                              setState(() {
                                selectedCategory = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please select category";
                              }
                              return null;
                            },
                            prefixIcon: Icons.category,
                          ),
                          SizedBox(height: 20.h),
                          CustomDropDownMenu(
                            labelText: "Select College (If Applicable)",
                            options: collegesWithIcons,
                            selectedValue: selectedCollege,
                            onChanged: (value) {
                              setState(() {
                                selectedCollege = value;
                              });
                            },
                            prefixIcon: Icons.school,
                          ),
                          SizedBox(height: 20.h),
                          CustomTagDropdown(
                            allTags: allTags,
                            selectedTags: selectedTags,
                            fetchTags: fetchTagsChoices,
                            hasNextPage: hasNextPage,
                            onSelectionChanged: (tags) {
                              setState(() => selectedTags = tags);
                            },
                            onCreateTag: (newTag) async {
                              await createTag(newTag);
                            },
                            validator: (value) {
                              if (selectedTags.isEmpty) {
                                return "Please select at least one tag";
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 20.h),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: CustomFont(
                              text: "RSO Logo",
                              fontSize: 16.r,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 10.h),
                          Stack(
                            //image
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  final pickedFile =
                                      await ImageHelper.pickImageFromGallery();
                                  if (pickedFile != null) {
                                    final compressed =
                                        await ImageHelper.compressImage(
                                          pickedFile,
                                        );
                                    setState(() {
                                      _selectedImage = compressed ?? pickedFile;
                                    });
                                    print("Selected image: $_selectedImage");
                                  }
                                },
                                child: Container(
                                  height: 180.w,
                                  width: 180.w,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade400,
                                    ),
                                    borderRadius: BorderRadius.circular(12.r),
                                    color: Colors.grey.shade100,
                                  ),
                                  child:
                                      _selectedImage != null
                                          ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12.r,
                                            ),
                                            child: Image.file(
                                              _selectedImage!,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                            ),
                                          )
                                          : Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.image_outlined,
                                                  color: Colors.grey,
                                                  size: 40.r,
                                                ),
                                                SizedBox(height: 8.h),
                                                CustomFont(
                                                  text: "Tap to upload logo",
                                                  fontSize: 14.r,
                                                  color: Colors.grey,
                                                ),
                                              ],
                                            ),
                                          ),
                                ),
                              ),

                              // Remove button (visible only if image is selected)
                              if (_selectedImage != null)
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedImage = null;
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 18.r,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 25.h),
                          if (_errormessage != null)
                            CustomFont(
                              text: _errormessage!,
                              fontSize: 14.r,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          SizedBox(height: 25.h),
                          CustomButton(
                            text: "Submit Application",
                            height: 45.h,
                            fontSize: 14.r,
                            fontweight: FontWeight.bold,
                            isLoading: _isLoading,
                            onPressed: () {
                              print("Creating a new RSO");
                              submitRSOApplication();
                            },
                          ),
                          SizedBox(height: 25.h),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
    );
  }
}

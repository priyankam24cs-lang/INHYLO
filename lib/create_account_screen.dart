
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() =>
      _CreateAccountScreenState();
}

class _CreateAccountScreenState
    extends State<CreateAccountScreen> {

  final _formKey = GlobalKey<FormState>();

  final brandController = TextEditingController();
  final nameController = TextEditingController();
  final mobileController = TextEditingController();
  final emailController = TextEditingController();
  final gstController = TextEditingController();

  bool agreed = false;
  bool loading = false;

  static const yellow = Color(0xFFFFE34D);
  static const black = Color(0xFF111111);
  static const bg = Color(0xFFFAFAF7);
  static const hint = Color(0xFF929292);
  static const border = Color(0xFFAAAAAA);
  static const red = Color(0xFF9C2630);

  @override
  void dispose() {
    brandController.dispose();
    nameController.dispose();
    mobileController.dispose();
    emailController.dispose();
    gstController.dispose();
    super.dispose();
  }

  String? validateBrand(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter your brand name';
    }
    if (value.trim().length < 2) {
      return 'Name is too short';
    }
    return null;
  }

  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter your name';
    }
    return null;
  }

  String? validateMobile(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter mobile number';
    }
    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(value)) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$')
            .hasMatch(value.trim())) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? validateGST(String? value) {
    if (value == null || value.isEmpty) return null;

    if (!RegExp(
      r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$',
    ).hasMatch(value)) {
      return 'Enter a valid GST number';
    }
    return null;
  }

  void createAccount() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (!agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the terms and conditions'),
        ),
      );
      return;
    }

    setState(() => loading = true);

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() => loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Account created for ${brandController.text} (demo)',
        ),
      ),
    );
  }

  Widget label(String text, {String suffix = ''}) {
    return Padding(
      padding: const EdgeInsets.only(top: 17, bottom: 9),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: black,
          ),
          children: [
            TextSpan(text: text),
            TextSpan(
              text: suffix,
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }

  Widget inputField({
    required TextEditingController controller,
    required String hintText,
    required String? Function(String?) validator,
    TextInputType keyboard = TextInputType.text,
    String? prefix,
    List<TextInputFormatter>? formatters,
    TextCapitalization capitalization =
        TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboard,
      inputFormatters: formatters,
      textCapitalization: capitalization,
      style: const TextStyle(
        fontSize: 16,
        color: black,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: hint,
          fontSize: 16,
        ),
        prefixText: prefix,
        prefixStyle: const TextStyle(
          color: black,
          fontSize: 16,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 17,
          vertical: 20,
        ),
        errorStyle: const TextStyle(
          color: red,
          fontSize: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(
            color: black,
            width: 1.7,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: red),
        ),
      ),
    );
  }

  Widget buildHeader() {
    return Container(
      color: yellow,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  '‹  Back to login',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Create your brand\naccount',
              style: TextStyle(
                fontSize: 37,
                height: 1.12,
                fontWeight: FontWeight.w800,
                color: black,
              ),
            ),
            const SizedBox(height: 13),
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 16,
                  color: black,
                ),
                children: [
                  TextSpan(text: 'Step 1 of '),
                  TextSpan(
                    text: '1',
                    style: TextStyle(
                      color: red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(text: ' · takes about a minute'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildLogo() {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Logo upload will be added later'),
              ),
            );
          },
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8B0),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: black,
                width: 1.7,
                style: BorderStyle.solid,
              ),
            ),
            child: const Icon(
              Icons.add,
              size: 45,
              color: black,
            ),
          ),
        ),
        const SizedBox(width: 18),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Brand logo',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: black,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Optional',
              style: TextStyle(
                fontSize: 16,
                color: hint,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildTerms() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: agreed,
          activeColor: black,
          checkColor: yellow,
          side: const BorderSide(
            color: black,
            width: 1.8,
          ),
          onChanged: (value) {
            setState(() {
              agreed = value ?? false;
            });
          },
        ),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 11),
            child: Text(
              'I agree to the INHYLO advertiser terms and ad content rules.',
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: black,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: loading ? null : createAccount,
        style: ElevatedButton.styleFrom(
          backgroundColor: black,
          foregroundColor: yellow,
          disabledBackgroundColor: black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(35),
          ),
          elevation: 0,
        ),
        child: loading
            ? const CircularProgressIndicator(
                color: yellow,
              )
            : const Text(
                'Create account',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              buildHeader(),

              Padding(
                padding: const EdgeInsets.fromLTRB(
                  22, 22, 22, 30,
                ),
                child: SafeArea(
                  top: false,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildLogo(),

                        label('Brand / company name'),
                        inputField(
                          controller: brandController,
                          hintText: '[BRAND NAME]',
                          validator: validateBrand,
                          capitalization:
                              TextCapitalization.words,
                        ),

                        label('Your name'),
                        inputField(
                          controller: nameController,
                          hintText: 'Contact person',
                          validator: validateName,
                          capitalization:
                              TextCapitalization.words,
                        ),

                        label('Mobile number'),
                        inputField(
                          controller: mobileController,
                          hintText: '[NUMBER]',
                          prefix: '+91  ',
                          keyboard: TextInputType.phone,
                          validator: validateMobile,
                          formatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                        ),

                        label('Email'),
                        inputField(
                          controller: emailController,
                          hintText: 'name@company.com',
                          keyboard: TextInputType.emailAddress,
                          validator: validateEmail,
                        ),

                        label(
                          'GST number',
                          suffix: ' (optional)',
                        ),
                        inputField(
                          controller: gstController,
                          hintText: '[GSTIN]',
                          validator: validateGST,
                          capitalization:
                              TextCapitalization.characters,
                          formatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z0-9]'),
                            ),
                            LengthLimitingTextInputFormatter(15),
                            TextInputFormatter.withFunction(
                              (oldValue, newValue) {
                                return newValue.copyWith(
                                  text: newValue.text.toUpperCase(),
                                  selection: newValue.selection,
                                );
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        buildTerms(),

                        const SizedBox(height: 22),

                        buildButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

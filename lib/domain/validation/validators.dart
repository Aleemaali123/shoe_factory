class Validators {
  static String digits(String value) => value.replaceAll(RegExp(r'\D'), '');

  static String? account({
    required String name,
    required String email,
    required String phone,
    String? password,
    bool checkPassword = false,
  }) {
    if (name.trim().length < 2) return 'Enter your name.';
    final trimmedEmail = email.trim();
    if (!trimmedEmail.contains('@') || !trimmedEmail.contains('.')) {
      return 'Enter a valid email.';
    }
    if (digits(phone).length != 10) return 'Enter a 10-digit phone number.';
    if (checkPassword && (password == null || password.trim().length < 4)) {
      return 'Use a password of at least 4 characters.';
    }
    return null;
  }

  static String? address({
    required String label,
    required String name,
    required String phone,
    required String line,
    required String city,
    required String pincode,
  }) {
    if (label.trim().isEmpty) {
      return 'Name this address, for example Home or Work.';
    }
    if (name.trim().length < 2) return 'Enter the recipient name.';
    if (digits(phone).length != 10) return 'Enter a 10-digit phone number.';
    if (line.trim().length < 5) return 'Enter the house and street.';
    if (city.trim().length < 2) return 'Enter the city.';
    if (digits(pincode).length != 6) return 'Enter a 6-digit PIN code.';
    return null;
  }
}

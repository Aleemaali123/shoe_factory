class AddToCartResult {
  const AddToCartResult({required this.added, required this.message});

  final bool added;
  final String message;
}

class OtpRequest {
  const OtpRequest({this.error, this.code, this.registered = false});

  final String? error;
  final String? code;
  final bool registered;
}

class OtpSignIn {
  const OtpSignIn(
      {this.error, this.needsProfile = false, this.signedIn = false});

  final String? error;
  final bool needsProfile;
  final bool signedIn;
}

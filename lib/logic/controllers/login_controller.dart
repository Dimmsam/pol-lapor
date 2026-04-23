// Nama Pembuat File: Rina Permata Dewi
// NIM: 241511061
// File: login_controller.dart

enum LoginStatus { idle, loading, success, error }

class LoginController {
  LoginStatus status = LoginStatus.idle;
  String? errorMessage;

  Future<LoginStatus> login(String email, String password) async {
    errorMessage = null;

    if (email.isEmpty || password.isEmpty) {
      status = LoginStatus.error;
      errorMessage = 'Email dan password wajib diisi';
      return status;
    }

    status = LoginStatus.loading;

    await Future.delayed(const Duration(seconds: 2));

    if (email == 'admin@polban.ac.id' && password == '123456') {
      status = LoginStatus.success;
    } else {
      status = LoginStatus.error;
      errorMessage = 'Login gagal';
    }

    return status;
  }
}
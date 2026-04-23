// Nama Pembuat File: Rina Permata Dewi
// NIM: 241511061
// File: auth_service.dart

class AuthService {
  Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 2));

    if (email == 'admin@polban.ac.id' && password == '123456') {
      return true;
    }

    return false;
  }
}
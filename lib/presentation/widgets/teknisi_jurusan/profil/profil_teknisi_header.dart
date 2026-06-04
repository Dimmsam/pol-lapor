import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../data/models/user_session.dart';
import '../../../../../core/utils/string_extension.dart';

class ProfilTeknisiHeader extends StatelessWidget {
  final Color navyColor;
  final UserSession userSession;

  const ProfilTeknisiHeader({
    super.key,
    required this.navyColor,
    required this.userSession,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(context),
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: _buildProfileCard(context),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE6E9EE), width: 1)),
      ),
      child: Center(
        child: Text(
          'Profil Saya',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: navyColor,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    final nama = userSession.nama;
    final email = userSession.email;
    final role = userSession.role;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 8)],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Opacity(
                  opacity: 0.06,
                  child: const SizedBox(
                    width: 96,
                    height: 96,
                    child: Icon(Icons.badge, size: 96, color: Colors.black),
                  ),
                ),
              ),
              Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.blueGrey,
                        child: Text(
                          nama.toInitials(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFA726),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    nama,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: navyColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$role\n$email',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

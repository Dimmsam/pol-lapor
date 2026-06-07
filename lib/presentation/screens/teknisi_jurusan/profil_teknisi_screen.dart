import 'package:flutter/material.dart';
import '../../widgets/teknisi_jurusan/profil/profil_teknisi_header.dart';
import '../../widgets/teknisi_jurusan/profil/profil_teknisi_menu.dart';
import '../../../data/models/user_session.dart';

class ProfilTeknisiScreen extends StatefulWidget {
  final UserSession userSession;

  const ProfilTeknisiScreen({super.key, required this.userSession});

  @override
  State<ProfilTeknisiScreen> createState() => _ProfilTeknisiScreenState();
}

class _ProfilTeknisiScreenState extends State<ProfilTeknisiScreen> {
  static const navy = Color(0xFF0B3A66);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(child: _buildProfileContent(context)),
    );
  }

  Widget _buildProfileContent(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ProfilTeknisiHeader(navyColor: navy, userSession: widget.userSession),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                ProfilTeknisiMenu(
                  onProfileUpdated: () {
                    if (mounted) setState(() {});
                  },
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'Versi Aplikasi 2.4.0 (Build 102)',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

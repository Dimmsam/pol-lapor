// Nama Pembuat File: Rina Permata Dewi
// NIM: 241511061
// File: profile_screen.dart

import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  final Color primaryBlue = const Color(0xFF0D47A1);
  final Color accentOrange = const Color(0xFFFF8F00);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0D47A1),
                Color(0xD90D47A1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: const [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person,
                  size: 40,
                  color: Color(0xFF0D47A1),
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Rina Permata Dewi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'rina@polban.ac.id',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Menu profil
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: const [
              _ProfileItem(
                icon: Icons.person_outline,
                title: 'Edit Profil',
              ),
              _ProfileItem(
                icon: Icons.lock_outline,
                title: 'Ubah Password',
              ),
              _ProfileItem(
                icon: Icons.info_outline,
                title: 'Tentang Aplikasi',
              ),
              SizedBox(height: 20),
              _LogoutButton(),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String title;

  const _ProfileItem({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: Colors.white,
        leading: Icon(
          icon,
          color: const Color(0xFF0D47A1),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () {},
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF8F00),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          Navigator.pushReplacementNamed(context, '/login');
        },
        child: const Text(
          'Logout',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
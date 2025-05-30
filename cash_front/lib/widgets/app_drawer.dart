import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cash_flip_app/providers/auth_provider.dart';

class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Drawer(
          backgroundColor: Color(0xFF23222A),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: Color(0xFF23222A)),
                child: Text(
                  'CashFlip',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.person_outline, color: Colors.white70),
                title: Text(
                  authProvider.userName ?? "Пользователь",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              Divider(color: Colors.white24),
              _buildMenuItem(
                context,
                icon: Icons.exit_to_app,
                title: 'Выйти',
                onTap: () {
                  // Выход из аккаунта
                  Provider.of<AuthProvider>(context, listen: false).logout();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70, size: 28),
      title: Text(title, style: TextStyle(color: Colors.white, fontSize: 18)),
      onTap: onTap,
    );
  }
}

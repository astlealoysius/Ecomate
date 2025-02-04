import 'package:flutter/material.dart';
import 'package:ecomate/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ecomate/screens/auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _nameController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = _authService.currentUser;
    if (user?.displayName != null) {
      _nameController.text = user!.displayName!;
    }
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await _authService.currentUser?.updateDisplayName(_nameController.text.trim());
      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isLoading ? null : _updateProfile,
            )
          else
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isEditing)
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Display Name',
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                      ),
                      textAlign: TextAlign.center,
                    )
                  else
                    Text(
                      user?.displayName ?? 'No name set',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    user?.email ?? 'No email',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onBackground.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.history, color: theme.colorScheme.primary),
                      title: const Text('Activity History'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Implement activity history
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.bar_chart, color: theme.colorScheme.primary),
                      title: const Text('Impact Statistics'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Implement statistics
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.settings, color: theme.colorScheme.primary),
                      title: const Text('Settings'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Implement settings
                      },
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                color: theme.colorScheme.errorContainer.withOpacity(0.1),
                child: ListTile(
                  leading: Icon(Icons.logout, color: theme.colorScheme.error),
                  title: Text(
                    'Sign Out',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    _authService.signOut();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const AuthScreen()),
                      (route) => false,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}

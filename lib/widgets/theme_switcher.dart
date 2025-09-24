import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/theme_provider.dart';

class ThemeSwitcher extends StatelessWidget {
  const ThemeSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return PopupMenuButton<ThemeMode>(
          icon: Icon(
            themeProvider.themeModeIcon,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          tooltip: 'Change Theme',
          onSelected: (ThemeMode mode) {
            themeProvider.setThemeMode(mode);
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<ThemeMode>(
              value: ThemeMode.light,
              child: Row(
                children: [
                  const Icon(Icons.light_mode, color: Colors.orange),
                  const SizedBox(width: 12),
                  Text(
                    'Light',
                    style: TextStyle(
                      fontWeight: themeProvider.themeMode == ThemeMode.light
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem<ThemeMode>(
              value: ThemeMode.dark,
              child: Row(
                children: [
                  const Icon(Icons.dark_mode, color: Colors.blue),
                  const SizedBox(width: 12),
                  Text(
                    'Dark',
                    style: TextStyle(
                      fontWeight: themeProvider.themeMode == ThemeMode.dark
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem<ThemeMode>(
              value: ThemeMode.system,
              child: Row(
                children: [
                  const Icon(Icons.brightness_auto, color: Colors.grey),
                  const SizedBox(width: 12),
                  Text(
                    'System',
                    style: TextStyle(
                      fontWeight: themeProvider.themeMode == ThemeMode.system
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return IconButton(
          icon: Icon(themeProvider.themeModeIcon),
          onPressed: () {
            themeProvider.toggleTheme();
          },
          tooltip: 'Toggle Theme',
        );
      },
    );
  }
}

class ThemeSettingsTile extends StatelessWidget {
  const ThemeSettingsTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return ListTile(
          leading: Icon(themeProvider.themeModeIcon),
          title: const Text('Theme'),
          subtitle: Text(themeProvider.themeModeString),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            _showThemeDialog(context, themeProvider);
          },
        );
      },
    );
  }

  void _showThemeDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('Light'),
                subtitle: const Text('Always use light theme'),
                value: ThemeMode.light,
                groupValue: themeProvider.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Dark'),
                subtitle: const Text('Always use dark theme'),
                value: ThemeMode.dark,
                groupValue: themeProvider.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('System'),
                subtitle: const Text('Follow system setting'),
                value: ThemeMode.system,
                groupValue: themeProvider.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mytanah/app_theme_controller.dart';
import 'package:mytanah/mytanahcalc.dart';
import 'package:mytanah/quicktanahcalc.dart';
import 'package:mytanah/viewtanahscreen.dart';

class MainMenu extends StatelessWidget {
  const MainMenu({super.key});

  static const Color _primary = Color(0xFF1B5E3A);
  static const Color _primarySoft = Color(0xFFE8F4ED);
  static const Color _surface = Color(0xFFFAFCF8);
  static const Color _darkSurface = Color(0xFF0F1F18);
  static const Color _darkCard = Color(0xFF172820);
  static const Color _textStrong = Color(0xFF163225);
  static const Color _textMuted = Color(0xFF66756B);
  static const Color _darkTextStrong = Color(0xFFEAF6EE);
  static const Color _darkTextMuted = Color(0xFFA8B8AD);

  @override
  Widget build(BuildContext context) {
    final actions = [
      _MenuAction(
        title: 'Kalkulator Pantas',
        subtitle: 'Kira cukai, hektar dan pecahan tanpa simpan rekod.',
        icon: Icons.speed_outlined,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const QuickTanahCalc()),
          );
        },
      ),
      _MenuAction(
        title: 'Kalkulator Pembahagian',
        subtitle: 'Kira lengkap bersama rekod geran, simpanan dan PDF.',
        icon: Icons.calculate_outlined,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MyTanahCal(pembahagianList: []),
            ),
          );
        },
      ),
      _MenuAction(
        title: 'Rekod Geran',
        subtitle: 'Lihat dan sambung kerja daripada rekod tersimpan.',
        icon: Icons.folder_copy_outlined,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ViewTanahScreen()),
          );
        },
      ),
    ];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? _darkSurface : _surface;
    final textStrong = isDark ? _darkTextStrong : _textStrong;

    return Scaffold(
      backgroundColor: surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [Color(0xFF0F1F18), Color(0xFF1B3026)]
                : const [Color(0xFFF5FAF2), Color(0xFFE2F1E8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              final horizontalPadding = isWide ? 40.0 : 20.0;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  24,
                  horizontalPadding,
                  32,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 920),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Header(isWide: isWide),
                        const SizedBox(height: 18),
                        const _ThemeModeCard(),
                        const SizedBox(height: 28),
                        Text(
                          'Menu Utama',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: textStrong,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 12),
                        _ActionLayout(actions: actions, isWide: isWide),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = Text(
      'MyTanah',
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
        color: isDark ? MainMenu._darkTextStrong : MainMenu._textStrong,
        fontWeight: FontWeight.w900,
      ),
    );

    final subtitle = Text(
      'Urus kiraan pembahagian dan rekod geran tanah dalam satu tempat.',
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: isDark ? MainMenu._darkTextMuted : MainMenu._textMuted,
        height: 1.45,
      ),
    );

    final logo = Container(
      width: isWide ? 96 : 78,
      height: isWide ? 96 : 78,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? MainMenu._darkCard : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Image.asset('assets/mytanah.png', fit: BoxFit.contain),
    );

    final textBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [title, const SizedBox(height: 8), subtitle],
    );

    return Container(
      padding: EdgeInsets.all(isWide ? 28 : 20),
      decoration: BoxDecoration(
        color: isDark
            ? MainMenu._darkCard.withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.86),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: isWide
          ? Row(
              children: [
                logo,
                const SizedBox(width: 24),
                Expanded(child: textBlock),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [logo, const SizedBox(height: 18), textBlock],
            ),
    );
  }
}

class _ThemeModeCard extends StatelessWidget {
  const _ThemeModeCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? MainMenu._darkCard : Colors.white;
    final textStrong = isDark ? MainMenu._darkTextStrong : MainMenu._textStrong;
    final textMuted = isDark ? MainMenu._darkTextMuted : MainMenu._textMuted;

    return Material(
      color: cardColor,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : MainMenu._primary.withValues(alpha: 0.1),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showThemeDialog(context),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : MainMenu._primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                  color: isDark ? const Color(0xFFBDE8C8) : MainMenu._primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paparan Aplikasi',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: textStrong,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isDark
                          ? 'Mod gelap sedang digunakan.'
                          : 'Mod cerah sedang digunakan.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: textMuted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDark ? const Color(0xFFBDE8C8) : MainMenu._primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showThemeDialog(BuildContext context) async {
    final selectedMode = await showDialog<ThemeMode>(
      context: context,
      builder: (dialogContext) {
        final currentMode = appThemeMode.value;

        return AlertDialog(
          icon: const Icon(Icons.contrast_rounded),
          title: const Text('Pilih Paparan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.light_mode_outlined),
                title: const Text('Light Mode'),
                trailing: currentMode == ThemeMode.light
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.pop(dialogContext, ThemeMode.light),
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode_outlined),
                title: const Text('Dark Mode'),
                trailing: currentMode == ThemeMode.dark
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.pop(dialogContext, ThemeMode.dark),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );

    if (selectedMode != null) {
      await setAppThemeMode(selectedMode);
    }
  }
}

class _ActionLayout extends StatelessWidget {
  const _ActionLayout({required this.actions, required this.isWide});

  final List<_MenuAction> actions;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    if (!isWide) {
      return Column(
        children: [
          for (final action in actions) ...[
            _MenuCard(action: action),
            if (action != actions.last) const SizedBox(height: 12),
          ],
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 16) / 2;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final action in actions)
              SizedBox(
                width: cardWidth,
                child: _MenuCard(action: action),
              ),
          ],
        );
      },
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.action});

  final _MenuAction action;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? MainMenu._darkCard : Colors.white;
    final textStrong = isDark ? MainMenu._darkTextStrong : MainMenu._textStrong;
    final textMuted = isDark ? MainMenu._darkTextMuted : MainMenu._textMuted;

    return Material(
      color: cardColor,
      elevation: 0,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : MainMenu._primary.withValues(alpha: 0.1),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : MainMenu._primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  action.icon,
                  color: isDark ? const Color(0xFFBDE8C8) : MainMenu._primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: textStrong,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      action.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: textMuted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.chevron_right,
                color: isDark ? const Color(0xFFBDE8C8) : MainMenu._primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuAction {
  const _MenuAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
}

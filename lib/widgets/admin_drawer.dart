import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:google_fonts/google_fonts.dart";
import "package:go_router/go_router.dart";
import "../services/auth_service.dart";
import "../services/settings_provider.dart";
import "../services/theme_provider.dart";
import "../services/providers.dart";

class AdminDrawer extends ConsumerWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTheme = ref.watch(appThemeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white60 : Colors.black54;
    final categoriesAsync = ref.watch(categoriesProvider);
    final roleAsync = ref.watch(userRoleProvider);
    final isSuperAdmin = roleAsync.value == 'super_admin';

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF0D0D1A) : Colors.white,
      child: Column(
        children: [
          // Drawer Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.primary.withAlpha(160)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(2),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/icons/admin.png',
                      fit: BoxFit.contain, // Better than BoxFit.fill
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "East Front Admin",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "System Management Dashboard",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Dashboard Nav Link
                ListTile(
                  leading: Icon(Icons.dashboard_outlined, color: cs.primary),
                  title: Text("Dashboard", style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w600)),
                  onTap: () => Navigator.pop(context),
                ),
                if (isSuperAdmin) ...[
                  ListTile(
                    leading: Icon(Icons.library_books_outlined, color: cs.primary),
                    title: Text("Book Subcategories", style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      context.push("/admin/book_subcategories");
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.category_outlined, color: cs.primary),
                    title: Text("Categories", style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      context.push("/admin/categories");
                    },
                  ),
                ],
                const Divider(indent: 16, endIndent: 16),

                // Dynamic Categories Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text("Categories Filter", style: GoogleFonts.inter(color: subTextColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ),
                categoriesAsync.when(
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                  data: (catsList) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: catsList.map((c) {
                        final catName = c["name"] as String;
                        return ListTile(
                          leading: Icon(Icons.category_outlined, color: cs.primary),
                          title: Text(catName, style: GoogleFonts.inter(color: textColor, fontSize: 13, fontWeight: FontWeight.w500)),
                          onTap: () {
                            ref.read(selectedCategoryProvider.notifier).setCategory(catName);
                            Navigator.pop(context);
                            context.go("/admin");
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
                const Divider(indent: 16, endIndent: 16),

                // Theme settings tile
                ListTile(
                  leading: Icon(Icons.palette_outlined, color: cs.primary),
                  title: Text("App Theme", style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w600)),
                  subtitle: Text(selectedTheme.name, style: GoogleFonts.inter(fontSize: 12, color: subTextColor)),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () {
                    Navigator.pop(context);
                    _showThemeSettings(context, ref, isDark);
                  },
                ),
                const Divider(indent: 16, endIndent: 16),

                // Font Settings
                ListTile(
                  leading: Icon(Icons.text_fields, color: cs.primary),
                  title: Text("Font Settings", style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () {
                    Navigator.pop(context);
                    _showFontSettings(context, ref, isDark);
                  },
                ),

                const Divider(indent: 16, endIndent: 16),

                // Logout Option
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: Text("Logout", style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                  onTap: () async {
                    Navigator.pop(context);
                    await AuthService.instance.logout();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFontSettings(BuildContext context, WidgetRef ref, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1A1A3E) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const SafeArea(child: _FontSettingsSheet()),
    );
  }

  void _showThemeSettings(BuildContext context, WidgetRef ref, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1A1A3E) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const SafeArea(child: _ThemeSettingsSheet()),
    );
  }
}

class _ThemeSettingsSheet extends ConsumerWidget {
  const _ThemeSettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTheme = ref.watch(appThemeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white54 : Colors.black54;
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withAlpha(80), borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 20),
            Text("App Theme", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 6),
            Text("Choose your preferred look", style: GoogleFonts.inter(fontSize: 12, color: subColor)),
            const SizedBox(height: 20),
            ...AppThemeType.values.map((theme) {
              final isSelected = selectedTheme == theme;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => ref.read(appThemeProvider.notifier).setTheme(theme),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? cs.primary.withAlpha(20) : (isDark ? Colors.white10 : Colors.black12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? cs.primary : Colors.transparent, width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(theme.name, style: GoogleFonts.inter(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: textColor)),
                        if (isSelected) Icon(Icons.check_circle, color: cs.primary, size: 20),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _FontSettingsSheet extends ConsumerWidget {
  const _FontSettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white54 : Colors.black54;
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withAlpha(80), borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 20),
            Text("Font Settings", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 6),
            Text("Customize reading experience", style: GoogleFonts.inter(fontSize: 12, color: subColor)),
            const SizedBox(height: 24),
            Text("Font Size", style: GoogleFonts.inter(color: subColor, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            const SizedBox(height: 10),
            Row(
              children: FontSizeSetting.values.map((fs) {
                final isSelected = settings.fontSize == fs;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => ref.read(settingsProvider.notifier).setFontSize(fs),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? cs.primary : (isDark ? Colors.white10 : Colors.black12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(fs.label, style: GoogleFonts.inter(fontSize: 11, color: isSelected ? Colors.white : subColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text("Line Spacing", style: GoogleFonts.inter(color: subColor, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            const SizedBox(height: 10),
            Row(
              children: [1.5, 1.7, 2.0, 2.2, 2.5].map((ls) {
                final isSelected = settings.lineSpacing == ls;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => ref.read(settingsProvider.notifier).setLineSpacing(ls),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? cs.primary : (isDark ? Colors.white10 : Colors.black12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text("$ls", style: GoogleFonts.inter(fontSize: 11, color: isSelected ? Colors.white : subColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text("Urdu Font Style", style: GoogleFonts.inter(color: subColor, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            const SizedBox(height: 10),
            Row(
              children: AppUrduFont.values.map((uf) {
                final isSelected = settings.urduFont == uf;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => ref.read(settingsProvider.notifier).setUrduFont(uf),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? cs.primary : (isDark ? Colors.white10 : Colors.black12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(uf == AppUrduFont.nastaliq ? "Nastaliq" : "Sans-Serif", style: GoogleFonts.inter(fontSize: 11, color: isSelected ? Colors.white : subColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}


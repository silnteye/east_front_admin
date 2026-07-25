import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:google_fonts/google_fonts.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import "../../services/providers.dart";

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF2F2FA);
    final cs = Theme.of(context).colorScheme;
    final roleAsync = ref.watch(userRoleProvider);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text("App Users", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? const Color(0xFF1A1A3E) : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
      ),
      body: roleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err", style: const TextStyle(color: Colors.redAccent))),
        data: (role) {
          if (role != "super_admin") {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 64, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text(
                    "Access Denied",
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Super Admin privileges are required to view this page.",
                    style: GoogleFonts.inter(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("users")
                      .where("isAnonymous", isEqualTo: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text("Error loading users: ${snapshot.error}",
                            style: const TextStyle(color: Colors.redAccent)),
                      );
                    }
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: isDark ? Colors.white24 : Colors.black26),
                            const SizedBox(height: 16),
                            Text("No registered users found", style: GoogleFonts.inter(color: Colors.grey)),
                          ],
                        ),
                      );
                    }

                    // Sort: super_admin first, then admin, then user. Within each group, sort by name.
                    final sortedDocs = List<QueryDocumentSnapshot>.from(docs);
                    sortedDocs.sort((a, b) {
                      final aData = a.data() as Map<String, dynamic>;
                      final bData = b.data() as Map<String, dynamic>;
                      final aRole = aData["role"] as String? ?? "user";
                      final bRole = bData["role"] as String? ?? "user";

                      int roleWeight(String r) {
                        if (r == "super_admin") return 0;
                        if (r == "admin") return 1;
                        return 2;
                      }

                      final weightCompare = roleWeight(aRole).compareTo(roleWeight(bRole));
                      if (weightCompare != 0) return weightCompare;

                      final aName = (aData["name"] as String? ?? "").toLowerCase();
                      final bName = (bData["name"] as String? ?? "").toLowerCase();
                      return aName.compareTo(bName);
                    });

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: sortedDocs.length,
                      itemBuilder: (context, index) {
                        final doc = sortedDocs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final uid = doc.id;
                        final email = data["email"] ?? "No Email";
                        final name = data["name"] ?? "User";
                        final isActive = data["isActive"] ?? true;
                        final photoUrl = data["photoUrl"] as String?;
                        final userRole = data["role"] ?? "user";

                        return Card(
                          color: isDark ? const Color(0xFF1A1A3E) : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: isDark ? 0 : 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                                      ? NetworkImage(photoUrl)
                                      : null,
                                  backgroundColor: cs.primary.withAlpha(30),
                                  child: photoUrl == null || photoUrl.isEmpty
                                      ? Icon(Icons.person_outline, color: cs.primary)
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        email,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          color: isDark ? Colors.white54 : Colors.black54,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Text(
                                            "Role: ",
                                            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                                          ),
                                          const SizedBox(width: 4),
                                          DropdownButton<String>(
                                            value: userRole,
                                            dropdownColor: isDark ? const Color(0xFF1A1A3E) : Colors.white,
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: isDark ? Colors.white : Colors.black87,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            underline: const SizedBox.shrink(),
                                            isDense: true,
                                            items: const [
                                              DropdownMenuItem(value: "user", child: Text("User")),
                                              DropdownMenuItem(value: "admin", child: Text("Admin")),
                                              DropdownMenuItem(value: "super_admin", child: Text("Super Admin")),
                                            ],
                                            onChanged: (newRole) async {
                                              if (newRole != null) {
                                                await FirebaseFirestore.instance
                                                    .collection("users")
                                                    .doc(uid)
                                                    .update({"role": newRole});
                                                ref.invalidate(userRoleProvider);
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (userRole != "super_admin")
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        isActive ? "Active" : "Deactivated",
                                        style: GoogleFonts.inter(
                                          color: isActive ? Colors.green : Colors.redAccent,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Switch(
                                        value: isActive,
                                        activeThumbColor: Colors.green,
                                        activeTrackColor: Colors.green.withAlpha(80),
                                        inactiveThumbColor: Colors.redAccent,
                                        inactiveTrackColor: Colors.redAccent.withAlpha(80),
                                        onChanged: (val) async {
                                          await FirebaseFirestore.instance
                                              .collection("users")
                                              .doc(uid)
                                              .update({"isActive": val});
                                        },
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../../../../core/theme/app_theme.dart";
import "../../../../../core/widgets/error_view.dart";
import "../../../../admin_shell.dart";
import "../../../../admin/data/providers/admin_provider.dart";

const _roles = ["owner", "manager", "support", "catalog_editor"];

Color _roleColor(String role) => switch (role) {
      "owner" => AppColors.rust,
      "manager" => AppColors.olive,
      "catalog_editor" => const Color(0xFF3B6E8F),
      _ => AppColors.inkSoft,
    };

String _roleLabel(String role) => role
    .split("_")
    .map((w) => w.isEmpty ? w : "${w[0].toUpperCase()}${w.substring(1)}")
    .join(" ");

Color _statusColor(String status) => status == "active" ? AppColors.success : AppColors.warning;

/// Staff screen — the mock backend only exposes a read route for staff
/// (`GET /admin/staff`), there's no invite/create mutation yet. Invites are
/// therefore applied optimistically to local state on top of the fetched
/// list so the UI still feels functional end to end.
class AdminStaffScreen extends ConsumerStatefulWidget {
  const AdminStaffScreen({super.key});

  @override
  ConsumerState<AdminStaffScreen> createState() => _AdminStaffScreenState();
}

class _AdminStaffScreenState extends ConsumerState<AdminStaffScreen> {
  final List<Map<String, dynamic>> _invited = [];

  void _openInviteDialog() {
    final emailCtrl = TextEditingController();
    String role = "support";
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text("Invite Staff", style: displayFont(fontSize: 18)),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: "Role", border: OutlineInputBorder()),
                  items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(_roleLabel(r)))).toList(),
                  onChanged: (v) => setDialogState(() => role = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                final email = emailCtrl.text.trim();
                if (email.isEmpty) return;
                Navigator.pop(context);
                setState(() {
                  _invited.add({
                    "id": "invited-${_invited.length + 1}",
                    "name": email.split("@").first,
                    "email": email,
                    "role": role,
                    "status": "active",
                  });
                });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Invited $email as ${_roleLabel(role)}")));
              },
              child: const Text("Send Invite"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(adminStaffProvider);
    return AdminShell(
      currentPath: "/admin/staff",
      title: "Staff",
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(onPressed: _openInviteDialog, icon: const Icon(Icons.person_add_alt_1_outlined), label: const Text("Invite Staff")),
            const SizedBox(height: 16),
            Expanded(
              child: staffAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => ErrorView(message: "Could not load staff", onRetry: () => ref.invalidate(adminStaffProvider)),
                data: (staff) {
                  final all = [...staff, ..._invited];
                  if (all.isEmpty) {
                    return Center(child: Text("No staff members yet", style: bodyFont(fontSize: 13, color: AppColors.inkSoft)));
                  }
                  return Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadii.card), border: Border.all(color: AppColors.line)),
                    child: LayoutBuilder(builder: (context, constraints) {
                      final wide = constraints.maxWidth > 700;
                      return ListView.separated(
                        itemCount: all.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.line),
                        itemBuilder: (context, i) {
                          final s = all[i];
                          final role = s["role"]?.toString() ?? "support";
                          final status = s["status"]?.toString() ?? "active";
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _roleColor(role).withOpacity(0.12),
                              child: Text(
                                (s["name"]?.toString().isNotEmpty == true ? s["name"].toString()[0] : "?").toUpperCase(),
                                style: bodyFont(fontSize: 13, fontWeight: FontWeight.w700, color: _roleColor(role)),
                              ),
                            ),
                            title: Text(s["name"]?.toString() ?? "", style: bodyFont(fontSize: 13.5, fontWeight: FontWeight.w700)),
                            subtitle: wide ? Text(s["email"]?.toString() ?? "", style: bodyFont(fontSize: 12, color: AppColors.inkSoft)) : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(color: _roleColor(role).withOpacity(0.12), borderRadius: BorderRadius.circular(AppRadii.chip)),
                                  child: Text(_roleLabel(role), style: bodyFont(fontSize: 11, fontWeight: FontWeight.w700, color: _roleColor(role))),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.circle, size: 8, color: _statusColor(status)),
                              ],
                            ),
                          );
                        },
                      );
                    }),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

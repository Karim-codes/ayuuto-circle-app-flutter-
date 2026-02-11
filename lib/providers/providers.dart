import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/group_service.dart';
import '../models/profile.dart';
import '../models/group.dart';
import '../models/member.dart';
import '../models/payment.dart';
import '../models/payout.dart';
import '../models/join_request.dart';

// ── Core ──────────────────────────────────────────────────

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(supabaseClientProvider));
});

final groupServiceProvider = Provider<GroupService>((ref) {
  return GroupService(ref.watch(supabaseClientProvider));
});

// ── Auth State ────────────────────────────────────────────

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(supabaseClientProvider).auth.currentUser;
});

// ── Profile ───────────────────────────────────────────────

final profileProvider = FutureProvider<Profile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.watch(authServiceProvider).getProfile();
});

// ── Groups ────────────────────────────────────────────────

final myGroupsProvider = FutureProvider<List<GroupWithStats>>((ref) async {
  ref.watch(currentUserProvider);
  return ref.watch(groupServiceProvider).getMyGroups();
});

final groupDetailProvider =
    FutureProvider.family<Group, String>((ref, groupId) async {
  return ref.watch(groupServiceProvider).getGroup(groupId);
});

// ── Members ───────────────────────────────────────────────

final membersProvider =
    FutureProvider.family<List<Member>, String>((ref, groupId) async {
  return ref.watch(groupServiceProvider).getMembers(groupId);
});

// ── Payments ──────────────────────────────────────────────

final activePaymentsProvider = FutureProvider.family<List<Payment>,
    ({String groupId, int cycleNumber})>((ref, params) async {
  return ref
      .watch(groupServiceProvider)
      .getActivePayments(params.groupId, params.cycleNumber);
});

// ── Payouts ───────────────────────────────────────────────

final payoutsProvider =
    FutureProvider.family<List<Payout>, String>((ref, groupId) async {
  return ref.watch(groupServiceProvider).getPayouts(groupId);
});

// ── Join Requests ─────────────────────────────────────────

final pendingJoinRequestsProvider =
    FutureProvider.family<List<JoinRequest>, String>((ref, groupId) async {
  return ref.watch(groupServiceProvider).getPendingJoinRequests(groupId);
});

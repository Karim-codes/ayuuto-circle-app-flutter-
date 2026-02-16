import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/group.dart';
import '../models/member.dart';
import '../models/payment.dart';
import '../models/payout.dart';
import '../models/join_request.dart';

class GroupService {
  final SupabaseClient _client;

  GroupService(this._client);

  String? get _userId => _client.auth.currentUser?.id;

  // ── Groups ──────────────────────────────────────────────

  Future<List<GroupWithStats>> getMyGroups() async {
    if (_userId == null) return [];

    // Get group IDs where the current user is a member
    final memberRows = await _client
        .from('members')
        .select('group_id')
        .eq('user_id', _userId!);

    final groupIds =
        (memberRows as List).map((r) => r['group_id'] as String).toList();

    if (groupIds.isEmpty) return [];

    final data = await _client
        .from('groups_with_stats')
        .select()
        .inFilter('id', groupIds)
        .order('created_at', ascending: false);

    return (data as List)
        .map((json) => GroupWithStats.fromJson(json))
        .toList();
  }

  Future<Group> getGroup(String groupId) async {
    final data = await _client
        .from('groups')
        .select()
        .eq('id', groupId)
        .single();
    return Group.fromJson(data);
  }

  Future<String> createGroup({
    required String name,
    required double contributionAmount,
    required String currency,
    required String frequency,
    String? whatsappLink,
    List<Map<String, dynamic>>? members,
  }) async {
    final result = await _client.rpc('create_group_with_members', params: {
      '_name': name,
      '_contribution_amount': contributionAmount,
      '_currency': currency,
      '_frequency': frequency,
      '_whatsapp_link': whatsappLink,
      '_members': members,
    });
    return result as String;
  }

  Future<void> updateGroup({
    required String groupId,
    String? name,
    double? contributionAmount,
    String? currency,
    String? frequency,
    String? whatsappLink,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (name != null) updates['name'] = name;
    if (contributionAmount != null) {
      updates['contribution_amount'] = contributionAmount;
    }
    if (currency != null) updates['currency'] = currency;
    if (frequency != null) updates['frequency'] = frequency;
    if (whatsappLink != null) updates['whatsapp_link'] = whatsappLink;

    await _client.from('groups').update(updates).eq('id', groupId);
  }

  Future<void> deleteGroup(String groupId) async {
    await _client.from('groups').delete().eq('id', groupId);
  }

  // ── Members ─────────────────────────────────────────────

  Future<List<Member>> getMembers(String groupId) async {
    final data = await _client
        .from('members')
        .select()
        .eq('group_id', groupId)
        .order('payout_position', ascending: true);

    return (data as List).map((json) => Member.fromJson(json)).toList();
  }

  Future<void> addMember({
    required String groupId,
    required String name,
    String? phone,
    required int payoutPosition,
  }) async {
    await _client.from('members').insert({
      'group_id': groupId,
      'name': name,
      'phone': phone,
      'payout_position': payoutPosition,
    });
  }

  Future<void> removeMember(String memberId) async {
    await _client.from('members').delete().eq('id', memberId);
  }

  // ── Payments ────────────────────────────────────────────

  Future<List<Payment>> getActivePayments(
      String groupId, int cycleNumber) async {
    final data = await _client
        .from('payments')
        .select()
        .eq('group_id', groupId)
        .eq('cycle_number', cycleNumber)
        .isFilter('voided_at', null)
        .order('created_at', ascending: false);

    return (data as List).map((json) => Payment.fromJson(json)).toList();
  }

  Future<void> markPaid({
    required String groupId,
    required String memberId,
    required int cycleNumber,
    required double amount,
  }) async {
    await _client.from('payments').insert({
      'group_id': groupId,
      'member_id': memberId,
      'cycle_number': cycleNumber,
      'amount': amount,
      'payment_date': DateTime.now().toIso8601String().split('T')[0],
    });
  }

  Future<void> markUnpaid({
    required String groupId,
    required String memberId,
    required int cycleNumber,
  }) async {
    await _client
        .from('payments')
        .update({'voided_at': DateTime.now().toIso8601String()})
        .eq('group_id', groupId)
        .eq('member_id', memberId)
        .eq('cycle_number', cycleNumber)
        .isFilter('voided_at', null);
  }

  // ── Payouts ─────────────────────────────────────────────

  Future<List<Payout>> getPayouts(String groupId) async {
    final data = await _client
        .from('payouts')
        .select()
        .eq('group_id', groupId)
        .order('cycle_number', ascending: true);

    return (data as List).map((json) => Payout.fromJson(json)).toList();
  }

  Future<void> confirmPayout({
    required String groupId,
    required int cycleNumber,
    required String recipientMemberId,
    required double amount,
  }) async {
    // 1. Insert payout record
    await _client.from('payouts').insert({
      'group_id': groupId,
      'cycle_number': cycleNumber,
      'recipient_member_id': recipientMemberId,
      'amount': amount,
    });

    // 2. Mark member as having received payout
    await _client
        .from('members')
        .update({'has_received_payout': true})
        .eq('id', recipientMemberId);

    // 3. Void all active payments for this cycle
    await _client
        .from('payments')
        .update({'voided_at': DateTime.now().toIso8601String()})
        .eq('group_id', groupId)
        .eq('cycle_number', cycleNumber)
        .isFilter('voided_at', null);
  }

  Future<void> advanceCycle(String groupId) async {
    await _client.rpc('advance_group_cycle', params: {
      '_group_id': groupId,
    });
  }

  // ── Invites ─────────────────────────────────────────────

  Future<String> generateInviteCode(String groupId) async {
    final code = await _client.rpc('generate_invite_code');

    await _client.from('group_invites').insert({
      'group_id': groupId,
      'invite_code': code,
    });

    return code as String;
  }

  Future<Map<String, dynamic>?> getGroupByInviteCode(String code) async {
    try {
      final data = await _client.rpc('get_group_by_invite_code', params: {
        'code': code,
      });
      if (data is List && data.isNotEmpty) {
        return data[0] as Map<String, dynamic>;
      }
      return data as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error getting group by invite code: $e');
      return null;
    }
  }

  // ── Join Requests ───────────────────────────────────────

  Future<void> submitJoinRequest({
    required String groupId,
    required String name,
    String? phone,
  }) async {
    await _client.from('join_requests').insert({
      'group_id': groupId,
      'user_id': _userId,
      'name': name,
      'phone': phone,
    });
  }

  Future<List<JoinRequest>> getPendingJoinRequests(String groupId) async {
    final data = await _client
        .from('join_requests')
        .select()
        .eq('group_id', groupId)
        .eq('status', 'pending')
        .order('created_at', ascending: true);

    return (data as List)
        .map((json) => JoinRequest.fromJson(json))
        .toList();
  }

  Future<void> approveJoinRequest({
    required String requestId,
    required String groupId,
    required String name,
    String? phone,
    String? userId,
    required int payoutPosition,
  }) async {
    // Update request status
    await _client.from('join_requests').update({
      'status': 'approved',
      'reviewed_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);

    // Add as member
    await _client.from('members').insert({
      'group_id': groupId,
      'name': name,
      'phone': phone,
      'user_id': userId,
      'payout_position': payoutPosition,
    });
  }

  Future<void> rejectJoinRequest(String requestId) async {
    await _client.from('join_requests').update({
      'status': 'rejected',
      'reviewed_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);
  }

  // ── History ─────────────────────────────────────────────

  Future<Map<String, dynamic>> getUserHistory() async {
    if (_userId == null) return {'payments': [], 'payouts': []};

    // Get member IDs for the current user
    final memberRows = await _client
        .from('members')
        .select('id, group_id')
        .eq('user_id', _userId!);

    final memberIds =
        (memberRows as List).map((r) => r['id'] as String).toList();

    if (memberIds.isEmpty) return {'payments': [], 'payouts': []};

    // Get group IDs the user belongs to
    final groupIds =
        (memberRows as List).map((r) => r['group_id'] as String).toSet().toList();

    // Get all payments for the user's groups (with member name)
    final payments = await _client
        .from('payments')
        .select('*, groups!inner(name, currency, contribution_amount), members!inner(name, user_id)')
        .inFilter('group_id', groupIds)
        .order('created_at', ascending: false);

    // Get all payouts for the user's groups (with recipient name)
    final payouts = await _client
        .from('payouts')
        .select('*, groups!inner(name, currency), members!payouts_recipient_member_id_fkey(name, user_id)')
        .inFilter('group_id', groupIds)
        .order('created_at', ascending: false);

    return {
      'payments': payments,
      'payouts': payouts,
      'memberIds': memberIds,
    };
  }

  // ── Helpers ─────────────────────────────────────────────

  Member? getNextRecipient(List<Member> members) {
    final eligible =
        members.where((m) => !m.hasReceivedPayout).toList()
          ..sort((a, b) => a.payoutPosition.compareTo(b.payoutPosition));
    return eligible.isNotEmpty ? eligible.first : null;
  }

  bool isRoundComplete(List<Member> members) {
    return members.every((m) => m.hasReceivedPayout);
  }
}

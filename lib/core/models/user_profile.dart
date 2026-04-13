import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// User Profile model — bisa dibuat dari Custom Claims atau Firestore.
class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String bengkelId;
  final String role;
  final List<String> permissions;
  final String status;
  final DateTime joinedAt;
  final String? invitedBy;
  final DateTime? lastActive;
  final List<String> deviceTokens;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.bengkelId,
    required this.role,
    this.permissions = const [],
    this.status = 'active',
    required this.joinedAt,
    this.invitedBy,
    this.lastActive,
    this.deviceTokens = const [],
  });

  /// Factory dari Custom Claims (prioritas utama — zero Firestore read).
  factory UserProfile.fromCustomClaims(User user, IdTokenResult tokenResult) {
    final claims = tokenResult.claims ?? {};
    return UserProfile(
      uid: user.uid,
      name: user.displayName ?? claims['name'] ?? '',
      email: user.email ?? claims['email'] ?? '',
      bengkelId: claims['bengkelId'] ?? '',
      role: claims['role'] ?? 'teknisi',
      permissions: List<String>.from(claims['permissions'] ?? []),
      status: 'active',
      joinedAt: DateTime.now(),
    );
  }

  /// Factory dari Firestore document (fallback untuk first login).
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      bengkelId: data['bengkelId'] ?? '',
      role: data['role'] ?? 'teknisi',
      permissions: List<String>.from(data['permissions'] ?? []),
      status: data['status'] ?? 'active',
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      invitedBy: data['invitedBy'],
      lastActive: (data['lastActive'] as Timestamp?)?.toDate(),
      deviceTokens: List<String>.from(data['deviceTokens'] ?? []),
    );
  }

  /// Convert to Map untuk Firestore write.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'bengkelId': bengkelId,
      'role': role,
      'permissions': permissions,
      'status': status,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'invitedBy': invitedBy,
      'lastActive': lastActive != null ? Timestamp.fromDate(lastActive!) : null,
      'deviceTokens': deviceTokens,
    };
  }

  /// Check apakah user punya permission tertentu.
  bool can(Permission permission) => permissions.contains(permission.name);

  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin';
  bool get isTeknisi => role == 'teknisi';
}

/// Daftar permission yang tersedia.
enum Permission {
  viewOmzet,
  deleteTransaction,
  manageInventory,
  backupData,
  manageStaff,
  sendReminder,
}

/// Auth State enum — menentukan routing di app.
enum AuthState {
  unauthenticated, // Belum login
  authenticating, // Sedang login
  missingProfile, // Login tapi belum punya profile (first time)
  authenticated, // Login + profile lengkap
}

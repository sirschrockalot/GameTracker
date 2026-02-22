/// Compile-time feature flags for controlling Phase 2 auth + parent portal rollout.
class FeatureFlags {
  FeatureFlags._();

  /// Enables Phase 2 team membership/auth flows:
  /// - Multiple coaches per team (join requests, approvals, member list)
  /// - Coach/parent join codes and role-based routing
  static const bool enableMembershipAuthV2 = true;

  /// Enables the parent-facing schedule portal (ParentHome).
  /// When disabled, parents should not be routed into the app.
  static const bool enableParentPortal = true;
}


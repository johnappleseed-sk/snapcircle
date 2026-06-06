class AdminDashboardModel {
  final int totalUsers;
  final int activeUsers;
  final int bannedUsers;
  final int totalPosts;
  final int totalComments;
  final int totalReports;
  final int pendingReports;
  final int totalStories;
  final int totalMessages;
  final int newUsersToday;
  final int newPostsToday;
  final int reportsToday;

  const AdminDashboardModel({
    this.totalUsers = 0,
    this.activeUsers = 0,
    this.bannedUsers = 0,
    this.totalPosts = 0,
    this.totalComments = 0,
    this.totalReports = 0,
    this.pendingReports = 0,
    this.totalStories = 0,
    this.totalMessages = 0,
    this.newUsersToday = 0,
    this.newPostsToday = 0,
    this.reportsToday = 0,
  });

  factory AdminDashboardModel.fromJson(Map<String, dynamic> json) {
    return AdminDashboardModel(
      totalUsers: _int(json['total_users']),
      activeUsers: _int(json['active_users']),
      bannedUsers: _int(json['banned_users']),
      totalPosts: _int(json['total_posts']),
      totalComments: _int(json['total_comments']),
      totalReports: _int(json['total_reports']),
      pendingReports: _int(json['pending_reports']),
      totalStories: _int(json['total_stories']),
      totalMessages: _int(json['total_messages']),
      newUsersToday: _int(json['new_users_today']),
      newPostsToday: _int(json['new_posts_today']),
      reportsToday: _int(json['reports_today']),
    );
  }

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

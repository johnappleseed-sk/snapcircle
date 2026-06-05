class ApiEndpoints {
  static const String health = '/health';
  static const String authGoogle = '/auth/google';
  static const String authFacebook = '/auth/facebook';
  static const String authDemo = '/auth/demo';
  static const String logout = '/logout';
  static const String user = '/user';
  static const String profile = '/profile';
  static const String users = '/users';
  static const String posts = '/posts';
  static const String createPost = '/posts';
  static const String savedPosts = '/saved-posts';
  static const String feedStatus = '/feed/status';
  static const String notifications = '/notifications';
  static const String notificationUnreadCount = '/notifications/unread-count';
  static const String markAllNotificationsRead = '/notifications/read-all';
  static const String conversations = '/conversations';

  static String postById(int id) => '/posts/$id';
  static String userById(int id) => '/users/$id';
  static String followUser(int id) => '/users/$id/follow';
  static String unfollowUser(int id) => '/users/$id/follow';
  static String likePost(int postId) => '/posts/$postId/like';
  static String unlikePost(int postId) => '/posts/$postId/like';
  static String savePost(int postId) => '/posts/$postId/save';
  static String unsavePost(int postId) => '/posts/$postId/save';
  static String postComments(int postId) => '/posts/$postId/comments';
  static String commentsStatus(int postId) => '/posts/$postId/comments/status';
  static String commentById(int commentId) => '/comments/$commentId';
  static String comments(int postId) => '/posts/$postId/comments';
  static String comment(int commentId) => '/comments/$commentId';
  static String like(int postId) => '/posts/$postId/like';
  static String follow(int userId) => '/users/$userId/follow';
  static String followers(int userId) => '/users/$userId/followers';
  static String following(int userId) => '/users/$userId/following';
  static String markNotificationRead(int id) => '/notifications/$id/read';
  static String deleteNotification(int id) => '/notifications/$id';
  static String conversationById(int id) => '/conversations/$id';
  static String conversationMessages(int conversationId) =>
      '/conversations/$conversationId/messages';
  static String markMessageRead(int messageId) => '/messages/$messageId/read';
}

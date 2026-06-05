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

  static String postById(int id) => '/posts/$id';
  static String userById(int id) => '/users/$id';
  static String followUser(int id) => '/users/$id/follow';
  static String unfollowUser(int id) => '/users/$id/follow';
  static String likePost(int postId) => '/posts/$postId/like';
  static String unlikePost(int postId) => '/posts/$postId/like';
  static String savePost(int postId) => '/posts/$postId/save';
  static String unsavePost(int postId) => '/posts/$postId/save';
  static String postComments(int postId) => '/posts/$postId/comments';
  static String commentById(int commentId) => '/comments/$commentId';
  static String comments(int postId) => '/posts/$postId/comments';
  static String comment(int commentId) => '/comments/$commentId';
  static String like(int postId) => '/posts/$postId/like';
  static String follow(int userId) => '/users/$userId/follow';
  static String followers(int userId) => '/users/$userId/followers';
  static String following(int userId) => '/users/$userId/following';
}

class PaginatedResponse<T> {
  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final int perPage;

  const PaginatedResponse({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.perPage,
  });

  bool get hasMore => currentPage < lastPage;

  factory PaginatedResponse.fromApi({
    required Map<String, dynamic> response,
    required T Function(Map<String, dynamic> json) itemBuilder,
    String? dataKey,
    int fallbackPage = 1,
    int fallbackPerPage = 10,
  }) {
    final payload = response['data'];
    final meta = payload is Map<String, dynamic> && payload['meta'] is Map
        ? Map<String, dynamic>.from(payload['meta'] as Map)
        : payload is Map<String, dynamic>
        ? payload
        : response;
    final rawItems = _extractList(response, dataKey);
    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map(itemBuilder)
        .toList();
    final currentPage = _parseInt(
      meta['current_page'],
      fallback: fallbackPage,
    );
    final perPage = _parseInt(meta['per_page'], fallback: fallbackPerPage);

    return PaginatedResponse<T>(
      items: items,
      currentPage: currentPage,
      lastPage: _parseInt(
        meta['last_page'],
        fallback: items.length < perPage ? currentPage : currentPage + 1,
      ),
      perPage: perPage,
      total: _parseInt(meta['total'], fallback: items.length),
    );
  }

  static List<dynamic> _extractList(
    Map<String, dynamic> response,
    String? dataKey,
  ) {
    final payload = response['data'];

    if (payload is List) {
      return payload;
    }

    if (payload is Map<String, dynamic>) {
      if (dataKey != null && payload[dataKey] is List) {
        return payload[dataKey] as List;
      }

      if (payload['data'] is List) {
        return payload['data'] as List;
      }
    }

    if (dataKey != null && response[dataKey] is List) {
      return response[dataKey] as List;
    }

    return const [];
  }

  static int _parseInt(dynamic value, {required int fallback}) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }

    return fallback;
  }
}

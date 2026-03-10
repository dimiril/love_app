class SearchItem {
  final String query;
  final DateTime date;

  SearchItem(this.query, {DateTime? date}) : date = date ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'query': query,
    'date': date.toIso8601String(),
  };

  factory SearchItem.fromMap(Map<String, dynamic> map) {
    return SearchItem(
      map['query'],
      date: DateTime.parse(map['date']),
    );
  }
}
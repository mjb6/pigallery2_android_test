import 'search.dart';

class AutoCompleteItem {
  final String text;
  final SearchQueryTypes type;

  AutoCompleteItem(this.text, this.type);

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'value': type.value,
    };
  }

  factory AutoCompleteItem.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'];
    final int typeValue = rawType is int ? rawType : int.tryParse(rawType.toString()) ?? 0;
    return AutoCompleteItem(
      json['value'] as String,
      SearchQueryTypes.fromValue(typeValue),
    );
  }
}

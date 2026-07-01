import 'package:equatable/equatable.dart';

class Snippet extends Equatable {
  final String id;
  final String label;
  final String value;

  const Snippet({required this.id, required this.label, required this.value});

  Snippet copyWith({String? label, String? value}) =>
      Snippet(id: id, label: label ?? this.label, value: value ?? this.value);

  @override
  List<Object?> get props => [id, label, value];
}

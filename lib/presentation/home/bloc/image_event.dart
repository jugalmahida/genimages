import 'package:equatable/equatable.dart';

abstract class ImageEvent extends Equatable {
  const ImageEvent();

  @override
  List<Object> get props => [];
}

class GenerateImageEvent extends ImageEvent {
  final String prompt;
  const GenerateImageEvent(this.prompt);

  @override
  List<Object> get props => [prompt];
}

import 'package:equatable/equatable.dart';

abstract class ImageState extends Equatable {
  const ImageState();

  @override
  List<Object?> get props => [];
}

class ImageInitial extends ImageState {}

class ImageLoading extends ImageState {}

class ImageSuccess extends ImageState {
  final String base64;
  const ImageSuccess(this.base64);

  @override
  List<Object?> get props => [base64];
}

class ImageFailure extends ImageState {
  final String error;
  const ImageFailure(this.error);

  @override
  List<Object?> get props => [error];
}

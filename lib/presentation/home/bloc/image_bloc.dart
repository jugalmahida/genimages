import 'package:flutter_bloc/flutter_bloc.dart';
import 'image_event.dart';
import 'image_state.dart';
// Import your ImageRepository from domain layer
import '../../../domain/repositories/image_repository.dart';

class ImageBloc extends Bloc<ImageEvent, ImageState> {
  final ImageRepository imageRepository;

  ImageBloc(this.imageRepository) : super(ImageInitial()) {
    on<GenerateImageEvent>((event, emit) async {
      emit(ImageLoading());
      try {
        final b64 = await imageRepository.generateImage(event.prompt);
        emit(ImageSuccess(b64));
      } catch (e) {
        emit(ImageFailure(e.toString()));
      }
    });
  }
}

import 'package:genimages/data/repositories/image_repo_impl.dart';
import 'package:genimages/data/services/api_client.dart';
import 'package:genimages/domain/repositories/image_repository.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  getIt.registerSingleton<ImageRepository>(
      ImageRepositoryImpl(ApiClient()));
}

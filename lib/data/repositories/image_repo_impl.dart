import 'package:genimages/core/constants/app_constants.dart';
import 'package:genimages/data/services/api_client.dart';
import 'package:genimages/domain/repositories/image_repository.dart';

class ImageRepositoryImpl implements ImageRepository {
  final ApiClient apiClient;
  ImageRepositoryImpl(this.apiClient);

  @override
  Future<String> generateImage(String prompt) async {
    final response = await apiClient.post(
      '/images/generations',
      data: {
        "model": "black-forest-labs/flux-dev",
        "response_format": "b64_json",
        "response_extension": "png",
        "width": 1024,
        "height": 1024,
        "num_inference_steps": 28,
        "negative_prompt": "",
        "seed": -1,
        "loras": null,
        "prompt": prompt,
      },
      headers: {
        "Authorization": "Bearer ${AppConstants.apiKey}",
        "Content-Type": "application/json",
      },
    );

    // Parse the response and return the Base64 string
    return response.data['data'][0]['b64_json'];
  }
}

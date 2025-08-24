abstract class ImageRepository {
  Future<String> generateImage(String prompt); // returns Base64 image string
}

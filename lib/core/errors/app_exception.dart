class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  AppException(this.message, {this.code, this.details});

  @override
  String toString() => message;
}

class VModalServiceException extends AppException {
  VModalServiceException(super.message, {super.code, super.details});
}

class VideoUploadException extends AppException {
  VideoUploadException(super.message, {super.code, super.details});
}

class IndexingException extends AppException {
  IndexingException(super.message, {super.code, super.details});
}

class SearchException extends AppException {
  SearchException(super.message, {super.code, super.details});
}

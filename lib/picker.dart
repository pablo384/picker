import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Denotes that an image is being picked.
const String kTypeImage = 'image';

/// Denotes that a video is being picked.
const String kTypeVideo = 'video';

/// Specifies the source where the picked image should come from.
enum ImageSource {
  /// Opens up the device camera, letting the user to take a new picture.
  camera,

  /// Opens the user's photo gallery.
  gallery,
}

/// Provides an easy way to pick an image/video from the image library,
/// or to take a picture/video with the camera.
class Picker {
  static const MethodChannel _channel =
      MethodChannel('plugins.flutter.io/picker');

  /// Returns a [File] object pointing to the image that was picked.
  ///
  /// The `source` argument controls where the image comes from. This can
  /// be either [ImageSource.camera] or [ImageSource.gallery].
  ///
  /// If specified, the image will be at most `maxWidth` wide and
  /// `maxHeight` tall. Otherwise the image will be returned at it's
  /// original width and height.
  /// The `imageQuality` argument modifies the quality of the image, ranging from 0-100
  /// where 100 is the original/max quality. If `imageQuality` is null, the image with
  /// the original quality will be returned. Compression is only supportted for certain
  /// image types such as JPEG. If compression is not supported for the image that is picked,
  /// an warning message will be logged.
  ///
  /// In Android, the MainActivity can be destroyed for various reasons. If that happens, the result will be lost
  /// in this call. You can then call [retrieveLostData] when your app relaunches to retrieve the lost data.
  static Future<File?> pickImage(
      {required ImageSource source,
      double? maxWidth,
      double? maxHeight,
      int? imageQuality}) async {
    assert(imageQuality == null || (imageQuality >= 0 && imageQuality <= 100));

    if (maxWidth != null && maxWidth < 0) {
      throw ArgumentError.value(maxWidth, 'maxWidth cannot be negative');
    }

    if (maxHeight != null && maxHeight < 0) {
      throw ArgumentError.value(maxHeight, 'maxHeight cannot be negative');
    }

    final String? path = await _channel.invokeMethod<String>(
      'pickImage',
      <String, dynamic>{
        'source': source.index,
        'maxWidth': maxWidth,
        'maxHeight': maxHeight,
        'imageQuality': imageQuality
      },
    );

    return path == null ? null : File(path);
  }

  /// Returns a [File] object pointing to the video that was picked.
  ///
  /// The [source] argument controls where the video comes from. This can
  /// be either [ImageSource.camera] or [ImageSource.gallery].
  ///
  /// In Android, the MainActivity can be destroyed for various fo reasons. If that happens, the result will be lost
  /// in this call. You can then call [retrieveLostData] when your app relaunches to retrieve the lost data.
  static Future<File?> pickVideo({
    required ImageSource source,
  }) async {
    final String? path = await _channel.invokeMethod<String>(
      'pickVideo',
      <String, dynamic>{
        'source': source.index,
      },
    );
    return path == null ? null : File(path);
  }

  static Future<String> saveFile(
      {required Uint8List fileData, String? title, String? description}) async {
    String filePath = (await _channel.invokeMethod(
      'saveFile',
      <String, dynamic>{
        'fileData': fileData,
        'title': title,
        'description': description
      },
    ))!;
    debugPrint("saved filePath:" + filePath);
    //process ios return filePath
    if (filePath.startsWith("file://")) {
      filePath = filePath.replaceAll("file://", "");
    }
    return filePath;
  }

  /// Retrieve the lost image file when [pickImage] or [pickVideo] failed because the  MainActivity is destroyed. (Android only)
  ///
  /// Image or video can be lost if the MainActivity is destroyed. And there is no guarantee that the MainActivity is always alive.
  /// Call this method to retrieve the lost data and process the data according to your APP's business logic.
  ///
  /// Returns a [LostDataResponse] if successfully retrieved the lost data. The [LostDataResponse] can represent either a
  /// successful image/video selection, or a failure.
  ///
  /// Calling this on a non-Android platform will throw [UnimplementedError] exception.
  ///
  /// See also:
  /// * [LostDataResponse], for what's included in the response.
  /// * [Android Activity Lifecycle](https://developer.android.com/reference/android/app/Activity.html), for more information on MainActivity destruction.
  static Future<LostDataResponse> retrieveLostData() async {
    final Map<String, dynamic>? result =
        await _channel.invokeMapMethod<String, dynamic>('retrieve');
    if (result == null) {
      return LostDataResponse.empty();
    }
    assert(result.containsKey('path') ^ result.containsKey('errorCode'));

    final String? type = result['type'];
    assert(type == kTypeImage || type == kTypeVideo);

    RetrieveType? retrieveType;
    if (type == kTypeImage) {
      retrieveType = RetrieveType.image;
    } else if (type == kTypeVideo) {
      retrieveType = RetrieveType.video;
    }

    PlatformException? exception;
    if (result.containsKey('errorCode')) {
      exception = PlatformException(
          code: result['errorCode'], message: result['errorMessage']);
    }

    final String? path = result['path'];

    return LostDataResponse(
        file: path == null ? null : File(path),
        exception: exception,
        type: retrieveType);
  }
}

/// The response object of [picker.retrieveLostData].
///
/// Only applies to Android.
/// See also:
/// * [picker.retrieveLostData] for more details on retrieving lost data.
class LostDataResponse {
  /// Creates an instance with the given [file], [exception], and [type]. Any of
  /// the params may be null, but this is never considered to be empty.
  LostDataResponse({this.file, this.exception, this.type});

  /// Initializes an instance with all member params set to null and considered
  /// to be empty.
  LostDataResponse.empty()
      : file = null,
        exception = null,
        type = null,
        _empty = true;

  /// Whether it is an empty response.
  ///
  /// An empty response should have [file], [exception] and [type] to be null.
  bool get isEmpty => _empty;

  /// The file that was lost in a previous [pickImage] or [pickVideo] call due to MainActivity being destroyed.
  ///
  /// Can be null if [exception] exists.
  final File? file;

  /// The exception of the last [pickImage] or [pickVideo].
  ///
  /// If the last [pickImage] or [pickVideo] threw some exception before the MainActivity destruction, this variable keeps that
  /// exception.
  /// You should handle this exception as if the [pickImage] or [pickVideo] got an exception when the MainActivity was not destroyed.
  ///
  /// Note that it is not the exception that caused the destruction of the MainActivity.
  final PlatformException? exception;

  /// Can either be [RetrieveType.image] or [RetrieveType.video];
  final RetrieveType? type;

  bool _empty = false;
}

/// The type of the retrieved data in a [LostDataResponse].
enum RetrieveType {
  /// A static picture. See [picker.pickImage].
  image,

  /// A video. See [picker.pickVideo].
  video
}

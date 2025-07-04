import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class WebSafeImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Map<String, String>? headers;

  const WebSafeImage({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.headers,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return errorWidget ?? _buildDefaultError();
    }

    // For web, use regular Image.network with proper headers
    if (kIsWeb) {
      return Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        headers: headers ?? _getDefaultHeaders(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ?? _buildDefaultPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) {
          print('❌ WebSafeImage failed to load: $imageUrl');
          print('Error: $error');
          return errorWidget ?? _buildDefaultError();
        },
      );
    }

    // For mobile, also use Image.network with headers
    return Image.network(
      imageUrl!,
      width: width,
      height: height,
      fit: fit,
      headers: headers ?? _getDefaultHeaders(),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? _buildDefaultPlaceholder();
      },
      errorBuilder: (context, error, stackTrace) {
        print('❌ Image.network failed to load: $imageUrl');
        print('Error: $error');
        return errorWidget ?? _buildDefaultError();
      },
    );
  }

  Map<String, String> _getDefaultHeaders() {
    return {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
      'Accept': 'image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.9',
      'Cache-Control': 'no-cache',
      'Pragma': 'no-cache',
    };
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade400),
        ),
      ),
    );
  }

  Widget _buildDefaultError() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(
          Icons.error_outline,
          size: (height ?? 60) * 0.3,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }
}
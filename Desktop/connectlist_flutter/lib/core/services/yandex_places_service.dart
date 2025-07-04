import 'package:dio/dio.dart';
import 'package:connectlist/core/config/api_config.dart';
import 'package:connectlist/core/models/content_item.dart';

class YandexPlacesService {
  late final Dio _searchDio;
  late final Dio _geocoderDio;
  
  YandexPlacesService() {
    _searchDio = Dio(BaseOptions(
      baseUrl: ApiConfig.yandexSearchUrl,
    ));
    
    _geocoderDio = Dio(BaseOptions(
      baseUrl: ApiConfig.yandexGeocoderUrl,
    ));
  }
  
  Future<List<ContentItem>> searchPlaces(String query, {double? lat, double? lon}) async {
    try {
      final queryParams = {
        'apikey': ApiConfig.yandexPlaceApiKey,
        'text': query,
        'lang': 'tr_TR',
        'type': 'biz',
        'results': 20,
      };
      
      if (lat != null && lon != null) {
        queryParams['ll'] = '$lon,$lat';
        queryParams['spn'] = '0.5,0.5';
      }
      
      final response = await _searchDio.get('/', queryParameters: queryParams);
      
      final features = response.data['features'] as List? ?? [];
      return features.map((place) => ContentItem.fromYandexPlace(place)).toList();
    } catch (e) {
      print('Error searching places: $e');
      return [];
    }
  }
  
  Future<Map<String, dynamic>?> getPlaceDetailsByCoordinates(double lat, double lon) async {
    try {
      final response = await _geocoderDio.get('/', queryParameters: {
        'apikey': ApiConfig.yandexGeocoderApiKey,
        'geocode': '$lon,$lat',
        'format': 'json',
        'lang': 'tr_TR',
      });
      
      final featureMember = response.data['response']['GeoObjectCollection']['featureMember'];
      if (featureMember != null && featureMember.isNotEmpty) {
        return featureMember[0]['GeoObject'];
      }
      return null;
    } catch (e) {
      print('Error getting place details: $e');
      return null;
    }
  }
  
  Future<Map<String, dynamic>?> geocodeAddress(String address) async {
    try {
      final response = await _geocoderDio.get('/', queryParameters: {
        'apikey': ApiConfig.yandexGeocoderApiKey,
        'geocode': address,
        'format': 'json',
        'lang': 'tr_TR',
      });
      
      final featureMember = response.data['response']['GeoObjectCollection']['featureMember'];
      if (featureMember != null && featureMember.isNotEmpty) {
        return featureMember[0]['GeoObject'];
      }
      return null;
    } catch (e) {
      print('Error geocoding address: $e');
      return null;
    }
  }
}
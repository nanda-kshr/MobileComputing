import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:app/main.dart';
import 'package:app/services/api_service.dart';

void main() {
  testWidgets('PosApp launches and displays Product Catalog', (WidgetTester tester) async {
    final mockClient = MockClient((request) async {
      if (request.url.path.endsWith('/api/categories')) {
        return http.Response(jsonEncode([]), 200);
      }
      if (request.url.path.endsWith('/api/products')) {
        return http.Response(jsonEncode([]), 200);
      }
      return http.Response('Not Found', 404);
    });

    final apiService = ApiService(client: mockClient, baseUrl: 'http://test.local');

    await tester.pumpWidget(PosApp(apiService: apiService));
    await tester.pumpAndSettle();

    expect(find.text('Product Catalog'), findsOneWidget);
  });
}

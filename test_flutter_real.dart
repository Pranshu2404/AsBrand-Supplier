import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  final url = Uri.parse('http://52.70.7.244:3000/supplier/products');
  final body = {
    "name": "Dart Real World Product",
    "description": "testing",
    "price": "100",
    "quantity": "10",
    "proCategoryId": "69a01325b73d9a56fdc3e483",
    "proSubCategoryId": "69a03f5dea4c2c0ae862ce2c",
    "skus": [
      {
        "skuId": "PEE-RED-L-1",
        "attributes": {"red": "red", "size": "l"},
        "stock": 18,
        "price": 100.0,
        "images": ["https://res.cloudinary.com/demo/image/upload/sample.jpg"]
      },
      {
        "skuId": "PEE-RED-M-2",
        "attributes": {"red": "red", "size": "m"},
        "stock": 18,
        "price": 100.0,
        "images": ["https://res.cloudinary.com/demo/image/upload/sample.jpg"]
      }
    ],
    "proVariants": [
      {
        "variantTypeName": "red",
        "items": ["red", "green"]
      },
      {
        "variantTypeName": "size",
        "items": ["l", "m"]
      }
    ]
  };

  final request = await HttpClient().postUrl(url);
  request.headers.set('Content-Type', 'application/json');
  request.headers.set('Authorization', 'Bearer ${args[0]}');
  request.add(utf8.encode(jsonEncode(body)));
  final response = await request.close();
  final responseBody = await response.transform(utf8.decoder).join();
  
  print('Status: ${response.statusCode}');
  print('Body: $responseBody');
}

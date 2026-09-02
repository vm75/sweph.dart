import 'package:example_dart/example.dart';
import 'package:web/web.dart';

void setValue(String id, String value) {
  (document.querySelector('#$id') as HTMLElement).textContent = value;
}

void main() {
  getSwephData().then((result) {
    result.forEach((key, value) => setValue(key, value));
  });
}

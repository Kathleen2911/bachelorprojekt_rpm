import 'dart:convert' as convert;
import "package:http/http.dart" as http;
import 'kunden_form.dart';

class FormController {
  final void Function(String) callback;

  static const String URL =
      "https://script.google.com/macros/s/AKfycbyymZs-wdzS285dCeKo7BDu0Vr0wSxkKZgAj5RTWox-XFdRsX8/exec";

  static const STATUS_SUCCESS = "SUCCESS";

  FormController(this.callback);

  void submitForm(KundenForm kundenForm) async {
    try {
      await http.get(URL + kundenForm.toParams()).then((response) {
        callback(convert.jsonDecode(response.body)['status']);
      });
    } catch (e) {
      print(e);
    }
  }
}

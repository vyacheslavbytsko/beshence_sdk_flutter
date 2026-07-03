import '../../beshence_sdk_flutter.dart';
import 'event.dart';

class BeshenceChain {
  final String name;
  final BeshenceAccount account;

  BeshenceChain({required this.name, required this.account});

  Future<void> addEvent(BeshenceEvent event) async {

  }
}
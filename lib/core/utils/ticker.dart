class Ticker {
  const Ticker();

  Stream<int> tick({Duration interval = const Duration(seconds: 1)}) {
    return Stream.periodic(interval, (count) => count + 1);
  }
}

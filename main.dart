import 'dart:io';

class GameResult {
  final Map<Player, double> probabilities;

  String toString() {
    return (probabilities.entries.toList()
          ..sort(((a, b) => a.key.index.compareTo(b.key.index))))
        .map((e) => e.value * 100)
        .join('/');
  }

  GameResult(this.probabilities) {
    if (probabilities.values.any((element) => element > 1)) {
      throw StateError('Invalid probability');
    }
  }
}

typedef GameState = Map<Player, int>;

enum Player { A, B, C }

const Player bestHuman = Player.B;
const List<Player> humans = [Player.A, Player.B];
const Map<Player, bool> dwm = {
  Player.A: false,
  Player.B: false,
  Player.C: false
};

MapEntry<GameResult, Player?> findMove(
  bool doFindMove,
  Player me,
  GameState state,
  bool doWorstMove,
) {
  List<Player> candidates = Player.values.toList();
  candidates.remove(me);
  List<MapEntry<GameResult, Player>> results = [];
  for (Player player in candidates) {
    if (state[player] == 0) {
      continue;
    }
    GameState newState = Map.of(state);
    newState[player] = newState[player]! - 1;
    Player op = candidates.singleWhere((element) => element != player);
    if (newState[player] == 0 && newState[op] == 0) {
      results.add(MapEntry(GameResult({me: 1, player: 0, op: 0}), player));
      continue;
    }
    results.add(
      MapEntry(
        findMove(
          false,
          [Player.values[(me.index + 1) % 3], Player.values[(me.index + 2) % 3]]
              .firstWhere((element) => !(newState[element] == 0)),
          newState,
          false,
        ).key,
        player,
      ),
    );
  }
  if (results.isEmpty) {
    throw '$candidates:$results';
  }
  if (results.length == 1) {
    if (results.single.value == me) {
      throw "ERR";
    }
    if (doFindMove) {
      return results.single;
    } else {
      return MapEntry(results.single.key, null);
    }
  } else {
    if (results.first.key.probabilities[me]! >
        results.last.key.probabilities[me]!) {
      if (results.first.value == me) {
        throw "ERR";
      }
      if (doFindMove) {
        if (doWorstMove) return results.last;
        return results.first;
      } else {
        return MapEntry(results.first.key, null);
      }
    }
    if (results.last.key.probabilities[me]! >
        results.first.key.probabilities[me]!) {
      if (results.last.value == me) {
        throw "ERR";
      }
      if (doFindMove) {
        if (doWorstMove) return results.first;
        return results.last;
      } else {
        return MapEntry(results.last.key, null);
      }
    }
    if (!doFindMove) {
      return MapEntry(
        results.fold(GameResult({}), (previousValue, element) {
          if (previousValue.probabilities.isEmpty) {
            return element.key;
          }
          Map<Player, double> result = {};
          for (MapEntry entry in previousValue.probabilities.entries) {
            result[entry.key] = entry.value / 2;
          }
          for (MapEntry entry in element.key.probabilities.entries) {
            result[entry.key] = result[entry.key]! + entry.value / 2;
          }
          return GameResult(result);
        }),
        null,
      );
    }

    if (results.first.key.probabilities[bestHuman] ==
        results.last.key.probabilities[bestHuman]) {
      Player p = me == Player.A ? Player.C : Player.A;

      if (p == me) {
        throw "ERR";
      }
      return results.singleWhere((element) => element.value == p);
    }
    Player p = (results.first.key.probabilities[bestHuman]! >
            results.last.key.probabilities[bestHuman]!)
        ? results.first.value
        : results.last.value;

    if (p == me) {
      throw "ERR";
    }
    return results.singleWhere((element) => element.value == p);
  }
}

String sts(GameState state) {
  return (state.entries.toList()
        ..sort(((a, b) => a.key.index.compareTo(b.key.index))))
      .map((e) => e.value)
      .join('/');
}

void main() {
  GameState state = {Player.A: 6, Player.B: 6, Player.C: 5};
  void handleMove(Player p) {
    if (state[p] != 0) {
      if (humans.contains(p)) {
        print('Your turn! You are ${p.name}.');
        String p2 = stdin.readLineSync()!;
        if (p2 == 'B') {
          print("${p.name} ATTACKS B");
          state[Player.B] = state[Player.B]! - 1;
        } else if (p2 == 'C') {
          print("${p.name} ATTACKS C");
          state[Player.C] = state[Player.C]! - 1;
        } else {
          print("${p.name} ATTACKS A");
          state[Player.A] = state[Player.A]! - 1;
        }
        List<Player> oths = [
          Player.values[(p.index + 1) % 3],
          Player.values[(p.index - 1) % 3]
        ].where((element) => state[element] != 0).toList();
        if (oths.isEmpty) {
          print('HP: ${sts(state)}');
          print('ANALYSIS: <you won>');
        } else {
          Player next = oths.first;
          //print(next);
          MapEntry<GameResult, Player?> p3 =
              findMove(false, next, state, false);
          print('HP: ${sts(state)}');
          print('ANALYSIS: ${p3.key}');
        }
      } else {
        print('Robot ${p.name}\'s turn.');
        MapEntry<GameResult, Player?> p2 = findMove(true, p, state, dwm[p]!);
        print("${p.name} ATTACKS ${p2.value!.name}");
        state[p2.value!] = state[p2.value]! - 1;
        print('HP: ${sts(state)}');
        print('ANALYSIS: ${p2.key}');
      }
      if (state.values.where((element) => element > 0).length < 2) {
        print(
            '${state.entries.singleWhere((element) => element.value > 0).key.name} wins!');
        exit(0);
      }
    }
  }

  while (true) {
    handleMove(Player.A);
    handleMove(Player.B);
    handleMove(Player.C);
  }
}

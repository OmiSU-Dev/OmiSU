/// Lightweight fuzzy text matching for library search.
///
/// Supports substring matches, ordered-character (subsequence) matches, and
/// small typos via edit distance — without pulling in a search dependency.

/// Minimum relevance for a candidate to count as a match.
const double kFuzzyMatchThreshold = 0.52;

/// Normalizes titles for comparison: lowercase, punctuation → space, collapse.
String normalizeForSearch(String input) {
  return input
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w\s]', unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// Whether [candidate] fuzzily matches [query].
bool fuzzyMatchesQuery(String query, String candidate) {
  return fuzzyMatchScore(query, candidate) != null;
}

/// Relevance in `[0, 1]`, or null when below [kFuzzyMatchThreshold].
double? fuzzyMatchScore(String query, String candidate) {
  final q = normalizeForSearch(query);
  if (q.isEmpty) return 1.0;

  final c = normalizeForSearch(candidate);
  if (c.isEmpty) return null;

  final tokens = q.split(' ').where((t) => t.isNotEmpty).toList();
  if (tokens.isEmpty) return 1.0;

  if (tokens.length == 1) {
    return _scoreToken(tokens.single, c);
  }

  var total = 0.0;
  for (final token in tokens) {
    final score = _scoreToken(token, c);
    if (score == null) return null;
    total += score;
  }
  return (total / tokens.length).clamp(0.0, 1.0);
}

double? _scoreToken(String token, String candidate) {
  double? best;

  if (candidate.contains(token)) {
    best = _maxScore(best, _substringScore(token, candidate));
  }

  for (final (wordIndex, word) in candidate.split(' ').indexed) {
    if (word.isEmpty) continue;
    if (word.contains(token)) {
      final wordScore = _substringScore(token, word) - wordIndex * 0.04;
      best = _maxScore(best, wordScore);
    }
    best = _maxScore(best, _subsequenceScore(token, word));
    if (token.length >= 3) {
      best = _maxScore(best, _levenshteinWordScore(token, word));
    }
  }

  best = _maxScore(best, _subsequenceScore(token, candidate));

  if (best == null || best < kFuzzyMatchThreshold) return null;
  return best.clamp(0.0, 1.0);
}

double _substringScore(String token, String haystack) {
  final idx = haystack.indexOf(token);
  var score = 0.86 + (token.length / haystack.length).clamp(0.0, 0.08);
  if (idx == 0) {
    score += 0.06;
  } else if (idx > 0 && haystack[idx - 1] == ' ') {
    score += 0.03;
  }
  score -= (idx / haystack.length) * 0.08;
  return score.clamp(0.0, 1.0);
}

/// All characters of [needle] appear in order inside [haystack].
double? _subsequenceScore(String needle, String haystack) {
  if (needle.isEmpty) return 1.0;

  var needleIndex = 0;
  var consecutive = 0;
  var maxConsecutive = 0;
  var gapPenalty = 0;

  for (var i = 0; i < haystack.length && needleIndex < needle.length; i++) {
    if (haystack[i] == needle[needleIndex]) {
      needleIndex++;
      consecutive++;
      if (consecutive > maxConsecutive) maxConsecutive = consecutive;
    } else if (consecutive > 0) {
      gapPenalty++;
      consecutive = 0;
    }
  }

  if (needleIndex < needle.length) return null;

  final coverage = needle.length / haystack.length;
  final consecutiveBonus = (maxConsecutive / needle.length) * 0.14;
  final score = 0.56 + coverage * 0.22 + consecutiveBonus - gapPenalty * 0.015;
  return score.clamp(0.0, 0.88);
}

double? _levenshteinWordScore(String token, String word) {
  if (token.length < 3 || word.length < 3) return null;
  if ((token.length - word.length).abs() > 2) return null;

  final distance = _levenshtein(token, word);
  final maxLen = token.length > word.length ? token.length : word.length;
  final ratio = 1.0 - distance / maxLen;
  if (ratio < 0.72) return null;
  return (0.58 + ratio * 0.26).clamp(0.0, 0.84);
}

int _levenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  final previous = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 0; i < a.length; i++) {
    var corner = previous[0];
    previous[0] = i + 1;
    for (var j = 0; j < b.length; j++) {
      final upperLeft = corner;
      corner = previous[j + 1];
      final cost = a[i] == b[j] ? 0 : 1;
      previous[j + 1] = _min3(
        previous[j + 1] + 1,
        previous[j] + 1,
        upperLeft + cost,
      );
    }
  }
  return previous[b.length];
}

int _min3(int a, int b, int c) => a < b ? (a < c ? a : c) : (b < c ? b : c);

double? _maxScore(double? current, double? candidate) {
  if (candidate == null) return current;
  if (current == null) return candidate;
  return candidate > current ? candidate : current;
}

library shapshift.hybrid_revision;

import 'package:pub_semver/pub_semver.dart';

abstract class HybridRevision<T> implements Comparable<HybridRevision> {
  final T value;

  HybridRevision._(this.value);

  static HybridRevision parse(String raw) {
    var intValue = int.parse(raw, onError: (_) => null);
    if (intValue != null) {
      return new SvnRevision(intValue);
    }

    var version = new Version.parse(raw);
    return new SemVerRevision(version);
  }
}

class SvnRevision extends HybridRevision<int> {
  SvnRevision(int value) : super._(value);

  int compareTo(HybridRevision other) {
    if (other is SvnRevision) {
      return value.compareTo(other.value);
    } else {
      assert(other is SemVerRevision);
      return -1;
    }
  }

  bool operator ==(other) => other is SvnRevision && other.value == value;

  int get hashCode => value.hashCode;
}

class SemVerRevision extends HybridRevision<Version> {
  SemVerRevision(Version value) : super._(value);

  int compareTo(HybridRevision other) {
    if (other is SemVerRevision) {
      return value.compareTo(other.value);
    } else {
      assert(other is SvnRevision);
      return 1;
    }
  }

  bool operator ==(other) => other is SemVerRevision && other.value == value;

  int get hashCode => value.hashCode;
}

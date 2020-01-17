module dud.semver2.setoperation;

import dud.semver2.versionunion;
import dud.semver2.versionrange;
import dud.semver2.semver;

@safe pure:

VersionUnion unionOf(const(SemVer) a, const(SemVer) b) {
	VersionUnion ret = VersionUnion(
			[ VersionRange(a, Inclusive.yes, a, Inclusive.yes)
			, VersionRange(b, Inclusive.yes, b, Inclusive.yes)
			]);
	return ret;
}

VersionUnion unionOf(const(SemVer) a, const(VersionRange) b) {
	return unionOf(b, a);
}

VersionUnion unionOf(const(VersionRange) a, const(SemVer) b) {
	VersionUnion ret = VersionUnion(
			[ a.dup
			, VersionRange(b, Inclusive.yes, b, Inclusive.yes)
			]);
	return ret;
}

VersionUnion unionOf(const(SemVer) a, const(VersionUnion) b) {
	return unionOf(b, a);
}

VersionUnion unionOf(const(VersionUnion) a, const(SemVer) b) {
	VersionUnion ret = a.dup();
	ret.insert(VersionRange(b, Inclusive.yes, b, Inclusive.yes));
	return ret;
}

VersionUnion unionOf(const(VersionRange) a, const(VersionRange) b) {
	VersionUnion ret = VersionUnion([a.dup , b.dup]);
	return ret;
}

VersionUnion unionOf(const(VersionRange) a, const(VersionUnion) b) {
	return unionOf(b, a);
}
VersionUnion unionOf(const(VersionUnion) a, const(VersionRange) b) {
	VersionUnion ret = a.dup();
	ret.insert(b);
	return ret;
}

VersionUnion unionOf(const(VersionUnion) a, const(VersionUnion) b) {
	import std.algorithm.iteration : each;

	VersionUnion ret = a.dup();
	b.ranges.each!(it => ret.insert(it));
	return ret;
}

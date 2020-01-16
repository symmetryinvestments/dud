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

VersionUnion unionOf(const(VersionRange) a, const(SemVer) b) {
	VersionUnion ret = VersionUnion(
			[ a.dup
			, VersionRange(b, Inclusive.yes, b, Inclusive.yes)
			]);
	return ret;
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

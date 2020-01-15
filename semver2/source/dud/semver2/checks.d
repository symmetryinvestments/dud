module dud.semver2.checks;

import std.algorithm.searching : any;

import dud.semver2.versionunion;
import dud.semver2.versionrange;
import dud.semver2.semver;

@safe pure:

/// Returns `true` if this constraint allows [version].
bool allowsAny(const(VersionRange) toCheckIn, const(SemVer) toCheck) {
	return isInRange(toCheckIn, toCheck);
}

bool allowsAny(const(VersionRange) toCheckIn, const(VersionRange) toCheck) {
	const SetRelation sr = relation(toCheck, toCheckIn);
	return sr != SetRelation.disjoint;
}

bool allowsAny(const(VersionRange) toCheckIn, const(VersionUnion) toCheck) {
	return toCheck.ranges
		.any!(vr => relation(vr, toCheckIn) != SetRelation.disjoint);
}

bool allowsAny(const(VersionUnion) toCheckIn, const(SemVer) toCheck) {
	return toCheckIn.ranges.any!(vr => isInRange(vr, toCheck));
}

bool allowsAny(const(VersionUnion) toCheckIn, const(VersionRange) toCheck) {
	return toCheckIn.ranges
		.any!(vr => relation(toCheck, vr) != SetRelation.disjoint);
}

bool allowsAny(const(VersionUnion) toCheckIn, const(VersionUnion) toCheck) {
	foreach(it; toCheck.ranges) {
		foreach(jt; toCheckIn.ranges) {
			const SetRelation sr = relation(it, jt);
			if(sr != SetRelation.disjoint) {
				return true;
			}
		}
	}
	return false;
}

/// Returns `true` if this constraint allows all the versions that [other]
/// allows.
bool allowsAll(const(VersionRange) toCheckIn, const(SemVer) toCheck) {
	return isInRange(toCheckIn, toCheck);
}

bool allowsAll(const(VersionRange) toCheckIn, const(VersionRange) toCheck) {
	return relation(toCheck, toCheckIn) == SetRelation.subset;
}

bool allowsAll(const(VersionRange) toCheckIn, const(VersionUnion) toCheck) {
	return toCheck.ranges
		.any!(vr => relation(vr, toCheckIn) == SetRelation.subset);
}

bool allowsAll(const(VersionUnion) toCheckIn, const(SemVer) toCheck) {
	return toCheckIn.ranges.any!(vr => isInRange(vr, toCheck));
}

bool allowsAll(const(VersionUnion) toCheckIn, const(VersionRange) toCheck);
bool allowsAll(const(VersionUnion) toCheckIn, const(VersionUnion) toCheck);

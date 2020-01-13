module dud.semver2.checks;

import dud.semver2.versionunion;
import dud.semver2.range;
import dud.semver2.semver;

/// Returns `true` if this constraint allows [version].
bool allows(const(VersionRange) toCheckIn, const(SemVer) toCheck) {
	return isInRange(toCheckIn, toCheck);
}

bool allows(const(VersionRange) toCheckIn, const(VersionRange) toCheck);
bool allows(const(VersionRange) toCheckIn, const(VersionUnion) toCheck);

bool allows(const(VersionUnion) toCheckIn, const(SemVer) toCheck);
bool allows(const(VersionUnion) toCheckIn, const(VersionRange) toCheck);
bool allows(const(VersionUnion) toCheckIn, const(VersionUnion) toCheck);

/// Returns `true` if this constraint allows all the versions that [other]
/// allows.
bool allowsAll(const(VersionRange) toCheckIn, const(SemVer) toCheck);
bool allowsAll(const(VersionRange) toCheckIn, const(VersionRange) toCheck);
bool allowsAll(const(VersionRange) toCheckIn, const(VersionUnion) toCheck);

bool allowsAll(const(VersionUnion) toCheckIn, const(SemVer) toCheck);
bool allowsAll(const(VersionUnion) toCheckIn, const(VersionRange) toCheck);
bool allowsAll(const(VersionUnion) toCheckIn, const(VersionUnion) toCheck);

/// Returns `true` if this constraint allows any of the versions that [other]
/// allows.
bool allowsAny(const(VersionRange) toCheckIn, const(SemVer) toCheck);
bool allowsAny(const(VersionRange) toCheckIn, const(VersionRange) toCheck);
bool allowsAny(const(VersionRange) toCheckIn, const(VersionUnion) toCheck);

bool allowsAny(const(VersionUnion) toCheckIn, const(SemVer) toCheck);
bool allowsAny(const(VersionUnion) toCheckIn, const(VersionRange) toCheck);
bool allowsAny(const(VersionUnion) toCheckIn, const(VersionUnion) toCheck);

module dud.semver2.checks;

import dud.semver2.versionunion;
import dud.semver2.range;
import dud.semver2.semver;

/// Returns `true` if this constraint allows [version].
bool allows(VersionRange toCheckIn, SemVer toCheck);
bool allows(VersionRange toCheckIn, VersionRange toCheck);
bool allows(VersionRange toCheckIn, VersionUnion toCheck);

bool allows(VersionUnion toCheckIn, SemVer toCheck);
bool allows(VersionUnion toCheckIn, VersionRange toCheck);
bool allows(VersionUnion toCheckIn, VersionUnion toCheck);

/// Returns `true` if this constraint allows all the versions that [other]
/// allows.
bool allowsAll(VersionRange toCheckIn, SemVer toCheck);
bool allowsAll(VersionRange toCheckIn, VersionRange toCheck);
bool allowsAll(VersionRange toCheckIn, VersionUnion toCheck);

bool allowsAll(VersionUnion toCheckIn, SemVer toCheck);
bool allowsAll(VersionUnion toCheckIn, VersionRange toCheck);
bool allowsAll(VersionUnion toCheckIn, VersionUnion toCheck);

/// Returns `true` if this constraint allows any of the versions that [other]
/// allows.
bool allowsAny(VersionRange toCheckIn, SemVer toCheck);
bool allowsAny(VersionRange toCheckIn, VersionRange toCheck);
bool allowsAny(VersionRange toCheckIn, VersionUnion toCheck);

bool allowsAny(VersionUnion toCheckIn, SemVer toCheck);
bool allowsAny(VersionUnion toCheckIn, VersionRange toCheck);
bool allowsAny(VersionUnion toCheckIn, VersionUnion toCheck);

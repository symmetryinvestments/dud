module dud.semver2.testdata;

@safe pure private:
import dud.semver2.semver;
import dud.semver2.versionrange;
import dud.semver2.versionunion;

immutable VersionRange vr1 = parseVersionRange(">=1.0.0 <=2.0.0").get();
immutable VersionRange vr2 = parseVersionRange(">=2.5.0 <=3.0.0").get();
immutable VersionRange vr3 = parseVersionRange(">=1.5.0 <=3.0.0").get();
immutable VersionRange vr4 = parseVersionRange(">=2.7.0 <=3.0.0").get();
immutable VersionRange vr5 = parseVersionRange(">3.0.0 <=4.0.0").get();

immutable VersionUnion vu1 = VersionUnion([vr1, vr4]);
immutable VersionUnion vu2 = VersionUnion([vr1, vr2]);
immutable VersionUnion vu3 = VersionUnion([vr3, vr4]);
immutable VersionUnion vu4 = VersionUnion([vr2, vr4]);
immutable VersionUnion vu5 = VersionUnion([vr1, vr5]);

immutable SemVer v1 = SemVer(0, 1, 0);
immutable SemVer v2 = SemVer(1, 1, 0);
immutable SemVer v3 = SemVer(2, 1, 0);
immutable SemVer v4 = SemVer(2, 5, 0);

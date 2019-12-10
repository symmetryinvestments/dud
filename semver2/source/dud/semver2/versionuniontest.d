module dud.semver2.versionuniontest;

@safe pure private:
import std.format : format;
import dud.semver2.semver;
import dud.semver2.parse;
import dud.semver2.versionrange;
import dud.semver2.versionunion;
import dud.semver2.comparision;

unittest {
	VersionRange vr1 = parseVersionRange(">=1.0.0 <=2.0.0").get();
	VersionRange vr2 = parseVersionRange(">=1.5.0 <=3.0.0").get();

	VersionRange m = merge(vr1, vr2);
	SetRelation sr = relation(m, parseVersionRange(">=1.0.0 <=3.0.0").get());
	assert(sr == SetRelation.subset, format("\nm: %s\nsr: %s", m, sr));

	m = merge(vr2, vr1);
	sr = relation(m, parseVersionRange(">=1.0.0 <=3.0.0").get());
	assert(sr == SetRelation.subset, format("\nm: %s\nsr: %s", m, sr));
}

unittest {
	VersionRange vr1 = parseVersionRange(">=1.0.0 <=1.5.0").get();
	VersionRange vr2 = parseVersionRange(">=1.5.0 <=3.0.0").get();

	VersionRange m = merge(vr1, vr2);
	SetRelation sr = relation(m, parseVersionRange(">=1.0.0 <=3.0.0").get());
	assert(sr == SetRelation.subset, format("\nm: %s\nsr: %s", m, sr));

	m = merge(vr2, vr1);
	sr = relation(m, parseVersionRange(">=1.0.0 <=3.0.0").get());
	assert(sr == SetRelation.subset, format("\nm: %s\nsr: %s", m, sr));
}

unittest {
	VersionRange vr1 = parseVersionRange(">=1.0.0 <1.5.0").get();
	VersionRange vr2 = parseVersionRange(">1.5.0 <=3.0.0").get();

	VersionRange m = merge(vr1, vr2);
	assert(m == VersionRange.init, format("\n%s", m));

	m = merge(vr2, vr1);
	assert(m == VersionRange.init, format("\n%s", m));
}

unittest {
	VersionRange vr1 = parseVersionRange(">=1.0.0 <=1.5.0").get();
	VersionRange vr2 = parseVersionRange(">1.5.0 <=3.0.0").get();

	VersionRange m = merge(vr1, vr2);
	assert(m == VersionRange.init, format("\n%s", m));

	m = merge(vr2, vr1);
	assert(m == VersionRange.init, format("\n%s", m));
}

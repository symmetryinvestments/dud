module dud.semver2.versionuniontest;

@safe pure private:
import std.array : front;
import std.format : format;
import std.stdio;

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

unittest {
	VersionRange[] arr =
		[ parseVersionRange(">=1.0.0 <=1.5.0").get()
		, parseVersionRange(">=2.0.0 <=3.5.0").get()
		];

	VersionRange vr = parseVersionRange(">=1.5.0 <=2.0.0").get();
	VersionRange[] m = merge(arr, vr);
	assert(m.length == 1, format("%s", m));

	auto exp = parseVersionRange(">=1.0.0 <=3.5.0").get();
	assert(m.front == exp, format("\nexp: %s\ngot: %s", exp, m.front));
}

unittest {
	const VersionRange vr1 = parseVersionRange(">=1.0.0 <=2.0.0").get();
	const VersionRange vr2 = parseVersionRange(">=1.5.0 <=3.0.0").get();
	const VersionRange vr3 = parseVersionRange(">=3.5.0 <=4.0.0").get();
	const VersionRange vr4 = parseVersionRange(">=4.5.0 <=5.0.0").get();
	const VersionRange vr5 = parseVersionRange(">=3.0.0 <=3.5.0").get();
	const VersionRange vr6 = parseVersionRange(">=4.0.0 <=4.5.0").get();

	VersionUnion vu;
	vu.insert(vr1);
	vu.insert(vr2);
	assert(vu.ranges.length == 1);
	vu.insert(vr3);
	assert(vu.ranges.length == 2);
	vu.insert(vr4);
	assert(vu.ranges.length == 3);
	vu.insert(vr5);
	assert(vu.ranges.length == 2);
	vu.insert(vr6);
	assert(vu.ranges.length == 1);
}

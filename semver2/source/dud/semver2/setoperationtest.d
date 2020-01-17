module dud.semver2.setoperationtest;

@safe pure private:
import std.exception : assertThrown, assertNotThrown;
import std.stdio;
import std.format : format;

import dud.semver2.checks;
import dud.semver2.parse;
import dud.semver2.semver;
import dud.semver2.versionrange;
import dud.semver2.versionunion;
import dud.semver2.setoperation;

import dud.semver2.testdata;

unittest { // SemVer, SemVer
	VersionUnion vu = unionOf(v1, v2);
	assert( allowsAll(vu, v1));
	assert( allowsAll(vu, v2));
	assert(!allowsAll(vu, v3));
	assert(!allowsAll(vu, v4));

	assert(!allowsAll(vu, vr1));
}

// VersionRange, SemVer
unittest {
	const VersionUnion vu = unionOf(vr1, v1);
	assert(vu.ranges.length == 2);
	assert(vu.ranges[1] == vr1);

	assert( allowsAll(vu, v1));
	assert( allowsAll(vu, vr1));

	const VersionUnion vu2 = unionOf(v1, vr1);
}

unittest {
	const VersionUnion vu = unionOf(vr1, v2);
	assert(vu.ranges.length == 1);
	assert( allowsAll(vu, v2));
	assert( allowsAll(vu, vr1), format("\n%s\n%s", vu, vr1));
}

unittest {
	const all = [vr1, vr2, vr3, vr4, vr5, vr6];
	foreach(it; all) {
		foreach(jt; all) {
			const VersionUnion vu = unionOf(it, jt);
			assert(allowsAll(vu, it));
			assert(allowsAll(vu, jt));

			const SetRelation sr = relation(it, jt);
			assert(vu.ranges.length == (sr == SetRelation.disjoint ? 2 : 1),
				format("\nit:%s\njt:%s\nrs:%s", it, jt, vu.ranges));

			const VersionUnion c = vu.dup();
			assert(allowsAll(c, it));
			assert(allowsAll(c, jt));
		}
	}
}

// VersionUnion, SemVer
unittest {
	const VersionUnion m = unionOf(vu2, v4);
	assert(m.ranges.length == 2);
	assert(allowsAll(m, vr1));
	assert(allowsAll(m, vr2));
	assert(allowsAll(m, v4));

	const VersionUnion m2 = unionOf(v4, vu2);
	assert(m == m2);
}

// VersionUnion, VersionRange
unittest {
	const VersionUnion m = unionOf(vu1, vr6);
	assert(m.ranges.length == 1);
	assert(allowsAll(m, vu1));
	assert(allowsAll(m, vr3));

	const VersionUnion m2 = unionOf(vr6, vu1);
	assert(m == m2);
}

// VersionUnion, VersionUnion
unittest {
	const VersionUnion m = unionOf(vu1, vu2);
	assert(m.ranges.length == 2);
	assert(allowsAll(m, vr1));
	assert(allowsAll(m, vr2));
	assert(allowsAll(m, vr4));
}

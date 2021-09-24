module dud.resolve.toolchaintest;

import std.algorithm.searching;
import dud.pkgdescription : Toolchain;
import dud.resolve.toolchain;
import dud.semver.versionunion;
import dud.semver.versionrange;

private:

const a = ToolchainVersionUnion(Toolchain.dmd, false
	, VersionUnion([parseVersionRange("^1.0.0").get()]));
const b = ToolchainVersionUnion(Toolchain.dmd, false
	, VersionUnion([parseVersionRange("^1.1.0").get()]));
const c = ToolchainVersionUnion(Toolchain.ldc, false
	, VersionUnion([parseVersionRange("^1.3.0").get()]));

const aa = [a.dup()];
const ab = [a.dup(),b.dup()];
const ac = [b.dup(),a.dup()];
const ad = [b.dup()];
const ae = [c.dup(),a.dup()];
const af = [c.dup(),a.dup(),a.dup()];

unittest {
	assert( areEqual(aa, aa));
	assert(!areEqual(aa, ab));
	assert(!areEqual(aa, ac));
	assert(!areEqual(aa, ad));
	assert(!areEqual(aa, ae));
	assert(!areEqual(aa, af));

	assert( areEqual(ab, ab));
	assert( areEqual(ab, ac));
	assert(!areEqual(ab, ad));
	assert(!areEqual(ab, ae));
	assert(!areEqual(ab, af));

	assert( areEqual(ac, ac));
	assert(!areEqual(ac, ad));
	assert(!areEqual(ac, ae));
	assert(!areEqual(ac, af));

	assert( areEqual(ad, ad));
	assert(!areEqual(ad, ae));
	assert(!areEqual(ad, af));

	assert( areEqual(ae, ae));
	assert(!areEqual(ae, af));

	assert( areEqual(af, af));
	assert(!areEqual(af, aa));
}

unittest {
	assert(areEqual(aa, aa) && relation(aa, aa) == SetRelation.subset);
}

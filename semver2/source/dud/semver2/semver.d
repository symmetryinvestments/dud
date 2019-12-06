module dud.semver2.semver;

@safe:

struct SemVer {
	uint major;
	uint minor;
	uint patch;

	string[] preRelease;
	string[] buildIdentifier;

	bool opEquals(const(SemVer) other) pure @safe nothrow {
		import dud.semver2.comparision : compare;
		return compare(this, other) == 0;
	}

	int opCmp(ref const(SemVer) other) pure @safe nothrow {
		import dud.semver2.comparision : compare;
		return compare(this, other);
	}
}

module dud.semver2.semver;

@safe:

struct SemVer {
@safe pure:

	uint major;
	uint minor;
	uint patch;

	string[] preRelease;
	string[] buildIdentifier;

	static immutable(SemVer) MinRelease = SemVer(0, 0, 0);
	static immutable(SemVer) MaxRelease = SemVer(uint.max, uint.max, uint.max);

	bool opEquals(const(SemVer) other) const nothrow {
		import dud.semver2.comparision : compare;
		return compare(this, other) == 0;
	}

	int opCmp(ref const(SemVer) other) const nothrow {
		import dud.semver2.comparision : compare;
		return compare(this, other);
	}

	size_t toHash() const nothrow @nogc {
		import std.algorithm.iteration : each;
		size_t hash = this.major.hashOf();
		hash = this.minor.hashOf(hash);
		hash = this.patch.hashOf(hash);
		this.preRelease.each!(it => hash = it.hashOf(hash));
		this.buildIdentifier.each!(it => hash = it.hashOf(hash));
		return hash;
	}

	@property SemVer dup() const {
		auto ret = SemVer(this.major, this.minor, this.patch,
				this.preRelease.dup(), this.buildIdentifier.dup());
		return ret;
	}

	static SemVer max() {
		return SemVer(uint.max, uint.max, uint.max);
	}

	static SemVer min() {
		return SemVer(uint.min, uint.min, uint.min);
	}
}

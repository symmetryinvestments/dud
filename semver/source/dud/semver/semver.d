module dud.semver.semver;

@safe:

struct SemVer {
@safe:

	uint major;
	uint minor;
	uint patch;

	string[] preRelease;
	string[] buildIdentifier;

	static immutable(SemVer) MinRelease = SemVer(0, 0, 0);
	static immutable(SemVer) MaxRelease = SemVer(uint.max, uint.max, uint.max);

	bool opEquals(const(SemVer) other) const nothrow pure {
		import dud.semver.comparision : compare;
		return compare(this, other) == 0;
	}

	int opCmp(const(SemVer) other) const nothrow pure {
		import dud.semver.comparision : compare;
		return compare(this, other);
	}

	size_t toHash() const nothrow @nogc pure {
		import std.algorithm.iteration : each;
		size_t hash = this.major.hashOf();
		hash = this.minor.hashOf(hash);
		hash = this.patch.hashOf(hash);
		this.preRelease.each!(it => hash = it.hashOf(hash));
		this.buildIdentifier.each!(it => hash = it.hashOf(hash));
		return hash;
	}

	@property SemVer dup() const pure {
		auto ret = SemVer(this.major, this.minor, this.patch,
				this.preRelease.dup(), this.buildIdentifier.dup());
		return ret;
	}

	static SemVer max() pure {
		return SemVer(uint.max, uint.max, uint.max);
	}

	static SemVer min() pure {
		return SemVer(uint.min, uint.min, uint.min);
	}

	string toString() const @safe pure {
		import std.array : appender, empty;
		import std.format : format;
		string ret = format("%s.%s.%s", this.major, this.minor, this.patch);
		if(!this.preRelease.empty) {
			ret ~= format("-%-(%s.%)", this.preRelease);
		}
		if(!this.buildIdentifier.empty) {
			ret ~= format("+%-(%s.%)", this.preRelease);
		}
		return ret;
	}
}

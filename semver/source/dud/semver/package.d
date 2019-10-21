module dud.semver;

/**
	Represents a version in semantic version format, or a branch identifier.

	This can either have the form "~master", where "master" is a branch name,
	or the form "major.update.bugfix-prerelease+buildmetadata" (see the
	Semantic Versioning Specification v2.0.0 at http://semver.org/).
*/
struct SemVer {
@safe pure:
	import dud.semver.operations;
	public {
		static immutable MAX_VERS = "99999.0.0";
		static immutable UNKNOWN_VERS = "unknown";
		static immutable masterString = "~master";
		enum branchPrefix = '~';

		static immutable SemVer minRelease = SemVer("0.0.0");
		static immutable SemVer maxRelease = SemVer(MAX_VERS);
		static immutable SemVer masterBranch = SemVer(masterString);
		static immutable SemVer unknown = SemVer(UNKNOWN_VERS);
	}

	string m_version;

	/** Constructs a new `SemVer` from its string representation.
	*/
	this(string vers)
	{
		import std.exception : enforce;
		enforce(vers.length > 1, "SemVer strings must not be empty.");
		if (vers[0] != branchPrefix && vers.ptr !is UNKNOWN_VERS.ptr)
			enforce(vers.isValidVersion(), "Invalid SemVer format: " ~ vers);
		m_version = vers;
	}

	/** Constructs a new `SemVer` from its string representation.

		This method is equivalent to calling the constructor and is used as an
		endpoint for the serialization framework.
	*/
	static SemVer fromString(string vers) { return SemVer(vers); }

	bool opEquals(const SemVer oth) const { return opCmp(oth) == 0; }

	/// Tests if this represents a branch instead of a version.
	@property bool isBranch() const { return m_version.length > 0 && m_version[0] == branchPrefix; }

	/// Tests if this represents the master branch "~master".
	@property bool isMaster() const { return m_version == masterString; }

	/** Tests if this represents a pre-release version.

		Note that branches are always considered pre-release versions.
	*/
	@property bool isPreRelease() const {
		if (isBranch) return true;
		return isPreReleaseVersion(m_version);
	}

	/// Tests if this represents the special unknown version constant.
	@property bool isUnknown() const { return m_version == UNKNOWN_VERS; }

	/** Compares two versions/branches for precedence.

		SemVers generally have precedence over branches and the master branch
		has precedence over other branches. Apart from that, versions are
		compared using SemVer semantics, while branches are compared
		lexicographically.
	*/
	int opCmp(ref const SemVer other) const {
		import std.format : format;
		if (isUnknown || other.isUnknown) {
			throw new Exception("Can't compare unknown versions! (this: %s, other: %s)".format(this, other));
		}
		if (isBranch || other.isBranch) {
			if(m_version == other.m_version) return 0;
			if (!isBranch) return 1;
			else if (!other.isBranch) return -1;
			if (isMaster) return 1;
			else if (other.isMaster) return -1;
			return this.m_version < other.m_version ? -1 : 1;
		}

		return compareVersions(m_version, other.m_version);
	}
	/// ditto
	int opCmp(in SemVer other) const { return opCmp(other); }

	/// Returns the string representation of the version/branch.
	string toString() const { return m_version; }
}

unittest {
	import std.exception : assertNotThrown, assertThrown;
	SemVer a; 
	SemVer b;

	assertNotThrown(a = SemVer("1.0.0"), "Constructing SemVer('1.0.0') failed");
	assert(!a.isBranch, "Error: '1.0.0' treated as branch");
	assert(a == a, "a == a failed");

	assertNotThrown(a = SemVer(SemVer.masterString), "Constructing SemVer("~SemVer.masterString~"') failed");
	assert(a.isBranch, "Error: '"~SemVer.masterString~"' treated as branch");
	assert(a.isMaster);
	assert(a == SemVer.masterBranch, "Constructed master version != default master version.");

	assertNotThrown(a = SemVer("~BRANCH"), "Construction of branch SemVer failed.");
	assert(a.isBranch, "Error: '~BRANCH' not treated as branch'");
	assert(!a.isMaster);
	assert(a == a, "a == a with branch failed");

	// opCmp
	a = SemVer("1.0.0");
	b = SemVer("1.0.0");
	assert(a == b, "a == b with a:'1.0.0', b:'1.0.0' failed");
	b = SemVer("2.0.0");
	assert(a != b, "a != b with a:'1.0.0', b:'2.0.0' failed");
	a = SemVer.masterBranch;
	b = SemVer("~BRANCH");
	assert(a != b, "a != b with a:MASTER, b:'~branch' failed");
	assert(a > b);
	assert(a < SemVer("0.0.0"));
	assert(b < SemVer("0.0.0"));
	assert(a > SemVer("~Z"));
	assert(b < SemVer("~Z"));

	// SemVer 2.0.0-rc.2
	a = SemVer("2.0.0-rc.2");
	b = SemVer("2.0.0-rc.3");
	assert(a < b, "Failed: 2.0.0-rc.2 < 2.0.0-rc.3");

	a = SemVer("2.0.0-rc.2+build-metadata");
	b = SemVer("2.0.0+build-metadata");
	assert(a < b, "Failed: "~a.toString()~"<"~b.toString());

	// 1.0.0-alpha < 1.0.0-alpha.1 < 1.0.0-beta.2 < 1.0.0-beta.11 < 1.0.0-rc.1 < 1.0.0
	SemVer[] versions;
	versions ~= SemVer("1.0.0-alpha");
	versions ~= SemVer("1.0.0-alpha.1");
	versions ~= SemVer("1.0.0-beta.2");
	versions ~= SemVer("1.0.0-beta.11");
	versions ~= SemVer("1.0.0-rc.1");
	versions ~= SemVer("1.0.0");
	for(int i=1; i<versions.length; ++i)
		for(int j=i-1; j>=0; --j)
			assert(versions[j] < versions[i], "Failed: " ~ versions[j].toString() ~ "<" ~ versions[i].toString());

	a = SemVer.unknown;
	b = SemVer.minRelease;
	assertThrown(a == b, "Failed: compared " ~ a.toString() ~ " with " ~ b.toString() ~ "");

	a = SemVer.unknown;
	b = SemVer.unknown;
	assertThrown(a == b, "Failed: UNKNOWN == UNKNOWN");

	assert(SemVer("1.0.0+a") == SemVer("1.0.0+b"));
}

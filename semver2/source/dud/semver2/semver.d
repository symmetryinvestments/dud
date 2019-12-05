module dud.semver2.semver;

@safe:

struct SemVer {
	uint major;
	uint minor;
	uint patch;

	string[] preRelease;
	string[] buildIdentifier;
}

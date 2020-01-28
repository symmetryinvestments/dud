module dud.resolve.term;

import std.exception : enforce;

import dud.semver.versionrange;
import dud.pkgdescription;
import dud.resolve.versionconfiguration;
import dud.resolve.positive;

@safe:
struct Term {
	const VersionConfiguration constraint;
	const PackageDescription pkg;
	const IsPositive isPositive;
}

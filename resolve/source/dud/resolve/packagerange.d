module dud.resolver.packagerange;

import dud.pkgdescription;
import dud.resolve.versionconfiguration;

struct PackageRange {
	const VersionConfiguration constraint;
	const PackageDescription pkg;
}

module dud.resolver.packagerange;

import dud.pkgdescription;
import dud.resolver.versionconfiguration;

struct PackageRange {
	const VersionConfiguration constraint;
	const PackageDescription pkg;
}

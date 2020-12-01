module dud.resolve.packagerange;

__EOF__

import dud.pkgdescription;
import dud.resolve.versionconfiguration;

struct PackageRange {
	const VersionConfiguration constraint;
	const PackageDescription pkg;
}

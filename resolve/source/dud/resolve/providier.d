module dud.resolve.providier;

import dud.pkgdescription : PackageDescription;
import dud.pkgdescription.versionspecifier : VersionSpecifier;

interface PackageProvidier {
	const(PackageDescription)[] getPackage(string name,
			const(VersionSpecifier) verRange);
}

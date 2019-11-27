module dud.resolve.versionconfiguration;

import dud.pkgdescription.versionspecifier;
import dud.resolve.setrelation;

struct VersionConfiguration {
	const VersionSpecifier ver;
	const string conf;
}

/** Return if a is a subset of b, or if a and b are disjoint, or
if a and b overlap
*/
SetRelation relation(const(VersionConfiguration) a,
		const(VersionConfiguration) b)
{
	const bool conf = (a.conf.empty && !b.conf.empty)
			|| (a.conf.empty && b.conf.empty)
		? true
		: a.conf == b.conf;
}

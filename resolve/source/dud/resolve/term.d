module dud.resolve.term;

import dud.resolve.versionconfiguration;
import dud.pkgdescription;

@safe:
struct Term {
	const bool isPositive;
	const VersionConfiguration constraint;
	const PackageDescription pkg;

	bool satisfies(ref const(Term) other) const {
		if(this.pkg.name != other.pkg.name) {
			return false;
		}
	}

	SetRelation relation(ref const(Term) other) const {
		enforce(this.pkg.name == other.pkg.name);

		const SetRelation sr = dud.resolve.versionconfiguration
				.relation(this.constraint, other.versionconfiguration);
		if(this.isPositive) {
			if(other.isPositive) {
				return sr;
			} else {
			}
		} else {
			if(other.isPositive) {
			} else {
			}
		}
	}
}

Term inverse(const Term old) {
	return Term(!old.isPositive, old.constraint, old.pkg);
}


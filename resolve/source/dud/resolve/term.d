module dud.resolve.term;

import std.exception : enforce;

import dud.semver.versionrange;
import dud.pkgdescription;
import dud.resolve.versionconfiguration;

@safe:
struct Term {
	const bool isPositive;
	const VersionConfiguration constraint;
	const PackageDescription pkg;

	bool satisfies(ref const(Term) other) const {
		if(this.pkg.name != other.pkg.name) {
			return false;
		}

		return true;
	}

	SetRelation relation(ref const(Term) other) const {
		enforce(this.pkg.name == other.pkg.name);

		const SetRelation sr = dud.resolve.versionconfiguration
				.relation(this.constraint, other.constraint);
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

		assert(false);
	}
}

Term inverse(const Term old) {
	return Term(!old.isPositive, old.constraint, old.pkg);
}


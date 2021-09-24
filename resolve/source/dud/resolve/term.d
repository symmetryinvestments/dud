module dud.resolve.term;

import std.array : empty;
import std.exception : enforce;
import std.typecons : Nullable, nullable, Flag;
debug import std.stdio;

import dud.pkgdescription;
import dud.semver.versionrange : SetRelation;
import dud.resolve.versionconfigurationtoolchain : invert
	   , VersionConfigurationToolchain;
import dud.resolve.providier;
import dud.resolve.positive;
import dud.resolve.conf;
import dud.resolve.confs;

alias IsRootPackage = Flag!"IsRootPackage";

@safe pure:
struct Term {
@safe pure:
	VersionConfigurationToolchain constraint;
	PackageDescriptionVersionRange pkg;

	/// is only an indicator `contraint` is used to store both stats
	IsPositive isPositive;
	IsRootPackage isRootPackage;

	string toString() const {
		import std.format : format;
		return format("Term(%s, %s, %s, %s)", this.pkg.pkg.name
				, this.isRootPackage, this.isPositive, this.constraint);
	}

	bool opEquals()(auto ref const(Term) other) const {
		return this.isPositive == other.isPositive
			&& this.isRootPackage == other.isRootPackage
			&& this.constraint == other.constraint
			&& this.pkg == other.pkg;
	}
}

Term invert(const(Term) t) {
	VersionConfigurationToolchain vc = t.constraint.invert();
	return Term(vc, t.pkg.dup(), cast(IsPositive)!t.isPositive);
}

bool satisfies(const(Term) that, const(Term) other) {
	return that.pkg.pkg.name == other.pkg.pkg.name
		&& relation(other, that) == SetRelation.subset;
}

SetRelation relation(const(Term) that, const(Term) other) {
	static import dud.resolve.versionconfigurationtoolchain;

	enforce(that.pkg.pkg.name == other.pkg.pkg.name);

	debug writefln("that: %3s other: %3s", that.isPositive, other.isPositive);
	const(Term) that2 = that.isPositive
		? that
		: that.invert();

	const(Term) other2 = other.isPositive
		? other
		: other.invert();

	return dud.resolve.versionconfigurationtoolchain.relation(that2.constraint
			, other2.constraint);
}

Nullable!(Term) intersectionOf(const(Term) a, const(Term) b) {
	static import dud.resolve.versionconfigurationtoolchain;

	const(VersionConfigurationToolchain) a2 = a.isPositive
		? a.constraint
		: invert(a.constraint);

	const(VersionConfigurationToolchain) b2 = b.isPositive
		? b.constraint
		: invert(b.constraint);

	Nullable!(VersionConfigurationToolchain) r = dud.resolve
		.versionconfigurationtoolchain
		.intersectionOf(a2, b2);

	return r.isNull()
		? Nullable!(Term).init
		: nullable(Term(r.get(), a.pkg.dup(), IsPositive.yes));
}

module dud.descriptiongetter.store;

import std.algorithm.iteration : filter, uniq;
import std.algorithm.sorting : sort;
import std.array : array;
import std.format : format;
import std.typecons : Nullable, nullable;
import std.stdio;

import dud.pkgdescription;
import dud.semver.semver : SemVer;
import dud.semver.parse : parseSemVer;

@safe:

class Getter {
	PackageDescription[][string] packages;

	bool insert(PackageDescription pkg) {
		PackageDescription[]* byName = pkg.name in this.packages;
		if(byName is null) {
			this.packages[pkg.name] = [pkg];
			return true;
		} else {
			const oldSize = byName.length;
			(*byName) ~= pkg;
			(*byName) = (*byName).sort!greater().uniq().array();
			return oldSize != byName.length;
		}
	}

	Nullable!(PackageDescription) get(string pkgName
			, const SemVer lessThan = SemVer.MaxRelease)
	{
		PackageDescription[]* vers = pkgName in this.packages;
		if(vers !is null) {
			auto filtered = (*vers).filter!(p => p.version_ < lessThan);
			return filtered.empty
				? Nullable!(PackageDescription).init
				: nullable(filtered.front);
		}
		return Nullable!(PackageDescription).init;
	}
}

private bool greater(const(PackageDescription) a, const(PackageDescription) b)
		pure
{
	return a.version_ > b.version_;
}

unittest {
	auto g = new Getter();

	PackageDescription a;
	a.name = "Foo";
	a.version_ = parseSemVer("1.0.0");

	assert(g.insert(a));
	assert(!g.insert(a), () @trusted { return format("%s", g.packages); }() );
}

unittest {
	auto g = new Getter();

	PackageDescription a;
	a.name = "Foo";
	a.version_ = parseSemVer("1.0.0");

	PackageDescription b;
	b.name = "Foo";
	b.version_ = parseSemVer("1.1.0");

	assert(g.insert(a));
	assert(g.insert(b));

	assert(g.get("Bar").isNull());
	assert(!g.get("Foo").isNull());
	assert(!g.get("Foo", SemVer(1,1,0)).isNull());
	assert(g.get("Foo", SemVer(1,0,0)).isNull());
}

module dud.resolve.conf;

import std.array : empty;
import std.typecons : Flag;

@safe pure:

alias Not = Flag!"Not";

struct Conf {
@safe pure:
	/// empty means wildcard
	string conf;
	/// true means the inverse of the `conf` inverse of `conf.empty`
	/// still means wildcard
	Not not;

	this(string s) {
		this(s, Not.no);
	}

	this(string s, Not b) {
		this.conf = s;
		this.not = b;
	}
}

Conf invert(const(Conf) c) {
	return c.conf.empty
		? Conf("", Not.no)
		: Conf(c.conf, cast(Not)!c.not);
}

bool allowsAny(const(Conf) a, const(Conf) b) {
	return a.not == b.not
		? a.conf == b.conf
		: a.conf != b.conf;
}

bool allowsAll(const(Conf) a, const(Conf) b) {
	return a.not == b.not && a.conf == b.conf;
}

unittest {
	const c1 = Conf("foo", Not.no);
	const c2 = Conf("bar", Not.no);

	assert( allowsAny(c1, c1));
	assert( allowsAll(c1, c1));
	assert(!allowsAny(c1, c2));
	assert(!allowsAll(c1, c2));
	assert(!allowsAny(c2, c1));
	assert(!allowsAll(c2, c1));
}

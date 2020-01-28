module dud.resolve.conf;

import std.array : empty;
import std.typecons : Flag;
import std.format : format;

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
	if(a.not == Not.yes && a.conf.empty) {
		return false;
	}

	if(b.not == Not.yes && b.conf.empty) {
		return false;
	}

	if(a.not == Not.no && a.conf.empty) {
		return true;
	}

	if(b.not == Not.no && b.conf.empty) {
		return true;
	}

	return a.not == Not.no && b.not == Not.no
		? a.conf == b.conf
		: a.not != b.not
			? a.conf != b.conf
			: true;
}

bool allowsAll(const(Conf) a, const(Conf) b) {
	return a.not == Not.no && a.conf.empty
		? true
		: a.not == Not.yes && a.conf.empty
			? false
			: a.not == b.not && a.conf == b.conf;
}

private {
	const c1 = Conf("foo", Not.no);
	const c2 = Conf("foo", Not.yes);
	const c3 = Conf("bar", Not.no);
	const c4 = Conf("bar", Not.yes);
	const c5 = Conf("", Not.no);
	const c6 = Conf("", Not.yes);
}

//
// invert
//

unittest {
	assert(invert(c1) == c2);
	assert(invert(c2) == c1);
	assert(invert(c3) == c4);
	assert(invert(c4) == c3);
	assert(invert(c5) == c5);
	assert(invert(c6) == c5);
}

//
// allowsAny
//

unittest {
	assert( allowsAny(c1, c1));
	assert(!allowsAny(c1, c2));
	assert(!allowsAny(c1, c3));
	assert( allowsAny(c1, c4));
	assert( allowsAny(c1, c5));
	assert(!allowsAny(c1, c6));

	assert(!allowsAny(c2, c1));
	assert( allowsAny(c2, c2));
	assert( allowsAny(c2, c3));
	assert( allowsAny(c2, c4));
	assert( allowsAny(c2, c5));
	assert(!allowsAny(c2, c6));

	assert(!allowsAny(c3, c1));
	assert( allowsAny(c3, c2));
	assert( allowsAny(c3, c3));
	assert(!allowsAny(c3, c4));
	assert( allowsAny(c3, c5));
	assert(!allowsAny(c3, c6));

	assert( allowsAny(c4, c1));
	assert( allowsAny(c4, c2));
	assert(!allowsAny(c4, c3));
	assert( allowsAny(c4, c4));
	assert( allowsAny(c4, c5));
	assert(!allowsAny(c4, c6));

	assert( allowsAny(c5, c1));
	assert( allowsAny(c5, c2));
	assert( allowsAny(c5, c3));
	assert( allowsAny(c5, c4));
	assert( allowsAny(c5, c5));
	assert(!allowsAny(c5, c6));

	assert(!allowsAny(c6, c1));
	assert(!allowsAny(c6, c2));
	assert(!allowsAny(c6, c3));
	assert(!allowsAny(c6, c4));
	assert(!allowsAny(c6, c5));
	assert(!allowsAny(c6, c6));
}

//
// allowsAll
//

unittest {
	assert( allowsAll(c1, c1));
	assert(!allowsAll(c1, c2));
	assert(!allowsAll(c1, c3));
	assert(!allowsAll(c1, c4));
	assert(!allowsAll(c1, c5));
	assert(!allowsAll(c1, c6));

	assert(!allowsAll(c2, c1));
	assert( allowsAll(c2, c2));
	assert(!allowsAll(c2, c3));
	assert(!allowsAll(c2, c4));
	assert(!allowsAll(c2, c5));
	assert(!allowsAll(c2, c6));

	assert(!allowsAll(c3, c1));
	assert(!allowsAll(c3, c2));
	assert( allowsAll(c3, c3));
	assert(!allowsAll(c3, c4));
	assert(!allowsAll(c3, c5));
	assert(!allowsAll(c3, c6));

	assert(!allowsAll(c4, c1));
	assert(!allowsAll(c4, c2));
	assert(!allowsAll(c4, c3));
	assert( allowsAll(c4, c4));
	assert(!allowsAll(c4, c5));
	assert(!allowsAll(c4, c6));

	assert( allowsAll(c5, c1));
	assert( allowsAll(c5, c2));
	assert( allowsAll(c5, c3));
	assert( allowsAll(c5, c4));
	assert( allowsAll(c5, c5));
	assert( allowsAll(c5, c6));

	assert(!allowsAll(c6, c1));
	assert(!allowsAll(c6, c2));
	assert(!allowsAll(c6, c3));
	assert(!allowsAll(c6, c4));
	assert(!allowsAll(c6, c5));
	assert(!allowsAll(c6, c6));
}

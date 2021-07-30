module dud.resolve.confstests;

import core.exception : AssertError;
import std.algorithm.iteration : map, joiner, filter;
import std.algorithm.searching : canFind;
import std.exception : enforce;
import std.format : format;
import std.stdio;

import dud.resolve.conf;
import dud.resolve.confs;
import dud.resolve.positive;
import dud.semver.versionrange;

private:

const c1 = Conf("foo", IsPositive.yes);
const c2 = Conf("foo", IsPositive.no);
const c3 = Conf("bar", IsPositive.yes);
const c4 = Conf("bar", IsPositive.no);
const c5 = Conf("", IsPositive.yes);
const c6 = Conf("", IsPositive.no);
const c7 = Conf("conf1", IsPositive.yes);

const(Confs) c12 = Confs([c1, c2]);
const(Confs) c13 = Confs([c1, c3]);
const(Confs) c14 = Confs([c1, c4]);
const(Confs) c15 = Confs([c1, c5]);
const(Confs) c16 = Confs([c1, c6]);

const(Confs) c23 = Confs([c2, c3]);
const(Confs) c24 = Confs([c2, c4]);
const(Confs) c25 = Confs([c2, c5]);
const(Confs) c26 = Confs([c2, c6]);

const(Confs) c34 = Confs([c3, c4]);
const(Confs) c35 = Confs([c3, c5]);
const(Confs) c36 = Confs([c3, c6]);

const(Confs) c45 = Confs([c4, c5]);
const(Confs) c46 = Confs([c4, c6]);

const(Confs) c56 = Confs([c5, c6]);

Confs[] cs;

static this() {
	cs = buildConfs();
}

unittest {
	auto a = Confs([c5]);
	auto b = Confs([c1]);

	assert(allowsAny(c5, c1), format("\n%s\n%s", c5, c6));
	testAllowAny(a, b, true);
}

Confs[] buildConfs() {
	Confs[] ret;
	const cs = [c1, c2, c3, c4, c5, c6];
	foreach(it; cs) {
		foreach(jt; cs) {
			foreach(kt; cs) {
				auto tmp = Confs([it, jt, kt]);
				if(tmp == Confs.init) {
					continue;
				}
				Confs d = tmp.dup();
				assert(d == tmp, format("\nold: %s\nnew: %s", tmp, d));
				ret ~= tmp;
			}
		}
	}
	return ret;
}

// invert

unittest {
	void testInvert(const(Confs) a, const(Confs) exp, int line = __LINE__) {
		const inv = a.invert();
		enforce!AssertError(inv == exp, format("\n  a: %s\nexp: %s\nrst: %s", a,
				exp, inv), __FILE__, line);
	}

	testInvert(c12, Confs([]));
	testInvert(c13, c24);
	testInvert(c14, c23);
	testInvert(c15, Confs([c6])); // c5 is special
	testInvert(c16, Confs([c5])); // c6 makes everything false

	testInvert(c23, c14);
	testInvert(c24, c13);
	testInvert(c25, Confs([c6]));
	testInvert(c26, Confs([c5]));

	testInvert(c34, Confs([]));
	testInvert(c35, Confs([c6]));
	testInvert(c36, Confs([c5]));

	testInvert(c45, Confs([c6]));
	testInvert(c46, Confs([c5]));

	testInvert(c56, Confs([c5]));
}

unittest {
	const c = Confs([c1]).invert();
	const e = Confs([c2]);
	assert(c == e, format("\n%s\n%s", c, e));
}

// allowAll

unittest {
	void testAllowAll(const(Confs) a, const(Confs) b, const bool exp,
			int line = __LINE__)
	{
		struct Indivitual {
			@safe pure:
			const(Conf) a;
			const(Conf) b;

			string toString() const {
				return format("\ta: %s\tb: %s\t%s", a, b, allowsAll(a, b));
			}
		}

		const bool rslt = allowsAll(a, b);
		enforce!AssertError(rslt == exp,
			format("\na: %s\nb: %s\nexp: %s\nrsl: %s\nall:\n%(%s\n%)", a, b,
				exp,
				rslt,
				a.confs
					.map!(it => b.confs.map!(jt => Indivitual(it, jt)))
					.joiner),
			__FILE__, line);
	}

	testAllowAll(Confs.init, Confs.init, true);
	testAllowAll(Confs([c1, c5]), Confs([c1]), true);
	testAllowAll(Confs([c5]), Confs([c1, c5]), true);
	testAllowAll(Confs([c5]), Confs([c1, c3]), true);
	testAllowAll(Confs([c1]), Confs([c1, c3, c5]), true);
	testAllowAll(Confs([c3]), Confs([c1, c3, c5]), true);
	testAllowAll(Confs([c3]), Confs([c3]), true);
	testAllowAll(Confs([c1]), Confs([c1]), true);
	testAllowAll(Confs([c2]), Confs([c2]), false);
	testAllowAll(Confs([c2]), Confs([c1]), false);
	testAllowAll(Confs([c2]), Confs([c3]), false);
	testAllowAll(Confs([c2]), Confs([c4]), false);
	testAllowAll(Confs([c2]), Confs([c5]), true);
	testAllowAll(Confs([c2]), Confs([c6]), false);

	foreach(it; cs) {
		testAllowAll(Confs.init, it, false);
		foreach(jt; cs) {
			allowsAll(it, jt);
		}
	}
}

unittest {
	void testAllowAll(const(Confs) a, const(Conf) b, const bool exp,
			int line = __LINE__)
	{
		struct Indivitual {
			@safe pure:
			const(Conf) a;
			const(Conf) b;

			string toString() const {
				return format("\ta: %s\tb: %s\t%s", a, b, allowsAll(a, b));
			}
		}

		const bool rslt = allowsAll(a, b);
		enforce!AssertError(rslt == exp,
			format("\na: %s\nb: %s\nexp: %s\nrsl: %s\nall:\n%(%s\n%)", a, b, exp,
				rslt, a.confs.map!(it => Indivitual(it, b))),
			__FILE__, line);
	}

	testAllowAll(c12, c1, false);
	testAllowAll(c12, c2, false);
	testAllowAll(c12, c3, false);
	testAllowAll(c12, c4, false);
	testAllowAll(c12, c5, false);
	testAllowAll(c12, c6, false);

	testAllowAll(c13, c1, true);
	testAllowAll(c13, c2, false);
	testAllowAll(c13, c3, true);
	testAllowAll(c13, c4, false);
	testAllowAll(c13, c5, false);
	testAllowAll(c13, c6, false);

	testAllowAll(c24, c1, false);
	testAllowAll(c24, c2, false);
	testAllowAll(c24, c3, false);
	testAllowAll(c24, c4, false);
	testAllowAll(c24, c5, false);
	testAllowAll(c24, c6, false);

	const(Confs) c22 = Confs([c2, c2]);
	testAllowAll(c22, c2, false);
}

// allowsAny
struct IndivitualAny {
	@safe pure:
	const(Conf) a;
	const(Conf) b;

	string toString() const {
		return format("\ta: %s\tb: %s\t%s", a, b, allowsAny(a, b));
	}
}

void testAllowAny(const(Confs) a, const(Conf) b, const bool exp,
		int line = __LINE__)
{
	const rsl = allowsAny(a, b);
	enforce!AssertError(rsl == exp, format(
			"\na: %s\nb: %s\nint: %s\nexp: %s\neach:%(%s\n%)", a, b, rsl, exp,
			a.confs
				.map!(aIt => IndivitualAny(aIt, b))),
			__FILE__, line);
}

unittest {
	testAllowAny(c13, c1, true);
	testAllowAny(c13, c3, true);
	testAllowAny(c13, c5, true);
	testAllowAny(c12, c5, false);
}

void testAllowAny(const(Confs) a, const(Confs) b, const bool exp,
		int line = __LINE__)
{
	const rsl = allowsAny(a, b);
	enforce!AssertError(rsl == exp, format(
			"\na: %s\nb: %s\nint: %s\nexp: %s\neach:%(%s\n%)", a, b, rsl, exp,
			a.confs
				.map!(aIt => b.confs.map!(bIt => IndivitualAny(aIt, bIt)))
				.joiner),
			__FILE__, line);
}

unittest {
	testAllowAny(c12, c12, true);
	testAllowAny(c12, c13, false);
	testAllowAny(c12, c14, false);
	testAllowAny(c12, c15, false);
	testAllowAny(c12, c16, false);

	testAllowAny(c13, c14, true);
}

unittest {
	foreach(it; cs) {
		foreach(c; it.confs.filter!(it => it.isPositive == IsPositive.yes)) {
			testAllowAny(it, c, true);
		}
	}
}

// intersectionOf

void testInter(const(Conf) a, const(Conf) b, const(Confs) exp,
		int line = __LINE__)
{
	const inter = intersectionOf(a, b);
	enforce!AssertError(inter == exp, format(
			"\na: %s\nb: %s\nint: %s\nexp: %s", a, b, inter, exp),
			__FILE__, line);
}

unittest {
	testInter(c7, c6, Confs([c6]));
}

void testInter(const(Confs) a, const(Confs) b, const(Confs) exp,
		int line = __LINE__)
{
	const inter = intersectionOf(a, b);
	enforce!AssertError(inter == exp, format(
			"\na: %s\nb: %s\nint: %s\nexp: %s", a, b, inter, exp),
			__FILE__, line);
}

unittest {
	testInter(Confs([c1, c3]), Confs([c1]), Confs([c1]));
	testInter(Confs([c1]), Confs([c1]), Confs([c1]));
	testInter(Confs([c3]), Confs([c1]), Confs([]));
}

unittest {
	testInter(c13, c13, c13);
	testInter(c13, c35, Confs([c1, c3]));
	testInter(c35, c35, Confs([c3, c5]));
	testInter(c56, c56, Confs([c6]));

	Confs a = Confs([c1, c3]);
	Confs b = Confs([c1, c3, c5]);

	testInter(a, b, a);
}

unittest {
	const a = Confs([c1]);
	const b = Confs([c3]);

	testInter(a, b, Confs([]));
}

// differenceOf

unittest {
	const c11 = Confs([c1]);
	const c33 = Confs([c3]);
	const c13 = differenceOf(c11, c33);
}

unittest {
	const none = Confs([Conf("", IsPositive.no)]);
	foreach(it; cs) {
		foreach(jt; cs) {
			const r = differenceOf(it, jt);
			if(it == jt && it != none) {
				allowsAny(r, it);
				allowsAny(r, jt);
			}
		}
	}
}

// additional

unittest {
	auto a = Confs([Conf("", IsPositive.no)]);
	auto b = Confs([]);

	assert(allowsAll(a, b));
	assert(allowsAny(a, b));
}

module dud.pkgdescription.testhelper;

package void unRollException(Exception e, string f) {
	import std.stdio : writefln;

	Throwable en = e;
	writefln("%s", f);
	while(en.next !is null) {
		en = en.next;
	}
	writefln("excp %s", en.msg);
}

module dud.pkgdescription.udas;

import std.format : format;

import dud.pkgdescription;

@safe pure:

struct SDL(alias In, alias Out) {
@safe pure:
	string name;

	this(string name) @nogc nothrow @safe pure {
		this.name = name;
	}
}

struct JSON(alias In, alias Out) {
@safe pure:
	string name;

	this(string name) @nogc nothrow @safe pure {
		this.name = name;
	}
}

mixin(buildGetName("JSON"));
mixin(buildGetName("SDL"));

@safe pure unittest {
	static assert(SDLName!"ddoxFilterArgs" == "x:ddoxFilterArgs",
			SDLName!"ddoxFilterArgs");
}

private string buildGetName(string type) {
	return q{
template %1$sName(string key) {
	enum attr = __traits(getAttributes,
			__traits(getMember, PackageDescription, key));

	static if(attr.length == 1) {
		alias First = attr[0];
		alias FirstType = typeof(First);
		static if(is(FirstType : %1$s!Args, Args...)
				&& attr[0].name.length != 0)
		{
			enum %1$sName = attr[0].name;
		} else {
			enum %1$sName = key;
		}
	} else static if(attr.length == 2) {
		alias First = attr[0];
		alias FirstType = typeof(First);
		alias Second = attr[1];
		alias SecondType = typeof(Second);
		static if(is(FirstType : %1$s!Args1, Args1...)
				&& attr[0].name.length != 0)
		{
			enum %1$sName = attr[0].name;
		} else static if(is(SecondType == %1$s!Args2, Args2...)
				&& attr[1].name.length != 0)
		{
			enum %1$sName = attr[1].name;
		} else {
			enum %1$sName = key;
		}
	} else {
		enum %1$sName = key;
	}
}
}.format(type);
}

mixin(buildGetPut("JSON", "Get", 0));
mixin(buildGetPut("JSON", "Put", 1));
mixin(buildGetPut("SDL", "Get", 0));
mixin(buildGetPut("SDL", "Put", 1));

private string buildGetPut(string type, string op, size_t idx) {
	return q{
template %1$s%2$s(string key) {
	enum attr = __traits(getAttributes,
			__traits(getMember, PackageDescription, key));

	static if(attr.length == 1) {
		alias First = attr[0];
		alias FirstType = typeof(First);
		static if(is(FirstType : %1$s!Args, Args...)) {
			alias %1$s%2$s = Args[%3$u];
		} else {
			static assert(false, "No %1$s op %2$s alias found for \"" ~ key ~ "\"");
		}
	} else static if(attr.length == 2) {
		alias First = attr[0];
		alias FirstType = typeof(First);
		alias Second = attr[1];
		alias SecondType = typeof(Second);
		static if(is(FirstType : %1$s!Args, Args...)) {
			alias %1$s%2$s = Args[%3$u];
		} else static if(is(SecondType : %1$s!Args, Args...)) {
			alias %1$s%2$s = Args[%3$u];
		} else {
			static assert(false, "No %1$s op %2$s alias found for \"" ~ key ~ "\"");
		}
	} else {
		static assert(false, "No %1$s op %2$s alias found for \"" ~ key ~ "\"");
	}
}}.format(type, op, idx);
}

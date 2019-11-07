module dud.exception;

@safe pure:

class DudException : Exception {
	this(string msg, string file = __FILE__, size_t line = __LINE__,
			Throwable next = null) @safe pure nothrow @nogc
	{
		super(msg, file, line, next);
	}
}

string exceptionClassBuilder(string name, string superName) {
	import std.format : format;

	return q{
class %1$s : %2$s {
	this(string msg, string file = __FILE__, size_t line = __LINE__)
		@safe pure nothrow @nogc
	{
		super(msg, file, line);
	}

	this(string msg, string file = __FILE__, size_t line = __LINE__,
			Throwable next = null) @safe pure nothrow @nogc
	{
		super(msg, file, line, next);
	}
}
}.format(name, superName);
}

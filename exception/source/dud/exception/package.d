module dud.exception;

@safe pure:

class DudException : Exception {
	this(string msg, string file = __FILE__, size_t line = __LINE__,
			Throwable next = null) @safe pure nothrow @nogc
	{
		super(msg, file, line, next);
	}
}

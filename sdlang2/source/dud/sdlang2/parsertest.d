module dud.sdlang2.parsertest;

import dud.sdlang2.lexer;
import dud.sdlang2.parser;
import dud.sdlang2.ast;

@safe pure:
unittest {
	auto l = Lexer(`key "value"`);
	auto p = Parser(l);
	Root r = p.parseRoot();
}

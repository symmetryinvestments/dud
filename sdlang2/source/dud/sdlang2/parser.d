module dud.sdlang2.parser;

import std.typecons : RefCounted, refCounted;
import std.format : format;
import dud.sdlang2.ast;
import dud.sdlang2.tokenmodule;

import dud.sdlang2.lexer;

import dud.sdlang2.exception;

struct Parser {
@safe pure:

	import std.array : appender;

	import std.format : formattedWrite;

	Lexer lex;

	this(Lexer lex) {
		this.lex = lex;
	}

	bool firstRoot() const pure @nogc @safe {
		return this.firstTags()
			 || this.lex.front.type == TokenType.eof;
	}

	Root parseRoot() {
		try {
			return this.parseRootImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a Root an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	Root parseRootImpl() {
		string[] subRules;
		subRules = ["T"];
		if(this.firstTags()) {
			Tags tags = this.parseTags();
			subRules = ["T"];
			if(this.lex.front.type == TokenType.eof) {
				this.lex.popFront();

				return new Root(RootEnum.T
					, tags
				);
			}
			auto app = appender!string();
			formattedWrite(app, 
				"In 'Root' found a '%s' while looking for", 
				this.lex.front
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__,
				subRules,
				["eof"]
			);

		} else if(this.lex.front.type == TokenType.eof) {
			this.lex.popFront();

			return new Root(RootEnum.E
			);
		}
		auto app = appender!string();
		formattedWrite(app, 
			"In 'Root' found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["ident -> Tag","eof"]
		);

	}

	bool firstTags() const pure @nogc @safe {
		return this.firstTag();
	}

	Tags parseTags() {
		try {
			return this.parseTagsImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a Tags an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	Tags parseTagsImpl() {
		string[] subRules;
		subRules = ["Tag", "TagFollow"];
		if(this.firstTag()) {
			Tag tag = this.parseTag();
			subRules = ["TagFollow"];
			if(this.firstTags()) {
				Tags follow = this.parseTags();

				return new Tags(TagsEnum.TagFollow
					, tag
					, follow
				);
			}
			return new Tags(TagsEnum.Tag
				, tag
			);
		}
		auto app = appender!string();
		formattedWrite(app, 
			"In 'Tags' found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["ident -> IDFull"]
		);

	}

	bool firstTag() const pure @nogc @safe {
		return this.firstIDFull();
	}

	Tag parseTag() {
		try {
			return this.parseTagImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a Tag an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	Tag parseTagImpl() {
		string[] subRules;
		subRules = ["A", "AO", "AOT", "AT", "E", "ET", "O", "OT", "V", "VA", "VAO", "VAOT", "VAT", "VO", "VOT", "VT"];
		if(this.firstIDFull()) {
			IDFull id = this.parseIDFull();
			subRules = ["V", "VA", "VAO", "VAOT", "VAT", "VO", "VOT", "VT"];
			if(this.firstValues()) {
				Values vals = this.parseValues();
				subRules = ["VA", "VAO", "VAOT", "VAT"];
				if(this.firstAttributes()) {
					Attributes attrs = this.parseAttributes();
					subRules = ["VAO", "VAOT"];
					if(this.firstOptChild()) {
						OptChild oc = this.parseOptChild();
						subRules = ["VAOT"];
						if(this.firstTagTerminator()) {
							this.parseTagTerminator();

							return new Tag(TagEnum.VAOT
								, id
								, vals
								, attrs
								, oc
							);
						}
						return new Tag(TagEnum.VAO
							, id
							, vals
							, attrs
							, oc
						);
					} else if(this.firstTagTerminator()) {
						this.parseTagTerminator();

						return new Tag(TagEnum.VAT
							, id
							, vals
							, attrs
						);
					}
					return new Tag(TagEnum.VA
						, id
						, vals
						, attrs
					);
				} else if(this.firstOptChild()) {
					OptChild oc = this.parseOptChild();
					subRules = ["VOT"];
					if(this.firstTagTerminator()) {
						this.parseTagTerminator();

						return new Tag(TagEnum.VOT
							, id
							, vals
							, oc
						);
					}
					return new Tag(TagEnum.VO
						, id
						, vals
						, oc
					);
				} else if(this.firstTagTerminator()) {
					this.parseTagTerminator();

					return new Tag(TagEnum.VT
						, id
						, vals
					);
				}
				return new Tag(TagEnum.V
					, id
					, vals
				);
			} else if(this.firstAttributes()) {
				Attributes attrs = this.parseAttributes();
				subRules = ["AO", "AOT"];
				if(this.firstOptChild()) {
					OptChild oc = this.parseOptChild();
					subRules = ["AOT"];
					if(this.firstTagTerminator()) {
						this.parseTagTerminator();

						return new Tag(TagEnum.AOT
							, id
							, attrs
							, oc
						);
					}
					return new Tag(TagEnum.AO
						, id
						, attrs
						, oc
					);
				} else if(this.firstTagTerminator()) {
					this.parseTagTerminator();

					return new Tag(TagEnum.AT
						, id
						, attrs
					);
				}
				return new Tag(TagEnum.A
					, id
					, attrs
				);
			} else if(this.firstOptChild()) {
				OptChild oc = this.parseOptChild();
				subRules = ["OT"];
				if(this.firstTagTerminator()) {
					this.parseTagTerminator();

					return new Tag(TagEnum.OT
						, id
						, oc
					);
				}
				return new Tag(TagEnum.O
					, id
					, oc
				);
			} else if(this.firstTagTerminator()) {
				this.parseTagTerminator();

				return new Tag(TagEnum.ET
					, id
				);
			}
			return new Tag(TagEnum.E
				, id
			);
		}
		auto app = appender!string();
		formattedWrite(app, 
			"In 'Tag' found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["ident"]
		);

	}

	bool firstIDFull() const pure @nogc @safe {
		return this.lex.front.type == TokenType.ident;
	}

	IDFull parseIDFull() {
		try {
			return this.parseIDFullImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a IDFull an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	IDFull parseIDFullImpl() {
		string[] subRules;
		subRules = ["L", "S"];
		if(this.lex.front.type == TokenType.ident) {
			Token id = this.lex.front;
			this.lex.popFront();
			subRules = ["L"];
			if(this.firstIDSuffix()) {
				IDSuffix suff = this.parseIDSuffix();

				return new IDFull(IDFullEnum.L
					, id
					, suff
				);
			}
			return new IDFull(IDFullEnum.S
				, id
			);
		}
		auto app = appender!string();
		formattedWrite(app, 
			"In 'IDFull' found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["ident"]
		);

	}

	bool firstIDSuffix() const pure @nogc @safe {
		return this.lex.front.type == TokenType.colon;
	}

	IDSuffix parseIDSuffix() {
		try {
			return this.parseIDSuffixImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a IDSuffix an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	IDSuffix parseIDSuffixImpl() {
		string[] subRules;
		subRules = ["C", "F"];
		if(this.lex.front.type == TokenType.colon) {
			this.lex.popFront();
			subRules = ["C", "F"];
			if(this.lex.front.type == TokenType.ident) {
				Token id = this.lex.front;
				this.lex.popFront();
				subRules = ["F"];
				if(this.firstIDSuffix()) {
					IDSuffix follow = this.parseIDSuffix();

					return new IDSuffix(IDSuffixEnum.F
						, id
						, follow
					);
				}
				return new IDSuffix(IDSuffixEnum.C
					, id
				);
			}
			auto app = appender!string();
			formattedWrite(app, 
				"In 'IDSuffix' found a '%s' while looking for", 
				this.lex.front
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__,
				subRules,
				["ident"]
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"In 'IDSuffix' found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["colon"]
		);

	}

	bool firstValues() const pure @nogc @safe {
		return this.lex.front.type == TokenType.value;
	}

	Values parseValues() {
		try {
			return this.parseValuesImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a Values an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	Values parseValuesImpl() {
		string[] subRules;
		subRules = ["Value", "ValueFollow"];
		if(this.lex.front.type == TokenType.value) {
			Token value = this.lex.front;
			this.lex.popFront();
			subRules = ["ValueFollow"];
			if(this.firstValues()) {
				Values follow = this.parseValues();

				return new Values(ValuesEnum.ValueFollow
					, value
					, follow
				);
			}
			return new Values(ValuesEnum.Value
				, value
			);
		}
		auto app = appender!string();
		formattedWrite(app, 
			"In 'Values' found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["value"]
		);

	}

	bool firstAttributes() const pure @nogc @safe {
		return this.firstAttribute();
	}

	Attributes parseAttributes() {
		try {
			return this.parseAttributesImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a Attributes an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	Attributes parseAttributesImpl() {
		string[] subRules;
		subRules = ["Attribute", "AttributeFollow"];
		if(this.firstAttribute()) {
			Attribute attr = this.parseAttribute();
			subRules = ["AttributeFollow"];
			if(this.firstAttributes()) {
				Attributes follow = this.parseAttributes();

				return new Attributes(AttributesEnum.AttributeFollow
					, attr
					, follow
				);
			}
			return new Attributes(AttributesEnum.Attribute
				, attr
			);
		}
		auto app = appender!string();
		formattedWrite(app, 
			"In 'Attributes' found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["ident -> IDFull"]
		);

	}

	bool firstAttribute() const pure @nogc @safe {
		return this.firstIDFull();
	}

	Attribute parseAttribute() {
		try {
			return this.parseAttributeImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a Attribute an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	Attribute parseAttributeImpl() {
		string[] subRules;
		subRules = ["A"];
		if(this.firstIDFull()) {
			IDFull id = this.parseIDFull();
			subRules = ["A"];
			if(this.lex.front.type == TokenType.assign) {
				this.lex.popFront();
				subRules = ["A"];
				if(this.lex.front.type == TokenType.value) {
					Token value = this.lex.front;
					this.lex.popFront();

					return new Attribute(AttributeEnum.A
						, id
						, value
					);
				}
				auto app = appender!string();
				formattedWrite(app, 
					"In 'Attribute' found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["value"]
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"In 'Attribute' found a '%s' while looking for", 
				this.lex.front
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__,
				subRules,
				["assign"]
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"In 'Attribute' found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["ident"]
		);

	}

	bool firstOptChild() const pure @nogc @safe {
		return this.lex.front.type == TokenType.lcurly;
	}

	OptChild parseOptChild() {
		try {
			return this.parseOptChildImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a OptChild an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	OptChild parseOptChildImpl() {
		string[] subRules;
		subRules = ["C"];
		if(this.lex.front.type == TokenType.lcurly) {
			this.lex.popFront();
			subRules = ["C"];
			if(this.lex.front.type == TokenType.eol) {
				this.lex.popFront();
				subRules = ["C"];
				if(this.firstTags()) {
					Tags tags = this.parseTags();
					subRules = ["C"];
					if(this.lex.front.type == TokenType.rcurly) {
						this.lex.popFront();

						return new OptChild(OptChildEnum.C
							, tags
						);
					}
					auto app = appender!string();
					formattedWrite(app, 
						"In 'OptChild' found a '%s' while looking for", 
						this.lex.front
					);
					throw new ParseException(app.data,
						__FILE__, __LINE__,
						subRules,
						["rcurly"]
					);

				}
				auto app = appender!string();
				formattedWrite(app, 
					"In 'OptChild' found a '%s' while looking for", 
					this.lex.front
				);
				throw new ParseException(app.data,
					__FILE__, __LINE__,
					subRules,
					["ident -> Tag"]
				);

			}
			auto app = appender!string();
			formattedWrite(app, 
				"In 'OptChild' found a '%s' while looking for", 
				this.lex.front
			);
			throw new ParseException(app.data,
				__FILE__, __LINE__,
				subRules,
				["eol"]
			);

		}
		auto app = appender!string();
		formattedWrite(app, 
			"In 'OptChild' found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["lcurly"]
		);

	}

	bool firstTagTerminator() const pure @nogc @safe {
		return this.lex.front.type == TokenType.eol
			 || this.lex.front.type == TokenType.semicolon;
	}

	TagTerminator parseTagTerminator() {
		try {
			return this.parseTagTerminatorImpl();
		} catch(ParseException e) {
			throw new ParseException(
				"While parsing a TagTerminator an Exception was thrown.",
				e, __FILE__, __LINE__
			);
		}
	}

	TagTerminator parseTagTerminatorImpl() {
		string[] subRules;
		subRules = ["E"];
		if(this.lex.front.type == TokenType.eol) {
			this.lex.popFront();

			return new TagTerminator(TagTerminatorEnum.E
			);
		} else if(this.lex.front.type == TokenType.semicolon) {
			this.lex.popFront();

			return new TagTerminator(TagTerminatorEnum.S
			);
		}
		auto app = appender!string();
		formattedWrite(app, 
			"In 'TagTerminator' found a '%s' while looking for", 
			this.lex.front
		);
		throw new ParseException(app.data,
			__FILE__, __LINE__,
			subRules,
			["eol","semicolon"]
		);

	}

}

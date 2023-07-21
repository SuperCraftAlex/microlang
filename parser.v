module main

import strconv

struct PARSEOUT {
	mut:
	is_arr bool
	arr []&PARSEOUT

	is_norm bool = true
	typ string
	subtyp string
	val string
	val2 string

	is_stmt bool
	op string
	left &PARSEOUT = unsafe { nil }
	right &PARSEOUT = unsafe { nil }
	modifier string

	errors []ERRW
}

pub fn (s PARSEOUT) str() string {
	mut o := []string {}
	o << "{"

	if s.typ.len > 0 {
		o << "\"type\": \"${s.typ}\","
	}
	if s.subtyp.len > 0 {
		o << "\"subtype\": \"${s.subtyp}\","
	}
	if s.val.len > 0 {
		o << "\"value\": \"${s.val}\","
	}
	if s.val2.len > 0 {
		o << "\"value 2\": \"${s.val}\","
	}
	if s.arr.len > 0 {
		o << "\"array\": ["
		for e in s.arr {
			o << (*e).str() + ","
		}
		o << "],"
	}
	if s.op.len > 0 {
		o << "\"operation\": \"${s.op}\","
	}
	if s.left != unsafe { nil } {
		o << "\"left\": ${(*s.left).str()},"
	}
	if s.right != unsafe { nil } {
		o << "\"right\": ${(*s.right).str()},"
	}
	if s.modifier.len > 0 {
		o << "\"modifier\": \"${s.modifier}\","
	}

	o << "}"
	return o.join("")
}

fn parse(stmnt string) &PARSEOUT {
	a := stmnt.trim_space()
	b := a.before("\"").split("=")

	if b.len > 1 {
		d := b[0].trim_space()
		if d.contains(" ") {
			c := d.split(" ")
			x := parse_exp(d.all_after_first(" "))
			y := parse_exp(a.before("\"").all_after_first("="))
			return &PARSEOUT {
				is_stmt: true
				op: "variable creation"
				left: x
				right: y
				modifier: c[0]
			}
		}
		else {
			y := parse_exp(a.before("\"").all_after_first("="))
			if d.starts_with("+") {
				return &PARSEOUT {
					is_stmt: true
					op: "t_var"
					left: parse_exp(d[1..])
					right: y
				}
			}
			return &PARSEOUT {
				is_stmt: true
				op: "assignment"
				left: parse_exp(d)
				right: y
			}
		}
	}

	return parse_exp(stmnt)
}

fn parse_exp(exp string) &PARSEOUT {
	e := exp.trim_space()
	if e.len == 0 {
		return &PARSEOUT { is_norm: false }
	}

	if e.starts_with("[") {
		if !e.ends_with("]") {
			return &PARSEOUT {
				errors: [ERRW {
					name: "Unclosed brackets"
					desc: exp
				}]
			}
		}
		elems := e[1..(e.len-1)].split(",")
		mut elemv := []&PARSEOUT {cap: elems.len}
		mut errors := []ERRW {}
		for elm in elems {
			p := parse_exp(elm)
			elemv << p
			errors << p.errors
		}
		return &PARSEOUT {
			is_arr: true
			arr: elemv
			typ: "literal"
			subtyp: "array"
			val: ""
			errors: errors
		}
	}

	if e.ends_with("]") {
		if !e.contains("[") {
			return &PARSEOUT {
				errors: [ERRW {
					name: "Unopened brackets"
					desc: exp
				}]
			}
		}
		f := e.before("[")
		g := parse_exp(f)

		h := e.all_after_first("[")[..e.len]
		i := parse_exp(h)

		return &PARSEOUT {
			typ: "array index"
			left: g
			right: i
		}
	}

	// stuff like registers
	if e.starts_with("%") {
		return &PARSEOUT {
			typ: "special"
			val: e[1..]
		}
	}

	if e.starts_with("&") {
		v := parse_exp(e[1..])
		return &PARSEOUT {
			typ: "address"
			subtyp: "of"
			is_arr: true
			arr: [v]
			errors: v.errors
		}
	}

	if e.starts_with("*") {
		v := parse_exp(e[1..])
		return &PARSEOUT {
			typ: "address"
			subtyp: "deref"
			is_arr: true
			arr: [v]
			errors: v.errors
		}
	}

	if e == "true" || e == "false" {
		return &PARSEOUT {
			typ: "literal"
			subtyp: "boolean"
			val: e
		}
	}

	if e.starts_with("!") {
		v := parse_exp(e[1..])
		return &PARSEOUT {
			typ: "bool_op"
			subtyp: "invert"
			is_arr: true
			arr: [v]
			errors: v.errors
		}
	}

	if e.starts_with("\"") || e.starts_with("'") {
		if e.ends_with("\"") || e.ends_with("'") {
			if e.starts_with("'") && e.ends_with("'") && e.len == 3 {
				return &PARSEOUT {
					typ: "literal"
					subtyp: "char"
					val: e[1..(e.len-1)]
				}
			}
			return &PARSEOUT {
				typ: "literal"
				subtyp: "string"
				val: e[1..(e.len-1)]
			}
		}
		else {
			return &PARSEOUT {
				errors: [ERRW {
					name: "Unclosed string / char"
					desc: exp
				}]
			}
		}
	}

	if e.starts_with("(") {
		if !e.ends_with(")") {
			return &PARSEOUT {
				errors: [ERRW {
					name: "Unclosed parenthesis"
					desc: exp
				}]
			}
		}
		return parse_exp(e[1..(e.len-1)])
	}

	if e.contains("(") {
		if !e.ends_with(")") {
			return &PARSEOUT {
				errors: [ERRW {
					name: "Unclosed parenthesis"
					desc: exp
				}]
			}
		}
		name := e.before("(")
		args := e.all_after_first("(").all_before_last(")").split(",")
		mut argv := []&PARSEOUT {cap: args.len}
		mut errors := []ERRW {}
		for arg in args {
			p := parse_exp(arg)
			errors << p.errors
			argv << p
		}
		return &PARSEOUT {
			is_arr: true
			arr: argv
			typ: "call"
			val: name
			errors: errors
		}
	}

	if e.contains(".") {
		mut ok := true
		strconv.atof64(e) or {
			ok = false
			0
		}
		if ok {
			return &PARSEOUT {
				typ: "literal"
				subtyp: "float"
				val: e
			}
		}
	}

	mut ok := true
	strconv.common_parse_int(e, 0, 64, true, true) or {
		ok = false
		0
	}
	if ok {
		return &PARSEOUT {
			typ: "literal"
			subtyp: "int"
			val: e
		}
	}

	if e.contains("==") {
		a := parse_exp(e.split("==")[0])
		b := parse_exp(e.split("==")[1])
		return &PARSEOUT {
			typ: "comparison"
			subtyp: "equal"
			is_arr: true
			arr: [a, b]
			errors: a.errors.and(b.errors)
		}
	}

	if e.contains("!=") {
		a := parse_exp(e.split("!=")[0])
		b := parse_exp(e.split("!=")[1])
		return &PARSEOUT {
			typ: "comparison"
			subtyp: "not_equal"
			is_arr: true
			arr: [a, b]
			errors: a.errors.and(b.errors)
		}
	}

	if e.contains("<=") {
		a := parse_exp(e.split("<=")[0])
		b := parse_exp(e.split("<=")[1])
		return &PARSEOUT {
			typ: "comparison"
			subtyp: "less_or_equal"
			is_arr: true
			arr: [a, b]
			errors: a.errors.and(b.errors)
		}
	}

	if e.contains(">=") {
		a := parse_exp(e.split(">=")[0])
		b := parse_exp(e.split(">=")[1])
		return &PARSEOUT {
			typ: "comparison"
			subtyp: "greater_or_equal"
			is_arr: true
			arr: [a, b]
			errors: a.errors.and(b.errors)
		}
	}

	if e.contains("<") {
		a := parse_exp(e.split("<")[0])
		b := parse_exp(e.split("<")[1])
		return &PARSEOUT {
			typ: "comparison"
			subtyp: "less"
			is_arr: true
			arr: [a, b]
			errors: a.errors.and(b.errors)
		}
	}

	if e.contains(">") {
		a := parse_exp(e.split(">")[0])
		b := parse_exp(e.split(">")[1])
		return &PARSEOUT {
			typ: "comparison"
			subtyp: "greater"
			is_arr: true
			arr: [a, b]
			errors: a.errors.and(b.errors)
		}
	}

	if e.contains(" ") {
		f := e.split(" ")
		println(f)
		return &PARSEOUT {
			is_stmt: true
			op: "variable creation"
			left: &PARSEOUT {
				typ: "literal"
				subtyp: "variable"
				val: f[1]
			}
			right: unsafe{ nil }
			modifier: f[0]
		}
	}

	return &PARSEOUT {
		typ: "literal"
		subtyp: "variable"
		val: e
	}
}

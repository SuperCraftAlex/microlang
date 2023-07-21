module main
/*
fn prepare__process_curblock(mut ctx &CTX, mut currb &string, mut currco []string) {
	a := currb.split(" ")
	match a.first() {
		"t" {
			mut typ := &TYPE {
				name: a.last()
			}
			for l in currco {
				if l == ".notypecheck" { typ.notypecheck = true }
				else if l == ".public" { typ.public = true }
				else if l.starts_with("size") { typ.size = l.after("size ").u8() }
				else if l.starts_with("group") { typ.group = l.after("group ") }
				else { ctx.errors << ERRW { name: "Instruction not permitted in type block", desc: l } }
			}
			ctx.types << typ
		}
		"f" {
			c := currb.all_after_first(" ").split("(")
			mut fun := &FUNC {
				name: c.first()
				isfunc: true
			}
			y := c.last().before(")").split(",")
			for arg in y {
				b := arg.trim_space().split(" ")
				tem := b[1]
				mut v := &VAR {
					name: tem.all_after_last("*")
					typ: b[0]
					pointerc: tem.count("*")
				}
				if ":RAM" in b {
					v.fixed_to_ram = true
				}
				if ":STACK" in b {
					v.fixed_to_stack = true
				}
				fun.args << v
			}
			if currb.all_after_first(" ").contains(">") {
				z := c.last().after(">").trim_space()
				fun.retv = &VAR {
					name: "_retv"
					typ: z.all_after_last("*")
					pointerc: z.count("*")
				}
			}
			for l in currco {
				if l == ".public" { fun.public = true }
				else if l == ".macro" { fun.macro = true }
				else if l == ".macro?" { fun.automacro = true }
				else { fun.code << l }
			}
			ctx.functions << fun
		}
		"b" {
			mut fun := &FUNC {
				name: a.last()
				isfunc: false
			}
			for l in currco {
				if l == ".public" { fun.public = true }
				else if l == ".macro" { fun.macro = true }
				else if l == ".macro?" { fun.automacro = true }
				else { fun.code << l }
			}
			ctx.functions << fun
		}
		"s" {
			mut struc := &STRUCT {
				name: a.last()
			}
			for l in currco {
				if l == ".public" { struc.public = true }
				else if l.split(" ").len == 2 {
					b := l.split(" ")
					struc.variables << VAR {
						name: b.first()
						typ: b.last()
					}
				}
				else { ctx.errors << ERRW { name: "Instruction not permitted in struct block", desc: l } }
			}
			ctx.structs << struc
		}
		"ct" {
			ctx.ct_blocks << FUNC {
				isfunc: false
				name: "_ct"
				code: currco
			}
		}
		"public" {
			ctx.publics << currco
		}

		else {
			ctx.errors << ERRW { name: "Block type $a does not exist!" }
		}
	}
}

fn prepare(lines []string) &CTX {
	mut ctx := &CTX {}

	mut currb := ""
	mut currco := []string {}

	mut ind := 0

	for lineee in lines {
		line := lineee.before("#").trim_right(' \n\t\v\f\r')

		if line.len == 0 || line.starts_with("#") {
			continue
		}

		if line.ends_with(":") {
			if currb.len > 0 {
				prepare__process_curblock(mut ctx, mut currb, mut currco)

				if currco.len == 0 {
					ctx.warnings << ERRW { name: "Empty block!" }
				}
				currco = []
			}
			else if currco.len > 0 {
				ctx.errors << ERRW { name: "Code outside of blocks not permitted!" }
				currco = []
			}
			currb = line.all_before_last(":")
			continue
		}

		if ind == 0 {
			ind = line.indent_width()
		}
		if ind != line.indent_width() {
			if line.indent_width() == 0 {
				ctx.errors << ERRW { name: "Code outside of blocks not permitted!" }
			} else {
				ctx.errors << ERRW { name: "Inconsistent / Invalid indent!" }
			}
		}

		currco << line.trim_space()
	}

	if currb.len > 0 {
		prepare__process_curblock(mut ctx, mut currb, mut currco)

		if currco.len == 0 {
			ctx.warnings << ERRW { name: "Empty block!" }
		}
		currco = []
	}

	return ctx
}
*/
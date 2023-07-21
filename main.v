module main

import os
import term
import argparser

fn exec_ct(mut basectx &CTX, mut ctx &&CTX, step int) {
	for f in ctx.ct_blocks {
		for line in f.code {
			po := parse(line)
			ctx.errors << po.errors
			if po.typ == "call" {
				if po.val == "use" {
					basectx.includes << po.arr.first().val
				}
			}
		}
	}
}

fn resolve_ifs(mut c &&CTX, settings []string) {
	for fun in c.functions {
		for line in fun.code {
			if line.starts_with(".if(") {
				b := line.all_after_first(".if(")
				conds := b[..b.len-1].split(",")
				for cond in conds {
					if cond.trim_space() !in settings {
						c.functions.delete(c.functions.index(fun))
					}
				}
			}
		}
	}
}

fn print_usage() {
	println("Usage: [source file]... -o [outputfile]")
	println("	(-lib [path to stdlib]) (-Eignore) (-Werror) (-Wignore)")
	println("	(-set [var]...) (-target [target architecture])")
	println("	(-help)")
}

fn main() {
	mut stdlibloc := "/lib/microlang/"

	mut exitonerror := true
	mut exitonwarn := false
	mut ignorew := false

	args := argparser.parse(os.args[1..])
	args.check_args(["", "help", "o", "lib", "set", "target", "Eignore", "Werror", "Wignore"]) or {
		println(term.red("Invalid argument option!"))
		print_usage()
		return
	}

	if args.len == 0 {
		print_usage()
		return
	}

	if args.has_arg("help") {
		println("microlang compiler v1-beta")
		if !os.is_dir(stdlibloc) {
			println(term.bright_yellow("stdlib location: ?"))
		}
		else {
			println("stdlib location: $stdlibloc")
		}
		print_usage()
		return
	}

	infiles := args.get_arg("")!
	if infiles.len == 0 {
		println(term.bright_red("No input file(s) specified!"))
		return
	}


	if !args.has_arg("o") {
		println(term.bright_red("No output file specified!"))
	}

	otemp := args.get_arg("o")!
	if otemp.len != 1 {
		println(term.bright_red("Too many output files specified!"))
		return
	}
	ofile := otemp[0]

	if args.has_arg("lib") {
		stdlibloc = args.get_arg("lib")![0]
	}

	stdlibexists := os.is_dir(stdlibloc)
	if !stdlibexists {
		println(term.bright_yellow("Warning: stdlib doesn't exist!"))
	}

	// TODO: other arg shit

	if args.has_arg("Eignore") { exitonerror = false }
	if args.has_arg("Werror") { exitonwarn = true }
	if args.has_arg("Wignore") { ignorew = true }

	if exitonwarn && !exitonerror {
		println(term.bright_red("Error: Invalid argument combination: -Eignore -Werror"))
		return
	}

	if exitonwarn && ignorew {
		println(term.bright_red("Error: Invalid argument combination: -Wignore -Werror"))
		return
	}

	mut ctx := &CTX {}
	mut togen := []&CTX {}
	mut settings := []string {}

	if args.has_arg("set") {
		settings << args.get_arg("set")!
	}

	if args.has_arg("target") {
		if !stdlibexists {
			println(term.bright_red("Error: Cannot specify target because stdlib does not exist!"))
			return
		}
		a := args.get_arg("target")!
		if a.len == 0 {
			println(term.bright_red("Error: No target specified but \"-target\" option found!"))
			return
		}


		if !os.is_file(stdlibloc + "/.microtargets") {
			println(term.bright_red("Error: no \".microtargets\" file in stdlib! Cannot set target!"))
			return
		}

		tgf := os.read_lines(stdlibloc + "/.microtargets")!
		mut req := a.clone()
		for line in tgf {
			c := line.before("#").trim_space()
			if c.len == 0 { continue }
			b := c.split("->")
			tg := b[0].trim_space()
			if tg !in a { continue }

			req.delete(req.index(tg))
			st := b[1].split(",")
			for s in st {
				settings << s.trim_space()
			}
		}

		if req.len > 0 {
			mut ous := ""
			mut first := true
			for tg in req {
				if first {
					first = false
				}
				else {
					ous += ", "
				}
				ous += "\"" + tg + "\""
			}
			if req.len == 1 {
				println(term.bright_red("Error: Target ${ous} not supported by stdlib!"))
			}
			else {
				println(term.bright_red("Error: Targets [${ous}] not supported by stdlib!"))
			}
			return
		}
	}

	for filep in infiles {
		fex := filep.split(".").last()
		if fex == "microsett" {
			if !os.is_file(filep) {
				println(term.bright_red("File \"${filep}\" not found!"))
				return
			}
			for line in os.read_file(filep)!.split_into_lines() {
				if line.trim_space().starts_with("#") {
					continue
				}
				settings << line.trim_space().before("#").split(",")
			}
			continue
		}
		if fex != "microlang" {
			print(term.bright_red("Unknown file extension \"${filep.split('.').last()}\"!"))
			println("Usable file extensions: \".microlang\", \".microsett\"")
			return
		}
		if !os.is_file(filep) {
			println(term.bright_red("File \"${filep}\" not found!"))
			return
		}

		mut c := prepare(os.read_file(filep)!.split_into_lines())
		c.name = filep.all_before_last(".").replace("//", "/")
		addexternalctx(mut ctx, c)
		togen << c
	}
	for set in settings {
		if set.len == 0 {
			settings.delete(settings.index(set))
		}
	}

	if print_check_warnings_errors(mut ctx, exitonwarn, ignorew) && exitonerror { return }
	println("Step 0 ${term.bright_green("done")}: Preparing")

	for mut c in togen {
		exec_ct(mut ctx, mut *c, 0)
	}

	if print_check_warnings_errors(mut ctx, exitonwarn, ignorew) && exitonerror { return }
	println("Step 1 ${term.bright_green("done")}: Executing ct code part 1")

	mut multilibctx := &CTX {}
	mut libs := []&CTX {}
	mut libn := []string {}
	if os.is_dir(stdlibloc) {
		for filep in os.ls(stdlibloc)! {
			if filep.split(".").last() != "microlang" {
				continue
			}

			mut c := prepare(os.read_file(stdlibloc + "/" + filep)!.split_into_lines())
			c.name = (stdlibloc + "/" + filep).all_before_last(".").replace("//", "/")
			addexternalctx(mut multilibctx, c)
			exec_ct(mut multilibctx, mut *c, 0)
			libs << c
			libn << filep.all_before_last(".")
		}
		if print_check_warnings_errors(mut multilibctx, exitonwarn, ignorew) && exitonerror { return }
		println("Step 2 ${term.bright_green("done")}: Preparing libraries")
	}
	else {
		println("Step 2 ${term.bright_yellow("skipped")}")
	}

	for inc in ctx.includes {
		if inc !in libn {
			ctx.errors << ERRW { name: "Library not found", desc: inc }
			continue
		}
		c := libs[libn.index(inc)]
		addexternalctx(mut ctx, c)
		togen << c
		for i in c.includes {
			if i !in libn {
				ctx.errors << ERRW { name: "Library not found", desc: i }
				continue
			}
			e := libs[libn.index(i)]
			addexternalctx(mut ctx, e)
			togen << e
		}
	}

	if print_check_warnings_errors(mut ctx, exitonwarn, ignorew) && exitonerror { return }
	println("Step 3 ${term.bright_green("done")}: Linking libraries")

	for mut c in togen {
		for mut fun in c.functions {
			for code in fun.code {
				p := parse(code)
				fun.p_code << p
				ctx.errors << p.errors
			}
		}
		for code in c.publics {
			p := parse(code)
			c.p_publics << p
			ctx.errors << p.errors
		}
	}

	if print_check_warnings_errors(mut ctx, exitonwarn, ignorew) && exitonerror { return }
	println("Step 4 ${term.bright_green("done")}: Parsing code")

	for mut c in togen {
		resolve_ifs(mut *c, settings)
	}

	//for mut c in togen {
	//	for mut fun in c.functions {
	//		mut used := []bool {}
	//		mut vars := []string {}
	//		mut torep := []&PARSEOUT {}
//
	//		for code in fun.p_code {
	//			if code.typ == "variable creation" {
//
	//			}
	//		}
	//	}
	//}

	mut out := "["
	for c in togen {
		out += c.str() + ","
	}
	out += "]"
	os.write_file("ctxout_after_5.json", out)!

	if print_check_warnings_errors(mut ctx, exitonwarn, ignorew) && exitonerror { return }
	println("Step 5 ${term.bright_green("done")}: Removing unused elements")

	for mut c in togen {
		exec_ct(mut ctx, mut *c, 1)
	}

	if print_check_warnings_errors(mut ctx, exitonwarn, ignorew) && exitonerror { return }
	println("Step 6 ${term.bright_green("done")}: Executing ct code part 2")

	if print_check_warnings_errors(mut ctx, exitonwarn, ignorew) && exitonerror { return }
	println("Step 7 ${term.bright_green("done")}: Optimizing part 1")

	if print_check_warnings_errors(mut ctx, exitonwarn, ignorew) {
		println(term.bright_red("Exited with errors!"))
		return
	}
	println("Step 8 ${term.bright_green("done")}: Generating locations of elements")

	if print_check_warnings_errors(mut ctx, exitonwarn, ignorew) {
		println(term.bright_red("Exited with errors!"))
		return
	}
	println("Step 9 ${term.bright_green("done")}: Optimizing part 2")

	if print_check_warnings_errors(mut ctx, exitonwarn, ignorew) {
		println(term.bright_red("Exited with errors!"))
		return
	}
	println("Step 10 ${term.bright_green("done")}: Codegen")

	println(term.bright_green("Finished succesfully!"))
	println(term.bright_green("Output saved to $ofile!"))
}

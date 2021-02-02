########################################################################
#                                                                      #
#               This software is part of the ast package               #
#          Copyright (c) 1982-2012 AT&T Intellectual Property          #
#                      and is licensed under the                       #
#                 Eclipse Public License, Version 1.0                  #
#                    by AT&T Intellectual Property                     #
#                                                                      #
#                A copy of the License is available at                 #
#          http://www.eclipse.org/org/documents/epl-v10.html           #
#         (with md5 checksum b35adb5213ca9657e911e9befb180842)         #
#                                                                      #
#              Information and Software Systems Research               #
#                            AT&T Research                             #
#                           Florham Park NJ                            #
#                                                                      #
#                  David Korn <dgk@research.att.com>                   #
#                                                                      #
########################################################################
: generate the ksh math builtin table
: include math.tab

# @(#)math.sh (AT&T Research) 2012-06-13

case $ZSH_VERSION in
?*)	emulate ksh ;;
*)	(command set -o posix) 2>/dev/null && set -o posix ;;
esac

command=$0
iffeflags="-n -v"
iffehdrs="math.h"
iffelibs="-lm"
table=/dev/null

eval $1
shift
table=$1

: check long double

eval `iffe $iffeflags -c "$cc" - typ long.double 2>&$stderr`

: check ast_standards.h

eval `iffe $iffeflags -F ast_standards.h -c "$cc" - tst use_ast_standards -lm 'note{' 'math.h needs ast_standards.h' '}end' 'link{' '#include <math.h>' '#ifndef isgreater' '#define isgreater(a,b) 0' '#endif' 'int main() { return isgreater(0.0,1.0); }' '}end'`
case $_use_ast_standards in
1)	iffeflags="$iffeflags -F ast_standards.h" ;;
esac
eval `iffe $iffeflags -c "$cc" - tst use_ieeefp -lm 'note{' 'ieeefp.h plays nice' '}end' 'link{' '#include <math.h>' '#include <ieeefp.h>' 'int main() { return 0; }' '}end'`
case $_use_ieeefp in
1)	iffehdrs="$iffehdrs ieeefp.h" ;;
esac

: read the table

exec < $table
ifs=$IFS
libs=
names=
nums=
while	read type args name aka
do	case $type in
	[fix])	names="$names $name"
		libs="$libs,$name"
		case $_typ_long_double in
		1)	libs="$libs,${name}l" ;;
		esac
		for a in $aka
		do	case $a in
			'{'*)	break
				;;
			*=*)	IFS='=|'
				set $a
				IFS=$ifs
				case ",$libs" in
				*,$1,*)	;;
				*)	names="$names $1"
					libs="$libs,$1"
					case $_typ_long_double in
					1)	libs="$libs,${1}l" ;;
					esac
					;;
				esac
				shift
				while	:
				do	case $# in
					0)	break ;;
					esac
					case ",$nums" in
					*,$1,*)	;;
					*)	nums="$nums,$1" ;;
					esac
					shift
				done
				;;
			esac
		done
		eval TYPE_$name='$type' ARGS_$name='$args' AKA_$name='$aka'
		;;
	esac
done

: check the math library

eval `iffe $iffeflags -c "$cc" - lib $libs $iffehdrs $iffelibs 2>&$stderr`
lib=
for name in $names
do	eval x='$'_lib_${name}l y='$'_lib_${name}
	case $x in
	1)	lib="$lib,${name}l" ;;
	esac
	case $y in
	1)	case $x in
		'')	lib="$lib,${name}" ;;
		esac
		;;
	esac
done
eval `iffe $iffeflags -c "$cc" - dat,npt,mac $lib $iffehdrs $iffelibs 2>&$stderr`
eval `iffe $iffeflags -c "$cc" - num $nums $iffehdrs $iffelibs 2>&$stderr`

cat <<!
#pragma prototyped

/* : : generated by $command from $table : : */

typedef Sfdouble_t (*Math_f)(Sfdouble_t,...);

!
case $_use_ast_standards in
1)	echo "#include <ast_standards.h>" ;;
esac
echo "#include <math.h>"
case $_hdr_ieeefp in
1)	echo "#include <ieeefp.h>" ;;
esac
cat <<!
#if defined(__ia64__) && defined(signbit)
# if defined __GNUC__ && __GNUC__ >= 4
#  define __signbitl(f)		__builtin_signbitl(f)
# else
#  include <ast_float.h>
#  if _lib_copysignl
#   define __signbitl(f)	(int)(copysignl(1.0,(f))<0.0)
#  endif
# endif
#endif
!
echo

: generate the intercept functions and table entries

nl='
'
ht='	'
tab=
for name in $names
do	eval x='$'_lib_${name}l y='$'_lib_${name} r='$'TYPE_${name} a='$'ARGS_${name} aka='$'AKA_${name}
	case $r in
	i)	L=int R=1 ;;
	x)	L=Sfdouble_t R=4 ;;
	*)	L=Sfdouble_t R=0 ;;
	esac
	F=local_$name
	case $x:$y in
	1:*)	f=${name}l
		t=Sfdouble_t
		local=
		;;
	*:1)	f=${name}
		t=double
		local=$_typ_long_double
		;;
	*)	body=
		for k in $aka
		do	case $body in
			?*)	body="$body $k"
				continue
				;;
			esac
			case $k in
			'{'*)	body=$k
				;;
			*=*)	IFS='=|'
				set $k
				IFS=$ifs
				f=$1
				shift
				v=$*
				eval x='$'_lib_${f}l y='$'_lib_${f}
				case $x:$y in
				1:*)	f=${f}l
					;;
				*:1)	;;
				*)	continue
					;;
				esac
				y=
				while	:
				do	case $# in
					0)	break ;;
					esac
					eval x='$'_num_$1
					case $x in
					1)	case $y in
						?*)	y="$y || " ;;
						esac
						y="${y}q == $1"
						;;
					esac
					shift
				done
				case $y in
				'')	;;
				*)	r=int R=1
					echo "static $r $F(Sfdouble_t a1) { $r q = $f(a1); return $y; }"
					tab="$tab$nl$ht\"\\0${R}${a}${name}\",$ht(Math_f)${F},"
					break
					;;
				esac
				;;
			esac
		done
		case $body in
		?*)	code="static $L $F("
			sep=
			ta=
			tc=
			td=
			for p in 1 2 3 4 5 6 7 8 9
			do	case $R:$p in
				4:2)	T=int ;;
				*)	T=Sfdouble_t ;;
				esac
				code="$code${sep}$T a$p"
				ta="$ta${sep}a$p"
				tc="$tc${sep}0"
				td="${td}$T a$p;"
				case $a in
				$p)	break ;;
				esac
				sep=","
			done
			_it_links_=0
			eval `iffe $iffeflags -c "$cc" - tst it_links_ note{ $F function links }end link{ "static $L $F($ta)$td${body}int main(){return $F($tc)!=0;}" }end sfio.h $iffehdrs $iffelibs 2>&$stderr`
			case $_it_links_ in
			1)	code="$code)$body"
				echo "$code"
				tab="$tab$nl$ht\"\\0${R}${a}${name}\",$ht(Math_f)${F},"
				;;
			esac
			;;
		esac
		continue
		;;
	esac
	case $r in
	i)	r=int ;;
	*)	r=$t ;;
	esac
	eval n='$'_npt_$f m='$'_mac_$f d='$'_dat_$f
	case $d:$m:$n in
	1:*:*|*:1:*)
		;;
	*:*:1)	code="extern $r $f("
		sep=
		for p in 1 2 3 4 5 6 7
		do	case $p:$f in
			2:ldexp*)	code="$code${sep}int" ;;
			*)		code="$code${sep}$t" ;;
			esac
			case $a in
			$p)	break ;;
			esac
			sep=","
		done
		code="$code);"
		echo "$code"
		;;
	esac
	case $local:$m:$n:$d in
	1:*:*:*|*:1:*:*|*:*:1:)
		args=
		code="static $L local_$f("
		sep=
		for p in 1 2 3 4 5 6 7 8 9
		do	args="$args${sep}a$p"
			case $R:$p in
			4:2)	T=int ;;
			*)	T=Sfdouble_t ;;
			esac
			code="$code${sep}$T a$p"
			case $a in
			$p)	break ;;
			esac
			sep=","
		done
		code="$code){return $f($args);}"
		echo "$code"
		f=local_$f
		;;
	esac
	for x in $name $aka
	do	case $x in
		'{'*)	break
			;;
		*=*)	continue
			;;
		esac
		tab="$tab$nl$ht\"\\0${R}${a}${x}\",$ht(Math_f)$f,"
	done
done
tab="$tab$nl$ht\"\",$ht$ht(Math_f)0"

cat <<!

/*
 * first byte is two-digit octal number.  Last digit is number of args
 * first digit is 0 if return value is double, 1 for integer
 */
const struct mathtab shtab_math[] =
{$tab
};
!

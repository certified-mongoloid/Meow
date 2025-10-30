# Meow

Meow

## Meow EBNF

The (* 4 \*), (* x \*), etc, next to the 'meow' non-terminals indicates the length
of the meow required.

add address = meow (* 5 \*), meaning "meoww", "mmeow", "meeow", etc.

```
(* Program Structure *)

program = operation, { operation } ;

operation = assignment | arithmetic | conditional | jump | io ;

(* Operations *)

arithmetic = meow (* 4 *), ( add | sub | mul | div );

add = add value | add address ;

add value = meow (* 4 *), address, address, value ;
add address = meow (* 5 *), address, address, address ;

sub = sub value | sub address ;

sub value = meow (* 6 *), address, address, value ;
sub address = meow (* 7 *), address, address, address ;

mul = mul value | mul address ;
mul value = meow (* 8 *), address, address, value ;
mul address = meow (* 9 *), address, address, address ;

div = div value | div address ;
div value = meow (* 10 *), address, address, value ;
div address = meow (* 11 *), address, address, address ;

conditional = meow (* 5 *), equals | greater | less ;

equals = equals val | equals address ;
equals val = meow (* 4 *), address, value, jump ;
equals address = meow (* 5 *), address, address, jump ;

greater = greater val | greater address ;
greater val = meow (* 6 *), address, value, jump ;
greater address = meow (* 7 *), address, address, jump ;

less = less val | less address ;
less val = meow (* 8 *), address, value, jump ;
less address = meow (* 9 *), address, address, jump ;

jump = meow (* 6 *), forward jump | backward jump ;

forward jump = foward val | forward address ;
forward val = meow (* 4 *), value ;
forward address = meow (* 5 *), address ;

backward jump = backward val | backward address ;
backward val = meow (* 6 *), value ;
backward address = meow (* 7 *), address ;

io = meow (* 7 *), input | output | output ascii;

input = meow (* 4 *), address ;
output = meow (* 5 *), address ;

output ascii = meow (* 6 *), address ;
(* Terminals *)
meow = "m", { "m" }, "e", { "e" }, "o", { "o" }, "w", { "w" } ;
```

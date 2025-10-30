//! Meow EBNF
//!
//! (* Program Structure *)
//! program = operation, { operation } ;
//! operation = assignment | arithmetic | conditional | jump | io ;
//!
//! (* Operations *)
//!
//! arithmetic = meow (* 4 *), ( add | sub | mul | div );
//!
//! add = add value | add address ;
//! add value = meow (* 4 *), address, address, value ;
//! add address = meow (* 5 *), address, address, address ;
//!
//! sub = sub value | sub address ;
//! sub value = meow (* 6 *), address, address, value ;
//! sub address = meow (* 7 *), address, address, address ;
//!
//! mul = mul value | mul address ;
//! mul value = meow (* 8 *), address, address, value ;
//! mul address = meow (* 9 *), address, address, address ;
//!
//! div = div value | div address ;
//! div value = meow (* 10 *), address, address, value ;
//! div address = meow (* 11 *), address, address, address ;
//!
//! conditional = meow (* 5 *), equals | greater | less ;
//!
//! equals = equals val | equals address ;
//! equals val = meow (* 4 *), address, value, jump ;
//! equals address = meow (* 5 *), address, address, jump ;
//!
//! greater = greater val | greater address ;
//! greater val = meow (* 6 *), address, value, jump ;
//! greater address = meow (* 7 *), address, address, jump ;
//!
//! less = less val | less address ;
//! less val = meow (* 8 *), address, value, jump ;
//! less address = meow (* 9 *), address, address, jump ;
//!
//! jump = meow (* 6 *), forward jump | backward jump ;
//!
//! forward jump = foward val | forward address ;
//! forward val = meow (* 4 *), value ;
//! forward address = meow (* 5 *), address ;
//!
//! backward jump = backward val | backward address ;
//! backward val = meow (* 6 *), value ;
//! backward address = meow (* 7 *), address ;
//!
//! io = meow (* 7 *), input | output | output ascii;
//!
//! input = meow (* 4 *), address ;
//! output = meow (* 5 *), address ;
//! output ascii = meow (* 6 *), address ;
//!
//! (* Terminals *)
//! meow = "m", { "m" }, "e", { "e" }, "o", { "o" }, "w", { "w" } ;
//!
//! (* Example *)
//! meow meow meow meow meowwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww
//! meow meow meoww meow meowwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww
//! meow meow meowww meoww meowwwwwwwwwwwwwwwwwwwwwwwwwwwwww
//! meowwww meoww meoww
//! meowwww meoww meowww
//! meow meow meowww meowwww meowwwwwwww
//! meowwww meoww meowww
//! meowwww meoww meowww
//! meow meow meowww meowwww meowwww
//! meowwww meoww meowww
//! meowwww meoww meow
//! meow meowww meow meow meoww
//! meowwww meoww meow
//! meow meow meoww meowwww meowwwwwwwwwwwwwwww
//! meowwww meoww meoww
//! meowwww meoww meowww
//! meow meow meowww meowwww meowwww
//! meowwww meoww meowww
//! meow meowww meowww meowwww meowwwwwww
//! meowwww meoww meowww
//! meow meowww meowww meowwww meowwwwwwwww
//! meowwww meoww meowww
//! meow meow meow meowwww meoww
//! meowwww meoww meow

const std = @import("std");

const trace = false;

pub fn main() !void {
    var da: std.heap.DebugAllocator(.{}) = .init;
    defer _ = da.deinit();
    const allocator = da.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    switch (args.len) {
        2 => try runFile(allocator, args[1]),
        else => {},
    }
}

fn runFile(allocator: std.mem.Allocator, path: []const u8) !void {
    const file = std.fs.cwd().openFile(path, .{}) catch {
        std.debug.print("Unable to open file\n", .{});
        std.process.exit(1);
    };
    defer file.close();

    const file_stat = file.stat() catch {
        std.debug.print("Unable to retrieve information about file\n", .{});
        std.process.exit(1);
    };

    const data = file.readToEndAlloc(allocator, file_stat.size) catch {
        std.debug.print("Unable to read file\n", .{});
        std.process.exit(1);
    };
    defer allocator.free(data);

    var tokenizer: Tokenizer = .init(data);
    var pm: PurrtualMachine = .init(&tokenizer);

    const result = pm.compile();
    if (result != .ok) {
        std.process.exit(1);
    }
}

const PurrtualMachine = struct {
    ip: usize,
    memory: [30000]u16,
    tokenizer: *Tokenizer,

    const State = enum {
        start,
        arithmetic,
        conditional,
        jump,
        io,
    };

    pub fn init(tokenizer: *Tokenizer) PurrtualMachine {
        return .{
            .ip = 0,
            .memory = [_]u16{0} ** 30000,
            .tokenizer = tokenizer,
        };
    }

    pub fn compile(self: *PurrtualMachine) enum { ok, dead } {
        var token: Token = undefined;
        state: switch (State.start) {
            .start => {
                token = self.tokenizer.next();
                if (token.tag == .eof) {
                    return .ok;
                }

                if (trace) {
                    std.debug.print("----------\n", .{});
                }

                switch (token.size()) {
                    0 => continue :state .arithmetic,
                    1 => continue :state .conditional,
                    2 => continue :state .jump,
                    3 => continue :state .io,
                    else => {
                        return .dead;
                    },
                }
            },
            .arithmetic => {
                const op = self.tokenizer.next().size();

                const address0 = self.tokenizer.next().size();
                const address1 = self.tokenizer.next().size();
                const third = self.tokenizer.next().size();

                switch (op) {
                    0...7 => self.arithmetic(@enumFromInt(op), address0, address1, third),
                    else => {
                        return .dead;
                    },
                }

                continue :state .start;
            },
            .conditional => {
                const comparison = self.tokenizer.next().size();

                const address = self.tokenizer.next().size();
                const second = self.tokenizer.next().size();

                switch (comparison) {
                    0...5 => {
                        const result = self.conditional(@enumFromInt(comparison), address, second);
                        if (result) continue :state .jump;
                        // consume tokens
                        _ = self.tokenizer.next();
                        _ = self.tokenizer.next();
                        _ = self.tokenizer.next();
                    },
                    else => {
                        return .dead;
                    },
                }

                continue :state .start;
            },
            .jump => {
                const direction = self.tokenizer.next().size();

                const distance = self.tokenizer.next().size();

                switch (direction) {
                    0...3 => self.jump(@enumFromInt(direction), distance),
                    else => {
                        return .dead;
                    },
                }

                continue :state .start;
            },
            .io => {
                const channel = self.tokenizer.next().size();
                const address = self.tokenizer.next().size();

                switch (channel) {
                    0...2 => self.io(@enumFromInt(channel), address) catch {
                        std.debug.print("Unable to access system IO", .{});
                        return .dead;
                    },
                    else => {
                        return .dead;
                    },
                }

                continue :state .start;
            },
        }

        return .dead;
    }

    fn arithmetic(
        self: *PurrtualMachine,
        op: enum(usize) {
            add_value,
            add_address,
            sub_value,
            sub_address,
            mul_value,
            mul_address,
            div_value,
            div_address,
        },
        address0: usize,
        address1: usize,
        third: usize,
    ) void {
        const val: u16 = @intCast(third);
        if (trace) {
            std.debug.print("Arithmetic {s}\n", .{@tagName(op)});
            std.debug.print("Address 0: [{d}] = {d}\n", .{ address0, self.memory[address0] });
            std.debug.print("Address 1: [{d}] = {d}\n", .{ address1, self.memory[address1] });
            switch (op) {
                .add_value, .sub_value, .mul_value, .div_value => std.debug.print("Value: {d}\n", .{val}),
                else => std.debug.print("Address 2: [{d}] = {d}\n", .{ third, self.memory[third] }),
            }
        }
        self.memory[address0] = switch (op) {
            .add_value => self.memory[address1] + val,
            .add_address => self.memory[address1] + self.memory[third],
            .sub_value => self.memory[address1] - val,
            .sub_address => self.memory[address1] - self.memory[third],
            .mul_value => self.memory[address1] * val,
            .mul_address => self.memory[address1] * self.memory[third],
            .div_value => self.memory[address1] / val,
            .div_address => self.memory[address1] / self.memory[third],
        };

        if (trace) {
            std.debug.print("Result: {d}\n", .{self.memory[address0]});
        }
    }

    fn conditional(
        self: *PurrtualMachine,
        comp: enum(usize) {
            equals_val,
            equals_address,
            greater_val,
            greater_address,
            less_val,
            less_address,
        },
        address: usize,
        second: usize,
    ) bool {
        const val: u16 = @intCast(second);
        if (trace) {
            std.debug.print("Conditional {s}\n", .{@tagName(comp)});
        }
        return switch (comp) {
            .equals_val => self.memory[address] == val,
            .equals_address => self.memory[address] == self.memory[second],
            .greater_val => self.memory[address] > val,
            .greater_address => self.memory[address] > self.memory[second],
            .less_val => self.memory[address] < val,
            .less_address => self.memory[address] < self.memory[second],
        };
    }

    fn jump(
        self: *PurrtualMachine,
        direction: enum {
            forward_val,
            forward_address,
            backward_val,
            backward_address,
        },
        distance: usize,
    ) void {
        const val: u16 = @intCast(distance);
        if (trace) {
            std.debug.print("Jump {s} {d}\n", .{ @tagName(direction), distance });
        }
        switch (direction) {
            .forward_val => {
                for (0..val) |_| {
                    _ = self.tokenizer.next();
                }
            },
            .forward_address => {
                for (0..self.memory[distance]) |_| {
                    _ = self.tokenizer.next();
                }
            },
            .backward_val => {
                for (0..val) |_| {
                    _ = self.tokenizer.goBack();
                }
            },
            .backward_address => {
                for (0..self.memory[distance]) |_| {
                    _ = self.tokenizer.goBack();
                }
            },
        }
    }

    fn io(
        self: *PurrtualMachine,
        channel: enum { input, output, output_ascii },
        address: usize,
    ) !void {
        if (trace) {
            std.debug.print("IO {s}\n", .{@tagName(channel)});
        }
        const stdin = std.io.getStdIn().reader();
        const stdout = std.io.getStdOut().writer();
        switch (channel) {
            .input => {
                const input = try stdin.readByte();
                self.memory[address] = input;
            },
            .output => try stdout.print("{d}", .{self.memory[address]}),
            .output_ascii => {
                const ascii: u8 = @intCast(self.memory[address]);
                try stdout.print("{c}", .{ascii});
            },
        }
    }
};

const Token = struct {
    tag: Tag,
    loc: Location,

    const Location = struct {
        start: usize,
        end: usize,
    };

    const Tag = enum {
        meow,
        eof,
        invalid,
    };

    pub fn size(self: Token) usize {
        return (self.loc.end - self.loc.start) - 4;
    }
};

const Tokenizer = struct {
    source: []const u8,
    index: usize,

    pub fn init(source: []const u8) Tokenizer {
        return .{
            .source = source,
            .index = 0,
        };
    }

    const State = enum {
        start,
        m,
        e,
        o,
        w,
        invalid,
    };

    pub fn goBack(self: *Tokenizer) void {
        state: switch (State.start) {
            .start => {
                switch (self.current()) {
                    ' ', '\t', '\r', '\n' => {
                        self.index -= 1;
                        continue :state .start;
                    },
                    else => continue :state .invalid,
                }
            },
            .invalid => {
                if (self.index == 0) {
                    return;
                }

                switch (self.current()) {
                    ' ', '\t', '\r', '\n' => {
                        return;
                    },
                    else => {
                        self.index -= 1;
                        continue :state .invalid;
                    },
                }
            },
            else => {},
        }
    }

    pub fn next(self: *Tokenizer) Token {
        var result: Token = .{
            .tag = undefined,
            .loc = .{
                .start = self.index,
                .end = undefined,
            },
        };

        state: switch (State.start) {
            .start => {
                if (self.index >= self.source.len) {
                    result.tag = .eof;
                    result.loc.end = self.index;
                    return result;
                }

                switch (self.current()) {
                    ' ', '\t', '\r', '\n' => {
                        self.index += 1;
                        result.loc.start = self.index;
                        continue :state .start;
                    },
                    'm' => continue :state .m,
                    else => continue :state .invalid,
                }
            },
            .m => {
                switch (self.current()) {
                    'm' => {
                        self.index += 1;
                        continue :state .m;
                    },
                    'e' => {
                        self.index += 1;
                        continue :state .e;
                    },
                    else => continue :state .invalid,
                }
            },
            .e => {
                switch (self.current()) {
                    'e' => {
                        self.index += 1;
                        continue :state .e;
                    },
                    'o' => {
                        self.index += 1;
                        continue :state .o;
                    },
                    else => continue :state .invalid,
                }
            },
            .o => {
                switch (self.current()) {
                    'o' => {
                        self.index += 1;
                        continue :state .o;
                    },
                    'w' => {
                        self.index += 1;
                        continue :state .w;
                    },
                    else => continue :state .invalid,
                }
            },
            .w => {
                switch (self.current()) {
                    'w' => {
                        self.index += 1;
                        continue :state .w;
                    },
                    ' ', '\t', '\r', '\n' => {
                        result.tag = .meow;
                    },
                    else => continue :state .invalid,
                }
            },
            .invalid => {
                switch (self.current()) {
                    '\t', '\r', '\n', ' ' => {
                        result.tag = .invalid;
                    },
                    else => {
                        self.index += 1;
                        continue :state .invalid;
                    },
                }
            },
        }

        result.loc.end = self.index;
        return result;
    }

    inline fn current(self: Tokenizer) u8 {
        return self.source[self.index];
    }
};

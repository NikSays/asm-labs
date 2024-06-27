# Assembly Labs

This repository is a showcase of several [NASM](https://www.nasm.us) programs I've written for FAF.AC21.1 Computer Architecture course. 

## Running the code

### Normal execution

Requires `nasm` and `gcc`.

```shell
# Generate the object file
nasm file.asm -o obj.o -f elf64

# Link and generate the executable:

# If label _start is defined (no stdlib used)
ld obj.o -o out
# If label main is defined (uses stdlib)
gcc obj.o -o out -no-pie

# Execute
./out
```

### Debugging

Requires `nasm`, `gcc` and `dbg`.

```shell
# Generate the object file, including debug info
nasm file.asm -o obj.o -f elf64 -F dwarf

# Link and generate the executable:

# If label _start is defined (no stdlib used)
ld obj.o -o out
# If label main is defined (uses stdlib)
gcc obj.o -o out -no-pie

# Start debugger
gdb ./out
```

## Personal findings

### System call conventions

I've noticed some of my colleagues using `4` for `sys_write` call, and was surprised, because I've read that `sys_write` is `1`. Then I found out about 2 different ways of executing system calls. First is the legacy 32-bit syscall convention, where to execute it, you write `int 0x80`, triggering a processor interrupt directly. Second is the 64-bit convention, where there's a separate `syscall` instruction. I opted to use the 64-bit convention.

### CLI arguments

The [AMD64 ABI (p.29)](https://refspecs.linuxbase.org/elf/x86_64-abi-0.99.pdf#page=30) states that when a program is initialized, the value at the stack pointer is N - the number of arguments, the next N values on stack are the pointers to null-terminated char arrays. As I know from my experience with Linux, the first argument is the name of the program itself.

### Position Independent Executables

At first I've been compiling and linking my code with `ld`.
This creates Position Dependent Executables. They know exact addresses of labels, e.g. label `len` is always at address `0x420000` in the virtual address space. But to include the `stdio` procedures from C Standard Library, I linked my programs with `gcc`.

But by default GCC produces Position Independent Executables (PIE). They can be linked as a static library into another program, so they can't know the addresses of any labels beforehand. To help with that, NASM has RIP-relative addressing. (RIP – instruction pointer). Just adding `default rel` to the top of the file converts any direct reference to a label like "`0x420000`" to "the address of the current instruction plus an offset". This way it does not matter at what address the program is loaded.
Except, there's more. At the time NASM compiles the .o file, it can't know where the external functions like `printf`, `fopen`, etc., are located, even relatively to the RIP. That's why every call to them must have the form of `call printf wrt ..plt`. The `wrt ..plt` means "With relation to Procedure Linkage Table". PLT is a constant place in program memory, where NASM points the calls, and the linker adds the jumps to the real location of the procedure.
To not deal with all of this I just added the `-no-pie` flag to GCC. [See this post](https://stackoverflow.com/questions/52126328/cant-call-c-standard-library-function-on-64-bit-linux-from-assembly-yasm-code/52131094#52131094).

### Stack alignment

When I first used `stdio`, I've been getting random SEGFAULTs. GDB showed them originating from the C functions. It was clear that the problem is more likely in me, than in C Standard Library. That's when I found out about the stack alignment. Basically, for some instructions to work properly, the address of the stack pointer needs to end in 0x0 (hexadecimal). This is always the case when an executable starts running ([AMD64 ABI p.30](https://refspecs.linuxbase.org/elf/x86_64-abi-0.99.pdf#page=31)). But here I'm using GCC, and the `_start` label is somewhere in the C runtime, which calls my `main` label. And calling pushes an 8-byte pointer to the stack, so when my `main` starts executing, the stack pointer ends in 0x8. The AMD64 calling convention states that the stack must always be 16-byte aligned right before the call ([AMD64 ABI p.16](https://refspecs.linuxbase.org/elf/x86_64-abi-0.99.pdf#page=17)), so it will always be misaligned right after. That's why in the first line of `main` I subtract 8 from RSP. It's important to keep in mind that the stack grows towards smaller addresses, so subtracting from it actually grows it. But before `ret` I need the stack pointer to be in its original position so that `ret` can pop the return pointer from it. So I add the 8 back.
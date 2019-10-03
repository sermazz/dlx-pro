perl ./assembler.bin/dlxasm.pl -list test.list -o test.bin test.asm
cat test.bin | hexdump -v -e '/1 "%02X" /1 "%02X" /1 "%02X" /1 "%02X\n"' > test.asm.mem
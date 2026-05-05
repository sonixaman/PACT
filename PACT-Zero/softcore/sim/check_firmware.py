#checker to see if the .bin is converting to .hex correctly
# use command > python3 bin_hex_check.py > head -5 firmware.hex
# compare against objdump output to check
import struct
fin = open('firmware.bin', 'rb')
data = fin.read()
fin.close()
fout = open('firmware.hex', 'w')
for i in range(0, len(data), 4):
    word = data[i:i+4]
    if len(word) < 4:
        word = word + b'\x00' * (4 - len(word))
    val = struct.unpack('<I', word)[0]
    fout.write('{:08x}\n'.format(val))
fout.close()
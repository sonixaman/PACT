#define UART_TX (*(volatile unsigned int*)0x10000000)
#define PHASE_REG (*(volatile unsigned int*)0x20000000)

void print_char(char c)
{
    UART_TX = c;
}

void print_str(const char* s) {
    while (*s){
        print_char(*s);
        s++;
    }
}

int main()
{
    int azimuth = 30;
    int elevation = 20;

    PHASE_REG = (elevation << 16) | azimuth;

    print_str("PACT OK\n");

    while(1);

    return 0;
}

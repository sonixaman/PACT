#define UART_TX (*(volatile unsigned int*)0x10000000)
#define PHASE_REG (*(volatile unsigned int*)0x20000000)

/* Uncomment to enable continuous steering
  Requires: cmd_reg.vhd, mem_intercon.vhd update, parallel_bus.vhd update 
  (uncomment comments with the heading " Uncomment to enable continuous steering"
   the files specified)
    Uncomment "%" lines to enable continous steering , remove all '%' before uncommenting
    
 % #define CMD_REG (*(volatile unsigned int*)0x20000004)
 
 */

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
    
    /* PACT One — continuous steering from Linux PS
       Uncomment when cmd_reg.vhd is implemented
     
     % unsigned int last_cmd = 0;
     % while(1) {
     %     unsigned int cmd = CMD_REG;
     %     if (cmd != last_cmd) {
     %         PHASE_REG = cmd;
     %         last_cmd = cmd;
     %     }
     % }
     */


    while(1);

    return 0;
}

#include <stdint.h>

/* 
   UART is a stimulation stub connects to uart_controller.vhd -> TCL console 
   you may connect it to an actual UART port 
*/
#define UART_TX (*(volatile unsigned int*)0x10000000) 

/* Uncomment to enable continuous steering
  (uncomment comments with the heading " Uncomment to enable continuous steering"
   the files specified)
    Uncomment "%" lines to enable continous steering , remove all '%' before uncommenting
    IMPORTANT : ignore lines above (already implemented)
 */
    
#define CMD_REG (*(volatile unsigned int*)0x20000004) //same function as phase_reg , intentionally kept redundant

#define offset_reg_00 (*(volatile unsigned int*)0x20000010)
#define offset_reg_01 (*(volatile unsigned int*)0x20000014)
#define offset_reg_10 (*(volatile unsigned int*)0x20000018)
#define offset_reg_11 (*(volatile unsigned int*)0x2000001C)

/*
    conversion_factor = max values of signed int/ 180 
    angle range : -180 to 180 (periodic)
    corresponding int rangle : max_value_signed
    handles angles without constraint 
    example 195 deg -> 180 + 15 -> -180 + 15 
*/
 
const int16_t sin_lookup [91] = 
    {  
         0,    4,   9,  13,  18,  22,  27,   31,   36,  40, 
        44,   49,  53,  58,  62,  66,  71,   75,   79,  83,  
        88,   92,  96, 100, 104, 108, 112,  116,  120, 124, 
       128,  132, 136, 139, 143, 147, 150,  154,  158, 161, 
       165,  168, 171, 175, 178, 181, 184,  187,  190, 193, 
       196,  199, 202, 204, 207, 210, 212,  215,  217, 219, 
       222,  224, 226, 228, 230, 232, 234,  236,  237, 239, 
       241,  242, 243, 245, 246, 247, 248,  249,  250, 251, 
       252,  253, 254, 254, 255, 255, 255,  256,  256, 256, 
       256
    };                                       

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

//would have to parse angles as signed integer
// scale it to signed integer while parsing 
// descale while calculating 

int sin_fixed(int real_angle)
{
    /*
        conversion_factor = max values of signed int/ 180 
        angle range : -180 to 180 (periodic)
        corresponding int rangle : max_value_signed
        handles angles without constraint 
        example 195 deg -> 180 + 15 -> -180 + 15 
    */

	/*
    int16_t angle = (int16_t)(real_angle * conversion_factor) ; //overflow handels normalization(-180 to 180)
    int sin_value; //output

    //conditional mirroring 
    if (angle <= 90*conversion_factor && angle >= 0)
    {
        sin_value = sin_lookup[angle/conversion_factor];
    }
    else if (angle > 90*conversion_factor && angle <= 180*conversion_factor)
    {
        sin_value = sin_lookup[180 - (angle/conversion_factor)];
    }
    else if ( angle > -90*conversion_factor && angle < 0 )
    {
        sin_value = -sin_lookup[-1*(angle/conversion_factor)];
    }
    else  
    {
        sin_value = -sin_lookup[ 180 + (angle/conversion_factor)];
    }
	*/
	
	// handle wrap-around without division 
	if (real_angle > 180) real_angle -= 360; 
	if (real_angle < -180) real_angle += 360; 
	
	int sin_value; 
	
	if (real_angle >= 0 && real_angle <= 90) 
	{ 
		sin_value = (int)sin_lookup[real_angle];
	} 
	else if(real_angle > 90 && real_angle <= 180) 
	{
		sin_value = (int)sin_lookup[180 - real_angle]; 
	} 
	else if (real_angle >= -90 &&real_angle < 0) 
	{ 
		sin_value = -((int)sin_lookup[-real_angle]); 	
	} 
	else 
	{ 
		sin_value = -((int)sin_lookup[180 + real_angle]);
	}

    return sin_value;
}

void compute_offsets(int az, int el,
                     uint8_t *off_00,
                     uint8_t *off_10,
                     uint8_t *off_01,
                     uint8_t *off_11)
{
    int delta_x = (sin_fixed(az + el) + sin_fixed(az - el)) >> 1;
    int delta_y = sin_fixed(el);

    *off_00 = 0;
    *off_10 = (uint8_t)(delta_x >> 1);
    *off_01 = (uint8_t)(delta_y >> 1);
    *off_11 = (uint8_t)((delta_x + delta_y) >> 1);
}

int main()
{
    int az , el ;
    uint8_t off_00, off_10, off_01, off_11;
    uint32_t last_cmd = 0;
    uint32_t cmd;

    //print_str("PACT OK \n"); //acknoledgement of working 

    //to calculate offset values and sent it to sequencer-> phase_shifter_ic
    while(1) 
    {
        
        cmd = CMD_REG;       // update cmd
        if (cmd != last_cmd) //check for change in value 
        {
            // unpack angles from CMD_REG
            az = (int)(cmd & 0xFFFF);
            el = (int)((cmd >> 16) & 0xFFFF);

            // compute phase offsets
            compute_offsets(az, el, &off_00, &off_10, &off_01, &off_11);

            // write to offset registers
            offset_reg_00 = off_00;
            offset_reg_10 = off_10;
            offset_reg_01 = off_01;
            offset_reg_11 = off_11;

            last_cmd = cmd; //change last_cmd  to newest value 
        }
    }
    return 0;
}

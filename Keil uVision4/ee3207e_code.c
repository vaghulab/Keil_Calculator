//EE3207 Group 2
//Names : Vaghul Aditya Balaji, Ravi Theja Reddy Singannagari & Jin Qian
//Title : 4-Bit Binary Calculator

#include <REG51.H>

//Associating the variables to the LED outputs on the FPGA Board
sbit add_led = P0^0;
sbit subtract_led = P0^1;
sbit multiply_led = P0^2;
sbit divide_led = P0^3;

//Associating the variables to the capacitive touchpad inputs on the FPGA Board
sbit user_input1 = P0^4;
sbit user_input2 = P0^5;
sbit user_input3 = P0^6;

void main()
{
	//Declaration of variables to be used in the Program
	unsigned char operand1 = 0x00;
	unsigned char operand2 = 0x00;
	unsigned int input_delay1 = 0;
	unsigned int input_delay2 = 0;
	
	//Assigning initial values for the GPIO Ports
	P1 = 0x00;
	P2 = 0xFF;
	P3 = 0xFF;

	//Turning off all the LEDs on the FPGA Board
	add_led = 0;
	subtract_led = 0;
	multiply_led = 0;
	divide_led = 0;

	while(1)
	{
		//Obtaining inputs from the GPIO pins and the capacitive touchpads
		operand1 = P2;
		operand1 &= 0x0F;

		operand2 = P3;
		operand2 &= 0x0F;

		user_input1 = P0^4;
		user_input2 = P0^5;
		user_input3 = P0^6;

		//Checking whether the user wants to perform an add/subtract/multiply/divide operation
		if(user_input1 && !user_input2 && !user_input3)
		{
			add_led = 1;
			subtract_led = 0;
			multiply_led = 0;
			divide_led = 0;

			P1 = operand1 + operand2;
		}
		else
			if(!user_input1 && user_input2 && !user_input3)
			{
				add_led = 0;
				subtract_led = 1;
				multiply_led = 0;
				divide_led = 0;

				//Code executed when a larger number is subtracted from a smaller number
				if(operand2 > operand1)
					P1 = 0xFF;
				else
					P1 = operand1 - operand2;
			}
			else
				if(!user_input1 && !user_input2 && user_input3)
				{
					add_led = 0;
					subtract_led = 0;
					multiply_led = 1;
					divide_led = 0;

					P1 = operand1 * operand2;
				}
				else
					if(user_input1 && user_input2 && !user_input3)
					{
						add_led = 0;
						subtract_led = 0;
						multiply_led = 0;
						divide_led = 1;

						P1 = operand1 / operand2;

						//Software delay to stabilize the input from the user (only valid for the divide operation)
						for(input_delay1 = 0; input_delay1 < 200; input_delay1++)
							  for(input_delay2 = 0; input_delay2 < 200; input_delay2++);
					}
	}
}
//End of Program
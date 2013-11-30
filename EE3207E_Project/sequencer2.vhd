library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use work.constants.all;

entity sequencer2 is
    port(
		rst              : in  std_logic;
		clk              : in  std_logic;
		ale		         : out std_logic;
		psen		     : out std_logic;

		alu_op_code	 	 : out  std_logic_vector (3 downto 0);
		alu_src_1L		 : out  std_logic_vector (7 downto 0);
		alu_src_1H		 : out  std_logic_vector (7 downto 0);
		alu_src_2L		 : out  std_logic_vector (7 downto 0);
		alu_src_2H		 : out  std_logic_vector (7 downto 0);
		alu_by_wd		 : out  std_logic;             -- byte(0)/word(1) instruction
		alu_cy_bw		 : out  std_logic;             -- carry/borrow bit
		alu_ans_L		 : in std_logic_vector (7 downto 0);
		alu_ans_H		 : in std_logic_vector (7 downto 0);
		alu_cy		 	 : in std_logic;             -- carry out of bit 7/15
		alu_ac		 	 : in std_logic;		    -- carry out of bit 3/7
		alu_ov		 	 : in std_logic;		    -- overflow

		dividend_i		 : out  std_logic_vector(15 downto 0);
		divisor_i		 : out  std_logic_vector(15 downto 0);
		quotient_o		 : in std_logic_vector(15 downto 0); 
		remainder_o	 	 : in std_logic_vector(15 downto 0);
		div_done		 : in std_logic ;

		mul_a_i		 	 : out  std_logic_vector(15 downto 0);  -- Multiplicand
		mul_b_i		 	 : out  std_logic_vector(15 downto 0);  -- Multiplicator
		mul_prod_o 	 	 : in std_logic_vector(31 downto 0) ;-- Product

		i_ram_wrByte   	 : out std_logic; 
		i_ram_wrBit   	 : out std_logic; 
		i_ram_rdByte   	 : out std_logic; 
		i_ram_rdBit   	 : out std_logic; 
		i_ram_addr 	 	 : out std_logic_vector(7 downto 0); 
		i_ram_diByte  	 : out std_logic_vector(7 downto 0); 
		i_ram_diBit   	 : out std_logic; 
		i_ram_doByte   	 : in std_logic_vector(7 downto 0); 
		i_ram_doBit   	 : in std_logic; 
		
		i_rom_addr       : out std_logic_vector (15 downto 0);
		i_rom_data       : in  std_logic_vector (7 downto 0);
		i_rom_rd         : out std_logic;
		
		pc_debug	 	 : out std_logic_vector (15 downto 0);
		interrupt_flag	 : in  std_logic_vector (2 downto 0);
		erase_flag	     : out std_logic);

end sequencer2;

-------------------------------------------------------------------------------

architecture seq_arch of sequencer2 is

   type t_cpu_state is (T0, T1, I0); --these determine whether you are in initialisation, state, normal execution state, etc
   type t_exe_state is (E0, E1, E2, E3, E4, E5, E6, E7, E8, E9, E10, E11, E12, E13, E14, E15, E16, E17, E18, E19, E20, E21, E22, E23, E24, E25, E26, E27, E28, E29, E30, E31, E32, E33, E34, E35, E36, E37, E38, E39, E40, E41, E42, E43, E44, E45); --these are the equivalence T0, T1 in the lecture
    
	signal cpu_state 		: t_cpu_state;
	signal exe_state 		: t_exe_state;
	signal IR				: std_logic_vector(7 downto 0);		-- Instruction Register
	signal PC				: std_logic_vector(15 downto 0);	-- Program Counter
	signal AR				: std_logic_vector(7 downto 0);		-- Address Register
	signal DR				: std_logic_vector(7 downto 0);		-- Data Register
	signal int_hold			: std_logic;

begin

   process(rst, clk)
	
	procedure RD_ROM (addr: std_logic_vector(15 downto 0)) is
	begin
		i_rom_addr <= addr;
		i_rom_rd <= '1';
	end RD_ROM;
	
	procedure RD_RAM (addr: std_logic_vector(7 downto 0)) is
	begin
		i_ram_addr <= addr;
		i_ram_rdByte <= '1';
		i_ram_rdBit <= '0';
		i_ram_wrByte <= '0';
		i_ram_wrBit <= '0';
	end RD_RAM;
	
	procedure WR_RAM (addr: std_logic_vector(7 downto 0)) is
	begin
		i_ram_addr <= addr;
		i_ram_rdByte <= '0';
		i_ram_rdBit <= '0';
		i_ram_wrByte <= '1';
		i_ram_wrBit <= '0';
	end WR_RAM;
	
	procedure RD_RAM_BIT (addr: std_logic_vector(7 downto 0)) is
	begin
		i_ram_addr <= addr;
		i_ram_rdByte <= '0';
		i_ram_rdBit <= '1';
		i_ram_wrByte <= '0';
		i_ram_wrBit <= '0';
	end RD_RAM_BIT;
	
	procedure WR_RAM_BIT (addr: std_logic_vector(7 downto 0)) is
	begin	
		i_ram_addr <= addr;
		i_ram_rdByte <= '0';
		i_ram_rdBit <= '0';
		i_ram_wrByte <= '0';
		i_ram_wrBit <= '1';
	end WR_RAM_BIT;
	
	procedure RESET_S is
	begin	
		i_ram_rdByte <= '0';
		i_ram_rdBit <= '0';
		i_ram_wrByte <= '0';
		i_ram_wrBit <= '0';
	end RESET_S;
	
    begin
    if( rst = '1' ) then
		cpu_state <= T0;
		exe_state <= E0;
		ale <= '0'; psen <= '0';
		mul_a_i <= (others => '0'); mul_b_i <= (others => '0');
		dividend_i <= (others => '0'); divisor_i <= (others => '1');
		i_ram_wrByte <= '0'; i_ram_rdByte <= '0'; i_ram_wrBit <= '0'; i_ram_rdBit <= '0';
		IR <= (others => '0');
		PC <= (others => '0');
		AR <= (others => '0');
		DR <= (others => '0');
		pc_debug <= (others => '1');
		int_hold <= '0';
		erase_flag <= '0';	
		
    elsif (clk'event and clk = '1') then
	    case cpu_state is
			when T0 =>
				case exe_state is
					when E0	=>
						AR <= PC(7 downto 0);	
						RD_ROM(PC);		
						if(PC = "00000000") then
							erase_flag <= '0';
						end if;
						exe_state <= E1;		
								
					when E1	=> 	
						--i_rom_data has M[AR]
						IR <= i_rom_data;
						PC <= PC + 1;
						RESET_S;
						exe_state <= E0;
						cpu_state <= T1;

					when others =>	  
					
				end case;  

			when T1 =>
				case IR is	
				
					-- NOP
					when "00000000"  =>
						case exe_state is
							when E0	=>
								exe_state <= E1;		
								
							when E1	=> 	
								exe_state <= E2;
						
							when E2	=> 	
								exe_state <= E3;
						
							when E3	=> 	
								exe_state <= E4;	
												
							when E4	=> 	
								exe_state <= E5;
						
							when E5	=> 	
								exe_state <= E6;
												
							when E6	=> 	
								exe_state <= E7;
						
							when E7	=> 	
								exe_state <= E8;
												
							when E8	=> 	
								exe_state <= E9;
						
							when E9	=> 	
								RESET_S;
								exe_state <= E0;
								cpu_state <= T0;

							when others =>	  
									
						end case;  

				
					-- ADD A,Rn					
					when "00101000"|"00101001"|"00101010"|"00101011"|"00101100"|"00101101"|"00101110"|"00101111" =>
						case exe_state is
							when E0	=>
								--get value of PSW
								RD_RAM(xD0);
								exe_state <= E1;		
								
							when E1	=> 	
								--storing address of the register in DR
								DR <= "000" & i_ram_doByte(4 downto 3) & IR(2 downto 0);
								exe_state <= E2;
						
							when E2	=> 	
								--get value of register
								i_ram_rdByte<='0';
								RD_RAM(DR);
								exe_state <= E3;
												
							when E3	=> 	
								DR <= i_ram_doByte;
								--Get A
								i_ram_rdByte<='0';
								RD_RAM(xE0);
								exe_state <= E4;
												
							when E4	=> 	
								--ADD A and Rn
								alu_op_code <= ALU_OPC_ADD;
								alu_src_1L <= i_ram_doByte; --value of A
								alu_src_2L <= DR; 	--value of Rn
								alu_cy_bw <= '0';
								alu_by_wd <= '0';
								
								--get PSW
								RD_RAM(xD0);
								exe_state <= E5;
						
							when E5	=> 	
								--Leave one cycle for addition to take place
								exe_state <= E6;
												
							when E6	=> 	
								--store answer in A
								WR_RAM(xE0);
								i_ram_diByte <= alu_ans_L;
								exe_state <= E7;
						
							when E7	=> 	
								--Leave one cycle for value to be written in ACC
								exe_state <= E8;
												
							when E8 => 	
								i_ram_diByte <= alu_cy & alu_ac & i_ram_doByte(5 downto 3) & alu_ov & i_ram_doByte(1 downto 0);
								
								--update PSW
								WR_RAM(xD0);
								exe_state <= E9;
						
							when E9 => 	
								--done with instruction
								RESET_S;
								exe_state <= E0;
								cpu_state <= T0;

							when others =>	  
									
						end case;  
						
					
					-- ADD A,DIRECT
					when "00100101"=>
						case exe_state is
							when E0 =>
								--get address from ROM	
								RD_ROM(PC);
								--get value of A
								RD_RAM(xE0);
								exe_state <= E1;
								
							when E1=>
								PC<= PC +1;
							    --Leave one cycle to load the values
								exe_state <= E2;
								
							when E2=>
								--storing the value of A in DR
								DR <= i_ram_doByte;
								--retreiving value from the Direct Address
								RD_RAM(i_rom_data);
								exe_state <= E3;
								
							when E3 =>
							    --Leave one cycle to load value
								exe_state <= E4;
								
							when E4=>
								--To Add A and (Direct)
								alu_op_code <= ALU_OPC_ADD;
								alu_src_1L <= i_ram_doByte;
								alu_src_2L <= DR; 	
								alu_cy_bw <= '0';
								alu_by_wd <= '0';
								
								--get PSW
								RD_RAM(xD0);
								exe_state <= E5;
								
							when E5 =>
								exe_state <= E6;
								
							when E6=>
								--store answer in the A
								WR_RAM(xE0);
								i_ram_diByte <= alu_ans_L;								
								exe_state <= E7;
														
							when E7=>
								--update PSW
								i_ram_diByte <= alu_cy & alu_ac & i_ram_doByte(5 downto 3) & alu_ov & i_ram_doByte(1 downto 0);
								WR_RAM(xD0);
								exe_state<=E8;
								
							when E8 =>
								--done with instruction
								RESET_S;
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;
						
						
					--MOV A, Rn
					when "11101000" | "11101001" | "11101010" | "11101011" | "11101100" | "11101101" | "11101110" | "11101111" =>
						case exe_state is
							when E0 =>
								--load PSW
								RD_RAM(xD0);								
								exe_state <= E1;
								
							when E1 =>
								--leave one cycle to load PSW
								exe_state <= E2;
								
							when E2 =>
								--get value of Rn
								i_ram_addr <= "000" & i_ram_doByte(4 downto 3) & IR(2 downto 0);
								i_ram_rdByte <= '1';
								i_ram_rdBit <= '0';
								exe_state <= E3;
								
							when E3 =>
								--wait to get value of Rn
								exe_state <= E4;
								
							when E4 =>										
								--write to A
								WR_RAM(xE0);
								i_ram_diByte <= i_ram_doByte;
								exe_state <= E5;
								
							when E5 =>
								exe_state <= E6;
								
							when E6 =>
								exe_state <= E7;
								
							when E7 =>
								--done with instruction
								RESET_S;
								exe_state <= E8;
								
							when E8 =>
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;
						
						
					--ADD A, @Ri
					when "00100110" | "00100111" =>
						case exe_state is
							when E0 =>	
								--load PSW
								RD_RAM(xD0);								
								exe_state <= E1;		
								
							when E1 =>
								--get value of Ri
								i_ram_addr <= "000" & i_ram_doByte(4 downto 3) & "00" & IR(0);
								i_ram_rdByte <= '1';
								i_ram_rdBit <= '0';
								exe_state <= E2;
								
							when E2 =>								
								--storing (Ri) in DR
								DR <= i_ram_doByte;
								exe_state <= E3;
								
						    when E3 =>
								--get value of register
								i_ram_rdByte<='0';
								RD_RAM(DR);								
								exe_state <= E4;
								
							when E4=>
								DR <= i_ram_doByte;
								--Get A
								i_ram_rdByte <= '0';
								RD_RAM(xE0);
								exe_state <= E5;
								
							when E5 =>
								--ADD A and Ri
								alu_op_code <= ALU_OPC_ADD;
								alu_src_1L <= i_ram_doByte; --value of A
								alu_src_2L <= DR; --value of (Ri)
								alu_cy_bw <= '0';
								alu_by_wd <= '0';
							
								--get PSW
								RD_RAM(xD0);
								exe_state <=E6;
								
							when E6 =>								
								exe_state <= E7;
								
							when E7 =>
								--store answer in A
								WR_RAM(xE0);
								i_ram_diByte <= alu_ans_L;
								exe_state <= E8;
								
							when E8 =>
								i_ram_diByte <= alu_cy & alu_ac & i_ram_doByte(5 downto 3) & alu_ov & i_ram_doByte(1 downto 0);
								
								--update PSW
								WR_RAM(xD0);																			
								exe_state<=E9;
								
							when E9=>	
								--done with instruction
								RESET_S;
								exe_state <= E0;
								cpu_state <= T0;
							
							when others =>
							
						end case;	
					

					--ADD A, #DATA
					when "00100100" =>
						case exe_state is
							when E0 =>								
								--get value of A
								RD_RAM(xE0);
								
								--get #DATA
								RD_ROM(PC);								
								exe_state <= E1;
								
							when E1 =>
								PC <= PC + 1;
								--leave one cycle to load A and #DATA
								exe_state <= E2;
								
							when E2 =>
								--ADD A and #DATA
								alu_op_code <= ALU_OPC_ADD;
								alu_src_1L <= i_ram_doByte; --value of A
								alu_src_2L <= i_rom_data; --value of #DATA
								alu_cy_bw <= '0';
								alu_by_wd <= '0';
								
								--get PSW
								RD_RAM(xD0);								
								exe_state <= E3;
								
							when E3 =>
								exe_state <= E4;
								
							when E4 =>
								--store answer in A
								WR_RAM(xE0);
								i_ram_diByte <= alu_ans_L;								
								exe_state <= E5;
								
							when E5 =>
								exe_state <= E6;		
								
							when E6 =>
								--update PSW
								WR_RAM(xD0);
								i_ram_diByte <= alu_cy & alu_ac & i_ram_doByte(5 downto 3) & alu_ov & i_ram_doByte(1 downto 0);								
								exe_state <= E7;
								
							when E7 =>							
								exe_state <= E8;
								
							when E8 =>
								RESET_S;
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;
					
					
					--ADDC A, Rn
					when "00111000"|"00111001"|"00111010"|"00111011"|"00111100"|"00111101"|"00111110"|"00111111" =>
						case exe_state is
							when E0	=>
								--get value of PSW
								RD_RAM(xD0);
								exe_state <= E1;		
								
							when E1	=> 	
								--storing address of the register in DR
								DR <= "000" & i_ram_doByte(4 downto 3) & IR(2 downto 0);
								AR <= i_ram_doByte;
								exe_state <= E2;
						
							when E2	=> 	
								--get value of register
								i_ram_rdByte<='0';
								RD_RAM(DR);
								exe_state <= E3;
																		
							when E3	=> 	
								DR<= i_ram_doByte;
								--Get A
								i_ram_rdByte<='0';
								RD_RAM(xE0);
								exe_state <= E4;
						
							when E4	=> 	
								--Leave one cycle for A to load
								exe_state <= E5;
												
							when E5	=> 	
								--ADD A and Rn
								alu_op_code <= ALU_OPC_ADC;
								alu_src_1L <= i_ram_doByte; --value of A
								alu_src_2L <= DR; 	--value of Rn
								alu_cy_bw <= AR(7);
								alu_by_wd <= '0';
								
								exe_state <= E6;
						
							when E6	=> 	
								--Leave one cycle for addition to take place
								exe_state <= E7;
												
							when E7	=> 	
								--store answer in A
								WR_RAM(xE0);
								i_ram_diByte <= alu_ans_L;
								exe_state <= E8;
												
							when E8	=> 	
								i_ram_diByte <= alu_cy & alu_ac & AR(5 downto 3) & alu_ov & AR(1 downto 0);
								
								--update PSW
								WR_RAM(xD0);
								exe_state <= E9;
						
							when E9	=> 	
								--done with instruction
								RESET_S;
								exe_state <= E0;
								cpu_state <= T0;

							when others =>	  
									
						end case; 
					
					
					-- ADDC A,DIRECT
					when "00110101"=>
						case exe_state is
							when E0 =>
								--get address from ROM	
								RD_ROM(PC);
								
								--get value of A
								RD_RAM(xE0);
								exe_state <= E1;
								
							when E1=>
								PC<= PC +1;
							    --Leave one cycle to load the values
								exe_state <=E2;
								
							when E2=>
								--storing the value of A in DR
								DR<=i_ram_doByte;
								
								--retreiving value from the Direct Address
								RD_RAM(i_rom_data);
								exe_state <=E3;
								
							when E3=>
								--Storing the value stored in the ROM Address
								AR <= i_ram_doByte;
								
								--get PSW
								RD_RAM(xD0);								
								exe_state <=E4;
								
							when E4 =>			
								--Leave one cycle to load value														
								exe_state <=E5;
								
							when E5 => 
								--To Add A and (Direct)
								alu_op_code <= ALU_OPC_ADC;
								alu_src_1L <= AR; --(Direct)
								alu_src_2L <= DR; --A
								alu_cy_bw <= i_ram_doByte(7);
								alu_by_wd <= '0';
								
								exe_state<=E6;
								
							when E6=>							
								exe_state<=E7;
								
							when E7 =>
								--store answer in the A
								WR_RAM(xE0);
								i_ram_diByte <= alu_ans_L;							
								exe_state<=E8;
								
							when E8=>
								--update PSW
								i_ram_diByte <= alu_cy & alu_ac & i_ram_doByte(5 downto 3) & alu_ov & i_ram_doByte(1 downto 0);
								WR_RAM(xD0);
							    exe_state <= E9;
								
							when E9 => 
								RESET_S; 
								exe_state <= E0;
								cpu_state <= T0;								

							when others =>
							
						end case;
					
					
					--ADDC A, @Ri
					when "00110110" | "00110111" =>
						case exe_state is
							when E0 =>	
								--load PSW
								RD_RAM(xD0);								
								exe_state <= E1;		
								
							when E1 =>
								--get value of Ri
								i_ram_addr <= "000" & i_ram_doByte(4 downto 3) & "00" & IR(0);
								i_ram_rdByte <= '1';
								i_ram_rdBit <= '0';
								AR <= i_ram_doByte;
								exe_state <= E2;
								
							when E2 =>								
								--storing (Ri) in DR
								DR <= i_ram_doByte;
								exe_state <= E3;
								
						    when E3 =>
								--get value of register
								i_ram_rdByte<='0';
								RD_RAM(DR);								
								exe_state <= E4;
								
							when E4=>
								DR <= i_ram_doByte;
								--Get A
								i_ram_rdByte <= '0';
								RD_RAM(xE0);
								exe_state <= E5;
								
							when E5 =>
								--ADD A and Ri
								alu_op_code <= ALU_OPC_ADC;
								alu_src_1L <= i_ram_doByte; --value of A
								alu_src_2L <= DR; --value of (Ri)
								alu_cy_bw <= AR(7);
								alu_by_wd <= '0';
							
								exe_state <=E6;
								
							when E6 =>								
								exe_state <= E7;
								
							when E7 =>
								--store answer in A
								WR_RAM(xE0);
								i_ram_diByte <= alu_ans_L;
								exe_state <= E8;
								
							when E8 =>
								i_ram_diByte <= alu_cy & alu_ac & AR(5 downto 3) & alu_ov & AR(1 downto 0);
								
								--update PSW
								WR_RAM(xD0);																			
								exe_state<=E9;
								
							when E9=>	
								--done with instruction
								RESET_S;
								exe_state <= E0;
								cpu_state <= T0;
							
							when others =>
							
						end case;					
					
					
					--ADDC A, #DATA
					when "00110100" =>
						case exe_state is
							when E0 =>
								--get value of A
								RD_RAM(xE0);
								
								--get #DATA
								RD_ROM(PC);								
								exe_state <= E1;
								
							when E1 =>
								PC <= PC + 1;
								--leave one cycle to load A and #DATA
								exe_state <= E2;
								
							when E2 =>
								--storing the value of A in DR
								DR <= i_ram_doByte;
								
								--get PSW
								RD_RAM(xD0);								
								exe_state <= E3;
								
							when E3=>
								--leave one cycle to load PSW
								exe_state <= E4;
								
							when E4=>
								--ADD A and #DATA
								alu_op_code <= ALU_OPC_ADC;
								alu_src_1L <= DR; --value of A
								alu_src_2L <= i_rom_data; --value of #DATA
								alu_cy_bw <= i_ram_doByte(7);
								alu_by_wd <= '0';
																										
								exe_state <= E5;
								
							when E5 =>
								exe_state <= E6;
								
							when E6=>
								--store answer in A
								WR_RAM(xE0);
								i_ram_diByte <= alu_ans_L;								
								exe_state <= E7;
								
							when E7 =>
								exe_state <= E8;
								
							when E8 =>
								--update PSW
								WR_RAM(xD0);
								i_ram_diByte <= alu_cy & alu_ac & i_ram_doByte(5 downto 3) & alu_ov & i_ram_doByte(1 downto 0);								
								exe_state <= E9;
								
							when E9 =>
								RESET_S;
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;
					
					
					--SUBB A, Rn
					when "10011000"|"10011001"|"10011010"|"10011011"|"10011100"|"10011101"|"10011110"|"10011111"=>
						case exe_state is
							when E0	=>
								--get value of PSW
								RD_RAM(xD0);
								exe_state <= E1;		
								
							when E1	=> 	
								--storing address of the register in DR
								DR <= "000" & i_ram_doByte(4 downto 3) & IR(2 downto 0);
								AR <= i_ram_doByte;
								exe_state <= E2;
						
							when E2	=> 	
								--get value of register
								i_ram_rdByte<='0';
								RD_RAM(DR);
								exe_state <= E3;
												
							when E3	=> 	
								DR<= i_ram_doByte;
								--Get A
								i_ram_rdByte<='0';
								RD_RAM(xE0);
								exe_state <= E4;
						
							when E4	=> 	
								--Leave one cycle for A to load
								exe_state <= E5;
												
							when E5	=> 	
								--Subtract Rn from A
								alu_op_code <= ALU_OPC_SBB;
								alu_src_1L <= i_ram_doByte; --value of A
								alu_src_2L <= DR; --value of Rn
								alu_cy_bw <= AR(7);
								alu_by_wd <= '0';
								
								exe_state <= E6;
						
							when E6	=> 	
								--Leave one cycle for addition to take place
								exe_state <= E7;
												
							when E7	=> 	
								--store answer in A
								WR_RAM(xE0);
								i_ram_diByte <= alu_ans_L;
								exe_state <= E8;
												
							when E8 => 	
								i_ram_diByte <= alu_cy & alu_ac & AR(5 downto 3) & alu_ov & AR(1 downto 0);
								
								--update PSW
								WR_RAM(xD0);
								exe_state <= E9;
						
							when E9 => 	
								--done with instruction
								RESET_S;
								exe_state <= E0;
								cpu_state <= T0;

							when others =>	  
									
						end case;
						
						
					--SUBB A, @Ri
					when "10010110"|"10010111"=>
						case exe_state is
							when E0 =>	
								--load PSW
								RD_RAM(xD0);								
								exe_state <= E1;		
								
							when E1 =>
								--get value of Ri
								i_ram_addr <= "000" & i_ram_doByte(4 downto 3) & "00" & IR(0);
								i_ram_rdByte <= '1';
								i_ram_rdBit <= '0';
								AR <= i_ram_doByte;
								exe_state <= E2;
								
							when E2 =>								
								--storing (Ri) in DR
								DR <= i_ram_doByte;
								exe_state <= E3;
								
						    when E3 =>
								--get value of register
								i_ram_rdByte<='0';
								RD_RAM(DR);								
								exe_state <= E4;
								
							when E4=>
								DR <= i_ram_doByte;
								--Get A
								i_ram_rdByte <= '0';
								RD_RAM(xE0);
								exe_state <= E5;
								
							when E5 =>
								--Subtract ((Ri)) from A
								alu_op_code <= ALU_OPC_SBB;
								alu_src_1L <= i_ram_doByte; --value of A
								alu_src_2L <= DR; --value of (Ri)
								alu_cy_bw <= AR(7);
								alu_by_wd <= '0';
							
								exe_state <=E6;
								
							when E6 =>								
								exe_state <= E7;
								
							when E7 =>
								--store answer in A
								WR_RAM(xE0);
								i_ram_diByte <= alu_ans_L;
								exe_state <= E8;
								
							when E8 =>
								i_ram_diByte <= alu_cy & alu_ac & AR(5 downto 3) & alu_ov & AR(1 downto 0);
								
								--update PSW
								WR_RAM(xD0);																			
								exe_state <= E9;
								
							when E9 =>	
								--done with instruction
								RESET_S;
								exe_state <= E0;
								cpu_state <= T0;
							
							when others =>
							
						end case;						
						
						
					--SUBB A, #DATA
					when "10010100" =>
						case exe_state is
							when E0 =>
								--get value of A
								RD_RAM(xE0);
								
								--get #DATA
								RD_ROM(PC);								
								exe_state <= E1;
								
							when E1 =>
								PC <= PC + 1;
								--leave one cycle to load A and #DATA
								exe_state <= E2;
								
							when E2 =>
								--storing the value of A in DR
								DR <= i_ram_doByte;
								
								--get PSW
								RD_RAM(xD0);								
								exe_state <= E3;
								
							when E3=>
								--leave one cycle to load PSW
								exe_state <= E4;
								
							when E4=>
								--Subtract #DATA from A
								alu_op_code <= ALU_OPC_SBB;
								alu_src_1L <= DR; --value of A
								alu_src_2L <= i_rom_data; --value of #DATA
								alu_cy_bw <= i_ram_doByte(7);
								alu_by_wd <= '0';
																										
								exe_state <= E5;
								
							when E5 =>
								exe_state <= E6;
								
							when E6=>
								--store answer in A
								WR_RAM(xE0);
								i_ram_diByte <= alu_ans_L;								
								exe_state <= E7;
								
							when E7 =>
								exe_state <= E8;
								
							when E8 =>
								--update PSW
								WR_RAM(xD0);
								i_ram_diByte <= alu_cy & alu_ac & i_ram_doByte(5 downto 3) & alu_ov & i_ram_doByte(1 downto 0);								
								exe_state <= E9;
								
							when E9 =>
								RESET_S;
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;	
						

					-- SUBB A,DIRECT
					when "10010101" =>
						case exe_state is
							when E0 =>
								--get address from ROM	
								RD_ROM(PC);
								
								--get value of A
								RD_RAM(xE0);
								exe_state <= E1;
								
							when E1=>
								PC<= PC +1;
							    --Leave one cycle to load the values
								exe_state <=E2;
								
							when E2=>
								--storing the value of A in DR
								DR <= i_ram_doByte;
								
								--retreiving value from the Direct Address
								RD_RAM(i_rom_data);
								exe_state <=E3;
								
							when E3=>
								--Storing the value stored in the ROM Address
								AR <= i_ram_doByte;
								
								--get PSW
								RD_RAM(xD0);								
								exe_state <=E4;
								
							when E4 =>			
								--Leave one cycle to load value														
								exe_state <=E5;
								
							when E5 => 
								--Subtract (Direct) from A
								alu_op_code <= ALU_OPC_SBB;
								alu_src_1L <= DR; --A
								alu_src_2L <= AR; --(Direct)
								alu_cy_bw <= i_ram_doByte(7);
								alu_by_wd <= '0';
								
								exe_state<=E6;
								
							when E6=>							
								exe_state<=E7;
								
							when E7 =>
								--store answer in the A
								WR_RAM(xE0);
								i_ram_diByte <= alu_ans_L;							
								exe_state<=E8;
								
							when E8=>
								--update PSW
								i_ram_diByte <= alu_cy & alu_ac & i_ram_doByte(5 downto 3) & alu_ov & i_ram_doByte(1 downto 0);
								WR_RAM(xD0);
							    exe_state <= E9;
								
							when E9 => 
								RESET_S; 
								exe_state <= E0;
								cpu_state <= T0;								

							when others =>
							
						end case;						
						
					
					-- INC A
					when "00000100"=>
						case exe_state is
							when E0 =>
								--get value of A
								RD_RAM(xE0);								
								exe_state<=E1;
								
							when E1=>
								--leave one cycle to load A				
								exe_state <=E2;
								
							when E2=>							   
								--To Add one to A
								alu_op_code <= ALU_OPC_INC;
								alu_src_1L <= i_ram_doByte; --A
								alu_cy_bw <= '0';
								alu_by_wd <= '0';																
								
								exe_state <=E3;
								
							when E3 =>							
								exe_state <=E4;
								
							when E4 => 
								exe_state <= E5;
								
							when E5 =>
								--store answer in A
								WR_RAM(xE0);
								i_ram_diByte <= alu_ans_L;								
								exe_state <= E6;
								
							when E6 =>
								exe_state <= E7;
								
							when E7 =>
								--done with instruction
								RESET_S;
								exe_state <= E8;
								
							when E8 =>
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;

						
					-- INC Rn
					when "00001000"|"00001001"|"00001010"|"00001011"|"00001100"|"00001101"|"00001110"|"00001111"=>
						case exe_state is
							when E0 =>							
								--get value of PSW
								RD_RAM(xD0);								
								exe_state <= E1;
								
							when E1=>
								--leave one cycle to load PSW				
								exe_state <= E2;
								
							when E2=>
								--storing address of the register in DR
								i_ram_rdByte <='0';
								DR <= "000" & i_ram_doByte(4 downto 3) & IR(2 downto 0);
								RD_RAM("000" & i_ram_doByte(4 downto 3) & IR(2 downto 0));								
							    exe_state <= E3;
							   
							when E3=>
								--Leave one cycle to load the value of the register
								exe_state <= E4;
								
							when E4=>										
								--To Add one to Rn
								alu_op_code <= ALU_OPC_INC;
								alu_src_1L <= i_ram_doByte; --Rn	
								alu_cy_bw <= '0';
								alu_by_wd <= '0';
																
								exe_state <=E5;
								
							when E5 =>								
								exe_state <=E6;
								
							when E6 => 
								--store answer in Rn
								WR_RAM(DR);
								i_ram_diByte <= alu_ans_L;
								exe_state <= E7;
								
							when E7 =>								
								exe_state <= E8;
								
							when E8 =>
								--done with instruction
								RESET_S;
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;			
						
					
					-- INC DIRECT
					when "00000101"=>
						case exe_state is
							when E0 =>
								--get address from ROM	
								RD_ROM(PC);
								exe_state <= E1;
								
							when E1=>
								PC <= PC +1;
							    --Leave one cycle to load address
								exe_state <= E2;
								
							when E2=>
								--storing address in DR
								DR <= i_rom_data;								
								RD_RAM(i_rom_data);
								exe_state <= E3;
								
							when E3 =>
							   --Leave one cycle to load value
								exe_state <=E4;
								
							when E4=>
								--To Add one to the value stored in the address
								alu_op_code <= ALU_OPC_INC;
								alu_src_1L <= i_ram_doByte; --(DIRECT)
								alu_cy_bw <= '0';
								alu_by_wd <= '0';
								
								exe_state <=E5;
								
							when E5 =>															
								exe_state <=E6;
								
							when E6 => 
								--store answer in the address
								WR_RAM(DR);
								i_ram_diByte <= alu_ans_L;
								exe_state <= E7;
								
							when E7 =>								
								exe_state <= E8;
								
							when E8 =>
								RESET_S;
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;
						
						
					-- INC @Ri
					when "00000110"|"00000111"=>
						case exe_state is
							when E0 =>	
								--load PSW
								RD_RAM(xD0);								
								exe_state <= E1;		
								
							when E1 =>
								--get value of Ri
								i_ram_addr <= "000" & i_ram_doByte(4 downto 3) & "00" & IR(0);
								i_ram_rdByte <= '1';
								i_ram_rdBit <= '0';
								exe_state <= E2;
								
							when E2 =>								
								--storing (Ri) in DR
								DR <= i_ram_doByte;
								exe_state <= E3;
								
						    when E3 =>
								--get value of register
								i_ram_rdByte<='0';
								RD_RAM(DR);								
								exe_state <= E4;
								
							when E4=>
								i_ram_rdByte <= '0';
								exe_state <= E5;
								
							when E5 =>								
								exe_state<= E6;
								
							when E6 =>
								--To add one to the value stored in Ri
								alu_op_code <= ALU_OPC_INC;
								alu_src_1L <= i_ram_doByte; --value of Ri
								alu_cy_bw <= '0';
								alu_by_wd <= '0';
							
								exe_state <=E7;
								
							when E7 =>								
								exe_state <= E8;
								
							when E8 =>
								--store answer in (Ri)
								WR_RAM(DR);
								i_ram_diByte <= alu_ans_L;
								exe_state <= E9;
								
							when E9 =>	
								--done with instruction
								RESET_S;
								exe_state <= E0;
								cpu_state <= T0;
							
							when others =>
							
						end case;	
						
					
					-- DEC A
					when "00010100"=>
						case exe_state is
							when E0 =>
								--get value of A
								RD_RAM(xE0);								
								exe_state<=E1;
								
							when E1=>
								--leave one cycle to load A				
								exe_state <=E2;
								
							when E2=>							   
								--To Decrement A
								alu_op_code <= ALU_OPC_DEC;
								alu_src_1L <= i_ram_doByte; --A
								alu_cy_bw <= '0';
								alu_by_wd <= '0';																
								
								exe_state <=E3;
								
							when E3 =>							
								exe_state <=E4;
								
							when E4 => 
								exe_state <= E5;
								
							when E5 =>
								--store answer in A
								WR_RAM(xE0);
								i_ram_diByte <= alu_ans_L;								
								exe_state <= E6;
								
							when E6 =>
								exe_state <= E7;
								
							when E7 =>
								--done with instruction
								RESET_S;
								exe_state <= E8;
								
							when E8 =>
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;

						
					-- DEC Rn
					when "00011000"|"00011001"|"00011010"|"00011011"|"00011100"|"00011101"|"00011110"|"00011111"=>
						case exe_state is
							when E0 =>							
								--get value of PSW
								RD_RAM(xD0);								
								exe_state <= E1;
								
							when E1=>
								--leave one cycle to load PSW				
								exe_state <= E2;
								
							when E2=>
								--storing address of the register in DR
								i_ram_rdByte <='0';
								DR <= "000" & i_ram_doByte(4 downto 3) & IR(2 downto 0);
								RD_RAM("000" & i_ram_doByte(4 downto 3) & IR(2 downto 0));								
							    exe_state <= E3;
							   
							when E3=>
								--Leave one cycle to load the value of the register
								exe_state <= E4;
								
							when E4=>										
								--To Decrement Rn
								alu_op_code <= ALU_OPC_DEC;
								alu_src_1L <= i_ram_doByte; --Rn	
								alu_cy_bw <= '0';
								alu_by_wd <= '0';
																
								exe_state <=E5;
								
							when E5 =>								
								exe_state <=E6;
								
							when E6 => 
								--store answer in Rn
								WR_RAM(DR);
								i_ram_diByte <= alu_ans_L;
								exe_state <= E7;
								
							when E7 =>								
								exe_state <= E8;
								
							when E8 =>
								--done with instruction
								RESET_S;
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;			
						
					
					-- DEC DIRECT
					when "00010101"=>
						case exe_state is
							when E0 =>
								--get address from ROM	
								RD_ROM(PC);
								exe_state <= E1;
								
							when E1=>
								PC <= PC +1;
							    --Leave one cycle to load address
								exe_state <= E2;
								
							when E2=>
								--storing address in DR
								DR <= i_rom_data;								
								RD_RAM(i_rom_data);
								exe_state <= E3;
								
							when E3 =>
							   --Leave one cycle to load value
								exe_state <=E4;
								
							when E4=>
								--To Decrement the value stored in the address
								alu_op_code <= ALU_OPC_DEC;
								alu_src_1L <= i_ram_doByte; --(DIRECT)
								alu_cy_bw <= '0';
								alu_by_wd <= '0';
								
								exe_state <=E5;
								
							when E5 =>															
								exe_state <=E6;
								
							when E6 => 
								--store answer in the address
								WR_RAM(DR);
								i_ram_diByte <= alu_ans_L;
								exe_state <= E7;
								
							when E7 =>								
								exe_state <= E8;
								
							when E8 =>
								RESET_S;
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;
						
						
					-- DEC @Ri
					when "00010110"|"00010111"=>
						case exe_state is
							when E0 =>	
								--load PSW
								RD_RAM(xD0);								
								exe_state <= E1;		
								
							when E1 =>
								--get value of Ri
								i_ram_addr <= "000" & i_ram_doByte(4 downto 3) & "00" & IR(0);
								i_ram_rdByte <= '1';
								i_ram_rdBit <= '0';
								exe_state <= E2;
								
							when E2 =>								
								--storing (Ri) in DR
								DR <= i_ram_doByte;
								exe_state <= E3;
								
						    when E3 =>
								--get value of register
								i_ram_rdByte<='0';
								RD_RAM(DR);								
								exe_state <= E4;
								
							when E4=>
								i_ram_rdByte <= '0';
								exe_state <= E5;
								
							when E5 =>								
								exe_state<= E6;
								
							when E6 =>
								--To Decrement the value stored in Ri
								alu_op_code <= ALU_OPC_DEC;
								alu_src_1L <= i_ram_doByte; --value of Ri
								alu_cy_bw <= '0';
								alu_by_wd <= '0';
							
								exe_state <=E7;
								
							when E7 =>								
								exe_state <= E8;
								
							when E8 =>
								--store answer in (Ri)
								WR_RAM(DR);
								i_ram_diByte <= alu_ans_L;
								exe_state <= E9;
								
							when E9 =>	
								--done with instruction
								RESET_S;
								exe_state <= E0;
								cpu_state <= T0;
							
							when others =>
							
						end case;	

					
					--INC DPTR
					when "10100011"=>
						case exe_state is
							when E0=>
								--Get Lower Byte (DPL)
								RD_RAM(x82);
								exe_state <= E1;
								
							when E1=>
								--Leave one cycle to load data
								exe_state <= E2;
								
							when E2=>
								--Increment the lower byte of the DATA PTR								
								alu_op_code <= ALU_OPC_INC;
								alu_src_1L <= i_ram_doByte; 	
								alu_cy_bw <= '0';
								alu_by_wd <= '0';
								
								--Get higher Byte (DPH)
								RD_RAM(x83);
								
								exe_state <= E3;
								
							when E3=>
								--Leave one cycle to load data
								exe_state <= E4;
								
							when E4=>
								--incrementing the upper byte if the lower byte has a carry
								if(alu_ans_L = "00000000") then 
									alu_op_code <= ALU_OPC_INC;
									alu_src_1L <= i_ram_doByte; 	
									alu_cy_bw <= '0';
									alu_by_wd <= '0';
									int_hold<='1';
								else
									int_hold<='0';
								end if;
								
								--Writing the result into DPL
								WR_RAM(x82);
								i_ram_diByte <= alu_ans_L;
								exe_state <= E5;
								
							when E5=>
								--Leave one cycle to load the answer/write data
								exe_state<=E6;
								
							when E6=>
								--Writing the result into DPH
								if(int_hold='1') then
									WR_RAM(x83);
									i_ram_diByte <= alu_ans_L;									
								end if;
								exe_state<=E7;
								
							when E7=> 
								exe_state <= E8;
								
							when E8 => 
								exe_state <= E9;
								
							when E9 => 
								RESET_S;
								exe_state <= E10;
								
							when E10 => 
								exe_state <= E11;
								
							when E11 => 
								exe_state <= E12;
								
							when E12 => 
								exe_state <= E13;
								
							when E13 => 
								exe_state <= E14;
								
							when E14 => 
								exe_state <= E15;
								
							when E15 => 
								exe_state <= E16;
								
							when E16 => 
								exe_state <= E17;
								
							when E17 => 
								exe_state <= E18;
								
							when E18 => 
								exe_state <= E19;
								
							when E19 => 
								exe_state <= E20;
								
							when E20 => 
								exe_state <= E21;
								
							when E21 => 
								--done with instruction
								exe_state <= E0;
								cpu_state <= T0;
								
							when others=>
							
						end case;
					
					
					--MUL AB
					when "10100100" =>
						case exe_state is
							when E0=>
								--Get the value of Register B
								RD_RAM(xF0);								
								exe_state <= E1;
								
							when E1=>
								--Leave one cycle to load Register B								
								exe_state <= E2;
								
							when E2=>
								DR <= i_ram_doByte;
								RD_RAM(xE0);								
								exe_state <= E3;
								
							when E3 =>
								--Leave one cycle to load A					
								exe_state <= E4;
								
							when E4 =>
								--Multiply A by B
								mul_a_i <= "00000000" & i_ram_doByte; --A
								mul_b_i <= "00000000" & DR; --B
								
								--Read PSW
								RD_RAM(xD0);								
								exe_state<=E5;
								
							when E5=>							
								exe_state <= E6;
								
							when E6=>
								exe_state <= E7;
								
							when E7=> 							
								exe_state <= E8;
								
							when E8 =>							
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E10;
								
							when E10 =>
								exe_state <= E11;
								
							when E11 =>
								exe_state <= E12;
								
							when E12 => 
								exe_state <= E13;
								
							when E13 => 
								exe_state <= E14;
								
							when E14 => 
								exe_state <= E15;
								
							when E15 => 
								exe_state <= E16;
								
							when E16 => 
								exe_state <= E17;
								
							when E17 => 
								exe_state <= E18;
								
							when E18 => 
								exe_state <= E19;
								
							when E19 => 
								exe_state <= E20;
								
							when E20 => 
								exe_state <= E21;
								
							when E21 => 
								exe_state <= E22;
								
							when E22 => 
								exe_state <= E23;
								
							when E23 => 
								exe_state <= E24;
								
							when E24 => 
								exe_state <= E25;
								
							when E25 => 
								exe_state <= E26;
								
							when E26 => 
								exe_state <= E27;
								
							when E27 => 
								exe_state <= E28;
								
							when E28 => 
								exe_state <= E29;
								
							when E29 => 
								exe_state <= E30;
								
							when E30 => 
								exe_state <= E31;
													
							when E31 => 
								exe_state <= E32;
								
							when E32 => 
								exe_state <= E33;
								
							when E33 => 
								exe_state <= E34;
								
							when E34 => 
								exe_state <= E35;
								
							when E35 => 
								exe_state <= E36;
								
							when E36 => 
								exe_state <= E37;
								
							when E37 => 
								exe_state <= E38;
								
							when E38 => 
								exe_state <= E39;
								
							when E39 => 
								--write bits 15 to 8 in B
								i_ram_diByte <= mul_prod_o(15 downto 8);
								WR_RAM(xF0);
								
								DR <= mul_prod_o(15 downto 8);
								AR <= i_ram_doByte;
								exe_state <= E40;
								
							when E40 => 
								exe_state <= E41;
								
							when E41 => 
								--Write bits 8 to 0 in A
								WR_RAM(xE0);
								i_ram_diByte <= mul_prod_o(7 downto 0);	
								exe_state <= E42;
								
							when E42 => 
								exe_state <= E43;
								
							when E43 => 
								--update PSW with appropriate OV flag
								if(DR /= "00000000") then 
									i_ram_diByte <= "00" & AR(5 downto 3) & '1' & AR(1 downto 0);
									WR_RAM(xD0);
								else
									i_ram_diByte <= "00" & AR(5 downto 3) & '0' & AR(1 downto 0);
									WR_RAM(xD0);							
								end if;
								
								exe_state <= E44;
								
							when E44 => 
								RESET_S;
								exe_state <= E45;
								
							when E45 => 
								--done with instruction
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;
					
					
					--DIV AB
					when "10000100" =>
						case exe_state is
							when E0=>
								--Get the value of Register B
								RD_RAM(xF0);								
								exe_state <= E1;
								
							when E1=>
								--Leave one cycle to load Register B								
								exe_state <= E2;
								
							when E2=>
								DR <= i_ram_doByte;
								--Get A
								RD_RAM(xE0);								
								exe_state <= E3;
								
							when E3 =>
								--Leave one cycle to load A							
								exe_state <= E4;
								
							when E4 =>
								--Divide A by B
								dividend_i <= "00000000" & i_ram_doByte; --A
								divisor_i <= "00000000" & DR; --B
								
								--Read PSW
								RD_RAM(xD0);									
								exe_state <= E5;
								
							when E5=>							
								exe_state <= E6;
								
							when E6=>
								AR <= i_ram_doByte;								
								exe_state <= E7;
								
							when E7 =>
								exe_state <= E8;
							
							when E8 =>
								exe_state <= E9;
								
							when E9=> 
								--update PSW with appropriate OV flag
								if(DR = "00000000") then 
									i_ram_diByte <= "00" & AR(5 downto 3) & '1' & AR(1 downto 0);
									WR_RAM(xD0);
								else
									i_ram_diByte <= "00" & AR(5 downto 3) & '0' & AR(1 downto 0);
									WR_RAM(xD0);										
								end if;
								exe_state <= E10;
								
							when E10 =>							
								exe_state <= E11;
								
							when E11 =>							
								exe_state <= E12;
								
							when E12 =>
								exe_state <= E13;
								
							when E13 =>							
								exe_state <= E14;
								
							when E14=>
								exe_state <= E15;
								
							when E15 =>
								exe_state <= E16;
								
							when E16=>
								exe_state <= E17;
								
							when E17 =>
								exe_state <= E18;
								
							when E18=>
								exe_state <= E19;
								
							when E19 =>
								exe_state <= E20;
								
							when E20=>
								exe_state <= E21;
								
							when E21 =>
								exe_state<= E22;
								
							when E22=>
								exe_state<= E23;
								
							when E23 => 
								exe_state <= E24;
								
							when E24 => 
								exe_state <= E25;
								
							when E25 => 
								exe_state <= E26;
								
							when E26 => 
								exe_state <= E27;
								
							when E27 => 
								exe_state <= E28;
								
							when E28 => 
								exe_state <= E29;
								
							when E29 => 
								exe_state <= E30;
								
							when E30 => 
								exe_state <= E31;
													
							when E31 => 
								exe_state <= E32;
								
							when E32 => 
								exe_state <= E33;
								
							when E33 => 
								exe_state <= E34;
								
							when E34 => 
								exe_state <= E35;
								
							when E35 => 
								exe_state <= E36;
								
							when E36 => 
								exe_state <= E37;
								
							when E37 => 
								exe_state <= E38;
								
							when E38 => 
								exe_state <= E39;
								
							when E39 => 
								exe_state <= E40;
								
							when E40 => 
								exe_state <= E41;
								
							when E41 => 
								i_ram_diByte <= quotient_o(7 downto 0);
								WR_RAM(xE0);	
								exe_state <= E42;
								
							when E42 => 
								exe_state <= E43;
								
							when E43 => 
								i_ram_diByte <= remainder_o(7 downto 0);
								WR_RAM(xF0);	
								exe_state <= E44;
								
							when E44 => 
								exe_state <= E45;
								
							when E45 => 
								--done with instruction
								RESET_S;
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;					
					
					
					--ANL A, Rn
					when "01011000" | "01011001" | "01011010" | "01011011" | "01011100" | "01011101" | "01011110" | "01011111" =>
						case exe_state is 
							when E0 =>
								--get PSW
								RD_RAM(xD0);								
								exe_state <= E1;
								
							when E1 =>
								exe_state <= E2;
								
							when E2 =>
								--get (Rn)
								i_ram_addr <= "000" & i_ram_doByte(4 downto 3) & IR(2 downto 0);
								i_ram_rdByte <= '1';								
								exe_state <= E3;
								
							when E3 =>
								exe_state <= E4;
								
							when E4 =>
								--store (Rn) in DR
								DR <= i_ram_doByte;
								
								--get ACC
								RD_RAM(xE0);								
								exe_state <= E5;
								
							when E5 =>
								exe_state <= E6;
								
							when E6 =>
								alu_op_code <= ALU_OPC_AND;
								alu_src_1L <= i_ram_doByte;
								alu_src_2L <= DR;
								alu_by_wd <= '0';
								
								exe_state <= E7;
								
							when E7 =>								
								exe_state <= E8;
								
							when E8 =>
								WR_RAM(xE0);
								i_ram_diByte <= alu_ans_L;
								exe_state <= E9;
								
							when E9 =>
								RESET_S;
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;
					
					
					--ANL A, direct
					when "01010101" =>
						case exe_state is
							when E0 =>
								--get direct
								RD_ROM(PC);
								--get ACC
								RD_RAM(xE0);
								
								exe_state <= E1;
								
							when E1 =>
								PC <= PC + 1;
								exe_state <= E2;
								
							when E2 =>
								--get (direct)
								RD_RAM(i_rom_data);
								--store ACC in DR
								DR <= i_ram_doByte;
								
								exe_state <= E3;
								
							when E3 =>
								exe_state <= E4;
								
							when E4 =>
								exe_state <= E5;
								
							when E5 =>
								alu_op_code <= ALU_OPC_AND;
								alu_src_1L <= DR;
								alu_src_2L <= i_ram_doByte;
								alu_by_wd <= '0';
								
								exe_state <= E6;
								
							when E6 =>							
								exe_state <= E7;
								
							when E7 =>
								WR_RAM(xE0);
								i_ram_diByte <= alu_ans_L;									
								exe_state <= E8;
								
							when E8 =>
								exe_state <= E9;
								
							when E9 =>
								RESET_S;
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;
					
					
					--ANL A, @Ri
					when "01010110" | "01010111" =>
						case exe_state is
							when E0 =>	
								--load PSW
								RD_RAM(xD0);								
								exe_state <= E1;		
								
							when E1 =>
								--get value of Ri
								i_ram_addr <= "000" & i_ram_doByte(4 downto 3) & "00" & IR(0);
								i_ram_rdByte <= '1';
								i_ram_rdBit <= '0';
								exe_state <= E2;
								
							when E2 =>								
								--storing (Ri) in DR
								DR <= i_ram_doByte;
								exe_state <= E3;
								
						    when E3 =>
								--get value of register
								i_ram_rdByte<='0';
								RD_RAM(DR);								
								exe_state <= E4;
								
							when E4=>
								DR <= i_ram_doByte;
								--Get A
								i_ram_rdByte <= '0';
								RD_RAM(xE0);
								exe_state <= E5;
								
							when E5 =>
								--Leave one cycle for A to load
								exe_state<= E6;
								
							when E6 =>
								--AND A and Ri
								alu_op_code <= ALU_OPC_AND;
								alu_src_1L <= i_ram_doByte; --value of A
								alu_src_2L <= DR; --value of (Ri)
								alu_by_wd <= '0';

								exe_state <=E7;
								
							when E7 =>								
								exe_state <= E8;
								
							when E8 =>
								--store answer in A
								WR_RAM(xE0);
								i_ram_diByte <= alu_ans_L;
								exe_state <= E9;
								
							when E9=>	
								--done with instruction
								RESET_S;
								exe_state <= E0;
								cpu_state <= T0;
							
							when others =>
							
						end case;	
					
					
					--ANL A, #DATA
					when "01010100" =>
						case exe_state is 
							when E0 =>
								--get #DATA
								RD_ROM(PC);
								
								--get ACC
								RD_RAM(xE0);
								
								exe_state <= E1;
								
							when E1 =>
								PC <= PC + 1;
								exe_state <= E2;
								
							when E2 =>
								alu_op_code <= ALU_OPC_AND;
								alu_src_1L <= i_ram_doByte;
								alu_src_2L <= i_rom_data;
								alu_by_wd <= '0';
								
								exe_state <= E3;
								
							when E3 =>								
								exe_state <= E4;
								
							when E4 =>
								WR_RAM(xE0);
								i_ram_diByte <= alu_ans_L;
								exe_state <= E5;
								
							when E5 =>
								exe_state <= E6;
								
							when E6 =>
								exe_state <= E7;
								
							when E7 =>
								RESET_S;
								exe_state <= E8;
								
							when E8 =>
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case; 
					
					
					--ANL direct, A
					when "01010010" =>
						case exe_state is
							when E0 =>
								--get direct
								RD_ROM(PC);
								--get ACC
								RD_RAM(xE0);
								
								exe_state <= E1;
								
							when E1 =>
								PC <= PC + 1;
								exe_state <= E2;
								
							when E2 =>
								--get (direct)
								RD_RAM(i_rom_data);
								
								--store ACC in DR
								DR <= i_ram_doByte;
								
								--store direct in AR
								AR <= i_rom_data;
								
								exe_state <= E3;
								
							when E3 =>
								exe_state <= E4;
								
							when E4 =>
								exe_state <= E5;
								
							when E5 =>
								alu_op_code <= ALU_OPC_AND;
								alu_src_1L <= DR;
								alu_src_2L <= i_ram_doByte;
								alu_by_wd <= '0';
								
								exe_state <= E6;
								
							when E6 =>							
								exe_state <= E7;
								
							when E7 =>
								WR_RAM(AR);
								i_ram_diByte <= alu_ans_L;									
								exe_state <= E8;
								
							when E8 =>
								RESET_S;
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;
					
					
					--ANL direct, #DATA
					when "01010011" =>
						case exe_state is
							when E0 =>
								--get direct
								RD_ROM(PC);								
								exe_state <= E1;
								
							when E1 =>
								PC <= PC + 1;
								exe_state <= E2;
								
							when E2 =>	
								--get (direct)
								RD_RAM(i_rom_data);
								
								--store direct in DR
								DR <= i_rom_data;
								
								--get #DATA
								RD_ROM(PC);
								
								exe_state <= E3;
								
							when E3 =>
								PC <= PC + 1;
								exe_state <= E4;
								
							when E4 =>
								alu_op_code <= ALU_OPC_AND;
								alu_src_1L <= i_rom_data;
								alu_src_2L <= i_ram_doByte;
								alu_by_wd <= '0';
								
								exe_state <= E5;
								
							when E5 =>
								exe_state <= E6;
								
							when E6 =>
								--write to direct
								WR_RAM(DR);
								i_ram_diByte <= alu_ans_L;
								exe_state <= E7;
								
							when E7 =>
								exe_state <= E8;
								
							when E8 =>
								exe_state <= E9;
								
							when E9 =>
								RESET_S;
								exe_state <= E10;
								
							when E10 =>
								exe_state <= E11;
								
							when E11 =>
								exe_state <= E12;
								
							when E12 => 
								exe_state <= E13;
								
							when E13 => 
								exe_state <= E14;
								
							when E14 => 
								exe_state <= E15;
								
							when E15 => 
								exe_state <= E16;
								
							when E16 => 
								exe_state <= E17;
								
							when E17 => 
								exe_state <= E18;
								
							when E18 => 
								exe_state <= E19;
								
							when E19 => 
								exe_state <= E20;
								
							when E20 => 
								exe_state <= E21;
								
							when E21 => 
								--done with instruction
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;
					
					
					--ORL A, Rn
					when  "01001000"|"01001001"|"01001010"|"01001011"|"01001100"|"01001101"|"01001110"|"01001111"=>
						case exe_state is 
							when E0 =>
								--get PSW
								RD_RAM(xD0);								
								exe_state <= E1;
								
							when E1 =>
								exe_state <= E2;
								
							when E2 =>
								--get (Rn)
								i_ram_addr <= "000" & i_ram_doByte(4 downto 3) & IR(2 downto 0);
								i_ram_rdByte <= '1';								
								exe_state <= E3;
								
							when E3 =>
								exe_state <= E4;
								
							when E4 =>
								--store (Rn) in DR
								DR <= i_ram_doByte;
								
								--get ACC
								RD_RAM(xE0);								
								exe_state <= E5;
								
							when E5 =>
								exe_state <= E6;
								
							when E6 =>
								alu_op_code <= ALU_OPC_OR;
								alu_src_1L <= i_ram_doByte;
								alu_src_2L <= DR;
								alu_by_wd <= '0';
								
								exe_state <= E7;
								
							when E7 =>								
								exe_state <= E8;
								
							when E8 =>
								WR_RAM(xE0);
								i_ram_diByte <= alu_ans_L;
								exe_state <= E9;
								
							when E9 =>
								RESET_S;
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;
					
					
					--ORL A, direct
					when  "01000101"=>
						case exe_state is
							when E0 =>
								--get direct
								RD_ROM(PC);
								--get ACC
								RD_RAM(xE0);
								
								exe_state <= E1;
								
							when E1 =>
								PC <= PC + 1;
								exe_state <= E2;
								
							when E2 =>
								--get (direct)
								RD_RAM(i_rom_data);
								--store ACC in DR
								DR <= i_ram_doByte;
								
								exe_state <= E3;
								
							when E3 =>
								exe_state <= E4;
								
							when E4 =>
								exe_state <= E5;
								
							when E5 =>
								alu_op_code <= ALU_OPC_OR;
								alu_src_1L <= DR;
								alu_src_2L <= i_ram_doByte;
								alu_by_wd <= '0';
								
								exe_state <= E6;
								
							when E6 =>							
								exe_state <= E7;
								
							when E7 =>
								WR_RAM(xE0);
								i_ram_diByte <= alu_ans_L;									
								exe_state <= E8;
								
							when E8 =>
								exe_state <= E9;
								
							when E9 =>
								RESET_S;
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;
					
					
					--ORL A, @Ri
					when  "01000110"|"01000111"=>
						case exe_state is
							when E0 =>	
								--load PSW
								RD_RAM(xD0);								
								exe_state <= E1;		
								
							when E1 =>
								--get value of Ri
								i_ram_addr <= "000" & i_ram_doByte(4 downto 3) & "00" & IR(0);
								i_ram_rdByte <= '1';
								i_ram_rdBit <= '0';
								exe_state <= E2;
								
							when E2 =>								
								--storing (Ri) in DR
								DR <= i_ram_doByte;
								exe_state <= E3;
								
						    when E3 =>
								--get value of register
								i_ram_rdByte<='0';
								RD_RAM(DR);								
								exe_state <= E4;
								
							when E4=>
								DR <= i_ram_doByte;
								--Get A
								i_ram_rdByte <= '0';
								RD_RAM(xE0);
								exe_state <= E5;
								
							when E5 =>
								--Leave one cycle for A to load
								exe_state<= E6;
								
							when E6 =>
								--OR A and Ri
								alu_op_code <= ALU_OPC_OR;
								alu_src_1L <= i_ram_doByte; --value of A
								alu_src_2L <= DR; --value of (Ri)
								alu_by_wd <= '0';

								exe_state <=E7;
								
							when E7 =>								
								exe_state <= E8;
								
							when E8 =>
								--store answer in A
								WR_RAM(xE0);
								i_ram_diByte <= alu_ans_L;
								exe_state <= E9;
								
							when E9=>	
								--done with instruction
								RESET_S;
								exe_state <= E0;
								cpu_state <= T0;
							
							when others =>
							
						end case;	
					
					
					--ORL A, #DATA
					when "01000100" =>
						case exe_state is 
							when E0 =>
								--get #DATA
								RD_ROM(PC);
								
								--get ACC
								RD_RAM(xE0);
								
								exe_state <= E1;
								
							when E1 =>
								PC <= PC + 1;
								exe_state <= E2;
								
							when E2 =>
								alu_op_code <= ALU_OPC_OR;
								alu_src_1L <= i_ram_doByte;
								alu_src_2L <= i_rom_data;
								alu_by_wd <= '0';
								
								exe_state <= E3;
								
							when E3 =>								
								exe_state <= E4;
								
							when E4 =>
								WR_RAM(xE0);
								i_ram_diByte <= alu_ans_L;
								exe_state <= E5;
								
							when E5 =>
								exe_state <= E6;
								
							when E6 =>
								exe_state <= E7;
								
							when E7 =>
								RESET_S;
								exe_state <= E8;
								
							when E8 =>
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case; 
					
					
					--ORL direct, A
					when  "01000010"=>
						case exe_state is
							when E0 =>
								--get direct
								RD_ROM(PC);
								--get ACC
								RD_RAM(xE0);
								
								exe_state <= E1;
								
							when E1 =>
								PC <= PC + 1;
								exe_state <= E2;
								
							when E2 =>
								--get (direct)
								RD_RAM(i_rom_data);
								
								--store ACC in DR
								DR <= i_ram_doByte;
								
								--store direct in AR
								AR <= i_rom_data;
								
								exe_state <= E3;
								
							when E3 =>
								exe_state <= E4;
								
							when E4 =>
								exe_state <= E5;
								
							when E5 =>
								alu_op_code <= ALU_OPC_OR;
								alu_src_1L <= DR;
								alu_src_2L <= i_ram_doByte;
								alu_by_wd <= '0';
								
								exe_state <= E6;
								
							when E6 =>							
								exe_state <= E7;
								
							when E7 =>
								WR_RAM(AR);
								i_ram_diByte <= alu_ans_L;									
								exe_state <= E8;
								
							when E8 =>
								RESET_S;
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;
					
					
					--ORL direct, #DATA
					when  "01000011"=>
						case exe_state is
							when E0 =>
								--get direct
								RD_ROM(PC);								
								exe_state <= E1;
								
							when E1 =>
								PC <= PC + 1;
								exe_state <= E2;
								
							when E2 =>	
								--get (direct)
								RD_RAM(i_rom_data);
								
								--store direct in DR
								DR <= i_rom_data;
								
								--get #DATA
								RD_ROM(PC);
								
								exe_state <= E3;
								
							when E3 =>
								PC <= PC + 1;
								exe_state <= E4;
								
							when E4 =>
								alu_op_code <= ALU_OPC_OR;
								alu_src_1L <= i_rom_data;
								alu_src_2L <= i_ram_doByte;
								alu_by_wd <= '0';
								
								exe_state <= E5;
								
							when E5 =>
								exe_state <= E6;
								
							when E6 =>
								--write to direct
								WR_RAM(DR);
								i_ram_diByte <= alu_ans_L;
								exe_state <= E7;
								
							when E7 =>
								exe_state <= E8;
								
							when E8 =>
								exe_state <= E9;
								
							when E9 =>
								RESET_S;
								exe_state <= E10;
								
							when E10 =>
								exe_state <= E11;
								
							when E11 =>
								exe_state <= E12;
								
							when E12 => 
								exe_state <= E13;
								
							when E13 => 
								exe_state <= E14;
								
							when E14 => 
								exe_state <= E15;
								
							when E15 => 
								exe_state <= E16;
								
							when E16 => 
								exe_state <= E17;
								
							when E17 => 
								exe_state <= E18;
								
							when E18 => 
								exe_state <= E19;
								
							when E19 => 
								exe_state <= E20;
								
							when E20 => 
								exe_state <= E21;
								
							when E21 => 
								--done with instruction
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;				
					
					
					--XRL A, Rn
					when  "01101000"|"01101001"|"01101010"|"01101011"|"01101100"|"01101101"|"01101110"|"01101111"=>
						case exe_state is 
							when E0 =>
								--get PSW
								RD_RAM(xD0);								
								exe_state <= E1;
								
							when E1 =>
								exe_state <= E2;
								
							when E2 =>
								--get (Rn)
								i_ram_addr <= "000" & i_ram_doByte(4 downto 3) & IR(2 downto 0);
								i_ram_rdByte <= '1';								
								exe_state <= E3;
								
							when E3 =>
								exe_state <= E4;
								
							when E4 =>
								--store (Rn) in DR
								DR <= i_ram_doByte;
								
								--get ACC
								RD_RAM(xE0);								
								exe_state <= E5;
								
							when E5 =>
								exe_state <= E6;
								
							when E6 =>
								alu_op_code <= ALU_OPC_XOR;
								alu_src_1L <= i_ram_doByte;
								alu_src_2L <= DR;
								alu_by_wd <= '0';
								
								exe_state <= E7;
								
							when E7 =>								
								exe_state <= E8;
								
							when E8 =>
								WR_RAM(xE0);
								i_ram_diByte <= alu_ans_L;
								exe_state <= E9;
								
							when E9 =>
								RESET_S;
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;
					
					
					--XRL A, direct
					when  "01100101"=>
						case exe_state is
							when E0 =>
								--get direct
								RD_ROM(PC);
								--get ACC
								RD_RAM(xE0);
								
								exe_state <= E1;
								
							when E1 =>
								PC <= PC + 1;
								exe_state <= E2;
								
							when E2 =>
								--get (direct)
								RD_RAM(i_rom_data);
								--store ACC in DR
								DR <= i_ram_doByte;
								
								exe_state <= E3;
								
							when E3 =>
								exe_state <= E4;
								
							when E4 =>
								exe_state <= E5;
								
							when E5 =>
								alu_op_code <= ALU_OPC_XOR;
								alu_src_1L <= DR;
								alu_src_2L <= i_ram_doByte;
								alu_by_wd <= '0';
								
								exe_state <= E6;
								
							when E6 =>							
								exe_state <= E7;
								
							when E7 =>
								WR_RAM(xE0);
								i_ram_diByte <= alu_ans_L;									
								exe_state <= E8;
								
							when E8 =>
								exe_state <= E9;
								
							when E9 =>
								RESET_S;
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;
					
					
					--XRL A, @Ri
					when  "01100110"|"01100111"=>
						case exe_state is
							when E0 =>	
								--load PSW
								RD_RAM(xD0);								
								exe_state <= E1;		
								
							when E1 =>
								--get value of Ri
								i_ram_addr <= "000" & i_ram_doByte(4 downto 3) & "00" & IR(0);
								i_ram_rdByte <= '1';
								i_ram_rdBit <= '0';
								exe_state <= E2;
								
							when E2 =>								
								--storing (Ri) in DR
								DR <= i_ram_doByte;
								exe_state <= E3;
								
						    when E3 =>
								--get value of register
								i_ram_rdByte<='0';
								RD_RAM(DR);								
								exe_state <= E4;
								
							when E4=>
								DR <= i_ram_doByte;
								--Get A
								i_ram_rdByte <= '0';
								RD_RAM(xE0);
								exe_state <= E5;
								
							when E5 =>
								--Leave one cycle for A to load
								exe_state<= E6;
								
							when E6 =>
								--XOR A and Ri
								alu_op_code <= ALU_OPC_XOR;
								alu_src_1L <= i_ram_doByte; --value of A
								alu_src_2L <= DR; --value of (Ri)
								alu_by_wd <= '0';

								exe_state <=E7;
								
							when E7 =>								
								exe_state <= E8;
								
							when E8 =>
								--store answer in A
								WR_RAM(xE0);
								i_ram_diByte <= alu_ans_L;
								exe_state <= E9;
								
							when E9=>	
								--done with instruction
								RESET_S;
								exe_state <= E0;
								cpu_state <= T0;
							
							when others =>
							
						end case;
					
					
					--XRL A, #DATA
					when "01100100" =>
						case exe_state is 
							when E0 =>
								--get #DATA
								RD_ROM(PC);
								
								--get ACC
								RD_RAM(xE0);
								
								exe_state <= E1;
								
							when E1 =>
								PC <= PC + 1;
								exe_state <= E2;
								
							when E2 =>
								alu_op_code <= ALU_OPC_XOR;
								alu_src_1L <= i_ram_doByte;
								alu_src_2L <= i_rom_data;
								alu_by_wd <= '0';
								
								exe_state <= E3;
								
							when E3 =>								
								exe_state <= E4;
								
							when E4 =>
								WR_RAM(xE0);
								i_ram_diByte <= alu_ans_L;
								exe_state <= E5;
								
							when E5 =>
								exe_state <= E6;
								
							when E6 =>
								exe_state <= E7;
								
							when E7 =>
								RESET_S;
								exe_state <= E8;
								
							when E8 =>
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case; 
					
					
					--XRL direct, A
					when  "01100010"=>
						case exe_state is
							when E0 =>
								--get direct
								RD_ROM(PC);
								--get ACC
								RD_RAM(xE0);
								
								exe_state <= E1;
								
							when E1 =>
								PC <= PC + 1;
								exe_state <= E2;
								
							when E2 =>
								--get (direct)
								RD_RAM(i_rom_data);
								
								--store ACC in DR
								DR <= i_ram_doByte;
								
								--store direct in AR
								AR <= i_rom_data;
								
								exe_state <= E3;
								
							when E3 =>
								exe_state <= E4;
								
							when E4 =>
								exe_state <= E5;
								
							when E5 =>
								alu_op_code <= ALU_OPC_XOR;
								alu_src_1L <= DR;
								alu_src_2L <= i_ram_doByte;
								alu_by_wd <= '0';
								
								exe_state <= E6;
								
							when E6 =>							
								exe_state <= E7;
								
							when E7 =>
								WR_RAM(AR);
								i_ram_diByte <= alu_ans_L;									
								exe_state <= E8;
								
							when E8 =>
								RESET_S;
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;
					
					
					--XRL direct, #DATA
					when  "01100011"=>
						case exe_state is
							when E0 =>
								--get direct
								RD_ROM(PC);								
								exe_state <= E1;
								
							when E1 =>
								PC <= PC + 1;
								exe_state <= E2;
								
							when E2 =>	
								--get (direct)
								RD_RAM(i_rom_data);
								
								--store direct in DR
								DR <= i_rom_data;
								
								--get #DATA
								RD_ROM(PC);
								
								exe_state <= E3;
								
							when E3 =>
								PC <= PC + 1;
								exe_state <= E4;
								
							when E4 =>
								alu_op_code <= ALU_OPC_XOR;
								alu_src_1L <= i_rom_data;
								alu_src_2L <= i_ram_doByte;
								alu_by_wd <= '0';
								
								exe_state <= E5;
								
							when E5 =>
								exe_state <= E6;
								
							when E6 =>
								--write to direct
								WR_RAM(DR);
								i_ram_diByte <= alu_ans_L;
								exe_state <= E7;
								
							when E7 =>
								exe_state <= E8;
								
							when E8 =>
								exe_state <= E9;
								
							when E9 =>
								RESET_S;
								exe_state <= E10;
								
							when E10 =>
								exe_state <= E11;
								
							when E11 =>
								exe_state <= E12;
								
							when E12 => 
								exe_state <= E13;
								
							when E13 => 
								exe_state <= E14;
								
							when E14 => 
								exe_state <= E15;
								
							when E15 => 
								exe_state <= E16;
								
							when E16 => 
								exe_state <= E17;
								
							when E17 => 
								exe_state <= E18;
								
							when E18 => 
								exe_state <= E19;
								
							when E19 => 
								exe_state <= E20;
								
							when E20 => 
								exe_state <= E21;
								
							when E21 => 
								--done with instruction
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;
					
					
					--DA A
					when "11010100"=>
						case exe_state is
							when E0 =>	
								--load A
								RD_RAM(xE0);								
								exe_state <= E1;		
								
							when E1 =>
								--storing A in DR
								DR <= i_ram_doByte;
								i_ram_rdByte <= '1';
								
								--load PSW
								RD_RAM(xD0);								
								exe_state <= E2;
								
							when E2 =>								
								--storing PSW in AR
								AR <= i_ram_doByte;
								exe_state <= E3;
								
						    when E3 =>	
								int_hold <= '0';
								
								if (AR(6) = '1' OR DR(3 downto 0) > "1001") then
									alu_op_code <= ALU_OPC_ADD;
									alu_src_1L <= "0000" & DR(3 downto 0);
									alu_src_2L <= "00000110";
									alu_cy_bw <= '0';
									alu_by_wd <= '0';
									int_hold <= '1';
								end if;	
														
								exe_state <= E4;
								
							when E4 =>
								if (int_hold = '1') then
									DR <= DR(7 downto 4) & alu_ans_L(3 downto 0);
									AR <= "0000000" & alu_ac;
									alu_op_code <= ALU_OPC_OR;
									alu_src_1L <= "0000000" & i_ram_doByte(7);
									alu_src_2L <= AR;
									alu_cy_bw <= '0';
									alu_by_wd <= '0';
								else 
									AR <= "00000000";
									alu_op_code <= ALU_OPC_OR;
									alu_src_1L <= "0000000" & i_ram_doByte(7);
									alu_src_2L <= AR;
									alu_cy_bw <= '0';
									alu_by_wd <= '0';									
								end if;
								
								exe_state<= E5;
								
							when E5 =>		
								int_hold <= '0';					
							
								if (AR(0) = '1' OR DR(7 downto 4) > "1001") then
									alu_op_code <= ALU_OPC_ADC;
									alu_src_1L <= "0000" & DR(7 downto 4);
									alu_src_2L <= "00000110";
									alu_cy_bw <= AR(0);
									alu_by_wd <= '0';
									int_hold <= '1';
								end if;	
								
								AR <= "0000000" & alu_ans_L(0);
							
								exe_state <= E6;
								
							when E6 =>
								exe_state <= E7;
								
							when E7 =>
								--store answer in A
								WR_RAM(xE0);
								
								if(int_hold = '1') then
									i_ram_diByte <= alu_ans_L(3 downto 0) & DR(3 downto 0);								
									alu_op_code <= ALU_OPC_OR;
									alu_src_1L <= AR;
									alu_src_2L <= "0000000" & alu_ac;
									alu_cy_bw <= '0';
									alu_by_wd <= '0';
								else
									i_ram_diByte <= DR;
									alu_op_code <= ALU_OPC_OR;
									alu_src_1L <= AR;
									alu_src_2L <= "00000000";
									alu_cy_bw <= '0';
									alu_by_wd <= '0';
								end if;
								
								exe_state <= E8;
								
							when E8 =>
								i_ram_diByte <= alu_ans_L(0) & i_ram_doByte(6 downto 0);
								
								--update PSW
								WR_RAM(xD0);																			
								exe_state <= E9;
								
							when E9 =>	
								--done with instruction
								RESET_S;
								exe_state <= E0;
								cpu_state <= T0;
							
							when others =>
							
						end case;							
					
					
					--CLR A
					when "11100100" =>
						case exe_state is 
							when E0 =>
								WR_RAM(xE0);
								i_ram_diByte <= (others => '0');
								exe_state <= E1;
								
							when E1 =>
								exe_state <= E2;
								
							when E2 =>
								exe_state <= E3;
								
							when E3 =>
								exe_state <= E4;
								
							when E4 =>
								exe_state <= E5;
								
							when E5 =>
								exe_state <= E6;
								
							when E6 =>
								exe_state <= E7;
								
							when E7 =>
								RESET_S;
								exe_state <= E8;
								
							when E8 =>
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;
					
					
					--CPL A
					when "11110100" =>
						case exe_state is
							when E0 =>
								--get ACC
								RD_RAM(xE0);
								exe_state <= E1;
								
							when E1 =>
								--leave one cycle to get ACC
								exe_state <= E2;
								
							when E2 =>	
								alu_op_code <= ALU_OPC_NOT;
								alu_src_1L <= i_ram_doByte;
								alu_by_wd <= '0';
								exe_state <= E3;
								
							when E3 =>
								exe_state <= E4;
								
							when E4 =>
								WR_RAM(xE0);
								i_ram_diByte <= alu_ans_L;
								exe_state <= E5;
								
							when E5 =>
								exe_state <= E6;
								
							when E6 =>
								exe_state <= E7;
								
							when E7 =>
								RESET_S;
								exe_state <= E8;
								
							when E8 =>
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;
					
					
					--RL A
					when "00100011" =>
						case exe_state is
							when E0 =>
								--get ACC
								RD_RAM(xE0);
								exe_state <= E1;
								
							when E1 =>
								--leave one cycle to get ACC
								exe_state <= E2;
								
							when E2 =>	
								WR_RAM(xE0);
								i_ram_diByte <= i_ram_doByte(6 downto 0) & i_ram_doByte(7);
								exe_state <= E3;
								
							when E3 =>
								exe_state <= E4;
								
							when E4 =>
								exe_state <= E5;
								
							when E5 =>
								exe_state <= E6;
								
							when E6 =>
								exe_state <= E7;
								
							when E7 =>
								RESET_S;
								exe_state <= E8;
								
							when E8 =>
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;	
					
					
					--RLC A
					when "00110011" =>
						case exe_state is
							when E0 =>
								--get ACC
								RD_RAM(xE0);
								exe_state <= E1;
								
							when E1 =>
								--leave one cycle to get ACC
								exe_state <= E2;
								
							when E2 =>	
								DR <= i_ram_doByte;
								exe_state <= E3;
								
							when E3 =>
								-- read PSW bit 
								-- address of bit is xD7
								RD_RAM_BIT("11010111");
								exe_state <= E4;
								
							when E4 =>
								--leave one cycle to get PSW bit
								exe_state <= E5;
								
							when E5 =>
								WR_RAM(xE0);
								i_ram_diByte <= DR(6 downto 0) & i_ram_doBit;
								exe_state <= E6;
								
							when E6 =>
								-- wait for ACC to get updated
								exe_state <= E7;
								
							when E7 =>
								-- bit adddress xD7
								WR_RAM_BIT("11010111");								
								i_ram_diBit <= DR(7);
								
								exe_state <= E8;
								
							when E8 =>
								-- wait for carry flag to get updated
								exe_state <= E9;
								
							when E9 =>
								RESET_S;
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;
					
					
					--RR A
					when "00000011" =>
						case exe_state is
							when E0 =>
								--get ACC
								RD_RAM(xE0);
								exe_state <= E1;
								
							when E1 =>
								--leave one cycle to get ACC
								exe_state <= E2;
								
							when E2 =>	
								WR_RAM(xE0);
								i_ram_diByte <= i_ram_doByte(0) & i_ram_doByte(7 downto 1);
								exe_state <= E3;
								
							when E3 =>
								exe_state <= E4;
								
							when E4 =>
								exe_state <= E5;
								
							when E5 =>
								exe_state <= E6;
								
							when E6 =>
								exe_state <= E7;
								
							when E7 =>
								RESET_S;
								exe_state <= E8;
								
							when E8 =>
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;	
					
					
					--RRC A
					when "00010011" =>
						case exe_state is
							when E0 =>
								--get ACC
								RD_RAM(xE0);
								exe_state <= E1;
								
							when E1 =>
								--leave one cycle to get ACC
								exe_state <= E2;
								
							when E2 =>	
								DR <= i_ram_doByte;
								exe_state <= E3;
								
							when E3 =>
								-- read PSW bit 
								-- address of bit is xD7
								RD_RAM_BIT("11010111");
								exe_state <= E4;
								
							when E4 =>
								--leave one cycle to get PSW bit
								exe_state <= E5;
								
							when E5 =>
								WR_RAM(xE0);
								i_ram_diByte <= i_ram_doBit & DR(7 downto 1);
								exe_state <= E6;
								
							when E6 =>
								-- wait for ACC to get updated
								exe_state <= E7;
								
							when E7 =>
								WR_RAM_BIT("11010111");
								i_ram_diBit <= DR(0);
								exe_state <= E8;
								
							when E8 =>
								-- wait for carry flag to get updated
								exe_state <= E9;
								
							when E9 =>
								RESET_S;
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;
					
					
					-- SWAP A
					when "11000100" =>
						case exe_state is
							when E0 =>
								--get ACC
								RD_RAM(xE0);
								exe_state <= E1;
								
							when E1 =>
								--leave one cycle to get ACC
								exe_state <= E2;
								
							when E2 =>	
								WR_RAM(xE0);
								i_ram_diByte <= i_ram_doByte(3 downto 0) & i_ram_doByte(7 downto 4);
								exe_state <= E3;
								
							when E3 =>
								--wait for ACC to be updated
								exe_state <= E4;
								
							when E4 =>
								exe_state <= E5;
								
							when E5 =>
								exe_state <= E6;
								
							when E6 =>
								exe_state <= E7;
								
							when E7 =>
								RESET_S;
								exe_state <= E8;
								
							when E8 =>
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;
					
					
					-- MOV A,direct
					-- The next instruction in ROM contains the direct address. We make use of PC which points to the next instruction.
					when  "11100101" =>
						case exe_state is 
							when E0 =>
								--get direct address
								RD_ROM(PC);
								exe_state <= E1;
								
							when E1 =>
								--leave one cycle to load direct address
								PC <= PC + 1;
								exe_state <= E2;
								
							when E2 =>
								--get value of direct address
								RD_RAM(i_rom_data);
								exe_state <= E3;
								
							when E3 =>
								--wait to get value of direct address
								exe_state <= E4;
								
							when E4=>
								--write to A
								WR_RAM(xE0);
								i_ram_diByte <= i_ram_doByte;
								
								exe_state <= E5;
								
							when E5 =>
								exe_state <= E6;
								
							when E6 =>
								exe_state <= E7;
								
							when E7 =>
								RESET_S;
								exe_state <= E8;
								
							when E8 =>
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;
					
					
					-- MOV A,@Ri
					when "11100110" | "11100111" =>
						case exe_state is
							when E0 =>
								--A <- ((Ri));							
								--get psw
								RD_RAM(xD0);							
								exe_state <= E1;
								
							when E1 =>
								--leave one cycle to get PSW
								exe_state <= E2;
								
							when E2 =>
								--get addr of Ri
								RD_RAM("000" & i_ram_doByte(4 downto 3) & "00" & IR(0));
								exe_state <= E3;
								
							when E3 =>
								--leave one cycle for getting addr of Ri
								exe_state <= E4;
								
							when E4 =>
								--get value of address inside Ri
								RD_RAM(i_ram_doByte);	
								exe_state <= E5;
								
							when E5 =>
								--leave one cycle for getting value of address inside Ri
								exe_state <= E6;
								
							when E6 =>
								--write to A
								WR_RAM(xE0);
								i_ram_diByte <= i_ram_doByte;													
								exe_state <= E7;
								
							when E7 =>
								RESET_S;
								exe_state <= E8;
								
							when E8 =>
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;
								
						
					-- MOV A,#data
					-- The next instruction in ROM contains the #data. We make use of PC which points to the next instruction.
					when "01110100" =>
						case exe_state is 
							when E0 =>
								--get #data
								RD_ROM(PC);
								exe_state <= E1;
								
							when E1 =>
								--leave one cycle to load #data
								PC <= PC + 1;
								exe_state <= E2;
								
							when E2 =>
								--write to A
								WR_RAM(xE0);								
								i_ram_diByte <= i_rom_data;
								exe_state <= E3;
								
							when E3 =>
								exe_state <= E4;
								
							when E4=>
								exe_state <= E5;
								
							when E5 =>
								exe_state<= E6;
								
							when E6 =>
								exe_state <=E7;
								
							when E7 =>
								RESET_S;
								exe_state <= E8;
								
							when E8 =>
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;
					
					
					-- MOV Rn,A
					when  "11111000" | "11111001" | "11111010" | "11111011" | "11111100" | "11111101" | "11111110" | "11111111" =>
						case exe_state is 
							when E0 =>
								--get value of A
								RD_RAM(xE0);
								exe_state <= E1;
								
							when E1 =>
								--leave one cycle to load A
								exe_state <= E2;
								
							when E2 =>
								DR <= i_ram_doByte;
								--get value of PSW
								RD_RAM(xD0);
								
								exe_state <= E3;
								
							when E3 =>
								--wait to get value
								exe_state <= E4;
								
							when E4=>
								--get address of Rn and write value of A stored in DR to Rn.
								WR_RAM("000" & i_ram_doByte(4 downto 3) & IR(2 downto 0));
								i_ram_diByte <= DR;
								exe_state <= E5;
								
							when E5 =>
								--wait to update value of Rn
								exe_state<= E6;
								
							when E6 =>
								exe_state <=E7;
								
							when E7 =>
								RESET_S;
								exe_state <= E8;
								
							when E8 =>
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;
					
					
					-- MOV Rn,direct
					-- The next instruction in ROM contains the direct address. We make use of PC which points to the next instruction.
					when  "10101000" | "10101001" | "10101010" | "10101011" | "10101100" | "10101101" | "10101110" | "10101111" =>
						case exe_state is 
							when E0 =>
								--get direct address
								RD_ROM(PC);
								exe_state <= E1;
								
							when E1 =>
								--leave one cycle to load direct address
								PC <= PC + 1;
								exe_state <= E2;
								
							when E2 =>
								--get value of direct address
								RD_RAM(i_rom_data);
								exe_state <= E3;
								
							when E3 =>
								--wait to get value of direct address
								exe_state <= E4;
								
							when E4=>
								DR <= i_ram_doByte;
								--get value of PSW							
								RD_RAM(xD0);
								exe_state <= E5;
								
							when E5 =>
								--wait to get value of PSW
								exe_state <= E6;
								
							when E6 =>
								--write DR to Rn
								WR_RAM("000" & i_ram_doByte(4 downto 3) & IR(2 downto 0));
								i_ram_diByte <= DR;
								exe_state <= E7;
								
							when E7 =>
								RESET_S;
								exe_state <= E8;
								
							when E8 =>
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E10;
								
							when E10 =>
								exe_state <= E11;
								
							when E11 =>
								exe_state <= E12;
								
							when E12 => 
								exe_state <= E13;
								
							when E13 => 
								exe_state <= E14;
								
							when E14 => 
								exe_state <= E15;
								
							when E15 => 
								exe_state <= E16;
								
							when E16 => 
								exe_state <= E17;
								
							when E17 => 
								exe_state <= E18;
								
							when E18 => 
								exe_state <= E19;
								
							when E19 => 
								exe_state <= E20;
								
							when E20 => 
								exe_state <= E21;
								
							when E21 => 
								--done with instruction
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;
					
					
					-- MOV Rn,#data
					-- The next instruction in ROM contains the #data. We make use of PC which points to the next instruction.
					when  "01111000" | "01111001" | "01111010" | "01111011" | "01111100" | "01111101" | "01111110" | "01111111" =>
						case exe_state is 
							when E0 =>
								--get #data
								RD_ROM(PC);
								exe_state <= E1;
								
							when E1 =>
								--leave one cycle to load #data
								PC <= PC + 1;
								exe_state <= E2;
								
							when E2 =>
								--get value of PSW							
								RD_RAM(xD0);
								exe_state <= E3;
								
							when E3 =>
								--wait to get value of PSW
								exe_state <= E4;
								
							when E4=>
								--write #data to Rn
								WR_RAM("000" & i_ram_doByte(4 downto 3) & IR(2 downto 0));
								i_ram_diByte <= i_rom_data;
								exe_state <= E5;
								
							when E5 =>
								--wait for Rn to be updated 
								exe_state <= E6;
								
							when E6 =>							
								exe_state <= E7;
								
							when E7 =>
								RESET_S;
								exe_state <= E8;
								
							when E8 =>
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;
					
					
					-- MOV direct,A
					-- The next instruction in ROM contains the direct address. We make use of PC which points to the next instruction.
					when "11110101" =>
						case exe_state is 
							when E0 =>
								--get direct address
								RD_ROM(PC);
								--get value of A
								RD_RAM(xE0);
								exe_state <= E1;
								
							when E1 =>
								--leave one cycle to load direct address
								PC <= PC + 1;
								exe_state <= E2;
								
							when E2 =>
								--write value of A to direct address
								WR_RAM(i_rom_data);
								i_ram_diByte <= i_ram_doByte;							
								exe_state <= E3;
								
							when E3 =>
								exe_state <= E4;
								
							when E4=>							
								exe_state <= E5;
								
							when E5 =>
								exe_state <= E6;
								
							when E6 =>
								exe_state <= E7;

							when E7 =>
								RESET_S;
								exe_state <= E8;
								
							when E8 =>
								exe_state <= E9;
								
							when E9 =>	
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;				
					
					
					-- MOV direct,Rn
					-- The next instruction in ROM contains the direct address. We make use of PC which points to the next instruction.
					when "10001000" | "10001001" | "10001010" | "10001011" | "10001100" | "10001101" | "10001110" | "10001111" =>
						case exe_state is 
							when E0 =>
								--get direct address
								RD_ROM(PC);
								--get value of PSW
								RD_RAM(xD0);
								
								exe_state <= E1;
								
							when E1 =>
								--leave one cycle to load direct address
								PC <= PC + 1;
								exe_state <= E2;
								
							when E2 =>
								--get value of Rn
								RD_RAM("000" & i_ram_doByte(4 downto 3) & IR(2 downto 0));					
								exe_state <= E3;
								
							when E3 =>
								--wait to get Rn
								exe_state <= E4;
								
							when E4 =>						
								--write Rn to direct address
								WR_RAM(i_rom_data);
								i_ram_diByte <= i_ram_doByte;
								exe_state <= E5;
								
							when E5 => 
								exe_state <= E6;
								
							when E6 => 
								exe_state <= E7;
								
							when E7 =>
								RESET_S;
								exe_state <= E8;
								
							when E8 =>	
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E10;
								
							when E10 =>
								exe_state <= E11;
								
							when E11 =>
								exe_state <= E12;
								
							when E12 => 
								exe_state <= E13;
								
							when E13 => 
								exe_state <= E14;
								
							when E14 => 
								exe_state <= E15;
								
							when E15 => 
								exe_state <= E16;
								
							when E16 => 
								exe_state <= E17;
								
							when E17 => 
								exe_state <= E18;
								
							when E18 => 
								exe_state <= E19;
								
							when E19 => 
								exe_state <= E20;
								
							when E20 => 
								exe_state <= E21;
								
							when E21 => 
								--done with instruction
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;
						
						
					-- MOV direct,direct
					-- The next instruction in ROM contains the direct address. We make use of PC which points to the next instruction.
					when "10000101" =>
						case exe_state is 
							when E0 =>
								--get source direct address
								RD_ROM(PC);
								exe_state <= E1;
								
							when E1 =>
								--leave one cycle to load source direct address
								PC <= PC + 1;
								exe_state <= E2;
								
							when E2 =>
								--get value of source direct address
								RD_RAM(i_rom_data);
								exe_state <= E3;
								
							when E3 =>
								--wait to get value of source direct address
								exe_state <= E4;
								
							when E4=>						
								--get destination direct address
								RD_ROM(PC);
								exe_state <= E5;
								
							when E5 => 
								--leave one cycle to load destination direct address
								PC <= PC + 1;
								exe_state <= E6;
								
							when E6 => 
								--write to destination direct address
								WR_RAM(i_rom_data);
								i_ram_diByte <= i_ram_doByte;
								exe_state <= E7;
								
							when E7 =>
								RESET_S;
								exe_state <= E8;
								
							when E8 =>	
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E10;
								
							when E10 =>
								exe_state <= E11;
								
							when E11 =>
								exe_state <= E12;
								
							when E12 => 
								exe_state <= E13;
								
							when E13 => 
								exe_state <= E14;
								
							when E14 => 
								exe_state <= E15;
								
							when E15 => 
								exe_state <= E16;
								
							when E16 => 
								exe_state <= E17;
								
							when E17 => 
								exe_state <= E18;
								
							when E18 => 
								exe_state <= E19;
								
							when E19 => 
								exe_state <= E20;
								
							when E20 => 
								exe_state <= E21;
								
							when E21 => 
								--done with instruction
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;
					
					
					-- MOV direct,@Ri
					-- The next instruction in ROM contains the direct address. We make use of PC which points to the next instruction.
					when "10000110" | "10000111" =>
						case exe_state is 
							when E0 =>
								--get direct address
								RD_ROM(PC);
								--get value of PSW
								RD_RAM(xD0);
								
								exe_state <= E1;
								
							when E1 =>
								--leave one cycle to load direct address
								PC <= PC + 1;
								exe_state <= E2;
								
							when E2 =>
								--get address of Rn
								RD_RAM("000" & i_ram_doByte(4 downto 3) & "00" & IR(0));					
								exe_state <= E3;
								
							when E3 =>
								--wait to get address of Ri
								exe_state <= E4;
								
							when E4=>					
								-- get value of (Ri)
								RD_RAM(i_ram_doByte);							
								exe_state <= E5;
								
							when E5 => 
								--wait to get value of (Ri)
								exe_state <= E6;
								
							when E6 => 
								--write ((Ri)) to direct address
								WR_RAM(i_rom_data);
								i_ram_diByte <= i_ram_doByte;
								
								exe_state <= E7;
								
							when E7 =>
								RESET_S;
								exe_state <= E8;
								
							when E8 =>	
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E10;
								
							when E10 =>
								exe_state <= E11;
								
							when E11 =>
								exe_state <= E12;
								
							when E12 => 
								exe_state <= E13;
								
							when E13 => 
								exe_state <= E14;
								
							when E14 => 
								exe_state <= E15;
								
							when E15 => 
								exe_state <= E16;
								
							when E16 => 
								exe_state <= E17;
								
							when E17 => 
								exe_state <= E18;
								
							when E18 => 
								exe_state <= E19;
								
							when E19 => 
								exe_state <= E20;
								
							when E20 => 
								exe_state <= E21;
								
							when E21 => 
								--done with instruction
								exe_state <= E0;
								cpu_state <= T0;	
								
							when others =>
							
						end case;
					
					
					-- MOV direct,#data
					-- The next instruction in ROM contains the direct address. We make use of PC which points to the next instruction.
					when "01110101" =>
						case exe_state is 
							when E0 =>
								--get direct address
								RD_ROM(PC);
								exe_state <= E1;
								
							when E1 =>
								--leave one cycle to load direct address
								PC <= PC + 1;
								exe_state <= E2;
								
							when E2 =>
								DR <= i_rom_data;
								
								--get #data from ROM
								RD_ROM(PC);
								
								exe_state <= E3;
								
							when E3 =>
								--wait to get #data
								--Update PC to next instruction
								PC <= PC + 1;
								exe_state <= E4;
								
							when E4=>
								WR_RAM(DR);
								i_ram_diByte <= i_rom_data;					
								exe_state <= E5;
								
							when E5 => 
								--wait to update value of direct
								exe_state <= E6;
								
							when E6 => 
								exe_state <= E7;

							when E7 =>
								RESET_S;
								exe_state <= E8;
								
							when E8 =>	
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E10;
								
							when E10 =>
								exe_state <= E11;
								
							when E11 =>
								exe_state <= E12;
								
							when E12 => 
								exe_state <= E13;
								
							when E13 => 
								exe_state <= E14;
								
							when E14 => 
								exe_state <= E15;
								
							when E15 => 
								exe_state <= E16;
								
							when E16 => 
								exe_state <= E17;
								
							when E17 => 
								exe_state <= E18;
								
							when E18 => 
								exe_state <= E19;
								
							when E19 => 
								exe_state <= E20;
								
							when E20 => 
								exe_state <= E21;
								
							when E21 => 
								--done with instruction
								exe_state <= E0;
								cpu_state <= T0;	
								
							when others =>
							
						end case;
					
					
					-- MOV @Ri,A
					when "11110110" | "11110111" =>
						case exe_state is 
							when E0 =>
								--get value of ACC
								RD_RAM(xE0);
								exe_state <= E1;
								
							when E1 =>
								--wait to get value of ACC
								exe_state <= E2;
								
							when E2 =>
								DR <= i_ram_doByte;
								
								--get value of PSW
								RD_RAM(xD0);
								
								exe_state <= E3;
								
							when E3 =>
								--wait to get value of PSW
								exe_state <= E4;
								
							when E4 =>					
								-- get value of Ri
								RD_RAM("000" & i_ram_doByte(4 downto 3) & "00" & IR(0));							
								exe_state <= E5;
								
							when E5 => 
								--wait to get value of (Ri)
								exe_state <= E6;
								
							when E6 => 
								--write ACC to ((Ri))
								WR_RAM(i_ram_doByte);
								i_ram_diByte <= DR;
								exe_state <= E7;
								
							when E7 =>
								RESET_S;
								exe_state <= E8;
								
							when E8 =>	
								exe_state <= E9;
								
							when E9 =>						
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;
					
					
					-- MOV @Ri,direct
					-- The next instruction in ROM contains the direct address. We make use of PC which points to the next instruction.
					when "10100110" | "10100111" =>
						case exe_state is 
							when E0 =>	
								--get direct address
								RD_ROM(PC);
								
								--get value of PSW
								RD_RAM(xD0);
								
								exe_state <= E1;
								
							when E1 =>
								--wait to get direct address and value of PSW 
								PC <= PC + 1;
								exe_state <= E2;
								
							when E2 =>
								-- get value of Ri
								RD_RAM("000" & i_ram_doByte(4 downto 3) & "00" & IR(0));
								exe_state <= E3;
								
							when E3 =>
								-- wait to get value of Ri
								exe_state <= E4;
								
							when E4=>					
								-- store address of (Ri) in DR
								DR <= i_ram_doByte;
								
								--get value of direct address
								RD_RAM(i_rom_data);
								
								exe_state <= E5;
								
							when E5 => 
								--wait to get value of direct address
								exe_state <= E6;
								
							when E6 => 
								--write value of direct address to ((Ri))
								WR_RAM(DR);
								i_ram_diByte <= i_ram_doByte;
								
								exe_state <= E7;

							when E7 =>
								RESET_S;
								exe_state <= E8;
								
							when E8 =>	
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E10;
								
							when E10 =>
								exe_state <= E11;
								
							when E11 =>
								exe_state <= E12;
								
							when E12 => 
								exe_state <= E13;
								
							when E13 => 
								exe_state <= E14;
								
							when E14 => 
								exe_state <= E15;
								
							when E15 => 
								exe_state <= E16;
								
							when E16 => 
								exe_state <= E17;
								
							when E17 => 
								exe_state <= E18;
								
							when E18 => 
								exe_state <= E19;
								
							when E19 => 
								exe_state <= E20;
								
							when E20 => 
								exe_state <= E21;
								
							when E21 => 
								--done with instruction
								exe_state <= E0;
								cpu_state <= T0;	
								
							when others =>
							
						end case;
					
					
					-- MOV @Ri,#data
					-- The next instruction in ROM contains #data. We make use of PC which points to the next instruction.
					when "01110110" | "01110111" =>
						case exe_state is 
							when E0 =>	
								--get #data
								RD_ROM(PC);
								
								--get value of PSW
								RD_RAM(xD0);
								
								exe_state <= E1;
								
							when E1 =>
								--wait to get #data and value of PSW 
								PC <= PC + 1;
								exe_state <= E2;
								
							when E2 =>
								-- get value of Ri
								RD_RAM("000" & i_ram_doByte(4 downto 3) & "00" & IR(0));
								exe_state <= E3;
								
							when E3 =>
								-- wait to get value of Ri
								exe_state <= E4;
								
							when E4=>					
								--write value of #data to ((Ri))
								WR_RAM(i_ram_doByte);
								i_ram_diByte <= i_rom_data;							
								exe_state <= E5;
								
							when E5 => 
								exe_state <= E6;
								
							when E6 => 
								exe_state <= E7;
								
							when E7 =>
								RESET_S;
								exe_state <= E8;
								
							when E8 =>	
								exe_state <= E9;
								
							when E9 =>						
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;					
					
					
					--MOV DPTR, #DATA16
					when "10010000" =>
						case exe_state is
							when E0 =>
								--get higher byte
								RD_ROM(PC);								
								exe_state <= E1;
								
							when E1 =>
								--leave one cycle to get byte
								PC <= PC + 1;
								exe_state <= E2;
								
							when E2 =>
								--store in DPH
								WR_RAM(x83);
								i_ram_diByte <= i_rom_data;
								
								--get next byte
								RD_ROM(PC);								
								exe_state <= E3;
								
							when E3 =>
								--leave one cycle to get byte
								PC <= PC + 1;
								exe_state <= E4;
								
							when E4 =>
								--store in DPL
								WR_RAM(x82);
								i_ram_diByte <= i_rom_data;								
								exe_state <= E5;
								
							when E5 =>
								exe_state <= E6;
								
							when E6 =>
								exe_state <= E7;
								
							when E7 =>
								exe_state <= E8;
								
							when E8 =>
								exe_state <= E9;
								
							when E9 =>
								RESET_S;
								exe_state <= E10;
								
							when E10 =>
								exe_state <= E11;
								
							when E11 =>
								exe_state <= E12;
								
							when E12 => 
								exe_state <= E13;
								
							when E13 => 
								exe_state <= E14;
								
							when E14 => 
								exe_state <= E15;
								
							when E15 => 
								exe_state <= E16;
								
							when E16 => 
								exe_state <= E17;
								
							when E17 => 
								exe_state <= E18;
								
							when E18 => 
								exe_state <= E19;
								
							when E19 => 
								exe_state <= E20;
								
							when E20 => 
								exe_state <= E21;
								
							when E21 => 
								--done with instruction
								exe_state <= E0;
								cpu_state <= T0;	
								
							when others =>
							
						end case;
					
					
					--MOVC A, @A+DPTR
					when "10010011" =>
						case exe_state is
							when E0 =>
								--get DPH
								RD_RAM(x83);								
								exe_state <= E1;
								
							when E1 =>
								--leave one cycle to get DPH
								exe_state <= E2;
								
							when E2 =>
								DR <= i_ram_doByte;
								
								--get DPL
								RD_RAM(x82);								
								exe_state <= E3;
								
							when E3 =>
								--leave one cycle to get DPL
								exe_state <= E4;
								
							when E4 =>
								AR <= i_ram_doByte;
								
								--get ACC
								RD_RAM(xE0);
								exe_state <= E5;
								
							when E5 =>
								--leave one cycle for ACC
								exe_state <= E6;
								
							when E6 =>	
								i_ram_rdByte <= '0';
								alu_op_code <= ALU_OPC_ADD;
								alu_src_1H <= "00000000";
								alu_src_1L <= i_ram_doByte;
								alu_src_2H <= DR;
								alu_src_2L <= AR;
								alu_cy_bw <= '0';
								alu_by_wd <= '1';
								
								exe_state <= E7;
								
							when E7 =>							
								exe_state <= E8;
								
							when E8 =>
								exe_state <= E9;
								
							when E9 =>
								RD_ROM(alu_ans_H & alu_ans_L);
								exe_state <= E10;
								
							when E10 =>
								exe_state <= E11;
								
							when E11 =>
								WR_RAM(xE0);
								i_ram_diByte <= i_rom_data;
								exe_state <= E12;
								
							when E12 => 
								exe_state <= E13;
								
							when E13 => 
								RESET_S;
								exe_state <= E14;
								
							when E14 => 
								exe_state <= E15;
								
							when E15 => 
								exe_state <= E16;
								
							when E16 => 
								exe_state <= E17;
								
							when E17 => 
								exe_state <= E18;
								
							when E18 => 
								exe_state <= E19;
								
							when E19 => 
								exe_state <= E20;
								
							when E20 => 
								exe_state <= E21;
								
							when E21 => 
								--done with instruction
								exe_state <= E0;
								cpu_state <= T0;	
								
							when others =>
							
						end case;
					
					
					--MOVC A, @A+PC
					when "10000011" =>
						case exe_state is
							when E0 =>	
								--get ACC
								RD_RAM(xE0);
								exe_state <= E1;
								
							when E1 =>
								exe_state <= E2;
								
							when E2 =>								
								exe_state <= E3;
								
							when E3 =>
								exe_state <= E4;
								
							when E4 =>
								exe_state <= E5;
								
							when E5 =>
								exe_state <= E6;
								
							when E6 =>	
								i_ram_rdByte <= '0';
								alu_op_code <= ALU_OPC_ADD;
								alu_src_1H <= "00000000";
								alu_src_1L <= i_ram_doByte;
								alu_src_2H <= PC(15 downto 8);
								alu_src_2L <= PC(7 downto 0);
								alu_cy_bw <= '0';
								alu_by_wd <= '1';
								
								exe_state <= E7;
								
							when E7 =>							
								exe_state <= E8;
								
							when E8 =>
								exe_state <= E9;
								
							when E9 =>
								RD_ROM(alu_ans_H & alu_ans_L);
								exe_state <= E10;
								
							when E10 =>
								exe_state <= E11;
								
							when E11 =>
								WR_RAM(xE0);
								i_ram_diByte <= i_rom_data;
								exe_state <= E12;
								
							when E12 => 
								exe_state <= E13;
								
							when E13 => 
								RESET_S;
								exe_state <= E14;
								
							when E14 => 
								exe_state <= E15;
								
							when E15 => 
								exe_state <= E16;
								
							when E16 => 
								exe_state <= E17;
								
							when E17 => 
								exe_state <= E18;
								
							when E18 => 
								exe_state <= E19;
								
							when E19 => 
								exe_state <= E20;
								
							when E20 => 
								exe_state <= E21;
								
							when E21 => 
								--done with instruction
								exe_state <= E0;
								cpu_state <= T0;	
								
							when others =>
							
						end case;
					
					
					--MOVX A, @Ri
					when "11100010" | "11100011" =>
						case exe_state is
							when E0 =>	
								--load PSW
								RD_RAM(xD0);								
								exe_state <= E1;		
								
							when E1 =>
								--get value of Ri
								i_ram_addr <= "000" & i_ram_doByte(4 downto 3) & "00" & IR(0);
								i_ram_rdByte <= '1';
								i_ram_rdBit <= '0';
								exe_state <= E2;
								
							when E2 =>								
								--storing (Ri) in DR
								DR <= i_ram_doByte;
								exe_state <= E3;
								
						    when E3 =>
								--get value of register
								i_ram_rdByte <= '0';
								RD_RAM(DR);								
								exe_state <= E4;
								
							when E4=>
								i_ram_rdByte <= '0';
								exe_state <= E5;
								
							when E5 =>	
								DR <= i_ram_doByte;
								exe_state <= E6;
								
							when E6 =>
								ale <= '1'; -- address latch enable
								WR_RAM(x80); -- P0		
								i_ram_diByte <= DR;
								exe_state <= E7;
								
							when E7 =>								
								exe_state <= E8;
								
							when E8 =>
								WR_RAM(xA0); -- P2		
								i_ram_diByte <= "00000000";
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E10;
								
							when E10 =>
								ale <= '0'; -- address byte is valid at the negative transition of ALE
								WR_RAM_BIT("10110111"); -- set P3(7) to read data from external memory
								i_ram_diBit <= '0';	
								
								exe_state <= E11;
								
							when E11 =>
								exe_state <= E12;
								
							when E12 => 
								RD_RAM(x80); -- P0
								exe_state <= E13;
								
							when E13 => 
								exe_state <= E14;
								
							when E14 => 
								WR_RAM(xE0); -- ACC
								i_ram_diByte <= i_ram_doByte;
								exe_state <= E15;
								
							when E15 => 
								exe_state <= E16;
								
							when E16 => 
								WR_RAM_BIT("10110111");
								i_ram_diBit <= '1';	
								exe_state <= E17;
								
							when E17 => 
								exe_state <= E18;
								
							when E18 => 
								RESET_S;
								exe_state <= E19;
								
							when E19 => 
								exe_state <= E20;
								
							when E20 => 
								exe_state <= E21;
								
							when E21 => 
								--done with instruction
								exe_state <= E0;
								cpu_state <= T0;	
								
							when others =>
							
						end case;
						
						
					--MOVX A,@DPTR
					when "11100000" => 
						case exe_state is
							when E0 =>
								--get DPH
								RD_RAM(x83);								
								exe_state <= E1;
								
							when E1 =>
								--leave one cycle to get DPH
								exe_state <= E2;
								
							when E2 =>
								DR <= i_ram_doByte;
								
								--get DPL
								RD_RAM(x82);								
								exe_state <= E3;
								
							when E3 =>
								--leave one cycle to get DPL
								exe_state <= E4;
								
							when E4 =>
								AR <= i_ram_doByte;
								exe_state <= E5;
								
							when E5 =>
								exe_state <= E6;
								
							when E6 =>
								ale <= '1'; -- address latch enable
								WR_RAM(x80); -- P0		
								i_ram_diByte <= AR;
								exe_state <= E7;
								
							when E7 =>								
								exe_state <= E8;
								
							when E8 =>
								WR_RAM(xA0); -- P2		
								i_ram_diByte <= DR;
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E10;
								
							when E10 =>
								ale <= '0'; -- address byte is valid at the negative transition of ALE
								WR_RAM_BIT("10110111"); -- set P3(7) to read data from external memory
								i_ram_diBit <= '0';	
								
								exe_state <= E11;
								
							when E11 =>
								exe_state <= E12;
								
							when E12 => 
								RD_RAM(x80); -- P0
								exe_state <= E13;
								
							when E13 => 
								exe_state <= E14;
								
							when E14 => 
								WR_RAM(xE0); -- ACC
								i_ram_diByte <= i_ram_doByte;
								exe_state <= E15;
								
							when E15 => 
								exe_state <= E16;
								
							when E16 => 
								WR_RAM_BIT("10110111");
								i_ram_diBit <= '1';	
								exe_state <= E17;
								
							when E17 => 
								exe_state <= E18;
								
							when E18 => 
								RESET_S;
								exe_state <= E19;
								
							when E19 => 
								exe_state <= E20;
								
							when E20 => 
								exe_state <= E21;
								
							when E21 => 
								--done with instruction
								exe_state <= E0;
								cpu_state <= T0;	
								
							when others =>
							
						end case;	
					
					
					--MOVX @Ri, A
					when "11110010"| "11110011" =>
						case exe_state is
							when E0 =>	
								--load PSW
								RD_RAM(xD0);								
								exe_state <= E1;		
								
							when E1 =>
								--get value of Ri
								i_ram_addr <= "000" & i_ram_doByte(4 downto 3) & "00" & IR(0);
								i_ram_rdByte <= '1';
								i_ram_rdBit <= '0';
								exe_state <= E2;
								
							when E2 =>								
								--storing (Ri) in DR
								DR <= i_ram_doByte;
								exe_state <= E3;
								
						    when E3 =>
								--get value of register
								i_ram_rdByte <= '0';
								RD_RAM(DR);								
								exe_state <= E4;
								
							when E4=>
								i_ram_rdByte <= '0';
								exe_state <= E5;
								
							when E5 =>	
								DR <= i_ram_doByte;
								exe_state <= E6;
								
							when E6 =>
								ale <= '1'; -- address latch enable
								WR_RAM(x80); -- P0		
								i_ram_diByte <= DR;
								exe_state <= E7;
								
							when E7 =>								
								exe_state <= E8;
								
							when E8 =>
								WR_RAM(xA0); -- P2		
								i_ram_diByte <= "00000000";
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E10;
								
							when E10 =>
								ale <= '0'; -- address byte is valid at the negative transition of ALE
								WR_RAM_BIT("10110110"); -- set P3(6) to write data to external memory
								i_ram_diBit <= '0';	
								
								exe_state <= E11;
								
							when E11 =>
								exe_state <= E12;
								
							when E12 => 
								RD_RAM(xE0); -- ACC
								exe_state <= E13;
								
							when E13 => 
								exe_state <= E14;
								
							when E14 => 
								WR_RAM(x80); -- P0
								i_ram_diByte <= i_ram_doByte;
								exe_state <= E15;
								
							when E15 => 
								exe_state <= E16;
								
							when E16 => 
								WR_RAM_BIT("10110110");
								i_ram_diBit <= '1';	
								exe_state <= E17;
								
							when E17 => 
								exe_state <= E18;
								
							when E18 => 
								RESET_S;
								exe_state <= E19;
								
							when E19 => 
								exe_state <= E20;
								
							when E20 => 
								exe_state <= E21;
								
							when E21 => 
								--done with instruction
								exe_state <= E0;
								cpu_state <= T0;	
								
							when others =>
							
						end case;
						
						
					--MOVX @DPTR, A
					when "11110000" => 
						case exe_state is
							when E0 =>
								--get DPH
								RD_RAM(x83);								
								exe_state <= E1;
								
							when E1 =>
								--leave one cycle to get DPH
								exe_state <= E2;
								
							when E2 =>
								DR <= i_ram_doByte;
								
								--get DPL
								RD_RAM(x82);								
								exe_state <= E3;
								
							when E3 =>
								--leave one cycle to get DPL
								exe_state <= E4;
								
							when E4 =>
								AR <= i_ram_doByte;
								exe_state <= E5;
								
							when E5 =>
								exe_state <= E6;
								
							when E6 =>
								ale <= '1'; -- address latch enable
								WR_RAM(x80); -- P0		
								i_ram_diByte <= AR;
								exe_state <= E7;
								
							when E7 =>								
								exe_state <= E8;
								
							when E8 =>
								WR_RAM(xA0); -- P2		
								i_ram_diByte <= DR;
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E10;
								
							when E10 =>
								ale <= '0'; -- address byte is valid at the negative transition of ALE
								WR_RAM_BIT("10110110"); -- set P3(6) to write data to external memory
								i_ram_diBit <= '0';	
								
								exe_state <= E11;
								
							when E11 =>
								exe_state <= E12;
								
							when E12 => 
								RD_RAM(xE0); -- ACC
								exe_state <= E13;
								
							when E13 => 
								exe_state <= E14;
								
							when E14 => 
								WR_RAM(x80); -- P0
								i_ram_diByte <= i_ram_doByte;
								exe_state <= E15;
								
							when E15 => 
								exe_state <= E16;
								
							when E16 => 
								WR_RAM_BIT("10110110");
								i_ram_diBit <= '1';	
								exe_state <= E17;
								
							when E17 => 
								exe_state <= E18;
								
							when E18 => 
								RESET_S;
								exe_state <= E19;
								
							when E19 => 
								exe_state <= E20;
								
							when E20 => 
								exe_state <= E21;
								
							when E21 => 
								--done with instruction
								exe_state <= E0;
								cpu_state <= T0;	
								
							when others =>
							
						end case;	
					
					
					--PUSH direct
					when "11000000" =>
						case exe_state is
							when E0 =>
								RD_RAM(x81);
								RD_ROM(PC);								
								exe_state <= E1;
								
							when E1 =>
								--leave one cycle to get direct and SP
								PC <= PC + 1;
								exe_state <= E2;
								
							when E2 =>
								--get (direct)
								DR <= i_ram_doByte;
								RD_RAM(i_rom_data);
								
								exe_state <= E3;
								
							when E3 =>
								--inc SP by 1
								DR <= DR + 1;
								
								--leave one cycle to get (direct)
								exe_state <= E4;
								
							when E4 =>
								--write (direct) to the address stored in DR
								WR_RAM(DR);
								i_ram_diByte <= i_ram_doByte;
								
								exe_state <= E5;
								
							when E5 =>
								--wait for data to be written
								exe_state <= E6;
								
							when E6 =>
								--update SP
								WR_RAM(x81);
								i_ram_diByte <= DR;								
								exe_state <= E7;
								
							when E7 =>
								exe_state <= E8;
								
							when E8 =>
								RESET_S;
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E10;
								
							when E10 =>
								exe_state <= E11;
								
							when E11 =>
								exe_state <= E12;
								
							when E12 => 
								exe_state <= E13;
								
							when E13 => 
								exe_state <= E14;
								
							when E14 => 
								exe_state <= E15;
								
							when E15 => 
								exe_state <= E16;
								
							when E16 => 
								exe_state <= E17;
								
							when E17 => 
								exe_state <= E18;
								
							when E18 => 
								exe_state <= E19;
								
							when E19 => 
								exe_state <= E20;
								
							when E20 => 
								exe_state <= E21;
								
							when E21 => 
								--done with instruction
								exe_state <= E0;
								cpu_state <= T0;	
								
							when others =>
							
						end case;
					
					
					--POP direct
					when "11010000" =>
						case exe_state is
							when E0 =>
								--get SP
								RD_RAM(x81);
								
								--get (direct)
								RD_ROM(PC);
								
								exe_state <= E1;
								
							when E1 =>
								PC <= PC + 1;
								--leave one cycle to get (direct) and SP
								
								exe_state <= E2;
								
							when E2 =>
								--get (SP)
								RD_RAM(i_ram_doByte);
								
								--store SP in DR
								DR <= i_ram_doByte;
								
								exe_state <= E3;
								
							when E3 =>
								--reduce SP
								DR <= DR - 1;
							
								--leave one cycle to get (SP)
								exe_state <= E4;
								
							when E4 =>
								--write (SP) to direct
								WR_RAM(i_rom_data);
								i_ram_diByte <= i_ram_doByte;
								
								exe_state <= E5;
								
							when E5 =>
								--leave one cycle to write
								exe_state <= E6;
								
							when E6 =>	
								--write DR to SP
								WR_RAM(x81);
								i_ram_diByte <= DR;								
								exe_state <= E7;
								
							when E7 =>
								exe_state <= E8;
								
							when E8 =>
								RESET_S;
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E10;
								
							when E10 =>
								exe_state <= E11;
								
							when E11 =>
								exe_state <= E12;
								
							when E12 => 
								exe_state <= E13;
								
							when E13 => 
								exe_state <= E14;
								
							when E14 => 
								exe_state <= E15;
								
							when E15 => 
								exe_state <= E16;
								
							when E16 => 
								exe_state <= E17;
								
							when E17 => 
								exe_state <= E18;
								
							when E18 => 
								exe_state <= E19;
								
							when E19 => 
								exe_state <= E20;
								
							when E20 => 
								exe_state <= E21;
								
							when E21 => 
								--done with instruction
								exe_state <= E0;
								cpu_state <= T0;	
								
							when others =>
							
						end case;
					
					
					--XCH A, Rn
					when "11001000" | "11001001" | "11001010" | "11001011" | "11001100" | "11001101" | "11001110" | "11001111" =>
						case exe_state is 
							when E0 =>
								--get PSW
								RD_RAM(xD0);								
								exe_state <= E1;
								
							when E1 =>
								--leave one cycle to get PSW
								exe_state <= E2;
								
							when E2 =>
								--get (Rn)
								RD_RAM("000" & i_ram_doByte(4 downto 3) & IR(2 downto 0));
								
								--store Rn addr in DR
								DR <= "000" & i_ram_doByte(4 downto 3) & IR(2 downto 0);
								
								exe_state <= E3;
								
							when E3 =>
								--leave one cycle to get (Rn)
								exe_state <= E4;
								
							when E4 =>
								--store (Rn) in AR
								AR <= i_ram_doByte;
								
								--get ACC
								RD_RAM(xE0);								
								exe_state <= E5;
								
							when E5 =>
								--leave one cycle to get ACC
								exe_state <= E6;
								
							when E6 =>
								--store ACC in Rn
								WR_RAM(DR);
								i_ram_diByte <= i_ram_doByte;								
								exe_state <= E7;
								
							when E7 =>
								--wait for write
								exe_state <= E8;
								
							when E8 =>
								--write Rn in ACC
								WR_RAM(xE0);
								i_ram_diByte <= AR;								
								exe_state <= E9;

							when E9 =>
								RESET_S;
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;
					

					--XCH A, direct
					when "11000101" =>
						case exe_state is
							when E0 =>
								--get direct
								RD_ROM(PC);
								
								--get ACC
								RD_RAM(xE0);
								
								exe_state <= E1;
								
							when E1 =>
								--leave one cycle 
								PC <= PC + 1;
								exe_state <= E2;
								
							when E2 =>
								--get (direct)
								RD_RAM(i_rom_data);
								
								--store ACC in DR
								DR <= i_ram_doByte;
								
								--store direct in AR
								AR <= i_rom_data;
								
								exe_state <= E4;
								
							when E4 =>
								exe_state <= E5;
								
							when E5 =>
								--write (direct) to ACC
								WR_RAM(xE0);
								i_ram_diByte <= i_ram_doByte;								
								exe_state <= E6;
								
							when E6 =>
								exe_state <= E7;
								
							when E7 =>
								--write ACC to direct
								WR_RAM(AR);
								i_ram_diByte <= DR;								
								exe_state <= E8;
								
							when E8 =>
								exe_state <= E9;

							when E9 =>
								RESET_S;
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;
					

					--XCH A, @Ri
					when "11000110" | "11000111" =>
						case exe_state is
							when E0 =>
								--get PSW
								RD_RAM(xD0);								
								exe_state <= E1;
								
							when E1 =>
								exe_state <= E2;
								
							when E2 =>
								--get (Ri)
								RD_RAM("000" & i_ram_doByte(4 downto 3) & "00" & IR(0));					
								exe_state <= E3;
								
							when E3 =>
								--store (Ri) in DR
								DR <= i_ram_doByte;
								RD_RAM(i_ram_doByte);	
								exe_state <= E4;
								
							when E4 =>							
								exe_state <= E5;
								
							when E5 =>
								--store ((Ri)) in AR
								AR <= i_ram_doByte;
							
								--get ACC
								RD_RAM(xE0);
								
								exe_state <= E6;
								
							when E6 =>
								exe_state <= E7;
								
							when E7 =>
								--copy ACC to (Ri)
								WR_RAM(DR);
								i_ram_diByte <= i_ram_doByte;
								exe_state <= E8;
								
							when E8 =>
								--write ((Ri)) to ACC
								WR_RAM(xE0);
								i_ram_diByte <= AR;								
								exe_state <= E9;
						
							when E9 =>
								RESET_S;
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;
					

					--XCHD A, @Ri
					when "11010110" | "11010111" =>
						case exe_state is
							when E0 =>
								--get PSW
								RD_RAM(xD0);								
								exe_state <= E1;
								
							when E1 =>
								exe_state <= E2;
								
							when E2 =>
								--get (Ri)
								RD_RAM("000" & i_ram_doByte(4 downto 3) & "00" & IR(0));					
								exe_state <= E3;
								
							when E3 =>
								--store (Ri) in DR
								DR <= i_ram_doByte;
								RD_RAM(i_ram_doByte);	
								exe_state <= E4;
								
							when E4 =>							
								exe_state <= E5;
								
							when E5 =>
								--store ((Ri)) in AR
								AR <= i_ram_doByte;
							
								--get ACC
								RD_RAM(xE0);
								
								exe_state <= E6;
								
							when E6 =>
								exe_state <= E7;
								
							when E7 =>
								--copy ACC to (Ri)
								WR_RAM(DR);
								i_ram_diByte <= AR(7 downto 4) & i_ram_doByte(3 downto 0);
								exe_state <= E8;
								
							when E8 =>
								--write ((Ri)) to ACC
								WR_RAM(xE0);
								i_ram_diByte <= i_ram_doByte(7 downto 4) & AR(3 downto 0);								
								exe_state <= E9;
						
							when E9 =>
								RESET_S;
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;
					
					
					--CLR C
					when "11000011" =>
						case exe_state is 
							when E0 =>
								WR_RAM_BIT("11010111");
								i_ram_diBit <= '0';								
								exe_state <= E1;
								
							when E1 =>
								exe_state <= E2;
								
							when E2 =>
								exe_state <= E3;
								
							when E3 =>
								exe_state <= E4;
								
							when E4 =>
								exe_state <= E5;
								
							when E5 =>
								exe_state <= E6;
								
							when E6 =>
								exe_state <= E7;
								
							when E7 =>
								exe_state <= E8;
								
							when E8 =>
								RESET_S;
								exe_state <= E9;

							when E9 =>
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;
					
					
					--CLR bit
					when "11000010" =>
						case exe_state is
							when E0 =>
								RD_ROM(PC);								
								exe_state <= E1;
								
							when E1 =>	
								--leave one cycle to get bit address
								PC <= PC + 1;										
								exe_state <= E2;
								
							when E2 =>
								WR_RAM_BIT(i_rom_data);
								i_ram_diBit <= '0';								
								exe_state <= E3;
								
							when E3 =>
								exe_state <= E4;
								
							when E4 =>
								exe_state <= E5;
								
							when E5 =>
								exe_state <= E6;
								
							when E6 =>
								exe_state <= E7;
								
							when E7 =>
								exe_state <= E8;
								
							when E8 =>
								RESET_S;
								exe_state <= E9;

							when E9 =>
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;
					
					
					-- SETB C
					when "11010011" =>
						case exe_state is
							when E0 =>
								-- write into PSW
								WR_RAM_BIT("11010111");
								i_ram_diBit <= '1';
								exe_state <= E1;
								
							when E1 =>								  
								exe_state <= E2;
								
							when E2 => 
								exe_state <= E3;
								
							when E3 =>
								exe_state <= E4;
								
							when E4 => 
								exe_state <= E5;
								
							when E5 => 
								exe_state <= E6;
								
							when E6 => 
								exe_state <= E7;
								
							when E7 => 
								exe_state <= E8;
								
							when E8 => 
								RESET_S;
								exe_state <= E9;
								
							when E9 => 
								-- move back to fetch next instruction
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;
					
					
					-- SETB bit
					when "11010010" =>
						case exe_state is
							when E0 =>
								-- get bit address
								RD_ROM(PC);
								exe_state <= E1;
								
							when E1	=>
								-- increment PC
								PC <= PC + 1;
								exe_state <= E2;
								
							when E2	=>
								-- write into that bit address
								WR_RAM_BIT(i_rom_data);
								i_ram_diBit <= '1';
								exe_state <= E3;
								
							when E3 =>
								exe_state <= E4;
								
							when E4 => 
								exe_state <= E5;
								
							when E5 => 
								exe_state <= E6;
								
							when E6 => 
								exe_state <= E7;
								
							when E7 => 
								exe_state <= E8;
								
							when E8 => 
								RESET_S;
								exe_state <= E9;

							when E9 => 
								-- move back to fetch next instruction									  
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;
					
					
					--CPL C
					when "10110011" =>
						case exe_state is 
							when E0 =>
								RD_RAM_BIT("11010111");							
								exe_state <= E1;
								
							when E1 =>
								--leave one cycle for getting bit
								exe_state <= E2;
								
							when E2 =>
								alu_op_code <= ALU_OPC_NOT;
								alu_src_1L <= "0000000" & i_ram_doBit;
								alu_by_wd <= '0';
								
								exe_state <= E3;
								
							when E3 =>
								exe_state <= E4;
								
							when E4 =>
								WR_RAM_BIT("11010111");
								i_ram_diBit <= alu_ans_L(0);
								
								exe_state <= E5;
								
							when E5 =>
								exe_state <= E6;
								
							when E6 =>
								exe_state <= E7;
								
							when E7 =>
								exe_state <= E8;
								
							when E8 =>
								RESET_S;
								exe_state <= E9;

							when E9 =>
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;
					

					--CPL bit
					when "10110010" =>
						case exe_state is
							when E0 =>
								--get bit address
								RD_ROM(PC);								
								exe_state <= E1;
								
							when E1 =>
								PC <= PC + 1;
								--leave one cycle to get address
								exe_state <= E2;
								
							when E2 =>
								RD_RAM_BIT(i_rom_data);
								DR <= i_rom_data;
								
								exe_state <= E3;
								
							when E3 =>							
								--leave one cycle to get bit
								exe_state <= E4;
								
							when E4 =>
								alu_op_code <= ALU_OPC_NOT;
								alu_src_1L <= "0000000" & i_ram_doBit;
								alu_by_wd <= '0';
								
								exe_state <= E5;
								
							when E5 =>
								exe_state <= E6;
								
							when E6 =>
								WR_RAM_BIT(DR);
								i_ram_diBit <= alu_ans_L(0);
								exe_state <= E7;
								
							when E7 =>
								exe_state <= E8;
								
							when E8 =>
								RESET_S;
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;
					
					
					--ANL C,Bit
					when "10000010" =>
						case exe_state is
							when E0 =>
								exe_state <= E1;
								
							when E1=>
								--Get address of bit
								RD_ROM(PC);						
								exe_state <= E2;
								
							when E2=>
								--Leave one cycle to load the address and the carry flag
								PC <= PC + 1;								
								exe_state <= E3;
								
							when E3=>														
								--Get (Bit) 
								RD_RAM_BIT(i_rom_data);
									
								exe_state <= E4;
								
							when E4=>
								--Leave one cycle to load the bit
								exe_state <= E5;
								
							when E5=>
								--If the source bit is '0', carry flag is cleared, else it remains as it is.
								if(i_ram_doBit='0') then
									WR_RAM_BIT("11010111");
									i_ram_diBit<='0';
								end if;
								
								exe_state <= E6;
								
							when E6 =>
								exe_state <= E7;
								
							when E7 =>
								exe_state <= E8;
								
							when E8 =>
								RESET_S;
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E10;
								
							when E10 =>
								exe_state <= E11;
								
							when E11 =>
								exe_state <= E12;
								
							when E12 => 
								exe_state <= E13;
								
							when E13 => 
								exe_state <= E14;
								
							when E14 => 
								exe_state <= E15;
								
							when E15 => 
								exe_state <= E16;
								
							when E16 => 
								exe_state <= E17;
								
							when E17 => 
								exe_state <= E18;
								
							when E18 => 
								exe_state <= E19;
								
							when E19 => 
								exe_state <= E20;
								
							when E20 => 
								exe_state <= E21;
								
							when E21 => 
								--done with instruction
								exe_state <= E0;
								cpu_state <= T0;	
								
							when others =>
							
						end case;
					
					
					--ANL C,/Bit
					when "10110000" =>
						case exe_state is
							when E0 =>
								exe_state <= E1;
								
							when E1=>
								--Get address of bit
								RD_ROM(PC);						
								exe_state <= E2;
								
							when E2=>
								--Leave one cycle to load the address and the carry flag
								PC <= PC + 1;								
								exe_state <= E3;
								
							when E3=>														
								--Get (Bit) 
								RD_RAM_BIT(i_rom_data);
									
								exe_state <= E4;
								
							when E4=>
								--Leave one cycle to load the bit
								exe_state <= E5;
								
							when E5=>
								--If the source bit is '1', carry flag is cleared, else it remains as it is.
								if(i_ram_doBit='1') then
									WR_RAM_BIT("11010111");
									i_ram_diBit<='0';
								end if;
								
								exe_state <= E6;
								
							when E6 =>
								exe_state <= E7;
								
							when E7 =>
								exe_state <= E8;
								
							when E8 =>
								RESET_S;
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E10;
								
							when E10 =>
								exe_state <= E11;
								
							when E11 =>
								exe_state <= E12;
								
							when E12 => 
								exe_state <= E13;
								
							when E13 => 
								exe_state <= E14;
								
							when E14 => 
								exe_state <= E15;
								
							when E15 => 
								exe_state <= E16;
								
							when E16 => 
								exe_state <= E17;
								
							when E17 => 
								exe_state <= E18;
								
							when E18 => 
								exe_state <= E19;
								
							when E19 => 
								exe_state <= E20;
								
							when E20 => 
								exe_state <= E21;
								
							when E21 => 
								--done with instruction
								exe_state <= E0;
								cpu_state <= T0;	
								
							when others =>
							
						end case;					
					
					
					--ORL C,Bit
					when "01110010" =>
						case exe_state is
							when E0 =>
								exe_state <= E1;
								
							when E1=>
								--Get address of bit
								RD_ROM(PC);						
								exe_state <= E2;
								
							when E2=>
								--Leave one cycle to load the address and the carry flag
								PC <= PC + 1;								
								exe_state <= E3;
								
							when E3=>														
								--Get (Bit) 
								RD_RAM_BIT(i_rom_data);
									
								exe_state <= E4;
								
							when E4=>
								--Leave one cycle to load the bit
								exe_state <= E5;
								
							when E5=>
								--If the source bit is '1', carry flag is set, otherwise it remains as it is
								if(i_ram_doBit='1') then
									WR_RAM_BIT("11010111");
									i_ram_diBit <= '1';
								end if;
								
								exe_state <= E6;
								
							when E6 =>
								exe_state <= E7;
								
							when E7 =>
								exe_state <= E8;
								
							when E8 =>
								RESET_S;
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E10;
								
							when E10 =>
								exe_state <= E11;
								
							when E11 =>
								exe_state <= E12;
								
							when E12 => 
								exe_state <= E13;
								
							when E13 => 
								exe_state <= E14;
								
							when E14 => 
								exe_state <= E15;
								
							when E15 => 
								exe_state <= E16;
								
							when E16 => 
								exe_state <= E17;
								
							when E17 => 
								exe_state <= E18;
								
							when E18 => 
								exe_state <= E19;
								
							when E19 => 
								exe_state <= E20;
								
							when E20 => 
								exe_state <= E21;
								
							when E21 => 
								--done with instruction
								exe_state <= E0;
								cpu_state <= T0;	
								
							when others =>
							
						end case;					
					
					
					--ORL C,/Bit
					when "10100000"=>
						case exe_state is
							when E0 =>
								exe_state <= E1;
								
							when E1=>
								--Get address of bit
								RD_ROM(PC);						
								exe_state <= E2;
								
							when E2=>
								--Leave one cycle to load the address and the carry flag
								PC <= PC + 1;								
								exe_state <= E3;
								
							when E3=>														
								--Get (Bit) 
								RD_RAM_BIT(i_rom_data);
									
								exe_state <= E4;
								
							when E4=>
								--Leave one cycle to load the bit
								exe_state <= E5;
								
							when E5=>
								--If the source bit is '0', carry flag is set, otherwise it remains as it is
								if(i_ram_doBit='0') then
									WR_RAM_BIT("11010111");
									i_ram_diBit <= '1';
								end if;
								
								exe_state <= E6;
								
							when E6 =>
								exe_state <= E7;
								
							when E7 =>
								exe_state <= E8;
								
							when E8 =>
								RESET_S;
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E10;
								
							when E10 =>
								exe_state <= E11;
								
							when E11 =>
								exe_state <= E12;
								
							when E12 => 
								exe_state <= E13;
								
							when E13 => 
								exe_state <= E14;
								
							when E14 => 
								exe_state <= E15;
								
							when E15 => 
								exe_state <= E16;
								
							when E16 => 
								exe_state <= E17;
								
							when E17 => 
								exe_state <= E18;
								
							when E18 => 
								exe_state <= E19;
								
							when E19 => 
								exe_state <= E20;
								
							when E20 => 
								exe_state <= E21;
								
							when E21 => 
								--done with instruction
								exe_state <= E0;
								cpu_state <= T0;	
								
							when others =>
							
						end case;						
					
					
					--MOV C, bit
					when "10100010" =>
						case exe_state is
							when E0 =>
								exe_state <= E1;
								
							when E1 =>
								--Get address of bit
								RD_ROM(PC);
								exe_state <= E2;
								
							when E2 =>
								--Leave one cycle to load the address 
								PC <= PC + 1;
								exe_state <= E3;
								
							when E3 =>
								--Get (Bit) 
								RD_RAM_BIT(i_rom_data);							
								exe_state <= E4;
								
							when E4 =>
								--Leave one cycle to load the bit
								exe_state <= E5;
								
							when E5 =>
								--Moving (Bit) into the Carry Flag
								WR_RAM_BIT("11010111");
								i_ram_diBit <= i_ram_doBit;
								
								exe_state <= E6;
								
							when E6 => 
								exe_state <= E7;
								
							when E7 => 
								exe_state <= E8;
								
							when E8 => 
								RESET_S;
								exe_state <= E9;

							when E9 => 
								-- move back to fetch next instruction
								exe_state <= E0;
								cpu_state <= T0;
								
							when others =>
							
						end case;		
					
					
					--MOV bit,C
					when "10010010" =>
						case exe_state is
							when E0 =>
								exe_state <= E1;
								
							when E1 =>
								--Get address of bit
								RD_ROM(PC);
								
								--Get the carry flag
								RD_RAM_BIT("11010111");	
								
								exe_state <= E2;
									
							when E2 =>
								--Leave one cycle to load the address and the carry flag
								PC <= PC + 1;
								exe_state <= E3;
									
							when E3 =>
								--Moving contents of the Carry flag to (bit)
								WR_RAM_BIT(i_rom_data);
								i_ram_diBit <= i_ram_doBit;
								exe_state <= E4;
								
							when E4 =>
								--Leave one cycle to write
								exe_state <= E5;	
								
							when E5 => 
								exe_state <= E6;
								
							when E6 => 
								exe_state <= E7;
								
							when E7 => 
								exe_state <= E8;
								
							when E8 => 
								RESET_S;
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E10;
								
							when E10 =>
								exe_state <= E11;
								
							when E11 =>
								exe_state <= E12;
								
							when E12 => 
								exe_state <= E13;
								
							when E13 => 
								exe_state <= E14;
								
							when E14 => 
								exe_state <= E15;
								
							when E15 => 
								exe_state <= E16;
								
							when E16 => 
								exe_state <= E17;
								
							when E17 => 
								exe_state <= E18;
								
							when E18 => 
								exe_state <= E19;
								
							when E19 => 
								exe_state <= E20;
								
							when E20 => 
								exe_state <= E21;
								
							when E21 => 
								--done with instruction
								exe_state <= E0;
								cpu_state <= T0;	
								
							when others =>
							
						end case;	
					
					
					-- JC rel
					when "01000000" =>
						case exe_state is
							when E0 =>
								-- get rel address
								RD_ROM(PC);
								
								-- get xD7 bit
								RD_RAM_BIT("11010111");
								
								exe_state <= E1;
								
							when E1	=>
								-- increment PC
								PC <= PC + 1;
								exe_state <= E2;
								
							when E2	=>
								-- AR has rel address
								AR <= i_rom_data;
								
								-- get the carry bit
								int_hold <= i_ram_doBit;	
								
								exe_state <= E3;
								
							when E3 =>
								-- set ALU to add
								alu_op_code <= ALU_OPC_ADD;
								alu_by_wd <= '1';
								alu_src_1L <= PC(7 downto 0);
								alu_src_1H <= PC(15 downto 8);	
								
								-- decide to move up/down -> subtract/add
								if(int_hold = '1') then
									alu_src_2L <= AR;
									if(AR(7) = '1')	then	
										alu_src_2H <= "11111111";
									else
										alu_src_2H <= "00000000";
									end if;
								else										
									alu_src_2L <= "00000000";
									alu_src_2H <= "00000000";
								end if;
								
								exe_state <= E4;
								
							when E4 =>
								exe_state <= E5;
								
							when E5 =>								  	
								exe_state <= E6;
								
							when E6 => 
								-- PC is updated
								PC <= alu_ans_H & alu_ans_L;
								exe_state <= E7;
								
							when E7 => 
								exe_state <= E8;
								
							when E8 => 
								RESET_S;
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E10;
								
							when E10 =>
								exe_state <= E11;
								
							when E11 =>
								exe_state <= E12;
								
							when E12 => 
								exe_state <= E13;
								
							when E13 => 
								exe_state <= E14;
								
							when E14 => 
								exe_state <= E15;
								
							when E15 => 
								exe_state <= E16;
								
							when E16 => 
								exe_state <= E17;
								
							when E17 => 
								exe_state <= E18;
								
							when E18 => 
								exe_state <= E19;
								
							when E19 => 
								exe_state <= E20;
								
							when E20 => 
								exe_state <= E21;
								
							when E21 => 
								--done with instruction
								exe_state <= E0;
								cpu_state <= T0;	
								
							when others =>
							
						end case;
					
					
					-- JNC rel
					when "01010000" =>	
						case exe_state is
							when E0 =>
								-- get rel address
								RD_ROM(PC);
								
								-- get xD7 bit
								RD_RAM_BIT("11010111");
								
								exe_state <= E1;
								
							when E1	=>
								-- increment PC
								PC <= PC + 1;
								exe_state <= E2;
								
							when E2	=>
								-- AR has rel address
								AR <= i_rom_data;
								
								-- get the carry bit
								int_hold <= i_ram_doBit;	
								
								exe_state <= E3;
								
							when E3 =>
								-- set ALU to add
								alu_op_code <= ALU_OPC_ADD;
								alu_by_wd <= '1';
								alu_src_1L <= PC(7 downto 0);
								alu_src_1H <= PC(15 downto 8);	
								
								-- decide to move up/down -> subtract/add
								if(int_hold = '0') then
									alu_src_2L <= AR;
									if(AR(7) = '1')	then	
										alu_src_2H <= "11111111";
									else
										alu_src_2H <= "00000000";
									end if;
								else										
									alu_src_2L <= "00000000";
									alu_src_2H <= "00000000";
								end if;
								
								exe_state <= E4;
								
							when E4 =>
								exe_state <= E5;
								
							when E5 =>								  	
								exe_state <= E6;
								
							when E6 => 
								-- PC is updated
								PC <= alu_ans_H & alu_ans_L;
								exe_state <= E7;
								
							when E7 => 
								exe_state <= E8;
								
							when E8 => 
								RESET_S;
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E10;
								
							when E10 =>
								exe_state <= E11;
								
							when E11 =>
								exe_state <= E12;
								
							when E12 => 
								exe_state <= E13;
								
							when E13 => 
								exe_state <= E14;
								
							when E14 => 
								exe_state <= E15;
								
							when E15 => 
								exe_state <= E16;
								
							when E16 => 
								exe_state <= E17;
								
							when E17 => 
								exe_state <= E18;
								
							when E18 => 
								exe_state <= E19;
								
							when E19 => 
								exe_state <= E20;
								
							when E20 => 
								exe_state <= E21;
								
							when E21 => 
								--done with instruction
								exe_state <= E0;
								cpu_state <= T0;	
								
							when others =>
							
						end case;					
					
					
					-- JB bit, rel
					when "00100000" =>
						case exe_state is
							when E0	=>
								-- get value pointed to by line of code
								RD_ROM(PC);								
								exe_state <= E1;
								
							when E1	=>
								-- increment PC
								PC <= PC + 1;
								exe_state <= E2;
								
							when E2	=>
								AR <= i_rom_data;
								exe_state <= E3;
								
							when E3 =>
								-- get value pointed to by line of code
								RD_ROM(PC);
								
								-- get RAM bit from address
								RD_RAM_BIT(AR);
								
								exe_state <= E4;
								
							when E4 =>
								-- increment PC
								PC <= PC + 1;
								exe_state <= E5;
								
							when E5 =>
								-- rel address is stored in DR
								DR <= i_rom_data;
								
								-- int_hold has the bit
								int_hold <= i_ram_doBit;
								
								exe_state <= E6;
								
							when E6 =>
								-- set ALU to add
								alu_op_code <= ALU_OPC_ADD;
								alu_by_wd <= '1';
								alu_src_1L <= PC(7 downto 0);
								alu_src_1H <= PC(15 downto 8);	
								
								-- decide to move up or down
								if(int_hold = '1') then
									alu_src_2L <= DR;
									-- add/subtract PC
									if(DR(7) = '1')	then	
										alu_src_2H <= "11111111";
									else
										alu_src_2H <= "00000000";
									end if;
								else								
									alu_src_2L <= "00000000";
									alu_src_2H <= "00000000";
								end if;	
								
								exe_state <= E7;
								
							when E7 =>
								exe_state <= E8;
								
							when E8 =>
								exe_state <= E9;
								
							when E9 => 
								-- update PC to new value
								PC <= alu_ans_H & alu_ans_L;
								exe_state <= E10;
								
							when E10 => 
								RESET_S;
								exe_state <= E11;
								
							when E11 =>
								exe_state <= E12;
								
							when E12 => 
								exe_state <= E13;
								
							when E13 => 
								exe_state <= E14;
								
							when E14 => 
								exe_state <= E15;
								
							when E15 => 
								exe_state <= E16;
								
							when E16 => 
								exe_state <= E17;
								
							when E17 => 
								exe_state <= E18;
								
							when E18 => 
								exe_state <= E19;
								
							when E19 => 
								exe_state <= E20;
								
							when E20 => 
								exe_state <= E21;
								
							when E21 => 
								--done with instruction
								exe_state <= E0;
								cpu_state <= T0;	
								
							when others =>
							
						end case;
					
					
					--JNB bit, rel
					when "00110000" =>	
						case exe_state is
							when E0	=>
								-- get value pointed to by line of code
								RD_ROM(PC);								
								exe_state <= E1;
								
							when E1	=>
								-- increment PC
								PC <= PC + 1;
								exe_state <= E2;
								
							when E2	=>
								AR <= i_rom_data;
								exe_state <= E3;
								
							when E3 =>
								-- get value pointed to by line of code
								RD_ROM(PC);
								
								-- get RAM bit from address
								RD_RAM_BIT(AR);
								
								exe_state <= E4;
								
							when E4 =>
								-- increment PC
								PC <= PC + 1;
								exe_state <= E5;
								
							when E5 =>
								-- rel address is stored in DR
								DR <= i_rom_data;
								
								-- int_hold has the bit
								int_hold <= i_ram_doBit;
								
								exe_state <= E6;
								
							when E6 =>
								-- set ALU to add
								alu_op_code <= ALU_OPC_ADD;
								alu_by_wd <= '1';
								alu_src_1L <= PC(7 downto 0);
								alu_src_1H <= PC(15 downto 8);	
								
								-- decide to move up or down
								if(int_hold = '0') then
									alu_src_2L <= DR;
									-- add/subtract PC
									if(DR(7) = '1')	then	
										alu_src_2H <= "11111111";
									else
										alu_src_2H <= "00000000";
									end if;
								else								
									alu_src_2L <= "00000000";
									alu_src_2H <= "00000000";
								end if;	
								
								exe_state <= E7;
								
							when E7 =>
								exe_state <= E8;
								
							when E8 =>
								exe_state <= E9;
								
							when E9 => 
								-- update PC to new value
								PC <= alu_ans_H & alu_ans_L;
								exe_state <= E10;
								
							when E10 => 
								RESET_S;
								exe_state <= E11;
								
							when E11 =>
								exe_state <= E12;
								
							when E12 => 
								exe_state <= E13;
								
							when E13 => 
								exe_state <= E14;
								
							when E14 => 
								exe_state <= E15;
								
							when E15 => 
								exe_state <= E16;
								
							when E16 => 
								exe_state <= E17;
								
							when E17 => 
								exe_state <= E18;
								
							when E18 => 
								exe_state <= E19;
								
							when E19 => 
								exe_state <= E20;
								
							when E20 => 
								exe_state <= E21;
								
							when E21 => 
								--done with instruction
								exe_state <= E0;
								cpu_state <= T0;	
								
							when others =>
							
						end case;					
					
					
					-- JBC bit, rel
					when "00010000" =>
						case exe_state is
							when E0	=>
								-- get value pointed to by line of code
								RD_ROM(PC);								
								exe_state <= E1;
								
							when E1	=>
								-- increment PC
								PC <= PC + 1;
								exe_state <= E2;
								
							when E2	=>
								AR <= i_rom_data;
								exe_state <= E3;
								
							when E3 =>
								-- get value pointed to by line of code
								RD_ROM(PC);
								
								-- get RAM bit from address
								RD_RAM_BIT(AR);
								
								exe_state <= E4;
								
							when E4 =>
								-- increment PC
								PC <= PC + 1;
								exe_state <= E5;
								
							when E5 =>
								-- rel address is stored in DR
								DR <= i_rom_data;
								
								-- int_hold has the bit
								int_hold <= i_ram_doBit;
								
								exe_state <= E6;
								
							when E6 =>
								-- set ALU to add
								alu_op_code <= ALU_OPC_ADD;
								alu_by_wd <= '1';
								alu_src_1L <= PC(7 downto 0);
								alu_src_1H <= PC(15 downto 8);	
								
								-- decide to move up or down
								if(int_hold = '1') then
									alu_src_2L <= DR;
									-- add/subtract PC
									if(DR(7) = '1')	then	
										alu_src_2H <= "11111111";
									else
										alu_src_2H <= "00000000";
									end if;
								else								
									alu_src_2L <= "00000000";
									alu_src_2H <= "00000000";
								end if;	
								
								exe_state <= E7;
								
							when E7 =>
								exe_state <= E8;
								
							when E8 =>
								WR_RAM_BIT(AR);
								i_ram_diBit <= '0';
								exe_state <= E9;
								
							when E9 => 
								-- update PC to new value
								PC <= alu_ans_H & alu_ans_L;
								exe_state <= E10;
								
							when E10 => 
								RESET_S;
								exe_state <= E11;
								
							when E11 =>
								exe_state <= E12;
								
							when E12 => 
								exe_state <= E13;
								
							when E13 => 
								exe_state <= E14;
								
							when E14 => 
								exe_state <= E15;
								
							when E15 => 
								exe_state <= E16;
								
							when E16 => 
								exe_state <= E17;
								
							when E17 => 
								exe_state <= E18;
								
							when E18 => 
								exe_state <= E19;
								
							when E19 => 
								exe_state <= E20;
								
							when E20 => 
								exe_state <= E21;
								
							when E21 => 
								--done with instruction
								exe_state <= E0;
								cpu_state <= T0;	
								
							when others =>
							
						end case;						
					
					
					-- ACALL addr11
					when "00010001"|"00110001"|"01010001"|"01110001"|"10010001"|"10110001"|"11010001"|"11110001" =>
						case exe_state is
							when E0	=>
								-- get first 8 bits of address from program
								RD_ROM(PC);
								
								-- get Stack pointer value
								RD_RAM(x81);
								
								exe_state <= E1;
								
							when E1	=>
								-- move to next value in program
								PC <= PC + 1;								
								exe_state <= E2;
								
							when E2	=>
								-- DR is set to SP + 1
								DR <= i_ram_doByte + 1;	
								
								-- AR is set to value in address pointed by PC line
								AR <= i_rom_data;
								
								exe_state <= E3;
								
							when E3 =>
								WR_RAM(DR);
								
								-- first 8 bits of code address is put into stack
								i_ram_diByte <= PC(7 downto 0);
								
								exe_state <= E4;
								
							when E4 =>
								-- Stack pointer in incremented
								DR <= DR + 1;
								exe_state <= E5;
								
							when E5 =>
								WR_RAM(DR);
								
								-- second 8 bits of code address is put into stack
								i_ram_diByte <= PC(15 downto 8);
								
								exe_state <= E6;
								
							when E6 =>
								-- new PC is set
								PC <= PC(15 downto 11) & IR(7 downto 5) & AR;

								WR_RAM(x81);
								
								-- stack pointer value is updated
								i_ram_diByte <= DR;
								
								exe_state <= E7;
								
							when E7 =>								   
								exe_state <= E8;
								
							when E8 => 
								RESET_S;
								exe_state <= E9;
								
							when E9 => 
								exe_state <= E10;
								
							when E10 => 
								exe_state <= E11;
								
							when E11 =>
								exe_state <= E12;
								
							when E12 => 
								exe_state <= E13;
								
							when E13 => 
								exe_state <= E14;
								
							when E14 => 
								exe_state <= E15;
								
							when E15 => 
								exe_state <= E16;
								
							when E16 => 
								exe_state <= E17;
								
							when E17 => 
								exe_state <= E18;
								
							when E18 => 
								exe_state <= E19;
								
							when E19 => 
								exe_state <= E20;
								
							when E20 => 
								exe_state <= E21;
								
							when E21 => 
								--done with instruction
								exe_state <= E0;
								cpu_state <= T0;	
								
							when others =>
							
						end case;
					
					
					-- LCALL addr16
					when "00010010" =>
						case exe_state is
							when E0	=>
								-- get first 8 bits of address from program
								RD_ROM(PC);
								
								-- get Stack pointer value
								RD_RAM(x81);
								
								exe_state <= E1;
								
							when E1	=>
								-- go to next line in code
								PC <= PC + 1;
								exe_state <= E2;
								
							when E2	=>
								-- DR is SP + 1
								DR <= i_ram_doByte + 1;
								
								-- AR is value in address pointed by PC line
								AR <= i_rom_data;
								
								exe_state <= E3;
								
							when E3 =>
								-- get next 8 bits of address from program
								RD_ROM(PC);
								exe_state <= E4;
								
							when E4 =>
								-- increment PC
								PC <= PC + 1;
								
								WR_RAM(DR);
								i_ram_diByte <= PC(7 downto 0);
								
								exe_state <= E5;
								
							when E5 =>
								DR <= DR + 1;		
								exe_state <= E6;
								
							when E6 =>
								WR_RAM(DR);
								i_ram_diByte <= PC(15 downto 8);
								exe_state <= E7;
								
							when E7 =>
								exe_state <= E8;
								
							when E8 =>
								WR_RAM(x81);
								i_ram_diByte <= DR;
								
								PC <= AR & i_rom_data;
								
								exe_state <= E9;
								
							when E9 =>	
								RESET_S;
								exe_state <= E10;
								
							when E10 => 
								exe_state <= E11;
								
							when E11 =>
								exe_state <= E12;
								
							when E12 => 
								exe_state <= E13;
								
							when E13 => 
								exe_state <= E14;
								
							when E14 => 
								exe_state <= E15;
								
							when E15 => 
								exe_state <= E16;
								
							when E16 => 
								exe_state <= E17;
								
							when E17 => 
								exe_state <= E18;
								
							when E18 => 
								exe_state <= E19;
								
							when E19 => 
								exe_state <= E20;
								
							when E20 => 
								exe_state <= E21;
								
							when E21 => 
								--done with instruction
								exe_state <= E0;
								cpu_state <= T0;	
								
							when others =>
							
						end case;	
					
					
					-- RET
					when "00100010" =>
						case exe_state is
							when E0	=>
								-- get value of Stack Pointer
								RD_RAM(x81);
								exe_state <= E1;
								
							when E1	=>
								-- store stack pointer value in DR
								DR <= i_ram_doByte;
		
								exe_state <= E2;
								
							when E2 =>
								-- get what stack pointer is pointing to (1st 8 bits of address)
								RD_RAM(DR);
								
								exe_state <= E3;
								
							when E3 => 	
								-- decrement SP value
								DR <= DR - 1;
								
								-- store first 8 bits of address to PC
								PC(15 downto 8) <= i_ram_doByte;
								
								exe_state <= E4;
								
							when E4 =>
								-- get the next 8 bits of address
								RD_RAM(DR);
								exe_state <= E5;
								
							when E5 =>
								exe_state <= E6;
								
							when E6 =>	
								-- store next 8 bits of address to PC
								PC(7 downto 0) <= i_ram_doByte;	
								exe_state <= E7;
								
							when E7 => 
								WR_RAM(x81);
							
								-- set diByte to write into RAM
								i_ram_diByte <= DR - 1;
								
								exe_state <= E8;
								
							when E8 => 
								RESET_S;
								exe_state <= E9;
								
							when E9 => 
								exe_state <= E10;
								
							when E10 => 
								exe_state <= E11;
								
							when E11 =>
								exe_state <= E12;
								
							when E12 => 
								exe_state <= E13;
								
							when E13 => 
								exe_state <= E14;
								
							when E14 => 
								exe_state <= E15;
								
							when E15 => 
								exe_state <= E16;
								
							when E16 => 
								exe_state <= E17;
								
							when E17 => 
								exe_state <= E18;
								
							when E18 => 
								exe_state <= E19;
								
							when E19 => 
								exe_state <= E20;
								
							when E20 => 
								exe_state <= E21;
								
							when E21 => 
								--done with instruction
								exe_state <= E0;
								cpu_state <= T0;	
								
							when others =>
							
						end case;
					
					
					--RETI
					when "00110010" =>
						case exe_state is
							when E0	=>
								-- get Stack Pointer value
								RD_RAM(x81);
								exe_state <= E1;
								
							when E1	=> 		
								-- DR has SP value
								DR <= i_ram_doByte;
								
								exe_state <= E2;
								
							when E2 =>	
								-- go to addr in stack
								RD_RAM(DR);
								exe_state <= E3;
								
							when E3 =>
								PC(15 downto 8) <= i_ram_doByte;
								
								-- update SP
								DR <= DR - 1;	
								
								exe_state <= E4;
								
							when E4 =>
								RD_RAM(DR);
								exe_state <= E5;
								
							when E5 =>
								exe_state <= E6;
								
							when E6 =>
								-- update the appropriate PC bits
								PC(7 downto 0) <= i_ram_doByte;	
								
								DR <= DR - 1;									
								exe_state <= E7;
								
							when E7 =>
								exe_state <= E8;	

							when E8 =>
								exe_state <= E9;	
								
							when E9 =>
								WR_RAM(x81);
								
								-- new SP value is DR
								i_ram_diByte <= DR;									
								
								exe_state <= E10;
								
							when E10 =>
								RESET_S;								
								exe_state <= E11;
								
							when E11 =>
								exe_state <= E12;
								
							when E12 => 
								exe_state <= E13;
								
							when E13 => 
								exe_state <= E14;
								
							when E14 => 
								exe_state <= E15;
								
							when E15 => 
								exe_state <= E16;
								
							when E16 => 
								exe_state <= E17;
								
							when E17 => 
								exe_state <= E18;
								
							when E18 => 
								exe_state <= E19;
								
							when E19 => 
								exe_state <= E20;
								
							when E20 => 
								exe_state <= E21;
								
							when E21 => 
								--done with instruction
								exe_state <= E0;
								cpu_state <= T0;	
								
							when others =>
							
						end case;
					
					
					-- AJMP addr11
					when "00000001"|"00100001"|"01000001"|"01100001"|"10000001"|"10100001"|"11000001"|"11100001" =>
						case exe_state is
							when E0	=>
								-- get PC value
								RD_ROM(PC);
								exe_state <= E1;
								
							when E1	=>
							   -- next PC state
								PC <= PC + 1;
								exe_state <= E2;
								
							when E2	=>
								-- Change the PC to jump line
								PC <= PC(15 downto 11) & IR(7 downto 5) & i_rom_data;			
								exe_state <= E3;
								
							when E3 =>
								exe_state <= E4;
								
							when E4 => 
								exe_state <= E5;
								
							when E5 => 
								exe_state <= E6;
								
							when E6 => 
								exe_state <= E7;
								
							when E7 => 
								exe_state <= E8;
								
							when E8 => 
								exe_state <= E9;
								
							when E9 => 
								RESET_S;
								exe_state <= E10;
								
							when E10 => 
								exe_state <= E11;
								
							when E11 =>
								exe_state <= E12;
								
							when E12 => 
								exe_state <= E13;
								
							when E13 => 
								exe_state <= E14;
								
							when E14 => 
								exe_state <= E15;
								
							when E15 => 
								exe_state <= E16;
								
							when E16 => 
								exe_state <= E17;
								
							when E17 => 
								exe_state <= E18;
								
							when E18 => 
								exe_state <= E19;
								
							when E19 => 
								exe_state <= E20;
								
							when E20 => 
								exe_state <= E21;
								
							when E21 => 
								--done with instruction
								exe_state <= E0;
								cpu_state <= T0;	
								
							when others =>
							
						end case;
					
					
					-- LJMP addr16
					when "00000010" =>
						case exe_state is
							when E0 =>
								-- get first 8 bits of address
								RD_ROM(PC);
								exe_state <= E1;
								
							when E1 =>
								-- increment PC
								PC <= PC + 1;
								exe_state <= E2;
								
							when E2 =>
								-- DR has first 8 bits of address
								DR <= i_rom_data;
								
								-- get next 8 bits of address
								RD_ROM(PC);
								
								exe_state <= E3;
								
							when E3 =>
								-- increment PC
								PC <= PC + 1;
								exe_state <= E4;
								
							when E4 =>
								-- PC is updated to the 16 bit address
								PC <= DR & i_rom_data;
								exe_state <= E5;
								
							when E5 => 	 
								exe_state <= E6;
								
							when E6 => 
								exe_state <= E7;
								
							when E7 => 
								exe_state <= E8;
								
							when E8 => 
								exe_state <= E9;
								
							when E9 => 
								RESET_S;
								exe_state <= E10;
								
							when E10 => 
								exe_state <= E11;
								
							when E11 =>
								exe_state <= E12;
								
							when E12 => 
								exe_state <= E13;
								
							when E13 => 
								exe_state <= E14;
								
							when E14 => 
								exe_state <= E15;
								
							when E15 => 
								exe_state <= E16;
								
							when E16 => 
								exe_state <= E17;
								
							when E17 => 
								exe_state <= E18;
								
							when E18 => 
								exe_state <= E19;
								
							when E19 => 
								exe_state <= E20;
								
							when E20 => 
								exe_state <= E21;
								
							when E21 => 
								--done with instruction
								exe_state <= E0;
								cpu_state <= T0;	
								
							when others =>
							
						end case;
					
					
					--SJMP rel
					when "10000000" =>
						case exe_state is
							when E0	=>
								-- get rel address from code
								RD_ROM(PC);
								exe_state <= E1;
								
							when E1	=>
								-- increment PC
								PC <= PC + 1;
								exe_state <= E2;
								
							when E2	=>
								-- set ALU to add
								alu_by_wd <= '1';
								alu_op_code <= ALU_OPC_ADD;
								alu_src_1L <= PC(7 downto 0);
								alu_src_1H <= PC(15 downto 8);				
								alu_src_2L <= i_rom_data;
								
								-- decide to move up/down -> subtract/add
								if(i_rom_data(7) = '1')	then			
									alu_src_2H <= "11111111";
								else
									alu_src_2H <= "00000000";
								end if;
								
								exe_state <= E3;
								
							when E3 =>
								-- PC is updated
								PC <= alu_ans_H & alu_ans_L;	
								exe_state <= E4;
								
							when E4 =>
								exe_state <= E5;
								
							when E5 => 
								exe_state <= E6;
								
							when E6 => 
								exe_state <= E7;
								
							when E7 => 
								exe_state <= E8;
								
							when E8 => 
								exe_state <= E9;
								
							when E9 => 
								RESET_S;
								exe_state <= E10;
								
							when E10 => 
								exe_state <= E11;
								
							when E11 =>
								exe_state <= E12;
								
							when E12 => 
								exe_state <= E13;
								
							when E13 => 
								exe_state <= E14;
								
							when E14 => 
								exe_state <= E15;
								
							when E15 => 
								exe_state <= E16;
								
							when E16 => 
								exe_state <= E17;
								
							when E17 => 
								exe_state <= E18;
								
							when E18 => 
								exe_state <= E19;
								
							when E19 => 
								exe_state <= E20;
								
							when E20 => 
								exe_state <= E21;
								
							when E21 => 
								--done with instruction
								exe_state <= E0;
								cpu_state <= T0;	
								
							when others =>
							
						end case;
					
					
					--JMP @A+DPTR
					when "01110011" =>	
						case exe_state is
							when E0 =>
								--get DPH
								RD_RAM(x83);								
								exe_state <= E1;
								
							when E1 =>
								--leave one cycle to get DPH
								exe_state <= E2;
								
							when E2 =>
								DR <= i_ram_doByte;
								
								--get DPL
								RD_RAM(x82);								
								exe_state <= E3;
								
							when E3 =>
								--leave one cycle to get DPL
								exe_state <= E4;
								
							when E4 =>
								AR <= i_ram_doByte;
								
								--get ACC
								RD_RAM(xE0);
								exe_state <= E5;
								
							when E5 =>
								--leave one cycle for ACC
								exe_state <= E6;
								
							when E6 =>	
								i_ram_rdByte <= '0';
								alu_op_code <= ALU_OPC_ADD;
								alu_src_1H <= "00000000";
								alu_src_1L <= i_ram_doByte;
								alu_src_2H <= DR;
								alu_src_2L <= AR;
								alu_cy_bw <= '0';
								alu_by_wd <= '1';
								
								exe_state <= E7;
								
							when E7 =>							
								exe_state <= E8;
								
							when E8 =>
								exe_state <= E9;
								
							when E9 =>
								-- update PC
								PC <= alu_ans_H & alu_ans_L;
								exe_state <= E10;
								
							when E10 =>
								exe_state <= E11;
								
							when E11 =>
								exe_state <= E12;
								
							when E12 => 
								exe_state <= E13;
								
							when E13 => 
								RESET_S;
								exe_state <= E14;
								
							when E14 => 
								exe_state <= E15;
								
							when E15 => 
								exe_state <= E16;
								
							when E16 => 
								exe_state <= E17;
								
							when E17 => 
								exe_state <= E18;
								
							when E18 => 
								exe_state <= E19;
								
							when E19 => 
								exe_state <= E20;
								
							when E20 => 
								exe_state <= E21;
								
							when E21 => 
								--done with instruction
								exe_state <= E0;
								cpu_state <= T0;	
								
							when others =>
							
						end case;
					
					
					--JZ rel
					when "01100000" =>
						case exe_state is
							when E0	=>
								-- get value pointed to by line of code
								RD_ROM(PC);
								
								-- get accumulator value from RAM
								RD_RAM(xE0);
								
								exe_state <= E1;
								
							when E1	=>
								-- increment PC
								PC <= PC + 1;
								exe_state <= E2;
								
							when E2	=>
								-- DR has accumulator value
								DR <= i_ram_doByte;
								
								-- get rel address in AR
								AR <= i_rom_data;
								
								exe_state <= E3;
								
							when E3 =>
								-- set ALU to add
								alu_by_wd <= '1';
								alu_op_code <= ALU_OPC_ADD;
								alu_src_1L <= PC(7 downto 0);			
								alu_src_1H <= PC(15 downto 8);
								
								-- accumulator check
								if(DR = "00000000") then	
									alu_src_2L <= AR;
									-- move up/down -> add/subtract
									if(AR(7) = '1')	then				
										alu_src_2H <= "11111111";
									else
										alu_src_2H <= "00000000";
									end if;
								else										
									alu_src_2L <= "00000000";
									alu_src_2H <= "00000000";
								end if;
								
								exe_state <= E4;
								
							when E4 =>
								exe_state <= E5;
								
							when E5 =>
								exe_state <= E6;
								
							when E6 => 
								-- PC is updated
								PC <= alu_ans_H & alu_ans_L;
								exe_state <= E7;
								
							when E7 => 
								exe_state <= E8;
								
							when E8 => 
								exe_state <= E9;
								
							when E9 => 
								RESET_S;
								exe_state <= E10;
								
							when E10 => 
								exe_state <= E11;
								
							when E11 =>
								exe_state <= E12;
								
							when E12 => 
								exe_state <= E13;
								
							when E13 => 
								exe_state <= E14;
								
							when E14 => 
								exe_state <= E15;
								
							when E15 => 
								exe_state <= E16;
								
							when E16 => 
								exe_state <= E17;
								
							when E17 => 
								exe_state <= E18;
								
							when E18 => 
								exe_state <= E19;
								
							when E19 => 
								exe_state <= E20;
								
							when E20 => 
								exe_state <= E21;
								
							when E21 => 
								--done with instruction
								exe_state <= E0;
								cpu_state <= T0;	
								
							when others =>
							
						end case;
					
					
					-- JNZ rel
					when "01110000" =>
						case exe_state is
							when E0	=>
								-- get value pointed to by line of code
								RD_ROM(PC);
								
								-- get accumulator value from RAM
								RD_RAM(xE0);
								
								exe_state <= E1;
								
							when E1	=>
								-- increment PC
								PC <= PC + 1;
								exe_state <= E2;
								
							when E2	=>
								-- DR has accumulator value
								DR <= i_ram_doByte;
								
								-- get rel address in AR
								AR <= i_rom_data;
								
								exe_state <= E3;
								
							when E3 =>
								-- set ALU to add
								alu_by_wd <= '1';
								alu_op_code <= ALU_OPC_ADD;
								alu_src_1L <= PC(7 downto 0);			
								alu_src_1H <= PC(15 downto 8);
								
								-- accumulator check
								if(DR = "00000000") then	
									alu_src_2L <= "00000000";
									alu_src_2H <= "00000000";
								else										
									alu_src_2L <= AR;
									-- move up/down -> add/subtract
									if(AR(7) = '1')	then				
										alu_src_2H <= "11111111";
									else
										alu_src_2H <= "00000000";
									end if;	
								end if;
								
								exe_state <= E4;
								
							when E4 =>							
								exe_state <= E5;
								
							when E5 =>
								exe_state <= E6;
								
							when E6 => 
								-- PC is updated
								PC <= alu_ans_H & alu_ans_L;
								exe_state <= E7;
								
							when E7 => 
								exe_state <= E8;
								
							when E8 => 
								exe_state <= E9;
								
							when E9 => 
								RESET_S;
								exe_state <= E10;
								
							when E10 => 
								exe_state <= E11;
								
							when E11 =>
								exe_state <= E12;
								
							when E12 => 
								exe_state <= E13;
								
							when E13 => 
								exe_state <= E14;
								
							when E14 => 
								exe_state <= E15;
								
							when E15 => 
								exe_state <= E16;
								
							when E16 => 
								exe_state <= E17;
								
							when E17 => 
								exe_state <= E18;
								
							when E18 => 
								exe_state <= E19;
								
							when E19 => 
								exe_state <= E20;
								
							when E20 => 
								exe_state <= E21;
								
							when E21 => 
								--done with instruction
								exe_state <= E0;
								cpu_state <= T0;	
								
							when others =>
							
						end case;
					
					
					--CJNE A,direct,rel
					when "10110101" =>
						case exe_state is
							when E0 =>
								-- get direct address
								RD_ROM(PC);
								
								-- get accumulator value
								RD_RAM(xE0);
								
								exe_state <= E1;
								
							when E1 =>
								-- increment PC
								PC <= PC + 1;
								exe_state <= E2;
								
							when E2 =>
								-- DR has accumulator value
								DR <= i_ram_doByte;
								exe_state <= E3;
								
							when E3 =>
								-- get value in direct address
								RD_RAM(i_rom_data);
								exe_state <= E4;
								
							when E4 =>
								-- get rel address
								RD_ROM(PC);
								exe_state <= E5;
								
							when E5 =>
								-- increment PC
								PC <= PC + 1;
								
								-- AR has value in direct address
								AR <= i_ram_doByte;
								
								exe_state <= E6;
								
							when E6 =>
								-- set ALU to add
								alu_by_wd <= '1';
								alu_op_code <= ALU_OPC_ADD;
								alu_src_1L <= PC(7 downto 0);
								alu_src_1H <= PC(15 downto 8);
								
								-- compare value in accumulator and direst address
								if(AR = DR) then
									alu_src_2H <= "00000000";
									alu_src_2L <= "00000000";
								else
									-- src 2 has rel address
									alu_src_2L <= i_rom_data;
									
									-- decide to move up/down -> subtract/add
									if(i_rom_data(7) = '1') then		
										alu_src_2H <= "11111111";
									else
										alu_src_2H <= "00000000";
									end if;									
								end if;
								
								exe_state <= E7;
								
							when E7 =>								
								-- to write into xD7
								WR_RAM_BIT("11010111");								
								
								if(DR < AR) then
									i_ram_diBit <= '1';
								else
									i_ram_diBit <= '0';
								end if;
								
								exe_state <= E8;
								
							when E8 =>
								exe_state <= E9;
								
							when E9 =>
								-- update PC
								PC <= alu_ans_H & alu_ans_L;
								exe_state <= E10;	
								
							when E10 =>
								RESET_S;
								exe_state <= E11;
								
							when E11 =>
								exe_state <= E12;
								
							when E12 => 
								exe_state <= E13;
								
							when E13 => 
								exe_state <= E14;
								
							when E14 => 
								exe_state <= E15;
								
							when E15 => 
								exe_state <= E16;
								
							when E16 => 
								exe_state <= E17;
								
							when E17 => 
								exe_state <= E18;
								
							when E18 => 
								exe_state <= E19;
								
							when E19 => 
								exe_state <= E20;
								
							when E20 => 
								exe_state <= E21;
								
							when E21 => 
								--done with instruction
								exe_state <= E0;
								cpu_state <= T0;	
								
							when others =>
							
						end case;
					
					
					-- CJNE A, #data, rel
					when "10110100" =>
						case exe_state is
							when E0 =>
								-- get immediate data
								RD_ROM(PC);
								
								-- get accumulator value
								RD_RAM(xE0);
								
								exe_state <= E1;
								
							when E1 =>
								-- increment PC
								PC <= PC + 1;
								exe_state <= E2;
								
							when E2 =>
								-- DR has accumulator value
								DR <= i_ram_doByte;
								
								-- AR has the immediate value
								AR <= i_rom_data;
								
								exe_state <= E3;
								
							when E3 =>
								exe_state <= E4;
								
							when E4 =>
								-- get rel address
								RD_ROM(PC);
								exe_state <= E5;
								
							when E5 =>
								-- increment PC
								PC <= PC + 1;
								exe_state <= E6;
								
							when E6 =>					
								-- set ALU to add
								alu_by_wd <= '1';
								alu_op_code <= ALU_OPC_ADD;
								alu_src_1L <= PC(7 downto 0);
								alu_src_1H <= PC(15 downto 8);
								
								-- compare value in accumulator and immediate data
								if(AR = DR) then
									alu_src_2H <= "00000000";
									alu_src_2L <= "00000000";
								else
									-- src 2 has rel address
									alu_src_2L <= i_rom_data;
									
									-- decide to move up/down -> subtract/add
									if(i_rom_data(7) = '1') then		
										alu_src_2H <= "11111111";
									else
										alu_src_2H <= "00000000";
									end if;									
								end if;
								
								exe_state <= E7;
								
							when E7 =>								
								-- to write into xD7
								WR_RAM_BIT("11010111");								
								
								if(DR < AR) then
									i_ram_diBit <= '1';
								else
									i_ram_diBit <= '0';
								end if;
								
								exe_state <= E8;
								
							when E8 =>
								exe_state <= E9;
								
							when E9 =>
								-- update PC
								PC <= alu_ans_H & alu_ans_L;
								exe_state <= E10;	
								
							when E10 =>
								RESET_S;
								exe_state <= E11;
								
							when E11 =>
								exe_state <= E12;
								
							when E12 => 
								exe_state <= E13;
								
							when E13 => 
								exe_state <= E14;
								
							when E14 => 
								exe_state <= E15;
								
							when E15 => 
								exe_state <= E16;
								
							when E16 => 
								exe_state <= E17;
								
							when E17 => 
								exe_state <= E18;
								
							when E18 => 
								exe_state <= E19;
								
							when E19 => 
								exe_state <= E20;
								
							when E20 => 
								exe_state <= E21;
								
							when E21 => 
								--done with instruction
								exe_state <= E0;
								cpu_state <= T0;	
								
							when others =>
							
						end case;
					
					
					-- CJNE Rn, #data, rel
					when "10111000"|"10111001"|"10111010"|"10111011"|"10111100"|"10111101"|"10111110"|"10111111" =>
						case exe_state is
							when E0 =>
								-- get immediate data
								RD_ROM(PC);
								
								-- get the PSW
								RD_RAM(xD0);
								
								exe_state <= E1;
								
							when E1 =>
								-- increment PC
								PC <= PC + 1;
								exe_state <= E2;
								
							when E2 =>
								-- AR has immediate value
								AR <= i_rom_data;
								
								RD_RAM("000" & i_ram_doByte (4 downto 3) & IR(2 downto 0));								
								exe_state <= E3;
								
							when E3 =>
								exe_state <= E4;
								
							when E4 =>
								-- DR has the register value
								DR <= i_ram_doByte;
							
								-- get rel address
								RD_ROM(PC);
								
								exe_state <= E5;
								
							when E5 =>
								-- increment PC
								PC <= PC + 1;
								exe_state <= E6;
								
							when E6 =>					
								-- set ALU to add
								alu_by_wd <= '1';
								alu_op_code <= ALU_OPC_ADD;
								alu_src_1L <= PC(7 downto 0);
								alu_src_1H <= PC(15 downto 8);
								
								-- compare value in register and immediate data
								if(AR = DR) then
									alu_src_2H <= "00000000";
									alu_src_2L <= "00000000";
								else
									-- src 2 has rel address
									alu_src_2L <= i_rom_data;
									
									-- decide to move up/down -> subtract/add
									if(i_rom_data(7) = '1') then		
										alu_src_2H <= "11111111";
									else
										alu_src_2H <= "00000000";
									end if;									
								end if;
								
								exe_state <= E7;
								
							when E7 =>								
								-- to write into xD7
								WR_RAM_BIT("11010111");								
								
								if(DR < AR) then
									i_ram_diBit <= '1';
								else
									i_ram_diBit <= '0';
								end if;
								
								exe_state <= E8;
								
							when E8 =>
								exe_state <= E9;
								
							when E9 =>
								-- update PC
								PC <= alu_ans_H & alu_ans_L;
								exe_state <= E10;	
								
							when E10 =>
								RESET_S;
								exe_state <= E11;
								
							when E11 =>
								exe_state <= E12;
								
							when E12 => 
								exe_state <= E13;
								
							when E13 => 
								exe_state <= E14;
								
							when E14 => 
								exe_state <= E15;
								
							when E15 => 
								exe_state <= E16;
								
							when E16 => 
								exe_state <= E17;
								
							when E17 => 
								exe_state <= E18;
								
							when E18 => 
								exe_state <= E19;
								
							when E19 => 
								exe_state <= E20;
								
							when E20 => 
								exe_state <= E21;
								
							when E21 => 
								--done with instruction
								exe_state <= E0;
								cpu_state <= T0;	
								
							when others =>
							
						end case;					
					
					
					-- CJNE @Ri, #data, rel
					when "10110110" | "10110111" =>
						case exe_state is
							when E0 =>
								-- get immediate data
								RD_ROM(PC);
								
								-- get the PSW
								RD_RAM(xD0);
								
								exe_state <= E1;
								
							when E1 =>
								-- increment PC
								PC <= PC + 1;
								exe_state <= E2;
								
							when E2 =>
								-- AR has immediate value
								AR <= i_rom_data;
								
								RD_RAM("000" & i_ram_doByte (4 downto 3) & "00" & IR(0));								
								exe_state <= E3;
								
							when E3 =>
								exe_state <= E4;
								
							when E4 =>
								RD_RAM(i_ram_doByte);
							
								-- get rel address
								RD_ROM(PC);
								
								exe_state <= E5;
								
							when E5 =>
								-- increment PC
								PC <= PC + 1;
								
								-- DR has the indirect value
								DR <= i_ram_doByte;
								
								exe_state <= E6;
								
							when E6 =>	
								-- set ALU to add
								alu_by_wd <= '1';
								alu_op_code <= ALU_OPC_ADD;
								alu_src_1L <= PC(7 downto 0);
								alu_src_1H <= PC(15 downto 8);
								
								-- compare indirect value and immediate data
								if(AR = DR) then
									alu_src_2H <= "00000000";
									alu_src_2L <= "00000000";
								else
									-- src 2 has rel address
									alu_src_2L <= i_rom_data;
									
									-- decide to move up/down -> subtract/add
									if(i_rom_data(7) = '1') then		
										alu_src_2H <= "11111111";
									else
										alu_src_2H <= "00000000";
									end if;									
								end if;
								
								exe_state <= E7;
								
							when E7 =>								
								-- to write into xD7
								WR_RAM_BIT("11010111");								
								
								if(DR < AR) then
									i_ram_diBit <= '1';
								else
									i_ram_diBit <= '0';
								end if;
								
								exe_state <= E8;
								
							when E8 =>
								exe_state <= E9;
								
							when E9 =>
								-- update PC
								PC <= alu_ans_H & alu_ans_L;
								exe_state <= E10;	
								
							when E10 =>
								RESET_S;
								exe_state <= E11;
								
							when E11 =>
								exe_state <= E12;
								
							when E12 => 
								exe_state <= E13;
								
							when E13 => 
								exe_state <= E14;
								
							when E14 => 
								exe_state <= E15;
								
							when E15 => 
								exe_state <= E16;
								
							when E16 => 
								exe_state <= E17;
								
							when E17 => 
								exe_state <= E18;
								
							when E18 => 
								exe_state <= E19;
								
							when E19 => 
								exe_state <= E20;
								
							when E20 => 
								exe_state <= E21;
								
							when E21 => 
								--done with instruction
								exe_state <= E0;
								cpu_state <= T0;	
								
							when others =>
							
						end case;						
					
					
					-- DJNZ Rn, rel
					when "11011000"|"11011001"|"11011010"|"11011011"|"11011100"|"11011101"|"11011110"|"11011111" =>
						case exe_state is
							when E0 =>
								-- get rel address
								RD_ROM(PC);
								
								-- get PSW
								RD_RAM(xD0);
								
								exe_state <= E1;
								
							when E1 =>
								-- increment PC
								PC <= PC + 1;
								exe_state <= E2;
								
							when E2 =>
								-- DR has rel address
								DR <= i_rom_data;
								
								-- AR has PSW value
								AR <= i_ram_doByte;
								
								exe_state <= E3;
								
							when E3 =>
								-- get value in register (PSW has ragister bank)
								RD_RAM("000" & AR(4 downto 3) & IR(2 downto 0)); 
								exe_state <= E4;
								
							when E4 =>
								-- write new value into register
								WR_RAM("000" & AR(4 downto 3) & IR(2 downto 0));
								exe_state <= E5;
								
							when E5 =>							
								-- AR has decremented value of appropriate register
								AR <= i_ram_doByte - 1;
								exe_state <= E6;
								
							when E6 =>	
								i_ram_diByte <= AR;
								exe_state <= E7;
								
							when E7 =>
								-- set ALU to add
								alu_by_wd <= '1';
								alu_op_code <= ALU_OPC_ADD;
								alu_src_1L <= PC(7 downto 0);
								alu_src_1H <= PC(15 downto 8);								

								if(AR = "00000000") then
									alu_src_2L <= "00000000";
									alu_src_2H <= "00000000";
								else
									alu_src_2L <= DR;
									if(DR(7) = '1') then
										alu_src_2H <= "11111111";		
									else
										alu_src_2H <= "00000000";
									end if;
								end if;	
								
								exe_state <= E8;
								
							when E8 =>
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E10;
								
							when E10 => 
								-- update PC
								PC <= alu_ans_H & alu_ans_L;	
								exe_state <= E11;
								
							when E11 =>
								exe_state <= E12;
								
							when E12 => 
								exe_state <= E13;
								
							when E13 => 
								exe_state <= E14;
								
							when E14 => 
								exe_state <= E15;
								
							when E15 => 
								exe_state <= E16;
								
							when E16 => 
								exe_state <= E17;
								
							when E17 => 
								exe_state <= E18;
								
							when E18 => 
								exe_state <= E19;
								
							when E19 => 
								exe_state <= E20;
								
							when E20 => 
								exe_state <= E21;
								
							when E21 => 
								--done with instruction
								exe_state <= E0;
								cpu_state <= T0;	
								
							when others =>
							
						end case;
					
					
					--DJNZ direct, rel
					when "11010101" =>
						case exe_state is
							when E0 =>
								-- get direct address
								RD_ROM(PC);								
								exe_state <= E1;
								
							when E1 =>
								-- increment PC
								PC <= PC + 1;
								exe_state <= E2;
								
							when E2 =>
								AR <= i_rom_data;
								RD_RAM(i_rom_data);
								
								--get relative address
								RD_ROM(PC);
								
								exe_state <= E3;
								
							when E3 =>
								-- write new value into direct address
								WR_RAM(AR);
								exe_state <= E4;
								
							when E4 =>
								-- AR has decremented value of direct address
								AR <= i_ram_doByte - 1;
							
								DR <= i_rom_data;
								exe_state <= E5;
								
							when E5 =>										
								i_ram_diByte <= AR;								
								exe_state <= E6;
								
							when E6 =>	
								exe_state <= E7;
								
							when E7 =>
								-- set ALU to add
								alu_by_wd <= '1';
								alu_op_code <= ALU_OPC_ADD;
								alu_src_1L <= PC(7 downto 0);
								alu_src_1H <= PC(15 downto 8);								

								if(AR = "00000000") then
									alu_src_2L <= "00000000";
									alu_src_2H <= "00000000";
								else
									alu_src_2L <= DR;
									if(DR(7) = '1') then
										alu_src_2H <= "11111111";		
									else
										alu_src_2H <= "00000000";
									end if;
								end if;	
								
								exe_state <= E8;
								
							when E8 =>
								exe_state <= E9;
								
							when E9 =>
								exe_state <= E10;
								
							when E10 => 
								-- update PC
								PC <= alu_ans_H & alu_ans_L;	
								exe_state <= E11;
								
							when E11 =>
								exe_state <= E12;
								
							when E12 => 
								exe_state <= E13;
								
							when E13 => 
								exe_state <= E14;
								
							when E14 => 
								exe_state <= E15;
								
							when E15 => 
								exe_state <= E16;
								
							when E16 => 
								exe_state <= E17;
								
							when E17 => 
								exe_state <= E18;
								
							when E18 => 
								exe_state <= E19;
								
							when E19 => 
								exe_state <= E20;
								
							when E20 => 
								exe_state <= E21;
								
							when E21 => 
								--done with instruction
								exe_state <= E0;
								cpu_state <= T0;	
								
							when others =>
							
						end case;					
					
					
					when others =>

				end case;

			when others => 		
				exe_state <= E0;	
				cpu_state <= T0;
    
		end case; --cpu_state
		
	end if;
	end process;
end seq_arch;

-------------------------------------------------------------------------------

-- end of file --

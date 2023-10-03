// look in pins.pcf for all the pin names on the TinyFPGA BX board
module top (
    input CLK,    // 16MHz clock
    input PIN_1,
    input PIN_2,
    output LED,   // User/boot LED next to power LED
    output PIN_14,
    output PIN_15,
    output USBPU  // USB pull-up resistor
);
    // drive USB pull-up resistor to '0' to disable USB
    assign USBPU = 0;
    assign LED = 0;


    wire [7:0] port_0, port_1;
    wire reset;
    wire [7:0] port_in, port_out;
    wire [7:0] pc_count;
    wire [15:0] instruction;
    wire [7:0]	a, b, bf, data, inm, inmB, j_offset, pc_load;
    wire [7:0] d_alu, d_mem, pc_jump, pc_stack;
    wire [3:0]	address_A, address_B, address_D, opcode;
    wire vdd, c_Inm, c_extend, c_jump, zero, c_data, reg_write, mem_write, jump;
    wire s_down, s_up, c_stack;
    wire [1:0]	c_ALU, c_B;

    //TinyFPGA
    assign port_1[0] = PIN_1;
    assign port_1[1:7] = 7'b0;
    assign reset = PIN_2;
    assign port_0[0] = PIN_14;
    assign port_0[1] = PIN_15;


    // bit swizzling
    assign opcode = instruction[15:12];
    assign address_A = instruction[11:8];
    assign address_B = instruction[7:4];
    assign address_D = instruction[3:0];
    assign inm[3:0] = address_B;
    assign inm[7:4] = address_A;
    assign inmB[7:4] = {4{address_B[3]}};
    assign inmB[3:0] = address_B;
    assign j_offset = instruction[7:0];

    // procesor
    Counter 	PC	 		(CLK, reset, jump | c_jump & zero |  c_stack, pc_load, pc_count);
    ROM				mem_inst	(pc_count, instruction);
    Decoder		decode		(opcode, c_ALU, c_B, reg_write, mem_write, c_data, s_up, s_down, c_stack, c_jump);
    Reg_IO  	regs		(CLK, reg_write, address_A, address_B, address_D, data, port_1, a, b, port_0);
    ALU				ALU1		(c_ALU, a, bf, d_alu, zero);
    Adder			pc_add		(pc_count, j_offset, pc_jump);
    MUX8_2x1	mux_data	(c_data, d_alu, d_mem, data);
    RAM				mem_data	(CLK, mem_write, a, b, d_mem);
    MUX8_2x1	mux_stack	(c_stack, pc_jump, pc_stack, pc_load);
    Stack			stack		(CLK, s_up, s_down, pc_count,pc_stack);
    MUX8_4x1	select_B	(c_B, b, inm, inmB, 8'b0, bf);

    ////////
    // make a simple blink circuit
    ////////
    //not (PIN_14, PIN_1);
      //assign PIN_15 = PIN_1;
    //nand (PIN_15, PIN_14, PIN_14);
    // keep track of time and location in blink_pattern

endmodule

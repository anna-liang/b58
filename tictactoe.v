/* Wild Misere Tic Tac Toe

Wild Misere Tic Tac Toe is a variation of the classic Tic Tac Toe game.
The "Wild" factor involves allowing a player to choose if they wish to
play an 'X' or an 'O' on each turn.
The "Misere" factor puts a twist on the ending condition of the game.
The goal is to avoid playing three X's or three O's in a row.
Whoever plays three letters in a row loses the game.

This game involves taking the input of the position (1-9) of the move and the
choice of 'X' or 'O' from the keyboard, and displays the game on a
VGA monitor.

*/
module tictactoe
	(
		CLOCK_50,						//	On Board 50 MHz
        SW,
		// The ports below are for the VGA output
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B,   						//	VGA Blue[9:0]
		PS2_KBDAT,						//	PS2 Keyboard Data
		PS2_KBCLK,						// 	PS2 Keyboard Clock
		HEX0,								// Hex dispays
		HEX2,
		HEX4,							
		HEX5,
	);

	input	CLOCK_50;				//	50 MHz
	input PS2_KBDAT;
	input PS2_KBCLK;
	wire [7:0] kb_scan_code;

	input   [17:0]   SW;

	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	output 	[6:0] HEX0;
	output 	[6:0]	HEX2;
	output 	[6:0] HEX4;
	output 	[6:0]	HEX5;
	
	// Create wires for loads, write, draw, reset, and data
	reg go;
	wire writeEn;
	reg resetn;
	wire drawEn;
	reg [1:0] data_in;
	wire data_result;
	wire ld_p1;
	wire ld_p2;
	wire ld_pos;
	wire check;
	wire [1:0] s1, s2, s3, s4, s5, s6, s7, s8, s9, turn;
	reg [3:0] pos;

	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;

	// Create wires for keyboard module
	wire [6:0] ASCII_value;
	wire kb_sc_ready;
	wire kb_letter_case;
	
	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	
	vga_adapter VGA(
		.resetn(resetn),
		.clock(CLOCK_50),
		.colour(colour),
		.x(x),
		.y(y),	
		.plot(writeEn),
		/* Signals for the DAC to drive the monitor. */
		.VGA_R(VGA_R),
		.VGA_G(VGA_G),
		.VGA_B(VGA_B),
		.VGA_HS(VGA_HS),
		.VGA_VS(VGA_VS),
		.VGA_BLANK(VGA_BLANK_N),
		.VGA_SYNC(VGA_SYNC_N),
		.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";


	// Instansiate Keyboard module
    keyboard kd(
        .clk(CLOCK_50),
        .reset(resetn),
        .ps2d(PS2_KBDAT),
        .ps2c(PS2_KBCLK),
        .scan_code(kb_scan_code),
        .scan_code_ready(kb_sc_ready),
        .letter_case_out(kb_letter_case)
    );

    // Instansiate ascii converter
    keytoascii ascii(
        .ascii_code(ASCII_value),
        .scan_code(kb_scan_code),
        .letter_case(kb_letter_case)
    );

	// Decode the ascii
	always@(CLOCK_50)
	begin		
		// Data in is 10 or 01, default 00
		case(ASCII_value)
			8'h62 : data_in <= 2'b01; // Move type is B, data_in is 01
			8'h72 : data_in <= 2'b10; // Move type is R, data_in is 10
			default : data_in <= 2'b00; // Default to 0
		endcase
	end
	
	always@(CLOCK_50)
	begin
		// Pos is 4 bit 1-9, default 0
		case (ASCII_value)
			8'h31 : pos <= 4'b0001; // Cell number 1, pos is 1 in binary
			8'h32 : pos <= 4'b0010; // Cell number 1, pos is 1 in binary
			8'h33 : pos <= 4'b0011; // Cell number 1, pos is 1 in binary
			8'h34 : pos <= 4'b0100; // Cell number 1, pos is 1 in binary
			8'h35 : pos <= 4'b0101; // Cell number 1, pos is 1 in binary
			8'h36 : pos <= 4'b0110; // Cell number 1, pos is 1 in binary
			8'h37 : pos <= 4'b0111; // Cell number 1, pos is 1 in binary
			8'h38 : pos <= 4'b1000; // Cell number 1, pos is 1 in binary
			8'h39 : pos <= 4'b1001; // Cell number 1, pos is 1 in binary
			default : pos <= 4'b000; // Default to 0
		endcase
	end
	
	
	always@(CLOCK_50)
	begin		
		// "GO" active high(Enter key)
		case(ASCII_value)
			8'h0A : go <= 1'b0;
			default : go <= 1'b1; // Default to 0
		endcase
	end
	
	
    // Instansiate datapath
	datapath d0(
		.ld_p1(ld_p1),
		.ld_p2(ld_p2),
		.data_in(data_in),
	    .pos(pos),
	    .ld_pos(ld_pos),
	    .drawEn(drawEn),  
	    .resetn(resetn),
	    .clock(CLOCK_50),
	    .s1(s1),
	    .s2(s2),
	    .s3(s3),
	    .s4(s4),
	    .s5(s5),
	    .s6(s6),
	    .s7(s7),
	    .s8(s8),
	    .s9(s9),
		.x_out(x),
	    .y_out(y),
	    .col_out(colour),
		.col(SW[9:7]),
	   	.ld_x(ld_x),
	   	.ld_y(ld_y),
	   	.ld_c(ld_c)
	);

    // Instansiate FSM control
	control c0(
		.go(go),
	   	.resetn(resetn),
	   	.clock(CLOCK_50),
	   	.check(check),
	   	.ld_p1(ld_p1),
	   	.ld_p2(ld_p2),
	   	.ld_pos(ld_pos),
	   	.writeEn(writeEn),
	   	.drawEn(drawEn),
	   	.ld_x(ld_x),
	   	.ld_y(ld_y),
	  	.ld_c(ld_c)
	);

	// Instansiate checking
	check_end e0(
	    .s1(s1),
	    .s2(s2),
	    .s3(s3),
	    .s4(s4),
	    .s5(s5),
	    .s6(s6),
	    .s7(s7),
	    .s8(s8),
	    .s9(s9),
	    .turn(turn),
	    .check(check),
	    .data_result(data_result)
	);
    

	// DISPLAY KEYBOARD INPUT TO HEX4 AND HEX5
	hex_display hex0(
		.IN(data_in[1:0]),
		.OUT(HEX0[6:0])
	);
	
	hex_display hex2(
	.IN(pos[3:0]),
	.OUT(HEX2[6:0])
	);

	hex_display hex4(
		.IN(ASCII_value[3:0]),
		.OUT(HEX4[6:0])
	);
	
	hex_display hex5(
		.IN(ASCII_value[6:4]),
		.OUT(HEX5[6:0])
	);


endmodule

module datapath(ld_p1, ld_p2, data_in, pos, ld_pos, drawEn, resetn, clock, s1, s2, s3, s4, s5, s6, s7, s8, s9, x_out, y_out, col_out, col, ld_x, ld_y, ld_c);
	input [1:0] data_in; // X or O
	input [3:0] pos; // Cell
	input ld_p1, ld_p2, ld_pos, drawEn, resetn, clock, ld_x, ld_y, ld_c;
	input [2:0] col;

	// Registers for each square of the grid
	output reg [1:0] s1, s2, s3, s4, s5, s6, s7, s8, s9;
	output [7:0] x_out;
	output [6:0] y_out;
	output [2:0] col_out;

	// Input registers for player 1, player 2, and square on grid
	reg [1:0] p1, p2;
	reg [3:0] position;

	// Registers for counter, x, y positions and colour
	reg [3:0] counter;
	reg [7:0] x;
	reg [6:0] y;
	reg [2:0] c;

	always @(posedge clock)
	begin
		// Reset all registers
		if (!resetn)
		begin
			p1 <= 2'b0;
			p2 <= 2'b0;
			position <= 4'b0;
			s1 <= 2'b0;
			s2 <= 2'b0;
			s3 <= 2'b0;
			s4 <= 2'b0;
			s5 <= 2'b0;
			s6 <= 2'b0;
			s7 <= 2'b0;
			s8 <= 2'b0;
			s9 <= 2'b0;
			x = 8'b00000000;
			y = 7'b0000000;
			c = 3'b000;
		end
		// Load data values
		else
		begin
			// ****might not need player registers or position register***
			// Loading player choices in player registers
			if (ld_p1)
				p1 <= data_in;
			if (ld_p2)
				p2 <= data_in;
			// Loading square position in position register
			if (ld_pos)
				position <= pos;
			// If a player has been loaded
			if (ld_p1 || ld_p2)
			begin
				// Move value into appropriate square register
				case (pos)
					4'b0001: s1 <= data_in;
					4'b0010: s2 <= data_in;
					4'b0011: s3 <= data_in;
					4'b0100: s4 <= data_in;
					4'b0101: s5 <= data_in;
					4'b0110: s6 <= data_in;
					4'b0111: s7 <= data_in;
					4'b1000: s8 <= data_in; 
					4'b1001: s9 <= data_in;
					default: s1 <= 4'b0;
				endcase
			end

			if (ld_x)
				x <= {1'b0, position};
			else if (ld_y)
				y <= position;
			else if (ld_c)
				c <= col;			
		end
	end

	always @(posedge clock)
	begin
		if (!resetn)
			x_out <= 7'b0;
			y_out <= 6'b0;
			col_out <= 3'b0;
			counter <= 5'b0000;
		else if (drawEn)
		begin
			x_out <= x + counter[1:0];
			y_out <= y + counter[4:2];
			if (counter == 5'b11111)
				counter <= 5'b00000;
			else
				counter <= counter + 1'b1;
		end
	end


	assign col_out = c;


endmodule

module control(go, resetn, clock, check, ld_p1, ld_p2, ld_pos, writeEn, drawEn, turn, ld_x, ld_y, ld_c);

	// Declare inputs, outputs, wires, and regs
	input go, resetn, clock, check;
	output reg ld_p1, ld_p2, ld_pos, writeEn, drawEn, ld_x, ld_y, ld_c;
	output reg [1:0] turn;
	
	reg [5:0] curr_state, next_state;

	// Declare states
	localparam  S_LOAD_P1_POS	 		= 5'd0,
				S_LOAD_P1_POS_WAIT 		= 5'd1,
				S_LOAD_P1        		= 5'd2,
				S_LOAD_P1_WAIT   		= 5'd3,
				S_LOAD_X_1              = 5'd4,
				S_LOAD_X_WAIT_1         = 5'd5,
				S_LOAD_Y_1              = 5'd6,
				S_LOAD_Y_WAIT_1         = 5'd7,
				S_LOAD_C_1              = 5'd8,
				S_LOAD_C_WAIT_1         = 5'd9,
				S_DRAW_P1 	  	 		= 5'd10,
				S_CHECK_P1       		= 5'd11,
				S_LOAD_P2_POS	 		= 5'd12,
				S_LOAD_P2_POS_WAIT 		= 5'd13,
				S_LOAD_P2        		= 5'd14,
				S_LOAD_P2_WAIT   		= 5'd15,
				S_LOAD_X_2              = 5'd16,
				S_LOAD_X_WAIT_2         = 5'd17,
				S_LOAD_Y_2              = 5'd18,
				S_LOAD_Y_WAIT_2         = 5'd19,
				S_LOAD_C_2              = 5'd20,
				S_LOAD_C_WAIT_2         = 5'd21,
				S_DRAW_P2     	 		= 5'd22,
				S_CHECK_P2       		= 5'd23,
				S_END_P1         		= 5'd24,
				S_END_P2	     		= 5'd25;

	// State table logic
    always@(*)
    begin: state_table 
            case (curr_state)
				S_LOAD_P1_POS: next_state = go ? S_LOAD_P1_POS_WAIT : S_LOAD_P1_POS; // Loop in current state until player 1 enters a square
				S_LOAD_P1_POS_WAIT: next_state = go ? S_LOAD_P1_POS_WAIT : S_LOAD_P1; // Loop in current state until go signal goes low
				S_LOAD_P1: next_state = go ? S_LOAD_P1_WAIT : S_LOAD_P1; // Loop in current state until player 1 enters a value
				S_LOAD_P1_WAIT: next_state = go ? S_LOAD_P1_WAIT : S_LOAD_X_1; // Loop in current state until go signal goes low
				S_LOAD_X_1: next_state = go ? S_LOAD_X_WAIT_1 : S_LOAD_X_1;
				S_LOAD_X_WAIT_1: next_state = go ? S_LOAD_X_WAIT_1 : S_LOAD_Y_1;
				S_LOAD_Y_1: next_state = go ? S_LOAD_Y_WAIT_1 : S_LOAD_Y_1;
				S_LOAD_Y_WAIT_1: next_state = go ? S_LOAD_Y_WAIT_1 : S_LOAD_C_1;
				S_LOAD_C_1: next_state = go ? S_LOAD_C_WAIT_1 : S_LOAD_C_1;
				S_LOAD_C_WAIT_1: next_state = go ? S_LOAD_C_WAIT_1 : S_DRAW_P1;
				S_DRAW_P1: next_state = go ? S_CHECK_P1 : S_DRAW_P1;	// Move into the checking state for player 1
				S_CHECK_P1: next_state = check ? S_END_P1 : S_LOAD_P2_POS; // End the game or move to take player 2's inputs
				S_LOAD_P2_POS: next_state = go ? S_LOAD_P2_POS_WAIT : S_LOAD_P2_POS; // Loop in current state until player 2 enters a square
				S_LOAD_P2_POS_WAIT: next_state = go ? S_LOAD_P2_POS_WAIT : S_LOAD_P2; // Loop in current state until go signal goes low
				S_LOAD_P2: next_state = go ? S_LOAD_P2_WAIT : S_LOAD_P2; // Loop in current state until player 2 enters a value
				S_LOAD_P2_WAIT: next_state = go ? S_LOAD_P2_WAIT : S_LOAD_X_2; // Loop in current state until go signal goes low
				S_LOAD_X_2: next_state = go ? S_LOAD_X_WAIT_2 : S_LOAD_X_2;
				S_LOAD_X_WAIT_2: next_state = go ? S_LOAD_X_WAIT_2 : S_LOAD_Y_2;
				S_LOAD_Y_2: next_state = go ? S_LOAD_Y_WAIT_2 : S_LOAD_Y_2;
				S_LOAD_Y_WAIT_2: next_state = go ? S_LOAD_Y_WAIT_2 : S_LOAD_C_2;
				S_LOAD_C_2: next_state = go ? S_LOAD_C_WAIT_2 : S_LOAD_C_2;
				S_LOAD_C_WAIT_2: next_state = go ? S_LOAD_C_WAIT_2 : S_DRAW_P2;
				S_DRAW_P2: next_state = go ? S_CHECK_P2 : S_DRAW_P2; // Move into the checking state for player 2
				S_CHECK_P2: next_state = check ? S_END_P2 : S_LOAD_P1_POS; // End the game or move to take player 1's inputs
            default:     next_state = S_LOAD_P1_POS;
        endcase
    end // state_table
	
	always @(*)
	begin: signals
		// Set all to a default 0
		ld_p1 = 1'b0;
		ld_p2 = 1'b0;
		ld_pos = 1'b0;
		writeEn = 1'b0;
		drawEn = 1'b0;
		turn = 2'b00;
		ld_x = 1'b0;
		ld_y = 1'b0;
		ld_c = 1'b0;
		case (curr_state)
			S_LOAD_P1_POS: begin	// Load player 1's square
				ld_pos = 1'b1;
				end
			S_LOAD_P1: begin	// Load player 1's move
				ld_p1 = 1'b1;
				end
			S_LOAD_P2_POS: begin // Load player 2's square
				ld_pos = 1'b1;
				end
			S_LOAD_P2: begin	// Load player 2's move
				ld_p2 = 1'b1;
				end
			S_LOAD_X_1: begin
				ld_x = 1'b1;
				end
			S_LOAD_Y_1: begin
				ld_y = 1'b1;
				end
			S_LOAD_C_1: begin
				ld_c = 1'b1;
				end
			S_DRAW_P1: begin	// Draw player 1's move
				writeEn = 1'b1;
				drawEn = 1'b1;
				end
			S_CHECK_P1: begin	// Tells check it's player 1's turn
				turn = 2'b01;
				end
			S_LOAD_X_2: begin
				ld_x = 1'b1;
				end
			S_LOAD_Y_2: begin
				ld_y = 1'b1;
				end
			S_LOAD_C_2: begin
				ld_c = 1'b1;
				end
			S_DRAW_P2: begin	// Draw player 2's move
				writeEn = 1'b1;
				drawEn = 1'b1;
				end
			S_CHECK_P2: begin	// Tells check it's player 2's turn
				turn = 2'b10;
				end
		endcase
	end
	
	// Move to the next state on the next positive clock edge
	always@(posedge clock)
	begin: state_FFs
        if(!resetn)
            curr_state <= S_LOAD_P1_POS;	// Move back to loading player 1's square if reset
        else
            curr_state <= next_state; 	// Otherwise, move to the next state
   end
endmodule

/* Checks the end conditions of the game.
Determines if there are three letters in a row, if there is a tie, or if the game continues
*/
module check_end(s1, s2, s3, s4, s5, s6, s7, s8, s9, turn, check, data_result);
	input [1:0] s1, s2, s3, s4, s5, s6, s7, s8, s9, turn;
	output reg check;
	output reg [1:0] data_result;
	
	// Temp wires for end combinations
	wire [1:0] t1, t2, t3, t4, t5, t6, t7, t8;
	// Temp wires for calculation
	wire check1, check2;
	
	// Check rows for a loss
	assign t1 = s1 & s2 & s3;
	assign t2 = s4 & s5 & s6;
	assign t3 = s7 & s8 & s9;
	
	// Check columns for a loss
	assign t4 = s1 & s4 & s7;
	assign t5 = s2 & s5 & s8;
	assign t6 = s3 & s6 & s9;
	
	// Check diagonals for a loss
	assign t7 = s1 & s5 & s9;
	assign t8 = s3 & s5 & s7;
	
	// Determine if there is a winner based on the presence of a high bit
	assign check1 = (t1[0] | t2[0] | t3[0] | t4[0] | t5[0] | t6[0] | t7[0] | t8[0]);
	assign check2 = (t1[1] | t2[1] | t3[1] | t4[1] | t5[1] | t6[1] | t7[1] | t8[1]);
	
	always@(*)
	begin
		// If we have 01 or 10, the player who just made a move lost
		if (check1 || check2)
		begin
			// Check being high means the game ended
			check <= 1'b1;
			// If it was player 1's turn, they lose
			if (turn == 2'b01)
				data_result <= 2'b10;
			// If it was player 2's turn, they lose
			else if (turn == 2'b10)
				data_result <= 2'b01;
		end
		// Otherwise, we have 00 for everything
		// Either the game has not ended yet, or the game ended in a tie
		else
		begin
			// If any of the squares have 00, that means the square is empty
			// i.e. the game has not ended yet
			if (s1 == 2'b0 || s2 == 2'b0 || s3 == 2'b0 || s4 == 2'b0 || s5 == 2'b0 || s6 == 2'b0 || s7 == 2'b0 || s8 == 2'b0 || s9 == 2'b0)
			begin
				// Set everything to low
				check <= 1'b0;
				data_result <= 2'b00;
			end
			// Otherwise, we have a tie
			else
			begin
				// Set everything to high
				check <= 1'b1;
				data_result <= 2'b11;
			end
		end
	end

endmodule



module hex_display(IN, OUT);
    input [3:0] IN;
	 output reg [6:0] OUT;
	 
	 always @(*)
	 begin
		case(IN[3:0])
			4'b0000: OUT = 7'b1000000;
			4'b0001: OUT = 7'b1111001;
			4'b0010: OUT = 7'b0100100;
			4'b0011: OUT = 7'b0110000;
			4'b0100: OUT = 7'b0011001;
			4'b0101: OUT = 7'b0010010;
			4'b0110: OUT = 7'b0000010;
			4'b0111: OUT = 7'b1111000;
			4'b1000: OUT = 7'b0000000;
			4'b1001: OUT = 7'b0011000;
			4'b1010: OUT = 7'b0001000;
			4'b1011: OUT = 7'b0000011;
			4'b1100: OUT = 7'b1000110;
			4'b1101: OUT = 7'b0100001;
			4'b1110: OUT = 7'b0000110;
			4'b1111: OUT = 7'b0001110;
			
			default: OUT = 7'b0111111;
		endcase

	end
endmodule

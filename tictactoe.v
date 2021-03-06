/* Wild Misere Tic Tac Toe

Wild Misere Tic Tac Toe is a variation of the classic Tic Tac Toe game.
The "Wild" factor involves allowing a player to choose if they wish to
play an X or O on each turn.
The "Misere" factor puts a twist on the ending condition of the game.
The goal is to avoid playing three X's or three O's in a row.
Whoever plays three X/O's in a row loses the game.

This game involves taking the input of the position (1-9) of the move and the
choice of X or O from the keyboard, and displays the game on the hex displays of the DE2 Board
*/

module tictactoe (
		CLOCK_50,						//	On Board 50 MHz
        SW,
		KEY,
		PS2_KBDAT,						//	PS2 Keyboard Data
		PS2_KBCLK,						// 	PS2 Keyboard Clock
		HEX0,
		HEX1,		// Hex dispays
		HEX2,
		HEX3,
		HEX4,							
		HEX5,
		HEX6,
		HEX7
	);

	input CLOCK_50;							//	50 MHz
	input PS2_KBDAT;
	input PS2_KBCLK;
	wire [7:0] kb_scan_code;

	input 	[17:0]	SW;
	input 	[3:0] 	KEY;

	// HEX outputs
	output 	[6:0] 	HEX0;
	output 	[6:0] 	HEX1;
	output 	[6:0]	HEX2;
	output 	[6:0] 	HEX3;
	output 	[6:0] 	HEX4;
	output 	[6:0]	HEX5;
	output 	[6:0]	HEX6;
	output 	[6:0]	HEX7;
	
	// Create wires for loads, write, draw, reset, and data
	wire go;
	assign go = SW[16];
	wire writeEn;
	wire resetn;
	assign resetn = SW[17];
	wire drawEn;
	reg [1:0] move;
//	assign move = SW[1:0];
	wire [1:0] winner;
	wire ld_p1;
	wire ld_p2;
	wire ld_pos;
	wire check;
	wire [1:0] s1, s2, s3, s4, s5, s6, s7, s8, s9, turn;
	reg [3:0] pos;
//	assign pos = SW[7:4];

	// Create wires for keyboard module
	wire [7:0] ASCII_value;
	wire kb_sc_ready;
	wire kb_letter_case;

	// For cycling through hex displays
	wire [2:0] drc_out;
	wire [27:0] rd_out;
	reg [27:0] rd_in;
	reg [1:0] hex0pos, hex1pos, hex2pos;
	reg hex_counter_enable;
	wire [3:0] position;

	// Instansiate Keyboard module
    keyboard kd(
        .clk(CLOCK_50),
        .reset(~resetn),
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


	// Same as above but using if statements
	always@(CLOCK_50)
	begin
		if(ASCII_value == 8'h78)	// Move type is x, move is 01
			begin
			move <= 2'b01;
			pos <= 4'b0000;
			end
		else if(ASCII_value == 8'h6F)	// Move type is o, move is 10
			begin
			move <= 2'b10;
			pos <= 4'b0000;
			end
		else if(ASCII_value == 8'h31)	// Each case below is for cell nums 1-9 that sets pos to 1-9 in bindary
			begin
			move <= 2'b00;
			pos <= 4'b0001;
			end
		else if(ASCII_value == 8'h32)
			begin
			move <= 2'b00;
			pos <= 4'b0010;
			end
		else if(ASCII_value == 8'h33)
			begin
			move <= 2'b00;
			pos <= 4'b0011;
			end
		else if(ASCII_value == 8'h34)
			begin
			move <= 2'b00;
			pos <= 4'b0100;
			end
		else if(ASCII_value == 8'h35)
			begin
			move <= 2'b00;
			pos <= 4'b0101;
			end
		else if(ASCII_value == 8'h36)
			begin
			move <= 2'b00;
			pos <= 4'b0110;
			end
		else if(ASCII_value == 8'h37)
			begin
			move <= 2'b00;
			pos <= 4'b0111;
			end
		else if(ASCII_value == 8'h38)
			begin
			move <= 2'b00;
			pos <= 4'b1000;
			end
		else if(ASCII_value == 8'h39)
			begin
			move <= 2'b00;
			pos <= 4'b1001;
			end
		else	// Any other key is pressed
			begin
			move <= 2'b00;
			pos <= 4'b000;
			end
	end
	
	
	
	// rate is 2 sec
	always @(posedge CLOCK_50)
	begin
		rd_in = 28'b101111101011110000100000000;
	end

	// pulse every 2 sec
	always @(posedge CLOCK_50)
	begin
		hex_counter_enable <= (rd_out[27:0] == 28'b0) ? 1 : 0;
	end

	always @(posedge CLOCK_50)
	begin
		// if the counter is 1, then display row 1
		if(drc_out == 3'b001)
		begin
			hex0pos = s1;
			hex1pos = s2;
			hex2pos = s3;
		end
		// if the counter is 2, then display row 2
		else if(drc_out == 3'b010)
		begin
			hex0pos = s4;
			hex1pos = s5;
			hex2pos = s6;
		end
		// if the counter is 3, then display row 3
		else if(drc_out == 3'b011)
		begin
			hex0pos = s7;
			hex1pos = s8;
			hex2pos = s9;
		end
	end

	// RATE DIVIDER AND DISPLAY COUNTER
	rate_divider rd(
		.q(rd_out[27:0]),
		.d(rd_in[27:0]),
		.clock(CLOCK_50),
		.clear_b(resetn),
	);

	display_row_counter drc(
		.q(drc_out[2:0]),
		.clock(CLOCK_50),
		.clear_b(resetn),
		.enable(hex_counter_enable)
	);

    // Instansiate datapath
	datapath d0(
		.ld_p1(ld_p1),
		.ld_p2(ld_p2),
		.move(move),
	    .pos(pos),
	    .ld_pos(ld_pos),
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
		.position(position)
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
		.turn(turn[1:0])
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
	    .turn(turn[1:0]),
	    .check(check),
	    .winner(winner)
	);

	// DISPLAY KEYBOARD INPUT TO HEX4 AND HEX5

	move_hexdisplay hex0(
		.IN(hex2pos),
		.OUT(HEX0[6:0])
	);

	move_hexdisplay hex1(
		.IN(hex1pos),
		.OUT(HEX1[6:0])
	);

	move_hexdisplay hex2(
		.IN(hex0pos),
		.OUT(HEX2[6:0])
	);
	
	hex_display hex3(
		.IN(drc_out[1:0]),
		.OUT(HEX3[6:0])
	);
	
	// selected move
	move_hexdisplay hex4(
		.IN(move[1:0]),
		.OUT(HEX4[6:0])
	);
	
	
	// selected position
	hex_display hex5(
		.IN(pos[3:0]),
		.OUT(HEX5[6:0])
	);
	
	// turn
	hex_display hex6(
		.IN(turn[1:0]),
		.OUT(HEX6[6:0])
	);
	
	// winner
	hex_display hex7(
		.IN(winner[1:0]),
		.OUT(HEX7[6:0])
	);
	
endmodule

module rate_divider(q, d, clock, clear_b);
	input wire [27:0] d;
	input clock;
	input clear_b;
	output reg [27:0] q;

	always @(posedge clock)
	begin
		if(clear_b == 1'b0 || q == 28'b0)
			q <= d;
		else
			q <= q - 1'b1;
	end
endmodule

module display_row_counter(q, clock, clear_b, enable);
	input clock;
	input clear_b;
	input enable;
	output reg [2:0] q;

	always @(posedge clock)
	begin
		if(clear_b == 1'b0 || q == 3'b100)
			q <= 1'b1;
		else if(enable == 1'b1)
			q <= q + 1'b1;
	end
endmodule

module datapath(ld_p1, ld_p2, move, pos, ld_pos, resetn, clock, s1, s2, s3, s4, s5, s6, s7, s8, s9, position);
	input [1:0] move; // O (10) or X (01)
	input [3:0] pos; // Cell (1-9 in binary)
	input ld_p1, ld_p2, ld_pos, resetn, clock;

	// Registers for each square of the grid
	output reg [1:0] s1, s2, s3, s4, s5, s6, s7, s8, s9;

	// Input registers for player 1, player 2, and square on grid
	reg [1:0] p1, p2;
	output reg [3:0] position;

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
		end
		// Load data values
		else
		begin
			// Loading player choices in player registers
			if (ld_p1)
				p1 <= move;
			else if (ld_p2)
				p2 <= move;
			// Loading square position in position register
			if (ld_pos)
				position <= pos;
			// If a player has been loaded
			if (ld_p1 || ld_p2)
			begin
				// Move value into appropriate square register by storing move
				if (position == 4'b0001)
					s1 <= move;
				else if (position == 4'b0010)
					s2 <= move;
				else if (position == 4'b0011)	
					s3 <= move;
				else if (position == 4'b0100)	
					s4 <= move;
				else if (position == 4'b0101)	
					s5 <= move;
				else if (position == 4'b0110)	
					s6 <= move;
				else if (position == 4'b0111)	
					s7 <= move;
				else if (position == 4'b1000)
					s8 <= move;
				else if (position == 4'b1001)	
					s9 <= move;
			end
		end
	end
endmodule

module control(go, resetn, clock, check, ld_p1, ld_p2, ld_pos, turn);
	// Declare inputs, outputs, wires, and regs
	input go, resetn, clock, check;
	output reg ld_p1, ld_p2, ld_pos;
	output reg [1:0] turn;
	
	reg [5:0] curr_state, next_state;

	// Declare states
	localparam  S_LOAD_P1_POS	 		= 5'd0,
				S_LOAD_P1_POS_WAIT 		= 5'd1,
				S_LOAD_P1        		= 5'd2,
				S_LOAD_P1_WAIT   		= 5'd3,
				S_CHECK_P1       		= 5'd4,
				S_LOAD_P2_POS	 		= 5'd5,
				S_LOAD_P2_POS_WAIT 		= 5'd6,
				S_LOAD_P2        		= 5'd7,
				S_LOAD_P2_WAIT   		= 5'd8,
				S_CHECK_P2       		= 5'd9,
				S_END_P1         		= 5'd10,
				S_END_P2	     		= 5'd11;

	// State table logic
    always@(*)
    begin: state_table 
            case (curr_state)
				S_LOAD_P1_POS: next_state = go ? S_LOAD_P1_POS_WAIT : S_LOAD_P1_POS; // Loop in current state until player 1 enters a square
				S_LOAD_P1_POS_WAIT: next_state = go ? S_LOAD_P1_POS_WAIT : S_LOAD_P1; // Loop in current state until go signal goes low
				S_LOAD_P1: next_state = go ? S_LOAD_P1_WAIT : S_LOAD_P1; // Loop in current state until player 1 enters a value
				S_LOAD_P1_WAIT: next_state = go ? S_LOAD_P1_WAIT : S_CHECK_P1; // Loop in current state until go signal goes low
				S_CHECK_P1: next_state = check ? S_END_P1 : S_LOAD_P2_POS; // End the game or move to take player 2's inputs
				S_LOAD_P2_POS: next_state = go ? S_LOAD_P2_POS_WAIT : S_LOAD_P2_POS; // Loop in current state until player 2 enters a square
				S_LOAD_P2_POS_WAIT: next_state = go ? S_LOAD_P2_POS_WAIT : S_LOAD_P2; // Loop in current state until go signal goes low
				S_LOAD_P2: next_state = go ? S_LOAD_P2_WAIT : S_LOAD_P2; // Loop in current state until player 2 enters a value
				S_LOAD_P2_WAIT: next_state = go ? S_LOAD_P2_WAIT : S_CHECK_P2; // Loop in current state until go signal goes low
				S_CHECK_P2: next_state = check ? S_END_P2 : S_LOAD_P1_POS; // End the game or move to take player 1's inputs
            default:	next_state = S_LOAD_P1_POS;
        endcase
    end // state_table
	
	always @(*)
	begin: signals
//		// Set all to a default 0
//		ld_p1 = 1'b0;
//		ld_p2 = 1'b0;
//		ld_pos = 1'b0;
//		turn = 2'b00;
		case (curr_state)
			S_LOAD_P1_POS:	// Load player 1's square
			begin
				ld_p1 = 1'b0;
				ld_p2 = 1'b0;
				ld_pos = 1'b1;
				turn = 2'b01;
			end
			S_LOAD_P1_POS_WAIT:
			begin
				ld_p1 = 1'b0;
				ld_p2 = 1'b0;
				ld_pos = 1'b1;
				turn = 2'b01;
			end
			S_LOAD_P1: // Load player 1's move
			begin
				ld_p1 = 1'b1;
				ld_p2 = 1'b0;
				ld_pos = 1'b0;
				turn = 2'b01;
			end
			S_LOAD_P1_WAIT:
			begin
				ld_p1 = 1'b1;
				ld_p2 = 1'b0;
				ld_pos = 1'b0;
				turn = 2'b01;
			end
			S_LOAD_P2_POS:  // Load player 2's square
			begin
				ld_p1 = 1'b0;
				ld_p2 = 1'b0;
				ld_pos = 1'b1;
				turn = 2'b10;
			end
			S_LOAD_P2_POS_WAIT:
			begin
				ld_p1 = 1'b0;
				ld_p2 = 1'b0;
				ld_pos = 1'b1;
				turn = 2'b10;
			end
			S_LOAD_P2: 	// Load player 2's move
			begin
				ld_p1 = 1'b0;
				ld_p2 = 1'b1;
				ld_pos = 1'b0;
				turn = 2'b10;
			end
			S_LOAD_P2_WAIT:
			begin
				ld_p1 = 1'b0;
				ld_p2 = 1'b1;
				ld_pos = 1'b0;
				turn = 2'b10;
			end
			S_CHECK_P1: 	// Tells check it's player 1's turn
			begin
				ld_p1 = 1'b0;
				ld_p2 = 1'b0;
				ld_pos = 1'b0;
				turn = 2'b01;
			end
			S_CHECK_P2: 	// Tells check it's player 2's turn
			begin
				ld_p1 = 1'b0;
				ld_p2 = 1'b0;
				ld_pos = 1'b0;
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
Determines if there are three tiles in a row, if there is a tie, or if the game continues
*/
module check_end(s1, s2, s3, s4, s5, s6, s7, s8, s9, turn, check, winner);
	input [1:0] s1, s2, s3, s4, s5, s6, s7, s8, s9, turn;
	output reg check;
	output reg [1:0] winner;
	
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
				winner <= 2'b10;
			// If it was player 2's turn, they lose
			else if (turn == 2'b10)
				winner <= 2'b01;
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
				winner <= 2'b00;
			end
			// Otherwise, we have a tie
			else
			begin
				// Set everything to high
				check <= 1'b1;
				winner <= 2'b11;
			end
		end
	end
endmodule


// Hex decoder module for outputting X or O to a hex display
module move_hexdisplay(IN, OUT);
	input [1:0] IN;
	output reg [6:0] OUT;

	always@(*)
	begin
		case(IN[1:0])
			2'b01 : OUT <= 7'b0001001; // Outputs X => H
			2'b10 : OUT <= 7'b1000000; // Outputs O => 0
			default : OUT <= 7'b0111111; // Default displays -
		endcase
	end
endmodule

/* HEX Display module
*/
module hex_display(IN, OUT);
    input [3:0] IN;
	output reg [6:0] OUT;
	 
	always @(*)
	begin
		case(IN[3:0])
			// Removed case for 4'b000
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

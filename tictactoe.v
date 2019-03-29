/* Wild Misere Tic Tac Toe

Wild Misere Red Tile Blue is a variation of the classic Tic Tac Toe game.
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
		SW,								// Switches
		KEY,								// Keys
		HEX0,								// Hex dispays
		HEX1,
		HEX2,
		HEX3,
		HEX4,							
		HEX5,
		HEX6,
		HEX7,
		LEDR,
		LEDG,
		PS2_KBDAT,						//	PS2 Keyboard Data
		PS2_KBCLK						//	PS2 Keyboard Clock
	);

	
	// Inputs
	input CLOCK_50;							//	50 MHz
	input 	[17:0]	SW;
	input 	[3:0] 	KEY;
	input PS2_KBDAT;
	input PS2_KBCLK;
	
	// Outputs
	// HEX outputs
	output 	[6:0] 	HEX0;
	output 	[6:0] 	HEX1;
	output 	[6:0]	HEX2;
	output 	[6:0] 	HEX3;
	output 	[6:0] 	HEX4;
	output 	[6:0]	HEX5;
	output 	[6:0]	HEX6;
	output 	[6:0]	HEX7;
	
	// LED outputs
	output	[17:0] 	LEDR;
	output	[8:0] 	LEDG;
	
	
	
	
	
	// Create wires for go, pos, move, and reset_all
	// Assign these to siwtches exept move and pos
	wire go;
	assign go = SW[16];
	wire [3:0] pos;
	// assign pos = SW[7:4];
	wire [1:0] move;
	// assign move = SW[1:0];
	wire reset_all;
	assign reset_all = SW[17];
	
	
	
	// Create wires for loads, write, draw, reset, and data
	wire writeEn;
	wire drawEn;
	wire [1:0] win_state;
	wire ld_p1;
	wire ld_p2;
	wire ld_pos;
	wire check;
	wire [1:0] s1, s2, s3, s4, s5, s6, s7, s8, s9, turn;

	// Create reg for resetting the game
	reg reset_game;



	// Create wires for keyboard module
	wire [7:0] ASCII_value;
	wire [7:0] kb_scan_code;
	wire kb_sc_ready;
	wire kb_letter_case;
	

	// For cycling through hex displays
	wire [2:0] drc_out;
	wire [27:0] rd_out;
	reg [27:0] rd_in;
	reg [1:0] hex0pos, hex1pos, hex2pos;
	reg hex_counter_enable;
	wire [3:0] position;

	// For scores for both players
	reg [7:0] p1_score;
	reg [7:0] p2_score;

	
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////

	// Instansiate Keyboard module
    keyboard kd(
        .clk(CLOCK_50),
        .reset(reset_game),
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
	 
	 // Instantiate ascii decoder for our game
	ascii_decoder decoder(
		.ASCII_VAL(ASCII_value),
		.clock(CLOCK_50),
		.move(move[1:0]),
		.pos(pos[3:0])
	);
	
	
	
	always @(posedge CLOCK_50)
	begin
		rd_in = 28'b101111101011110000100000000;
	end

	always @(posedge CLOCK_50)
	begin
		hex_counter_enable <= (rd_out[27:0] == 28'b0) ? 1 : 0;
	end

	always @(posedge CLOCK_50)
	begin
		if(drc_out == 3'b001)
		begin
			hex0pos = s1;
			hex1pos = s2;
			hex2pos = s3;
		end
		else if(drc_out == 3'b010)
		begin
			hex0pos = s4;
			hex1pos = s5;
			hex2pos = s6;
		end
		else if(drc_out == 3'b011)
		begin
			hex0pos = s7;
			hex1pos = s8;
			hex2pos = s9;
		end
	end

	// Add scores when theres a winner
	always @(posedge CLOCK_50)
	begin
		if(win_state == 2'b01)
			p1_score <= p1_score + 1;
		else if(win_state == 2'b10)
			p2_score <= p2_score + 1;
	end

	// Assign scores to leds
	assign LEDR[7:0] = p1_score[7:0];
	assign LEDG[7:0] = p2_score[7:0];

	// Reset game on win/tie
	always @(posedge CLOCK_50)
	begin
		if(win_state == 2'b01 || win_state == 2'b10 || win_state == 2'b11)
			reset_game = 0;
		else
			reset_game = 1;
	end

	// Reset scores/game on input
	always @(posedge CLOCK_50)
	begin
		if(reset_all == 1'b0)
		begin
			p1_score <= 0;
			p2_score <= 0;
			reset_all = 1;
			reset_game = 1;
		end
	end

	// RATE DIVIDER AND DISPLAY COUNTER
	rate_divider rd(
		.out(rd_out[27:0]),
		.in(rd_in[27:0]),
		.clock(CLOCK_50),
		.clear_b(reset_game),
	);

	display_row_counter drc(
		.out(drc_out[2:0]),
		.clock(CLOCK_50),
		.clear_b(reset_game),
		.enable(hex_counter_enable)
	);

    // Instansiate datapath
	datapath d0(
		.ld_p1(ld_p1),
		.ld_p2(ld_p2),
		.move(move),
	    .pos(pos),
	    .ld_pos(ld_pos),
	    .reset_game(reset_game),
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
	   	.reset_game(reset_game),
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
	    .win_state(win_state)
	);

	
	
	
	
	// Displaying to hex displays

	// HEX2-HEX0 displays each row of the tictactoe grid
	hex_display hex0(
		.IN(hex2pos),
		.OUT(HEX0[6:0])
	);
	
	hex_display hex1(
		.IN(hex1pos),
		.OUT(HEX1[6:0])
	);

	hex_display hex2(
		.IN(hex0pos),
		.OUT(HEX2[6:0])
	);
	
	// HEX3 displays the current row num
	hex_display hex3(
		.IN(drc_out[1:0]),
		.OUT(HEX3[6:0])
	);
	
	// HEX4 displays the player's selected move
	move_hexdisplay hex4(
		.IN(move[1:0]),
		.OUT(HEX4[6:0])
	);
	
	/*
	// Following displays the registers in cells 1-3
	// move in square 1
	hex_display hex0(
		.IN(s3[1:0]),
		.OUT(HEX0[6:0])
	);

	// move in square 2
	hex_display hex1(
		.IN(s2[1:0]),
		.OUT(HEX1[6:0])
	);
	
	// move in square 3
	hex_display hex2(
		.IN(s1[1:0]),
		.OUT(HEX2[6:0])
	);
	*/
	
	// HEX5 displays the player's selecte position (ie cell number to make move)
	hex_display hex5(
		.IN(pos[3:0]),
		.OUT(HEX5[6:0])
	);
	
	/*
	// Following displays the position stored in the register
	// position in register
	hex_display hex5(
		.IN(position[3:0]),
		.OUT(HEX5[6:0])
	);
	*/
	
	// HEX6 displays whose turn it is
	hex_display hex6(
		.IN(turn[1:0]),
		.OUT(HEX6[6:0])
	);
	
	// HEX7 displays the winner of the game (0-no winner, 1-P1 Wins, 2-P2 Wins, 3-Tie)
	hex_display hex7(
		.IN(win_state[1:0]),
		.OUT(HEX7[6:0])
	);
endmodule



// Rate divider module
module rate_divider(out, in, clock, clear_b);
	input wire [27:0] in;
	input clock;
	input clear_b;
	output reg [27:0] out;

	always @(posedge clock)
	begin
		if(clear_b == 1'b0 || out == 28'b0)
			out <= in;
		else
			out <= out - 1'b1;
	end
endmodule

module display_row_counter(out, clock, clear_b, enable);
	input clock;
	input clear_b;
	input enable;
	output reg [2:0] out;

	always @(posedge clock)
	begin
		if(clear_b == 1'b0 || out == 3'b100)
			out <= 1'b1;
		else if(enable == 1'b1)
			out <= out + 1'b1;
	end
endmodule

// Data path module
module datapath(ld_p1, ld_p2, move, pos, ld_pos, reset_game, clock, s1, s2, s3, s4, s5, s6, s7, s8, s9, position);
	input [1:0] move; // O (10) or X (01)
	input [3:0] pos; // Cell (1-9 in binary)
	input ld_p1, ld_p2, ld_pos, reset_game, clock;

	// Registers for each square of the grid
	output reg [1:0] s1, s2, s3, s4, s5, s6, s7, s8, s9;

	// Input registers for player 1, player 2, and square on grid
	reg [1:0] p1, p2;
	output reg [3:0] position;

	always @(posedge clock)
	begin
		// Reset all registers
		if (!reset_game)
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

// Control module
module control(go, reset_game, clock, check, ld_p1, ld_p2, ld_pos, turn);
	// Declare inputs, outputs, wires, and regs
	input go, reset_game, clock, check;
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
        if(!reset_game)
            curr_state <= S_LOAD_P1_POS;	// Move back to loading player 1's square if reset
        else
            curr_state <= next_state; 	// Otherwise, move to the next state
   end
endmodule

/* Checks the end conditions of the game.
Determines if there are three tiles in a row, if there is a tie, or if the game continues
*/
module check_end(s1, s2, s3, s4, s5, s6, s7, s8, s9, turn, check, win_state);
	input [1:0] s1, s2, s3, s4, s5, s6, s7, s8, s9, turn;
	output reg check;
	output reg [1:0] win_state;
	
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
				win_state <= 2'b10;
			// If it was player 2's turn, they lose
			else if (turn == 2'b10)
				win_state <= 2'b01;
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
				win_state <= 2'b00;
			end
			// Otherwise, we have a tie
			else
			begin
				// Set everything to high
				check <= 1'b1;
				win_state <= 2'b11;
			end
		end
	end
endmodule


// Ascii decoder module
module ascii_decoder(ASCII_VAL, clock, move, pos);
	input ASCII_VAL;
	input clock;
	output reg [1:0] move;
	output reg [3:0] pos;
	
	always@(clock)
	begin
		// Data in is 10 or 01, default 00
		case(ASCII_VAL)
			8'h78 : move <= 2'b01; // Move type is x, move is 01
			8'h6F : move <= 2'b10; // Move type is o, move is 10
			default : move <= 2'b00; // Default to 0
		endcase
	end
	
	always@(clock)
	begin
		// Pos is 4 bit 1-9, default 0
		case (ASCII_VAL)
			8'h31 : pos <= 4'b0001; // Cell number 1, pos is 1 in binary
			8'h32 : pos <= 4'b0010; // Cell number 2, pos is 2 in binary
			8'h33 : pos <= 4'b0011; // Cell number 3, pos is 3 in binary
			8'h34 : pos <= 4'b0100; // Cell number 4, pos is 4 in binary
			8'h35 : pos <= 4'b0101; // Cell number 5, pos is 5 in binary
			8'h36 : pos <= 4'b0110; // Cell number 6, pos is 6 in binary
			8'h37 : pos <= 4'b0111; // Cell number 7, pos is 7 in binary
			8'h38 : pos <= 4'b1000; // Cell number 8, pos is 8 in binary
			8'h39 : pos <= 4'b1001; // Cell number 9, pos is 9 in binary
			default : pos <= 4'b0000; // Default to 0
		endcase
	end


//	// Same as above but using if statements
//	always@(clock)
//	begin
//		if(ASCII_VAL == 8'h62)
//			begin
//			move <= 2'b01;
//			pos <= 4'b0000;
//			end
//		else if(ASCII_VAL == 8'h72)
//			begin
//			move <= 2'b10;
//			pos <= 4'b0000;
//			end
//		else if(ASCII_VAL == 8'h31)
//			begin
//			move <= 2'b00;
//			pos <= 4'b0001;
//			end
//		else if(ASCII_VAL == 8'h32)
//			begin
//			move <= 2'b00;
//			pos <= 4'b0010;
//			end
//		else if(ASCII_VAL == 8'h33)
//			begin
//			move <= 2'b00;
//			pos <= 4'b0011;
//			end
//		else if(ASCII_VAL == 8'h34)
//			begin
//			move <= 2'b00;
//			pos <= 4'b0100;
//			end
//		else if(ASCII_VAL == 8'h35)
//			begin
//			move <= 2'b00;
//			pos <= 4'b0101;
//			end
//		else if(ASCII_VAL == 8'h36)
//			begin
//			move <= 2'b00;
//			pos <= 4'b0110;
//			end
//		else if(ASCII_VAL == 8'h37)
//			begin
//			move <= 2'b00;
//			pos <= 4'b0111;
//			end
//		else if(ASCII_VAL == 8'h38)
//			begin
//			move <= 2'b00;
//			pos <= 4'b1000;
//			end
//		else if(ASCII_VAL == 8'h39)
//			begin
//			move <= 2'b00;
//			pos <= 4'b1001;
//			end
//	end
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
			default : OUT <= 7'b1111111;
		endcase
	end
endmodule


// Hex display module
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

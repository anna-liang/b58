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
		VGA_B   						//	VGA Blue[9:0]
	);

	input			CLOCK_50;				//	50 MHz
	input   [17:0]   SW;

	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	// Create wires for player 1, player 2, writeEn, and resetn
	wire [0:0] p1;
	wire [0:0] p2;
	wire [3:0] sq1;
	wire [3:0] sq2;
	wire writeEn;
	wire resetn;
	assign resetn = SW[17];
	wire ld_p1, ld_p2, ld_sq, ld_sq2, drawEn;
	
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
	
    // Instansiate datapath
	datapath d0(.ld_x(ld_x),
		    .ld_y(ld_y),
		    .ld_c(ld_c),
		    .drawEn(drawEn),
		    .position(SW[6:0]),
		    .col(SW[9:7]),
		    .resetn(resetn),
		    .clock(CLOCK_50),
		    .x_out(x),
		    .y_out(y),
		    .col_out(colour));

    // Instansiate FSM control
	control c0(.go(SW[16]),
		   .ld(SW[15]),
		   .resetn(resetn),
		   .clock(CLOCK_50),
		   .ld_x(ld_x),
		   .ld_y(ld_y),
		   .ld_c(ld_c),
		   .writeEn(writeEn),
		   .drawEn(drawEn));
    
endmodule

module datapath(ld_p1, ld_p2, data_in, square, drawEn, resetn, clock);
	input [0:0] data_in;
	input [3:0] square;
	input ld_p1, ld_p2, drawEn, resetn, clock;
	output [0:0] p1_out;
	output [0:0] p2_out;
	output reg [0:0] data_result;
	//output [2:0] col_out;

	// Input registers for player 1, player 2, and square on grid
	reg [0:0] p1, p2;
	reg [3:0] sq;
	// Registers for each square of the grid
	reg [0:0] s0, s1, s2, s3, s4, s5, s6, s7, s8
	
	
	always @(posedge clock)
	begin
		// If a player and square has been loaded
		if (ld_p1 && ld_sq || ld_p2 && ld_sq)
		begin
			// Grid registers
			always @(*)
			begin
				// Move value into appropriate register
				case (square)
					4'b0000: s0 <= data_in;
					4'b0001: s1 <= data_in;
					4'b0010: s2 <= data_in;
					4'b0011: s3 <= data_in;
					4'b0100: s4 <= data_in;
					4'b0101: s5 <= data_in;
					4'b0110: s6 <= data_in;
					4'b0111: s7 <= data_in;
					4'b1000: s8 <= data_in; 
					default: s0 = 4'b111;
				endcase
			end
		end
	end
			/*
		if (ld_p1)
			//p1 <= data_in;	// load player 1's move in p1 register
			
		if (ld_p2)
			p2 <= data_in;	// load player 2's move in p2 register
			
		if (ld_sq1)
			sq1 <= square;	// load grid position in sq1 register
		if (ld_sq2)
			sq2 <= square;	// load grid position in sq2 register
			*/
		

	/*
		if (!resetn)
		begin
			x = 8'b00000000;
			y = 7'b0000000;
			c = 3'b000;
		end
		else
		begin
			if (ld_x)
				x <= {1'b0, position};
			else if (ld_y)
				y <= position;
			else if (ld_c)
				c <= col;
		end
		*/
	/*
	always @(posedge clock)
	begin
		if (!resetn)
			counter <= 4'b0000;
		else if (drawEn)
		begin
			if (counter == 4'b1111)
				counter <= 4'b0000;
			else
				counter <= counter + 1'b1;
		end
	end

	assign x_out = x + counter[1:0];
	assign y_out = y + counter[3:2];
	assign col_out = c;
	*/

endmodule

module control(go, ld, resetn, clock, ld_p1, ld_p2, ld_sq, writeEn, drawEn);

	input go, ld, resetn, clock;
	output reg ld_p1, ld_p2, ld_sq, writeEn, drawEn;
	
	reg [5:0] curr_state, next_state;

	// Declare states
	localparam  S_LOAD_P1_SQ	 = 5'd0;
				S_LOAD_P1_SQ_WAIT = 5'd1;
				S_LOAD_P1        = 5'd2,
                S_LOAD_P1_WAIT   = 5'd3,
				S_DRAW_P1 	  	 = 5'd4,
                S_CHECK_P1       = 5'd5,
				S_LOAD_P2_SQ	 = 5'd6;
				S_LOAD_P2_SQ_WAIT = 5'd7;
                S_LOAD_P2        = 5'd8,
                S_LOAD_P2_WAIT   = 5'd9,
				S_DRAW_P2     	 = 5'd10,
                S_CHECK_P2       = 5'd11,
                S_END_P1         = 5'd12,
                S_END_P2	     = 5'd13,

	// State table logic
    always@(*)
    begin: state_table 
            case (current_state)
				S_LOAD_P1_SQ: next_state = go ? S_LOAD_P1_SQ_WAIT : S_LOAD_P1_SQ; // Loop in current state until player 1 enters a square
				S_LOAD_P1_SQ_WAIT: next_state = go ? S_LOAD_P1_SQ_WAIT : S_LOAD_P1; // Loop in current state until go signal goes low
                S_LOAD_P1: next_state = go ? S_LOAD_P1_WAIT : S_LOAD_P1; // Loop in current state until player 1 enters a value
                S_LOAD_P1_WAIT: next_state = go ? S_LOAD_P1_WAIT : S_CHECK_P1; // Loop in current state until go signal goes low
				S_DRAW_P2: next_state = S_CHECK_P1;	// Move into the checking state for player 1
				S_CHECK_P1: next_state = ; // /////
				
				S_LOAD_P2_SQ: next_state = go ? S_LOAD_P2_SQ_WAIT : S_LOAD_P2_SQ; // Loop in current state until player 2 enters a square
				S_LOAD_P2_SQ_WAIT: next_state = go ? S_LOAD_P2_SQ_WAIT : S_LOAD_P2; // Loop in current state until go signal goes low
				S_LOAD_P2: next_state = go ? S_LOAD_P2_WAIT : S_LOAD_P2; // Loop in current state until player 2 enters a value
                S_LOAD_P2_WAIT: next_state = go ? S_LOAD_P2_WAIT : S_CHECK_P2; // Loop in current state until go signal goes low
				S_DRAW_P2: next_state = S_CHECK_P2; // Move into the checking state for player 2
                S_CHECK_P2: next_state = ; // ///////////////
				
            default:     next_state = S_LOAD_P1_SQ;
        endcase
    end // state_table
	
	always @(*)
	begin
		// Set all loads to a default 0
		ld_p1 = 1'b0;
		ld_p2 = 1'b0;
		ld_sq = 1'b0;
		writeEn = 1'b0;
		drawEn = 1'b0;
		case (curr_state)
			S_LOAD_P1_SQ: begin	// Load player 1's square
				ld_sq = 1'b1;
				end
			S_LOAD_P1: begin	// Load player 1's move
				ld_p1 = 1'b1;
				end
			S_LOAD_P2_SQ: begin // Load player 2's square
				ld_sq = 1'b1;
				end
			S_LOAD_P2: begin	// Load player 2's move
				ld_p2 = 1'b1;
				end
			S_DRAW_P1: begin	// Draw player 1's move
				writeEn = 1'b1;
				drawEn = 1'b1;
				end
			S_DRAW_P2: begin	// Draw player 2's move
				writeEn = 1'b1;
				drawEn = 1'b1;
				end
			S_CHECK_P1: begin	// Check "losing" conditions for player 1

				ld_s0 = 1'b1;	// Take value in square 0
				ld_s1 = 1'b1;	// Take value in square 1
				alu_select_a = 4'b0000;	// Select square 0
				alu_select_b = 4'b0001;	// Select square 1
				alu_op = 1'b0; 	// Multiply
				ld_alu_out = 1'b1; ld_temp = 1'b1; // Load back in temp register
				ld_s2 = 1'b1; 	// Take value in square 2
				alu_select_a = 4'b0010; // Select square 0
				alu_select_b = 4'b1010; // Select temp register (square 0 and square 1)
				ld_r = 1'b1; 	// Store result in result register
				
				
				end
			S_CHECK_P2: begin	// Check "losing" conditions for player 2
				end
		endcase
	end
	
	// Move to the next state on the next positive clock edge
	always@(posedge clock)
	begin: state_FFs
        if(!resetn)
            curr_state <= S_LOAD_P1_SQ;	// Move back to loading player 1's square if reset
        else
            curr_state <= next_state; 	// Otherwise, move to the next state
    end
endmodule
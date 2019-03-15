module vga
    (
        CLOCK_50,                       //  On Board 50 MHz
        KEY,
        VGA_CLK,                        //  VGA Clock
        VGA_HS,                         //  VGA H_SYNC
        VGA_VS,                         //  VGA V_SYNC
        VGA_BLANK_N,                        //  VGA BLANK
        VGA_SYNC_N,                     //  VGA SYNC
        VGA_R,                          //  VGA Red[9:0]
        VGA_G,                          //  VGA Green[9:0]
        VGA_B                           //  VGA Blue[9:0]
    );

    input           CLOCK_50;               //  50 MHz
    input   [3:0]   KEY;

    // Declare your inputs and outputs here
    // Do not change the following outputs
    output          VGA_CLK;                //  VGA Clock
    output          VGA_HS;                 //  VGA H_SYNC
    output          VGA_VS;                 //  VGA V_SYNC
    output          VGA_BLANK_N;                //  VGA BLANK
    output          VGA_SYNC_N;             //  VGA SYNC
    output  [9:0]   VGA_R;                  //  VGA Red[9:0]
    output  [9:0]   VGA_G;                  //  VGA Green[9:0]
    output  [9:0]   VGA_B;                  //  VGA Blue[9:0]
    
    wire resetn;
    assign resetn = KEY[0];
    wire [2:0] colour;
    wire [7:0] x;
    wire [6:0] y;
    wire wren;

    reg [6:0] x_register;
    always @(posedge KEY[3])
    begin
        
    end

    assign wren = KEY[1];

    wire ld_x, do_draw;
    wire [3:0] draw;

    control c0(
            .clk(CLOCK_50),
            .read_x(KEY[3]),
            .resetn(resetn),
            .plot(KEY[1]),
            .old_draw(draw),
            .ld_x(ld_x),
            .do_draw(do_draw),
            .draw(draw)
    );
    
    datapath d0(
            .clk(CLOCK_50),
            .resetn(resetn),
            .colour_in(SW[9:7]),
            .data_in(SW[6:0]),
            .ld_x(ld_x),
            .do_draw(do_draw),
            .draw(draw),
            .old_x(x),
            .old_y(y),
            .x(x),
            .y(y),
            .colour(colour)
    );
	 
	     vga_adapter VGA(
            .resetn(resetn),
            .clock(CLOCK_50),
            .colour(colour),
            .x(x),
            .y(y),
            .plot(wren),
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
endmodule

module control(clk, read_x, resetn, plot, old_draw, ld_x, do_draw, draw);
    input clk, read_x, resetn, plot;
    input [3:0] old_draw;

    output reg ld_x, do_draw;
    output reg [3:0] draw;

    reg [1:0] current_state, next_state;

    localparam  RESET         = 2'd0,
                LD_X        = 2'd1,
                LD_X_WAIT   = 2'd2,
                DRAW          = 2'd3;

    always @(*)
    begin
        case (current_state)
            RESET: next_state = clk & read_x ? LD_X : RESET;
            LD_X: next_state = ~clk ? LD_X_WAIT : LD_X;
            LD_X_WAIT: next_state = clk & plot ? DRAW : LD_X_WAIT;
            DRAW: next_state =  (old_draw == 4'b1111) ? RESET : DRAW;
            default: next_state = RESET;
        endcase
    end

    always @(*)
    begin
        ld_x = 1'b0;
        do_draw = 1'b0;
        draw = 4'b0000;

        case (current_state)
            LD_X:
                begin
                    ld_x = 1'b1;
                end
            DRAW:
                begin
                    do_draw = 1'b1;
                    draw = old_draw + 4'b0001;
                end
        endcase
    end

    always @(posedge clk)
    begin
        if (!resetn)
            current_state <= RESET;
        else
            current_state <= next_state;
    end
endmodule

module datapath(clk, resetn, colour_in, data_in, ld_x, do_draw, draw, old_x, old_y, x, y, colour);
    input clk, resetn, ld_x, do_draw;
    input [2:0] colour_in;
    input [6:0] data_in;
    input [3:0] draw;
    input [7:0] old_x;
    input [6:0] old_y;

    output reg [7:0] x;
    output reg [6:0] y;
    output [2:0] colour;

    always @(posedge clk)
    begin
        x <= old_x;
        y <= old_y;

        if (!resetn)
        begin
            x <= 8'b0;
            y <= 7'b0;
        end
        else
        begin
            if (ld_x)
                x <= {1'b0, data_in};
            if (do_draw)
                if (draw == 4'b0000)
                    y <= data_in;
                x <= old_x + draw[1:0];
                y <= old_y + draw[3:2];
        end
    end

    assign colour = colour_in;
endmodule


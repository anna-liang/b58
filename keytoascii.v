module keytoascii
    (
        input wire letter_case,
        input wire [7:0] scan_code,
        output reg [7:0] ascii_code
    );
    
always@(*)
    begin
    
    if(letter_case == 1'b0)   // Lowercase
        begin
        case(scan_code)
            8'h45: ascii_code = 8'h30;   // 0
            8'h16: ascii_code = 8'h31;   // 1
            8'h1e: ascii_code = 8'h32;   // 2
            8'h26: ascii_code = 8'h33;   // 3
            8'h25: ascii_code = 8'h34;   // 4
            8'h2e: ascii_code = 8'h35;   // 5
            8'h36: ascii_code = 8'h36;   // 6
            8'h3d: ascii_code = 8'h37;   // 7
            8'h3e: ascii_code = 8'h38;   // 8
            8'h46: ascii_code = 8'h39;   // 9
            8'h44: ascii_code = 8'h6F;   // o
            8'h22: ascii_code = 8'h78;   // x
            default: ascii_code = 8'h00; // NUL
        endcase
        end
    end
endmodule

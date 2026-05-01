module tt_um_funproj (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,  
    input  wire [7:0] uio_in, 
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena, 
    input  wire       clk, 
    input  wire       rst_n
);
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    tiny_cpu my_cpu (
        .clk(clk),
        .reset(!rst_n),
        .keyboard_in(ui_in), 
        .screen_out(uo_out)
    );

endmodule

module tiny_cpu (
    input clk,
    input reset,
    input [7:0] keyboard_in,
    output reg [7:0] screen_out
);

    // Minimal state: 3-bit PC, 2 registers, tiny RAM
    reg [2:0] pc;
    reg [7:0] reg_a, reg_b;
    reg [127:0] ram [127:0];  // Only 128 bytes of RAM
    
    wire [7:0] instruction;
    wire [7:0] alu_result;
    
    // Decode
    wire [1:0] opcode = instruction[7:6];
    wire [2:0] addr = instruction[2:0];
    wire reg_sel = instruction[3];  // 0=reg_a, 1=reg_b
    wire imm_mode = instruction[4];
    
    // Micro ROM - 8 instructions max
    reg [7:0] rom [7:0];
    initial begin
        rom[0] = 8'b10010000;  // LOAD reg_a from keyboard (imm=1, reg_sel=0)
        rom[1] = 8'b00000000;  // ADD reg_a + ram[0] -> reg_a
        rom[2] = 8'b11000000;  // STORE reg_a to screen
        rom[3] = 8'b00000001;  // ADD reg_a + ram[1] -> reg_a
        rom[4] = 8'b11000000;  // STORE reg_a to screen
        rom[5] = 8'b00000000;  // LOOP
        rom[6] = 8'b00000000;
        rom[7] = 8'b00000000;
    end
    
    assign instruction = rom[pc];
    
    // Simplified ALU
    assign alu_result = reg_a + ram[addr];
    
    // RAM initialization
    integer i;
    initial begin
        for (i = 0; i < 8; i = i + 1) ram[i] = 8'h00;
    end
    
    always @(posedge clk) begin
        if (reset) begin
            pc <= 3'b000;
            reg_a <= 8'h00;
            reg_b <= 8'h00;
            screen_out <= 8'h20;  // Space character
        end else begin
            case (opcode)
                2'b00: begin  // ADD/LOAD
                    if (imm_mode) begin
                        if (reg_sel) reg_b <= keyboard_in;
                        else reg_a <= keyboard_in;
                    end else begin
                        if (reg_sel) reg_b <= alu_result;
                        else reg_a <= alu_result;
                    end
                    pc <= pc + 1;
                end
                
                2'b01: begin  // STORE to RAM
                    ram[addr] <= reg_sel ? reg_b : reg_a;
                    pc <= pc + 1;
                end
                
                2'b10: begin  // LOAD from RAM
                    if (imm_mode) begin
                        if (reg_sel) reg_b <= keyboard_in;
                        else reg_a <= keyboard_in;
                    end else begin
                        if (reg_sel) reg_b <= ram[addr];
                        else reg_a <= ram[addr];
                    end
                    pc <= pc + 1;
                end
                
                2'b11: begin  // STORE to screen / JUMP
                    if (imm_mode) begin
                        pc <= addr;  // JUMP
                    end else begin
                        screen_out <= reg_sel ? reg_b : reg_a;
                        pc <= pc + 1;
                    end
                end
            endcase
        end
    end

endmodule

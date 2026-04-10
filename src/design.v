module simple_cpu (
    input clk,
    input reset,
    output [7:0] alu_out_monitor,
    input [7:0] keyboard_in,
    output [7:0] screen_out
);

    wire [7:0] instruction;
    wire [1:0] sel_dest, sel_a, sel_b;
    wire [7:0] data_a, data_b, alu_result, reg_wr_data;
    wire alu_op, reg_write, load_en, jump_en;
    wire load_imm, ram_write, sel_ram_to_reg; 
    wire is_zero;
    wire [7:0] ram_data_out;
    wire [7:0] data_to_cpu;
    
    reg [7:0] pc_reg;
    reg [7:0] screen_buffer;

    wire [7:0] mem_address = data_b;

    assign data_to_cpu = (mem_address == 8'hFE) ? keyboard_in : ram_data_out;
    assign screen_out = screen_buffer;

    wire actual_jump = (instruction[5] == 0) ? jump_en : (jump_en && is_zero);

    always @(posedge clk) begin 
      if (reset) 
          pc_reg <= 8'h00;
      else if (actual_jump) 
          pc_reg <= instruction; 
      else 
          pc_reg <= pc_reg + 1;
    end 
    
    always @(posedge clk) begin
      if (ram_write && mem_address == 8'hFF)
          screen_buffer <= data_a; 
    end

    instruction_rom ROM_UNIT (
        .addr(pc_reg), 
        .data(instruction)
    );

    control_unit DECODER (
        .instr(instruction), 
        .alu_op(alu_op), 
        .reg_write(reg_write),
        .load_en(load_en),
        .load_imm(load_imm),
        .ram_write(ram_write),
        .sel_ram_to_reg(sel_ram_to_reg),
        .jump_en(jump_en), 
        .sel_dest(sel_dest), .sel_a(sel_a), .sel_b(sel_b)
    );  

    register_file REGS (
        .clk(clk), .reset(reset), .wr_en(reg_write),
        .wr_addr(sel_dest), .wr_data(reg_wr_data),
        .rd_addr_a(sel_a), .rd_data_a(data_a),
        .rd_addr_b(sel_b), .rd_data_b(data_b)
    );

    data_ram RAM_UNIT (
      .clk(clk),
      .wr_en(ram_write && mem_address < 8'hFE), 
      .addr(mem_address),
      .din(data_a),
      .dout(ram_data_out)
    );

    assign reg_wr_data = (load_imm) ? instruction : 
                         (sel_ram_to_reg) ? data_to_cpu : alu_result;

    assign alu_result = (alu_op == 0) ? (data_a + data_b) : (data_a - data_b);
    assign is_zero = (alu_result == 8'b0);
    assign alu_out_monitor = alu_result;

endmodule

module instruction_rom (
    input [7:0] addr,
    output [7:0] data
);
    reg [7:0] mem [255:0];
  	integer i;
    
    initial begin
        
        for (i = 0; i < 256; i = i + 1) mem[i] = 8'h00;
        $readmemb("program.txt", mem);
    end
    
    assign data = mem[addr];
endmodule

module control_unit (
    input [7:0] instr,
    output reg alu_op, reg_write, load_en, jump_en,
    output reg load_imm, ram_write, sel_ram_to_reg,
    output [1:0] sel_dest, sel_a, sel_b
);
    assign sel_dest = instr[5:4];
    assign sel_a    = instr[3:2];
    assign sel_b    = instr[1:0];

    always @(*) begin
        {alu_op, reg_write, load_en, jump_en, load_imm, ram_write, sel_ram_to_reg} = 7'b0000000;
        case (instr[7:6])
            2'b00: begin 
                if (instr[5:4] == 2'b11) ram_write = 1; 
                else begin alu_op = 0; reg_write = 1; end
            end
            2'b01: begin alu_op = 1; reg_write = 1; end 
            2'b10: begin 
                reg_write = 1;
                if (instr[5] == 0) load_imm = 1;
                else sel_ram_to_reg = 1;
            end
            2'b11: jump_en = 1; 
        endcase
    end
endmodule

module register_file (
    input clk, reset, wr_en,
    input [1:0] wr_addr, rd_addr_a, rd_addr_b,
    input [7:0] wr_data,
    output [7:0] rd_data_a, rd_data_b
);
    reg [7:0] regs [3:0];
    assign rd_data_a = regs[rd_addr_a];
    assign rd_data_b = regs[rd_addr_b];
    integer i;
    always @(posedge clk) begin
        if (reset) for (i=0; i<4; i=i+1) regs[i] <= 0;
        else if (wr_en) regs[wr_addr] <= wr_data;
    end
endmodule 

module data_ram (
    input clk, wr_en,
    input [7:0] addr,
    input [7:0] din, 
    output [7:0] dout
);
    reg [7:0] ram [255:0];
    assign dout = ram[addr];
    always @(posedge clk) 
        if (wr_en) ram[addr] <= din;
endmodule
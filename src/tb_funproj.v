`timescale 1ns/1ps

module tb_simple_cpu();


    reg clk;
    reg reset;
    reg [7:0] keyboard_in;


    wire [7:0] alu_out_monitor;
    wire [7:0] screen_out;


    simple_cpu uut (
        .clk(clk),
        .reset(reset),
        .alu_out_monitor(alu_out_monitor),
        .keyboard_in(keyboard_in),
        .screen_out(screen_out)
    );


    always #5 clk = ~clk;

    initial begin

        clk = 0;
        reset = 1;
        keyboard_in = 8'h00;


        #20 reset = 0;
        $display("--- CPU Reset Released ---");


        #100 keyboard_in = 8'd65; 
        

        #500;
        
        $display("Simulation finished.");
        $finish;
    end


    initial begin
        $monitor("Time=%0t | PC=%h | ALU_Out=%d | Screen=%c (Hex:%h)", 
                 $time, uut.pc_reg, alu_out_monitor, screen_out, screen_out);
    end

endmodule
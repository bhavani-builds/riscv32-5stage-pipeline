`timescale 1ns/1ps

module tb_riscv_pipeline;

    reg clk;
    reg reset;

    // Instantiate processor
    riscv_pipeline uut (
        .clk(clk),
        .reset(reset)
    );

    // Clock: 10 ns period
    always #5 clk = ~clk;

    initial begin

        // Waveform dump
        $dumpfile("riscv_pipeline.vcd");
        $dumpvars(0, tb_riscv_pipeline);

        // Initial values
        clk   = 1'b0;
        reset = 1'b1;

        // Hold reset
        #20;

        reset = 1'b0;

        // Run processor
        #300;

        $display("====================================");
        $display(" RISC-V PIPELINE SIMULATION COMPLETE");
        $display("====================================");

        $finish;
    end

endmodule

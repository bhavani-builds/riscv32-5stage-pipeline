module instruction_memory (
    input  wire [31:0] address,
    output wire [31:0] instruction
);

    reg [31:0] memory [0:255];

    assign instruction = memory[address[9:2]];

    initial begin
        $readmemh("../programs/test_program.hex", memory);
    end

endmodule

module instruction_memory (
    input  wire [31:0] address,
    output wire [31:0] instruction
);

    reg [31:0] memory [0:255];

    assign instruction = memory[address[9:2]];

    initial begin
        memory[0] = 32'h00000013; // NOP
        memory[1] = 32'h00000013; // NOP
        memory[2] = 32'h00000013; // NOP
        memory[3] = 32'h00000013; // NOP
    end

endmodule

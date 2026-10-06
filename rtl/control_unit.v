module control_unit (
    input  wire [6:0] opcode,

    output reg        reg_write,
    output reg        mem_read,
    output reg        mem_write,
    output reg        mem_to_reg,
    output reg        alu_src,
    output reg        branch,
    output reg        jump,
    output reg [3:0]  alu_control
);

    always @(*) begin

        // Default control values
        reg_write  = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        mem_to_reg = 1'b0;
        alu_src    = 1'b0;
        branch     = 1'b0;
        jump       = 1'b0;
        alu_control = 4'b0000;

        case (opcode)

            // R-type instructions
            7'b0110011: begin
                reg_write   = 1'b1;
                alu_src     = 1'b0;
                alu_control = 4'b0000;
            end

            // I-type ALU instructions
            7'b0010011: begin
                reg_write   = 1'b1;
                alu_src     = 1'b1;
                alu_control = 4'b0000;
            end

            // Load - LW
            7'b0000011: begin
                reg_write   = 1'b1;
                mem_read    = 1'b1;
                mem_to_reg  = 1'b1;
                alu_src     = 1'b1;
                alu_control = 4'b0000;
            end

            // Store - SW
            7'b0100011: begin
                mem_write   = 1'b1;
                alu_src     = 1'b1;
                alu_control = 4'b0000;
            end

            // Branch - BEQ
            7'b1100011: begin
                branch      = 1'b1;
                alu_src     = 1'b0;
                alu_control = 4'b0001;
            end

            // Jump - JAL
            7'b1101111: begin
                reg_write   = 1'b1;
                jump        = 1'b1;
                alu_control = 4'b0000;
            end

            default: begin
                reg_write   = 1'b0;
            end

        endcase
    end

endmodule

module hazard_detection (
    input  wire [4:0] rs1_id,
    input  wire [4:0] rs2_id,

    input  wire [4:0] rd_ex,
    input  wire        mem_read_ex,

    output reg        stall
);

    always @(*) begin

        stall = 1'b0;

        // Load-use hazard
        if (mem_read_ex &&
            (rd_ex != 5'd0) &&
            ((rd_ex == rs1_id) ||
             (rd_ex == rs2_id))) begin

            stall = 1'b1;

        end

    end

endmodule

module riscv_pipeline (
    input wire        clk,
    input wire        reset
);

    // =========================================================
    // IF STAGE
    // =========================================================

    wire [31:0] pc_current;
    wire [31:0] pc_next;
    wire [31:0] instruction;

    assign pc_next = pc_current + 32'd4;

    pc pc_unit (
        .clk(clk),
        .reset(reset),
        .next_pc(pc_next),
        .pc(pc_current)
    );

    instruction_memory instruction_mem (
        .address(pc_current),
        .instruction(instruction)
    );


    // =========================================================
    // IF / ID PIPELINE REGISTER
    // =========================================================

    wire [31:0] if_id_pc;
    wire [31:0] if_id_instruction;

    if_id if_id_reg (
        .clk(clk),
        .reset(reset),
        .stall(1'b0),
        .flush(1'b0),

        .pc_in(pc_current),
        .instruction_in(instruction),

        .pc_out(if_id_pc),
        .instruction_out(if_id_instruction)
    );


    // =========================================================
    // ID STAGE
    // =========================================================

    wire [6:0] opcode;
    wire [4:0] rs1;
    wire [4:0] rs2;
    wire [4:0] rd;

    assign opcode = if_id_instruction[6:0];
    assign rd     = if_id_instruction[11:7];
    assign rs1    = if_id_instruction[19:15];
    assign rs2    = if_id_instruction[24:20];


    // Control signals

    wire       reg_write;
    wire       mem_read;
    wire       mem_write;
    wire       mem_to_reg;
    wire       alu_src;
    wire       branch;
    wire       jump;

    wire [3:0] alu_control;

    control_unit control (
        .opcode(opcode),

        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_to_reg(mem_to_reg),
        .alu_src(alu_src),
        .branch(branch),
        .jump(jump),
        .alu_control(alu_control)
    );


    // Register file

    wire [31:0] read_data1;
    wire [31:0] read_data2;

    register_file registers (
        .clk(clk),
        .reset(reset),

        .read_reg1(rs1),
        .read_reg2(rs2),

        .write_reg(mem_wb_rd),
        .write_data(write_back_data),
        .reg_write(mem_wb_reg_write),

        .read_data1(read_data1),
        .read_data2(read_data2)
    );


    // Immediate generator

    wire [31:0] immediate;

    immediate_generator imm_gen (
        .instruction(if_id_instruction),
        .immediate(immediate)
    );


    // =========================================================
    // HAZARD DETECTION
    // =========================================================

    wire stall;

    hazard_detection hazard_unit (
        .rs1_id(rs1),
        .rs2_id(rs2),

        .rd_ex(id_ex_rd),
        .mem_read_ex(id_ex_mem_read),

        .stall(stall)
    );


    // =========================================================
    // ID / EX PIPELINE REGISTER
    // =========================================================

    wire        id_ex_reg_write;
    wire        id_ex_mem_read;
    wire        id_ex_mem_write;
    wire        id_ex_mem_to_reg;
    wire        id_ex_alu_src;
    wire        id_ex_branch;
    wire        id_ex_jump;

    wire [3:0]  id_ex_alu_control;

    wire [31:0] id_ex_pc;
    wire [31:0] id_ex_read_data1;
    wire [31:0] id_ex_read_data2;
    wire [31:0] id_ex_immediate;

    wire [4:0] id_ex_rs1;
    wire [4:0] id_ex_rs2;
    wire [4:0] id_ex_rd;

    id_ex id_ex_reg (
        .clk(clk),
        .reset(reset),
        .flush(1'b0),

        .reg_write_in(reg_write),
        .mem_read_in(mem_read),
        .mem_write_in(mem_write),
        .mem_to_reg_in(mem_to_reg),
        .alu_src_in(alu_src),
        .branch_in(branch),
        .jump_in(jump),
        .alu_control_in(alu_control),

        .pc_in(if_id_pc),
        .read_data1_in(read_data1),
        .read_data2_in(read_data2),
        .immediate_in(immediate),

        .rs1_in(rs1),
        .rs2_in(rs2),
        .rd_in(rd),

        .reg_write_out(id_ex_reg_write),
        .mem_read_out(id_ex_mem_read),
        .mem_write_out(id_ex_mem_write),
        .mem_to_reg_out(id_ex_mem_to_reg),
        .alu_src_out(id_ex_alu_src),
        .branch_out(id_ex_branch),
        .jump_out(id_ex_jump),
        .alu_control_out(id_ex_alu_control),

        .pc_out(id_ex_pc),
        .read_data1_out(id_ex_read_data1),
        .read_data2_out(id_ex_read_data2),
        .immediate_out(id_ex_immediate),

        .rs1_out(id_ex_rs1),
        .rs2_out(id_ex_rs2),
        .rd_out(id_ex_rd)
    );


    // =========================================================
    // EX STAGE
    // =========================================================

    wire [1:0] forward_a;
    wire [1:0] forward_b;

    forwarding_unit forwarding (
        .rs1_ex(id_ex_rs1),
        .rs2_ex(id_ex_rs2),

        .rd_mem(ex_mem_rd),
        .reg_write_mem(ex_mem_reg_write),

        .rd_wb(mem_wb_rd),
        .reg_write_wb(mem_wb_reg_write),

        .forward_a(forward_a),
        .forward_b(forward_b)
    );


    reg [31:0] alu_input_a;
    reg [31:0] alu_input_b_forwarded;

    always @(*) begin

        case (forward_a)
            2'b00: alu_input_a = id_ex_read_data1;
            2'b01: alu_input_a = write_back_data;
            2'b10: alu_input_a = ex_mem_alu_result;
            default: alu_input_a = id_ex_read_data1;
        endcase

        case (forward_b)
            2'b00: alu_input_b_forwarded = id_ex_read_data2;
            2'b01: alu_input_b_forwarded = write_back_data;
            2'b10: alu_input_b_forwarded = ex_mem_alu_result;
            default: alu_input_b_forwarded = id_ex_read_data2;
        endcase

    end


    wire [31:0] alu_input_b;
    wire [31:0] alu_result;
    wire        alu_zero;

    assign alu_input_b =
        id_ex_alu_src ?
        id_ex_immediate :
        alu_input_b_forwarded;

    alu alu_unit (
        .a(alu_input_a),
        .b(alu_input_b),
        .alu_control(id_ex_alu_control),

        .result(alu_result),
        .zero(alu_zero)
    );


    // =========================================================
    // EX / MEM PIPELINE REGISTER
    // =========================================================

    wire        ex_mem_reg_write;
    wire        ex_mem_mem_read;
    wire        ex_mem_mem_write;
    wire        ex_mem_mem_to_reg;

    wire [31:0] ex_mem_alu_result;
    wire [31:0] ex_mem_write_data;

    wire [4:0] ex_mem_rd;

    ex_mem ex_mem_reg (
        .clk(clk),
        .reset(reset),

        .reg_write_in(id_ex_reg_write),
        .mem_read_in(id_ex_mem_read),
        .mem_write_in(id_ex_mem_write),
        .mem_to_reg_in(id_ex_mem_to_reg),

        .alu_result_in(alu_result),
        .write_data_in(alu_input_b_forwarded),

        .rd_in(id_ex_rd),

        .reg_write_out(ex_mem_reg_write),
        .mem_read_out(ex_mem_mem_read),
        .mem_write_out(ex_mem_mem_write),
        .mem_to_reg_out(ex_mem_mem_to_reg),

        .alu_result_out(ex_mem_alu_result),
        .write_data_out(ex_mem_write_data),

        .rd_out(ex_mem_rd)
    );


    // =========================================================
    // MEM STAGE
    // =========================================================

    wire [31:0] memory_read_data;

    data_memory data_mem (
        .clk(clk),
        .mem_read(ex_mem_mem_read),
        .mem_write(ex_mem_mem_write),

        .address(ex_mem_alu_result),
        .write_data(ex_mem_write_data),

        .read_data(memory_read_data)
    );


    // =========================================================
    // MEM / WB PIPELINE REGISTER
    // =========================================================

    wire        mem_wb_reg_write;
    wire        mem_wb_mem_to_reg;

    wire [31:0] mem_wb_alu_result;
    wire [31:0] mem_wb_memory_data;

    wire [4:0] mem_wb_rd;

    mem_wb mem_wb_reg (
        .clk(clk),
        .reset(reset),

        .reg_write_in(ex_mem_reg_write),
        .mem_to_reg_in(ex_mem_mem_to_reg),

        .alu_result_in(ex_mem_alu_result),
        .memory_data_in(memory_read_data),

        .rd_in(ex_mem_rd),

        .reg_write_out(mem_wb_reg_write),
        .mem_to_reg_out(mem_wb_mem_to_reg),

        .alu_result_out(mem_wb_alu_result),
        .memory_data_out(mem_wb_memory_data),

        .rd_out(mem_wb_rd)
    );


    // =========================================================
    // WRITE BACK STAGE
    // =========================================================

    wire [31:0] write_back_data;

    assign write_back_data =
        mem_wb_mem_to_reg ?
        mem_wb_memory_data :
        mem_wb_alu_result;

endmodule

module chi_req_decoder #(
    parameter FLIT_WIDTH  = 213,
    parameter ADDR_WIDTH  = 52,
    parameter TXN_ID_W    = 12,
    parameter NODE_ID_W   = 7
)(
    input  logic                    clk,
    input  logic                    rst_n,

    // CHI REQ Channel - Inputs from HN
    input  logic                    rxreqflitv,          // flit valid
    input  logic                    rxreqflitpend,       // flit pending
    input  logic [FLIT_WIDTH-1:0]   rxreqflit,           // full request flit

    // Credit return to HN
    output logic                    rxreqlcrdv,

    // Decoded outputs
    output logic                    req_valid,
    output logic [3:0]              req_qos,
    output logic [NODE_ID_W-1:0]    req_tgt_id,
    output logic [NODE_ID_W-1:0]    req_src_id,
    output logic [TXN_ID_W-1:0]     req_txn_id,
    output logic [6:0]              req_opcode,
    output logic [2:0]              req_size,
    output logic [ADDR_WIDTH-1:0]   req_addr,
    output logic                    req_allow_retry,
    output logic [1:0]              req_order,
    output logic [3:0]              req_mem_attr,
    output logic                    req_exp_comp_ack,

    // Transaction type flags
    output logic                    req_is_read,
    output logic                    req_is_write
);

localparam INIT_CREDIT = 4;
localparam READNOSNP      = 7'b0000100;
localparam WRITENOSNPPTL  = 7'b0011100;
localparam WRITENOSNPFULL = 7'b0011101;

// Internal signals
logic [2:0] credit_count;
logic init_credit_over;

// -----------------------------
// Field extraction
// -----------------------------
always_comb begin
    // Default values
    req_qos          = '0;
    req_tgt_id       = '0;
    req_src_id       = '0;
    req_txn_id       = '0;
    req_opcode       = '0;
    req_size         = '0;
    req_addr         = '0;
    req_allow_retry  = '0;
    req_order        = '0;
    req_mem_attr     = '0;
    req_exp_comp_ack = '0;

    if (rxreqflitv) begin
        req_qos          = rxreqflit[3:0];
        req_tgt_id       = rxreqflit[10:4];
        req_src_id       = rxreqflit[17:11];
        req_txn_id       = rxreqflit[29:18];
        req_opcode       = rxreqflit[56:50];
        req_size         = rxreqflit[60:58];
        req_addr         = rxreqflit[115:64];
        req_allow_retry  = rxreqflit[120];
        req_order        = rxreqflit[122:121];
        req_mem_attr     = rxreqflit[130:127];
        req_exp_comp_ack = rxreqflit[141];
    end
end

// -----------------------------
// Opcode decoding
// -----------------------------
assign req_is_read  = rxreqflitv && (req_opcode == READNOSNP);
assign req_is_write = rxreqflitv &&
                      ((req_opcode == WRITENOSNPFULL) ||
                       (req_opcode == WRITENOSNPPTL));

assign req_valid = req_is_read || req_is_write;

// -----------------------------
// Credit return logic
// -----------------------------
typedef enum logic [1:0] {
    INIT   = 2'b00,
    NORMAL = 2'b01
} state_t;

state_t credit_state;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        credit_state     <= INIT;
        credit_count     <= INIT_CREDIT;
        rxreqlcrdv       <= 1'b0;
        init_credit_over <= 1'b0;
    end
    else begin
        case (credit_state)

            INIT: begin
                if (credit_count > 0) begin
                    rxreqlcrdv <= 1'b1;
                    credit_count <= credit_count - 1;
                end
                else begin
                    rxreqlcrdv       <= 1'b0;
                    init_credit_over <= 1'b1;
                    credit_state     <= NORMAL;
                end
            end

            NORMAL: begin
                // Return one credit after receiving a flit
                if (rxreqflitv) begin
                    rxreqlcrdv <= 1'b1;
                end
                else begin
                    rxreqlcrdv <= 1'b0;
                end
            end

            default: begin
                credit_state <= INIT;
                rxreqlcrdv   <= 1'b0;
            end

        endcase
    end
end

endmodule
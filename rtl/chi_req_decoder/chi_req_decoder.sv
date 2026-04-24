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
    input  logic                    rxreqflitpend,       // flit pending (1 cycle warning)
    input  logic [FLIT_WIDTH-1:0]   rxreqflit,           // full request flit

    // Credit return to HN
    output logic                    rxreqlcrdv,          // link credit valid

    // Decoded outputs to Flow Controller
    output logic                    req_valid,           // decoded request is valid
    output logic [3:0]              req_qos,             // quality of service
    output logic [NODE_ID_W-1:0]    req_tgt_id,          // target node ID
    output logic [NODE_ID_W-1:0]    req_src_id,          // source node ID
    output logic [TXN_ID_W-1:0]     req_txn_id,          // transaction ID
    output logic [6:0]              req_opcode,          // transaction opcode
    output logic [2:0]              req_size,            // transfer size
    output logic [ADDR_WIDTH-1:0]   req_addr,            // target address
    output logic                    req_allow_retry,     // allow retry flag
    output logic [1:0]              req_order,           // ordering requirement
    output logic [3:0]              req_mem_attr,        // memory attributes
    output logic                    req_exp_comp_ack,    // expect comp ack

    // Transaction type flags
    output logic                    req_is_read,         // ReadNoSnp detected
    output logic                    req_is_write         // WriteNoSnp detected

);

localparam INIT_CREDIT = 4;
localparam READNOSNP      = 7'b0000100;
localparam WRITENOSNPPTL  = 7'b0011100;
localparam WRITENOSNPFULL = 7'b0011101;

// Internal signals
logic[2:0] credit_counter;
logic credit_over_flag;

// Field extraction - only when flit is valid
assign req_is_read = (req_opcode == READNOSNP);
assign req_is_write = (req_opcode == WRITENOSNPFULL) | (req_opcode == WRITENOSNPPTL);

// Opcode decoding
// TODO: add opcode decode

// Credit return logic
// TODO: add credit logic

endmodule
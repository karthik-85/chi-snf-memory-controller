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
logic[2:0] credit_count;
logic init_credit_over;

// Field extraction - only when flit is valid
always_comb begin
    if(rxreqflitv)begin //HN sends this signal and once we recieve the actual flit, we assign our o/ps in SN-F

    assign req_qos = rxreqflit[3:0];
    assign req_tgt_id = rxreqflit[10:4];
    assign req_src_id = rxreqflit[17:11];
    assign req_txn_id = rxreqflit[29:18];
    assign req_opcode = rxreqflit[56:50];
    assign req_size = rxreqflit[60:58];
    assign req_addr = rxreqflit[115:64];
    assign req_allow_retry = rxreqflit[120];
    assign req_order = rxreqflit[122:121];
    assign req_mem_attr = rxreqflit[130:127];
    assign req_exp_comp_ack = rxreqflit[141];
        
    end

    else begin

    assign req_qos = 0;
    assign req_tgt_id = 0;
    assign req_src_id = 0;
    assign req_txn_id = 0;
    assign req_opcode = 0;
    assign req_size = 0;
    assign req_addr = 0;
    assign req_allow_retry = 0;
    assign req_order = 0;
    assign req_mem_attr = 0;
    assign req_exp_comp_ack = 0;
        
    end
end

// Opcode decoding
assign req_is_read =  rxreqflitv && (req_opcode == READNOSNP);
assign req_is_write = rxreqflitv && ((req_opcode == WRITENOSNPFULL) || (req_opcode == WRITENOSNPPTL));

assign req_valid = req_is_read || req_is_write:


// Credit return logic

typedef enum logic[1:0] {INIT = 2'b00, NORMAL = 2'b01} state_t;

state_t credit_state;

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin

        credit_state<=INIT;
        credit_count<=INIT_CREDIT;
        rxreqlcrdv<=0;
        init_credit_over<=0;

    end

    else begin
        case (credit_state)
        
            INIT:begin
                if(credit_count>0)begin

                    rxreqlcrdv<=1; //if this is high, it means SN-F is sending credits to HN and using that, HN will send a Flit
                    credit_count<=credit_count-1;

                end

                else begin
                    
                    rxreqlcrdv<=0;
                    init_credit_over<=1;
                    credit_state<=NORMAL;

                end
            end

            NORMAL:begin
                // Return one credit to HN the cycle after receiving a flit
                if(rxreqflitv)begin
                    rxreqlcrdv<=1;
                end

                else begin
                    rxreqlcrdv<=0;
                end
            end

            default:begin

                credit_state<=INIT;
                rxreqlcrdv<=0;

            end

        endcase
    end
    
end

endmodule
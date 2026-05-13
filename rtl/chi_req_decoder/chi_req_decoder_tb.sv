`timescale 1ns/1ps

module tb();

localparam FLIT_WIDTH = 213;

logic clk;
logic rst_n;
logic                    rxreqflitv;          // flit valid
logic                    rxreqflitpend;       // flit pending (1 cycle warning)
logic [FLIT_WIDTH-1:0]   rxreqflit;
logic                    rxreqlcrdv;
logic                    req_valid;
logic [3:0]              req_qos;
logic [6:0]              req_tgt_id;
logic [6:0]              req_src_id;
logic [11:0]             req_txn_id;
logic [6:0]              req_opcode;
logic [2:0]              req_size;
logic [51:0]             req_addr;
logic                    req_allow_retry;
logic [1:0]              req_order;
logic [3:0]              req_mem_attr;
logic                    req_exp_comp_ack;
logic                    req_is_read;
logic                    req_is_write;


chi_req_decoder#(
    .FLIT_WIDTH(213),
    .ADDR_WIDTH(52),
    .TXN_ID_W(12),
    .NODE_ID_W(7)
)dut (
    .clk(clk),
    .rst_n(rst_n),
    .rxreqflitv(rxreqflitv),
    .rxreqflitpend(rxreqflitpend),
    .rxreqflit(rxreqflit),
    .rxreqlcrdv(rxreqlcrdv),
    .req_valid(req_valid),
    .req_qos(req_qos),
    .req_tgt_id(req_tgt_id),
    .req_src_id(req_src_id),
    .req_txn_id(req_txn_id),
    .req_opcode(req_opcode),
    .req_size(req_size),
    .req_addr(req_addr),
    .req_allow_retry(req_allow_retry),
    .req_order(req_order),
    .req_mem_attr(req_mem_attr),
    .req_exp_comp_ack(req_exp_comp_ack),
    .req_is_read(req_is_read),
    .req_is_write(req_is_write)
);

    always #5 clk = ~clk;

task send_readnosnp (
    input logic [6:0] tgt_id,
    input logic [6:0] src_id,
    input logic [11:0] txn_id,
    input logic [51:0] addr,
    input logic [2:0] size

);

    logic[212:0] flit = '0;
    
    flit[10:4] = tgt_id;
    flit[17:11] = src_id;
    flit[29:18] = txn_id;
    flit[115:64] = addr;
    flit[60:58] = size;
    flit[3:0] = '0; //QoS
    flit[120] = 0; //Allowretry
    flit[122:121] = '0; //Order
    flit[130:127] = 4'b0010; // MemAttr - Why are we using a realistic value?
    flit[141] = 0; //ExpCompAck
    flit[56:50] = 7'b0000100; //Opcode
    
    //Driving the Flit into DUT
    
    @(posedge clk);
    rxreqflitv = 1;
    rxreqflit = flit;
    //wait for one clk edge and deassert
    @(posedge clk);
    rxreqflitv = 0;
    rxreqflit = 0;
    
endtask

task send_writenosnpfull (
    input logic [6:0] tgt_id,
    input logic [6:0] src_id,
    input logic [11:0] txn_id,
    input logic [51:0] addr,
    input logic [2:0] size
);

    logic[212:0] flit = '0;

    flit[10:4] = tgt_id;
    flit[17:11] = src_id;
    flit[29:18] = txn_id;
    flit[115:64] = addr;
    flit[60:58] = size;
    flit[3:0] = '0; //QoS
    flit[120] = 0; //Allowretry
    flit[122:121] = '0; //Order
    flit[130:127] = 4'b0010; // MemAttr - Why are we using a realistic value?
    flit[141] = 0; //ExpCompAck
    flit[56:50] = 7'b0011101; //Opcode

    // Driving the flit into dut
    @(posedge clk);
    rxreqflitv = 1;
    rxreqflit = flit;

    @(posedge clk);
    rxreqflitv = 0;
    rxreqflit = 0;
    
endtask

task send_writenosnpptl (
    input logic [6:0] tgt_id,
    input logic [6:0] src_id,
    input logic [11:0] txn_id,
    input logic [51:0] addr,
    input logic [2:0] size
);

    logic[212:0] flit = '0;

    flit[10:4] = tgt_id;
    flit[17:11] = src_id;
    flit[29:18] = txn_id;
    flit[115:64] = addr;
    flit[60:58] = size;
    flit[3:0] = '0; //QoS
    flit[120] = 0; //Allowretry
    flit[122:121] = '0; //Order
    flit[130:127] = 4'b0010; // MemAttr - Why are we using a realistic value?
    flit[141] = 0; //ExpCompAck
    flit[56:50] = 7'b0011100; //Opcode

    // Driving the flit into dut
    @(posedge clk);
    rxreqflitv = 1;
    rxreqflit = flit;

    @(posedge clk);
    rxreqflitv = 0;
    rxreqflit = 0;
    
endtask

initial begin

    $dumpfile("dump.vcd"); //For waveform view
    $dumpvars();
    
    clk=0;
    rst_n=0;
    rxreqflitv=0;
    rxreqflitpend=0;
    rxreqflit=0;

    repeat(4)@(posedge clk);
    rst_n=1;

    repeat(6)@(posedge clk);
    //sending the flit (tgt,src,txn,addr,size)
    send_readnosnp(7'h01, 7'h02, 12'hABC, 52'h1000, 3'b110);
    
    //repeat(2)@(posedge clk); // waiting for outputs to settle
    //Commented the above delay as the values from function send_readnosnp are being updated in the same cycle

    if(req_is_read == 1 && req_is_write == 0 && req_valid == 1 && req_txn_id == 12'hABC && req_addr == 52'h1000 && req_size == 3'b110 && req_src_id == 7'h02 && req_tgt_id == 7'h01)begin
        $display("Simulation PASSED req_is_read:%0d, req_is_write:%0d, req_valid:%0d, req_txn_id:%0d, req_addr:%0d, req_size:%0d, req_src_id:%0d, req_tgt_id:%0d\n",req_is_read, req_is_write, req_valid, req_txn_id, req_addr, req_size, req_src_id, req_tgt_id);        
    end
    else begin
        $display("Simulation FAILED req_is_read:%0d, req_is_write:%0d, req_valid:%0d, req_txn_id:%0d, req_addr:%0d, req_size:%0d, req_src_id:%0d, req_tgt_id:%0d\n",req_is_read, req_is_write, req_valid, req_txn_id, req_addr, req_size, req_src_id, req_tgt_id);
    end

    repeat(2)@(posedge clk);
    //Testcase - ReadNoSnp with address = 0
    //sending the flit (tgt,src,txn,addr,size)
    send_readnosnp(7'h01, 7'h02, 12'hABC, 52'h0, 3'b110);

    if(req_is_read == 1 && req_is_write == 0 && req_valid == 1 && req_txn_id == 12'hABC && req_addr == 52'h0 && req_size == 3'b110 && req_src_id == 7'h02 && req_tgt_id == 7'h01)begin
        $display("Simulation PASSED req_is_read:%0d, req_is_write:%0d, req_valid:%0d, req_txn_id:%0d, req_addr:%0d, req_size:%0d, req_src_id:%0d, req_tgt_id:%0d\n",req_is_read, req_is_write, req_valid, req_txn_id, req_addr, req_size, req_src_id, req_tgt_id);        
    end
    else begin
        $display("Simulation FAILED req_is_read:%0d, req_is_write:%0d, req_valid:%0d, req_txn_id:%0d, req_addr:%0d, req_size:%0d, req_src_id:%0d, req_tgt_id:%0d\n",req_is_read, req_is_write, req_valid, req_txn_id, req_addr, req_size, req_src_id, req_tgt_id);
    end

    repeat(2)@(posedge clk);
    //Testcase - ReadNoSnp with address = 52'hFFFFFFFFFFFFF
    //sending the flit (tgt,src,txn,addr,size)
    send_readnosnp(7'h01, 7'h02, 12'hABC, 52'hFFFFFFFFFFFFF, 3'b110);

    if(req_is_read == 1 && req_is_write == 0 && req_valid == 1 && req_txn_id == 12'hABC && req_addr == 52'hFFFFFFFFFFFFF && req_size == 3'b110 && req_src_id == 7'h02 && req_tgt_id == 7'h01)begin
        $display("Simulation PASSED req_is_read:%0d, req_is_write:%0d, req_valid:%0d, req_txn_id:%0d, req_addr:%0d, req_size:%0d, req_src_id:%0d, req_tgt_id:%0d\n",req_is_read, req_is_write, req_valid, req_txn_id, req_addr, req_size, req_src_id, req_tgt_id);        
    end
    else begin
        $display("Simulation FAILED req_is_read:%0d, req_is_write:%0d, req_valid:%0d, req_txn_id:%0d, req_addr:%0d, req_size:%0d, req_src_id:%0d, req_tgt_id:%0d\n",req_is_read, req_is_write, req_valid, req_txn_id, req_addr, req_size, req_src_id, req_tgt_id);
    end

    repeat(2)@(posedge clk);
    //Testcase - ReadNoSnp with TxnID = 0
    //sending the flit (tgt,src,txn,addr,size)
    send_readnosnp(7'h01, 7'h02, 12'h0, 52'h1000, 3'b110);

    if(req_is_read == 1 && req_is_write == 0 && req_valid == 1 && req_txn_id == 12'h0 && req_addr == 52'h1000 && req_size == 3'b110 && req_src_id == 7'h02 && req_tgt_id == 7'h01)begin
        $display("Simulation PASSED req_is_read:%0d, req_is_write:%0d, req_valid:%0d, req_txn_id:%0d, req_addr:%0d, req_size:%0d, req_src_id:%0d, req_tgt_id:%0d\n",req_is_read, req_is_write, req_valid, req_txn_id, req_addr, req_size, req_src_id, req_tgt_id);        
    end
    else begin
        $display("Simulation FAILED req_is_read:%0d, req_is_write:%0d, req_valid:%0d, req_txn_id:%0d, req_addr:%0d, req_size:%0d, req_src_id:%0d, req_tgt_id:%0d\n",req_is_read, req_is_write, req_valid, req_txn_id, req_addr, req_size, req_src_id, req_tgt_id);
    end

    repeat(2)@(posedge clk);
    //Testcase - ReadNoSnp with TxnID = 12'hFFF
    //sending the flit (tgt,src,txn,addr,size)
    send_readnosnp(7'h01, 7'h02, 12'hFFF, 52'h1000, 3'b110);

    if(req_is_read == 1 && req_is_write == 0 && req_valid == 1 && req_txn_id == 12'hFFF && req_addr == 52'h1000 && req_size == 3'b110 && req_src_id == 7'h02 && req_tgt_id == 7'h01)begin
        $display("Simulation PASSED req_is_read:%0d, req_is_write:%0d, req_valid:%0d, req_txn_id:%0d, req_addr:%0d, req_size:%0d, req_src_id:%0d, req_tgt_id:%0d\n",req_is_read, req_is_write, req_valid, req_txn_id, req_addr, req_size, req_src_id, req_tgt_id);        
    end
    else begin
        $display("Simulation FAILED req_is_read:%0d, req_is_write:%0d, req_valid:%0d, req_txn_id:%0d, req_addr:%0d, req_size:%0d, req_src_id:%0d, req_tgt_id:%0d\n",req_is_read, req_is_write, req_valid, req_txn_id, req_addr, req_size, req_src_id, req_tgt_id);
    end

    repeat(2)@(posedge clk);
    //Testcase - ReadNoSnp with size = minimum - 000 - 1byte
    //sending the flit (tgt,src,txn,addr,size)
    send_readnosnp(7'h01, 7'h02, 12'hAAA, 52'h1000, 3'b000);

    if(req_is_read == 1 && req_is_write == 0 && req_valid == 1 && req_txn_id == 12'hAAA && req_addr == 52'h1000 && req_size == 3'b000 && req_src_id == 7'h02 && req_tgt_id == 7'h01)begin
        $display("Simulation PASSED req_is_read:%0d, req_is_write:%0d, req_valid:%0d, req_txn_id:%0d, req_addr:%0d, req_size:%0d, req_src_id:%0d, req_tgt_id:%0d\n",req_is_read, req_is_write, req_valid, req_txn_id, req_addr, req_size, req_src_id, req_tgt_id);        
    end
    else begin
        $display("Simulation FAILED req_is_read:%0d, req_is_write:%0d, req_valid:%0d, req_txn_id:%0d, req_addr:%0d, req_size:%0d, req_src_id:%0d, req_tgt_id:%0d\n",req_is_read, req_is_write, req_valid, req_txn_id, req_addr, req_size, req_src_id, req_tgt_id);
    end

    repeat(2)@(posedge clk);
    //Testcase - ReadNoSnp with size = maximum = 3'b110 - 64bytes
    //sending the flit (tgt,src,txn,addr,size)
    send_readnosnp(7'h01, 7'h02, 12'hBBB, 52'h1000, 3'b110);

    if(req_is_read == 1 && req_is_write == 0 && req_valid == 1 && req_txn_id == 12'hBBB && req_addr == 52'h1000 && req_size == 3'b110 && req_src_id == 7'h02 && req_tgt_id == 7'h01)begin
        $display("Simulation PASSED req_is_read:%0d, req_is_write:%0d, req_valid:%0d, req_txn_id:%0d, req_addr:%0d, req_size:%0d, req_src_id:%0d, req_tgt_id:%0d\n",req_is_read, req_is_write, req_valid, req_txn_id, req_addr, req_size, req_src_id, req_tgt_id);        
    end
    else begin
        $display("Simulation FAILED req_is_read:%0d, req_is_write:%0d, req_valid:%0d, req_txn_id:%0d, req_addr:%0d, req_size:%0d, req_src_id:%0d, req_tgt_id:%0d\n",req_is_read, req_is_write, req_valid, req_txn_id, req_addr, req_size, req_src_id, req_tgt_id);
    end

    repeat(2)@(posedge clk);
    //Testcase - WriteNoSnpFull basic transaction
    //sending the flit (tgt,src,txn,addr,size)
    send_writenosnpfull(7'h01, 7'h02, 12'hCCC, 52'h2100, 3'b110);

    if(req_is_read == 0 && req_is_write == 1 && req_valid == 1 && req_txn_id == 12'hCCC && req_addr == 52'h2100 && req_size == 3'b110 && req_src_id == 7'h02 && req_tgt_id == 7'h01)begin
        $display("Simulation PASSED req_is_read:%0d, req_is_write:%0d, req_valid:%0d, req_txn_id:%0d, req_addr:%0d, req_size:%0d, req_src_id:%0d, req_tgt_id:%0d\n",req_is_read, req_is_write, req_valid, req_txn_id, req_addr, req_size, req_src_id, req_tgt_id);        
    end
    else begin
        $display("Simulation FAILED req_is_read:%0d, req_is_write:%0d, req_valid:%0d, req_txn_id:%0d, req_addr:%0d, req_size:%0d, req_src_id:%0d, req_tgt_id:%0d\n",req_is_read, req_is_write, req_valid, req_txn_id, req_addr, req_size, req_src_id, req_tgt_id);
    end

    repeat(2)@(posedge clk);
    //Testcase - WriteNoSnpptl basic transaction
    //sending the flit (tgt,src,txn,addr,size)
    send_writenosnpptl(7'h01, 7'h02, 12'hDDD, 52'h2200, 3'b010);

    if(req_is_read == 0 && req_is_write == 1 && req_valid == 1 && req_txn_id == 12'hDDD && req_addr == 52'h2200 && req_size == 3'b010 && req_src_id == 7'h02 && req_tgt_id == 7'h01)begin
        $display("Simulation PASSED req_is_read:%0d, req_is_write:%0d, req_valid:%0d, req_txn_id:%0d, req_addr:%0d, req_size:%0d, req_src_id:%0d, req_tgt_id:%0d\n",req_is_read, req_is_write, req_valid, req_txn_id, req_addr, req_size, req_src_id, req_tgt_id);        
    end
    else begin
        $display("Simulation FAILED req_is_read:%0d, req_is_write:%0d, req_valid:%0d, req_txn_id:%0d, req_addr:%0d, req_size:%0d, req_src_id:%0d, req_tgt_id:%0d\n",req_is_read, req_is_write, req_valid, req_txn_id, req_addr, req_size, req_src_id, req_tgt_id);
    end

    $display("Simulation finished\n");

    //checking Idle behavior

    repeat(6)@(posedge clk);
    if(req_valid)
        $display("req_valid is %0d and unexpected behavior\n",req_valid);
    else
        $display("req_valid is %0d and expected behavior\n",req_valid);

    #120;
    $finish();    

end

endmodule
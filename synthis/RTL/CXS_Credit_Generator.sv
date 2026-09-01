module CXS_Credit_Generator #(
    parameter int MAX_CREDITS = 15,
    parameter int CREDIT_W = $clog2(MAX_CREDITS+1)
)(
    input  logic i_CXS_Credit_Generator_clk,
    input  logic i_CXS_Credit_Generator_rst_n,
    input  logic i_CXS_Credit_Generator_cxsvalid,   // Incoming flit from transmitter
    input  logic i_CXS_Credit_Generator_buf_release, // One FIFO entry released by receiver

    input  logic i_CXS_Credit_Generator_valid_credit_grant,

    input logic   i_CXS_Credit_Generator_CXSCRDRTN,

    output logic o_CXS_Credit_Generator_cxscrdgnt,   // Credit grant to transmitter
    output logic o_CXS_Credit_Generator_return_all_credit
);

    // Internal Registers
    // Credits granted but not yet consumed if fifo has 10 free entries and 8 outstading then the grant
    //may be generated are 2 
    logic [$clog2(MAX_CREDITS+1)-1:0] fifo_free,fifo_free_reg;
    logic [CREDIT_W-1:0] outstanding_credit,outstanding_credit_reg;
    logic grant_enable;
    logic return_all_credit;
    //logic for credit grant assign
    always_comb begin
        if ((fifo_free_reg > outstanding_credit_reg) &&
            (outstanding_credit_reg < MAX_CREDITS) && i_CXS_Credit_Generator_valid_credit_grant)
            grant_enable = 1'b1;
        else
            grant_enable = 1'b0;
    end
//combinational logic 
    always_comb 
    begin
        fifo_free = fifo_free_reg;
        outstanding_credit = outstanding_credit_reg;
        //logic for outstanding grand 
        if (grant_enable && !i_CXS_Credit_Generator_cxsvalid)
        begin
            if (outstanding_credit < MAX_CREDITS)
            outstanding_credit = outstanding_credit + 1;
        end
        else if (!grant_enable && i_CXS_Credit_Generator_cxsvalid)
        begin
             if (outstanding_credit != 0)
            outstanding_credit = outstanding_credit - 1;
        end
        else if (!i_CXS_Credit_Generator_cxsvalid && i_CXS_Credit_Generator_CXSCRDRTN )
        begin
             if (outstanding_credit != 0) 
            outstanding_credit = outstanding_credit - 1;
        end

        //logic for fifo free entries 
        if (i_CXS_Credit_Generator_cxsvalid && !i_CXS_Credit_Generator_buf_release) 
        begin
             if (fifo_free != 0)
             fifo_free = fifo_free - 1;
        end 
        else if  (!i_CXS_Credit_Generator_cxsvalid && i_CXS_Credit_Generator_buf_release)
        begin
            if (fifo_free < MAX_CREDITS)
            fifo_free = fifo_free + 1;
        end 

        return_all_credit = (outstanding_credit == 0) ? 1:0;

        // case ({i_CXS_Credit_Generator_cxsvalid, grant_enable, i_CXS_Credit_Generator_buf_release})
        //     // 001 : Buffer released only
        //     3'b001: begin
        //         if (fifo_free < MAX_CREDITS)
        //             fifo_free = fifo_free + 1;
        //     end
        //     // 010 : Grant credit only
        //     3'b010: begin
        //         if (outstanding_credit < MAX_CREDITS)
        //             outstanding_credit = outstanding_credit + 1;
        //     end
        //     // 011 : Grant credit + buffer released
        //     3'b011: begin
        //         if (fifo_free < MAX_CREDITS)
        //             fifo_free = fifo_free + 1;
        //         if (outstanding_credit < MAX_CREDITS)
        //             outstanding_credit = outstanding_credit + 1;
        //     end
        //     // 100 : Receive flit only
        //     3'b100: begin
        //         if (fifo_free != 0)
        //             fifo_free = fifo_free - 1;
        //         if (outstanding_credit != 0)
        //             outstanding_credit = outstanding_credit - 1;
        //     end
        //     // 101 : Receive flit + buffer released
        //     // Net FIFO change = 0
        //     3'b101: begin
        //         if (outstanding_credit != 0)
        //             outstanding_credit = outstanding_credit - 1;
        //     end
        //     // 110 : Receive flit + grant
        //     // Outstanding net = 0
        //     3'b110: begin
        //         if (fifo_free != 0)
        //             fifo_free = fifo_free - 1;
        //     end
        // endcase
    end

    // Credit Accounting (grant counter)
    always_ff @(posedge i_CXS_Credit_Generator_clk or negedge i_CXS_Credit_Generator_rst_n)
    begin
        if(!i_CXS_Credit_Generator_rst_n)
        begin
            fifo_free_reg          <= MAX_CREDITS;
            outstanding_credit_reg <= 0;
            //o_CXS_Credit_Generator_cxscrdgnt <= 0;
            o_CXS_Credit_Generator_return_all_credit <= 0;
        end
        else
        begin
            fifo_free_reg          <= fifo_free;
            outstanding_credit_reg <= outstanding_credit;
            //o_CXS_Credit_Generator_cxscrdgnt <= grant_enable; // commented as credit grant and ack can asserted in same cycle 
            o_CXS_Credit_Generator_return_all_credit <= return_all_credit;
        end
    end
    //compinationally output the credit grant at same cycle of ack/////////////////////////////////
    assign o_CXS_Credit_Generator_cxscrdgnt= grant_enable;
endmodule


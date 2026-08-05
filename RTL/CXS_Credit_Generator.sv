module credit_generator #(
    parameter int FIFO_DEPTH = 16,
    parameter int MAX_CREDITS = 15
)(
    input  logic clk,
    input  logic rst_n,
    input  logic i_cxsvalid,   // Incoming flit from transmitter
    input  logic i_buf_release, // One FIFO entry released by receiver
    output logic o_cxscrdgnt   // Credit grant to transmitter

);

    // Internal Registers
    // Credits granted but not yet consumed if fifo has 10 free entries and 8 outstading then the grant
    //may be generated are 2 
    logic [$clog2(FIFO_DEPTH+1)-1:0] fifo_free,fifo_free_reg;
    logic [3:0] outstanding_credit,outstanding_credit_reg;
    logic grant_enable;

    //logic for credit grant assign
    always_comb begin
        if ((fifo_free_reg > outstanding_credit_reg) &&
            (outstanding_credit_reg < MAX_CREDITS))
            grant_enable = 1'b1;
        else
            grant_enable = 1'b0;
    end
//combinational logic 
    always_comb 
    begin
        fifo_free = fifo_free_reg;
        outstanding_credit = outstanding_credit_reg;
        case ({i_cxsvalid, grant_enable, i_buf_release})
            // 001 : Buffer released only
            3'b001: begin
                if (fifo_free < FIFO_DEPTH)
                    fifo_free = fifo_free + 1;
            end
            // 010 : Grant credit only
            3'b010: begin
                if (outstanding_credit < MAX_CREDITS)
                    outstanding_credit = outstanding_credit + 1;
            end
            // 011 : Grant credit + buffer released
            3'b011: begin
                if (fifo_free < FIFO_DEPTH)
                    fifo_free = fifo_free + 1;
                if (outstanding_credit < MAX_CREDITS)
                    outstanding_credit = outstanding_credit + 1;
            end
            // 100 : Receive flit only
            3'b100: begin
                if (fifo_free != 0)
                    fifo_free = fifo_free - 1;
                if (outstanding_credit != 0)
                    outstanding_credit = outstanding_credit - 1;
            end
            // 101 : Receive flit + buffer released
            // Net FIFO change = 0
            3'b101: begin
                if (outstanding_credit != 0)
                    outstanding_credit = outstanding_credit - 1;
            end
            // 110 : Receive flit + grant
            // Outstanding net = 0
            3'b110: begin
                if (fifo_free != 0)
                    fifo_free = fifo_free - 1;
            end
        endcase
    end

    // Credit Accounting (grant counter)
    always_ff @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            fifo_free_reg          <= FIFO_DEPTH;
            outstanding_credit_reg <= 0;
            o_cxscrdgnt <= 0;
        end
        else
        begin
            fifo_free_reg          <= fifo_free;
            outstanding_credit_reg <= outstanding_credit;
            o_cxscrdgnt <= grant_enable;
        end
    end
endmodule


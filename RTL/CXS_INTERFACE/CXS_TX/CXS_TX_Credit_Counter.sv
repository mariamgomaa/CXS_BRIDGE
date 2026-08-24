// =============================================================================
// CXS_TX_Credit_Counter.sv
// Tracks credits granted by the receiver (CXSCRDGNT) and consumed by sent
// flits. Mirrors the accounting style of CXS_Credit_Generator on the RX side.
// =============================================================================

module CXS_TX_Credit_Counter #(
    parameter int MAX_CREDITS = 15,
    parameter int CREDIT_W    = $clog2(MAX_CREDITS+1)
)(
    input  logic                    i_CXS_TX_Credit_Counter_clk,
    input  logic                    i_CXS_TX_Credit_Counter_rst_n,

    input  logic                    i_CXS_TX_Credit_Counter_CXSCRDGNT, // credit granted this cycle
    input  logic                    i_CXS_TX_Credit_Counter_flit_sent, // CXSVALID this cycle (1 credit consumed)

    output logic                    o_CXS_TX_Credit_Counter_credit_avail
);

    logic [CREDIT_W-1:0] credit_count, credit_count_reg;

    always_comb begin
        credit_count = credit_count_reg;

        // Grant only: gain one credit
        if (i_CXS_TX_Credit_Counter_CXSCRDGNT && !i_CXS_TX_Credit_Counter_flit_sent) begin
            if (credit_count_reg < MAX_CREDITS)
                credit_count = credit_count_reg + 1;
        end
        // Consume only: lose one credit
        else if (!i_CXS_TX_Credit_Counter_CXSCRDGNT && i_CXS_TX_Credit_Counter_flit_sent) begin
            if (credit_count_reg != 0)
                credit_count = credit_count_reg - 1;
        end
        // Grant + consume in the same cycle: no net change 
    end

    always_ff @(posedge i_CXS_TX_Credit_Counter_clk or negedge i_CXS_TX_Credit_Counter_rst_n) begin
        if (!i_CXS_TX_Credit_Counter_rst_n)
            credit_count_reg <= '0;
        else
            credit_count_reg <= credit_count;
    end

    assign o_CXS_TX_Credit_Counter_credit_avail  = (credit_count_reg != 0);

endmodule

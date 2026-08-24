module CXS_Link_Control_TX
(
    input  logic i_CXS_Link_Control_TX_clk,
    input  logic i_CXS_Link_Control_TX_rst_n,

    input  logic i_CXS_Link_Control_TX_pkt_pending,  // data queued/arriving that needs sending
    input  logic i_CXS_Link_Control_TX_CXSACTIVEACK, // from receiver

    output logic o_CXS_Link_Control_TX_CXSACTIVEREQ,
    output logic o_CXS_Link_Control_TX_valid_sending  // gates the flit transmitter
);

    typedef enum logic [1:0] {
        STOP       = 2'b00,
        ACTIVATE   = 2'b01,
        RUN        = 2'b11,
        DEACTIVATE = 2'b10
    } state_t;

    state_t current_state, next_state;

    always_comb begin
        o_CXS_Link_Control_TX_CXSACTIVEREQ  = 1'b0;
        o_CXS_Link_Control_TX_valid_sending = 1'b0;
        case (current_state)
        STOP: // idle, no credits held, no flits in flight
        begin
            if (i_CXS_Link_Control_TX_pkt_pending)
                next_state = ACTIVATE;
            else
                next_state = STOP;
        end
        ACTIVATE: // requesting link, waiting for receiver ack
        begin
            o_CXS_Link_Control_TX_CXSACTIVEREQ = 1'b1;
            if (i_CXS_Link_Control_TX_CXSACTIVEACK) //waiting for ack
            begin
                next_state = RUN;
                o_CXS_Link_Control_TX_valid_sending = 1'b1;
            end 
            else
                next_state = ACTIVATE;
        end
        RUN: // link active, transmitter may send while it has data and credit
        begin
            o_CXS_Link_Control_TX_CXSACTIVEREQ  = 1'b1;
            o_CXS_Link_Control_TX_valid_sending = 1'b1;
            if (!i_CXS_Link_Control_TX_pkt_pending)
                next_state = DEACTIVATE;
            else
                next_state = RUN;
        end
        DEACTIVATE: // no more data, drop request and wait for receiver to drop ack
        begin
            o_CXS_Link_Control_TX_CXSACTIVEREQ = 1'b0;
            if (!i_CXS_Link_Control_TX_CXSACTIVEACK)
                next_state = STOP;
            else
                next_state = DEACTIVATE;
        end
        endcase
    end

    always_ff @(posedge i_CXS_Link_Control_TX_clk or negedge i_CXS_Link_Control_TX_rst_n)
    begin
        if (!i_CXS_Link_Control_TX_rst_n)
            current_state <= STOP;
        else
            current_state <= next_state;
    end

endmodule

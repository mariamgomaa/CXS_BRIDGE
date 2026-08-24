module CXS_Link_Control 
(
    input logic i_CXS_Link_Control_clk,
    input logic i_CXS_Link_Control_rst_n,
    input logic i_CXS_Link_Control_CXSACTIVEREQ , //this may be need to cdc solution 

    input logic i_CXS_Link_Control_return_all_credit,

    output logic o_CXS_Link_Control_valid_recieving,
    output logic o_CXS_Link_Control_valid_credit_grant,
    output logic o_CXS_Link_Control_CXSACTIVEACK 
    // output logic o_CXS_Link_Control_CXSDEACTHINT 
);



        typedef enum logic [1:0] {
            STOP     = 2'b00,
            ACTIVATE = 2'b01,
            RUN      = 2'b11,
            DEACTIVATE = 2'b10
    } state_t;

    state_t current_state ,next_state;

    //next state logic 
    always_comb 
    begin
        o_CXS_Link_Control_CXSACTIVEACK = 1'b0;
        // o_CXS_Link_Control_CXSDEACTHINT = 1'b0;
        o_CXS_Link_Control_valid_recieving = 1'b0;
        o_CXS_Link_Control_valid_credit_grant = 1'b0;
        case (current_state)
        STOP :
        begin
            if (i_CXS_Link_Control_CXSACTIVEREQ)
            next_state = ACTIVATE;
            else 
            next_state = STOP;
        end 
        ACTIVATE: // the transation state between the stop and activation that reciever can send credit and send ack
        begin
            o_CXS_Link_Control_CXSACTIVEACK = 1'b1;
            o_CXS_Link_Control_valid_credit_grant = 1'b1; //allow for reciever to assert ack and greditgrant at same cycle
            next_state = RUN ;
        end
        RUN: // at this state the link is running reciever recieve the flits and send credit
        begin
            o_CXS_Link_Control_CXSACTIVEACK = 1'b1;
            o_CXS_Link_Control_valid_recieving = 1'b1;
            o_CXS_Link_Control_valid_credit_grant = 1'b1;
            if (!i_CXS_Link_Control_CXSACTIVEREQ)
            next_state = DEACTIVATE;
            else 
            next_state = RUN;
        end
        DEACTIVATE://at this state the reciever accept remaning flit in pipline after tx finish and rest of unused credit   
        begin
            o_CXS_Link_Control_CXSACTIVEACK = 1'b1;
            o_CXS_Link_Control_valid_recieving = 1'b1;
            o_CXS_Link_Control_valid_credit_grant = 1'b0;
            if (i_CXS_Link_Control_return_all_credit)
            next_state = STOP;
            else 
            next_state = DEACTIVATE;
        end
        endcase 


    end 
    always_ff @(posedge i_CXS_Link_Control_clk or negedge i_CXS_Link_Control_rst_n )
    begin 
        if(!i_CXS_Link_Control_rst_n)
        begin
            current_state <= STOP;
        end 
        else 
        begin
            current_state <= next_state;
        end
    end 
endmodule 
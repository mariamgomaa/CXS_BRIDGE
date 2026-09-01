module CXS_RX_TOP #(
    //parameter for reciever and decoder 
    parameter int CXSMAXPAYLOADPERFLIT = 2,
    parameter int CXSDATAFLITWIDTH = 32,
    parameter int CNTL_W = 3*CXSMAXPAYLOADPERFLIT,
    //parameter for credit generator 
    parameter int MAX_CREDITS = 15,
    parameter int CREDIT_W = $clog2(MAX_CREDITS+1),
    parameter int FIFO_WIDTH = CNTL_W + CXSDATAFLITWIDTH

) (

    input logic                          i_CXS_RX_TOP_CLK,
    input logic                          i_CXS_RX_TOP_rst_n,
    input logic [CXSDATAFLITWIDTH-1 :0]  i_CXS_RX_TOP_CXSDATA ,
    input logic [CNTL_W-1 : 0]           i_CXS_RX_TOP_CXSCNTL,
    input logic                          i_CXS_RX_TOP_CXSVALID,
    input logic                          i_CXS_RX_TOP_CXSACTIVEREQ,
    input logic                          i_CXS_RX_TOP_CXSCRDRTN,
    input logic                          i_CXS_RX_TOP_buf_release,  //from asynchronous fifo 

    // output logic                         o_CXS_RX_TOP_CXSDEACTHINT,
    output logic                         o_CXS_RX_TOP_CXSCRDGNT,
    output logic                         o_CXS_RX_TOP_CXSACTIVEACK,
    output logic                         o_CXS_RX_TOP_VALID,
    output logic[FIFO_WIDTH-1 : 0]       o_CXS_RX_TOP_DATA

);
    //internal wire 

    //wires for connect reciever <--> with link control

    logic state_valid_recieving;
    logic valid_credit_grant;

    //wires for connect reciever <--> with decoder <---> boundry extractor
    logic                             flit_valid;
    logic  [CNTL_W-1 : 0 ]            cxscntl_data;
    logic  [CXSDATAFLITWIDTH-1 : 0 ]  cxsdata ;
    logic  [CXSMAXPAYLOADPERFLIT-1:0] start_field;
    logic  [CXSMAXPAYLOADPERFLIT-1:0] end_field;
    logic  [CXSMAXPAYLOADPERFLIT-1:0] error_field;
    
    //internal wires to connect the link controller <--> credit generator <--> flit reciever
    logic return_all_credit;
    
    // reciever module instantiation 

    CXS_flit_receiver #(
    .CXSMAXPAYLOADPERFLIT(CXSMAXPAYLOADPERFLIT),
    .CXSDATAFLITWIDTH(CXSDATAFLITWIDTH),
    .CNTL_W(CNTL_W)

) 
    u_CXS_flit_receiver
(
    .i_CXS_flit_receiver_CXS_CLK(i_CXS_RX_TOP_CLK),
    .i_CXS_flit_receiver_RST_N(i_CXS_RX_TOP_rst_n),

    .i_CXS_flit_receiver_CXSVALID(i_CXS_RX_TOP_CXSVALID),
    .i_CXS_flit_receiver_CXSDATA(i_CXS_RX_TOP_CXSDATA),
    .i_CXS_flit_receiver_CXSCNTL(i_CXS_RX_TOP_CXSCNTL),

    .i_CXS_flit_state_valid_recieving(state_valid_recieving),

    .o_CXS_flit_receiver_flit_valid(flit_valid),
    .o_CXS_flit_receiver_rx_data(cxsdata),
    .o_CXS_flit_receiver_cxscntl_data(cxscntl_data)
);

    cxscntl_decoder #(
    .CXSMAXPAYLOADPERFLIT(CXSMAXPAYLOADPERFLIT),
    .CXSDATAFLITWIDTH(CXSDATAFLITWIDTH),
    .CNTL_W(CNTL_W)
)
    u_cxscntl_decoder
(
    .i_cxscntl_decoder_flit_valid(flit_valid),
    .i_cxscntl_decoder_cxscntl_data(cxscntl_data),

    .o_cxscntl_decoder_start_field(start_field),
    .o_cxscntl_decoder_end_field(end_field),
    .o_cxscntl_decoder_end_error(error_field)

);
assign o_CXS_RX_TOP_VALID = flit_valid;

    CXS_Boundry_Extractor #(

    .CXSMAXPAYLOADPERFLIT(CXSMAXPAYLOADPERFLIT),
    .CXSDATAFLITWIDTH (CXSDATAFLITWIDTH),
    .CNTL_W (CNTL_W),
    .FIFO_WIDTH(FIFO_WIDTH)
)
    u_CXS_Boundry_Extractor
(
    .i_boundry_extractor_cxsdata(cxsdata),
    .i_boundry_extractor_start_field(start_field),
    .i_boundry_extractor_end_filed(end_field),
    .i_boundry_extractor_error_field(error_field),

    .o_boundry_extractor_data(o_CXS_RX_TOP_DATA)

);

CXS_Link_Control u_CXS_Link_Control
(
    .i_CXS_Link_Control_clk(i_CXS_RX_TOP_CLK),
    .i_CXS_Link_Control_rst_n(i_CXS_RX_TOP_rst_n),
    .i_CXS_Link_Control_CXSACTIVEREQ(i_CXS_RX_TOP_CXSACTIVEREQ) , 

    .i_CXS_Link_Control_return_all_credit(return_all_credit),

    .o_CXS_Link_Control_valid_recieving(state_valid_recieving),
    .o_CXS_Link_Control_valid_credit_grant(valid_credit_grant),
    .o_CXS_Link_Control_CXSACTIVEACK(o_CXS_RX_TOP_CXSACTIVEACK)
    // .o_CXS_Link_Control_CXSDEACTHINT(o_CXS_RX_TOP_CXSDEACTHINT) 

);

CXS_Credit_Generator #(
    .MAX_CREDITS (MAX_CREDITS),
    .CREDIT_W (CREDIT_W)
)
    u_CXS_Credit_Generator
(
    .i_CXS_Credit_Generator_clk(i_CXS_RX_TOP_CLK),
    .i_CXS_Credit_Generator_rst_n(i_CXS_RX_TOP_rst_n),
    .i_CXS_Credit_Generator_cxsvalid(flit_valid),   // Incoming flit from transmitter
    .i_CXS_Credit_Generator_buf_release(i_CXS_RX_TOP_buf_release), // One FIFO entry released by receiver

    .i_CXS_Credit_Generator_valid_credit_grant(valid_credit_grant),

    .i_CXS_Credit_Generator_CXSCRDRTN(i_CXS_RX_TOP_CXSCRDRTN),

    .o_CXS_Credit_Generator_cxscrdgnt(o_CXS_RX_TOP_CXSCRDGNT),   // Credit grant to transmitter
    .o_CXS_Credit_Generator_return_all_credit(return_all_credit)
);
endmodule
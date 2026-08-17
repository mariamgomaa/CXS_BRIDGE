
module control_unit #(
    parameter int   PAYLOAD_W = 16,
    parameter int   ADDR_W    = 8,
    parameter int   DATA_W    = 8,
    parameter int  PAYLOAD_INFO_W=PAYLOAD_W+3
)
(
    //system signals 
    input  logic                  i_control_unit_clk,
    input  logic                  i_control_unit_rst_n,

    // FIFO Interface
    input  logic                  i_control_unit_fifo_empty,
    input  logic [PAYLOAD_INFO_W-1:0]   i_control_unit_fifo_data,

    // cdm interface 
    input  logic                  i_control_unit_config_done,
    input  logic[PAYLOAD_W-1:0]   i_control_unit_config_data,

    // FSM outputs
    output logic                  o_control_unit_rd_fifo_en,
    output logic                  o_control_unit_config_we,
    output logic                  o_control_unit_payload_valid,
    output logic                  o_control_unit_status_valid,
    output logic                  o_control_unit_rd_config_en,

    // Datapath
    output logic [ADDR_W-1:0]     o_control_unit_address,
    output logic [DATA_W-1:0]     o_control_unit_data,
    output logic [PAYLOAD_W-1:0]  o_control_unit_config_data,
    output logic [ADDR_W-1:0]     o_control_unit_config_address,
    
    // Configuration
    output logic                  o_control_unit_addr_mode,
    output logic [2:0]            o_control_unit_enc_mode,
    output logic [1:0]            o_control_unit_parity_mode
);

    //----------------------------------------------------
    // FIFO Decode
    //----------------------------------------------------

    logic pkt_start;
    logic pkt_end;
    logic pkt_error;
    logic [PAYLOAD_W-1:0] payload_reg;

    assign pkt_start = i_control_unit_fifo_data[PAYLOAD_INFO_W-1];
    assign pkt_end   = i_control_unit_fifo_data[PAYLOAD_INFO_W-2];
    assign pkt_error   = i_control_unit_fifo_data[PAYLOAD_INFO_W-3];
//register the data for storing the correct value in cdm 
    always_ff @(posedge i_control_unit_clk or negedge i_control_unit_rst_n) begin
        if (!i_control_unit_rst_n)
            payload_reg <= '0;
        else if (o_control_unit_rd_fifo_en)
            payload_reg <= i_control_unit_fifo_data[PAYLOAD_W-1:0];
    end

    //address internal wire 
    logic first_cfg_tlp;
    logic config_address_counter;
    //----------------------------------------------------
    // Header Decoder Signals
    //----------------------------------------------------


    logic [1:0] pkt_type;
    logic [1:0] parity_mode;
    logic [2:0] enc_mode;
    logic [7:0] dev_count;
    logic       addr_mode;

    //----------------------------------------------------
    // Header Validator
    //----------------------------------------------------

    logic header_valid;

    //----------------------------------------------------
    // Header Decoder
    //----------------------------------------------------

    header_decoder u_header_decoder
    (
        .i_header_decoder_header(i_control_unit_fifo_data[PAYLOAD_W-1:0]),

        .o_header_decoder_pkt_type    (pkt_type),
        .o_header_decoder_parity_mode (parity_mode),
        .o_header_decoder_enc_mode    (enc_mode),
        .o_header_decoder_dev_count   (dev_count),
        .o_header_decoder_addr_mode   (addr_mode)
    );

    //----------------------------------------------------
    // Header Validator
    //----------------------------------------------------

    header_validitor u_header_validator
    (
        .i_header_validitor_pkt_type    (pkt_type),
        .i_header_validitor_parity_mode (parity_mode),
        .i_header_validitor_enc_mode    (enc_mode),
        .i_header_validitor_dev_count   (dev_count),

        .o_header_validitor_valid(header_valid)
    );

    //----------------------------------------------------
    // FSM
    //----------------------------------------------------

    control_unit_fsm u_fsm
    (
        .i_control_unit_fsm_clk          (i_control_unit_clk),
        .i_control_unit_fsm_rst_n        (i_control_unit_rst_n),

        .i_control_unit_fsm_fifo_empty   (i_control_unit_fifo_empty),

        .i_control_unit_fsm_pkt_start    (pkt_start),
        .i_control_unit_fsm_pkt_end      (pkt_end),
        .i_control_unit_fsm_pkt_error     (pkt_error),


        .i_control_unit_fsm_pkt_type     (pkt_type),
        .i_control_unit_fsm_device_count  (dev_count),
        .i_control_unit_fsm_header_valid (header_valid),

        .i_control_unit_fsm_config_done  (i_control_unit_config_done),

        .o_control_unit_fsm_config_address_counter (config_address_counter),
        .o_control_unit_fsm_rd_config_en (o_control_unit_rd_config_en),
        .o_control_unit_fsm_rd_fifo_en   (o_control_unit_rd_fifo_en),
        .o_control_unit_fsm_config_we    (o_control_unit_config_we),
        .o_control_unit_fsm_payload_valid(o_control_unit_payload_valid),
        .o_control_unit_fsm_first_cfg_tlp(first_cfg_tlp),
        .o_control_unit_fsm_status_valid (o_control_unit_status_valid)
    );


    //address for configration packet controller
    config_addr_ctrl u_config_addr_ctrl
(
    .i_config_addr_ctrl_clk         (i_control_unit_clk),
    .i_config_addr_ctrl_rst_n       (i_control_unit_rst_n),
    .i_config_addr_ctrl_first_cfg_tlp (first_cfg_tlp),
    .i_control_unit_rd_fifo_en   (o_control_unit_rd_fifo_en),
    .i_config_addr_ctrl_pkt_start   (pkt_start),
    .i_config_addr_ctrl_pkt_type    (pkt_type),
    .i_config_addr_ctrl_config_address_counter (config_address_counter),

    .o_config_addr_ctrl_config_addr (o_control_unit_config_address)
);
    //----------------------------------------------------
    // Datapath
    //----------------------------------------------------

    assign o_control_unit_address = payload_reg[15:8];
    assign o_control_unit_data    = payload_reg[7:0];

    //----------------------------------------------------
    // Configuration outputs
    //----------------------------------------------------
    assign o_control_unit_config_data = payload_reg ;
    assign o_control_unit_addr_mode   = i_control_unit_config_data[15];
    assign o_control_unit_enc_mode    = i_control_unit_config_data[6:4];
    assign o_control_unit_parity_mode = i_control_unit_config_data[3:2];

endmodule
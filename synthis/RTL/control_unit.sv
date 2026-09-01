
module control_unit #(
    parameter int   PAYLOAD_W = 16,
    parameter int   CONFIG_DATA_W = 32,
    parameter int   ADDR_W    = 8,
    parameter int   DATA_W    = 8
)
(
    //system signals 
    input  logic                  i_control_unit_clk,
    input  logic                  i_control_unit_rst_n,

    // FIFO Interface
    input  logic                  i_control_unit_flit_decoder_cu_valid,
    //input  logic                  i_control_unit_data_valid,

    input  logic [PAYLOAD_W-1:0]   i_control_unit_fifo_data,

    // cdm interface 
    input  logic[CONFIG_DATA_W-1:0]   i_control_unit_config_data,

    // FSM outputs
    output logic                  o_control_unit_rd_fifo_en,

    input logic                           i_control_unit_start_pkt,
    input logic                           i_control_unit_end_pkt,
    input logic                           i_control_unit_error_pkt,

    input logic                             i_control_unit_app_ack,


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
    output logic [1:0]            o_control_unit_parity_mode,
    output logic [ADDR_W-1:0]     o_control_unit_base_address,
    output logic [ADDR_W-1:0]     o_control_unit_device_count,
    output logic [1:0]            o_control_unit_status_pkt_type,   // which pkt_type this status refers to ass error
    output logic [1:0]            o_control_unit_status_error_type 
);

    //----------------------------------------------------
    // FIFO Decode
    //----------------------------------------------------

    logic [PAYLOAD_W-1:0] payload_reg;

//register the data for storing the correct value in cdm 
    always_ff @(posedge i_control_unit_clk or negedge i_control_unit_rst_n) begin
        if (!i_control_unit_rst_n)
        begin
            payload_reg <= '0;
            // pkt_start <= 1'b0;
            // pkt_end   <= 1'b0;
            // pkt_error <= 1'b0;
        end
        else if (o_control_unit_rd_fifo_en)
        begin
            payload_reg <= i_control_unit_fifo_data ;
            // pkt_start <= i_control_unit_fifo_data[PAYLOAD_INFO_W-1];
            // pkt_end   <= i_control_unit_fifo_data[PAYLOAD_INFO_W-2];
            // pkt_error   <= i_control_unit_fifo_data[PAYLOAD_INFO_W-3];
    end
    end

    //address internal wire 
    logic first_cfg_tlp;
    logic config_address_counter;
    logic new_config_pkt;
    //----------------------------------------------------
    // Header Decoder Signals
    //----------------------------------------------------


    logic [1:0] pkt_type;
    logic [1:0] parity_mode;
    logic [2:0] enc_mode;
    logic [7:0] dev_count;

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
        .o_header_decoder_dev_count   (dev_count)
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

        .i_control_unit_fsm_flit_decoder_cu_valid   (i_control_unit_flit_decoder_cu_valid),

        .i_control_unit_fsm_pkt_start    (i_control_unit_start_pkt),
        .i_control_unit_fsm_pkt_end      (i_control_unit_end_pkt),
        .i_control_unit_fsm_pkt_error     (i_control_unit_error_pkt),

        .i_control_unit_fsm_pkt_type     (pkt_type),
        .i_control_unit_fsm_device_count  (dev_count),
        .i_control_unit_fsm_header_valid (header_valid),

        .i_control_unit_fsm_app_ack  (i_control_unit_app_ack),


        .o_control_unit_fsm_config_address_counter (config_address_counter),
        .o_control_unit_fsm_rd_config_en (o_control_unit_rd_config_en),
        .o_control_unit_fsm_rd_fifo_en   (o_control_unit_rd_fifo_en),
        .o_control_unit_fsm_config_we    (o_control_unit_config_we),
        .o_control_unit_fsm_payload_valid(o_control_unit_payload_valid),
        .o_control_unit_fsm_first_cfg_tlp(first_cfg_tlp),
        .o_control_unit_fsm_status_valid (o_control_unit_status_valid),

        .o_control_unit_fsm_status_pkt_type(o_control_unit_status_pkt_type),
        .o_control_unit_fsm_status_error_type(o_control_unit_status_error_type),
        .o_control_unit_fsm_new_config_pkt(new_config_pkt)


    );


    //address for configration packet controller
    config_addr_ctrl u_config_addr_ctrl
(
    .i_config_addr_ctrl_clk         (i_control_unit_clk),
    .i_config_addr_ctrl_rst_n       (i_control_unit_rst_n),
    .i_config_addr_ctrl_first_cfg_tlp (first_cfg_tlp),
    .i_config_addr_ctrl_pkt_start   (i_control_unit_start_pkt),
    .i_config_addr_ctrl_pkt_type    (pkt_type),
    .i_config_addr_ctrl_config_address_counter (config_address_counter),
    .i_config_addr_ctrl_new_config_pkt (new_config_pkt),
    .o_config_addr_ctrl_config_addr (o_control_unit_config_address)
);
    // ----------------------------------------------------
    // Datapath
    // ----------------------------------------------------
    always_comb begin
        if (o_control_unit_payload_valid)
        begin
    o_control_unit_address = payload_reg[15:8];
    o_control_unit_data    = payload_reg[7:0];
    //----------------------------------------------------
    // Configuration outputs
    //----------------------------------------------------
    o_control_unit_base_address = i_control_unit_config_data[23:16];
    o_control_unit_addr_mode   = i_control_unit_config_data[15];
    o_control_unit_enc_mode    = i_control_unit_config_data[6:4];
    o_control_unit_parity_mode = i_control_unit_config_data[3:2];
    o_control_unit_device_count = i_control_unit_config_data [14:7];
        end
    else 
    begin
    o_control_unit_address = 'b0;
    o_control_unit_data    = 'b0;
    o_control_unit_device_count = 'b0;
    //----------------------------------------------------
    // Configuration outputs
    //----------------------------------------------------
    o_control_unit_base_address = 'b0;
    o_control_unit_addr_mode   = 'b0;
    o_control_unit_enc_mode    = 'b0;
    o_control_unit_parity_mode = 'b0;
    end
    end


    assign o_control_unit_config_data = (o_control_unit_config_we) ? payload_reg : 'b0 ;

endmodule
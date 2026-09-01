module CXS_SYSTEM_TOP #(
    parameter int NUMBER_STAGES = 2,
    //--------------------------------------------------
    // CXS Parameters
    //--------------------------------------------------
    parameter int CXSMAXPAYLOADPERFLIT = 2,
    parameter int CXSDATAFLITWIDTH     = 32,

    //--------------------------------------------------
    // FIFO / Credit Parameters
    //--------------------------------------------------
    parameter int FIFO_DEPTH            = 16,
    parameter int MAX_CREDITS           = 15,

    //--------------------------------------------------
    // Processing Parameters
    //--------------------------------------------------
    parameter int PAYLOAD_W             = 16,
    parameter int ADDR_W                = 8,
    parameter int LOGICAL_ADD_W     = 9,
    parameter int DATA_W                = 8,
    //DATA SYNCHRONIZER PARAMETER 
    parameter int NUM_STAGES          =2,
    parameter  int  BUS_WIDTH          =4,
    //--------------------------------------------------
    // Derived Parameters
    //--------------------------------------------------
    parameter int CNTL_W                = 3 * CXSMAXPAYLOADPERFLIT,
    parameter int FIFO_WIDTH            = CNTL_W + CXSDATAFLITWIDTH,
    parameter int CREDIT_W              = $clog2(MAX_CREDITS + 1),
    parameter int ENCRYPTED_W           = 2 * DATA_W,
    parameter int CDM_DATA_W            = ENCRYPTED_W + 1,
    parameter int CONFIG_DATA_W         = 32,
    parameter int DEPTH                 = 512
    
)(
    input logic                        i_rst_n,
    //--------------------------------------------------
    // RX CXS INTERFACE
    //--------------------------------------------------
    input logic                         i_cxs_clk,
    input logic [CXSDATAFLITWIDTH-1:0]  i_cxsdata,
    input logic [CNTL_W-1:0]            i_cxscntl,
    input logic                         i_cxsvalid,
    input logic                         i_cxsactivereq,
    input logic                         i_cxscrdrtn,
    //-----------------------------------------------------
    // TX CXS INTERFACE  
    //---------------------------------------------------
    input logic                        i_cxs_cxscrdgnt,
    input logic                        i_cxs_cxsactiveack,
    //--------------------------------------------------
    // FIFO Read / Processing Clock Domain
    //--------------------------------------------------
    input logic                         i_system_clk,

    //--------------------------------------------------
    // Outputs for cxs interface 
    //--------------------------------------------------
    output logic                         o_cxscrdgnt,
    output logic                         o_cxsactiveack,

    output logic                                o_CXSVALID,
    output logic[CXSDATAFLITWIDTH-1 : 0]    o_CXSDATA,
    output logic[CNTL_W-1 : 0 ]                 o_CXSCNTL,
    output logic                                o_CXSACTIVEREQ,
    //---------------------------------------------
    //cdm interface 
    //--------------------------------------
    input  logic                     i_app_rd_en,
    input  logic [LOGICAL_ADD_W-1:0] i_app_rd_address,
    input logic                      i_app_ack,
    output logic [CDM_DATA_W-1:0]    o_app_rd_data
);


    //====================================================
    // Internal Signals
    //====================================================
    //---------------------------------------------
    // internal signals for tx interfce and control unit
    logic                         status_valid;
    logic [1:0]  status_pkt_type;   
    logic [1:0]  status_error_type ;
    logic [BUS_WIDTH-1:0] synch_status;
    logic        synch_status_valid;
    //--------------------------------------------------
    // CXS RX TOP --> Async FIFO
    //--------------------------------------------------
    logic [FIFO_WIDTH-1:0] rx_data;
    logic                  rx_valid;

    //--------------------------------------------------
    // Async FIFO
    //--------------------------------------------------
    logic [FIFO_WIDTH-1:0] fifo_data_out;
    logic                  fifo_full;
    logic                  fifo_empty;
    logic                  fifo_wr_en;
    logic                  fifo_rd_en;
    logic                  fifo_buf_release;

    //--------------------------------------------------
    // Flit Decoder --> Control Unit
    //--------------------------------------------------
    logic                  flit_decoder_cu_valid;
    logic                  control_unit_rd_fifo_en;

    logic [PAYLOAD_W-1:0]  decoded_payload;

    //--------------------------------------------------
    // Control Unit --> Configuration / CDM
    //--------------------------------------------------
    logic                  config_we;
    logic                  payload_valid;
    logic                  rd_config_en;

    logic [ADDR_W-1:0]     payload_address;
    logic [DATA_W-1:0]     payload_data;

    logic [PAYLOAD_W-1:0]  config_data;
    logic [ADDR_W-1:0]     config_address;

    logic                  addr_mode;
    logic [2:0]            enc_mode;
    logic [1:0]            parity_mode;
    logic [ADDR_W-1:0]     device_count;

    //--------------------------------------------------
    // Encryption Unit
    //--------------------------------------------------
    logic [ENCRYPTED_W-1:0] encrypted_data;
    logic                   encrypted_valid;

    //--------------------------------------------------
    // Parity Unit
    //--------------------------------------------------
    logic [CDM_DATA_W-1:0] parity_data;
    logic                  parity_done;

    //--------------------------------------------------
    // CDM Control Signals
    //--------------------------------------------------
    logic                  cdm_wr_en;
    logic                  cdm_addr_valid;
    logic                  cdm_data_valid;

    logic [LOGICAL_ADD_W-1:0]     cdm_wr_address;
    logic [CDM_DATA_W-1:0] cdm_wr_data;

    logic                            cdm_config_rd_en;
    logic [CONFIG_DATA_W-1:0]       cdm_rd_config_data;


    logic [7:0]                     base_address;
    logic [LOGICAL_ADD_W-1 : 0]            atu_address ;
    logic                           atu_valid;

    logic error_pkt;
    logic start_pkt;
    logic end_pkt;


    logic cxs_rst_n;
    logic system_rst_n;
    //====================================================
    //CXS  INTERFACE TOP
    //====================================================
        // CXS INTERFACE INSTANTIATION 

    CXS_TOP #(
    //parameter for reciever and decoder 
    .CXSMAXPAYLOADPERFLIT (CXSMAXPAYLOADPERFLIT),
    .CXSDATAFLITWIDTH (CXSDATAFLITWIDTH),
    .CNTL_W (CNTL_W),
    //parameter for credit generator 
    .MAX_CREDITS(MAX_CREDITS),
    .CREDIT_W(CREDIT_W),
    .FIFO_WIDTH (FIFO_WIDTH)

) 
u_CXS_TOP
(
    .i_CXS_TOP_CLK(i_cxs_clk),
    .i_CXS_TOP_rst_n(cxs_rst_n),
    // CXS RECIEVER INTERFACE 
    .i_CXS_TOP_CXSDATA(i_cxsdata) ,
    .i_CXS_TOP_CXSCNTL(i_cxscntl),
    .i_CXS_TOP_CXSVALID(i_cxsvalid),
    .i_CXS_TOP_CXSACTIVEREQ(i_cxsactivereq),
    .i_CXS_TOP_CXSCRDRTN(i_cxscrdrtn),
    .i_CXS_TOP_buf_release(fifo_buf_release),  //from asynchronous fifo 


    .o_CXS_TOP_CXSCRDGNT(o_cxscrdgnt),
    .o_CXS_TOP_CXSACTIVEACK(o_cxsactiveack),
    .o_CXS_TOP_VALID(rx_valid),
    .o_CXS_TOP_DATA(rx_data),

    // CXS TRANSMITTER INTERFACE 
    // status information to send (e.g. from control_unit)
    .i_CXS_TOP_status_valid(synch_status_valid),
    .i_CXS_TOP_status_pkt_type(synch_status[3:2]),
    .i_CXS_TOP_status_error_type(synch_status[1:0]),

    // CXS link inputs from the receiver
    .i_CXS_TOP_CXSCRDGNT(i_cxs_cxscrdgnt),
    .i_CXS_TOP_CXSACTIVEACK(i_cxs_cxsactiveack),

    // CXS link outputs to the receiver
    .o_CXS_TOP_CXSVALID(o_CXSVALID),
    .o_CXS_TOP_CXSDATA(o_CXSDATA),
    .o_CXS_TOP_CXSCNTL(o_CXSCNTL),
    .o_CXS_TOP_CXSACTIVEREQ(o_CXSACTIVEREQ)
);


    assign fifo_wr_en = rx_valid && !fifo_full;
///////////////////////////////////////////////////////////
//CDC SOLUTION FROM FAST TO SLOW USING ASYNCH FIFO 
//DATA SYNCHRONIZER FROM SLOW TO FAST FOR TRANSMITTER 
//////////////////////////////////////////////////////////////
DATA_SYNC #(
    .NUM_STAGES (NUM_STAGES ),
    .BUS_WIDTH  (BUS_WIDTH) 
    
)
u_DATA_SYNC
(
    .i_DATA_SYNC_CLK(i_cxs_clk),
    .i_DATA_SYNC_RST_n(cxs_rst_n),
    .i_DATA_SYNC_usync_bus({status_pkt_type,status_error_type}),
    .i_DATA_SYNC_bus_enable(status_valid),

    .o_DATA_SYNC_sync_bus(synch_status),
    .o_DATA_SYNC_enable_pulse(synch_status_valid)

);

    async_fifo #(
        .DEPTH (FIFO_DEPTH),
        .WIDTH (FIFO_WIDTH)
    ) u_async_fifo (

        //------------------------------------------------
        // Write Domain
        //------------------------------------------------
        .i_Asynch_FIFO_wr_clk  (i_cxs_clk),
        .i_Asynch_FIFO_wr_rstn (cxs_rst_n),

        .i_Asynch_FIFO_data_in (rx_data),
        .i_Asynch_FIFO_wr_en   (fifo_wr_en),

        //------------------------------------------------
        // Read Domain
        //------------------------------------------------
        .i_Asynch_FIFO_rd_clk  (i_system_clk),
        .i_Asynch_FIFO_rd_rstn (system_rst_n),

        .i_Asynch_FIFO_rd_en   (fifo_rd_en),

        //------------------------------------------------
        // Data / Status
        //------------------------------------------------
        .o_Asynch_FIFO_data_out    (fifo_data_out),
        .o_Asynch_FIFO_full        (fifo_full),
        .o_Asynch_FIFO_empty       (fifo_empty),

        // Returned to CXS_RX_TOP Credit Generator
        .o_Asynch_FIFO_buf_release (fifo_buf_release)
    );

RST_SYNCH #(
    .NUMBER_STAGES (NUMBER_STAGES)
)
u_RST_SYNCH_CXS
(
    .CLK(i_cxs_clk),
    .RST(i_rst_n),
    .SYNCH_RST(cxs_rst_n)
);

RST_SYNCH #(
    .NUMBER_STAGES (NUMBER_STAGES)
)
u_RST_SYNCH_SYSTEM
(
    .CLK(i_system_clk),
    .RST(i_rst_n),
    .SYNCH_RST(system_rst_n)
);
////////////////////////////////////////////////////////////////////////////

    Flit_Decoder #(
        .CXSMAXPAYLOADPERFLIT (CXSMAXPAYLOADPERFLIT),
        .CNTL_W (CNTL_W),
        .FIFO_WIDTH (FIFO_WIDTH),
        .PAYLOAD_W (PAYLOAD_W),
        .CXSDATAFLITWIDTH     (CXSDATAFLITWIDTH)
    ) u_flit_decoder (

        .i_Flit_Decoder_clk        (i_system_clk),
        .i_Flit_Decoder_rst_n      (system_rst_n),

        .i_Flit_Decoder_Data_in    (fifo_data_out),
        .i_Flit_Decoder_fifo_empty (fifo_empty),

        // Request from Control Unit
        .i_Flit_Decoder_cu_rd_en   (control_unit_rd_fifo_en),

        // Request to Async FIFO
        .o_Flit_Decoder_fifo_rd_en (fifo_rd_en),

        // Data available for CU
        .o_Flit_Decoder_cu_valid   (flit_decoder_cu_valid),

        // Decoded payload information
        .o_Flit_Decoder_payload    (decoded_payload),

        .o_Flit_Decoder_start_pkt(start_pkt),
        .o_Flit_Decoder_end_pkt(end_pkt),
        .o_Flit_Decoder_error_pkt(error_pkt)

    );



    //====================================================
    // 4. CONTROL UNIT
    //====================================================

    control_unit #(
        .PAYLOAD_W (PAYLOAD_W),
        .ADDR_W    (ADDR_W),
        .DATA_W    (DATA_W),
        .CONFIG_DATA_W (CONFIG_DATA_W)
    ) u_control_unit (

        //------------------------------------------------
        // System
        //------------------------------------------------
        .i_control_unit_clk       (i_system_clk),
        .i_control_unit_rst_n     (system_rst_n),

        //------------------------------------------------
        // Flit Decoder Interface
        //------------------------------------------------
        .i_control_unit_flit_decoder_cu_valid(flit_decoder_cu_valid),
        .i_control_unit_fifo_data (decoded_payload),

        //------------------------------------------------
        // CDM Configuration Read Interface
        //------------------------------------------------
        .i_control_unit_config_data(
            cdm_rd_config_data[CONFIG_DATA_W-1:0]
        ),

        .i_control_unit_start_pkt(start_pkt),
        .i_control_unit_end_pkt(end_pkt),
        .i_control_unit_error_pkt(error_pkt),

        .i_control_unit_app_ack(i_app_ack),

        //------------------------------------------------
        // FSM Outputs
        //------------------------------------------------
        .o_control_unit_rd_fifo_en
            (control_unit_rd_fifo_en),

        .o_control_unit_config_we
            (config_we),

        .o_control_unit_payload_valid
            (payload_valid),


        .o_control_unit_status_valid
            (status_valid),

        .o_control_unit_rd_config_en
            (rd_config_en),

        //------------------------------------------------
        // Payload Datapath
        //------------------------------------------------
        .o_control_unit_address
            (payload_address),

        .o_control_unit_data
            (payload_data),

        //------------------------------------------------
        // Configuration Write
        //------------------------------------------------
        .o_control_unit_config_data
            (config_data),

        .o_control_unit_config_address
            (config_address),

        //------------------------------------------------
        // Configuration
        //------------------------------------------------
        .o_control_unit_addr_mode
            (addr_mode),

        .o_control_unit_enc_mode
            (enc_mode),

        .o_control_unit_parity_mode
            (parity_mode),

        .o_control_unit_base_address
        (base_address),

        .o_control_unit_device_count
        (device_count),

        .o_control_unit_status_pkt_type(status_pkt_type),
        .o_control_unit_status_error_type(status_error_type)
    );
address_translation_unit #(
    .ADD_W ( ADDR_W),
    .LOGICAL_ADD_W (LOGICAL_ADD_W)
)
u_address_translation_unit
(

    .i_atu_mode(addr_mode),      // 0 = Limit Mode (future work), 1 = Region Mode
    .i_atu_address(payload_address),
    .i_atu_valid(payload_valid),
    .i_atu_start_address (device_count),
    .i_atu_base_address(base_address),  
    .o_atu_address(atu_address),
    .o_atu_valid(atu_valid)
);
    encryption_unit #(
        .DATA_WIDTH (DATA_W)
    ) u_encryption_unit (

        .i_encryption_unit_payload_data
            (payload_data),

        .i_encryption_unit_payload_valid
            (payload_valid),

        .i_encryption_unit_encryption_mode
            (enc_mode),

        .o_encryption_unit_encrypted_data
            (encrypted_data),

        .o_encryption_unit_encrypted_valid
            (encrypted_valid)
    );



    parity_unit #(
        .DATA_W (ENCRYPTED_W)
    ) u_parity_unit (

        .i_parity_unit_encrypted_data
            (encrypted_data),

        .i_parity_unit_encrypted_valid
            (encrypted_valid),

        .i_parity_unit_parity_mode
            (parity_mode),

        .o_parity_unit_data_with_parity
            (parity_data),

        .o_parity_unit_parity_done
            (parity_done)
    );
    


    always_comb begin

        //------------------------------------------------
        // Default values
        //------------------------------------------------
        cdm_wr_en       = 1'b0;
        cdm_addr_valid  = 1'b0;
        cdm_data_valid  = 1'b0;
        cdm_wr_address  = '0;
        cdm_wr_data     = '0;

        //------------------------------------------------
        // Configuration Write
        //------------------------------------------------
        if (config_we) begin

            cdm_wr_en      = 1'b1;
            cdm_addr_valid = 1'b1;
            cdm_data_valid = 1'b1;

            cdm_wr_address = {1'b0,config_address} ;

            // Zero-extend configuration data to CDM width
            cdm_wr_data =
                {{(CDM_DATA_W-PAYLOAD_W){1'b0}}, config_data};

        end

        //------------------------------------------------
        // Normal Processed Payload Write
        //------------------------------------------------
        else if (parity_done&&atu_valid) begin

            cdm_wr_en      = 1'b1;
            cdm_addr_valid = 1'b1;
            cdm_data_valid = 1'b1;

            cdm_wr_address = atu_address;
            cdm_wr_data    = parity_data;

        end

    end



    assign cdm_config_rd_en      = rd_config_en;


    central_data_memory #(
        .DATA_WIDTH (CDM_DATA_W),
        .LOGICAL_ADD_W (LOGICAL_ADD_W),
        .DEPTH      (DEPTH),
        .CONFIG_DATA_W (CONFIG_DATA_W)
    ) u_central_data_memory (

        //------------------------------------------------
        // System
        //------------------------------------------------
        .i_cdm_clk          (i_system_clk),
        .i_cdm_rst_n        (system_rst_n),

        //------------------------------------------------
        // Write Interface
        //------------------------------------------------
        .i_cdm_wr_address   (cdm_wr_address),
        .i_cdm_addr_valid   (cdm_addr_valid),
        .i_cdm_wdata        (cdm_wr_data),
        .i_cdm_data_valid   (cdm_data_valid),
        .i_cdm_wr_en        (cdm_wr_en),

        //------------------------------------------------
        // Read Interface for configration data
        //------------------------------------------------
        .i_cdm_cfg_rd_en        (cdm_config_rd_en),
        .o_cdm_cfg_data      (cdm_rd_config_data),
        //------------------------------------------------
        // Read Interface for application layer
        //------------------------------------------------
        .i_cdm_app_rd_en(i_app_rd_en),
        .i_cdm_app_rd_address(i_app_rd_address),
        .o_cdm_app_rd_data(o_app_rd_data)
    );


endmodule
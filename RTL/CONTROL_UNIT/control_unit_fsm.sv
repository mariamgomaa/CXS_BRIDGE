
module control_unit_fsm (
    input  logic       i_control_unit_fsm_clk,
    input  logic       i_control_unit_fsm_rst_n,
    input  logic        i_control_unit_fsm_flit_decoder_cu_valid,
    input  logic        i_control_unit_fsm_pkt_start,
    input  logic        i_control_unit_fsm_pkt_end,
    input  logic [1:0]  i_control_unit_fsm_pkt_type,
    input  logic [7:0]  i_control_unit_fsm_device_count,
    input  logic         i_control_unit_fsm_header_valid,
    input  logic         i_control_unit_fsm_config_done,
    input  logic         i_control_unit_fsm_pkt_error,
    output logic        o_control_unit_fsm_config_address_counter,
    output logic        o_control_unit_fsm_rd_config_en,
    output logic        o_control_unit_fsm_rd_fifo_en,

    output logic        o_control_unit_fsm_config_we,
    output logic        o_control_unit_fsm_payload_valid,
    output logic        o_control_unit_fsm_status_valid,
    output logic        o_control_unit_fsm_first_cfg_tlp,
    output logic        o_control_unit_fsm_new_config_pkt,


    output logic [1:0]  o_control_unit_fsm_status_pkt_type,   // which pkt_type this status refers to ass error
    output logic [1:0]  o_control_unit_fsm_status_error_type 
);

logic write_configration_en;
logic [7:0] device_cnt_rem;
logic config_count_done;
logic pkt_end_reg;

    typedef enum logic [2:0] {
        IDLE        = 3'b000,
        CFG_SCAN    = 3'b001,     // peek/pop a config-phase word, decide what it is
        CFG_WR      = 3'b011,
        LINK_SCAN   = 3'b010, // peek/pop the link word, decide validity
        LINK_OK     = 3'b110,  // Moore: pulse status_valid for a good link word
        DATA_SCAN   = 3'b111,   // peek/pop a data-phase word, decide what it is
        DATA_BODY   = 3'b101,// Moore: pulse payload_valid for a body flit
        ERROR       = 3'b100
    } state_t;

    typedef enum logic [1:0] {
        PKT_CONFIG = 2'b00,
        PKT_LINK   = 2'b01,
        PKT_DATA   = 2'b10
    } pkt_type_t;

    state_t current_state, next_state;

 typedef enum logic [1:0] {
        ERR_NONE        = 2'b00,
        ERR_HEADER      = 2'b01,   // header_valid low / pkt_error on the header word
        ERR_TRANSACTION = 2'b10
    } error_type_t;


    // error status internal signal 
    error_type_t error_type_next;
    logic [1:0]  error_pkt_type_next;
    error_type_t error_type_reg;
    logic [1:0]  err_pkt_type_reg;
    logic data_active;
// ------
    logic [1:0] header_num;

    //========================
    // Moore output logic
    //========================
    always_comb begin
        o_control_unit_fsm_rd_config_en  = 1'b0;
        o_control_unit_fsm_rd_fifo_en    = 1'b0;
        o_control_unit_fsm_config_we     = 1'b0;
        o_control_unit_fsm_payload_valid = 1'b0;
        o_control_unit_fsm_status_valid  = 1'b0;

        o_control_unit_fsm_status_pkt_type  = 2'b00;    // for error status 
        o_control_unit_fsm_status_error_type = ERR_NONE; // for erorr  status output 

        //o_control_unit_fsm_config_address_counter = 1'b0;
        //write_configration_en = 1'b0;
        case (current_state)
            IDLE: ; // all outputs 0

            CFG_SCAN:
            begin
                o_control_unit_fsm_rd_fifo_en = 1'b1;
                //o_control_unit_fsm_config_address_counter = 1'b1;
            end
            CFG_WR:
            begin
                o_control_unit_fsm_config_we = 1'b1;
                //write_configration_en = 1'b1;
            end
            LINK_SCAN:
            begin
                o_control_unit_fsm_rd_fifo_en = 1'b1;
            end
            LINK_OK:
            begin
                o_control_unit_fsm_status_valid = 1'b1;
                o_control_unit_fsm_status_error_type = ERR_NONE;
            end
            DATA_SCAN:
            begin
                o_control_unit_fsm_rd_fifo_en   = 1'b1;
                o_control_unit_fsm_rd_config_en = 1'b1;
            end

            DATA_BODY: 
            begin
                o_control_unit_fsm_rd_config_en  = 1'b1;
                o_control_unit_fsm_payload_valid = 1'b1;
            end

            ERROR:
            begin
                o_control_unit_fsm_status_valid = 1'b1;
                o_control_unit_fsm_rd_fifo_en   = 1'b1;
                o_control_unit_fsm_status_pkt_type   = err_pkt_type_reg;
                o_control_unit_fsm_status_error_type = error_type_reg;

            end
            default:;
        endcase
    end

    //========================
    // Next-state logic
    //========================
always_comb begin
    next_state = current_state; // safe default, kills the old latch bugs
    o_control_unit_fsm_config_address_counter = 1'b0; //need in special case in scan configration
    write_configration_en = 1'b0;
    o_control_unit_fsm_new_config_pkt = 1'b0;

    error_type_next     = ERR_NONE; //status error register
    error_pkt_type_next = 2'b00;

    case (current_state)

        IDLE: 
        begin
            if (i_control_unit_fsm_flit_decoder_cu_valid)
                next_state = CFG_SCAN;
            else 
                next_state = IDLE ;
        end

        CFG_SCAN: 
        begin
            
        if (i_control_unit_fsm_flit_decoder_cu_valid)
        begin
            if (i_control_unit_fsm_pkt_start) 
            begin

                // First configuration TLP
                if (o_control_unit_fsm_first_cfg_tlp) 
                begin
                    if ((i_control_unit_fsm_pkt_type == PKT_CONFIG))
                    begin
                    if(i_control_unit_fsm_header_valid &&
                        !i_control_unit_fsm_pkt_error)
                        begin
                        next_state = CFG_WR;
                        o_control_unit_fsm_config_address_counter = 1'b1;
                        write_configration_en = 1'b1;
                        end

                    else 
                        begin
                        next_state           = ERROR;
                        error_type_next       = ERR_HEADER;   
                        error_pkt_type_next   = i_control_unit_fsm_pkt_type;
                        end
                    end

                    else
                    begin
                        next_state = ERROR;
                        error_type_next       = ERR_TRANSACTION;   
                        error_pkt_type_next   = i_control_unit_fsm_pkt_type;
                    end
                end

                    // Continuation configuration TLP
                else
                begin
                    if (i_control_unit_fsm_pkt_type == PKT_CONFIG &&!i_control_unit_fsm_pkt_error)
                    begin
                    next_state = CFG_SCAN; //THIS PACKET NOT WRITE INTO CDM
                    o_control_unit_fsm_config_address_counter = 1'b1;
                    end
                    
                    else
                    begin
                    next_state = ERROR;
                    error_type_next       = ERR_TRANSACTION;   
                    error_pkt_type_next   = i_control_unit_fsm_pkt_type;
                    end
                end
            end

            else
            begin
                o_control_unit_fsm_config_address_counter = 1'b1;
                next_state = CFG_WR;
                write_configration_en = 1'b1;
            end

        end 
        else
        next_state = CFG_SCAN;
        end

        CFG_WR:
        begin 
            if (pkt_end_reg && config_count_done) 
            begin
            next_state = LINK_SCAN ;
            end
            else
            next_state =CFG_SCAN; 

        end 

        LINK_SCAN: 
        begin
        if (i_control_unit_fsm_flit_decoder_cu_valid)
        begin
            if ( i_control_unit_fsm_pkt_type == PKT_LINK) 
            begin
                if (i_control_unit_fsm_pkt_start && i_control_unit_fsm_pkt_end)
                    next_state = LINK_OK;
                else begin
                    next_state           = ERROR;
                    error_type_next       = ERR_TRANSACTION;  
                    error_pkt_type_next   = PKT_LINK;
                end
            end
            else
            begin
                next_state = LINK_SCAN;
            end
        end
        else 
        begin
            next_state = LINK_SCAN;
        end
        end

        LINK_OK:
        begin
        next_state = DATA_SCAN;
        data_active = 'b0;
        end 

        DATA_SCAN: 
        begin
            if (i_control_unit_fsm_flit_decoder_cu_valid)
        begin
            if (i_control_unit_fsm_pkt_start)
            begin
                if (i_control_unit_fsm_pkt_type == PKT_DATA &&!i_control_unit_fsm_pkt_error)
                begin
                next_state = DATA_SCAN ;
                data_active ='b1;
                end
                else if ((i_control_unit_fsm_pkt_type == PKT_CONFIG)) //new configration packet 
                    begin
                    if(i_control_unit_fsm_header_valid &&
                        !i_control_unit_fsm_pkt_error)
                        begin
                        next_state = CFG_WR;
                        o_control_unit_fsm_config_address_counter = 1'b1;
                        write_configration_en = 1'b1;
                        o_control_unit_fsm_new_config_pkt = 1'b1;
                        end
                    end
                else 
                begin
                next_state= ERROR;
                error_type_next       = ERR_TRANSACTION;
                error_pkt_type_next   = i_control_unit_fsm_pkt_type;
                end 
            end 
            else if (data_active ==1'b1)
            begin
                next_state = DATA_BODY;
            end
            else 
            begin
                next_state = DATA_SCAN ;
            end 
        end
        else 
        begin
        next_state = DATA_SCAN ;
        end
        end

        DATA_BODY:
        begin
        next_state = DATA_SCAN ;
        end
        ERROR: //popping the bad tlp not store or use this data till end =1
        begin
            if (i_control_unit_fsm_flit_decoder_cu_valid && pkt_end_reg)
                next_state = IDLE;
            else
                next_state = ERROR;
        end

        default: next_state = IDLE;

        endcase
    end

    //========================
    // State register
    //========================
always_ff @(posedge i_control_unit_fsm_clk or negedge i_control_unit_fsm_rst_n) begin
    if (!i_control_unit_fsm_rst_n) begin
        current_state  <= IDLE;
    end
    else begin
        current_state <= next_state;
    end
end

//flip flop for device count and configration pkt count 
always_ff @(posedge i_control_unit_fsm_clk or negedge i_control_unit_fsm_rst_n) begin
    if (!i_control_unit_fsm_rst_n)
    begin
        o_control_unit_fsm_first_cfg_tlp  <= 1'b1;
        device_cnt_rem <= 'b1;
        header_num <= 'b0;
    end
    // Load from the first configuration header
    else if (current_state == CFG_SCAN &&
            i_control_unit_fsm_pkt_start &&
            o_control_unit_fsm_first_cfg_tlp&&
            i_control_unit_fsm_pkt_type == PKT_CONFIG &&
            i_control_unit_fsm_header_valid || o_control_unit_fsm_new_config_pkt)
            begin
            o_control_unit_fsm_first_cfg_tlp <= 1'b0;
            device_cnt_rem <= i_control_unit_fsm_device_count;
            header_num <= 'b0;
            end
    // One complete device region stored
    else if (write_configration_en && !i_control_unit_fsm_pkt_start && device_cnt_rem != 0)
    begin
        if (header_num == 'b0)
        begin
        header_num <= header_num + 1;
        end
        else 
        begin
        device_cnt_rem <= device_cnt_rem - 1'b1;
        end
    end
end

assign config_count_done = (device_cnt_rem == 0);



always_ff @(posedge i_control_unit_fsm_clk or negedge i_control_unit_fsm_rst_n) begin
    if (!i_control_unit_fsm_rst_n)
        pkt_end_reg <= 1'b0;
    else if (i_control_unit_fsm_flit_decoder_cu_valid) // i edit here for error handle current_state == CFG_SCAN && 
        pkt_end_reg <= i_control_unit_fsm_pkt_end;
end

always_ff @(posedge i_control_unit_fsm_clk or negedge i_control_unit_fsm_rst_n) begin
    if (!i_control_unit_fsm_rst_n) begin
        error_type_reg   <= ERR_NONE;
        err_pkt_type_reg <= 2'b00;
    end
    else if (next_state == ERROR && current_state != ERROR) begin
        error_type_reg   <= error_type_next;
        err_pkt_type_reg <= error_pkt_type_next;
    end
    else if (current_state == ERROR && next_state == IDLE) begin
        error_type_reg   <= ERR_NONE;
        err_pkt_type_reg <= 2'b00;
    end
end

endmodule

module Flit_Decoder #(
    parameter int CXSMAXPAYLOADPERFLIT = 2,
    parameter int CXSDATAFLITWIDTH     = 32,
    parameter int CNTL_W               = 3 * CXSMAXPAYLOADPERFLIT,
    parameter int FIFO_WIDTH            = CNTL_W + CXSDATAFLITWIDTH,
    parameter int PAYLOAD_W             = 16      //make it parameteized later --->**************
)(
    input  logic                   i_Flit_Decoder_clk,
    input  logic                   i_Flit_Decoder_rst_n,

    input  logic [FIFO_WIDTH-1:0]  i_Flit_Decoder_Data_in,
    input  logic                   i_Flit_Decoder_fifo_empty,

    input  logic                   i_Flit_Decoder_cu_rd_en,

    output logic                   o_Flit_Decoder_fifo_rd_en,
    output logic                   o_Flit_Decoder_cu_valid,
    output logic [PAYLOAD_W-1:0]   o_Flit_Decoder_payload,

    output logic                          o_Flit_Decoder_start_pkt,
    output logic                          o_Flit_Decoder_end_pkt,
    output logic                          o_Flit_Decoder_error_pkt
);
    localparam int  PAYLOAD_INFO_W    = FIFO_WIDTH/2  ;

    // Stores one complete FIFO entry
    logic [FIFO_WIDTH-1:0] flit_buffer_reg;
    // Indicates that the buffer contains a valid flit
    logic flit_buffer_valid_reg;
    // 0 -> payload 0
    // 1 -> payload 1
    logic payload_select_reg;
    // Indicates that a FIFO read was requested and
    // we are waiting for FIFO data_out to become valid
    logic fifo_read_pending_reg;


    //========================================================
    // FIFO Read Enable
    //========================================================

    always_comb begin

        o_Flit_Decoder_fifo_rd_en = 1'b0;
        // ---------------------------------------------------
        // Case 1:
        // Decoder buffer is empty.
        // Request a new flit from FIFO.
        // ---------------------------------------------------
        if (!flit_buffer_valid_reg &&
            !fifo_read_pending_reg &&
            !i_Flit_Decoder_fifo_empty) begin
            o_Flit_Decoder_fifo_rd_en = 1'b1;
        end
        // ---------------------------------------------------
        // Case 2:
        // Payload 1 is being consumed.
        // Request the next flit from FIFO.
        // ---------------------------------------------------
        else if (flit_buffer_valid_reg &&
                !fifo_read_pending_reg &&
                payload_select_reg &&
                i_Flit_Decoder_cu_rd_en &&
                !i_Flit_Decoder_fifo_empty) begin
            o_Flit_Decoder_fifo_rd_en = 1'b1;
        end
    end


    //========================================================
    // Payload / Valid Output
    //========================================================
    always_comb begin
        // Valid only when:
        // 1. Buffer contains valid data
        // 2. We are NOT waiting for a new FIFO read
        o_Flit_Decoder_cu_valid = flit_buffer_valid_reg &&
                                !fifo_read_pending_reg;
        // Default payload
        o_Flit_Decoder_payload = 'b0;
        o_Flit_Decoder_start_pkt = 1'b0;
        o_Flit_Decoder_end_pkt = 1'b0;
        o_Flit_Decoder_error_pkt = 1'b0;

        if (flit_buffer_valid_reg &&
            !fifo_read_pending_reg) begin
            // Payload 0
            if (payload_select_reg == 1'b0) begin
                o_Flit_Decoder_payload =
                    flit_buffer_reg[
                        FIFO_WIDTH-4 : PAYLOAD_INFO_W
                    ];
                    o_Flit_Decoder_start_pkt = flit_buffer_reg[FIFO_WIDTH-1];
                    o_Flit_Decoder_end_pkt = flit_buffer_reg[FIFO_WIDTH-2];
                    o_Flit_Decoder_error_pkt = flit_buffer_reg[FIFO_WIDTH-3];
            end
            // Payload 1
            else begin
                o_Flit_Decoder_payload =
                    flit_buffer_reg[
                        PAYLOAD_INFO_W-4 : 0
                    ];
                    o_Flit_Decoder_start_pkt = flit_buffer_reg[PAYLOAD_INFO_W-1];
                    o_Flit_Decoder_end_pkt = flit_buffer_reg[PAYLOAD_INFO_W-2];
                    o_Flit_Decoder_error_pkt = flit_buffer_reg[PAYLOAD_INFO_W-3];
            end
        end
    end


    //========================================================
    // Buffer Control
    //========================================================

    always_ff @(posedge i_Flit_Decoder_clk or
                negedge i_Flit_Decoder_rst_n) begin
        if (!i_Flit_Decoder_rst_n) begin
            flit_buffer_reg       <= '0;
            flit_buffer_valid_reg <= 1'b0;
            payload_select_reg    <= 1'b0;
            fifo_read_pending_reg <= 1'b0;
        end
        else begin
            //================================================
            // CASE 1:
            // A FIFO read was requested in the previous cycle.
            //
            // The FIFO has registered data_out, so its new
            // data is available now.
            //================================================
            if (fifo_read_pending_reg) begin
                flit_buffer_reg <= i_Flit_Decoder_Data_in;
                flit_buffer_valid_reg <= 1'b1;
                // Start from payload 0
                payload_select_reg <= 1'b0;
                // Read operation completed
                fifo_read_pending_reg <= 1'b0;
            end
            //================================================
            // CASE 2:
            // A FIFO read is being requested now.
            //
            // Do NOT capture Data_in yet.
            // Capture it on the next clock.
            //================================================
            else if (o_Flit_Decoder_fifo_rd_en) begin
                fifo_read_pending_reg <= 1'b1;
                // Current buffer is not valid while waiting
                // for the new FIFO data.
                flit_buffer_valid_reg <= 1'b0;
            end
            //================================================
            // CASE 3:
            // CU consumes the current payload.
            //================================================
            else if (flit_buffer_valid_reg &&
                    i_Flit_Decoder_cu_rd_en) begin
                // -------------------------------------------
                // Payload 0 consumed
                // -------------------------------------------
                if (payload_select_reg == 1'b0) begin
                    // Payload 1 is already in the buffer.
                    // Move to payload 1.
                    payload_select_reg <= 1'b1;
                end
                // -------------------------------------------
                // Payload 1 consumed
                // -------------------------------------------
                else begin
                    // If FIFO contains another flit,
                    // o_Flit_Decoder_fifo_rd_en will be
                    // asserted combinationally.
                    //
                    // The actual FIFO data will be captured
                    // in the next cycle.
                    if (!i_Flit_Decoder_fifo_empty) begin
                        flit_buffer_valid_reg <= 1'b0;
                    end
                    else begin
                        // No more flits
                        flit_buffer_valid_reg <= 1'b0;
                        payload_select_reg    <= 1'b0;
                    end
                end
            end
        end
    end
endmodule
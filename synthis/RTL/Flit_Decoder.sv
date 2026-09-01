module Flit_Decoder #(
    parameter int CXSMAXPAYLOADPERFLIT = 2,
    parameter int CXSDATAFLITWIDTH     = 32,
    parameter int CNTL_W               = 3 * CXSMAXPAYLOADPERFLIT,
    parameter int FIFO_WIDTH            = CNTL_W + CXSDATAFLITWIDTH,
    parameter int PAYLOAD_W             = 16
)(
    input  logic                   i_Flit_Decoder_clk,
    input  logic                   i_Flit_Decoder_rst_n,

    input  logic [FIFO_WIDTH-1:0]  i_Flit_Decoder_Data_in,
    input  logic                  i_Flit_Decoder_fifo_empty,

    input  logic                   i_Flit_Decoder_cu_rd_en,

    output logic                  o_Flit_Decoder_fifo_rd_en,
    output logic                  o_Flit_Decoder_cu_valid,
    output logic [PAYLOAD_W-1:0]  o_Flit_Decoder_payload,

    output logic                  o_Flit_Decoder_start_pkt,
    output logic                  o_Flit_Decoder_end_pkt,
    output logic                  o_Flit_Decoder_error_pkt
);

    //========================================================
    // Parameters
    //========================================================

    localparam int PAYLOAD_INFO_W = FIFO_WIDTH / 2;


    //========================================================
    // Current State / Registers
    //========================================================

    // Stores one complete FIFO entry
    logic [FIFO_WIDTH-1:0] flit_buffer_reg;

    // Indicates that the buffer contains a valid flit
    logic flit_buffer_valid_reg;

    // 0 -> Payload 0
    // 1 -> Payload 1
    logic payload_select_reg;

    // Indicates that a FIFO read was requested and
    // we are waiting for FIFO data_out to become valid
    logic fifo_read_pending_reg;


    //========================================================
    // Next-State Signals
    //========================================================

    logic [FIFO_WIDTH-1:0] flit_buffer_next;

    logic flit_buffer_valid_next;

    logic payload_select_next;

    logic fifo_read_pending_next;


    //========================================================
    // Internal FIFO Read Request
    //========================================================

    logic fifo_rd_req;

    always_comb begin

        fifo_rd_req = 1'b0;
        if (!flit_buffer_valid_reg &&
            !fifo_read_pending_reg &&
            !i_Flit_Decoder_fifo_empty) begin

            fifo_rd_req = 1'b1;
        end
        else if (flit_buffer_valid_reg &&
                 !fifo_read_pending_reg &&
                 payload_select_reg &&
                 i_Flit_Decoder_cu_rd_en &&
                 !i_Flit_Decoder_fifo_empty) begin

            fifo_rd_req = 1'b1;
        end

    end

    assign o_Flit_Decoder_fifo_rd_en = fifo_rd_req;

    always_comb begin

        //====================================================
        // Default outputs
        //====================================================

        o_Flit_Decoder_cu_valid     = 1'b0;
        o_Flit_Decoder_payload      = '0;
        o_Flit_Decoder_start_pkt    = 1'b0;
        o_Flit_Decoder_end_pkt      = 1'b0;
        o_Flit_Decoder_error_pkt    = 1'b0;


        //====================================================
        // Valid data available to Control Unit
        //====================================================

        if (flit_buffer_valid_reg &&
            !fifo_read_pending_reg) begin

            o_Flit_Decoder_cu_valid = 1'b1;

            //================================================
            // Payload 0
            //================================================

            if (!payload_select_reg) begin

                o_Flit_Decoder_payload =
                    flit_buffer_reg[
                        FIFO_WIDTH-4 : PAYLOAD_INFO_W
                    ];

                o_Flit_Decoder_start_pkt =
                    flit_buffer_reg[FIFO_WIDTH-1];

                o_Flit_Decoder_end_pkt =
                    flit_buffer_reg[FIFO_WIDTH-2];

                o_Flit_Decoder_error_pkt =
                    flit_buffer_reg[FIFO_WIDTH-3];
            end

            //================================================
            // Payload 1
            //================================================

            else begin

                o_Flit_Decoder_payload =
                    flit_buffer_reg[
                        PAYLOAD_INFO_W-4 : 0
                    ];

                o_Flit_Decoder_start_pkt =
                    flit_buffer_reg[PAYLOAD_INFO_W-1];

                o_Flit_Decoder_end_pkt =
                    flit_buffer_reg[PAYLOAD_INFO_W-2];

                o_Flit_Decoder_error_pkt =
                    flit_buffer_reg[PAYLOAD_INFO_W-3];
            end

        end

    end

    always_comb begin


        flit_buffer_next       = flit_buffer_reg;
        flit_buffer_valid_next = flit_buffer_valid_reg;
        payload_select_next    = payload_select_reg;
        fifo_read_pending_next = fifo_read_pending_reg;

        if (fifo_read_pending_reg) begin

            flit_buffer_next =
                i_Flit_Decoder_Data_in;

            flit_buffer_valid_next = 1'b1;

            // Every new flit starts with Payload 0
            payload_select_next = 1'b0;

            // FIFO read has completed
            fifo_read_pending_next = 1'b0;

        end
        else if (fifo_rd_req) begin

            fifo_read_pending_next = 1'b1;

            // Current buffer is no longer presented
            // while waiting for the new FIFO data.
            flit_buffer_valid_next = 1'b0;

        end
        else if (flit_buffer_valid_reg &&
                 i_Flit_Decoder_cu_rd_en) begin


            //================================================
            // Payload 0 consumed
            //================================================

            if (!payload_select_reg) begin

                // Payload 1 is already stored in the buffer.
                //
                // Move to Payload 1.
                payload_select_next = 1'b1;

            end


            //================================================
            // Payload 1 consumed
            //================================================

            else begin

                // The current flit has been completely consumed.
                flit_buffer_valid_next = 1'b0;

                // Next flit, when loaded, starts at Payload 0.
                payload_select_next = 1'b0;

            end

        end

    end
    always_ff @(posedge i_Flit_Decoder_clk or
                negedge i_Flit_Decoder_rst_n) begin

        if (!i_Flit_Decoder_rst_n) begin

            flit_buffer_reg       <= '0;
            flit_buffer_valid_reg <= 1'b0;
            payload_select_reg    <= 1'b0;
            fifo_read_pending_reg <= 1'b0;

        end

        else begin

            flit_buffer_reg       <= flit_buffer_next;
            flit_buffer_valid_reg <= flit_buffer_valid_next;
            payload_select_reg    <= payload_select_next;
            fifo_read_pending_reg <= fifo_read_pending_next;

        end

    end

endmodule
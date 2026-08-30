`timescale 1ns/1ps

module CXS_SYSTEM_TOP_TB;
    //--------------------------------------------------
    // Parameters
    //--------------------------------------------------
    parameter int CXSMAXPAYLOADPERFLIT = 2;
    parameter int CXSDATAFLITWIDTH     = 32;
    parameter int FIFO_DEPTH           = 16;
    parameter int MAX_CREDITS          = 15;
    parameter int PAYLOAD_W            = 16;
    parameter int ADDR_W               = 8;
    parameter int DATA_W               = 8;
    localparam int CNTL_W        = 3 * CXSMAXPAYLOADPERFLIT;
    localparam int ENCRYPTED_W   = 2 * DATA_W;
    localparam int CDM_DATA_W    = ENCRYPTED_W + 1;
    //--------------------------------------------------
    // Clock and Reset
    //--------------------------------------------------
    logic i_cxs_clk;
    logic i_rst_n;
    logic i_system_clk;
    //--------------------------------------------------
    // CXS Interface Inputs
    //--------------------------------------------------
    logic [CXSDATAFLITWIDTH-1:0] i_cxsdata;
    logic [CNTL_W-1:0]           i_cxscntl;

    logic i_cxsvalid;
    logic i_cxsactivereq;
    logic i_cxscrdrtn;
    logic  i_cxs_cxscrdgnt;
    logic i_cxs_cxsactiveack;
    //--------------------------------------------------
    // DUT Outputs
    //--------------------------------------------------
    logic                       o_cxscrdgnt;
    logic                       o_cxsactiveack;
    logic                       o_CXSVALID;
    logic                       o_CXSACTIVEREQ;
    logic[CXSDATAFLITWIDTH-1:0] o_CXSDATA;
    logic[CNTL_W-1:0]           o_CXSCNTL;
    logic                     i_app_rd_en;
    logic [8:0]        i_app_rd_address;
    logic [CDM_DATA_W-1:0]    o_app_rd_data;
    logic i_app_ack;
    //--------------------------------------------------
    // DUT
    //--------------------------------------------------
    CXS_SYSTEM_TOP #(
        .CXSMAXPAYLOADPERFLIT (CXSMAXPAYLOADPERFLIT),
        .CXSDATAFLITWIDTH     (CXSDATAFLITWIDTH),
        .FIFO_DEPTH            (FIFO_DEPTH),
        .MAX_CREDITS           (MAX_CREDITS),
        .PAYLOAD_W             (PAYLOAD_W),
        .ADDR_W                (ADDR_W),
        .DATA_W                (DATA_W)
    )
    DUT
    (
        //--------------------------------------------------
        // CXS RX Clock Domain
        //--------------------------------------------------
        .i_cxs_clk       (i_cxs_clk),
        .i_rst_n     (i_rst_n),
        //--------------------------------------------------
        // CXS Interface
        //--------------------------------------------------
        .i_cxsdata          (i_cxsdata),
        .i_cxscntl          (i_cxscntl),
        .i_cxsvalid         (i_cxsvalid),
        .i_cxsactivereq     (i_cxsactivereq),
        .i_cxscrdrtn        (i_cxscrdrtn),
        .i_cxs_cxsactiveack  (i_cxs_cxsactiveack),
        .i_cxs_cxscrdgnt     (i_cxs_cxscrdgnt),
        //--------------------------------------------------
        // System Clock Domain
        //--------------------------------------------------
        .i_system_clk       (i_system_clk),
        .i_app_rd_en(i_app_rd_en),
        .i_app_rd_address(i_app_rd_address),
        .i_app_ack (i_app_ack),
        //--------------------------------------------------
        // Outputs
        //--------------------------------------------------
        .o_cxscrdgnt        (o_cxscrdgnt),
        .o_cxsactiveack     (o_cxsactiveack),
        .o_CXSVALID     (o_CXSVALID),
        .o_CXSDATA      (o_CXSDATA),
        .o_CXSCNTL   (o_CXSCNTL),
        .o_CXSACTIVEREQ  (o_CXSACTIVEREQ),
        .o_app_rd_data(o_app_rd_data)
    );
    //==================================================
    // Clock Generation
    //==================================================
    // CXS Clock
    initial i_cxs_clk = 1'b0;
    always #5 i_cxs_clk = ~i_cxs_clk;
    // System Clock
    initial i_system_clk = 1'b0;
    always #7 i_system_clk = ~i_system_clk;
integer report_fd;
initial begin
    report_fd = $fopen("sim_report.txt", "w");
    if (report_fd == 0) begin
        $display("ERROR: could not open sim_report.txt");
        $finish;
    end
    $fmonitor(report_fd,
        "T=%0t | ACT_REQ=%b ACT_ACK=%b | VALID=%b DATA=%h CNTL=%b | CRDGNT=%b \n || FSM: cur=%s nxt=%s | BUF_REL=%b ||\n CU_IN: addr=%h data=%h cfg_addr=%h cfg_data=%h | CU_EN: rd_fifo=%b rd_cfg=%b cfg_we=%b payload_v=%b status_v=%b | MODE: addr_mode=%b enc_mode=%b parity_mode=%b \n",
        $time,
        i_cxsactivereq, o_cxsactiveack,
        i_cxsvalid, i_cxsdata, i_cxscntl,
        o_cxscrdgnt,
        DUT.u_control_unit.u_fsm.current_state.name(),
        DUT.u_control_unit.u_fsm.next_state.name(),
        DUT.u_async_fifo.o_Asynch_FIFO_buf_release,
        DUT.u_control_unit.o_control_unit_address,
        DUT.u_control_unit.o_control_unit_data,
        DUT.u_control_unit.o_control_unit_config_address,
        DUT.u_control_unit.o_control_unit_config_data,
        DUT.u_control_unit.o_control_unit_rd_fifo_en,
        DUT.u_control_unit.o_control_unit_rd_config_en,
        DUT.u_control_unit.o_control_unit_config_we,
        DUT.u_control_unit.o_control_unit_payload_valid,
        DUT.u_control_unit.o_control_unit_status_valid,
        DUT.u_control_unit.o_control_unit_addr_mode,
        DUT.u_control_unit.o_control_unit_enc_mode,
        DUT.u_control_unit.o_control_unit_parity_mode
    );
end
final begin
    $fclose(report_fd);
end
    //==================================================
    // Reset Task
    //==================================================
    task reset;
        begin
            i_rst_n = 1'b0;
            i_cxsdata      = '0;
            i_cxscntl      = '0;
            i_cxsvalid     = 1'b0;
            i_cxsactivereq = 1'b0;
            i_cxscrdrtn    = 1'b0;
            i_cxs_cxscrdgnt    = 1'b0;
            i_cxs_cxsactiveack = 1'b0;
            i_app_ack = 1'b0;
        i_app_rd_en = 1'b0;
        i_app_rd_address = '0;
            repeat(3) @(posedge i_cxs_clk);
            i_rst_n = 1'b1;
            @(posedge i_cxs_clk);
        end
    endtask
    //==================================================
    // Activate CXS Link RX
    //==================================================
    task activate_link;
        begin
            @(negedge i_cxs_clk);
            i_cxsactivereq = 1'b1;
            // Keep request asserted until FSM responds
            wait(o_cxsactiveack == 1'b1);
            // Give link controller time to stabilize
            repeat(2) @(posedge i_cxs_clk);
        end
    endtask
    task automatic rx_activeack_respond(input int delay_cycles = 2);
        begin
            wait (o_CXSACTIVEREQ == 1'b1);
            repeat (delay_cycles) @(posedge i_cxs_clk);
            i_cxs_cxsactiveack = 1'b1;
            $display("[%0t] RX MODEL: CXSACTIVEACK asserted", $time);
        end
    endtask

    //--------------------------------------------------
    // One-shot: drop ACK (models receiver deactivating
    // the link, or simply the response to REQ falling).
    //--------------------------------------------------
    task automatic rx_activeack_deassert();
        begin
            @(negedge i_cxs_clk);
            i_cxs_cxsactiveack = 1'b0;
            $display("[%0t] RX MODEL: CXSACTIVEACK deasserted", $time);
        end
    endtask

    //--------------------------------------------------
    // Grant N credits: one CXSCRDGNT pulse per credit,
    // with gap_cycles idle cycles between pulses.
    //--------------------------------------------------
    task automatic rx_grant_credits(input int num_credits, input int gap_cycles = 1);
        integer i;
        begin
            for (i = 0; i < num_credits; i = i + 1) begin
                @(negedge i_cxs_clk);
                i_cxs_cxscrdgnt = 1'b1;
                @(posedge i_cxs_clk);
                @(negedge i_cxs_clk);
                i_cxs_cxscrdgnt = 1'b0;
                repeat (gap_cycles) @(posedge i_cxs_clk);
            end
            $display("[%0t] RX MODEL: granted %0d credit(s)", $time, num_credits);
        end
    endtask

    //--------------------------------------------------
    // Explicitly withhold credits (no grants) for a
    // fixed number of cycles - useful to test TX stall
    // behavior when the credit counter hits zero.
    //--------------------------------------------------
    task automatic rx_withhold_credits(input int cycles);
        begin
            i_cxs_cxscrdgnt = 1'b0;
            repeat (cycles) @(posedge i_cxs_clk);
            $display("[%0t] RX MODEL: withheld credits for %0d cycle(s)", $time, cycles);
        end
    endtask


    task automatic rx_model_run(input int initial_credits = 8);
        begin
            fork
                begin : rx_ack_proc
                    forever begin
                        wait (o_CXSACTIVEREQ == 1'b1);
                        repeat (2) @(posedge i_cxs_clk);
                        i_cxs_cxsactiveack = 1'b1;
                        wait (o_CXSACTIVEREQ == 1'b0);
                        @(negedge i_cxs_clk);
                        i_cxs_cxsactiveack = 1'b0;
                    end
                end
                begin : rx_credit_proc
                    rx_grant_credits(initial_credits, 1);
                end
            join_none
        end
    endtask

task automatic app_check_cdm_and_ack(
    input logic [8:0] addr,
    input logic [CDM_DATA_W-1:0] expected_data
);
begin
    wait (DUT.u_control_unit.u_fsm.current_state == 4'b0111);
    i_app_rd_address = addr;
    i_app_rd_en      = 1'b1;
    @(negedge i_system_clk);
    i_app_rd_en      = 1'b0;
    if (o_app_rd_data == expected_data)
    begin
        $display("[%0t] APP: CDM check PASSED. addr=%h data=%h",
                $time, addr, o_app_rd_data);
        // ACK only after successful CDM check
        @(negedge i_system_clk);
        i_app_ack = 1'b1;
        // Keep ACK high for one system clock
        @(negedge i_system_clk);
        i_app_ack = 1'b0;
        $display("[%0t] APP: ACK asserted", $time);
    end
    else
    begin
        $display("[%0t] APP: CDM check FAILED. addr=%h expected=%h actual=%h",
                $time, addr, expected_data, o_app_rd_data);
        i_app_ack = 1'b0;
    end

end
endtask
    //==================================================
    // Send One CXS Flit
    //
    // One flit contains two 16-bit payloads:
    //
    // i_cxsdata[15:0]  -> Payload 0
    // i_cxsdata[31:16] -> Payload 1
    //
    // CNTL assumption:
    //
    // {start0,end0,error0,start1,end1,error1}
    //
    // If your CXSCNTL decoder uses another bit order,
    // change only the CNTL format here.
    //==================================================
    task send_flit;
        input logic [15:0] payload0;
        input logic [15:0] payload1;
        input logic start0;
        input logic start1;
        input logic end0;
        input logic end1;
        input logic error0;
        input logic error1;
        begin
            @(negedge i_cxs_clk);
            i_cxsdata = {
                payload1,
                payload0
            };
            i_cxscntl = {
                error1,
                error0,
                start1,
                end1,
                end0,
                start1,
                start0
                
            };
            i_cxsvalid = 1'b1;
            @(posedge i_cxs_clk);
            i_cxsvalid = 1'b0;
            i_cxsdata  = '0;
            i_cxscntl  = '0;
        end
    endtask


    //==================================================
    // Header Formation
    //
    // Same format used in your Control Unit TB:
    //
    // [15]    addr_mode
    // [14:7]  device_count
    // [6:4]   encryption_mode
    // [3:2]   parity_mode
    // [1:0]   pkt_type
    //==================================================
    function automatic logic [15:0] header_form(
        input logic       address_mode,
        input logic [7:0] device_count,
        input logic [2:0] encryption_mode,
        input logic [1:0] parity,
        input logic [1:0] pkt_type
    );
        begin
            header_form = {
                address_mode,
                device_count,
                encryption_mode,
                parity,
                pkt_type
            };
        end
    endfunction
    //==================================================
    // Main Stimulus
    //==================================================
    initial begin
                reset();
        //--------------------------------------------------
        // Activate CXS Link (RX direction, as before)
        //--------------------------------------------------
        activate_link();
        //--------------------------------------------------
        // Start the receiver model for the TX path. From
        // here on, ACTIVEREQ auto-ACKs and there's a pool
        // of 8 credits available to the transmitter.
        //--------------------------------------------------
        rx_model_run(8);

        $display ("============================================================================");
        $display("test 1 send wrong configration packet device count error");
        $display ("============================================================================");

        send_flit(
            //------------------------------------------------
            // Payload 0 = Header
            //------------------------------------------------
            header_form(
                1'b1,       // address_mode
                8'd0,       // device_count
                3'b001,     // encryption mode
                2'b01,      // parity mode
                2'b00       // CONFIG packet
            ),
            //------------------------------------------------
            // Payload 1 = First Configuration Data
            //------------------------------------------------
            16'h1111,
            //------------------------------------------------
            // Payload 0 Control
            //------------------------------------------------
            1'b1,           // start0
            1'b0,           // start0
            1'b0,           // end0
            //------------------------------------------------
            // Payload 1 Control
            //------------------------------------------------
            1'b0,           // end1
            1'b0,           // error0
            1'b0            // error1
        );
        send_flit(
            16'h2222,
            16'h3333,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            1'b0
        );
        send_flit(
            16'h4444,
            header_form(
                1'b0,
                8'd0,
                3'b00,
                2'b00,
                2'b00
            ),
            1'b0,
            1'b1,       
            1'b1,//end of tlp 64 bit on two flit each flit 32 bit
            1'b0,
            1'b0,
            1'b0
        );
        @(posedge i_system_clk);

        $display ("============================================================================");
        $display("test 2 send correct configration packet with continous two configration packet");
        $display ("============================================================================");

        send_flit(
            //------------------------------------------------
            // Payload 0 = Header
            //------------------------------------------------
            header_form(
                1'b1,       // address_mode
                8'd5,       // device_count
                3'b001,     // encryption mode
                2'b01,      // parity mode
                2'b00       // CONFIG packet
            ),
            //------------------------------------------------
            // Payload 1 = First Configuration Data that has base address
            //------------------------------------------------
            16'h000A,//let set base address 10
            //------------------------------------------------
            // Payload 0 Control
            //------------------------------------------------
            1'b1,           // start0
            1'b0,           // start0
            1'b0,           // end0
            //------------------------------------------------
            // Payload 1 Control
            //------------------------------------------------
            1'b0,           // end1
            1'b0,           // error0
            1'b0            // error1
        );
        //--------------------------------------------------
        // Continue Configuration Data
        //--------------------------------------------------
        send_flit(
            16'h1111,
            16'h2222,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            1'b0
        );
        //--------------------------------------------------
        // Last Configuration Word in first configration tlp
        //--------------------------------------------------
        send_flit(
            16'h3333,
            16'h4444,
            1'b0,
            1'b0,       
            1'b1,//end of tlp 64 bit on two flit each flit 32 bit
            1'b0,
            1'b0,
            1'b0
        );
        send_flit(
            //------------------------------------------------
            // Configuration Word
            //------------------------------------------------
        header_form(
                1'b0,
                8'd0,
                3'b00,
                2'b00,
                2'b00 //configration packet
            ),
            16'h5555,
            //------------------------------------------------
            // Header Control
            //------------------------------------------------
            1'b1,
            1'b0,
            1'b0, 
            //------------------------------------------------
            // Data Control
            //------------------------------------------------
            1'b1,
            1'b0,
            1'b0
        );

        $display ("============================================================================");
        $display("test 3 send link packet ");
        $display ("============================================================================");
        send_flit(
            //------------------------------------------------
            // Configuration Word
            //------------------------------------------------
            header_form(
                1'b0,
                8'd0,
                3'b00,
                2'b00,
                2'b01
            ),
            16'h0A88, //  1000 1000 --> 1 1110 1010 1110 1010
            //------------------------------------------------
            // Header Control
            //------------------------------------------------
            1'b1,
            1'b0,
            1'b0, 
            //------------------------------------------------
            // Data Control
            //------------------------------------------------
            1'b1,
            1'b0,
            1'b0
        );
        fork
        app_check_cdm_and_ack(
        9'b111,
        17'b11101010111010101
            );
        join_none
        
        $display ("============================================================================");
        $display("test 4 send data packet tlp has 6 payload ");
        $display ("============================================================================");
                send_flit(
            //------------------------------------------------
            // Configuration Word
            //------------------------------------------------
            header_form(
                1'b0,
                8'd0,
                3'b00,
                2'b00,
                2'b10
            ),
            16'h0AAA, // address 0000 0001       data  AA 1010 1010 --> 10011001100110010 
            //------------------------------------------------
            // Header Control
            //------------------------------------------------
            1'b1,
            1'b0,
            1'b0, 
            //------------------------------------------------
            // Data Control
            //------------------------------------------------
            1'b0,
            1'b0,
            1'b0
        );
                send_flit(
            //------------------------------------------------
            // Configuration Word
            //------------------------------------------------
            16'h0BBB,// address 0000 0002       data  BB
            16'h0CCC,// address 0000 0003       data  CC
            //------------------------------------------------
            // Header Control
            //------------------------------------------------
            1'b0,
            1'b0,
            1'b0, 
            //------------------------------------------------
            // Data Control
            //------------------------------------------------
            1'b0,
            1'b0,
            1'b0
        );
                send_flit(
            //------------------------------------------------
            // Configuration Word
            //------------------------------------------------
            16'h0DDD,// address 0000 0004       data  DD
            16'h0EEE,// address 0000 0002       data  BB
            //------------------------------------------------
            // Header Control
            //------------------------------------------------
            1'b0,
            1'b0,
            1'b0, 
            //------------------------------------------------
            // Data Control
            //------------------------------------------------
            1'b1,
            1'b0,
            1'b0
        );
            send_flit(
            //------------------------------------------------
            // Configuration Word
            //------------------------------------------------
                        header_form(
                1'b0,
                8'd0,
                3'b00,
                2'b00,
                2'b10
            ), //53  continous data packet
            16'h0FFF,// address 0000 0003       data  CC
            //------------------------------------------------
            // Header Control
            //------------------------------------------------
            1'b1,
            1'b0,
            1'b0, 
            //------------------------------------------------
            // Data Control
            //------------------------------------------------
            1'b0,
            1'b0,
            1'b0
        );
                send_flit(
            //------------------------------------------------
            // Configuration Word
            //------------------------------------------------
            16'h1012,// address 0000 0004       data  DD
            16'h2034,
            //------------------------------------------------
            // Header Control
            //------------------------------------------------
            1'b0,
            1'b0,
            1'b0, 
            //------------------------------------------------
            // Data Control
            //------------------------------------------------
            1'b1,
            1'b0,
            1'b0
        );
                    send_flit(
            //------------------------------------------------
            // Configuration Word
            //------------------------------------------------
                        header_form(
                1'b1,
                8'd3,
                3'b01,
                2'b01,
                2'b00
            ), //new configration pkt
            16'h000A,// base address 10 
            //------------------------------------------------
            // Header Control
            //------------------------------------------------
            1'b1,
            1'b0,
            1'b0, 
            //------------------------------------------------
            // Data Control
            //------------------------------------------------
            1'b0,
            1'b0,
            1'b0
        );
        send_flit(
            //------------------------------------------------
            // Configuration Word
            //------------------------------------------------
            16'h7777,
            16'h8888,
            //------------------------------------------------
            // Header Control
            //------------------------------------------------
            1'b0,
            1'b0,
            1'b0, 
            //------------------------------------------------
            // Data Control
            //------------------------------------------------
            1'b1,
            1'b0,
            1'b0
        );

        $display ("============================================================================");
        $display("test 5 TX starvation: withhold credits then release");
        $display ("============================================================================");
        //--------------------------------------------------
        // Example of directly driving the receiver model
        // instead of the background rx_model_run() pool:
        // stall the TX by withholding credits, then grant
        // a fresh batch and watch the TX resume.
        //--------------------------------------------------
        rx_withhold_credits(20);
        rx_grant_credits(4, 2);

         #1000;
        $stop;

    end


    //==================================================
    // VCD Dump
    //==================================================
    initial begin

        $dumpfile("CXS_SYSTEM_TOP_TB.vcd");
        $dumpvars(0, CXS_SYSTEM_TOP_TB);

    end

wire [37:0] i_Asynch_FIFO_data_in;
assign i_Asynch_FIFO_data_in = {
    DUT.u_async_fifo.i_Asynch_FIFO_data_in[15:0],
    DUT.u_async_fifo.i_Asynch_FIFO_data_in[34:19],
        2'b00,
    DUT.u_async_fifo.i_Asynch_FIFO_data_in[16],
    DUT.u_async_fifo.i_Asynch_FIFO_data_in[35],
    DUT.u_async_fifo.i_Asynch_FIFO_data_in[17],
    DUT.u_async_fifo.i_Asynch_FIFO_data_in[36],
    DUT.u_async_fifo.i_Asynch_FIFO_data_in[18],
    DUT.u_async_fifo.i_Asynch_FIFO_data_in[37]

};
wire [39:0] o_CXS_TOP_DATA;
assign o_CXS_TOP_DATA = {
    DUT.u_CXS_TOP.o_CXS_TOP_DATA[15:0],
    DUT.u_CXS_TOP.o_CXS_TOP_DATA[34:19],
        2'b00,
    DUT.u_CXS_TOP.o_CXS_TOP_DATA[16],
    DUT.u_CXS_TOP.o_CXS_TOP_DATA[35],
    DUT.u_CXS_TOP.o_CXS_TOP_DATA[17],
    DUT.u_CXS_TOP.o_CXS_TOP_DATA[36],
    DUT.u_CXS_TOP.o_CXS_TOP_DATA[18],
    DUT.u_CXS_TOP.o_CXS_TOP_DATA[37]

};
wire [39:0] o_Asynch_FIFO_data_out;
assign o_Asynch_FIFO_data_out = {
    DUT.u_async_fifo.o_Asynch_FIFO_data_out[15:0],
    DUT.u_async_fifo.o_Asynch_FIFO_data_out[34:19],
        2'b00,

    DUT.u_async_fifo.o_Asynch_FIFO_data_out[16],
    DUT.u_async_fifo.o_Asynch_FIFO_data_out[35],
    DUT.u_async_fifo.o_Asynch_FIFO_data_out[17],
    DUT.u_async_fifo.o_Asynch_FIFO_data_out[36],
    DUT.u_async_fifo.o_Asynch_FIFO_data_out[18],
    DUT.u_async_fifo.o_Asynch_FIFO_data_out[37]

};
wire [39:0] i_Flit_Decoder_Data_in;
assign i_Flit_Decoder_Data_in = {
    DUT.u_flit_decoder.i_Flit_Decoder_Data_in[15:0],
    DUT.u_flit_decoder.i_Flit_Decoder_Data_in[34:19],
        2'b00,

    DUT.u_flit_decoder.i_Flit_Decoder_Data_in[16],
    DUT.u_flit_decoder.i_Flit_Decoder_Data_in[35],
    DUT.u_flit_decoder.i_Flit_Decoder_Data_in[17],
    DUT.u_flit_decoder.i_Flit_Decoder_Data_in[36],
    DUT.u_flit_decoder.i_Flit_Decoder_Data_in[18],
    DUT.u_flit_decoder.i_Flit_Decoder_Data_in[37]
};


endmodule
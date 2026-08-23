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
    logic i_cxs_rx_clk;
    logic i_cxs_rx_rst_n;

    logic i_system_clk;
    logic i_system_rst_n;


    //--------------------------------------------------
    // CXS Interface Inputs
    //--------------------------------------------------
    logic [CXSDATAFLITWIDTH-1:0] i_cxsdata;
    logic [CNTL_W-1:0]           i_cxscntl;

    logic i_cxsvalid;
    logic i_cxsactivereq;
    logic i_cxscrdrtn;


    //--------------------------------------------------
    // DUT Outputs
    //--------------------------------------------------
    logic                       o_cxscrdgnt;
    logic                       o_cxsactiveack;

    logic                       o_cdm_rd_valid;
    logic [CDM_DATA_W-1:0]      o_cdm_rd_data;

    logic                       o_cdm_write_done;
    logic                       o_cdm_write_error;
    logic  [1:0]               o_status_pkt_type;
    logic  [1:0]               o_status_error_type;
    logic                      o_status_valid;



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
        .i_cxs_rx_clk       (i_cxs_rx_clk),
        .i_cxs_rx_rst_n     (i_cxs_rx_rst_n),

        //--------------------------------------------------
        // CXS Interface
        //--------------------------------------------------
        .i_cxsdata          (i_cxsdata),
        .i_cxscntl          (i_cxscntl),
        .i_cxsvalid         (i_cxsvalid),
        .i_cxsactivereq     (i_cxsactivereq),
        .i_cxscrdrtn        (i_cxscrdrtn),

        //--------------------------------------------------
        // System Clock Domain
        //--------------------------------------------------
        .i_system_clk       (i_system_clk),
        .i_system_rst_n     (i_system_rst_n),

        //--------------------------------------------------
        // Outputs
        //--------------------------------------------------
        .o_cxscrdgnt        (o_cxscrdgnt),
        .o_cxsactiveack     (o_cxsactiveack),

        .o_cdm_rd_valid     (o_cdm_rd_valid),
        .o_cdm_rd_data      (o_cdm_rd_data),

        .o_cdm_write_done   (o_cdm_write_done),
        .o_cdm_write_error  (o_cdm_write_error),
        .o_status_valid      (o_status_valid),
        .o_status_pkt_type   (o_status_pkt_type),
        .o_status_error_type(o_status_error_type)
    );


    //==================================================
    // Clock Generation
    //==================================================

    // CXS Clock
    initial i_cxs_rx_clk = 1'b0;
    always #5 i_cxs_rx_clk = ~i_cxs_rx_clk;


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
        "T=%0t | ACT_REQ=%b ACT_ACK=%b | VALID=%b DATA=%h CNTL=%b | CRDGNT=%b | CDM_WR_DONE=%b CDM_RD_VALID=%b \n || FSM: cur=%s nxt=%s | BUF_REL=%b ||\n CU_IN: addr=%h data=%h cfg_addr=%h cfg_data=%h | CU_EN: rd_fifo=%b rd_cfg=%b cfg_we=%b payload_v=%b status_v=%b | MODE: addr_mode=%b enc_mode=%b parity_mode=%b \n",
        $time,
        i_cxsactivereq, o_cxsactiveack,
        i_cxsvalid, i_cxsdata, i_cxscntl,
        o_cxscrdgnt, o_cdm_write_done, o_cdm_rd_valid,
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

            i_cxs_rx_rst_n = 1'b0;
            i_system_rst_n = 1'b0;

            i_cxsdata      = '0;
            i_cxscntl      = '0;
            i_cxsvalid     = 1'b0;

            i_cxsactivereq = 1'b0;
            i_cxscrdrtn    = 1'b0;

            repeat(3) @(posedge i_cxs_rx_clk);

            i_cxs_rx_rst_n = 1'b1;
            i_system_rst_n = 1'b1;

            @(posedge i_cxs_rx_clk);

        end

    endtask


    //==================================================
    // Activate CXS Link
    //==================================================
    task activate_link;

        begin

            @(negedge i_cxs_rx_clk);

            i_cxsactivereq = 1'b1;

            // Keep request asserted until FSM responds
            wait(o_cxsactiveack == 1'b1);

            // Give link controller time to stabilize
            repeat(2) @(posedge i_cxs_rx_clk);

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

            @(negedge i_cxs_rx_clk);

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

            @(posedge i_cxs_rx_clk);

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
        // Activate CXS Link
        //--------------------------------------------------
        activate_link();
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
        //--------------------------------------------------
        // Continue Configuration Data
        //--------------------------------------------------
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
        //--------------------------------------------------
        // Last Configuration Word in first configration tlp
        //--------------------------------------------------
        send_flit(
            16'h4444,
            header_form(
                1'b0,
                8'd0,
                3'b00,
                2'b00,
                2'b00 //configration packet
            ),
            1'b0,
            1'b1,       
            1'b1,//end of tlp 64 bit on two flit each flit 32 bit
            1'b0,
            1'b0,
            1'b0
        );
        send_flit(
            //------------------------------------------------
            // Configuration Word
            //------------------------------------------------
            16'hAAAA,
            16'h0000,
            //------------------------------------------------
            // Header Control
            //------------------------------------------------
            1'b0,
            1'b0,
            1'b1, //end of
            //------------------------------------------------
            // Data Control
            //------------------------------------------------
            1'b0,
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
            16'h0000,
            //------------------------------------------------
            // Header Control
            //------------------------------------------------
            1'b1,
            1'b0,
            1'b1, //end of
            //------------------------------------------------
            // Data Control
            //------------------------------------------------
            1'b1,
            1'b0,
            1'b0
        );
        $display ("============================================================================");
        $display("test 4 send data packet tlp has 5 payload ");
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
            16'h01AA, // address 0000 0001       data  AA 1010 1010 --> 10011001100110010 
            //------------------------------------------------
            // Header Control
            //------------------------------------------------
            1'b1,
            1'b0,
            1'b0, //end of
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
            16'h02BB,// address 0000 0002       data  BB
            16'h03CC,// address 0000 0003       data  CC
            //------------------------------------------------
            // Header Control
            //------------------------------------------------
            1'b0,
            1'b0,
            1'b0, //end of
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
            16'h04DD,// address 0000 0004       data  DD
            header_form(
                1'b0,
                8'd0,
                3'b00,
                2'b00,
                2'b10
            ), //53  continous data packet
            //------------------------------------------------
            // Header Control
            //------------------------------------------------
            1'b0,
            1'b1,
            1'b1, //end of
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
            16'h05BB,// address 0000 0002       data  BB
            16'h06CC,// address 0000 0003       data  CC
            //------------------------------------------------
            // Header Control
            //------------------------------------------------
            1'b0,
            1'b0,
            1'b0, //end of
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
            16'h06FF,// address 0000 0004       data  DD
            header_form(
                1'b1,
                8'd2,
                3'b01,
                2'b01,
                2'b00
            ), //new configration pkt
            //------------------------------------------------
            // Header Control
            //------------------------------------------------
            1'b0,
            1'b1,
            1'b1, //end of
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
            16'h05BB,// address 0000 0002       data  BB
            16'h06CC,// address 0000 0003       data  CC
            //------------------------------------------------
            // Header Control
            //------------------------------------------------
            1'b0,
            1'b0,
            1'b0, //end of
            //------------------------------------------------
            // Data Control
            //------------------------------------------------
            1'b1,
            1'b0,
            1'b0
        );
        
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


endmodule
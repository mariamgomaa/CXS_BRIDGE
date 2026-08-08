`timescale 1ns/1ps

module CXS_RX_TOP_tb;

    // ============================================================
    // Parameters
    // ============================================================
    parameter int CXSMAXPAYLOADPERFLIT = 2;
    parameter int CXSDATAFLITWIDTH     = 32;
    parameter int CNTL_W               = 3 * CXSMAXPAYLOADPERFLIT;

    parameter int FIFO_DEPTH            = 16;
    parameter int MAX_CREDITS           = 15;
    parameter int CREDIT_W              = $clog2(MAX_CREDITS + 1);
    parameter int FIFO_WIDTH            = CNTL_W + CXSDATAFLITWIDTH;


    // ============================================================
    // Clock / Reset
    // ============================================================
    logic clk;
    logic rst_n;


    // ============================================================
    // CXS inputs
    // ============================================================
    logic [CXSDATAFLITWIDTH-1:0] i_CXS_RX_TOP_CXSDATA;
    logic [CNTL_W-1:0]           i_CXS_RX_TOP_CXSCNTL;

    logic i_CXS_RX_TOP_CXSVALID;
    logic i_CXS_RX_TOP_CXSACTIVEREQ;
    logic i_CXS_RX_TOP_CXSCRDRTN;
    logic i_CXS_RX_TOP_buf_release;


    // ============================================================
    // CXS outputs
    // ============================================================
    logic o_CXS_RX_TOP_CXSCRDGNT;
    logic o_CXS_RX_TOP_CXSACTIVEACK;

    logic                     o_CXS_RX_TOP_VALID;
    logic [FIFO_WIDTH-1:0]    o_CXS_RX_TOP_DATA;


    // ============================================================
    // DUT
    // ============================================================
    CXS_RX_TOP #(
        .CXSMAXPAYLOADPERFLIT(CXSMAXPAYLOADPERFLIT),
        .CXSDATAFLITWIDTH    (CXSDATAFLITWIDTH),
        .CNTL_W              (CNTL_W),
        .FIFO_DEPTH          (FIFO_DEPTH),
        .MAX_CREDITS         (MAX_CREDITS),
        .CREDIT_W            (CREDIT_W),
        .FIFO_WIDTH          (FIFO_WIDTH)
    )
    DUT
    (
        .i_CXS_RX_TOP_CLK(
            clk
        ),

        .i_CXS_RX_TOP_rst_n(
            rst_n
        ),

        .i_CXS_RX_TOP_CXSDATA(
            i_CXS_RX_TOP_CXSDATA
        ),

        .i_CXS_RX_TOP_CXSCNTL(
            i_CXS_RX_TOP_CXSCNTL
        ),

        .i_CXS_RX_TOP_CXSVALID(
            i_CXS_RX_TOP_CXSVALID
        ),

        .i_CXS_RX_TOP_CXSACTIVEREQ(
            i_CXS_RX_TOP_CXSACTIVEREQ
        ),

        .i_CXS_RX_TOP_CXSCRDRTN(
            i_CXS_RX_TOP_CXSCRDRTN
        ),

        .i_CXS_RX_TOP_buf_release(
            i_CXS_RX_TOP_buf_release
        ),

        .o_CXS_RX_TOP_CXSCRDGNT(
            o_CXS_RX_TOP_CXSCRDGNT
        ),

        .o_CXS_RX_TOP_CXSACTIVEACK(
            o_CXS_RX_TOP_CXSACTIVEACK
        ),

        .o_CXS_RX_TOP_VALID(
            o_CXS_RX_TOP_VALID
        ),

        .o_CXS_RX_TOP_DATA(
            o_CXS_RX_TOP_DATA
        )
    );


    // ============================================================
    // Clock
    // 10 ns period
    // ============================================================
    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end


    // ============================================================
    // Reset task
    // ============================================================
    task reset_dut;
    begin

        $display("\n==============================================");
        $display("RESET");
        $display("==============================================");

        rst_n = 1'b0;

        i_CXS_RX_TOP_CXSDATA      = '0;
        i_CXS_RX_TOP_CXSCNTL      = '0;
        i_CXS_RX_TOP_CXSVALID     = 1'b0;
        i_CXS_RX_TOP_CXSACTIVEREQ = 1'b0;
        i_CXS_RX_TOP_CXSCRDRTN    = 1'b0;
        i_CXS_RX_TOP_buf_release  = 1'b0;

        repeat (3) @(posedge clk);

        rst_n = 1'b1;

        repeat (2) @(posedge clk);

    end
    endtask


    // ============================================================
    // Activate link
    // ============================================================
    task activate_link;
    begin

        $display("\n==============================================");
        $display("ACTIVATE LINK");
        $display("==============================================");

        @(negedge clk);

        i_CXS_RX_TOP_CXSACTIVEREQ = 1'b1;

        @(posedge clk);

        $display(
            "[%0t] ACTIVE_REQ=%b ACTIVE_ACK=%b CREDIT_GRANT=%b",
            $time,
            i_CXS_RX_TOP_CXSACTIVEREQ,
            o_CXS_RX_TOP_CXSACTIVEACK,
            o_CXS_RX_TOP_CXSCRDGNT
        );

        @(posedge clk);

    end
    endtask


    // ============================================================
    // Send one CXS flit
    //
    // Custom 32-bit CNTL:
    //
    // CNTL[0] = START0
    // CNTL[1] = START1
    // CNTL[2] = END0
    // CNTL[3] = END1
    // CNTL[4] = ERROR0
    // CNTL[5] = ERROR1
    //
    // Payload0 = DATA[15:0]
    // Payload1 = DATA[31:16]
    // ============================================================
    task send_flit;

        input [31:0] data;
        input [5:0]  cntl;

    begin

        @(negedge clk);

        i_CXS_RX_TOP_CXSVALID = 1'b1;
        i_CXS_RX_TOP_CXSDATA  = data;
        i_CXS_RX_TOP_CXSCNTL  = cntl;

        $display(
            "[%0t] SEND FLIT : DATA=%h CNTL=%06b",
            $time,
            data,
            cntl
        );

        @(posedge clk);

        @(negedge clk);

        i_CXS_RX_TOP_CXSVALID = 1'b0;
        i_CXS_RX_TOP_CXSDATA  = '0;
        i_CXS_RX_TOP_CXSCNTL  = '0;

    end
    endtask


    // ============================================================
    // Send consecutive flits
    //
    // CXSVALID remains asserted for multiple cycles.
    // ============================================================
    task send_flit_continuous;

        input [31:0] data0;
        input [5:0]  cntl0;

        input [31:0] data1;
        input [5:0]  cntl1;

    begin

        @(negedge clk);

        i_CXS_RX_TOP_CXSVALID = 1'b1;

        i_CXS_RX_TOP_CXSDATA  = data0;
        i_CXS_RX_TOP_CXSCNTL  = cntl0;

        $display(
            "[%0t] SEND FLIT 0 : DATA=%h CNTL=%06b",
            $time,
            data0,
            cntl0
        );

        @(posedge clk);

        @(negedge clk);

        i_CXS_RX_TOP_CXSDATA = data1;
        i_CXS_RX_TOP_CXSCNTL = cntl1;

        $display(
            "[%0t] SEND FLIT 1 : DATA=%h CNTL=%06b",
            $time,
            data1,
            cntl1
        );

        @(posedge clk);

        @(negedge clk);

        i_CXS_RX_TOP_CXSVALID = 1'b0;
        i_CXS_RX_TOP_CXSDATA  = '0;
        i_CXS_RX_TOP_CXSCNTL  = '0;

    end
    endtask


    // ============================================================
    // Return one credit
    // ============================================================
    task return_credit;

    begin

        @(negedge clk);

        i_CXS_RX_TOP_CXSCRDRTN = 1'b1;

        $display(
            "[%0t] CXSCRDRTN = 1",
            $time
        );

        @(posedge clk);

        @(negedge clk);

        i_CXS_RX_TOP_CXSCRDRTN = 1'b0;

    end

    endtask


    // ============================================================
    // Release one FIFO entry
    //
    // This represents downstream consuming one FIFO entry.
    // ============================================================
    task release_buffer;

    begin

        @(negedge clk);

        i_CXS_RX_TOP_buf_release = 1'b1;

        $display(
            "[%0t] BUF_RELEASE = 1",
            $time
        );

        @(posedge clk);

        @(negedge clk);

        i_CXS_RX_TOP_buf_release = 1'b0;

    end

    endtask


    // ============================================================
    // Deactivate link
    // ============================================================
    task deactivate_link;

    begin

        $display("\n==============================================");
        $display("DEACTIVATE LINK");
        $display("==============================================");

        @(negedge clk);

        i_CXS_RX_TOP_CXSACTIVEREQ = 1'b0;

        $display(
            "[%0t] ACTIVE_REQ = 0",
            $time
        );

    end

    endtask


    // ============================================================
    // Main monitor
    // ============================================================
    always @(posedge clk) begin

        $display(
            "[%0t] | ACK=%b | VALID=%b | DATA=%h | CRDGNT=%b | CRDRTN=%b | BUF_REL=%b",

            $time,

            //i_CXS_RX_TOP_CXSACTIVEREQ,
            o_CXS_RX_TOP_CXSACTIVEACK,

            o_CXS_RX_TOP_VALID,
            o_CXS_RX_TOP_DATA,

            o_CXS_RX_TOP_CXSCRDGNT,

            i_CXS_RX_TOP_CXSCRDRTN,
            i_CXS_RX_TOP_buf_release
        );

    end


    // ============================================================
    // Main test
    // ============================================================
    initial begin

        $display("\n");
        $display("================================================");
        $display("          CXS RX TOP TESTBENCH");
        $display("================================================");

        // --------------------------------------------------------
        // Reset
        // --------------------------------------------------------
        reset_dut();


        // --------------------------------------------------------
        // TEST 1
        // Activate link
        // --------------------------------------------------------
        activate_link();


        // ========================================================
        // TEST 2
        //
        // One packet contained completely in payload 0.
        //
        // Payload 0:
        // START = 1
        // END   = 1
        // ERROR = 0
        //
        // Payload 1:
        // START = 0
        // END   = 0
        // ERROR = 0
        //
        // CNTL:
        //
        // bit5 = ERROR1 = 0
        // bit4 = ERROR0 = 0
        // bit3 = END1   = 0
        // bit2 = END0   = 1
        // bit1 = START1 = 0
        // bit0 = START0 = 1
        //
        // CNTL = 000101
        // ========================================================

        $display("\n----------------------------------------------");
        $display("TEST 2: SINGLE PAYLOAD PACKET");
        $display("----------------------------------------------");

        send_flit(
            32'h1122_3344,
            6'b000101
        );

        repeat (2) @(posedge clk);


        // ========================================================
        // TEST 3
        //
        // Packet spans two payloads in the same flit.
        //
        // Payload0:
        // START = 1
        // END   = 0
        //
        // Payload1:
        // START = 0
        // END   = 1
        //
        // CNTL = 001001
        // ========================================================

        $display("\n----------------------------------------------");
        $display("TEST 3: TWO PAYLOAD PACKET");
        $display("----------------------------------------------");

        send_flit(
            32'hAABB_CCDD,
            6'b001001
        );

        repeat (2) @(posedge clk);


        // ========================================================
        // TEST 4
        //
        // Payload0 has an error.
        //
        // START0 = 1
        // END0   = 1
        // ERROR0 = 1
        //
        // CNTL = 010101
        // ========================================================

        $display("\n----------------------------------------------");
        $display("TEST 4: ERROR PAYLOAD");
        $display("----------------------------------------------");

        send_flit(
            32'hDEAD_BEEF,
            6'b010101
        );

        repeat (2) @(posedge clk);


        // ========================================================
        // TEST 5
        //
        // Consecutive flits.
        //
        // This checks that the receiver can accept a flit every
        // clock while CXSVALID remains asserted.
        // ========================================================

        $display("\n----------------------------------------------");
        $display("TEST 5: CONSECUTIVE FLITS");
        $display("----------------------------------------------");

        send_flit_continuous(
            32'h0000_1111,
            6'b000001,

            32'h2222_3333,
            6'b001000
        );

        repeat (2) @(posedge clk);


        // ========================================================
        // TEST 6
        //
        // Buffer release.
        //
        // This represents downstream consuming FIFO entries.
        // ========================================================

        $display("\n----------------------------------------------");
        $display("TEST 6: BUFFER RELEASE");
        $display("----------------------------------------------");

        release_buffer();
        release_buffer();
        release_buffer();

        repeat (2) @(posedge clk);


        // ========================================================
        // TEST 7
        //
        // Return credits from transmitter.
        //
        // CXSCRDRTN decreases outstanding_credit.
        // ========================================================

        $display("\n----------------------------------------------");
        $display("TEST 7: CREDIT RETURN");
        $display("----------------------------------------------");

        return_credit();
        return_credit();
        return_credit();

        repeat (2) @(posedge clk);


        // ========================================================
        // TEST 8
        //
        // Deactivate.
        //
        // Link Control should:
        //
        // ACK              = 1
        // VALID_RECEIVING  = 1
        // CREDIT_GRANT     = 0
        //
        // while waiting for all credits to return.
        // ========================================================

        $display("\n----------------------------------------------");
        $display("TEST 8: DEACTIVATE");
        $display("----------------------------------------------");

        deactivate_link();

        repeat (3) @(posedge clk);


        // ========================================================
        // TEST 9
        //
        // While deactivating, send one final flit.
        //
        // The Link Control remains receiving-enabled in your
        // DEACTIVATE state.
        // ========================================================

        $display("\n----------------------------------------------");
        $display("TEST 9: FINAL FLIT DURING DEACTIVATE");
        $display("----------------------------------------------");

        send_flit(
            32'hCAFE_BABE,
            6'b000101
        );

        repeat (3) @(posedge clk);


        // ========================================================
        // TEST 10
        //
        // Return remaining credits.
        //
        // When outstanding_credit reaches zero,
        // return_all_credit should become 1.
        // ========================================================

        $display("\n----------------------------------------------");
        $display("TEST 10: RETURN ALL CREDITS");
        $display("----------------------------------------------");

        return_credit();
        return_credit();
        return_credit();
        return_credit();
        return_credit();

        repeat (5) @(posedge clk);


        // ========================================================
        // Finish
        // ========================================================

        $display("\n");
        $display("================================================");
        $display("          CXS RX TOP TEST COMPLETE");
        $display("================================================");

        $stop;

    end

endmodule
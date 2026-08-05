`timescale 1ns/1ps

module control_unit_tb;

    parameter PAYLOAD_W = 16;
    parameter ADDR_W    = 8;
    parameter DATA_W    = 8;
    localparam PAYLOAD_INFO_W = PAYLOAD_W + 2;

    //----------------------------------------------------
    // Clock & Reset
    //----------------------------------------------------
    logic clk;
    logic rst_n;

    //----------------------------------------------------
    // DUT Inputs
    //----------------------------------------------------
    logic fifo_empty;
    logic [PAYLOAD_INFO_W-1:0] fifo_data;

    logic config_done;
    logic [PAYLOAD_W-1:0] config_data;

    //----------------------------------------------------
    // DUT Outputs
    //----------------------------------------------------
    logic rd_fifo_en;
    logic config_we;
    logic payload_valid;
    logic status_valid;
    logic rd_config_en;

    logic [ADDR_W-1:0] address;
    logic [DATA_W-1:0] data;
    logic [PAYLOAD_W-1:0] config_payload;
    logic [ADDR_W-1:0] config_address;

    logic addr_mode;
    logic [2:0] enc_mode;
    logic [1:0] parity_mode;

    //----------------------------------------------------
    // DUT
    //----------------------------------------------------
    control_unit DUT
    (
        .i_control_unit_clk(clk),
        .i_control_unit_rst_n(rst_n),

        .i_control_unit_fifo_empty(fifo_empty),
        .i_control_unit_fifo_data(fifo_data),

        .i_control_unit_config_done(config_done),
        .i_control_unit_config_data(config_data),

        .o_control_unit_rd_fifo_en(rd_fifo_en),
        .o_control_unit_config_we(config_we),
        .o_control_unit_payload_valid(payload_valid),
        .o_control_unit_status_valid(status_valid),
        .o_control_unit_rd_config_en(rd_config_en),

        .o_control_unit_address(address),
        .o_control_unit_data(data),
        .o_control_unit_config_data(config_payload),
        .o_control_unit_config_address(config_address),

        .o_control_unit_addr_mode(addr_mode),
        .o_control_unit_enc_mode(enc_mode),
        .o_control_unit_parity_mode(parity_mode)
    );

    //----------------------------------------------------
    // Clock Generation
    //----------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    //----------------------------------------------------
    // Monitor
    //----------------------------------------------------
    initial
    begin
        $display("-------------------------------------------------------------");
        $display("Time  State Signals");
        $display("-------------------------------------------------------------");

$monitor("%0t fifo_empty=%b rd_fifo=%b cfg_we=%b addr_mode=%b enc_mode=%b parity_mode=%b  payload_valid=%b payload_address=%h cfg_addr=%0d payload=%h current_state =%s nsxt_state =%s config_payload=%h  payload_data=%h ",
            $time,
            fifo_empty,
            rd_fifo_en,
            config_we,
            addr_mode,
            enc_mode,
            parity_mode,
            payload_valid,
            address,
            config_address,
            fifo_data[15:0],
            DUT.u_fsm.current_state,
            DUT.u_fsm.next_state,
            config_payload,
            data);
            
    end

    //----------------------------------------------------
    // Stimulus
    //----------------------------------------------------
    initial
    begin

        //-----------------------------
        // Initial Values
        //-----------------------------
        rst_n       = 0;
        fifo_empty  = 1;
        fifo_data   = '0;
        config_done = 0;
        config_data = 16'h0000;

        //-----------------------------
        // Reset Test
        //-----------------------------
        reset();

        //--------------------------------------------------
        // Configuration Header
        //
        // addr_mode      =1
        // device_count   =5
        // enc_mode       =000
        // parity         =00
        // pkt_type       =00 (CONFIG)   10000100 00010100
        //--------------------------------------------------

        fifo_empty = 0;
        @(posedge clk);
        header_form (1'b1,1'b0,1'b1,8'd5,3'b001,2'b01,2'b00);    
        @(posedge clk);
        @(posedge clk);
        //--------------------------------------------------
        // Configuration Word 0
        //--------------------------------------------------
        payload_format (0,0,16'h1111);
        @(posedge clk);
        @(posedge clk);
        //--------------------------------------------------
        // Configuration Word 1
        //--------------------------------------------------
        payload_format (0,0,16'h2222);
        @(posedge clk);
        @(posedge clk);
        //--------------------------------------------------
        // Configuration Word 2
        //--------------------------------------------------
        payload_format (0,0,16'h3333);
        @(posedge clk);
        @(posedge clk);
        //--------------------------------------------------
        // Last Configuration Word in first configration packet
        //--------------------------------------------------
        payload_format (0,1,16'h4444);
        @(posedge clk);
        @(posedge clk);
        header_form (1'b1,1'b0,1'b0,8'd0,3'b000,2'b00,2'b00);            
        @(posedge clk);
        //--------------------------------------------------
        // Configuration Word 0
        //--------------------------------------------------
        payload_format (0,1,16'h5555);
        @(posedge clk);
        config_done = 1;
        @(posedge clk);
        payload_format (1,1,16'h0001);
        @(posedge clk);
config_done = 0;
        payload_format (1,0,16'h0002);
        config_data = 16'b1000010000010100;
        @(posedge clk);
        @(posedge clk);
        payload_format (0,0,16'h1234);
        @(posedge clk);
        @(posedge clk);
        payload_format (0,1,16'h5678);
        @(posedge clk);
        @(posedge clk);

        fifo_empty = 1;
        reset();
        fifo_empty = 0;
        @(posedge clk);
        header_form (1'b1,1'b0,1'b1,8'd0,3'b001,2'b01,2'b00);    
        @(posedge clk);
        @(posedge clk);
        //--------------------------------------------------
        // Configuration Word 0
        //--------------------------------------------------
        payload_format (0,0,16'h1111);
        @(posedge clk);
        @(posedge clk);
        //--------------------------------------------------
        // Configuration Word 1
        //--------------------------------------------------
        payload_format (0,0,16'h2222);
        @(posedge clk);
        @(posedge clk);
        //--------------------------------------------------
        // Configuration Word 2
        //--------------------------------------------------
        payload_format (0,0,16'h3333);
        @(posedge clk);
        @(posedge clk);

        #100;

        $finish;

    end

task header_form ;
input p_start , p_end ,address_mode;
input[7:0] device_count;
input [2:0] encryption_mode;
input [1:0] parity,pkt_type;
begin
    fifo_data = {
                p_start,            // pkt_start
                p_end,            // pkt_end
                address_mode,            // addr_mode
                device_count,            // device count
                encryption_mode,          // enc mode
                parity,           // parity
                pkt_type            // config packet
            };
end 
endtask

task payload_format ;
input p_start,p_end;
input [15:0] data;
begin
    fifo_data = {
                p_start,
                p_end,
                data
            };
end
endtask

task reset ;
begin
        rst_n = 0;
        @(posedge clk);
        rst_n = 1;
        @(posedge clk);

end 
endtask
endmodule
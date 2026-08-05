module config_addr_ctrl #(
    parameter int ADDR_W = 8
)
(
    input  logic              i_config_addr_ctrl_clk,
    input  logic              i_config_addr_ctrl_rst_n,
    input  logic              i_config_addr_ctrl_first_cfg_tlp,   
    input  logic              i_config_addr_ctrl_config_address_counter,
    // Control
    input  logic              i_control_unit_rd_fifo_en,
    input  logic              i_config_addr_ctrl_pkt_start,
    input  logic [1:0]        i_config_addr_ctrl_pkt_type,

    // Address output
    output logic [ADDR_W-1:0] o_config_addr_ctrl_config_addr
);

    localparam logic [1:0] CONFIG_PKT = 2'b00;

    logic [ADDR_W-1:0] config_addr_cnt;

    always_ff @(posedge i_config_addr_ctrl_clk or negedge i_config_addr_ctrl_rst_n)
    begin
        if(!i_config_addr_ctrl_rst_n)
        begin
            config_addr_cnt <= '0;
        end

        // First word of configuration packet
        else if(i_config_addr_ctrl_pkt_start && (i_config_addr_ctrl_pkt_type == CONFIG_PKT)&&i_config_addr_ctrl_first_cfg_tlp)
        begin
            config_addr_cnt <= '0;
        end

        // Every successful configuration write
        else if(!i_config_addr_ctrl_pkt_start &&i_config_addr_ctrl_config_address_counter)
        begin
            config_addr_cnt <= config_addr_cnt + 1'b1;
        end
    end

    assign o_config_addr_ctrl_config_addr = config_addr_cnt;

endmodule
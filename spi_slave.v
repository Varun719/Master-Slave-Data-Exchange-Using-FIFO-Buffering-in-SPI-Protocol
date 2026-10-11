module spi_slave (
    input clk, sck, reset, ss,
    input mosi,
    output reg miso
);
    reg [7:0] fifo_mem [0:63];
    reg [15:0] shift_in;
    reg [7:0] shift_out;
    reg [7:0] fifo_addr;
    reg [4:0] bit_cnt;
    reg last_sck, ready;

    integer i;

    always @(posedge clk) begin
        last_sck <= sck;
        if (reset) begin
            fifo_mem[0] <= 8'hA1;
            fifo_mem[1] <= 8'hB2;
            fifo_mem[2] <= 8'hC3;
            fifo_mem[3] <= 8'hD4;
            for (i = 4; i < 64; i = i + 1)
                fifo_mem[i] <= 8'h00;
            bit_cnt <= 0; miso <= 0; ready <= 0; shift_out <= 0;
        end else if (!ss) begin
            if (~last_sck & sck) begin
                shift_in <= {shift_in[14:0], mosi};
                bit_cnt <= bit_cnt + 1;
                if (bit_cnt == 15) begin
                    fifo_addr <= shift_in[15:8];
                    shift_out <= fifo_mem[shift_in[15:8]];
                    ready <= 1;
                    bit_cnt <= 0;
                end
            end
            if (ready && last_sck & ~sck) begin
                miso <= shift_out[7];
                shift_out <= {shift_out[6:0], 1'b0};
            end
        end else begin
            bit_cnt <= 0; miso <= 0; ready <= 0;
        end
    end
endmodule

`timescale 1ns / 1ps

module final_spi_comm_protocol;

reg clk = 0, sck = 0, reset = 1, ss = 1, start = 0;
wire mosi, miso, spi_done;
wire [7:0] spi_data_received;
reg [7:0] fifo_addr = 3, mem_addr = 7, alt_addr = 10, retry_count = 0;
reg [7:0] memory [0:15];
integer i;
parameter MAX_RETRY = 3;

always #5 clk = ~clk;
always #10 sck = ~sck;

spi_master master (
    .clk(clk), .sck(sck), .reset(reset), .start(start), .ss(ss),
    .mosi(mosi), .miso(miso), .fifo_addr(fifo_addr), .mem_addr(mem_addr),
    .data_received(spi_data_received), .done(spi_done)
);

spi_slave slave (
    .clk(clk), .sck(sck), .reset(reset), .ss(ss), .mosi(mosi), .miso(miso)
);


initial begin
    @(negedge reset);
    for (i = 0; i < 16; i = i + 1)
        memory[i] = 8'h00;
end


initial begin
    $display("\n--- SPI FIFO to Memory with Retry Begins ---");
    #20 reset = 0;
    #20 ss = 0; start = 1;
    @(posedge spi_done); start = 0;

    $display("SPI Data Received = %h", spi_data_received);

    if (memory[mem_addr] === 8'h00) begin
        memory[mem_addr] = spi_data_received;
        $display("Written at %0d", mem_addr);
    end else begin
        while (memory[mem_addr] !== 8'h00 && retry_count < MAX_RETRY) begin
            retry_count = retry_count + 1;
            mem_addr = alt_addr;
            $display("Retry %0d at %0d", retry_count, mem_addr);
            start = 1; @(posedge spi_done); start = 0;
        end
        if (memory[mem_addr] === 8'h00) begin
            memory[mem_addr] = spi_data_received;
            $display("Written at retry %0d", mem_addr);
        end else $display("Data lost after max retries.");
    end

    ss = 1;
    $display("\n--- Final Memory Content ---");
    for (i = 0; i < 16; i = i + 1)
        $display("Mem[%0d]=%h", i, memory[i]);
    $finish;
end
endmodule

module spi_master (
    input clk, sck, reset, start, ss,
    output reg mosi,
    input miso,
    input [7:0] fifo_addr, mem_addr,
    output reg [7:0] data_received,
    output reg done
);
    reg [15:0] shift_out, shift_in;
    reg [4:0] bit_cnt;
    reg running, last_sck;

    always @(posedge clk) begin
        last_sck <= sck;
        if (reset) begin
            running <= 0; done <= 0; bit_cnt <= 0; mosi <= 0;
        end else if (start & ~running) begin
            running <= 1; done <= 0; bit_cnt <= 16;
            shift_out <= {fifo_addr, mem_addr}; shift_in <= 0;
        end else if (running & ~ss) begin
            if (~last_sck & sck) begin
                mosi <= shift_out[15];
                shift_out <= {shift_out[14:0], 1'b0};
                shift_in <= {shift_in[14:0], miso};
                bit_cnt <= bit_cnt - 1;
                if (bit_cnt == 1) begin
                    data_received <= {shift_in[6:0], miso};
                    done <= 1; running <= 0;
                end
            end
        end else done <= 0;
    end
endmodule

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



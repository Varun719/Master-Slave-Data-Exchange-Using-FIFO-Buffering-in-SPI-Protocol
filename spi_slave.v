module spi_slave(
  input wire sck,
  input wire ss,
  input wire reset,
  input wire [1:0] mode,
  input wire [7:0] data_in,
  input wire s_send,

  output reg [7:0] spdr,
  output reg spif,
  output reg miso_s,
  input wire mosi_s
);

  reg [7:0] shift_register;
  reg [2:0] bit_count;

  wire cpol = mode[1];
  wire cpha = mode[0];

  // Unified always block with reset and main logic
  always @(posedge sck or posedge reset or posedge ss) begin
    if (reset || ss) begin
      bit_count      <= 3'd0;
      shift_register <= 8'd0;
      spdr           <= 8'd0;
      miso_s         <= 1'b0;
      spif           <= 1'b0;
    end
    else if (!ss && s_send && mode == 2'b00) begin
      shift_register <= {shift_register[6:0], mosi_s};
      miso_s <= data_in[7 - bit_count];

      bit_count <= bit_count + 1;

      if (bit_count == 3'd7) begin
        spdr <= {shift_register[6:0], mosi_s};
        spif <= 1'b1;
        bit_count <= 0;
      end
    end
  end

endmodule

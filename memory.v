module memory(data,address,clk,reset);
input [9:0]address;
input clk,reset;
output reg [7:0]data;
reg [7:0]ram[1023:0];
integer i;

initial
begin
	for(i=0;i<1024;i=i+1)
	begin
		ram[i]=i;
	end
end

always@(posedge clk or posedge reset)
begin
	if(reset)
	begin
		data<=8'b0;
	end
	else
	begin
		data<=ram[address];
	end
end
endmodule

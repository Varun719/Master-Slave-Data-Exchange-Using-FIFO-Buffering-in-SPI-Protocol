module fifo(data_in,clk,reset,enqueue_enable,data_out);  
input clk,reset,enqueue_enable;
input [7:0]data_in;
reg [7:0]fifo[0:63];
integer i;
reg [5:0]front;
reg [5:0]rear;
output reg [7:0]data_out;

always@(posedge clk)
begin
   if(reset)
	 begin
		  for(i=0;i<64;i=i+1)
		  begin
			 fifo[i]<=8'h00;
			 front<=6'd63;
			 rear<=6'd63;
			 data_out<=8'h00;
		  end
	 end
	 
  else if(enqueue_enable)
	begin
	 if(front==6'd63 && rear==6'd63)
	 begin
		  front<=0;
		  rear<=0;
		  fifo[rear]<=data_in;
	 end
	 else if(rear==6'd63)
	 begin
		  $display("Sorry queueue is full : %0t",$time);
	 end
	 else
	 begin
		 rear<=rear+1;
		 fifo[rear+1]<=data_in;
	 end
  end
 
	else
	begin
	 if(front==6'd63 && rear==6'd63)
	 begin
		  front<=0;
		  rear<=0;
		  data_out<=fifo[front];
	 end
	 
	 else if(front==rear)
	 begin
	    data_out<=fifo[front];
	    $display("Dequed data=%0d",data_out);
		  front<=6'd63;
		  rear<=6'd63;
	 end
	 else
	 begin
		  data_out<=fifo[front];
		  $display("data_out=%0d",data_out);
		  front<=front+1;
	 end
  end
end
endmodule
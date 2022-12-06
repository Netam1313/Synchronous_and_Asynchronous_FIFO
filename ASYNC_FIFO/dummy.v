
module async_fifo #(parameter addr_size=4,data_size=8)
						(input rd_clk,wr_clk,rrst,wrst,rd_en,wr_en,input[data_size-1:0]wr_data,
						  output [data_size-1:0]data_out,output full,empty);
						  
wire wfullen,rempty_en;
wire [addr_size-1:0]wr_addr,rd_addr;
wire [addr_size:0]wr_ptr,rd_ptr,sync_rdptr,sync_wptr;

assign wfullen=wr_en & ~full;//write on fifo when mem is not full and wr_en is high
assign rempty_en=rd_en & ~empty;
gray_ptr wr_gray(wr_clk,wrst, wfullen,full,1'b1,wr_ptr,wr_addr);//for counting write pointer
gray_ptr rd_gray(rd_clk,rrst, rempty_en,1'b1,empty,rd_ptr,rd_addr);
rdptr_sync synrd(wr_clk,wrst,rd_ptr,sync_rdptr);
wrptr_sync syncwr(rd_clk,rrst,wr_ptr,sync_wptr);
fifo_empty f_emp(rd_clk,rrst,rd_ptr,sync_wptr,empty);
fifo_full f_full(wr_clk,wrst,wr_ptr,sync_rdptr,full );
fifo_mem_rd_wr mem1(wr_clk,wfullen,rempty_en,wr_addr,rd_addr,wr_data,data_out);
endmodule


/****************************************************************************************************************/


module fifo_full #(parameter addr_size=4)(input wclk,wrst,input[addr_size:0]wr_ptr,sync_rdptr,output reg full );

always@(posedge wclk or negedge wrst)
begin
if(!wrst) full<=1'b0;
else if((wr_ptr[addr_size]!=sync_rdptr[addr_size] )&& (wr_ptr[addr_size-1]!=sync_rdptr[addr_size-1])&& 
				wr_ptr[addr_size-2:0]==sync_rdptr[addr_size-2:0]) full<=1'b1;
else full<=1'b0;
end
endmodule


/****************************************************************************************************************/


module fifo_empty #(parameter addr_size=4)(input rclk,rrst,input[addr_size:0]rd_ptr,sync_wptr,output reg empty );

always@(posedge rclk or negedge rrst)
begin
if(!rrst) empty<=1'b1;
else if(rd_ptr==sync_wptr) empty<=1'b1;
else empty<=1'b0;
end
endmodule

/****************************************************************************************************************/

module gray_ptr #(parameter addr_size=4)
				(input clk,rst, inc_en,full,empty,output reg[addr_size:0]nxt_gray,output[addr_size:0]mem_addr );
		
wire [addr_size:0] nxt_binary;
reg [addr_size:0] binary;	

always @(posedge clk or negedge rst)
if(!rst) begin binary<=0;nxt_gray<=0;end
else if(inc_en) begin binary<=nxt_binary;nxt_gray<=nxt_binary ^ (nxt_binary>>1);end

//assign binary<=nxt_binary;
assign nxt_binary=binary+(inc_en & (~full|~empty));
//assign nxt_gray=nxt_binary ^ (nxt_binary>>1);
assign mem_addr=binary[addr_size-1:0];
endmodule


/****************************************************************************************************************/


module fifo_mem_rd_wr #(parameter addr_size=4,data_size=8)(input wr_clk,wr_en,rd_en,input[addr_size-1:0]wr_addr,rd_addr,
							input[data_size-1:0]wr_data,output[data_size-1:0]data_out);

localparam len=2**addr_size;							
reg [data_size-1:0]fifo_mem[0:len-1];				
assign data_out=rd_en?fifo_mem[rd_addr]:0;
always@(posedge wr_clk)
begin
	if(wr_en) fifo_mem[wr_addr]<=wr_data;
end
endmodule

/****************************************************************************************************************/

module rdptr_sync #(parameter addr_size=4)(input wclk,wrst,input[addr_size:0]rd_ptr,output reg[addr_size:0]sync_rdptr);

reg [addr_size:0]temp;
always@(posedge wclk or negedge wrst)//write pointer work on read clock
begin
if(!wrst)begin sync_rdptr<=0;
						temp<=0; end
else begin
			temp<=rd_ptr;
			sync_rdptr<=temp;
		end
end
endmodule

/****************************************************************************************************************/

module wrptr_sync #(parameter addr_size=4)(input rclk,rrst,input[addr_size:0]wr_ptr,output reg[addr_size:0]sync_wptr);

reg [addr_size:0]temp;
always@(posedge rclk or negedge rrst)//write pointer work on read clock
begin
if(!rrst)begin sync_wptr<=0;
						temp<=0; end
else begin
			temp<=wr_ptr;
			sync_wptr<=temp;
		end
end
endmodule






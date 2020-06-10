`timescale 1ps/1ps
module top
(
	input                       clk,                    //clock input
	input                       rst_n,	                //reset input
	input                       key,                   //record play button
	input                       wm8731_bclk,            //audio bit clock
	input                       wm8731_daclrc,          //DAC sample rate left right clock
	output                      wm8731_dacdat,          //DAC audio data output 
	input                       wm8731_adclrc,          //ADC sample rate left right clock
	input                       wm8731_adcdat,          //ADC audio data input
	inout                       wm8731_scl,             //I2C clock
	inout                       wm8731_sda,             //I2C data
	output                      sdram_clk,              //sdram clock
	output                      sdram_cke,              //sdram clock enable
	output                      sdram_cs_n,             //sdram chip select
	output                      sdram_we_n,             //sdram write enable
	output                      sdram_cas_n,            //sdram column address strobe
	output                      sdram_ras_n,            //sdram row address strobe
	output[1:0]                 sdram_dqm,              //sdram data enable 
	output[1:0]                 sdram_ba,               //sdram bank address
	output[12:0]                sdram_addr,             //sdram address
	output[5:0]                 sel,                    //digital led chip select
   output[7:0]                 seg_led,                //seven segments LED output
	inout[15:0]                 sdram_dq                //sdram data
);
parameter MEM_DATA_BITS         = 16  ;                 //external memory user interface data width
parameter ADDR_BITS             = 24  ;                 //external memory user interface address width
parameter BUSRT_BITS            = 10  ;                 //external memory user interface burst width
wire                            wr_burst_data_req;
wire                            wr_burst_finish;
wire                            rd_burst_finish;
wire                            rd_burst_req;
wire                            wr_burst_req;
wire[BUSRT_BITS - 1:0]          rd_burst_len;
wire[BUSRT_BITS - 1:0]          wr_burst_len;
wire[ADDR_BITS - 1:0]           rd_burst_addr;
wire[ADDR_BITS - 1:0]           wr_burst_addr;
wire                            rd_burst_data_valid;
wire[MEM_DATA_BITS - 1 : 0]     rd_burst_data;
wire[MEM_DATA_BITS - 1 : 0]     wr_burst_data;
wire                            read_req;
wire                            read_req_ack;  
wire                            read_en;
wire[63:0]                      read_data;
wire                            write_en;
wire[63:0]                      write_data;
wire                            write_req;
wire                            write_req_ack;
wire[9:0]                       lut_index;
wire[31:0]                      lut_data;

//segment decoder
wire[6:0] seg_data_0;
seg_decoder seg_decoder_m0(
    .bin_data  (1'b0),
    .seg_led  (seg_data_0)
);
wire[6:0] seg_data_1;
seg_decoder seg_decoder_m1(
    .bin_data  (1'b0),
    .seg_led  (seg_data_1)
);
wire[6:0] seg_data_2;
wire[3:0] data_2 = 4'd6;
seg_decoder seg_decoder_m2(
    .bin_data  (data_2),
    .seg_led  (seg_data_2)
);
wire[6:0] seg_data_3;
wire[3:0] data_3 = 4'd3;
seg_decoder seg_decoder_m3(
    .bin_data  (data_3),
    .seg_led  (seg_data_3)
);
wire[6:0] seg_data_4;
wire[3:0] data_4 = 4'hd;
seg_decoder seg_decoder_m4(
    .bin_data  (data_4),
    .seg_led  (seg_data_4)
);

wire[6:0] seg_data_5;
wire[3:0] data_5 = 4'hb;
seg_decoder seg_decoder_m5(
    .bin_data  (data_5),
    .seg_led  (seg_data_5)
);

// segment scan
seg_scan seg_scan_m0(
    .clk        (clk),
    .rst_n      (rst_n),
    .sel    (sel),
    .seg_led   (seg_led),
    .seg_data_0 ({1'b1,seg_data_0}),      //The  decimal point at the highest bit,and low level effecitve
    .seg_data_1 ({1'b1,seg_data_1}), 
    .seg_data_2 ({1'b1,seg_data_2}),
    .seg_data_3 ({1'b1,seg_data_3}),
    .seg_data_4 ({1'b1,seg_data_4}),
    .seg_data_5 ({1'b1,seg_data_5})
); 
//generate SDRAM controller clock
sdram_pll sdram_pll_m0(
	.inclk0                     (clk                     ),
	.c0                         (sdram_clk               )
);

//I2C master controller
i2c_config i2c_config_m0(
	.rst                        (~rst_n                   ),
	.clk                        (clk                      ),
	.clk_div_cnt                (16'd500                  ),
	.i2c_addr_2byte             (1'b0                     ),
	.lut_index                  (lut_index                ),
	.lut_dev_addr               (lut_data[31:24]          ),
	.lut_reg_addr               (lut_data[23:8]           ),
	.lut_reg_data               (lut_data[7:0]            ),
	.error                      (                         ),
	.done                       (                         ),
	.i2c_scl                    (wm8731_scl               ),
	.i2c_sda                    (wm8731_sda               )
);
//configure look-up table
lut_wm8731 lut_wm8731_m0(
	.lut_index                  (lut_index                ),
	.lut_data                   (lut_data                 )
);

audio_record_play_ctrl audio_record_play_ctrl_m0
(
	.rst                        (~rst_n                   ),
	.clk                        (clk                      ),
	.key                        (key                      ),
	.bclk                       (wm8731_bclk              ),
	.daclrc                     (wm8731_daclrc            ),
	.dacdat                     (wm8731_dacdat            ),
	.adclrc                     (wm8731_adclrc            ),
	.adcdat                     (wm8731_adcdat            ),
	.write_req                  (write_req                ),
	.write_req_ack              (write_req_ack            ),
	.write_en                   (write_en                 ),
	.write_data                 (write_data               ),
	.read_req                   (read_req                 ),
	.read_req_ack               (read_req_ack             ),
	.read_en                    (read_en                  ),
	.read_data                  (read_data                )
);

//audio frame data read-write control
frame_read_write frame_read_write_m0
(
	.rst                        (~rst_n                   ),
	.mem_clk                    (sdram_clk                ),
	.rd_burst_req               (rd_burst_req             ),
	.rd_burst_len               (rd_burst_len             ),
	.rd_burst_addr              (rd_burst_addr            ),
	.rd_burst_data_valid        (rd_burst_data_valid      ),
	.rd_burst_data              (rd_burst_data            ),
	.rd_burst_finish            (rd_burst_finish          ),
	.read_clk                   (clk                      ),
	.read_req                   (read_req                 ),
	.read_req_ack               (read_req_ack             ),
	.read_finish                (                         ),
	.read_addr_0                (24'd0                    ), //The first frame address is 0
	.read_addr_1                (24'd0                    ), //The second frame address is 24'd2073600 ,large enough address space for one frame of video
	.read_addr_2                (24'd0                    ),
	.read_addr_3                (24'd0                    ),
	.read_addr_index            (2'd0                     ),
	.read_len                   (24'd786432               ), //frame size, as large as possible storage space
	.read_en                    (read_en                  ),
	.read_data                  (read_data                ),

	.wr_burst_req               (wr_burst_req             ),
	.wr_burst_len               (wr_burst_len             ),
	.wr_burst_addr              (wr_burst_addr            ),
	.wr_burst_data_req          (wr_burst_data_req        ),
	.wr_burst_data              (wr_burst_data            ),
	.wr_burst_finish            (wr_burst_finish          ),
	.write_clk                  (clk                      ),
	.write_req                  (write_req                ),
	.write_req_ack              (write_req_ack            ),
	.write_finish               (                         ),
	.write_addr_0               (24'd0                    ),
	.write_addr_1               (24'd0                    ),
	.write_addr_2               (24'd0                    ),
	.write_addr_3               (24'd0                    ),
	.write_addr_index           (2'd0                     ),
	.write_len                  (24'd786432               ), //frame size, as large as possible storage space
	.write_en                   (write_en                 ),
	.write_data                 (write_data               )
);
//sdram controller
sdram_core sdram_core_m0
(
	.rst                        (~rst_n                   ),
	.clk                        (sdram_clk                ),
	.rd_burst_req               (rd_burst_req             ),
	.rd_burst_len               (rd_burst_len             ),
	.rd_burst_addr              (rd_burst_addr            ),
	.rd_burst_data_valid        (rd_burst_data_valid      ),
	.rd_burst_data              (rd_burst_data            ),
	.rd_burst_finish            (rd_burst_finish          ),
	.wr_burst_req               (wr_burst_req             ),
	.wr_burst_len               (wr_burst_len             ),
	.wr_burst_addr              (wr_burst_addr            ),
	.wr_burst_data_req          (wr_burst_data_req        ),
	.wr_burst_data              (wr_burst_data            ),
	.wr_burst_finish            (wr_burst_finish          ),
	.sdram_cke                  (sdram_cke                ),
	.sdram_cs_n                 (sdram_cs_n               ),
	.sdram_ras_n                (sdram_ras_n              ),
	.sdram_cas_n                (sdram_cas_n              ),
	.sdram_we_n                 (sdram_we_n               ),
	.sdram_dqm                  (sdram_dqm                ),
	.sdram_ba                   (sdram_ba                 ),
	.sdram_addr                 (sdram_addr               ),
	.sdram_dq                   (sdram_dq                 )
);


endmodule

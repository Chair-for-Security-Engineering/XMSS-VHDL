create_clock -period 1.5 -name clk -waveform {0.000 5.25} [get_ports clk]






set_input_delay -clock [get_clocks clk] -min -add_delay 2.000 [get_ports {d[data_in][*]}]
set_input_delay -clock [get_clocks clk] -max -add_delay 2.000 [get_ports {d[data_in][*]}]
set_input_delay -clock [get_clocks clk] -min -add_delay 2.000 [get_ports {d[enable]}]
set_input_delay -clock [get_clocks clk] -max -add_delay 2.000 [get_ports {d[enable]}]
set_output_delay -clock [get_clocks clk] -min -add_delay 0.000 [get_ports {q[done]}]
set_output_delay -clock [get_clocks clk] -max -add_delay 2.000 [get_ports {q[done]}]


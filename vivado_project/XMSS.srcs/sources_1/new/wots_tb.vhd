----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11.02.2020 15:41:04
-- Design Name: 
-- Module Name: wots_chain_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.wots_comp.ALL;
use work.params.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity wots_tb is
    constant clk_period : time := 5 ns;

	signal clk, reset : std_logic;
	signal wots_in : wots_input_type;
	signal wots_out : wots_output_type;
	signal hash_in : absorb_message_input_type;
	signal hash_out : absorb_message_output_type;
	signal bram_in : dual_port_bram_in;
	signal bram_out : dual_port_bram_out;
end wots_tb;

architecture Behavioral of wots_tb is

begin
    bram_module : entity work.blk_mem_gen_0
	port map(
	    clka    => clk,
        ena     => wots_out.bram.a.en,
        wea(0)  => wots_out.bram.a.wen,
        addra   => wots_out.bram.a.addr,
        dina    => wots_out.bram.a.din,
        douta   => wots_in.bram.a.dout,
        clkb    => clk,
        enb     => wots_out.bram.b.en,
        web(0)  => wots_out.bram.b.wen,
        addrb   => wots_out.bram.b.addr,
        dinb    => wots_out.bram.b.din,
        doutb   => wots_in.bram.b.dout
	);

    uut : entity work.wots
	port map(
		clk     => clk,
		reset => reset,
		d => wots_in,
	    q => wots_out);
	
	hash : entity work.absorb_message
	generic map(
	   BLOCK_SIZE => 512,
	   PADDING_LENGTH => 64)
	port map(
	   clk => clk,
	   reset => reset,
	   d => wots_out.hash,
	   q => wots_in.hash );

	process
	begin
		clk <= '1';
		wait for clk_period / 2;

		clk <= '0';
		wait for clk_period / 2;
	end process;

	process
	begin
	   ---- Testvector
--Seeds
--
--a344f01778bb4aca2d1406c8821017fbd029aa42803a835c362396778c678dfa (priv)
--602b26ef82322218b61c22a9581989384d0d4a5653a5d761e3f8fbe80f5020bb (pub)
--
--Params are: 
--Func: 0
--n: 32
--Wots_w: 16
--wots_log_w: 4
--wots_len1: 64
--wots_len2: 3
--wots_len: 67
--wots_sig_bytes: 2144
--full_height: 10
--tree_height: 10
--d: 1
--index_bytes: 4
--sig_bytes: 2500
--pk_bytes: 64
--sk_bytes: 132
--bds_k: 0
--
--Public Keys:
--60d71b4187d276fbb517c8bc5e6e737c5812883738950c55cbe518cae598b0bc
--16966c5740170ce211290aef79087d45be516104b5eec243ebbcd4303b420e06
--f678aea06a0b57b5cc25f8283cc013af856299225b4d3da21ed14ffb4a257bec
--b273b5df5dbb81e292910879212dd0a2aff4b5f6013a236c8d22c130f3295272
--d20ebd86f6bfc19c4596e387a0fe21f25bfcfe77a98d24f85ede8c10f223bdd9
--7a304006b6005c592584d8730edd7a33aa1243376d257a0ade290b485d333c23
--8d4f51c76e274b1401c18e572f618bd816fb564999a5a956fdfd7c981bd3c941
--c1acbe39846231e0916b0ce4600eeb9992e8207ffaf39ff8fd7c6a7e7d365b23
--955d24e43ab78d10dae588abd319d9237af86b00710d64316f5a826efcbc1fe5
--bdd515aa6eead13403fca1eb624b0b293138740f19026b0e8874d10e6a50abcc
--7d4a9ca21f05df0a00145b1f1540db521c34ccac2f2282e2a335989b29ad648c
--3db791ebb5236847b6e798957085a52cb9f99a0c45d26fc9ae5ee9dee9624e4d
--921cf4095288bcde4c88f72d5b40d03ee2acfda077cbcfa996a5902963b74719
--d4066ca26ad8fca25a92374143c0b8899ad0da5f3eb9450ef1e3e8661072b5e6
--e7807b240ce8593b682fdcdfa65bc6703f4a325dddddfed09846fdf3fae11abd
--5205a05fb25cc3e4eb6411dc53c6f6eb794cdd6b474ee20dd736094e0447f557
--46f1deea8dc725bad0ddb1b69ad4ca7118834506d65c3e525df5401ea0417e0f
--809286f905f5e17b17b77bb4f43ef4c230590e20fcc58e00aa5833aa1921ff75
--e16351f669e93e471d268842bde9928b69201f4af03734cce6be1e1008798bde
--09352bf764962006497ec3bf1f6b3377f7d9d27c5a90a7f248fbf85075d20506
--6e325654d06cac0f309192eb2fa31591d14606a3f696f9413088149ec39ab4e1
--6c218817695e8f59cbd2a8054fa1420403d0fe87bc0a73885772bb3a02cfc021
--7b2c048f6b249f13317c3fe43eb5346cbb492d65aa1e4e547b22ffbd1e8870c9
--62e9de56bde4afad7877a062b683d10de185073d20e8e9f63ee364fdbc7f0dff
--53819c4eca1e2b96acefde619f7fb26569d3d8a059e821690b3a3ff1b71d901a
--9c5a4f7b8541c01dc22bc4fc2fe562c48cb42e92b095693ee147f9f6a8402874
--453322aa6fca229a74548065ff107235fe442937ea23ebaea3cdd8c9a1ab098c
--40bc0654171718287a07c9f1ccd4901d6e119f2f04dd2a4438b69724d31c5ddf
--c7b5b5384fafb9b5bc897564451434a077b9110a7f4292490dd4881e33212e1c
--4bcc65929a948cef84bcfbc630a0f00f0bde0c5342d298fe9a55b2b8fd474cdb
--85745f31aed1184fa485b0d3d8c565afd86290bd4221e6c91d1529f1d7b8a6a1
--66c7e912144d79582d0a775b079d98bf8b86c149927ab92641481354c76d17a2
--d78c9dbe8d9599fa91360759f6a5e74fb739609c18881d97cde429b2a35276d3
--27e61933a40e8fc5c6d9677ebad77544d462c49d28d84d92ea70dc74bc685201
--00adb16737167221bb3feaaaf5e26c4621a282ea6505d571b7b244f134de5871
--8f073dae0db659cbcb9941090387629f4efdf1276a1d08c1895ed27eab99731c
--6fc1fd98db1278dea73b7d4452f64e9853b64d402a0eadc94c9dc4f790844f89
--30ec048f48f06e8ad1f6985792caca6964cf5fc8f79e469e1ef7e9bb472ebb7d
--05b20e7c6774ebc5dc0dc74e16e2b04f651fec947613ca22a8858c254697cc45
--e675367ec952658d7e0e407a2662873828c52700120f06c955767a62c11d6b9a
--e376ede6ac9f3f5ca6c68cf052ffb83238294142620e0f860da50de701c2af96
--950dd001ac246be08294793979a3aa0ab8088f56e85d09a28aabb3f606506eae
--25f1b315a97c5bd344e5ecb5e90b83c2c5db2258c4c2cd8c227e3db37eb12ff3
--0e058f9a56e0abc666fe059b58d4efb8b1baa9627e3a0f821804694d34a95168
--b82baf9b479c9c5f6fdcbcfd093f61e6a6608076bfbae43aaf31b2d020155120
--5b12e88649ae172b2edde47e1508696ed17cd20f84dfe73ffe89a8f769456de3
--6872d9022ce7a7dd8d3debb16acb88d5a9784a7046390dcdf53d3aa820a7d926
--bb1376f05d18028b390aea35a70f8355038207c95b27b0fb4b4f7811d0c8b0af
--68ecbd316d1363f774cbc264d520f350546a025a211b2a72d26449c1f4bf6c23
--02dacd03766654e7d65fbf384931b71dcc87abef2cb77527f1b5114bb7ebb9a7
--b77d6dc7ad50262d02fba0fc7220c1ac61707b548e34ba8ce6cdf355d9971a33
--eef8304b623ad00379ab044877a3ca6f5b95be2a14fbd681d974566218bd066a
--703757c498ad9359f1d5798ebf16a3cec1c1cfbac77e231478859419ed6e0c75
--e64cc52559081d7cb82d2cf3fc749169a553ff6e8cbb3ebc3fc78e5aa15d8190
--40dbfd7ac834b5528e7fd8bb0b5650fec7191a9e2f4602b3252c599028f9655a
--86557a6d06de5c387b5d80851418830ffa8e79f85f1f6de10ac69926550b37d3
--6857222ffba20a096813304d5401471d8a5208ce4f2482a0bfc320261c3c5aaa
--2908dcbe552a36259e741115e0728fe9701c5b4072df683ff34dd41f0da44fd3
--b51f598ae81840ea77789e0ff020d1442abf7e4547d1b064eb1c27c594fab57d
--55a275760f3881ebbded952d0bda19fce8a0a626c08c8bf0b46e23f757172bc0
--8d6066d60f3fc78a359c0df65883ff29956dca479a4cdf978f0dddac48281542
--bf3c670d9db5ddbce894ea34631104bfe028dbbbea2562e55b08a0ca303eda60
--f0548710110851e9038cd900212d00e559648da4896d7b4923515e7331fdf412
--6ac08cbf41d8eeef4d20372f3c75937f409b00d20568c3275f2cfa31eb425b91
--fac0d3d734a4e76760fb6e9c26cfbc46cbc9e7b5d233ff8a6fce0e98d88fb1fa
--299bc4fd2633698aecc3d3e95209c22c66fe4ec74a5f32469aa74bc027ee4988
--a43c01047cefd39a4ccc566e6f49de0f24bfb23a3de173f1375e8753f628efeb
--
--Message 
--f01ea2366b149531d2800dfff7bccb6f02206d4c98827e69d1330d55e3d08445
--Csum = 8288 
--
--Signature
--60d71b4187d276fbb517c8bc5e6e737c5812883738950c55cbe518cae598b0bc
--11a5b2d223114324dfedc221d9f3c41435476d0807810c17bd995a273b20f326
--20dd208eed9ba6a9387fc02f97e9e3be43c140981e4df6242b117eac80cdd8fa
--7f8136bd485b6cd6b4320ba551530c92d768eb9c3ad6b40cc550e09b70b7177c
--0c4d8431c05fec08b659224e64eba8c709e8a4ca14e334dcc8a2c2130b267041
--305adb33bbf070ce6ee1ddcca9ec203a33b2735e11df379093ec411b52b2342a
--7bedf92a813712669b2a69cc01197c8103aa922cc0e62b837ee63c45aa3c9881
--b671732b2a002780d466609649bf1d19888e0e5f56a66288430fd1dc74c4f5f1
--bf5a6c46cf98dd818f313ab741bd05d3f599a663c19a5debb86a1ca6d9ce5f9d
--68c29e652b26c61816566654124a54c8ae48d49815791f748726f2ba4fa93b42
--c6153e5becb079eb99910867bf73fdb39b6b3a51843fdb2ddfe01f26ddada4d3
--eb7ffde52b2158fb05746d538174feadf3d456bb157e0c5c535e80fc986a71b6
--d49b0a49a439a78e319223f64b3be3cf06d843ee1899e2a7e7b740c7c11c6708
--184cdb36c14edc3f70bd4dd162234d08ff3d4836427e721c4ffa921335e984cb
--0ddc3ef38f362c14abb13f7815d86bb2c43318d985d4c06f774ae63f441d4092
--9ac15bae647063b59133b3c46ef2449c925d2ebdc80fba857e4877c3a10f046e
--abf3ca724cdb87ed470737c2c771348e19f33d85d769fd8ec050d4ba233dd3af
--cd6e62e54e14c44e1bf861f99b6fac899e81c3352c3c3d109debbaaab5f5b24b
--79859ebc8d42d4106fc5492b55c4d6f04c55557007189ed0810efbb2dcffe4eb
--e54bf8372e82948e317682799098960d07fc352e1704171b3d2be18e519b43e2
--2dc63b9de6b480133a67e8591e9df3120b28f9dee6c79d327ccfc0c4524cf3fd
--1212f8a8f458fcf0096d4b0edd2a8926e74003a0933c05c9184d826b75d7c6d0
--7b2c048f6b249f13317c3fe43eb5346cbb492d65aa1e4e547b22ffbd1e8870c9
--62e9de56bde4afad7877a062b683d10de185073d20e8e9f63ee364fdbc7f0dff
--53819c4eca1e2b96acefde619f7fb26569d3d8a059e821690b3a3ff1b71d901a
--2058e9f2945b34e18a46ad3e55f2f1dc7499176f2362f0ad8a0402b978bc1147
--d538779feca867fac5de323f3965b2c62fe1ee7bc1f8078f0741c5e3ea4efbde
--068ed626baf5446c5aa8fb4044ec6056350961e4426a76199b03d0133835b937
--8ddffd8899837fcfa2f42692b8be284138e23d959478e11b3be4cb3410dc6e76
--90c7bdda07c95d929ac14e936606c2085a6bebc1157f499e5bdbde0cc7850881
--e31cf84ab1bf7f127aaab37117f5fd65a78735a3fc7b841b60401fbfd461c4ec
--66c7e912144d79582d0a775b079d98bf8b86c149927ab92641481354c76d17a2
--33e42d6cdd458cb1d31195acfaad41a7864a84a318041cfe5890cca13ee1ae21
--072ffdbd6fd8fa2d2851645cdf45dba6bb21dfe1bfad6687d1d655e3c63863ee
--e31f5e8427a1c8304a7206cdf2d667be13fcb07c74719bbd2958b60d2040a55b
--6c80d3871b3fdce45db48175df135a9c3d13037bbef5f1a3fe04a17dfad70acb
--d44b3b09f584d8bc753d782fe0ed785bd0d34a98e3683bbbc946ab1bd71e3628
--8ce027c47bb70a5b12dacce648dfc44b0b00cb4b47557e14f8344491eb16e3a5
--07f29b61da5498452941d9f1f3dcc29176de1fdc0744e6f12f77e12e852ed4d4
--2157f4bf0511460ad73362284615be02e96da7b89ab32e342f923c0ed5626eaf
--fc8fec82f177c7b9cc774987b895bcd2eda27112c79ed6b09f6147ceddaf72cd
--5a7c84854c15b4aa52577eddb625446ff58df04432d782b799dd1ce75474422a
--cf3646e9a61fb45bdcf4909bbf1be2cc13ef6752e1d2399d798cb915d17ee59b
--3cbcc48725dc67088d5b84d5698ab2befbb9c697e6f581d21102288777833724
--5e2dafdbf018d9c98cbaae01623c659c7fc457c983f7214bd03a5e4d27c9adbb
--5d8059cba4a5d1981e1785ef9192bc6c59f96f2d7f4a32db0007987552945809
--a4b280a847fa50107862373329cc29543d2fc84ca5ac065530cead06ea4f156c
--e22d04af63ab8d6e7def1370a2a39c201f8c0e6c4aa71b4203f83e4ba393dbb8
--99ccb20ed032e78dd59e7018b63506219ad1918b4c9334e25da6c82c331c9ff4
--8d094f213690ad023e59ae8c4da987c2fed81ffacc5df44d0356a095ab06b695
--55a365d0a20f053288ca4d24990d1c429086e6dbe7ecd2178423e3217a314be5
--55120afca30b79b765dbbb8f96aaabfd58d329e809bd5eb0b8271ef1dd2af6ae
--4e849212e9bffc65ad56a7363800e5a9e6628278f1508298942bb040883b2024
--cf34b0983dc4ef266f16ec96eb43a818cd7c99e0a73cd2d3b4f542cf7863d2e0
--79a7e83e957c9ad0b8aa7aa855008ba7ab683eb6baeb4d4fa4add5a362774321
--945885343b12f786593bd5b01b04645754ec1740ec48234ffd63ca32dded516b
--91954e3ad97b052cb084dd5bde7bafae64df1bf53207d7cf5cff6536a54cc00d
--9d5f0295f2279f71aab2a9f6cfbc89b1d8c98dee0d7fc58329171515208f18d9
--02f22d801ecfcd87338b4ca9e8aa432cd17cc93abb8d20a396a71248bbf0a300
--b994ed378a3dfd2c7a28d20a3d8234cbf20ae6ac7c5bca053e0b2c14a6ec422c
--6890ae49ec44220abfbe753abc1059074e21f2c7bd1fff4bff9c83533aa8163c
--462eb1cc614b0da622277bb94f45ad001ec4a434ae8907c88f7047a4061922fd
--a59ceb115be494787a8b1ff1700cbe97de61b462caceb3fad017c977f58a4aad
--0d061e8a371641ad319ba97abbd2ef03d87b38dddc0c98f77350522f26d8b255
--145c7050addf8c48121188e68a506d77487e9ab1a4fdd4ef0815f822dbc16718
--7614f2a2063940a1037973d95fdf8c3fad7cce641309ab68397ad93c49def70b
--5ba2098fd6ee2e0a5c2344971aa6a4a0b49c1d7228b1e0e769e6dcf492948dd2
--
	
	
		wots_in.enable <= '0';
		reset <= '1';
		wait for 2 * clk_period;
        reset <= '0';
		wait for 2 * clk_period;
		wots_in.mode <= "00";
		wots_in.seed <= x"a344f01778bb4aca2d1406c8821017fbd029aa42803a835c362396778c678dfa";
		wots_in.pub_seed <= x"602b26ef82322218b61c22a9581989384d0d4a5653a5d761e3f8fbe80f5020bb";
		wots_in.address(0) <= x"00000000";
		wots_in.address(1) <= x"00000000";
		wots_in.address(2) <= x"00000000";
		wots_in.address(3) <= x"00000000";
		wots_in.address(4) <= x"00000000";
		wots_in.address(5) <= x"00000000";
		wots_in.address(6) <= x"00000000";
		wots_in.address(7) <= x"00000000";
		wots_in.enable <= '1';

		wait for 5 * clk_period;
		wots_in.enable <= '0';
		
		wait until wots_out.done = '1';
		wait for 5 * clk_period;
		wots_in.mode <= "01";
		wots_in.message <= x"f01ea2366b149531d2800dfff7bccb6f02206d4c98827e69d1330d55e3d08445";
		wots_in.enable <= '1';
		wait for 1*clk_period;
		wots_in.enable <= '0';
		wait until wots_out.done = '1';
		
		
		--wots_in.signature <= wots_out.signature;
		wait for 5 * clk_period;
		wots_in.mode <= "10";

		wots_in.enable <= '1';
		wait for 1*clk_period;
		wots_in.enable <= '0';
		wait until wots_out.done = '1';
        
		wait;
	end process;

end Behavioral;

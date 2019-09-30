# GVPF - Generalized Variation of Prediction Footprint

If you find the GVPF source code useful for academic research, you are highly encouraged to cite the following paper:

`David Vázquez-Padín, Marco Fontani, Dasara Shullani, Fernando Pérez-González, Alessandro Piva and Mauro Barni.
"Video Integrity Verification and GOP Size Estimation via Generalized Variation of Prediction Footprint" to appear
in IEEE Transactions on Information Forensics and Security, 10.1109/TIFS.2019.2951313.`

## Abstract

The Variation of Prediction Footprint (VPF), formerly used in video forensics for double compression detection and GOP size estimation, is comprehensively investigated to improve its acquisition capabilities and extend its use to video sequences that contain bi-directional frames (B-frames). By relying on a universal rate-distortion analysis applied to a generic double compression scheme, we first explain the rationale behind the presence of the VPF in double compressed videos and then justify the need of exploiting a new source of information such as the motion vectors, to enhance the VPF acquisition process. Finally, we describe the shifted VPF induced by the presence of B-frames and detail how to compensate the shift to avoid misguided GOP size estimations. The experimental results show that the proposed Generalized VPF (G-VPF) technique outperforms the state of the art, not only in terms of double compression detection and GOP size estimation, but also in reducing computational time.

## Authors
 - David Vázquez-Padín, dvazquez@gts.uvigo.es
 - Marco Fontani, marco.fontani@unifi.it
 - Dasara Shullani, dasara.shullani@unifi.it
 - Fernando Pérez-González, fperez@gts.uvigo.es
 - Alessandro Piva, alessandro.piva@unifi.it
 - Mauro Barni, barni@dii.unisi.it

## GVPF Code

The GVPF code is organized as follows:
 - src/
  - gvpf_12compression.m
  - gvpf_estimation.m
 - test/
  - test_me.m
  - akiyo_cif.yuv


The `gvpf_12compression.m` performs single and double compression on YUV videos.

The `gvpf_estimation.m` performs first GOP estimation and double compression detection.

The `test_me.m` shows how to use `gvpf_12compression.m` and `gvpf_estimation.m` on `akiyo_cif.yuv`.


### Prerequisites:

The GVPF is developed with `Matlab R2017b` and uses the following software to perform video analysis and compression
 - FFmpeg 3.0.1, including: FFprobe, H.264, MPEG-2 and MPEG-4 codecs,
 - x264-snapshot-20160424-2245.

The codecs folder should contain the executable of `FFmpeg` and `x264`. This folder path has to be used as `codec_path` in the `test_me` script.


### Sample code:

In `test_me.m` you can find a usage example. It performs single and double compression over `akiyo_cif.yuv` video in VBR-CRF with: MPEG-2/H.264 codec, GOP size 14/9, QP 2/5 without B-frames in 1st or 2nd compression.
It performs the GVPF analysis: first GOP estimation and double compression detection for both resulting videos.
To run a test:
 - modify the `codec_path` with the fullpath of the CODECs folder
 - call function `test_me`

```matlab
>> test_me

[info]: Processing -- akiyo_cif
[info]: 1 compression -- akiyo_cif DM1=rd BRC1=vbr G1=14 B1=02 COD1=mpeg Bframes=0
[info]: 2 compression -- akiyo_cif DM1=rd BRC1=vbr G1=14 B1=02 COD1=mpeg DM2=rd BRC2=crf G2=09 B2=05 COD2=h264 Bframes=0
[info]: Processing -- tpd6de1100_f4bc_47de_b601_d9f1046b8bb6_video  -- estGOP:   64 -- phi: 0.510
[info]: Processing -- tp7afaee8a_7129_4bbe_9ad8_23f0ee6db56c_video  -- estGOP:   14 -- phi: 1.804
GVPF analysis output:
    video_name: '/tmp/tp4ef97b74_1db7_4d46_9531_484b4a4422de_akiyo_cif_1st.mpeg'
          cod1: 'mpeg'
            B1: 2
            G1: 14
         btrc1: 'vbr'
    num_frames: 250

             video: '/tmp/tp4ef97b74_1db7_4d46_9531_484b4a4422de_akiyo_cif_1st.mpeg'
    gop_estimation: 64
        phi_c_norm: 0.5100
            frames: {1×249 cell}
          mb_types: {1×249 cell}
         mv_values: {249×1 cell}
      dc_detection: 0

    video_name: '/tmp/tp5be25146_2d7c_4e20_a1be_14641c44dd38_akiyo_cif_2nd.h264'
          cod2: 'h264'
            B2: 5
            G2: 9
         btrc2: 'crf'
      B_frames: 0
    num_frames: 250

             video: '/tmp/tp5be25146_2d7c_4e20_a1be_14641c44dd38_akiyo_cif_2nd.h264'
    gop_estimation: 14
        phi_c_norm: 1.8041
            frames: {1×250 cell}
          mb_types: {1×250 cell}
         mv_values: {250×1 cell}
      dc_detection: 1
```

## License

Copyright (C) 2019 David Vázquez-Padín, Marco Fontani, Dasara Shullani

GVPF is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

GVPF is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

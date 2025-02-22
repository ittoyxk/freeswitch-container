## Install
```shell
docker pull ghcr.io/ittoyxk/freeswitch:v1.10.11
```

## Run
```shell
docker run -d --name freeswitch --ulimit core=-1 --network host --restart always ghcr.io/ittoyxk/freeswitch:v1.10.11
```

## update modules.conf.xml
```xml
<!-- <load module="mod_signalwire"/>-->
<load module="mod_shout"/>
```

## update vars.xml 
```xml
<include>
  <X-PRE-PROCESS cmd="set" data="default_password=123456"/>

  <X-PRE-PROCESS cmd="set" data="sound_prefix=$${sounds_dir}/zh/cn/link"/>
  <!--<Z-PRE-PROCESS cmd="set" data="sound_prefix=$${sounds_dir}/en/us/allison"/> -->

  <X-PRE-PROCESS cmd="set" data="domain=$${local_ip_v4}"/>
  <X-PRE-PROCESS cmd="set" data="domain_name=$${domain}"/>
  <X-PRE-PROCESS cmd="set" data="hold_music=local_stream://moh"/>
  <X-PRE-PROCESS cmd="set" data="transfer_ringback=$${hold_music}"/>
  <X-PRE-PROCESS cmd="set" data="use_profile=external"/>
  <X-PRE-PROCESS cmd="set" data="rtp_sdes_suites=AEAD_AES_256_GCM_8|AEAD_AES_128_GCM_8|AES_CM_256_HMAC_SHA1_80|AES_CM_192_HMAC_SHA1_80|AES_CM_128_HMAC_SHA1_80|AES_CM_256_HMAC_SHA1_32|AES_CM_192_HMAC_SHA1_32|AES_CM_128_HMAC_SHA1_32|AES_CM_128_NULL_AUTH"/>
  <X-PRE-PROCESS cmd="set" data="global_codec_prefs=OPUS,PCMU,PCMA,H264"/>
  <X-PRE-PROCESS cmd="set" data="outbound_codec_prefs=OPUS,PCMU,PCMA,H264"/>


  <X-PRE-PROCESS cmd="set" data="xmpp_client_profile=xmppc"/>
  <X-PRE-PROCESS cmd="set" data="xmpp_server_profile=xmpps"/>
  <X-PRE-PROCESS cmd="set" data="bind_server_ip=auto"/>

  <X-PRE-PROCESS cmd="env-set" data="ext_ip=$EXT_IP"/>
  <X-PRE-PROCESS cmd="set" data="external_rtp_ip=$${ext_ip}"/>
  <X-PRE-PROCESS cmd="set" data="external_sip_ip=$${ext_ip}"/>

  <X-PRE-PROCESS cmd="set" data="unroll_loops=true"/>

  <X-PRE-PROCESS cmd="set" data="outbound_caller_name=FreeSWITCH"/>
  <X-PRE-PROCESS cmd="set" data="outbound_caller_id=0000000000"/>

  <!-- various debug and defaults -->
  <X-PRE-PROCESS cmd="set" data="call_debug=false"/>
  <X-PRE-PROCESS cmd="set" data="console_loglevel=info"/>
  <X-PRE-PROCESS cmd="set" data="default_areacode=918"/>
  <X-PRE-PROCESS cmd="set" data="default_country=US"/>

  <X-PRE-PROCESS cmd="set" data="presence_privacy=false"/>

  <X-PRE-PROCESS cmd="set" data="cn-ring=%(1000,4000,450)"/>
  <X-PRE-PROCESS cmd="set" data="us-ring=%(2000,4000,440,480)"/>
  <X-PRE-PROCESS cmd="set" data="bong-ring=v=-7;%(100,0,941.0,1477.0);v=-7;>=2;+=.1;%(1400,0,350,440)"/>
  <X-PRE-PROCESS cmd="set" data="beep=%(1000,0,640)"/>
  <X-PRE-PROCESS cmd="set" data="sit=%(274,0,913.8);%(274,0,1370.6);%(380,0,1776.7)"/>
  <X-PRE-PROCESS cmd="set" data="ringback=$${cn-ring}"/>

  <X-PRE-PROCESS cmd="set" data="df_us_ssn=(?!219099999|078051120)(?!666|000|9\d{2})\d{3}(?!00)\d{2}(?!0{4})\d{4}"/>
  <X-PRE-PROCESS cmd="set" data="df_luhn=?:4[0-9]{12}(?:[0-9]{3})?|5[1-5][0-9]{14}|3[47][0-9]{13}|3(?:0[0-5]|[68][0-9])[0-9]{11}|6(?:011|5[0-9]{2})[0-9]{12}|(?:2131|1800|35\d{3})\d{11}"/>
  <!-- change XX to X below to enable -->
  <XX-PRE-PROCESS cmd="set" data="digits_dialed_filter=(($${df_luhn})|($${df_us_ssn}))"/>

  <X-PRE-PROCESS cmd="set" data="default_provider=example.com"/>
  <X-PRE-PROCESS cmd="set" data="default_provider_username=joeuser"/>
  <X-PRE-PROCESS cmd="set" data="default_provider_password=password"/>
  <X-PRE-PROCESS cmd="set" data="default_provider_from_domain=example.com"/>
  <!-- true or false -->
  <X-PRE-PROCESS cmd="set" data="default_provider_register=false"/>
  <X-PRE-PROCESS cmd="set" data="default_provider_contact=5000"/>

  <X-PRE-PROCESS cmd="set" data="sip_tls_version=tlsv1,tlsv1.1,tlsv1.2"/>

  <X-PRE-PROCESS cmd="set" data="sip_tls_ciphers=ALL:!ADH:!LOW:!EXP:!MD5:@STRENGTH"/>

  <!-- Internal SIP Profile -->
  <X-PRE-PROCESS cmd="set" data="internal_auth_calls=true"/>
  <X-PRE-PROCESS cmd="set" data="internal_sip_port=5060"/>
  <X-PRE-PROCESS cmd="set" data="internal_tls_port=5061"/>
  <X-PRE-PROCESS cmd="set" data="internal_ssl_enable=false"/>

  <!-- External SIP Profile -->
  <X-PRE-PROCESS cmd="set" data="external_auth_calls=false"/>
  <X-PRE-PROCESS cmd="set" data="external_sip_port=5080"/>
  <X-PRE-PROCESS cmd="set" data="external_tls_port=5081"/>
  <X-PRE-PROCESS cmd="set" data="external_ssl_enable=false"/>

  <!-- Video Settings -->
  <!-- Setting the max bandwdith -->
  <X-PRE-PROCESS cmd="set" data="rtp_video_max_bandwidth_in=3mb"/>
  <X-PRE-PROCESS cmd="set" data="rtp_video_max_bandwidth_out=3mb"/>

  <!-- WebRTC Video -->
  <!-- Suppress CNG for WebRTC Audio -->
  <X-PRE-PROCESS cmd="set" data="suppress_cng=true"/>
  <!-- Enable liberal DTMF for those that can't get it right -->
  <X-PRE-PROCESS cmd="set" data="rtp_liberal_dtmf=true"/>
  <!-- Helps with WebRTC Audio -->

  <!-- Stock Video Avatars -->
  <X-PRE-PROCESS cmd="set" data="video_mute_png=$${images_dir}/default-mute.png"/>
  <X-PRE-PROCESS cmd="set" data="video_no_avatar_png=$${images_dir}/default-avatar.png"/>
  <X-PRE-PROCESS cmd="set" data="rtp_force_video_fmtp=profile-level-id=42C01E;packetization-mode=1"/>
  <X-PRE-PROCESS cmd="set" data="rtp_pass_codecs_on_stream_change=true"/>
  <X-PRE-PROCESS cmd="set" data="rtp_video_max_bandwidth_in=600"/>
  <X-PRE-PROCESS cmd="set" data="rtp_video_max_bandwidth_out=600"/>
  <X-PRE-PROCESS cmd="set" data="rtp_video_max_bandwidth=600"/>
  <X-PRE-PROCESS cmd="set" data="core_video_blank_image=false"/>
</include>
```

## docker-compose.yml 
```shell
version: "3"

services:
  xk-switch:
    container_name: freeswitch
    hostname: "xk-node-1"
    image: ghcr.io/ittoyxk/freeswitch:v1.10.11
    environment:
      - TZ=Asia/Shanghai
      - EXT_IP=192.168.1.218
    network_mode: host
    logging:
      driver: "json-file"
      options:
        max-file: "10"
        max-size: "200m"
    restart: always
    ulimits:
      core: -1
    privileged: true
    stdin_open: true
    tty: true
    volumes:
      - ./conf/:/usr/local/freeswitch/conf/
      - ./log/:/usr/local/freeswitch/log/
```

## Update log

- update project time is: 2024-12-29 17:14:36
- update project time is: 2024-12-29 17:16:02
- update project time is: 2024-12-30 11:00:01
- update project time is: 2024-12-31 11:00:01
- update project time is: 2025-01-01 11:00:01
- update project time is: 2025-01-02 11:00:01
- update project time is: 2025-01-03 11:00:01
- update project time is: 2025-01-04 11:00:01
- update project time is: 2025-01-05 11:00:02
- update project time is: 2025-01-06 11:00:01
- update project time is: 2025-01-07 11:00:01
- update project time is: 2025-01-08 11:00:02
- update project time is: 2025-01-09 11:00:01
- update project time is: 2025-01-10 11:00:01
- update project time is: 2025-01-11 11:00:01
- update project time is: 2025-01-12 11:00:01
- update project time is: 2025-01-14 20:15:01
- update project time is: 2025-01-17 20:23:49
- update project time is: 2025-01-18 11:00:01
- update project time is: 2025-01-19 11:00:01
- update project time is: 2025-01-20 11:00:01
- update project time is: 2025-02-7 11:00:01
- update project time is: 2025-02-9 11:00:01- update project time is: 2025-02-13 09:20:50
- update project time is: 2025-02-13 11:00:01
- update project time is: 2025-02-14 11:00:01
- update project time is: 2025-02-15 11:00:01
- update project time is: 2025-02-16 11:00:01
- update project time is: 2025-02-17 11:00:01
- update project time is: 2025-02-18 11:00:01
- update project time is: 2025-02-19 11:00:01
- update project time is: 2025-02-20 11:00:01
- update project time is: 2025-02-21 11:00:01
- update project time is: 2025-02-22 11:00:01

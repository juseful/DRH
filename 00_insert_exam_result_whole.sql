-- 검사결과(마스터정보 기준, 결과치환 대상 검사, 혈압검사, CaCT Ca Score) Insert, update 실행
-- 검사결과 insert, update
-- 마스터 정보 대상 검사 data insert
-- 메시지 출력기능 추가. 메시지 확인은 F5를 눌러야 가능함
variable var_msg2 char(40);
variable var_msg3 char(40);
  
declare
    incnt     number(10) := 0;
    errcnt    number(10) := 0;
        
begin
for drh in (-- 마스터 정보 기준
            -- 데이터 select
            select a.ptno               as ptno
                 , a.sm_date            as sm_date
                 , a.apnt_no            as apnt_no
                 , a.exmn_typ           as exmn_typ
                 , a.ordr_cd            as ordr_cd
                 , a.ordr_sno           as ordr_sno
                 , a.exmn_cd            as exmn_cd
                 , a.ordr_ymd           as ordr_ymd
                 , a.enfr_dt            as enfr_dt
                 , a.cleaned_vl         as cleaned_vl
                 , a.exrs_ncvl_vl       as exrs_ncvl_vl
                 , a.exrs_unit_nm       as exrs_unit_nm
                 , a.nrml_lwlm_ncvl_vl  as nrml_lwlm_ncvl_vl
                 , a.nrml_uplm_ncvl_vl  as nrml_uplm_ncvl_vl
                 , ''                   as exrs_ctn
                 , ''                   as exrs_info
                 , ''                   as exrs_cnls
                 , ''                   as exrs_comments
                 , a.ver                  as updt_ver
                 , sysdate              as rgst_dt
                 , sysdate              as last_updt_dt
              from (-- 기준치 적용 수치데이터
                    select /*+ INDEX(A 3E3C0E433E3C0E3E28_I02) INDEX(B 3E3243333E2E143C28_PK) INDEX(C 3C15332B3C20431528_PK) index(d 1543294D47144D3C0E3E283343_PK) index(E 3E3C3C5B0C233C3E28_PK) */
                           a.ptno
                         , a.ordr_ymd     sm_date
                         , a.apnt_no
                         , '0'            exmn_typ
                         , c.ordr_sno
                         , c.ordr_cd
                         , b.exmn_cd
                         , c.ordr_ymd     ordr_ymd 
                         , c.enfr_dt
                         , case
                                when 
                           decode(-- 0이 없는 소수점 데이터를 숫자 형태로 변환
                                  REGEXP_REPLACE(
                                                 regexp_replace(
                                                                (
                                                                 case 
                                                                      when b.exrs_ncvl_vl like '.%' then '0'||b.exrs_ncvl_vl
                                                                      else b.exrs_ncvl_vl
                                                                  end 
                                                                )
                                                               ,'^-?[0-9]+((\.[0-9]+)([Ee][+-][0-9]+)?)?'
                                                               )
                                                ,'^-?[0-9]+((\.[0-9]+)([Ee][+-][0-9]+)?)?'
                                                ,''
                                                )
                                 ,'',(
                                      case
                                           when b.exrs_ncvl_vl like '.%' then '0'||b.exrs_ncvl_vl
                                           else b.exrs_ncvl_vl
                                       end 
                                     )
                                 ,''
                                 )
                           between to_number(nvl(d.CLEANED_LWLM_VL,'0')) and to_number(nvl(d.CLEANED_UPLM_VL,'9999999')) 
                                     then
                           decode(-- 0이 없는 소수점 데이터를 숫자 형태로 변환
                                  REGEXP_REPLACE(
                                                 regexp_replace(
                                                                (
                                                                 case 
                                                                      when b.exrs_ncvl_vl like '.%' then '0'||b.exrs_ncvl_vl
                                                                      else b.exrs_ncvl_vl
                                                                  end 
                                                                )
                                                               ,'^-?[0-9]+((\.[0-9]+)([Ee][+-][0-9]+)?)?'
                                                               )
                                                ,'^-?[0-9]+((\.[0-9]+)([Ee][+-][0-9]+)?)?'
                                                ,''
                                                )
                                 ,'',(
                                      case
                                           when b.exrs_ncvl_vl like '.%' then '0'||b.exrs_ncvl_vl
                                           else b.exrs_ncvl_vl
                                       end 
                                     )
                                 ,''
                                 )
                           else ''
                           end
                           cleaned_vl
                         , b.exrs_ncvl_vl
                         , b.exrs_unit_nm
                         , b.nrml_lwlm_ncvl_vl
                         , b.nrml_uplm_ncvl_vl
                         , d.ver /* 마스터 테이블의 버전 정보를 기준으로 적용 */
                         , row_number () over(partition by a.ptno, a.ordr_ymd, b.exmn_cd order by c.enfr_dt desc, c.ordr_sno desc, c.ordr_cd) RN /* 같은 날 중복처방/재검인 경우를 구분하기 위해 실시를 가장 나중에 한 것을 처음으로 가져옴. */
                      from 스키마.3E3C0E433E3C0E3E28@DAWNR_SMCDWS a
                         , 스키마.3E3C3C5B0C233C3E28@DAWNR_SMCDWS e
                         , 스키마.3E3243333E2E143C28@DAWNR_SMCDWS b
                         , 스키마.3C15332B3C20431528@DAWNR_SMCDWS c
                         , 스키마.1543294D47144D3C0E3E283343 d --smcdws.1543294D47144D3C0E3E283343@DAWNR_SMCDWS d -- 또는 스키마.1543294D47144D3C0E3E283343 로 적용해도 됨.
                     where a.ordr_ymd between to_date(&indata_frdt,'yyyymmdd') and to_date(&indata_todt,'yyyymmdd') -- to_date('20220602','yyyymmdd') and to_date('20220602','yyyymmdd')
                       and a.cncl_dt is null
                       and a.pckg_cd = e.pckg_cd
                       and (substr(e.pckg_type_cd,1,1) not in ('6','7','9') -- 생습, 스포츠외래, 서비스 패키지 제외.
                           and -- 제외대상을 포함시에는 and로 걸어야 함.
                            e.pckg_type_cd not in ('5W','5Z') -- 서비스 형태의 특화 패키지 대상자 제외
                           )
                       and a.ptno not in (-- 자료추출 금지 대상자
                                          &not_in_ptno
                                         )
                       and a.ptno = b.ptno
                       and a.ordr_ymd = b.ordr_ymd
                       and b.exmn_cd = d.code
                       and d.ver = '2'
                       and d.code not in (-- 결과치환 검사와 파일 대상 검사 제외
                                          'BL5111','BL5112','BL5113','BL5115','BL5116','BL5117','BL512001'
                                         ,'BL6111','BL6112','BL6115','BL6116','BL6117','BL6118','BL6119','BL6120','BL6121','BL6122'
                                         ,'NR0101','NR0102','NR0103','NR0201','NR0202','NR0305'
                                         ,'RC118401','RC118402','SM0600DBP','SM0600SBP','BL3364','SM053101','SM053111'
                                         ,'SM0132','SM013201','SM0133','SM013301','SM013401','SM0161','SM0162','SM0163','SM0164' -- ver 2.0에서 추가됨
                                         )
                       and nvl(b.exrs_updt_yn,'N') != 'Y'
                       and b.ptno = c.ptno
                       and b.ordr_ymd = c.ordr_ymd
                       and b.ordr_sno = c.ordr_sno
                       and c.codv_cd = 'G'
                       and nvl(c.dc_dvsn_cd,'N') != 'X'
                       and a.apnt_no = c.hlsc_apnt_no 
                   ) a
             where not exists (-- 수진일에 재검으로 발생된 중복 처방 제거를 위해 필요.
                               select /*+ INDEX(X 3E3C3343332B0E3C28_I08) */
                                      'Y'
                                 from 스키마.3E3C3343332B0E3C28@DAWNR_SMCDWS x
                                where a.rn = '1'
                                  and a.ordr_ymd = x.exim_dt
                                  and x.rern_dvsn_cd in ('1','2')
                                  and a.ptno = x.ptno
                                  and a.ordr_cd = x.re_exmn_cd
                              )
    
           )
                
            loop
            begin   -- 데이터 insert
                          insert /*+ append */
                            into 스키마.1543294D47144D43333E2E1428
                                 (
                                   PTNO
                                 , SM_DATE
                                 , APNT_NO
                                 , EXMN_TYP
                                 , ORDR_CD
                                 , ORDR_SNO
                                 , EXMN_CD
                                 , ORDR_YMD
                                 , EXEC_TIME
                                 , CLEANED_NCVL_VL
                                 , EXRS_NCVL_VL
                                 , EXRS_UNIT_NM
                                 , NRML_LWLM_VL
                                 , NRML_UPLM_VL
                                 , EXRS_CTN
                                 , EXRS_INFO
                                 , EXRS_CNLS
                                 , EXRS_COMMENTS
                                 , UPDT_VER
                                 , RGST_DT
                                 , LAST_UPDT_DT
                                 )
                           values(
                                   drh.ptno
                                 , drh.sm_date
                                 , drh.apnt_no
                                 , drh.exmn_typ
                                 , drh.ordr_cd
                                 , drh.ordr_sno
                                 , drh.exmn_cd
                                 , drh.ordr_ymd
                                 , drh.enfr_dt
                                 , drh.cleaned_vl
                                 , drh.exrs_ncvl_vl
                                 , drh.exrs_unit_nm
                                 , drh.nrml_lwlm_ncvl_vl
                                 , drh.nrml_uplm_ncvl_vl
                                 , drh.exrs_ctn
                                 , drh.exrs_info
                                 , drh.exrs_cnls
                                 , drh.exrs_comments
                                 , drh.updt_ver
                                 , drh.rgst_dt
                                 , drh.last_updt_dt
                                 )
                                 ;
                  
                         commit;
                       
                       incnt := incnt + 1;
                  
                       exception
                       when others then
                          rollback;
                          errcnt := errcnt + 1;
            
            end;
            end loop;
       
:var_msg2  := 'insert '  || to_char(incnt)    || ' 건';
:var_msg3  := 'error '   || to_char(errcnt)   || ' 건';
   
end ;
/
print var_msg2
print var_msg3
spool off;
    
-- 결과치환 대상 검사 data insert
variable var_msg2 char(40);
variable var_msg3 char(40);
  
declare
    incnt     number(10) := 0;
    errcnt    number(10) := 0;
        
begin
for drh in (-- 결과치환 대상검사.
            -- 데이터 select
            select a.ptno               as ptno
                 , a.sm_date            as sm_date
                 , a.apnt_no            as apnt_no
                 , a.exmn_typ           as exmn_typ
                 , a.ordr_cd            as ordr_cd
                 , a.ordr_sno           as ordr_sno
                 , a.exmn_cd            as exmn_cd
                 , a.ordr_ymd           as ordr_ymd
                 , a.enfr_dt            as enfr_dt
                 , a.cleaned_vl         as cleaned_vl
                 , a.exrs_ncvl_vl       as exrs_ncvl_vl
                 , a.exrs_unit_nm       as exrs_unit_nm
                 , a.nrml_lwlm_ncvl_vl  as nrml_lwlm_ncvl_vl
                 , a.nrml_uplm_ncvl_vl  as nrml_uplm_ncvl_vl
                 , ''                   as exrs_ctn
                 , ''                   as exrs_info
                 , ''                   as exrs_cnls
                 , ''                   as exrs_comments
                 , '2'                  as updt_ver -- 버전체크는 필수!!!
                 , sysdate              as rgst_dt
                 , sysdate              as last_updt_dt
              from (
                    select /*+ INDEX(A 3E3C0E433E3C0E3E28_I02) INDEX(B 3E3243333E2E143C28_PK) INDEX(C MDEXMOR_PK) INDEX(E 3E3C3C5B0C233C3E28_PK) */
                           a.ptno
                         , a.ordr_ymd     sm_date
                         , a.apnt_no
                         , '0'            exmn_typ
                         , c.ordr_sno
                         , c.ordr_cd
                         , b.exmn_cd
                         , c.ordr_ymd     ordr_ymd 
                         , c.enfr_dt
                         , '' cleaned_vl
                         , b.exrs_ncvl_vl
                         , b.exrs_unit_nm
                         , b.nrml_lwlm_ncvl_vl
                         , b.nrml_uplm_ncvl_vl
                         , row_number () over(partition by a.ptno, a.ordr_ymd, b.exmn_cd order by c.enfr_dt desc, c.ordr_sno desc, c.ordr_cd) RN /* 같은 날 중복처방/재검인 경우를 구분하기 위해 실시를 가장 나중에 한 것을 처음으로 가져옴. */
                      from 스키마.3E3C0E433E3C0E3E28@DAWNR_SMCDWS a
                         , 스키마.3E3243333E2E143C28@DAWNR_SMCDWS b
                         , 스키마.3C15332B3C20431528@DAWNR_SMCDWS c
                         , 스키마.3E3C3C5B0C233C3E28@DAWNR_SMCDWS e
                     where a.ordr_ymd between to_date(&indata_frdt,'yyyymmdd') and to_date(&indata_todt,'yyyymmdd') -- to_date('20220602','yyyymmdd') and to_date('20220602','yyyymmdd')
                       and a.cncl_dt is null
                       and a.pckg_cd = e.pckg_cd
                       and (substr(e.pckg_type_cd,1,1) not in ('6','7','9') -- 생습, 스포츠외래, 서비스 패키지 제외.
                           and -- 제외대상을 포함시에는 and로 걸어야 함. 
                            e.pckg_type_cd not in ('5W','5Z') -- 서비스 형태의 특화 패키지 대상자 제외
                           )
                       and a.ptno not in (-- 자료추출 금지 대상자
                                          &not_in_ptno
                                         )
                       and a.ptno = b.ptno
                       and a.ordr_ymd = b.ordr_ymd
                       and b.exmn_cd in (-- 결과치환 검사와 파일 대상 검사 제외
                                         'BL5111','BL5112','BL5113','BL5115','BL5116','BL5117','BL512001'
                                        ,'BL6111','BL6112','BL6115','BL6116','BL6117','BL6118','BL6119','BL6120','BL6121','BL6122'
                                        ,'NR0101','NR0102','NR0103','NR0201','NR0202','NR0305'
                                        ,'RC118401','RC118402','SM0600DBP','SM0600SBP','BL3364','SM053101','SM053111'
                                        ,'SM0132','SM013201','SM0133','SM013301','SM013401','SM0161','SM0162','SM0163','SM0164' -- ver 2.0에서 추가됨
                                        )
                       and nvl(b.exrs_updt_yn,'N') != 'Y'
                       and b.ptno = c.ptno
                       and b.ordr_ymd = c.ordr_ymd
                       and b.ordr_sno = c.ordr_sno
                       and c.codv_cd = 'G'
                       and nvl(c.dc_dvsn_cd,'N') != 'X'
                       and a.apnt_no = c.hlsc_apnt_no 
                   ) a
             where not exists (/* 수진일에 재검으로 발생된 중복 처방 제거를 위해 필요. */
                               select /*+ INDEX(X 3E3C3343332B0E3C28_I08) */
                                      'Y'
                                 from 스키마.3E3C3343332B0E3C28@DAWNR_SMCDWS x
                                where a.rn = '1'
                                  and a.ordr_ymd = x.exim_dt
                                  and x.rern_dvsn_cd in ('1','2')
                                  and a.ptno = x.ptno
                                  and a.ordr_cd = x.re_exmn_cd
                              )
    
           )
                
            loop
            begin   -- 데이터 insert
                          insert /*+ append */
                            into 스키마.1543294D47144D43333E2E1428
                                 (
                                   PTNO
                                 , SM_DATE
                                 , APNT_NO
                                 , EXMN_TYP
                                 , ORDR_CD
                                 , ORDR_SNO
                                 , EXMN_CD
                                 , ORDR_YMD
                                 , EXEC_TIME
                                 , CLEANED_NCVL_VL
                                 , EXRS_NCVL_VL
                                 , EXRS_UNIT_NM
                                 , NRML_LWLM_VL
                                 , NRML_UPLM_VL
                                 , EXRS_CTN
                                 , EXRS_INFO
                                 , EXRS_CNLS
                                 , EXRS_COMMENTS
                                 , UPDT_VER
                                 , RGST_DT
                                 , LAST_UPDT_DT
                                 )
                           values(
                                   drh.ptno
                                 , drh.sm_date
                                 , drh.apnt_no
                                 , drh.exmn_typ
                                 , drh.ordr_cd
                                 , drh.ordr_sno
                                 , drh.exmn_cd
                                 , drh.ordr_ymd
                                 , drh.enfr_dt
                                 , drh.cleaned_vl
                                 , drh.exrs_ncvl_vl
                                 , drh.exrs_unit_nm
                                 , drh.nrml_lwlm_ncvl_vl
                                 , drh.nrml_uplm_ncvl_vl
                                 , drh.exrs_ctn
                                 , drh.exrs_info
                                 , drh.exrs_cnls
                                 , drh.exrs_comments
                                 , drh.updt_ver
                                 , drh.rgst_dt
                                 , drh.last_updt_dt
                                 )
                                 ;
                  
                         commit;
                       
                       incnt := incnt + 1;
                  
                       exception
                       when others then
                          rollback;
                          errcnt := errcnt + 1;
            
            end;
            end loop;
       
:var_msg2  := 'insert '  || to_char(incnt)    || ' 건';
:var_msg3  := 'error '   || to_char(errcnt)   || ' 건';
   
end ;
/
print var_msg2
print var_msg3
spool off;
    
-- 결과치환 대상 검사 data update
begin
-- BL6111
update 스키마.1543294D47144D43333E2E1428 B
   set cleaned_ncvl_vl = 
                          (
                           case
                                when lower(b.exrs_ncvl_vl) like 'am%'    then '1'
                                when lower(b.exrs_ncvl_vl) like 'br%'    then '2'
                                when lower(b.exrs_ncvl_vl) like 'gr%'    then '3'
                                when lower(b.exrs_ncvl_vl) like 'or%'    then '4'
                                when lower(b.exrs_ncvl_vl) like 're%'    then '5'
                                when (lower(b.exrs_ncvl_vl) like '%st%'
                                     or
                                      lower(b.exrs_ncvl_vl) like '%sr%'
                                     )                                   then '6' -- 검증 후 수정
                                when lower(b.exrs_ncvl_vl) like 'ye%'    then '7'
                                when (lower(b.exrs_ncvl_vl) like 'milky%'
                                     or
                                      lower(b.exrs_ncvl_vl) like 'color%'
                                     or
                                      lower(b.exrs_ncvl_vl) like 'whi%'
                                     or
                                      lower(b.exrs_ncvl_vl) like 'other%'
                                     )                                   then '8'
                           else ''
                           end  
                          )
where sm_date between to_date(&indata_frdt,'yyyymmdd') and to_date(&indata_todt,'yyyymmdd')
  and exmn_cd = 'BL6111'
             ;
                  
commit;
   
end ;
/
spool off;
    
-- 결과치환 대상 검사 data update
begin
-- BL6112
update 스키마.1543294D47144D43333E2E1428 B
   set cleaned_ncvl_vl = 
                          (
                           case
                                when (lower(b.exrs_ncvl_vl) like '%ea%'
                                     or
                                      lower(b.exrs_ncvl_vl) like '%ae%'
                                     )                                    then '1'
                                when lower(b.exrs_ncvl_vl) like '%ou%'    then '2'
                           else '3'
                           end  
                          )
 where sm_date between to_date(&indata_frdt,'yyyymmdd') and to_date(&indata_todt,'yyyymmdd')
   and exmn_cd = 'BL6112'
             ;
                  
commit;
   
end ;
/
spool off;
    
-- 결과치환 대상 검사 data update
begin
-- BL6115
update 스키마.1543294D47144D43333E2E1428 B
   set cleaned_ncvl_vl = 
                          (
                           case
                                when lower(b.exrs_ncvl_vl) like 'ne%'     then '0' -- 검증 후 수정
                                when lower(b.exrs_ncvl_vl) like '%25%tr%' then '0.5'
                                when lower(b.exrs_ncvl_vl) like '75%'   then '1'
                                when lower(b.exrs_ncvl_vl) like '150%'    then '2'
                                when lower(b.exrs_ncvl_vl) like '500%'    then '3'
                           else ''
                           end  
                          )
 where sm_date between to_date(&indata_frdt,'yyyymmdd') and to_date(&indata_todt,'yyyymmdd')
   and exmn_cd = 'BL6115'
             ;
                  
commit;
   
end ;
/
spool off;
    
-- 결과치환 대상 검사 data update
begin
-- BL6116
update 스키마.1543294D47144D43333E2E1428 B
   set cleaned_ncvl_vl = 
                          (
                           case
                                when lower(b.exrs_ncvl_vl) like 'n%'      then '0'
                                when lower(b.exrs_ncvl_vl) like '%50%tr%' then '0.5'
                                when lower(b.exrs_ncvl_vl) like '1000%'   then '3'
                                when lower(b.exrs_ncvl_vl) like '100%'    then '1'
                                when lower(b.exrs_ncvl_vl) like '300%'    then '2'
                           else ''
                           end  
                          )
 where sm_date between to_date(&indata_frdt,'yyyymmdd') and to_date(&indata_todt,'yyyymmdd')
   and exmn_cd = 'BL6116'
             ;
                  
commit;
   
end ;
/
spool off;
    
-- 결과치환 대상 검사 data update
begin
-- BL6117
update 스키마.1543294D47144D43333E2E1428 B
   set cleaned_ncvl_vl = 
                          (
                           case
                                when lower(b.exrs_ncvl_vl) like 'n%'     then '0'
                                when lower(b.exrs_ncvl_vl) like '%5%tr%' then '0.5'
                                when lower(b.exrs_ncvl_vl) like '150%'   then '3'
                                when lower(b.exrs_ncvl_vl) like '15%'    then '1'
                                when lower(b.exrs_ncvl_vl) like '50%'    then '2'
                           else ''
                           end  
                          )
 where sm_date between to_date(&indata_frdt,'yyyymmdd') and to_date(&indata_todt,'yyyymmdd')
   and exmn_cd = 'BL6117'
             ;
                  
commit;
   
end ;
/
spool off;
    
-- 결과치환 대상 검사 data update
begin
-- BL6118
update 스키마.1543294D47144D43333E2E1428 B
   set cleaned_ncvl_vl = 
                          (
                           case
                                when lower(b.exrs_ncvl_vl) like 'n%'    then '0'
                                when lower(b.exrs_ncvl_vl) like '10%'    then '' -- 검증 후 수정
                                when lower(b.exrs_ncvl_vl) like '1%'    then '1'
                                when lower(b.exrs_ncvl_vl) like '3%'    then '2'
                                when lower(b.exrs_ncvl_vl) like '6%'    then '3'
                           else ''
                           end  
                          )
 where sm_date between to_date(&indata_frdt,'yyyymmdd') and to_date(&indata_todt,'yyyymmdd')
   and exmn_cd = 'BL6118'
             ;
                  
commit;
   
end ;
/
spool off;
    
-- 결과치환 대상 검사 data update
begin
-- BL6119
update 스키마.1543294D47144D43333E2E1428 B
   set cleaned_ncvl_vl = 
                          (
                           case
                                when lower(b.exrs_ncvl_vl) like 'n%'        then '0'
                                when lower(b.exrs_ncvl_vl) like '%10%tr%'   then '0.5'
                                when replace(lower(b.exrs_ncvl_vl),' ','') = '50+'      then '' -- 검증 후 수정
                                when replace(lower(b.exrs_ncvl_vl),' ','') like '500%'      then '' -- 검증 후 수정
                                when lower(b.exrs_ncvl_vl) like '50%'       then '2'
                                when replace(lower(b.exrs_ncvl_vl),' ','') = '150++'    then '' -- 검증 후 수정
                                when lower(b.exrs_ncvl_vl) like '150%'      then '3'
                                when (replace(lower(b.exrs_ncvl_vl),' ','')  like '250+++++'
                                     or
                                      replace(lower(b.exrs_ncvl_vl),' ','')  like '250+++'
                                     )                                      then '' -- 검증 후 수정
                                when lower(b.exrs_ncvl_vl) like '%250%'      then '4' -- 검증 후 수정
                                when (lower(b.exrs_ncvl_vl) like '25%++'
                                     or
                                      lower(b.exrs_ncvl_vl) like '25%tr'
                                     or
                                      lower(b.exrs_ncvl_vl) like '25%-'
                                     )                                      then '' -- 검증 후 수정
                                when lower(b.exrs_ncvl_vl) like '%25%'       then '1' -- 검증 후 수정
                           else ''
                           end  
                          )
 where sm_date between to_date(&indata_frdt,'yyyymmdd') and to_date(&indata_todt,'yyyymmdd')
   and exmn_cd = 'BL6119'
             ;
                  
commit;
   
end ;
/
spool off;
    
-- 결과치환 대상 검사 data update
begin
-- BL6120
update 스키마.1543294D47144D43333E2E1428 B
   set cleaned_ncvl_vl = 
                          (
                           case
                                when (lower(b.exrs_ncvl_vl) like 'n%'
                                     or
                                      lower(b.exrs_ncvl_vl) like '%rm%'
                                     )                                    then '0'
                                when lower(b.exrs_ncvl_vl) like '1%tr%'   then '0.5'
                                when lower(b.exrs_ncvl_vl) like '4%'      then '1'
                                when lower(b.exrs_ncvl_vl) like '8%'      then '2'
                                when lower(b.exrs_ncvl_vl) like '12%'     then '3'
                           else ''
                           end  
                          )
 where sm_date between to_date(&indata_frdt,'yyyymmdd') and to_date(&indata_todt,'yyyymmdd')
   and exmn_cd = 'BL6120'
             ;
                  
commit;
   
end ;
/
spool off;
    
-- 결과치환 대상 검사 data update
begin
-- BL6121
update 스키마.1543294D47144D43333E2E1428 B
   set cleaned_ncvl_vl = 
                          (
                           case
                                when (lower(b.exrs_ncvl_vl) like '%ne%'
                                     or
                                      lower(b.exrs_ncvl_vl) like '%rg%'
                                     )                                   then '0'
                                when lower(b.exrs_ncvl_vl) like 'p%-%'   then '' -- 검증 후 수정
                                when lower(b.exrs_ncvl_vl) like '%p%'     then '1' -- 검증 후 수정
                           else ''
                           end  
                          )
 where sm_date between to_date(&indata_frdt,'yyyymmdd') and to_date(&indata_todt,'yyyymmdd')
   and exmn_cd = 'BL6121'
             ;
                  
commit;
   
end ;
/
spool off;
    
-- 결과치환 대상 검사 data update
begin
-- BL6122
update 스키마.1543294D47144D43333E2E1428 B
   set cleaned_ncvl_vl = 
                          (
                           case
                                when (lower(b.exrs_ncvl_vl) like 'n%'
                                     or
                                      lower(b.exrs_ncvl_vl) like '%g%'
                                     or
                                      lower(b.exrs_ncvl_vl) like '%wbc%'
                                     )                                     then '0'
                                when (replace(lower(b.exrs_ncvl_vl),' ','') like '25++'
                                     or
                                      replace(lower(b.exrs_ncvl_vl),' ','') like '25tr'
                                     or
                                      substr(lower(b.exrs_ncvl_vl),1,instr(lower(b.exrs_ncvl_vl),' ')-1) = '250'
                                     or
                                      lower(b.exrs_ncvl_vl) = '25'
                                     )                                     then ''
                                when lower(b.exrs_ncvl_vl) like '%2%'       then '1'
                                when substr(lower(b.exrs_ncvl_vl),1,instr(lower(b.exrs_ncvl_vl),' ')-1) = '10'      then ''
                                when (replace(lower(b.exrs_ncvl_vl),' ','') = '100+'
                                     or
                                      replace(lower(b.exrs_ncvl_vl),' ','') = '100+++'
                                     )                                      then ''
                                when lower(b.exrs_ncvl_vl) like '100%'      then '2'
                                when substr(lower(b.exrs_ncvl_vl),1,instr(lower(b.exrs_ncvl_vl),' ')-1) = '50'      then ''
                                when replace(lower(b.exrs_ncvl_vl),' ','') = '500++'      then ''
                                when lower(b.exrs_ncvl_vl) like '500%'      then '3'
                           else ''
                           end  
                          )
 where sm_date between to_date(&indata_frdt,'yyyymmdd') and to_date(&indata_todt,'yyyymmdd')
   and exmn_cd = 'BL6122'
             ;
                  
commit;
   
end ;
/
spool off;
    
-- 결과치환 대상 검사 data update
begin
-- Hepatitis
update 스키마.1543294D47144D43333E2E1428 B
   set cleaned_ncvl_vl = 
                          (
                           case
                                when (lower(b.exrs_ncvl_vl) like '%e%g%'
                                     or
                                      lower(b.exrs_ncvl_vl) like 'n%'
                                     )                                    then '0' -- 검증 후 수정
                                when (lower(b.exrs_ncvl_vl) like 'w%'     
                                     or
                                      lower(b.exrs_ncvl_vl) like 'b%'     
                                     )                                   then '0.5' -- 결과보고 형식변경으로 추가됨. 230627
                                when (lower(b.exrs_ncvl_vl) like 'p%'     
                                     or
                                      lower(b.exrs_ncvl_vl) like 'r%'     
                                     )                                   then '1' -- 결과보고 형식변경으로 추가됨. 230627
                           else ''
                           end  
                          )
 where sm_date between to_date(&indata_frdt,'yyyymmdd') and to_date(&indata_todt,'yyyymmdd')
   and exmn_cd in (
                  'BL5111','BL5112','BL5113','BL5115','BL5116','BL5117','BL512001'
                 ,'NR0101','NR0102','NR0103','NR0201','NR0202','NR0305'
                 )
             ;
                  
commit;
   
end ;
/
spool off;
    
-- 결과치환 대상 검사 data update
begin
-- SM0132, SM0133, SM053101, SM053111
update 스키마.1543294D47144D43333E2E1428 B
   set b.cleaned_ncvl_vl = b.exrs_ncvl_vl
where sm_date between to_date(&indata_frdt,'yyyymmdd') and to_date(&indata_todt,'yyyymmdd')
  and exmn_cd in ('SM0132','SM0133','SM053101', 'SM053111')
             ;
                  
commit;
   
end ;
/
spool off;
    
-- 결과치환 대상 검사 data update
begin
-- SM013201
update 스키마.1543294D47144D43333E2E1428 B
   set cleaned_ncvl_vl = 
                          (
                           case
                                when lower(b.exrs_ncvl_vl) like '%표준%'    then '1'
                                when lower(b.exrs_ncvl_vl) like '%저체중%'    then '0'
                                when lower(b.exrs_ncvl_vl) like '%과체중%'    then '2'
                           else ''
                           end  
                          )
where sm_date between to_date(&indata_frdt,'yyyymmdd') and to_date(&indata_todt,'yyyymmdd')
  and exmn_cd = 'SM013201'
             ;
                  
commit;
   
end ;
/
spool off;
    
-- 결과치환 대상 검사 data update
begin
-- SM013301, SM013401
update 스키마.1543294D47144D43333E2E1428 B
   set cleaned_ncvl_vl = 
                          (
                           case
                                when lower(b.exrs_ncvl_vl) like '%표준%'    then '1'
                                when lower(b.exrs_ncvl_vl) like '%적음%'    then '0'
                                when lower(b.exrs_ncvl_vl) like '%많음%'    then '2'
                           else ''
                           end  
                          )
where sm_date between to_date(&indata_frdt,'yyyymmdd') and to_date(&indata_todt,'yyyymmdd')
  and exmn_cd in ('SM013301','SM013401')
             ;
                  
commit;
   
end ;
/
spool off;
    
-- 결과치환 대상 검사 data update
begin
-- SM0161, SM0162
update 스키마.1543294D47144D43333E2E1428 B
   set cleaned_ncvl_vl = 
                          (
                           case
                                when lower(b.exrs_ncvl_vl) like '%표준%'    then '1'
                                when lower(b.exrs_ncvl_vl) like '%허약%'    then '0'
                                when lower(b.exrs_ncvl_vl) like '%발달%'    then '2'
                           else ''
                           end  
                          )
where sm_date between to_date(&indata_frdt,'yyyymmdd') and to_date(&indata_todt,'yyyymmdd')
  and exmn_cd in ('SM0161','SM0162')
             ;
                  
commit;
   
end ;
/
spool off;
    
-- 결과치환 대상 검사 data update
begin
-- SM0163, SM0164
update 스키마.1543294D47144D43333E2E1428 B
   set cleaned_ncvl_vl = 
                          (
                           case
                                when lower(b.exrs_ncvl_vl) = '균형'    then '0'
                                when lower(b.exrs_ncvl_vl) like '%약간%'    then '1'
                                when lower(b.exrs_ncvl_vl) like '%심한%'    then '2'
                           else ''
                           end  
                          )
where sm_date between to_date(&indata_frdt,'yyyymmdd') and to_date(&indata_todt,'yyyymmdd')
  and exmn_cd in ('SM0163','SM0164')
             ;
                  
commit;
   
end ;
/
spool off;

-- calculated data update
begin
   
-- PT sec, INR result update
update 스키마.1543294D47144D43333E2E1428 b
   set b.cleaned_ncvl_vl = null
     , b.last_updt_dt = sysdate
 where exists (
select a.*
  from (
        select a.*
             , nullif(nvl(to_number(a.pt_or),0),0)/nullif(nvl(to_number(a.inr_or),0),0) calvl
          from (   
                select a.PTNO
                     , a.sm_date
                     , a.APNT_NO
                     , a.EXMN_TYP
                     , a.ORDR_CD
                     , a.ORDR_SNO
                     , a.ordr_ymd
                     , a.exec_time
                     , max(decode(a.exmn_cd,'BL211101',a.CLEANED_NCVL_VL,'')) PT_CLEANED
                     , max(decode(a.exmn_cd,'BL211101',a.EXRS_NCVL_VL,'')) PT_OR
                     , max(decode(a.exmn_cd,'BL211103',a.CLEANED_NCVL_VL,'')) INR_CLEANED
                     , max(decode(a.exmn_cd,'BL211103',a.EXRS_NCVL_VL,'')) INR_OR
                  from 스키마.1543294D47144D43333E2E1428 a
                 where sm_date between to_date(&indata_frdt,'yyyymmdd') and to_date(&indata_todt,'yyyymmdd')
                    and a.exmn_cd in ('BL211101','BL211103')
                 group by a.PTNO
                     , a.sm_date
                     , a.APNT_NO
                     , a.EXMN_TYP
                     , a.ORDR_CD
                     , a.ORDR_SNO
                     , a.ordr_ymd
                     , a.exec_time
               ) a
       ) a
 where (a.calvl > 20
       or
        a.calvl is null
       )
                  and b.ptno = a.ptno
                  and b.sm_date = a.sm_date
                  and b.apnt_no = a.apnt_no
                  and b.ordr_sno = a.ordr_sno
                  and b.exmn_cd in ('BL211101','BL211103')
              )
             ;
                 
commit;
   
end ;
/
spool off;
   
-- calculated data update
begin
   
-- Vitamin D 오류값 update
update 스키마.1543294D47144D43333E2E1428 b
   set b.cleaned_ncvl_vl = (
                            select max(decode(X.exmn_cd,'BL399201',X.CLEANED_NCVL_VL,'')) 
                                  +max(decode(X.exmn_cd,'BL399202',X.CLEANED_NCVL_VL,''))
                              from 스키마.1543294D47144D43333E2E1428 x
                             where x.exmn_cd in ('BL399201','BL399202')
                               and B.PTNO = x.ptno
                               and b.sm_date = x.sm_date
                               and b.apnt_no = x.apnt_no                             
                           )
     , B.LAST_UPDT_DT = sysdate
 where exists 
       (-- Vitamin D
        select 'y'
          from (
                select a.ptno, a.sm_date, a.apnt_no, a.ordr_cd, A.ORDR_SNO
                     , max(decode(a.exmn_cd,'BL399201',A.CLEANED_NCVL_VL,'')) BL399201
                     , max(decode(a.exmn_cd,'BL399201',A.EXRS_NCVL_VL,''))    BL399201_O
                     , max(decode(a.exmn_cd,'BL399202',A.CLEANED_NCVL_VL,'')) BL399202
                     , max(decode(a.exmn_cd,'BL399202',A.EXRS_NCVL_VL,''))    BL399202_O
                     , max(decode(a.exmn_cd,'BL399203',A.CLEANED_NCVL_VL,'')) BL399203
                     , max(decode(a.exmn_cd,'BL399203',A.EXRS_NCVL_VL,''))    BL399203_O
                     , max(decode(a.exmn_cd,'BL399201',A.CLEANED_NCVL_VL,'')) 
                      +max(decode(a.exmn_cd,'BL399202',A.CLEANED_NCVL_VL,'')) calvl
                     , case
                            when max(decode(a.exmn_cd,'BL399201',A.CLEANED_NCVL_VL,'')) 
                                +max(decode(a.exmn_cd,'BL399202',A.CLEANED_NCVL_VL,''))
                               !=max(decode(a.exmn_cd,'BL399203',A.CLEANED_NCVL_VL,'')) 
                            then 'Y'
                       else 'N'
                       end erroryn
                  from 스키마.1543294D47144D43333E2E1428 a
                 where a.sm_date between to_date(&indata_frdt,'yyyymmdd') and to_date(&indata_todt,'yyyymmdd')
                   and a.ordr_cd like 'BL3992'
                 group by a.ptno, a.sm_date, a.apnt_no, a.ordr_cd, A.ORDR_SNO
               ) a
         where a.erroryn = 'Y'
           and b.ptno = a.ptno
           and b.sm_date = a.sm_date
           and b.apnt_no = a.apnt_no
       )
   and b.exmn_cd like 'BL399203%'
             ;
                 
commit;
   
end ;
/
spool off;
   
-- calculated data update
begin
   
-- HBs NR 오류값 update
update 스키마.1543294D47144D43333E2E1428 b
   set b.cleaned_ncvl_vl = null
     , B.LAST_UPDT_DT = sysdate
 where exists 
       (-- HBs NR
        select *
          from (
                select a.ptno, a.sm_date, a.apnt_no, a.ordr_cd, A.ORDR_SNO
                     , max(decode(a.exmn_cd,'NR0101',A.CLEANED_NCVL_VL,'')) NR0101
                     , max(decode(a.exmn_cd,'NR0102',A.CLEANED_NCVL_VL,'')) NR0102
                     , max(decode(a.exmn_cd,'NR0103',A.CLEANED_NCVL_VL,'')) NR0103
                     , max(decode(a.exmn_cd,'NR0101',A.EXRS_NCVL_VL,'')) NR0101_O
                     , max(decode(a.exmn_cd,'NR0102',A.EXRS_NCVL_VL,'')) NR0102_O
                     , max(decode(a.exmn_cd,'NR0103',A.EXRS_NCVL_VL,'')) NR0103_O
                     , case
                            when max(decode(a.exmn_cd,'NR0101',A.CLEANED_NCVL_VL,'')) = 1
                             and 
                                 max(decode(a.exmn_cd,'NR0102',A.CLEANED_NCVL_VL,'')) = 1
                             and 
                                 max(decode(a.exmn_cd,'NR0103',A.CLEANED_NCVL_VL,'')) = 0 
                            then 'Y'
                       else 'N'
                       end erroryn
                  from 스키마.1543294D47144D43333E2E1428 a
                 where a.sm_date between to_date(&indata_frdt,'yyyymmdd') and to_date(&indata_todt,'yyyymmdd')
                   and a.ordr_cd like 'NR01%'
                 group by a.ptno, a.sm_date, a.apnt_no, a.ordr_cd, A.ORDR_SNO
               ) a
         where a.erroryn = 'Y'
           and b.ptno = a.ptno
           and b.sm_date = a.sm_date
           and b.apnt_no = a.apnt_no
       )
   and b.exmn_cd like 'NR01%'
             ;
                 
commit;
   
end ;
/
spool off;
   
-- calculated data update
begin
   
-- BUN/Cr ratio 오류값 update
update 스키마.1543294D47144D43333E2E1428 b
   set b.cleaned_ncvl_vl = (
                            select round(
                                         max(decode(x.exmn_cd,'BL3119',x.CLEANED_NCVL_VL,'')) 
                                        /max(decode(x.exmn_cd,'BL3120',x.CLEANED_NCVL_VL,''))
                                        ,1 
                                        )
                              from 스키마.1543294D47144D43333E2E1428 x
                             where B.PTNO = x.ptno
                               and b.sm_date = x.sm_date
                               and b.apnt_no = x.apnt_no
                               and b.exec_time = x.exec_time
                               and x.exmn_cd in ('BL3119','BL3120')
                           )
     , B.LAST_UPDT_DT = sysdate
 where exists 
       (-- BUN/Cr ratio
        select *
          from (
                select a.ptno, a.sm_date, a.apnt_no, a.ordr_cd, A.ORDR_SNO, a.exec_time
                     , max(decode(a.exmn_cd,'BL3119',A.EXRS_NCVL_VL,'')) BL3119
                     , max(decode(a.exmn_cd,'BL3120',A.EXRS_NCVL_VL,'')) BL3120
                     , max(decode(a.exmn_cd,'BL312001',A.EXRS_NCVL_VL,'')) BL312001
                     , round(
                             max(decode(a.exmn_cd,'BL3119',A.CLEANED_NCVL_VL,'')) 
                            /max(decode(a.exmn_cd,'BL3120',A.CLEANED_NCVL_VL,''))
                            ,1 
                            ) calvl
                     , case
                            when 
                                 ROUND(
                                       max(decode(a.exmn_cd,'BL3119',A.CLEANED_NCVL_VL,'')) 
                                      /max(decode(a.exmn_cd,'BL3120',A.CLEANED_NCVL_VL,''))
                                      ,1
                                      ) 
                                !=nvl(
                                      max(decode(a.exmn_cd,'BL312001',A.EXRS_NCVL_VL,''))
                                     ,0
                                     )
                            then 'Y'
                       else 'N'
                       end erroryn
                  from 스키마.1543294D47144D43333E2E1428 a
                 where 
                       a.sm_date between to_date(&indata_frdt,'yyyymmdd') and to_date(&indata_todt,'yyyymmdd')
                   and a.exmn_cd in ('BL3119','BL3120','BL312001')
                 group by a.ptno, a.sm_date, a.apnt_no, a.ordr_cd, A.ORDR_SNO, a.exec_time
               ) a
         where a.erroryn = 'Y'
           and b.ptno = a.ptno
           and b.sm_date = a.sm_date
           and b.apnt_no = a.apnt_no
       )
   and b.exmn_cd = 'BL312001'
             ;
                 
commit;
   
end ;
/
spool off;
   
-- calculated data update
begin
   
-- URINE Albumin/Cr ratio 오류값 update
update 스키마.1543294D47144D43333E2E1428 b
   set b.cleaned_ncvl_vl = (
                            select round(
                                         max(decode(x.exmn_cd,'BL3252',x.CLEANED_NCVL_VL,'')) 
                                        /max(decode(x.exmn_cd,'BL3249',x.CLEANED_NCVL_VL,''))*1000
                                        ,2
                                        )
                              from 스키마.1543294D47144D43333E2E1428 x
                             where B.PTNO = x.ptno
                               and b.sm_date = x.sm_date
                               and b.apnt_no = x.apnt_no
                               and b.exec_time = x.exec_time
                               and x.exmn_cd in ('BL3249','BL3252')
                           )
     , B.LAST_UPDT_DT = sysdate
 where exists 
       (-- URINE Albumin/Cr ratio
        select *
          from (
                select a.ptno, a.sm_date, a.apnt_no, a.ordr_cd, A.ORDR_SNO, A.EXEC_TIME
                     , max(decode(a.exmn_cd,'BL3249',A.CLEANED_NCVL_VL,'')) BL3249
                     , max(decode(a.exmn_cd,'BL3252',A.CLEANED_NCVL_VL,'')) BL3252
                     , max(decode(a.exmn_cd,'BL326501',A.CLEANED_NCVL_VL,'')) BL326501
                     , max(decode(a.exmn_cd,'BL3249',A.EXRS_NCVL_VL,'')) BL3249_O
                     , max(decode(a.exmn_cd,'BL3252',A.EXRS_NCVL_VL,'')) BL3252_O
                     , max(decode(a.exmn_cd,'BL326501',A.EXRS_NCVL_VL,'')) BL326501_O
                     , ROUND(
                             max(decode(a.exmn_cd,'BL3252',A.EXRS_NCVL_VL,''))/
                             max(decode(a.exmn_cd,'BL3249',A.EXRS_NCVL_VL,''))*1000
                            ,2 
                            )calvl
                     , case
                            when max(decode(a.exmn_cd,'BL326501',A.EXRS_NCVL_VL,''))
                                -ROUND(
                                       (max(decode(a.exmn_cd,'BL3252',A.EXRS_NCVL_VL,''))/
                                        max(decode(a.exmn_cd,'BL3249',A.EXRS_NCVL_VL,''))*1000
                                       )
                                      ,2
                                      ) > 0.1
                            then 'Y'
                       else 'N'
                       end erroryn
                  from 스키마.1543294D47144D43333E2E1428 a
                 where a.sm_date between to_date(&indata_frdt,'yyyymmdd') and to_date(&indata_todt,'yyyymmdd')
                   and a.ordr_cd like 'BL32%'
                 group by a.ptno, a.sm_date, a.apnt_no, a.ordr_cd, A.ORDR_SNO, A.EXEC_TIME
               ) a
         where a.erroryn = 'Y'
           and b.ptno = a.ptno
           and b.sm_date = a.sm_date
           and b.apnt_no = a.apnt_no
       )
   and b.exmn_cd = 'BL326501'
             ;
                 
commit;
   
end ;
/
spool off;

    
-- systolic BP data insert
-- 메시지 출력기능 추가. 메시지 확인은 F5를 눌러야 가능함
variable var_msg2 char(40);
variable var_msg3 char(40);
  
declare
    incnt     number(10) := 0;
    errcnt    number(10) := 0;
        
begin
for drh in (-- 마스터 정보 기준
            -- 데이터 select
            select a.ptno               as ptno
                 , a.sm_date            as sm_date
                 , a.apnt_no            as apnt_no
                 , a.exmn_typ           as exmn_typ
                 , a.ordr_cd            as ordr_cd
                 , a.ordr_sno           as ordr_sno
                 , a.exmn_cd            as exmn_cd
                 , a.ordr_ymd           as ordr_ymd
                 , a.enfr_dt            as enfr_dt
                 , a.cleaned_vl         as cleaned_vl
                 , a.exrs_ncvl_vl       as exrs_ncvl_vl
                 , a.exrs_unit_nm       as exrs_unit_nm
                 , ''                   as nrml_lwlm_ncvl_vl
                 , ''                   as nrml_uplm_ncvl_vl
                 , ''                   as exrs_ctn
                 , ''                   as exrs_info
                 , ''                   as exrs_cnls
                 , ''                   as exrs_comments
                 , '2.0'                  as updt_ver
                 , sysdate              as rgst_dt
                 , sysdate              as last_updt_dt
              from (-- Systolic BP 데이터
                    select a.ptno
                         , a.sm_date
                         , a.apnt_no
                         , a.exmn_typ
                         , a.ordr_cd
                         , a.ordr_sno
                         , a.exmn_Cd
                         , a.ordr_ymd
                         , a.enfr_dt
                         , round((nvl(a.sm0600,0)+nvl(a.sm0601,0)+nvl(a.sm0602,0)+nvl(a.sm0603,0)+nvl(a.sm0604,0)
                                 +nvl(a.sm0605,0)+nvl(a.sm0606,0)+nvl(a.sm0607,0)+nvl(a.sm0608,0)+nvl(a.sm0609,0)
                                 )/a.cnt) cleaned_vl
                         , a.exrs_ncvl_vl
                         , 'mmHg' exrs_unit_nm
                      from (
                            select /*+ INDEX(A 3E3C0E433E3C0E3E28_I02) index(b 3E3C3C5B0C233C3E28_PK) INDEX(c 3E3243333E2E143C28_PK) INDEX(d 3C15332B3C20431528_PK) */
                                   a.ptno
--                                 , to_char(a.ordr_ymd,'yyyy-mm-dd') sm_date
                                 , a.ordr_ymd sm_date
                                 , a.apnt_no
                                 , d.ordr_cd
                                 , '0' exmn_typ
                                 , c.ordr_sno
                                 , 'SM0600SBP' exmn_cd
--                                 , to_char(c.ordr_ymd,'yyyy-mm-dd') ordr_ymd
                                 , c.ordr_ymd
--                                 , to_char(d.enfr_dt,'yyyy-mm-dd hh24:mi:ss') exec_time
                                 , d.enfr_dt
                                 , c.exrs_ncvl_vl
                    --             , substr(c.exrs_ncvl_vl,1,instr(c.exrs_ncvl_vl,'/')-1) SM0600
                                 , (
                                    select max(substr(x.exrs_ncvl_vl,1,instr(x.exrs_ncvl_vl,'/')-1))
                                      from 스키마.3E3243333E2E143C28@DAWNR_SMCDWS x
                                     where x.ptno = a.ptno
                                       and x.ordr_ymd = a.ordr_ymd
                                       and x.exmn_cd = 'SM0600'
                                       and nvl(x.exrs_updt_yn,'N') != 'Y'
                                   ) SM0600
                                 , (
                                    select max(substr(x.exrs_ncvl_vl,1,instr(x.exrs_ncvl_vl,'/')-1))
                                      from 스키마.3E3243333E2E143C28@DAWNR_SMCDWS x
                                     where x.ptno = a.ptno
                                       and x.ordr_ymd = a.ordr_ymd
                                       and x.exmn_cd = 'SM0601'
                                       and nvl(x.exrs_updt_yn,'N') != 'Y'
                                   ) SM0601
                                 , (
                                    select max(substr(x.exrs_ncvl_vl,1,instr(x.exrs_ncvl_vl,'/')-1))
                                      from 스키마.3E3243333E2E143C28@DAWNR_SMCDWS x
                                     where x.ptno = a.ptno
                                       and x.ordr_ymd = a.ordr_ymd
                                       and x.exmn_cd = 'SM0602'
                                       and nvl(x.exrs_updt_yn,'N') != 'Y'
                                   ) SM0602
                                 , (
                                    select max(substr(x.exrs_ncvl_vl,1,instr(x.exrs_ncvl_vl,'/')-1))
                                      from 스키마.3E3243333E2E143C28@DAWNR_SMCDWS x
                                     where x.ptno = a.ptno
                                       and x.ordr_ymd = a.ordr_ymd
                                       and x.exmn_cd = 'SM0603'
                                       and nvl(x.exrs_updt_yn,'N') != 'Y'
                                   ) SM0603
                                 , (
                                    select max(substr(x.exrs_ncvl_vl,1,instr(x.exrs_ncvl_vl,'/')-1))
                                      from 스키마.3E3243333E2E143C28@DAWNR_SMCDWS x
                                     where x.ptno = a.ptno
                                       and x.ordr_ymd = a.ordr_ymd
                                       and x.exmn_cd = 'SM0604'
                                       and nvl(x.exrs_updt_yn,'N') != 'Y'
                                   ) SM0604
                                 , (
                                    select max(substr(x.exrs_ncvl_vl,1,instr(x.exrs_ncvl_vl,'/')-1))
                                      from 스키마.3E3243333E2E143C28@DAWNR_SMCDWS x
                                     where x.ptno = a.ptno
                                       and x.ordr_ymd = a.ordr_ymd
                                       and x.exmn_cd = 'SM0605'
                                       and nvl(x.exrs_updt_yn,'N') != 'Y'
                                   ) SM0605
                                 , (
                                    select max(substr(x.exrs_ncvl_vl,1,instr(x.exrs_ncvl_vl,'/')-1))
                                      from 스키마.3E3243333E2E143C28@DAWNR_SMCDWS x
                                     where x.ptno = a.ptno
                                       and x.ordr_ymd = a.ordr_ymd
                                       and x.exmn_cd = 'SM0606'
                                       and nvl(x.exrs_updt_yn,'N') != 'Y'
                                   ) SM0606
                                 , (
                                    select max(substr(x.exrs_ncvl_vl,1,instr(x.exrs_ncvl_vl,'/')-1))
                                      from 스키마.3E3243333E2E143C28@DAWNR_SMCDWS x
                                     where x.ptno = a.ptno
                                       and x.ordr_ymd = a.ordr_ymd
                                       and x.exmn_cd = 'SM0607'
                                       and nvl(x.exrs_updt_yn,'N') != 'Y'
                                   ) SM0607
                                 , (
                                    select max(substr(x.exrs_ncvl_vl,1,instr(x.exrs_ncvl_vl,'/')-1))
                                      from 스키마.3E3243333E2E143C28@DAWNR_SMCDWS x
                                     where x.ptno = a.ptno
                                       and x.ordr_ymd = a.ordr_ymd
                                       and x.exmn_cd = 'SM0608'
                                       and nvl(x.exrs_updt_yn,'N') != 'Y'
                                   ) SM0608
                                 , (
                                    select max(substr(x.exrs_ncvl_vl,1,instr(x.exrs_ncvl_vl,'/')-1))
                                      from 스키마.3E3243333E2E143C28@DAWNR_SMCDWS x
                                     where x.ptno = a.ptno
                                       and x.ordr_ymd = a.ordr_ymd
                                       and x.exmn_cd = 'SM0609'
                                       and nvl(x.exrs_updt_yn,'N') != 'Y'
                                   ) SM0609
                                 , (
                                    select count(x.exmn_cd)
                                      from 스키마.3E3243333E2E143C28@DAWNR_SMCDWS x
                                     where x.ptno = a.ptno
                                       and x.ordr_ymd = a.ordr_ymd
                                       and x.exmn_cd LIKE 'SM060%'
                                       and nvl(x.exrs_updt_yn,'N') != 'Y'
                                   ) cnt
                              from 스키마.3E3C0E433E3C0E3E28@DAWNR_SMCDWS a
                                 , 스키마.3E3C3C5B0C233C3E28@DAWNR_SMCDWS b
                                 , 스키마.3E3243333E2E143C28@DAWNR_SMCDWS c
                                 , 스키마.3C15332B3C20431528@DAWNR_SMCDWS d
                             where a.ordr_ymd between to_date(&indata_frdt,'yyyymmdd') and to_date(&indata_todt,'yyyymmdd') -- to_date('20220602','yyyymmdd') and to_date('20220602','yyyymmdd')
                               and a.cncl_dt is null
                               and b.pckg_cd = a.pckg_cd
                               and (substr(b.pckg_type_cd,1,1) not in ('6','7','9') -- 생습, 스포츠외래, 서비스 패키지 제외.
                                   and -- 제외대상을 포함시에는 and로 걸어야 함. 제외 대상 정리필요.
                                    b.pckg_type_cd not in ('5W','5Z') -- 서비스 형태의 특화 패키지 대상자 제외
                                   )
                               and a.ptno not in (-- 자료추출 금지 대상자
                                                 &not_in_ptno
                                                 )
                               and c.ptno = a.ptno
                               and c.ordr_ymd = a.ordr_ymd
                               and nvl(c.exrs_updt_yn,'N') != 'Y'
                               and c.exmn_cd = 'SM0600'
                               and d.ptno = c.ptno
                               and d.ordr_ymd = c.ordr_ymd
                               and d.ordr_sno = c.ordr_sno
                               and d.hlsc_apnt_no = a.apnt_no /* multi pkg인 경우 원 처방 패키지 고려 */
                           ) a
                   ) a
           )
                
            loop
            begin   -- 데이터 insert
                          insert /*+ append */
                            into 스키마.1543294D47144D43333E2E1428
                                 (
                                   PTNO
                                 , SM_DATE
                                 , APNT_NO
                                 , EXMN_TYP
                                 , ORDR_CD
                                 , ORDR_SNO
                                 , EXMN_CD
                                 , ORDR_YMD
                                 , EXEC_TIME
                                 , CLEANED_NCVL_VL
                                 , EXRS_NCVL_VL
                                 , EXRS_UNIT_NM
                                 , NRML_LWLM_VL
                                 , NRML_UPLM_VL
                                 , EXRS_CTN
                                 , EXRS_INFO
                                 , EXRS_CNLS
                                 , EXRS_COMMENTS
                                 , UPDT_VER
                                 , RGST_DT
                                 , LAST_UPDT_DT
                                 )
                           values(
                                   drh.ptno
                                 , drh.sm_date
                                 , drh.apnt_no
                                 , drh.exmn_typ
                                 , drh.ordr_cd
                                 , drh.ordr_sno
                                 , drh.exmn_cd
                                 , drh.ordr_ymd
                                 , drh.enfr_dt
                                 , drh.cleaned_vl
                                 , drh.exrs_ncvl_vl
                                 , drh.exrs_unit_nm
                                 , drh.nrml_lwlm_ncvl_vl
                                 , drh.nrml_uplm_ncvl_vl
                                 , drh.exrs_ctn
                                 , drh.exrs_info
                                 , drh.exrs_cnls
                                 , drh.exrs_comments
                                 , drh.updt_ver
                                 , drh.rgst_dt
                                 , drh.last_updt_dt
                                 )
                                 ;
                  
                         commit;
                       
                       incnt := incnt + 1;
                  
                       exception
                       when others then
                          rollback;
                          errcnt := errcnt + 1;
            
            end;
            end loop;
       
:var_msg2  := 'insert '  || to_char(incnt)    || ' 건';
:var_msg3  := 'error '   || to_char(errcnt)   || ' 건';
   
end ;
/
print var_msg2
print var_msg3
spool off;
     
-- diastolic BP data insert
-- 메시지 출력기능 추가. 메시지 확인은 F5를 눌러야 가능함
variable var_msg2 char(40);
variable var_msg3 char(40);
  
declare
    incnt     number(10) := 0;
    errcnt    number(10) := 0;
        
begin
for drh in (-- 마스터 정보 기준
            -- 데이터 select
            select a.ptno               as ptno
                 , a.sm_date            as sm_date
                 , a.apnt_no            as apnt_no
                 , a.exmn_typ           as exmn_typ
                 , a.ordr_cd            as ordr_cd
                 , a.ordr_sno           as ordr_sno
                 , a.exmn_cd            as exmn_cd
                 , a.ordr_ymd           as ordr_ymd
                 , a.enfr_dt            as enfr_dt
                 , a.cleaned_vl         as cleaned_vl
                 , a.exrs_ncvl_vl       as exrs_ncvl_vl
                 , a.exrs_unit_nm       as exrs_unit_nm
                 , ''                   as nrml_lwlm_ncvl_vl
                 , ''                   as nrml_uplm_ncvl_vl
                 , ''                   as exrs_ctn
                 , ''                   as exrs_info
                 , ''                   as exrs_cnls
                 , ''                   as exrs_comments
                 , '2.0'                  as updt_ver
                 , sysdate              as rgst_dt
                 , sysdate              as last_updt_dt
              from (-- Diastolic BP 데이터
                    select a.ptno
                         , a.sm_date
                         , a.apnt_no
                         , a.exmn_typ
                         , a.ordr_cd
                         , a.ordr_sno
                         , a.exmn_Cd
                         , a.ordr_ymd
                         , a.enfr_dt
                         , round((nvl(a.sm0600,0)+nvl(a.sm0601,0)+nvl(a.sm0602,0)+nvl(a.sm0603,0)+nvl(a.sm0604,0)
                                 +nvl(a.sm0605,0)+nvl(a.sm0606,0)+nvl(a.sm0607,0)+nvl(a.sm0608,0)+nvl(a.sm0609,0)
                                 )/a.cnt) cleaned_vl
                         , a.exrs_ncvl_vl
                         , 'mmHg' exrs_unit_nm
                      from (
                            select /*+ INDEX(A 3E3C0E433E3C0E3E28_I02) index(b 3E3C3C5B0C233C3E28_PK) INDEX(c 3E3243333E2E143C28_PK) INDEX(d 3C15332B3C20431528_PK) */
                                   a.ptno
--                                 , to_char(a.ordr_ymd,'yyyy-mm-dd') sm_date
                                 , a.ordr_ymd sm_date
                                 , a.apnt_no
                                 , d.ordr_cd
                                 , '0' exmn_typ
                                 , c.ordr_sno
                                 , 'SM0600DBP' exmn_cd
--                                 , to_char(c.ordr_ymd,'yyyy-mm-dd') ordr_ymd
                                 , c.ordr_ymd
--                                 , to_char(d.enfr_dt,'yyyy-mm-dd hh24:mi:ss') exec_time
                                 , d.enfr_dt
                                 , c.exrs_ncvl_vl
                    --             , substr(c.exrs_ncvl_vl,1,instr(c.exrs_ncvl_vl,'/')-1) SM0600
                                 , (
                                    select max(substr(x.exrs_ncvl_vl,instr(x.exrs_ncvl_vl,'/')+1))
                                      from 스키마.3E3243333E2E143C28@DAWNR_SMCDWS x
                                     where x.ptno = a.ptno
                                       and x.ordr_ymd = a.ordr_ymd
                                       and x.exmn_cd = 'SM0600'
                                       and nvl(x.exrs_updt_yn,'N') != 'Y'
                                   ) SM0600
                                 , (
                                    select max(substr(x.exrs_ncvl_vl,instr(x.exrs_ncvl_vl,'/')+1))
                                      from 스키마.3E3243333E2E143C28@DAWNR_SMCDWS x
                                     where x.ptno = a.ptno
                                       and x.ordr_ymd = a.ordr_ymd
                                       and x.exmn_cd = 'SM0601'
                                       and nvl(x.exrs_updt_yn,'N') != 'Y'
                                   ) SM0601
                                 , (
                                    select max(substr(x.exrs_ncvl_vl,instr(x.exrs_ncvl_vl,'/')+1))
                                      from 스키마.3E3243333E2E143C28@DAWNR_SMCDWS x
                                     where x.ptno = a.ptno
                                       and x.ordr_ymd = a.ordr_ymd
                                       and x.exmn_cd = 'SM0602'
                                       and nvl(x.exrs_updt_yn,'N') != 'Y'
                                   ) SM0602
                                 , (
                                    select max(substr(x.exrs_ncvl_vl,instr(x.exrs_ncvl_vl,'/')+1))
                                      from 스키마.3E3243333E2E143C28@DAWNR_SMCDWS x
                                     where x.ptno = a.ptno
                                       and x.ordr_ymd = a.ordr_ymd
                                       and x.exmn_cd = 'SM0603'
                                       and nvl(x.exrs_updt_yn,'N') != 'Y'
                                   ) SM0603
                                 , (
                                    select max(substr(x.exrs_ncvl_vl,instr(x.exrs_ncvl_vl,'/')+1))
                                      from 스키마.3E3243333E2E143C28@DAWNR_SMCDWS x
                                     where x.ptno = a.ptno
                                       and x.ordr_ymd = a.ordr_ymd
                                       and x.exmn_cd = 'SM0604'
                                       and nvl(x.exrs_updt_yn,'N') != 'Y'
                                   ) SM0604
                                 , (
                                    select max(substr(x.exrs_ncvl_vl,instr(x.exrs_ncvl_vl,'/')+1))
                                      from 스키마.3E3243333E2E143C28@DAWNR_SMCDWS x
                                     where x.ptno = a.ptno
                                       and x.ordr_ymd = a.ordr_ymd
                                       and x.exmn_cd = 'SM0605'
                                       and nvl(x.exrs_updt_yn,'N') != 'Y'
                                   ) SM0605
                                 , (
                                    select max(substr(x.exrs_ncvl_vl,instr(x.exrs_ncvl_vl,'/')+1))
                                      from 스키마.3E3243333E2E143C28@DAWNR_SMCDWS x
                                     where x.ptno = a.ptno
                                       and x.ordr_ymd = a.ordr_ymd
                                       and x.exmn_cd = 'SM0606'
                                       and nvl(x.exrs_updt_yn,'N') != 'Y'
                                   ) SM0606
                                 , (
                                    select max(substr(x.exrs_ncvl_vl,instr(x.exrs_ncvl_vl,'/')+1))
                                      from 스키마.3E3243333E2E143C28@DAWNR_SMCDWS x
                                     where x.ptno = a.ptno
                                       and x.ordr_ymd = a.ordr_ymd
                                       and x.exmn_cd = 'SM0607'
                                       and nvl(x.exrs_updt_yn,'N') != 'Y'
                                   ) SM0607
                                 , (
                                    select max(substr(x.exrs_ncvl_vl,instr(x.exrs_ncvl_vl,'/')+1))
                                      from 스키마.3E3243333E2E143C28@DAWNR_SMCDWS x
                                     where x.ptno = a.ptno
                                       and x.ordr_ymd = a.ordr_ymd
                                       and x.exmn_cd = 'SM0608'
                                       and nvl(x.exrs_updt_yn,'N') != 'Y'
                                   ) SM0608
                                 , (
                                    select max(substr(x.exrs_ncvl_vl,instr(x.exrs_ncvl_vl,'/')+1))
                                      from 스키마.3E3243333E2E143C28@DAWNR_SMCDWS x
                                     where x.ptno = a.ptno
                                       and x.ordr_ymd = a.ordr_ymd
                                       and x.exmn_cd = 'SM0609'
                                       and nvl(x.exrs_updt_yn,'N') != 'Y'
                                   ) SM0609
                                 , (
                                    select count(x.exmn_cd)
                                      from 스키마.3E3243333E2E143C28@DAWNR_SMCDWS x
                                     where x.ptno = a.ptno
                                       and x.ordr_ymd = a.ordr_ymd
                                       and x.exmn_cd LIKE 'SM060%'
                                       and nvl(x.exrs_updt_yn,'N') != 'Y'
                                   ) cnt
                              from 스키마.3E3C0E433E3C0E3E28@DAWNR_SMCDWS a
                                 , 스키마.3E3C3C5B0C233C3E28@DAWNR_SMCDWS b
                                 , 스키마.3E3243333E2E143C28@DAWNR_SMCDWS c
                                 , 스키마.3C15332B3C20431528@DAWNR_SMCDWS d
                             where a.ordr_ymd between to_date(&indata_frdt,'yyyymmdd') and to_date(&indata_todt,'yyyymmdd') -- to_date('20220602','yyyymmdd') and to_date('20220602','yyyymmdd')
                               and a.cncl_dt is null
                               and b.pckg_cd = a.pckg_cd
                               and (substr(b.pckg_type_cd,1,1) not in ('6','7','9') -- 생습, 스포츠외래, 서비스 패키지 제외.
                                   and -- 제외대상을 포함시에는 and로 걸어야 함. 제외 대상 정리필요.
                                    b.pckg_type_cd not in ('5W','5Z') -- 서비스 형태의 특화 패키지 대상자 제외
                                   )
                               and a.ptno not in (-- 자료추출 금지 대상자
                                                 &not_in_ptno
                                                 )
                               and c.ptno = a.ptno
                               and c.ordr_ymd = a.ordr_ymd
                               and nvl(c.exrs_updt_yn,'N') != 'Y'
                               and c.exmn_cd = 'SM0600'
                               and d.ptno = c.ptno
                               and d.ordr_ymd = c.ordr_ymd
                               and d.ordr_sno = c.ordr_sno
                               and d.hlsc_apnt_no = a.apnt_no /* multi pkg인 경우 원 처방 패키지 고려 */
                           ) a
                   ) a
           )
                
            loop
            begin   -- 데이터 insert
                          insert /*+ append */
                            into 스키마.1543294D47144D43333E2E1428
                                 (
                                   PTNO
                                 , SM_DATE
                                 , APNT_NO
                                 , EXMN_TYP
                                 , ORDR_CD
                                 , ORDR_SNO
                                 , EXMN_CD
                                 , ORDR_YMD
                                 , EXEC_TIME
                                 , CLEANED_NCVL_VL
                                 , EXRS_NCVL_VL
                                 , EXRS_UNIT_NM
                                 , NRML_LWLM_VL
                                 , NRML_UPLM_VL
                                 , EXRS_CTN
                                 , EXRS_INFO
                                 , EXRS_CNLS
                                 , EXRS_COMMENTS
                                 , UPDT_VER
                                 , RGST_DT
                                 , LAST_UPDT_DT
                                 )
                           values(
                                   drh.ptno
                                 , drh.sm_date
                                 , drh.apnt_no
                                 , drh.exmn_typ
                                 , drh.ordr_cd
                                 , drh.ordr_sno
                                 , drh.exmn_cd
                                 , drh.ordr_ymd
                                 , drh.enfr_dt
                                 , drh.cleaned_vl
                                 , drh.exrs_ncvl_vl
                                 , drh.exrs_unit_nm
                                 , drh.nrml_lwlm_ncvl_vl
                                 , drh.nrml_uplm_ncvl_vl
                                 , drh.exrs_ctn
                                 , drh.exrs_info
                                 , drh.exrs_cnls
                                 , drh.exrs_comments
                                 , drh.updt_ver
                                 , drh.rgst_dt
                                 , drh.last_updt_dt
                                 )
                                 ;
                  
                         commit;
                       
                       incnt := incnt + 1;
                  
                       exception
                       when others then
                          rollback;
                          errcnt := errcnt + 1;
            
            end;
            end loop;
       
:var_msg2  := 'insert '  || to_char(incnt)    || ' 건';
:var_msg3  := 'error '   || to_char(errcnt)   || ' 건';
   
end ;
/
print var_msg2
print var_msg3
spool off;
     
-- Coronary Artery Calcium CT Score insert
-- RC118401 data insert
-- 메시지 출력기능 추가. 메시지 확인은 F5를 눌러야 가능함
variable var_msg2 char(40);
variable var_msg3 char(40);
  
declare
    incnt     number(10) := 0;
    errcnt    number(10) := 0;
        
begin
for drh in (-- 마스터 정보 기준
            -- 데이터 select
            select a.ptno               as ptno
                 , a.sm_date            as sm_date
                 , a.apnt_no            as apnt_no
                 , a.exmn_typ           as exmn_typ
                 , a.ordr_cd            as ordr_cd
                 , a.ordr_sno           as ordr_sno
                 , a.exmn_cd            as exmn_cd
                 , a.ordr_ymd           as ordr_ymd
                 , a.EXEC_TIME          as EXEC_TIME
                 , a.cleaned_ncvl_vl    as cleaned_ncvl_vl
                 , a.exrs_ncvl_vl       as exrs_ncvl_vl
                 , a.exrs_unit_nm       as exrs_unit_nm
                 , ''                   as nrml_lwlm_vl
                 , ''                   as nrml_uplm_vl
                 , a.exrs_ctn           as exrs_ctn
                 , a.exrs_info          as exrs_info
                 , a.exrs_cnls          as exrs_cnls
                 , a.exrs_comments      as exrs_comments
                 , '2'                  as updt_ver
                 , sysdate              as rgst_dt
                 , sysdate              as last_updt_dt
              from (-- RC118401 AJ 130 score 데이터 추출
                    select 
                           b.ptno
                         , b.ordr_ymd sm_date --to_char(b.ordr_ymd,'yyyy-mm-dd') sm_date <- 날짜 format이 맞지 않으면 error가 발생됨.
                         , a.apnt_no
                         , '0' exmn_typ
                         , c.ordr_cd
                         , c.ordr_sno
                         , 'RC118401' exmn_cd
                         , c.ordr_ymd--to_char(c.ordr_ymd,'yyyy-mm-dd') ordr_ymd <- 날짜 format이 맞지 않으면 error가 발생됨.
                         , c.enfr_dt exec_time --to_char(c.enfr_dt,'yyyy-mm-dd hh24:mi:ss') EXEC_TIME <- 날짜 format이 맞지 않으면 error가 발생됨.
                         , case
                                when
                                     substr(
                                            decode(b.exmn_cd
                                                   ,'RC1184'
                                                   ,regexp_replace(-- 숫자 뒤의 엔터값 삭제
                                                                   decode(instr(to_char(b.cnls_dx_ctn),'=',1,2)
                                                                         ,0
                                                                         ,'0'
                                                                         ,trim(
                                                                               substr(
                                                                                      substr(
                                                                                             to_char(b.cnls_dx_ctn)
                                                                                            ,1
                                                                                            ,instr(to_char(b.cnls_dx_ctn),'=',1,1) + regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,1) + 1),'[가-힣A-Za-z]') - 1
                                                                                            )
                                                                                     ,instr(
                                                                                            substr(
                                                                                                   to_char(b.cnls_dx_ctn)
                                                                                                  ,1
                                                                                                  ,instr(to_char(b.cnls_dx_ctn),'=',1,1) + regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,1) + 1),'[가-힣A-Za-z]') - 1
                                                                                                  )
                                                                                           ,'='
                                                                                           ,1
                                                                                           ,1
                                                                                           ) + 1
                                                                                     )
                                                                              )
                                                                         )
                                                                  ,'[^0-9.]' -- 숫자와 소수점 외에
                                                                  ,''
                                                                  )
                                                   ,''
                                                   )
                                            ,length(
                                                    decode(b.exmn_cd
                                                           ,'RC1184'
                                                           ,regexp_replace(-- 숫자 뒤의 엔터값 삭제
                                                                           decode(instr(to_char(b.cnls_dx_ctn),'=',1,2)
                                                                                 ,0
                                                                                 ,'0'
                                                                                 ,trim(
                                                                                       substr(
                                                                                              substr(
                                                                                                     to_char(b.cnls_dx_ctn)
                                                                                                    ,1
                                                                                                    ,instr(to_char(b.cnls_dx_ctn),'=',1,1) + regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,1) + 1),'[가-힣A-Za-z]') - 1
                                                                                                    )
                                                                                             ,instr(
                                                                                                    substr(
                                                                                                           to_char(b.cnls_dx_ctn)
                                                                                                          ,1
                                                                                                          ,instr(to_char(b.cnls_dx_ctn),'=',1,1) + regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,1) + 1),'[가-힣A-Za-z]') - 1
                                                                                                          )
                                                                                                   ,'='
                                                                                                   ,1
                                                                                                   ,1
                                                                                                   ) + 1
                                                                                             )
                                                                                      )
                                                                                 )
                                                                          ,'[^0-9.]' -- 숫자와 소수점 외에
                                                                          ,''
                                                                          )
                                                           ,''
                                                           )
                                                   )
                                            ) = '.'
                                then                 substr(
                                            decode(b.exmn_cd
                                                   ,'RC1184'
                                                   ,regexp_replace(-- 숫자 뒤의 엔터값 삭제
                                                                   decode(instr(to_char(b.cnls_dx_ctn),'=',1,2)
                                                                         ,0
                                                                         ,'0'
                                                                         ,trim(
                                                                               substr(
                                                                                      substr(
                                                                                             to_char(b.cnls_dx_ctn)
                                                                                            ,1
                                                                                            ,instr(to_char(b.cnls_dx_ctn),'=',1,1) + regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,1) + 1),'[가-힣A-Za-z]') - 1
                                                                                            )
                                                                                     ,instr(
                                                                                            substr(
                                                                                                   to_char(b.cnls_dx_ctn)
                                                                                                  ,1
                                                                                                  ,instr(to_char(b.cnls_dx_ctn),'=',1,1) + regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,1) + 1),'[가-힣A-Za-z]') - 1
                                                                                                  )
                                                                                           ,'='
                                                                                           ,1
                                                                                           ,1
                                                                                           ) + 1
                                                                                     )
                                                                              )
                                                                         )
                                                                  ,'[^0-9.]' -- 숫자와 소수점 외에
                                                                  ,''
                                                                  )
                                                   ,''
                                                   )
                                            ,1
                                            ,length(
                                                    decode(b.exmn_cd
                                                           ,'RC1184'
                                                           ,regexp_replace(-- 숫자 뒤의 엔터값 삭제
                                                                           decode(instr(to_char(b.cnls_dx_ctn),'=',1,2)
                                                                                 ,0
                                                                                 ,'0'
                                                                                 ,trim(
                                                                                       substr(
                                                                                              substr(
                                                                                                     to_char(b.cnls_dx_ctn)
                                                                                                    ,1
                                                                                                    ,instr(to_char(b.cnls_dx_ctn),'=',1,1) + regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,1) + 1),'[가-힣A-Za-z]') - 1
                                                                                                    )
                                                                                             ,instr(
                                                                                                    substr(
                                                                                                           to_char(b.cnls_dx_ctn)
                                                                                                          ,1
                                                                                                          ,instr(to_char(b.cnls_dx_ctn),'=',1,1) + regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,1) + 1),'[가-힣A-Za-z]') - 1
                                                                                                          )
                                                                                                   ,'='
                                                                                                   ,1
                                                                                                   ,1
                                                                                                   ) + 1
                                                                                             )
                                                                                      )
                                                                                 )
                                                                          ,'[^0-9.]' -- 숫자와 소수점 외에
                                                                          ,''
                                                                          )
                                                           ,''
                                                           )
                                                   ) - 1
                                            )
                                else 
                                     decode(b.exmn_cd
                                           ,'RC1184'
                                           ,regexp_replace(-- 숫자 뒤의 엔터값 삭제
                                                           decode(instr(to_char(b.cnls_dx_ctn),'=',1,2)
                                                                 ,0
                                                                 ,'0'
                                                                 ,trim(
                                                                       substr(
                                                                              substr(
                                                                                     to_char(b.cnls_dx_ctn)
                                                                                    ,1
                                                                                    ,instr(to_char(b.cnls_dx_ctn),'=',1,1) + regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,1) + 1),'[가-힣A-Za-z]') - 1
                                                                                    )
                                                                             ,instr(
                                                                                    substr(
                                                                                           to_char(b.cnls_dx_ctn)
                                                                                          ,1
                                                                                          ,instr(to_char(b.cnls_dx_ctn),'=',1,1) + regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,1) + 1),'[가-힣A-Za-z]') - 1
                                                                                          )
                                                                                   ,'='
                                                                                   ,1
                                                                                   ,1
                                                                                   ) + 1
                                                                             )
                                                                      )
                                                                 )
                                                          ,'[^0-9.]' -- 숫자와 소수점 외에
                                                          ,''
                                                          )
                                           ,''
                                           )
                                end cleaned_ncvl_vl -- aj_130
                         , '' exrs_ncvl_vl
                         , '' exrs_unit_nm
                         , '' nrml_lwlm_vl
                         , '' nrml_uplm_vl
                         , decode(b.exmn_cd,'RC1184',to_char(b.exrs_ctn),'') EXRS_CTN
                         , decode(b.exmn_cd,'RC1184',to_char(b.gros_rslt_ctn),'') EXRS_info
                         , decode(b.exmn_cd,'RC1184',to_char(b.cnls_dx_ctn),'') EXRS_cnls
                         , decode(b.exmn_cd,'RC1184',to_char(b.exrs_rmrk_ctn),'') EXRS_comments
                      from 스키마.3E3C0E433E3C0E3E28@DAWNR_SMCDWS a
                         , 스키마.3E3243333E2E143C28@DAWNR_SMCDWS b
                         , 스키마.3C15332B3C20431528@DAWNR_SMCDWS c
                     where a.ordr_ymd between to_date(&indata_frdt,'yyyymmdd') and to_date(&indata_todt,'yyyymmdd') -- to_date('20220602','yyyymmdd') and to_date('20220602','yyyymmdd')
                       and a.cncl_dt is null
                       and b.ptno = a.ptno
                       and b.ordr_ymd = a.ordr_ymd
                       and b.exmn_cd = 'RC1184'
                       and nvl(b.exrs_updt_yn,'N') != 'Y'
                       and c.ptno = b.ptno
                       and c.ordr_ymd = b.ordr_ymd
                       and c.ordr_sno = b.ordr_sno
                       and c.codv_cd = 'G'
                       and nvl(c.dc_dvsn_cd,'N') != 'X'
                       and c.hlsc_apnt_no = a.apnt_no
                               and a.ptno not in (-- 자료추출 금지 대상자
                                                 &not_in_ptno
                                                 )
                   ) a
           )
                
            loop
            begin   -- 데이터 insert
                          insert /*+ append */
                            into 스키마.1543294D47144D43333E2E1428
                                 (
                                   PTNO
                                 , SM_DATE
                                 , APNT_NO
                                 , EXMN_TYP
                                 , ORDR_CD
                                 , ORDR_SNO
                                 , EXMN_CD
                                 , ORDR_YMD
                                 , EXEC_TIME
                                 , CLEANED_NCVL_VL
                                 , EXRS_NCVL_VL
                                 , EXRS_UNIT_NM
                                 , NRML_LWLM_VL
                                 , NRML_UPLM_VL
                                 , EXRS_CTN
                                 , EXRS_INFO
                                 , EXRS_CNLS
                                 , EXRS_COMMENTS
                                 , UPDT_VER
                                 , RGST_DT
                                 , LAST_UPDT_DT
                                 )
                           values(
                                   drh.ptno
                                 , drh.sm_date
                                 , drh.apnt_no
                                 , drh.exmn_typ
                                 , drh.ordr_cd
                                 , drh.ordr_sno
                                 , drh.exmn_cd
                                 , drh.ordr_ymd
                                 , drh.EXEC_TIME
                                 , drh.cleaned_ncvl_vl
                                 , drh.exrs_ncvl_vl
                                 , drh.exrs_unit_nm
                                 , drh.nrml_lwlm_vl
                                 , drh.nrml_uplm_vl
                                 , drh.exrs_ctn
                                 , drh.exrs_info
                                 , drh.exrs_cnls
                                 , drh.exrs_comments
                                 , drh.updt_ver
                                 , drh.rgst_dt
                                 , drh.last_updt_dt
                                 )
                                 ;
                  
                         commit;
                       
                       incnt := incnt + 1;
                  
                       exception
                       when others then
                          rollback;
                          errcnt := errcnt + 1;
            
            end;
            end loop;
       
:var_msg2  := 'insert '  || to_char(incnt)    || ' 건';
:var_msg3  := 'error '   || to_char(errcnt)   || ' 건';
   
end ;
/
print var_msg2
print var_msg3
spool off;
    
-- RC118402 data insert
-- 메시지 출력기능 추가. 메시지 확인은 F5를 눌러야 가능함
variable var_msg2 char(40);
variable var_msg3 char(40);
  
declare
    incnt     number(10) := 0;
    errcnt    number(10) := 0;
        
begin
for drh in (-- 마스터 정보 기준
            -- 데이터 select
            select a.ptno               as ptno
                 , a.sm_date            as sm_date
                 , a.apnt_no            as apnt_no
                 , a.exmn_typ           as exmn_typ
                 , a.ordr_cd            as ordr_cd
                 , a.ordr_sno           as ordr_sno
                 , a.exmn_cd            as exmn_cd
                 , a.ordr_ymd           as ordr_ymd
                 , a.EXEC_TIME          as EXEC_TIME
                 , a.cleaned_ncvl_vl    as cleaned_ncvl_vl
                 , a.exrs_ncvl_vl       as exrs_ncvl_vl
                 , a.exrs_unit_nm       as exrs_unit_nm
                 , ''                   as nrml_lwlm_vl
                 , ''                   as nrml_uplm_vl
                 , a.exrs_ctn           as exrs_ctn
                 , a.exrs_info          as exrs_info
                 , a.exrs_cnls          as exrs_cnls
                 , a.exrs_comments      as exrs_comments
                 , '2'                  as updt_ver
                 , sysdate              as rgst_dt
                 , sysdate              as last_updt_dt
              from (-- RC118402 volume 130 score 데이터 추출
                    select 
                           b.ptno
                         , b.ordr_ymd sm_date --to_char(b.ordr_ymd,'yyyy-mm-dd') sm_date <- 날짜 format이 맞지 않으면 error가 발생됨.
                         , a.apnt_no
                         , '0' exmn_typ
                         , c.ordr_cd
                         , c.ordr_sno
                         , 'RC118402' exmn_cd
                         , c.ordr_ymd--to_char(c.ordr_ymd,'yyyy-mm-dd') ordr_ymd <- 날짜 format이 맞지 않으면 error가 발생됨.
                         , c.enfr_dt exec_time --to_char(c.enfr_dt,'yyyy-mm-dd hh24:mi:ss') EXEC_TIME <- 날짜 format이 맞지 않으면 error가 발생됨.
                         , case
                                when
                                     substr(
                                            regexp_replace(
                                            case
                                                 when instr(lower(
                                                                  decode(
                                                                         b.exmn_cd
                                                                        ,'RC1184'
                                                                        , trim(
                                                                               substr(
                                                                                      to_char(b.cnls_dx_ctn)
                                                                                     ,-- 첫번째 구분값의 시작위치 이후
                                                                                      instr(to_char(b.cnls_dx_ctn),'=',1,1) -- 1. '=' 구분자가 있는 위치에
                                                                                      +                                     -- 3. 더한다.
                                                                                      regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,1) + 1),'[가-힣A-Za-z]')-- + 1 -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                     ,-- 세번째 구분 값의 위치 - 첫번째 구분 값의 위치 
                                                                                      instr(to_char(b.cnls_dx_ctn),'=',1,2) -- 1. '=' 구분자가 있는 위치에
                                                                                      +                                     -- 3. 더한다.
                                                                                      regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,2) + 1),'[가-힣A-Za-z]') - 1 -- 2. 두번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                      -
                                                                                      (-- 첫번째 구분값의 시작위치 이후
                                                                                      instr(to_char(b.cnls_dx_ctn),'=',1,1) -- 1. '=' 구분자가 있는 위치에
                                                                                      +                                     -- 3. 더한다.
                                                                                      regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,1) + 1),'[가-힣A-Za-z]')    -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                      )
                                                                                     ) 
                                                                              )
                                                                        ,''
                                                                        )
                                                                 )
                                                           ,'mass' -- 두번째 결과 문구에서 mass가 포함되어 있다면
                                                           ,1
                                                           ,1                      
                                                           ) != 0
                                                 then -- 세번째 결과 문구를 가져와라
                                                      decode(
                                                             b.exmn_cd
                                                            ,'RC1184'
                                                            ,decode(instr(to_char(b.cnls_dx_ctn),'=',1,3)
                                                                   ,0
                                                                   ,''
                                                                   ,trim(
                                                                         substr(
                                                                                trim(
                                                                                     substr(
                                                                                            to_char(b.cnls_dx_ctn)
                                                                                           ,-- 두번째 구분값의 시작위치 이후
                                                                                            instr(to_char(b.cnls_dx_ctn),'=',1,2) -- 1. '=' 구분자가 있는 위치에
                                                                                            +                                     -- 3. 더한다.
                                                                                            regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,2) + 1),'[가-힣A-Za-z]')-- + 1 -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                           ,-- 세번째 구분 값 이후 첫 문자위치 - 두번째 구분 값의 위치 
                                                                                            instr(to_char(b.cnls_dx_ctn),'=',1,3) -- 1. '=' 구분자가 있는 위치에
                                                                                            +                                     -- 3. 더한다.
                                                                                            regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,3) + 1),'[가-힣A-Za-z]') - 1 -- 2. 세번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                            -
                                                                                            (-- 두번째 구분값의 시작위치 이후
                                                                                            instr(to_char(b.cnls_dx_ctn),'=',1,2) -- 1. '=' 구분자가 있는 위치에
                                                                                            +                                     -- 3. 더한다.
                                                                                            regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,2) + 1),'[가-힣A-Za-z]')    -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                            )
                                                                                           ) 
                                                                                    )
                                                                               ,instr(
                                                                                      trim(
                                                                                           substr(
                                                                                                  to_char(b.cnls_dx_ctn)
                                                                                                 ,-- 두번째 구분값의 시작위치 이후
                                                                                                  instr(to_char(b.cnls_dx_ctn),'=',1,2) -- 1. '=' 구분자가 있는 위치에
                                                                                                  +                                     -- 3. 더한다.
                                                                                                  regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,2) + 1),'[가-힣A-Za-z]')-- + 1 -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                                 ,-- 세번째 구분 값 이후 첫 문자위치 - 두번째 구분 값의 위치 
                                                                                                  instr(to_char(b.cnls_dx_ctn),'=',1,3) -- 1. '=' 구분자가 있는 위치에
                                                                                                  +                                     -- 3. 더한다.
                                                                                                  regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,3) + 1),'[가-힣A-Za-z]') - 1 -- 2. 세번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                                  -
                                                                                                  (-- 두번째 구분값의 시작위치 이후
                                                                                                  instr(to_char(b.cnls_dx_ctn),'=',1,2) -- 1. '=' 구분자가 있는 위치에
                                                                                                  +                                     -- 3. 더한다.
                                                                                                  regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,2) + 1),'[가-힣A-Za-z]')    -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                                  )
                                                                                                 ) 
                                                                                          )                                                 
                                                                                     ,'='
                                                                                     ,1
                                                                                     ,1
                                                                                     ) + 1
                                                                               )
                                                                        )
                                                                   )
                                                            ,''
                                                            )
                                                 else -- 그렇지 않으면 두번째 문구를 그대로 사용해 된다.
                                                      decode(
                                                             b.exmn_cd
                                                            ,'RC1184'
                                                            ,trim(
                                                                  substr(
                                                                         trim(
                                                                               substr(
                                                                                      to_char(b.cnls_dx_ctn)
                                                                                     ,-- 첫번째 구분값의 시작위치 이후
                                                                                      instr(to_char(b.cnls_dx_ctn),'=',1,1) -- 1. '=' 구분자가 있는 위치에
                                                                                      +                                     -- 3. 더한다.
                                                                                      regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,1) + 1),'[가-힣A-Za-z]')-- + 1 -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                     ,-- 세번째 구분 값의 위치 - 첫번째 구분 값의 위치 
                                                                                      instr(to_char(b.cnls_dx_ctn),'=',1,2) -- 1. '=' 구분자가 있는 위치에
                                                                                      +                                     -- 3. 더한다.
                                                                                      regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,2) + 1),'[가-힣A-Za-z]') - 1 -- 2. 두번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                      -
                                                                                      (-- 첫번째 구분값의 시작위치 이후
                                                                                      instr(to_char(b.cnls_dx_ctn),'=',1,1) -- 1. '=' 구분자가 있는 위치에
                                                                                      +                                     -- 3. 더한다.
                                                                                      regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,1) + 1),'[가-힣A-Za-z]')    -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                      )
                                                                                     ) 
                                                                              )
                                                                        ,instr(
                                                                               trim(
                                                                                     substr(
                                                                                            to_char(b.cnls_dx_ctn)
                                                                                           ,-- 첫번째 구분값의 시작위치 이후
                                                                                            instr(to_char(b.cnls_dx_ctn),'=',1,1) -- 1. '=' 구분자가 있는 위치에
                                                                                            +                                     -- 3. 더한다.
                                                                                            regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,1) + 1),'[가-힣A-Za-z]')-- + 1 -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                           ,-- 세번째 구분 값의 위치 - 첫번째 구분 값의 위치 
                                                                                            instr(to_char(b.cnls_dx_ctn),'=',1,2) -- 1. '=' 구분자가 있는 위치에
                                                                                            +                                     -- 3. 더한다.
                                                                                            regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,2) + 1),'[가-힣A-Za-z]') - 1 -- 2. 두번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                            -
                                                                                            (-- 첫번째 구분값의 시작위치 이후
                                                                                            instr(to_char(b.cnls_dx_ctn),'=',1,1) -- 1. '=' 구분자가 있는 위치에
                                                                                            +                                     -- 3. 더한다.
                                                                                            regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,1) + 1),'[가-힣A-Za-z]')    -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                            )
                                                                                           ) 
                                                                                    )
                                                                              ,'='
                                                                              ,1
                                                                              ,1
                                                                              ) + 1
                                                                        )
                                                                 )
                                                            ,''
                                                            )
                                                 end 
                                                          ,'[^0-9.]' -- 숫자와 소수점 외에
                                                          ,''
                                                          )
                                            ,length(
                                                    regexp_replace(
                                                    case
                                                         when instr(lower(
                                                                          decode(
                                                                                 b.exmn_cd
                                                                                ,'RC1184'
                                                                                , trim(
                                                                                       substr(
                                                                                              to_char(b.cnls_dx_ctn)
                                                                                             ,-- 첫번째 구분값의 시작위치 이후
                                                                                              instr(to_char(b.cnls_dx_ctn),'=',1,1) -- 1. '=' 구분자가 있는 위치에
                                                                                              +                                     -- 3. 더한다.
                                                                                              regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,1) + 1),'[가-힣A-Za-z]')-- + 1 -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                             ,-- 세번째 구분 값의 위치 - 첫번째 구분 값의 위치 
                                                                                              instr(to_char(b.cnls_dx_ctn),'=',1,2) -- 1. '=' 구분자가 있는 위치에
                                                                                              +                                     -- 3. 더한다.
                                                                                              regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,2) + 1),'[가-힣A-Za-z]') - 1 -- 2. 두번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                              -
                                                                                              (-- 첫번째 구분값의 시작위치 이후
                                                                                              instr(to_char(b.cnls_dx_ctn),'=',1,1) -- 1. '=' 구분자가 있는 위치에
                                                                                              +                                     -- 3. 더한다.
                                                                                              regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,1) + 1),'[가-힣A-Za-z]')    -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                              )
                                                                                             ) 
                                                                                      )
                                                                                ,''
                                                                                )
                                                                         )
                                                                   ,'mass' -- 두번째 결과 문구에서 mass가 포함되어 있다면
                                                                   ,1
                                                                   ,1                      
                                                                   ) != 0
                                                         then -- 세번째 결과 문구를 가져와라
                                                              decode(
                                                                     b.exmn_cd
                                                                    ,'RC1184'
                                                                    ,decode(instr(to_char(b.cnls_dx_ctn),'=',1,3)
                                                                           ,0
                                                                           ,''
                                                                           ,trim(
                                                                                 substr(
                                                                                        trim(
                                                                                             substr(
                                                                                                    to_char(b.cnls_dx_ctn)
                                                                                                   ,-- 두번째 구분값의 시작위치 이후
                                                                                                    instr(to_char(b.cnls_dx_ctn),'=',1,2) -- 1. '=' 구분자가 있는 위치에
                                                                                                    +                                     -- 3. 더한다.
                                                                                                    regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,2) + 1),'[가-힣A-Za-z]')-- + 1 -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                                   ,-- 세번째 구분 값 이후 첫 문자위치 - 두번째 구분 값의 위치 
                                                                                                    instr(to_char(b.cnls_dx_ctn),'=',1,3) -- 1. '=' 구분자가 있는 위치에
                                                                                                    +                                     -- 3. 더한다.
                                                                                                    regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,3) + 1),'[가-힣A-Za-z]') - 1 -- 2. 세번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                                    -
                                                                                                    (-- 두번째 구분값의 시작위치 이후
                                                                                                    instr(to_char(b.cnls_dx_ctn),'=',1,2) -- 1. '=' 구분자가 있는 위치에
                                                                                                    +                                     -- 3. 더한다.
                                                                                                    regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,2) + 1),'[가-힣A-Za-z]')    -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                                    )
                                                                                                   ) 
                                                                                            )
                                                                                       ,instr(
                                                                                              trim(
                                                                                                   substr(
                                                                                                          to_char(b.cnls_dx_ctn)
                                                                                                         ,-- 두번째 구분값의 시작위치 이후
                                                                                                          instr(to_char(b.cnls_dx_ctn),'=',1,2) -- 1. '=' 구분자가 있는 위치에
                                                                                                          +                                     -- 3. 더한다.
                                                                                                          regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,2) + 1),'[가-힣A-Za-z]')-- + 1 -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                                         ,-- 세번째 구분 값 이후 첫 문자위치 - 두번째 구분 값의 위치 
                                                                                                          instr(to_char(b.cnls_dx_ctn),'=',1,3) -- 1. '=' 구분자가 있는 위치에
                                                                                                          +                                     -- 3. 더한다.
                                                                                                          regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,3) + 1),'[가-힣A-Za-z]') - 1 -- 2. 세번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                                          -
                                                                                                          (-- 두번째 구분값의 시작위치 이후
                                                                                                          instr(to_char(b.cnls_dx_ctn),'=',1,2) -- 1. '=' 구분자가 있는 위치에
                                                                                                          +                                     -- 3. 더한다.
                                                                                                          regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,2) + 1),'[가-힣A-Za-z]')    -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                                          )
                                                                                                         ) 
                                                                                                  )                                                 
                                                                                             ,'='
                                                                                             ,1
                                                                                             ,1
                                                                                             ) + 1
                                                                                       )
                                                                                )
                                                                           )
                                                                    ,''
                                                                    )
                                                         else -- 그렇지 않으면 두번째 문구를 그대로 사용해 된다.
                                                              decode(
                                                                     b.exmn_cd
                                                                    ,'RC1184'
                                                                    ,trim(
                                                                          substr(
                                                                                 trim(
                                                                                       substr(
                                                                                              to_char(b.cnls_dx_ctn)
                                                                                             ,-- 첫번째 구분값의 시작위치 이후
                                                                                              instr(to_char(b.cnls_dx_ctn),'=',1,1) -- 1. '=' 구분자가 있는 위치에
                                                                                              +                                     -- 3. 더한다.
                                                                                              regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,1) + 1),'[가-힣A-Za-z]')-- + 1 -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                             ,-- 세번째 구분 값의 위치 - 첫번째 구분 값의 위치 
                                                                                              instr(to_char(b.cnls_dx_ctn),'=',1,2) -- 1. '=' 구분자가 있는 위치에
                                                                                              +                                     -- 3. 더한다.
                                                                                              regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,2) + 1),'[가-힣A-Za-z]') - 1 -- 2. 두번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                              -
                                                                                              (-- 첫번째 구분값의 시작위치 이후
                                                                                              instr(to_char(b.cnls_dx_ctn),'=',1,1) -- 1. '=' 구분자가 있는 위치에
                                                                                              +                                     -- 3. 더한다.
                                                                                              regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,1) + 1),'[가-힣A-Za-z]')    -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                              )
                                                                                             ) 
                                                                                      )
                                                                                ,instr(
                                                                                       trim(
                                                                                             substr(
                                                                                                    to_char(b.cnls_dx_ctn)
                                                                                                   ,-- 첫번째 구분값의 시작위치 이후
                                                                                                    instr(to_char(b.cnls_dx_ctn),'=',1,1) -- 1. '=' 구분자가 있는 위치에
                                                                                                    +                                     -- 3. 더한다.
                                                                                                    regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,1) + 1),'[가-힣A-Za-z]')-- + 1 -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                                   ,-- 세번째 구분 값의 위치 - 첫번째 구분 값의 위치 
                                                                                                    instr(to_char(b.cnls_dx_ctn),'=',1,2) -- 1. '=' 구분자가 있는 위치에
                                                                                                    +                                     -- 3. 더한다.
                                                                                                    regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,2) + 1),'[가-힣A-Za-z]') - 1 -- 2. 두번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                                    -
                                                                                                    (-- 첫번째 구분값의 시작위치 이후
                                                                                                    instr(to_char(b.cnls_dx_ctn),'=',1,1) -- 1. '=' 구분자가 있는 위치에
                                                                                                    +                                     -- 3. 더한다.
                                                                                                    regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,1) + 1),'[가-힣A-Za-z]')    -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                                    )
                                                                                                   ) 
                                                                                            )
                                                                                      ,'='
                                                                                      ,1
                                                                                      ,1
                                                                                      ) + 1
                                                                                )
                                                                         )
                                                                    ,''
                                                                    )
                                                         end 
                                                                  ,'[^0-9.]' -- 숫자와 소수점 외에
                                                                  ,''
                                                                  )
                                                   )
                                            ) = '.'
                                then substr(
                                            regexp_replace(
                                            case
                                                 when instr(lower(
                                                                  decode(
                                                                         b.exmn_cd
                                                                        ,'RC1184'
                                                                        , trim(
                                                                               substr(
                                                                                      to_char(b.cnls_dx_ctn)
                                                                                     ,-- 첫번째 구분값의 시작위치 이후
                                                                                      instr(to_char(b.cnls_dx_ctn),'=',1,1) -- 1. '=' 구분자가 있는 위치에
                                                                                      +                                     -- 3. 더한다.
                                                                                      regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,1) + 1),'[가-힣A-Za-z]')-- + 1 -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                     ,-- 세번째 구분 값의 위치 - 첫번째 구분 값의 위치 
                                                                                      instr(to_char(b.cnls_dx_ctn),'=',1,2) -- 1. '=' 구분자가 있는 위치에
                                                                                      +                                     -- 3. 더한다.
                                                                                      regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,2) + 1),'[가-힣A-Za-z]') - 1 -- 2. 두번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                      -
                                                                                      (-- 첫번째 구분값의 시작위치 이후
                                                                                      instr(to_char(b.cnls_dx_ctn),'=',1,1) -- 1. '=' 구분자가 있는 위치에
                                                                                      +                                     -- 3. 더한다.
                                                                                      regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,1) + 1),'[가-힣A-Za-z]')    -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                      )
                                                                                     ) 
                                                                              )
                                                                        ,''
                                                                        )
                                                                 )
                                                           ,'mass' -- 두번째 결과 문구에서 mass가 포함되어 있다면
                                                           ,1
                                                           ,1                      
                                                           ) != 0
                                                 then -- 세번째 결과 문구를 가져와라
                                                      decode(
                                                             b.exmn_cd
                                                            ,'RC1184'
                                                            ,decode(instr(to_char(b.cnls_dx_ctn),'=',1,3)
                                                                   ,0
                                                                   ,''
                                                                   ,trim(
                                                                         substr(
                                                                                trim(
                                                                                     substr(
                                                                                            to_char(b.cnls_dx_ctn)
                                                                                           ,-- 두번째 구분값의 시작위치 이후
                                                                                            instr(to_char(b.cnls_dx_ctn),'=',1,2) -- 1. '=' 구분자가 있는 위치에
                                                                                            +                                     -- 3. 더한다.
                                                                                            regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,2) + 1),'[가-힣A-Za-z]')-- + 1 -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                           ,-- 세번째 구분 값 이후 첫 문자위치 - 두번째 구분 값의 위치 
                                                                                            instr(to_char(b.cnls_dx_ctn),'=',1,3) -- 1. '=' 구분자가 있는 위치에
                                                                                            +                                     -- 3. 더한다.
                                                                                            regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,3) + 1),'[가-힣A-Za-z]') - 1 -- 2. 세번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                            -
                                                                                            (-- 두번째 구분값의 시작위치 이후
                                                                                            instr(to_char(b.cnls_dx_ctn),'=',1,2) -- 1. '=' 구분자가 있는 위치에
                                                                                            +                                     -- 3. 더한다.
                                                                                            regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,2) + 1),'[가-힣A-Za-z]')    -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                            )
                                                                                           ) 
                                                                                    )
                                                                               ,instr(
                                                                                      trim(
                                                                                           substr(
                                                                                                  to_char(b.cnls_dx_ctn)
                                                                                                 ,-- 두번째 구분값의 시작위치 이후
                                                                                                  instr(to_char(b.cnls_dx_ctn),'=',1,2) -- 1. '=' 구분자가 있는 위치에
                                                                                                  +                                     -- 3. 더한다.
                                                                                                  regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,2) + 1),'[가-힣A-Za-z]')-- + 1 -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                                 ,-- 세번째 구분 값 이후 첫 문자위치 - 두번째 구분 값의 위치 
                                                                                                  instr(to_char(b.cnls_dx_ctn),'=',1,3) -- 1. '=' 구분자가 있는 위치에
                                                                                                  +                                     -- 3. 더한다.
                                                                                                  regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,3) + 1),'[가-힣A-Za-z]') - 1 -- 2. 세번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                                  -
                                                                                                  (-- 두번째 구분값의 시작위치 이후
                                                                                                  instr(to_char(b.cnls_dx_ctn),'=',1,2) -- 1. '=' 구분자가 있는 위치에
                                                                                                  +                                     -- 3. 더한다.
                                                                                                  regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,2) + 1),'[가-힣A-Za-z]')    -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                                  )
                                                                                                 ) 
                                                                                          )                                                 
                                                                                     ,'='
                                                                                     ,1
                                                                                     ,1
                                                                                     ) + 1
                                                                               )
                                                                        )
                                                                   )
                                                            ,''
                                                            )
                                                 else -- 그렇지 않으면 두번째 문구를 그대로 사용해 된다.
                                                      decode(
                                                             b.exmn_cd
                                                            ,'RC1184'
                                                            ,trim(
                                                                  substr(
                                                                         trim(
                                                                               substr(
                                                                                      to_char(b.cnls_dx_ctn)
                                                                                     ,-- 첫번째 구분값의 시작위치 이후
                                                                                      instr(to_char(b.cnls_dx_ctn),'=',1,1) -- 1. '=' 구분자가 있는 위치에
                                                                                      +                                     -- 3. 더한다.
                                                                                      regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,1) + 1),'[가-힣A-Za-z]')-- + 1 -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                     ,-- 세번째 구분 값의 위치 - 첫번째 구분 값의 위치 
                                                                                      instr(to_char(b.cnls_dx_ctn),'=',1,2) -- 1. '=' 구분자가 있는 위치에
                                                                                      +                                     -- 3. 더한다.
                                                                                      regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,2) + 1),'[가-힣A-Za-z]') - 1 -- 2. 두번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                      -
                                                                                      (-- 첫번째 구분값의 시작위치 이후
                                                                                      instr(to_char(b.cnls_dx_ctn),'=',1,1) -- 1. '=' 구분자가 있는 위치에
                                                                                      +                                     -- 3. 더한다.
                                                                                      regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,1) + 1),'[가-힣A-Za-z]')    -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                      )
                                                                                     ) 
                                                                              )
                                                                        ,instr(
                                                                               trim(
                                                                                     substr(
                                                                                            to_char(b.cnls_dx_ctn)
                                                                                           ,-- 첫번째 구분값의 시작위치 이후
                                                                                            instr(to_char(b.cnls_dx_ctn),'=',1,1) -- 1. '=' 구분자가 있는 위치에
                                                                                            +                                     -- 3. 더한다.
                                                                                            regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,1) + 1),'[가-힣A-Za-z]')-- + 1 -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                           ,-- 세번째 구분 값의 위치 - 첫번째 구분 값의 위치 
                                                                                            instr(to_char(b.cnls_dx_ctn),'=',1,2) -- 1. '=' 구분자가 있는 위치에
                                                                                            +                                     -- 3. 더한다.
                                                                                            regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,2) + 1),'[가-힣A-Za-z]') - 1 -- 2. 두번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                            -
                                                                                            (-- 첫번째 구분값의 시작위치 이후
                                                                                            instr(to_char(b.cnls_dx_ctn),'=',1,1) -- 1. '=' 구분자가 있는 위치에
                                                                                            +                                     -- 3. 더한다.
                                                                                            regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,1) + 1),'[가-힣A-Za-z]')    -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                            )
                                                                                           ) 
                                                                                    )
                                                                              ,'='
                                                                              ,1
                                                                              ,1
                                                                              ) + 1
                                                                        )
                                                                 )
                                                            ,''
                                                            )
                                                 end 
                                                          ,'[^0-9.]' -- 숫자와 소수점 외에
                                                          ,''
                                                          )
                                            ,1
                                            ,length(
                                                    regexp_replace(
                                                    case
                                                         when instr(lower(
                                                                          decode(
                                                                                 b.exmn_cd
                                                                                ,'RC1184'
                                                                                , trim(
                                                                                       substr(
                                                                                              to_char(b.cnls_dx_ctn)
                                                                                             ,-- 첫번째 구분값의 시작위치 이후
                                                                                              instr(to_char(b.cnls_dx_ctn),'=',1,1) -- 1. '=' 구분자가 있는 위치에
                                                                                              +                                     -- 3. 더한다.
                                                                                              regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,1) + 1),'[가-힣A-Za-z]')-- + 1 -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                             ,-- 세번째 구분 값의 위치 - 첫번째 구분 값의 위치 
                                                                                              instr(to_char(b.cnls_dx_ctn),'=',1,2) -- 1. '=' 구분자가 있는 위치에
                                                                                              +                                     -- 3. 더한다.
                                                                                              regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,2) + 1),'[가-힣A-Za-z]') - 1 -- 2. 두번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                              -
                                                                                              (-- 첫번째 구분값의 시작위치 이후
                                                                                              instr(to_char(b.cnls_dx_ctn),'=',1,1) -- 1. '=' 구분자가 있는 위치에
                                                                                              +                                     -- 3. 더한다.
                                                                                              regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,1) + 1),'[가-힣A-Za-z]')    -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                              )
                                                                                             ) 
                                                                                      )
                                                                                ,''
                                                                                )
                                                                         )
                                                                   ,'mass' -- 두번째 결과 문구에서 mass가 포함되어 있다면
                                                                   ,1
                                                                   ,1                      
                                                                   ) != 0
                                                         then -- 세번째 결과 문구를 가져와라
                                                              decode(
                                                                     b.exmn_cd
                                                                    ,'RC1184'
                                                                    ,decode(instr(to_char(b.cnls_dx_ctn),'=',1,3)
                                                                           ,0
                                                                           ,''
                                                                           ,trim(
                                                                                 substr(
                                                                                        trim(
                                                                                             substr(
                                                                                                    to_char(b.cnls_dx_ctn)
                                                                                                   ,-- 두번째 구분값의 시작위치 이후
                                                                                                    instr(to_char(b.cnls_dx_ctn),'=',1,2) -- 1. '=' 구분자가 있는 위치에
                                                                                                    +                                     -- 3. 더한다.
                                                                                                    regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,2) + 1),'[가-힣A-Za-z]')-- + 1 -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                                   ,-- 세번째 구분 값 이후 첫 문자위치 - 두번째 구분 값의 위치 
                                                                                                    instr(to_char(b.cnls_dx_ctn),'=',1,3) -- 1. '=' 구분자가 있는 위치에
                                                                                                    +                                     -- 3. 더한다.
                                                                                                    regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,3) + 1),'[가-힣A-Za-z]') - 1 -- 2. 세번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                                    -
                                                                                                    (-- 두번째 구분값의 시작위치 이후
                                                                                                    instr(to_char(b.cnls_dx_ctn),'=',1,2) -- 1. '=' 구분자가 있는 위치에
                                                                                                    +                                     -- 3. 더한다.
                                                                                                    regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,2) + 1),'[가-힣A-Za-z]')    -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                                    )
                                                                                                   ) 
                                                                                            )
                                                                                       ,instr(
                                                                                              trim(
                                                                                                   substr(
                                                                                                          to_char(b.cnls_dx_ctn)
                                                                                                         ,-- 두번째 구분값의 시작위치 이후
                                                                                                          instr(to_char(b.cnls_dx_ctn),'=',1,2) -- 1. '=' 구분자가 있는 위치에
                                                                                                          +                                     -- 3. 더한다.
                                                                                                          regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,2) + 1),'[가-힣A-Za-z]')-- + 1 -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                                         ,-- 세번째 구분 값 이후 첫 문자위치 - 두번째 구분 값의 위치 
                                                                                                          instr(to_char(b.cnls_dx_ctn),'=',1,3) -- 1. '=' 구분자가 있는 위치에
                                                                                                          +                                     -- 3. 더한다.
                                                                                                          regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,3) + 1),'[가-힣A-Za-z]') - 1 -- 2. 세번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                                          -
                                                                                                          (-- 두번째 구분값의 시작위치 이후
                                                                                                          instr(to_char(b.cnls_dx_ctn),'=',1,2) -- 1. '=' 구분자가 있는 위치에
                                                                                                          +                                     -- 3. 더한다.
                                                                                                          regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,2) + 1),'[가-힣A-Za-z]')    -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                                          )
                                                                                                         ) 
                                                                                                  )                                                 
                                                                                             ,'='
                                                                                             ,1
                                                                                             ,1
                                                                                             ) + 1
                                                                                       )
                                                                                )
                                                                           )
                                                                    ,''
                                                                    )
                                                         else -- 그렇지 않으면 두번째 문구를 그대로 사용해 된다.
                                                              decode(
                                                                     b.exmn_cd
                                                                    ,'RC1184'
                                                                    ,trim(
                                                                          substr(
                                                                                 trim(
                                                                                       substr(
                                                                                              to_char(b.cnls_dx_ctn)
                                                                                             ,-- 첫번째 구분값의 시작위치 이후
                                                                                              instr(to_char(b.cnls_dx_ctn),'=',1,1) -- 1. '=' 구분자가 있는 위치에
                                                                                              +                                     -- 3. 더한다.
                                                                                              regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,1) + 1),'[가-힣A-Za-z]')-- + 1 -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                             ,-- 세번째 구분 값의 위치 - 첫번째 구분 값의 위치 
                                                                                              instr(to_char(b.cnls_dx_ctn),'=',1,2) -- 1. '=' 구분자가 있는 위치에
                                                                                              +                                     -- 3. 더한다.
                                                                                              regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,2) + 1),'[가-힣A-Za-z]') - 1 -- 2. 두번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                              -
                                                                                              (-- 첫번째 구분값의 시작위치 이후
                                                                                              instr(to_char(b.cnls_dx_ctn),'=',1,1) -- 1. '=' 구분자가 있는 위치에
                                                                                              +                                     -- 3. 더한다.
                                                                                              regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,1) + 1),'[가-힣A-Za-z]')    -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                              )
                                                                                             ) 
                                                                                      )
                                                                                ,instr(
                                                                                       trim(
                                                                                             substr(
                                                                                                    to_char(b.cnls_dx_ctn)
                                                                                                   ,-- 첫번째 구분값의 시작위치 이후
                                                                                                    instr(to_char(b.cnls_dx_ctn),'=',1,1) -- 1. '=' 구분자가 있는 위치에
                                                                                                    +                                     -- 3. 더한다.
                                                                                                    regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,1) + 1),'[가-힣A-Za-z]')-- + 1 -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                                   ,-- 세번째 구분 값의 위치 - 첫번째 구분 값의 위치 
                                                                                                    instr(to_char(b.cnls_dx_ctn),'=',1,2) -- 1. '=' 구분자가 있는 위치에
                                                                                                    +                                     -- 3. 더한다.
                                                                                                    regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,2) + 1),'[가-힣A-Za-z]') - 1 -- 2. 두번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                                    -
                                                                                                    (-- 첫번째 구분값의 시작위치 이후
                                                                                                    instr(to_char(b.cnls_dx_ctn),'=',1,1) -- 1. '=' 구분자가 있는 위치에
                                                                                                    +                                     -- 3. 더한다.
                                                                                                    regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,1) + 1),'[가-힣A-Za-z]')    -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                                    )
                                                                                                   ) 
                                                                                            )
                                                                                      ,'='
                                                                                      ,1
                                                                                      ,1
                                                                                      ) + 1
                                                                                )
                                                                         )
                                                                    ,''
                                                                    )
                                                         end 
                                                                  ,'[^0-9.]' -- 숫자와 소수점 외에
                                                                  ,''
                                                                  )
                                                   ) - 1
                                            )
                                else 
                                     regexp_replace(
                                     case
                                          when instr(lower(
                                                           decode(
                                                                  b.exmn_cd
                                                                 ,'RC1184'
                                                                 , trim(
                                                                        substr(
                                                                               to_char(b.cnls_dx_ctn)
                                                                              ,-- 첫번째 구분값의 시작위치 이후
                                                                               instr(to_char(b.cnls_dx_ctn),'=',1,1) -- 1. '=' 구분자가 있는 위치에
                                                                               +                                     -- 3. 더한다.
                                                                               regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,1) + 1),'[가-힣A-Za-z]')-- + 1 -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                              ,-- 세번째 구분 값의 위치 - 첫번째 구분 값의 위치 
                                                                               instr(to_char(b.cnls_dx_ctn),'=',1,2) -- 1. '=' 구분자가 있는 위치에
                                                                               +                                     -- 3. 더한다.
                                                                               regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,2) + 1),'[가-힣A-Za-z]') - 1 -- 2. 두번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                               -
                                                                               (-- 첫번째 구분값의 시작위치 이후
                                                                               instr(to_char(b.cnls_dx_ctn),'=',1,1) -- 1. '=' 구분자가 있는 위치에
                                                                               +                                     -- 3. 더한다.
                                                                               regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,1) + 1),'[가-힣A-Za-z]')    -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                               )
                                                                              ) 
                                                                       )
                                                                 ,''
                                                                 )
                                                          )
                                                    ,'mass' -- 두번째 결과 문구에서 mass가 포함되어 있다면
                                                    ,1
                                                    ,1                      
                                                    ) != 0
                                          then -- 세번째 결과 문구를 가져와라
                                               decode(
                                                      b.exmn_cd
                                                     ,'RC1184'
                                                     ,decode(instr(to_char(b.cnls_dx_ctn),'=',1,3)
                                                            ,0
                                                            ,''
                                                            ,trim(
                                                                  substr(
                                                                         trim(
                                                                              substr(
                                                                                     to_char(b.cnls_dx_ctn)
                                                                                    ,-- 두번째 구분값의 시작위치 이후
                                                                                     instr(to_char(b.cnls_dx_ctn),'=',1,2) -- 1. '=' 구분자가 있는 위치에
                                                                                     +                                     -- 3. 더한다.
                                                                                     regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,2) + 1),'[가-힣A-Za-z]')-- + 1 -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                    ,-- 세번째 구분 값 이후 첫 문자위치 - 두번째 구분 값의 위치 
                                                                                     instr(to_char(b.cnls_dx_ctn),'=',1,3) -- 1. '=' 구분자가 있는 위치에
                                                                                     +                                     -- 3. 더한다.
                                                                                     regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,3) + 1),'[가-힣A-Za-z]') - 1 -- 2. 세번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                     -
                                                                                     (-- 두번째 구분값의 시작위치 이후
                                                                                     instr(to_char(b.cnls_dx_ctn),'=',1,2) -- 1. '=' 구분자가 있는 위치에
                                                                                     +                                     -- 3. 더한다.
                                                                                     regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,2) + 1),'[가-힣A-Za-z]')    -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                     )
                                                                                    ) 
                                                                             )
                                                                        ,instr(
                                                                               trim(
                                                                                    substr(
                                                                                           to_char(b.cnls_dx_ctn)
                                                                                          ,-- 두번째 구분값의 시작위치 이후
                                                                                           instr(to_char(b.cnls_dx_ctn),'=',1,2) -- 1. '=' 구분자가 있는 위치에
                                                                                           +                                     -- 3. 더한다.
                                                                                           regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,2) + 1),'[가-힣A-Za-z]')-- + 1 -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                          ,-- 세번째 구분 값 이후 첫 문자위치 - 두번째 구분 값의 위치 
                                                                                           instr(to_char(b.cnls_dx_ctn),'=',1,3) -- 1. '=' 구분자가 있는 위치에
                                                                                           +                                     -- 3. 더한다.
                                                                                           regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,3) + 1),'[가-힣A-Za-z]') - 1 -- 2. 세번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                           -
                                                                                           (-- 두번째 구분값의 시작위치 이후
                                                                                           instr(to_char(b.cnls_dx_ctn),'=',1,2) -- 1. '=' 구분자가 있는 위치에
                                                                                           +                                     -- 3. 더한다.
                                                                                           regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,2) + 1),'[가-힣A-Za-z]')    -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                           )
                                                                                          ) 
                                                                                   )                                                 
                                                                              ,'='
                                                                              ,1
                                                                              ,1
                                                                              ) + 1
                                                                        )
                                                                 )
                                                            )
                                                     ,''
                                                     )
                                          else -- 그렇지 않으면 두번째 문구를 그대로 사용해 된다.
                                               decode(
                                                      b.exmn_cd
                                                     ,'RC1184'
                                                     ,trim(
                                                           substr(
                                                                  trim(
                                                                        substr(
                                                                               to_char(b.cnls_dx_ctn)
                                                                              ,-- 첫번째 구분값의 시작위치 이후
                                                                               instr(to_char(b.cnls_dx_ctn),'=',1,1) -- 1. '=' 구분자가 있는 위치에
                                                                               +                                     -- 3. 더한다.
                                                                               regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,1) + 1),'[가-힣A-Za-z]')-- + 1 -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                              ,-- 세번째 구분 값의 위치 - 첫번째 구분 값의 위치 
                                                                               instr(to_char(b.cnls_dx_ctn),'=',1,2) -- 1. '=' 구분자가 있는 위치에
                                                                               +                                     -- 3. 더한다.
                                                                               regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,2) + 1),'[가-힣A-Za-z]') - 1 -- 2. 두번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                               -
                                                                               (-- 첫번째 구분값의 시작위치 이후
                                                                               instr(to_char(b.cnls_dx_ctn),'=',1,1) -- 1. '=' 구분자가 있는 위치에
                                                                               +                                     -- 3. 더한다.
                                                                               regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,1) + 1),'[가-힣A-Za-z]')    -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                               )
                                                                              ) 
                                                                       )
                                                                 ,instr(
                                                                        trim(
                                                                              substr(
                                                                                     to_char(b.cnls_dx_ctn)
                                                                                    ,-- 첫번째 구분값의 시작위치 이후
                                                                                     instr(to_char(b.cnls_dx_ctn),'=',1,1) -- 1. '=' 구분자가 있는 위치에
                                                                                     +                                     -- 3. 더한다.
                                                                                     regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,1) + 1),'[가-힣A-Za-z]')-- + 1 -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                    ,-- 세번째 구분 값의 위치 - 첫번째 구분 값의 위치 
                                                                                     instr(to_char(b.cnls_dx_ctn),'=',1,2) -- 1. '=' 구분자가 있는 위치에
                                                                                     +                                     -- 3. 더한다.
                                                                                     regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,2) + 1),'[가-힣A-Za-z]') - 1 -- 2. 두번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                     -
                                                                                     (-- 첫번째 구분값의 시작위치 이후
                                                                                     instr(to_char(b.cnls_dx_ctn),'=',1,1) -- 1. '=' 구분자가 있는 위치에
                                                                                     +                                     -- 3. 더한다.
                                                                                     regexp_instr(substr(to_char(b.cnls_dx_ctn),instr(to_char(b.cnls_dx_ctn),'=',1,1) + 1),'[가-힣A-Za-z]')    -- 2. 첫번째 '=' 이후로 나오는 첫 문자의 자리위치에서 1을 빼준 것을
                                                                                     )
                                                                                    ) 
                                                                             )
                                                                       ,'='
                                                                       ,1
                                                                       ,1
                                                                       ) + 1
                                                                 )
                                                          )
                                                     ,''
                                                     )
                                          end 
                                                   ,'[^0-9.]' -- 숫자와 소수점 외에
                                                   ,''
                                                   )
                                end cleaned_ncvl_vl -- volume_130
                         , '' exrs_ncvl_vl
                         , '' exrs_unit_nm
                         , '' nrml_lwlm_vl
                         , '' nrml_uplm_vl
                         , decode(b.exmn_cd,'RC1184',to_char(b.exrs_ctn),'') EXRS_CTN
                         , decode(b.exmn_cd,'RC1184',to_char(b.gros_rslt_ctn),'') EXRS_info
                         , decode(b.exmn_cd,'RC1184',to_char(b.cnls_dx_ctn),'') EXRS_cnls
                         , decode(b.exmn_cd,'RC1184',to_char(b.exrs_rmrk_ctn),'') EXRS_comments
                      from 스키마.3E3C0E433E3C0E3E28@DAWNR_SMCDWS a
                         , 스키마.3E3243333E2E143C28@DAWNR_SMCDWS b
                         , 스키마.3C15332B3C20431528@DAWNR_SMCDWS c
                     where a.ordr_ymd between to_date(&indata_frdt,'yyyymmdd') and to_date(&indata_todt,'yyyymmdd') -- to_date('20220602','yyyymmdd') and to_date('20220602','yyyymmdd')
                       and a.cncl_dt is null
                       and b.ptno = a.ptno
                       and b.ordr_ymd = a.ordr_ymd
                       and b.exmn_cd = 'RC1184'
                       and nvl(b.exrs_updt_yn,'N') != 'Y'
                       and c.ptno = b.ptno
                       and c.ordr_ymd = b.ordr_ymd
                       and c.ordr_sno = b.ordr_sno
                       and c.codv_cd = 'G'
                       and nvl(c.dc_dvsn_cd,'N') != 'X'
                       and c.hlsc_apnt_no = a.apnt_no
                               and a.ptno not in (-- 자료추출 금지 대상자
                                                 &not_in_ptno
                                                 )
                   ) a
           )
                
            loop
            begin   -- 데이터 insert
                          insert /*+ append */
                            into 스키마.1543294D47144D43333E2E1428
                                 (
                                   PTNO
                                 , SM_DATE
                                 , APNT_NO
                                 , EXMN_TYP
                                 , ORDR_CD
                                 , ORDR_SNO
                                 , EXMN_CD
                                 , ORDR_YMD
                                 , EXEC_TIME
                                 , CLEANED_NCVL_VL
                                 , EXRS_NCVL_VL
                                 , EXRS_UNIT_NM
                                 , NRML_LWLM_VL
                                 , NRML_UPLM_VL
                                 , EXRS_CTN
                                 , EXRS_INFO
                                 , EXRS_CNLS
                                 , EXRS_COMMENTS
                                 , UPDT_VER
                                 , RGST_DT
                                 , LAST_UPDT_DT
                                 )
                           values(
                                   drh.ptno
                                 , drh.sm_date
                                 , drh.apnt_no
                                 , drh.exmn_typ
                                 , drh.ordr_cd
                                 , drh.ordr_sno
                                 , drh.exmn_cd
                                 , drh.ordr_ymd
                                 , drh.EXEC_TIME
                                 , drh.cleaned_ncvl_vl
                                 , drh.exrs_ncvl_vl
                                 , drh.exrs_unit_nm
                                 , drh.nrml_lwlm_vl
                                 , drh.nrml_uplm_vl
                                 , drh.exrs_ctn
                                 , drh.exrs_info
                                 , drh.exrs_cnls
                                 , drh.exrs_comments
                                 , drh.updt_ver
                                 , drh.rgst_dt
                                 , drh.last_updt_dt
                                 )
                                 ;
                  
                         commit;
                       
                       incnt := incnt + 1;
                  
                       exception
                       when others then
                          rollback;
                          errcnt := errcnt + 1;
            
            end;
            end loop;
       
:var_msg2  := 'insert '  || to_char(incnt)    || ' 건';
:var_msg3  := 'error '   || to_char(errcnt)   || ' 건';
   
end ;
/
print var_msg2
print var_msg3
spool off
exit;
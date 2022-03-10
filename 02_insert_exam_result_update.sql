-- 결과치환 대상 검사, 에러수정 최종파일.
-- 코드1개를 하나 여러 개를 같이 하나 시간 차이가 크지 않아서, 결과 UPDATE를 나중에 실행키로 함.
-- 메시지 출력기능 추가. 메시지 확인은 F5를 눌러야 가능함.
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
                 , '1'                  as updt_ver
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
                         , ''
--                         , case
--                                when lower(b.exrs_ncvl_vl) like 'am%'    then '1'
--                                when lower(b.exrs_ncvl_vl) like 'br%'    then '2'
--                                when lower(b.exrs_ncvl_vl) like 'gr%'    then '3'
--                                when lower(b.exrs_ncvl_vl) like 'or%'    then '4'
--                                when lower(b.exrs_ncvl_vl) like 're%'    then '5'
--                                when (lower(b.exrs_ncvl_vl) like '%st%'
--                                     or
--                                      lower(b.exrs_ncvl_vl) like '%sr%'
--                                     )                                   then '6' -- 검증 후 수정
--                                when lower(b.exrs_ncvl_vl) like 'ye%'    then '7'
--                                when (lower(b.exrs_ncvl_vl) like 'milky%'
--                                     or
--                                      lower(b.exrs_ncvl_vl) like 'color%'
--                                     or
--                                      lower(b.exrs_ncvl_vl) like 'whi%'
--                                     or
--                                      lower(b.exrs_ncvl_vl) like 'other%'
--                                     )                                   then '8'
--                           else ''
--                           end  
                           cleaned_vl
                         , b.exrs_ncvl_vl
                         , b.exrs_unit_nm
                         , b.nrml_lwlm_ncvl_vl
                         , b.nrml_uplm_ncvl_vl
                         , row_number () over(partition by a.ptno, a.ordr_ymd, b.exmn_cd order by c.enfr_dt desc, c.ordr_sno desc, c.ordr_cd) RN /* 같은 날 중복처방/재검인 경우를 구분하기 위해 실시를 가장 나중에 한 것을 처음으로 가져옴. */
                      from 스키마.3E3C0E433E3C0E3E28@SMISR_스키마 a
                         , 스키마.3E3243333E2E143C28@SMISR_스키마 b
                         , 스키마.3C15332B3C20431528@SMISR_스키마 c
                         , 스키마.3E3C3C5B0C233C3E28@SMISR_스키마 e
                     where a.ordr_ymd between to_date(&Y||'0901','yyyymmdd') and to_date(&Y||'0930','yyyymmdd')
                       and a.cncl_dt is null
                       and a.pckg_cd = e.pckg_cd
                       and (substr(e.pckg_type_cd,1,1) not in ('6','7','9') -- 생습, 스포츠외래, 서비스 패키지 제외.
                           or
                            e.pckg_type_cd not in ('5W','5Z') -- 서비스 형태의 특화 패키지 대상자 제외
                           )
                       and a.ptno not in (-- 자료추출 금지 대상자
                                          &not_in_ptno
                                         )
                       and a.ptno = b.ptno
                       and a.ordr_ymd = b.ordr_ymd
                       and b.exmn_cd in (
                                          'BL5111','BL5112','BL5113','BL5115','BL5116','BL5117','BL512001'
                                         ,'BL6111','BL6112','BL6115','BL6116','BL6117','BL6118','BL6119','BL6120','BL6121','BL6122'
                                         ,'NR0101','NR0102','NR0103','NR0201','NR0202','NR0305'
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
                                 from 스키마.3E3C3343332B0E3C28@SMISR_스키마 x
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
                            into smcdrh.1543294D47144D43333E2E1428
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
spool off
exit

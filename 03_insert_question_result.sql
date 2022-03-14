-- 문진 정보 전체 데이터 이관 실행 script
-- 문진 기본정보 insert, 문진응답자 전체
-- 변수 길이가 길다는 에러메세지 때문에 변수를 숫자정보로 치환
-- 메시지 출력기능 추가. 메시지 확인은 F5를 눌러야 가능함
variable var_msg2 char(40);
variable var_msg3 char(40);
  
declare
    incnt     number(10) := 0;
    errcnt    number(10) := 0;
        
begin
for drh in (
            -- 데이터 select
            select a.RPRS_APNT_NO                    as "1"
                 , a.PTNO                            as "2"
                 , a.ORDR_PRRN_YMD                   as "3"
                 , a.INPC_CD                         as "4"
                 , a.FOREIGN                         as "5"
                 , '1.0'                             as UPDT_VER
                 , sysdate                           as rgst_dt
                 , sysdate                           as last_updt_dt
              from (-- 문진 응답내역 전체항목, 최종(가족력 기타암 통합만 있는 것)
                    -- 문진 응답자 기본 사항
                    -- SMISR 서버의 메모리 리소스를 매우 잡아 먹는 관계로 카테고리 분할함.
                    select /*+ ordered use_nl(A F) index(a 3E3C0E433E3C0E3E28_i13) index(f 3E3C23302E333E0E28_pk) */
                           f.rprs_apnt_no
                         , F.PTNO
                         , f.ordr_prrn_ymd
                         , f.inpc_cd
                         , decode(substr(b.brrn,1,1),'5','1','6','1','7','1','8','1','0') foreign
                      from 스키마.3E3C0E433E3C0E3E28@SMISR_스키마  a
                         , 스키마.0E5B5B285B28402857@SMISR_스키마  b
                         , 스키마.3E3C23302E333E0E28@SMISR_스키마  f
                         , 스키마.3E3C23302E333E3C28@SMISR_스키마  g
                     where 
                           a.ordr_prrn_ymd between to_date(&qfrdt,'yyyymmdd') and to_date(&qtodt,'yyyymmdd')
                       and a.ordr_ymd is not null
                       and a.cncl_dt is null
                       and b.ptno = a.ptno
                       and f.ptno = a.ptno
                       and f.ordr_prrn_ymd = a.ordr_prrn_ymd
                       and f.inpc_cd in ('AM','RR','MA1')
                       AND (-- AM, RR의 경우는 응답한 것만 저장되었으므로, 모두 범위에 포함
                                      (f.inpc_cd = 'AM'  and f.item_sno between 1 and 500)
                                   or (f.inpc_cd = 'RR'  and f.item_sno between 1 and  300)
                                   OR (f.inpc_cd = 'MA1' and f.item_sno between 1 and  917)
                           )
                       and f.rprs_apnt_no = a.rprs_apnt_no
                       and f.qstn_cd1 = g.inqy_cd(+)
                       and a.ptno not in (
                                          &not_in_ptno
                                         )
                     group by f.rprs_apnt_no
                         , F.PTNO
                         , f.ordr_prrn_ymd
                         , f.inpc_cd
                         , b.brrn 
                   ) a
                       
           )
                
            loop
            begin   -- 데이터 insert
                          insert /*+ append */
                            into 스키마.1543294D47144D302E333E0E28 a
                                 (
                                   RPRS_APNT_NO
                                 , PTNO
                                 , ORDR_PRRN_YMD
                                 , QUESTION_TYPE
                                 , FOREIGN
                                 , UPDT_VER
                                 , RGST_DT
                                 , LAST_UPDT_DT
                                 )
                           values(
                                   drh."1"
                                 , drh."2"
                                 , drh."3"
                                 , drh."4"
                                 , drh."5"
                                 , drh.UPDT_VER
                                 , drh.RGST_DT
                                 , drh.LAST_UPDT_DT
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
   
-- 문진 정보 update, 건진동기, 생활습관, 알러지, 약물이상반응, 수술력
-- 변수 길이가 길다는 에러메세지 때문에 변수를 숫자정보로 치환
-- 메시지 출력기능 추가. 메시지 확인은 F5를 눌러야 가능함
variable var_msg2 char(40);
variable var_msg3 char(40);
  
declare
    upcnt     number(10) := 0;
    errcnt    number(10) := 0;
        
begin
for drh in (
            -- 데이터 select
            select a.RPRS_APNT_NO                   as RPRS_APNT_NO
                 , a.PTNO                           as ptno
                 , a.ORDR_PRRN_YMD                  as ordr_prrn_ymd
                 , a.INPC_CD                         as "4"
                 , a.FOREIGN                         as "5"
                 , a.EXAM_MOTIVE                     as "6"
                 , a.EXAM                            as "7"
                 , a.EXAM_FIRST_AGE                  as "8"
                 , a.EXAM_MOST_RECENT_YY             as "9"
                 , a.EXAM_MOST_RECENT_MM             as "10"
                 , a.EXAM_FREQ_YR                    as "11"
                 , a.EXAM_PLACE                      as "12"
                 , a.MARITAL_STATUS                  as "13"
                 , a.EDUCATION                       as "14"
                 , a.INCOME                          as "15"
                 , a.SMK_YS                          as "16"
                 , a.SMK                             as "17"
                 , a.SMK_DURATION                    as "18"
                 , a.SMK_CURRENT_AMOUNT              as "19"
                 , a.SMK_START_AGE                   as "20"
                 , a.SMK_END_YR                      as "21"
                 , a.SMK_PACKYRS                     as "22"
                 , a.ALC_YS                          as "23"
                 , a.ALC                             as "24"
                 , a.ALC_FREQ                        as "25"
                 , a.ALC_AMOUNT_DRINKS               as "26"
                 , a.ALC_START_AGE                   as "27"
                 , a.ALC_DURATION                    as "28"
                 , a.ALC_ENDYR                       as "29"
                 , a.ALC_AMOUNT_GRAMS                as "30"
                 , a.PHY                             as "31"
                 , a.OVERALL_PHYSICAL_ACTIVITY       as "32"
                 , a.PHY_FREQ_2009                   as "33"
                 , a.PHY_DURATION_2009               as "34"
                 , a.PHY_FREQ                        as "35"
                 , a.PHY_DURATION                    as "36"
                 , a.PHY_STARTYR                     as "37"
                 , a.PHY_WALKING                     as "38"
                 , a.PHY_JOGGING                     as "39"
                 , a.PHY_TENNIS                      as "40"
                 , a.PHY_GOLF                        as "41"
                 , a.PHY_SWIMMING                    as "42"
                 , a.PHY_CLIMBING                    as "43"
                 , a.PHY_AEROBIC                     as "44"
                 , a.PHY_FITNESS                     as "45"
                 , a.PHY_OTHER                       as "46"
                 , a.ALLERGY                         as "47"
                 , a.ALLERGY_PENICILLIN              as "48"
                 , a.ALLERGY_SULFA                   as "49"
                 , a.ALLERGY_CONTRAST_AGENT          as "50"
                 , a.ALLERGY_LOCAL_ANESTHETIC        as "51"
                 , a.ALLERGY_ASPIRIN                 as "52"
                 , a.ALLERGY_OTHER                   as "53"
                 , a.ALLERGY_UNKNOWN                 as "54"
                 , a.ADVERSE_MED                     as "55"
                 , a.ADVERSE_MED_ANTIBIOTICS         as "56"
                 , a.ADVERSE_MED_CONTRAST_AGENT      as "57"
                 , a.ADVERSE_MED_LOCAL_ANESTHETIC    as "58"
                 , a.ADVERSE_MED_ASPIRIN_PAINKILLER  as "59"
                 , a.ADVERSE_MED_OTHER               as "60"
                 , a.SURGERY_STOMACH                 as "61"
                 , a.SURGERY_GALLBLADDER             as "62"
                 , a.SURGERY_COLON                   as "63"
                 , a.SURGERY_APPENDIX                as "64"
                 , a.SURGERY_THYROID                 as "65"
                 , a.SURGERY_UTERUS                  as "66"
                 , a.SURGERY_OVARY                   as "67"
                 , a.SURGERY_BREAST                  as "68"
                 , a.SURGERY_KIDNEY                  as "69"
                 , a.SURGERY_OTHER                   as "70"
                 , sysdate                           as last_updt_dt
              from (-- 문진 응답내역 전체항목, 최종(가족력 기타암 통합만 있는 것)
                    -- 문진 응답내역 중 건진동기, 생활습관, 알러지, 약물이상반응, 수술력
                    -- SMISR 서버의 메모리 리소스를 매우 잡아 먹는 관계로 카테고리 분할함.
                    select /*+ ordered use_nl(A F) index(a 3E3C0E433E3C0E3E28_i13) index(f 3E3C23302E333E0E28_pk) */
                           f.rprs_apnt_no
                         , F.PTNO
                         , f.ordr_prrn_ymd
                         , f.inpc_cd
                         , decode(substr(b.brrn,1,1),'5','1','6','1','7','1','8','1','0') foreign
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM2Y'  ,'1'
                                                                      ,'AM3Y'  ,'0'
                                                                      ,'AM2'   ,'1'
                                                                      ,'AM3'   ,'0'
                                                                      ,'MA12Y' ,'1'
                                                                      ,'MA13Y' ,'0'
                                                                      ,'RR2Y'  ,'1'
                                                                      ,'RR3Y'  ,'0','')) exam_motive
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM6Y'  ,'1'
                                                                      ,'AM10Y' ,'0'
                                                                      ,'AM6'   ,'1'
                                                                      ,'AM10'  ,'0'
                                     ,decode(f.inpc_cd,'RR' ,'9999'
                                                      ,'MA1','9999','')
                                     )
                              ) exam
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM7'  ,f.inqy_rspn_ctn1
                                     ,decode(f.inpc_cd,'RR' ,'9999'
                                                      ,'MA1','9999','')
                                     )
                              ) exam_first_age
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM8'  ,f.inqy_rspn_ctn1
                                     ,decode(f.inpc_cd,'RR' ,'9999'
                                                      ,'MA1','9999','')
                                     )
                              ) exam_most_recent_yy
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM8'  ,f.inqy_rspn_ctn2
                                     ,decode(f.inpc_cd,'RR' ,'9999'
                                                      ,'MA1','9999','')
                                     )
                              ) exam_most_recent_mm
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM9'  ,f.inqy_rspn_ctn2
                                     ,decode(f.inpc_cd,'RR' ,'9999'
                                                      ,'MA1','9999','')
                                     )
                              ) exam_freq_yr
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'RR5Y' ,'1'
                                                                      ,'RR6Y' ,'0'
                                                                      ,'RR5'  ,'1'
                                                                      ,'RR6'  ,'0'
                                                                      ,decode(f.inpc_cd,'AM' ,'9999'
                                                                                       ,'MA1','9999','')
                                     )
                              ) exam_place
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM12Y' ,'0'
                                                                      ,'AM13Y' ,'1'
                                                                      ,'AM14Y' ,'2'
                                                                      ,'AM15Y' ,'3'
                                                                      ,'AM16Y' ,'4'
                                                                      ,'RR8Y' ,'0'
                                                                      ,'RR9Y' ,'1'
                                                                      ,'RR10Y','2'
                                                                      ,'RR11Y','3'
                                                                      ,'RR12Y','4'
                                                                      ,'AM12'  ,'0'
                                                                      ,'AM13'  ,'1'
                                                                      ,'AM14'  ,'2'
                                                                      ,'AM15'  ,'3'
                                                                      ,'AM16'  ,'4'
                                                                      ,'RR8'  ,'0'
                                                                      ,'RR9'  ,'1'
                                                                      ,'RR10' ,'2'
                                                                      ,'RR11' ,'3'
                                                                      ,'RR12' ,'4'
                                     ,decode(f.inpc_cd,'MA1','9999','')
                                     )
                              ) marital_status
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM18Y' ,'0'
                                                                      ,'AM19Y' ,'1'
                                                                      ,'AM20Y' ,'2'
                                                                      ,'AM21Y' ,'3'
                                                                      ,'AM22Y' ,'4'
                                                                      ,'AM23Y' ,'5'
                                                                      ,'AM18'  ,'0'
                                                                      ,'AM19'  ,'1'
                                                                      ,'AM20'  ,'2'
                                                                      ,'AM21'  ,'3'
                                                                      ,'AM22'  ,'4'
                                                                      ,'AM23'  ,'5'
                                     ,decode(f.inpc_cd,'RR' ,'9999'
                                                      ,'MA1','9999','')
                                     )
                              ) education
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM25Y' ,'0'
                                                                      ,'AM26Y' ,'1'
                                                                      ,'AM27Y' ,'2'
                                                                      ,'AM28Y' ,'3'
                                                                      ,'AM29Y' ,'4'
                                                                      ,'AM25'  ,'0'
                                                                      ,'AM26'  ,'1'
                                                                      ,'AM27'  ,'2'
                                                                      ,'AM28'  ,'3'
                                                                      ,'AM29'  ,'4'
                                     ,decode(f.inpc_cd,'RR' ,'9999'
                                                      ,'MA1','9999','')
                                     )
                              ) income
                         /* Smoking */
                         , case
                                when /* 흡연력 관련 응답 내역이 있으면 1 */
                                     count(
                                           case 
                                                when f.inpc_cd = 'AM' and (f.item_sno between 52 and 58) then f.inqy_rspn_cd
                                                when f.inpc_cd = 'RR' and (f.item_sno between 46 and 48) then f.inqy_rspn_cd
                                                when f.inpc_cd = 'MA1' and (f.item_sno between 7 and 21) then f.ceck_yn||f.inqy_rspn_ctn1 -- MA1 문진의 경우 CTN은 응답이 있어도 ceck_yn이 null이므로 함께 고려
                                                when f.inpc_cd = 'MA1' and (f.item_sno between 7 and 21) then f.inqy_rspn_ctn1
                                                else ''
                                           end 
                                          ) > 0
                                then '1'
                                when /* 흡연력 관련 응답 내역이 없고, 원래 안 피우면 0 */
                                     count(
                                           case 
                                                when f.inpc_cd = 'AM' and (f.item_sno between 52 and 58) then f.inqy_rspn_cd
                                                when f.inpc_cd = 'RR' and (f.item_sno between 46 and 48) then f.inqy_rspn_cd
                                                when f.inpc_cd = 'MA1' and (f.item_sno between 7 and 21) then f.ceck_yn||f.inqy_rspn_ctn1 -- MA1 문진의 경우 CTN은 응답이 있어도 ceck_yn이 null이므로 함께 고려
                                                when f.inpc_cd = 'MA1' and (f.item_sno between 7 and 21) then f.inqy_rspn_ctn1
                                                else ''
                                           end 
                                          ) = 0
                                     and 
                                     count(
                                           case 
                                                when f.inpc_cd||f.item_sno = 'AM59' then f.inqy_rspn_cd
                                                when f.inpc_cd||f.item_sno = 'RR49' then f.inqy_rspn_cd
                                                when f.inpc_cd||f.item_sno||f.ceck_yn = 'MA16Y' then f.ceck_yn
                                                else ''
                                           end 
                                          ) = 1
                                then '0'
                                else ''
                           end smk_ys
                         , case
                                when /* 흡연력 관련 응답 내역이 없고, 원래 안 피우면 0 */
                                     count(
                                           case 
                                                when f.inpc_cd = 'AM' and (f.item_sno between 52 and 58) then f.inqy_rspn_cd
                                                when f.inpc_cd = 'RR' and (f.item_sno between 46 and 48) then f.inqy_rspn_cd
                                                when f.inpc_cd = 'MA1' and (f.item_sno between 7 and 21) then f.ceck_yn||f.inqy_rspn_ctn1 -- MA1 문진의 경우 CTN은 응답이 있어도 ceck_yn이 null이므로 함께 고려
                                                when f.inpc_cd = 'MA1' and (f.item_sno between 7 and 21) then f.inqy_rspn_ctn1
                                                else ''
                                           end 
                                          ) = 0
                                     and 
                                     count(
                                           case 
                                                when f.inpc_cd||f.item_sno = 'AM59' then f.inqy_rspn_cd
                                                when f.inpc_cd||f.item_sno = 'RR49' then f.inqy_rspn_cd
                                                when f.inpc_cd||f.item_sno||f.ceck_yn = 'MA16Y' then f.ceck_yn
                                                else ''
                                           end 
                                          ) = 1
                                then '0'
                                else MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM57Y' ,'2'
                                                                                ,'AM58Y' ,'1'--,''))  AMQ0074
                                                                                ,'AM57'  ,'2'
                                                                                ,'AM58'  ,'1'--,''))  AMQ0074
                                                                                ,'RR46Y' ,'2'
                                                                                ,'RR48Y' ,'1'--,''))                                         RRQ05
                                                                                ,'RR46' ,'2'
                                                                                ,'RR48' ,'1'--,''))                                         RRQ05
                                                                                ,'MA17Y' ,'1'
                                                                                ,'MA18Y' ,'2'--,''))             MA1Q02
                                            ,''))
                           end smk
                         , max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM54'  ,f.inqy_rspn_ctn1 
                                                                      ,'AM54Y' ,f.inqy_rspn_ctn1-- ,''))                                 AMQ0072
                                                                      ,'MA110' ,f.inqy_rspn_ctn1
                                     ,DECODE(f.inpc_cd,'RR','9999','')
                                     )
                              ) smk_duration
                         , min(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM55'  ,f.inqy_rspn_ctn1 
                                                                      ,'AM55Y' ,f.inqy_rspn_ctn1-- ,''))                                 AMQ0073
                                                                      ,'RR47'  ,f.inqy_rspn_ctn1
                                                                      ,'RR47Y' ,f.inqy_rspn_ctn1--,''))                                  RRQ0501
                                                                      ,'MA112Y','0'
                                                                      ,'MA113Y','1'
                                                                      ,'MA114Y','2'
                                                                      ,'MA115Y','3'--,''))                                               MA1Q0203
                                     ,'')
                              ) smk_current_amount
                         , max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM53'  ,f.inqy_rspn_ctn1 
                                                                      ,'AM53Y' ,f.inqy_rspn_ctn1-- ,''))                                 AMQ0071
                                                                      ,'MA19'  ,f.inqy_rspn_ctn1--,''))                                  MA1Q0201
                                     ,DECODE(f.inpc_cd,'RR','9999','')
                                     )
                              ) smk_start_age
                         , max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM58'  ,f.inqy_rspn_ctn1 
                                                                      ,'AM58Y' ,f.inqy_rspn_ctn1-- ,''))                                 AMQ0074
                                                                      ,'MA117Y','0'
                                                                      ,'MA118Y','1'
                                                                      ,'MA119Y','2'
                                                                      ,'MA120Y','3'
                                                                      ,'MA121Y','4'--,''))                                               MA1Q0204
                                     ,DECODE(f.inpc_cd,'RR','9999','')
                                     )
                              ) smk_end_yr
                         , min(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA112Y',5--'M0'
                                                                      ,'MA113Y',15--'M1'
                                                                      ,'MA114Y',25--'M2'
                                                                      ,'MA115Y',35--'M3'--,''))                                               MA1Q0203
                                     ,''
                                     )
                              ) 
                           /20
                           *
                           case 
                                when regexp_replace(max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA110' ,f.inqy_rspn_ctn1,'')),'^-?[0-9]+((\.[0-9]+)([Ee][+-][0-9]+)?)?','') is null 
                                then max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA110' ,f.inqy_rspn_ctn1,''))
                                else ''
                           end smk_packyrs
                         /* Alcohol */
                         , case
                                when /* 음주 관련 응답 내역이 있으면 1 */
                                     count(
                                           case 
                                                when f.inpc_cd = 'AM' and (f.item_sno between 61 and 78) then f.inqy_rspn_cd
                                                when f.inpc_cd = 'RR' and (f.item_sno between 51 and 64) then f.inqy_rspn_cd
                                                when f.inpc_cd = 'MA1' and (f.item_sno between 24 and 37) then f.ceck_yn||f.inqy_rspn_ctn1 -- MA1 문진의 경우 CTN은 응답이 있어도 ceck_yn이 null이므로 함께 고려
                                                else ''
                                           end 
                                          ) > 0
                                then '1'
                                when /* 음주 관련 응답 내역이 없고, 원래 안 마시면 0 */
                                     count(
                                           case 
                                                when f.inpc_cd = 'AM' and (f.item_sno between 61 and 78) then f.inqy_rspn_cd
                                                when f.inpc_cd = 'RR' and (f.item_sno between 51 and 64) then f.inqy_rspn_cd
                                                when f.inpc_cd = 'MA1' and (f.item_sno between 24 and 37) then f.ceck_yn||f.inqy_rspn_ctn1 -- MA1 문진의 경우 CTN은 응답이 있어도 ceck_yn이 null이므로 함께 고려
                                                else ''
                                           end 
                                          ) = 0
                                     and 
                                     count(
                                           case 
                                                when f.inpc_cd||f.item_sno = 'AM79' then f.inqy_rspn_cd
                                                when f.inpc_cd||f.item_sno = 'RR65' then f.inqy_rspn_cd
                                                when f.inpc_cd||f.item_sno||f.ceck_yn = 'MA123Y' then f.ceck_yn
                                                else ''
                                           end 
                                          ) = 1
                                then '0'
                                else ''
                           end alc_ys
                         , case
                                when /* 음주 관련 응답 내역이 없고, 원래 안 마시면 0 */
                                     count(
                                           case 
                                                when f.inpc_cd = 'AM' and (f.item_sno between 61 and 78) then f.inqy_rspn_cd
                                                when f.inpc_cd = 'RR' and (f.item_sno between 51 and 64) then f.inqy_rspn_cd
                                                else ''
                                           end 
                                          ) = 0
                                     and 
                                     count(
                                           case 
                                                when f.inpc_cd||f.item_sno = 'AM79' then f.inqy_rspn_cd
                                                when f.inpc_cd||f.item_sno = 'RR65' then f.inqy_rspn_cd
                                                else ''
                                           end 
                                          ) = 1
                                then '0'
                                else MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM77Y'  ,'2'
                                                                                ,'AM78Y'  ,'1'--,''))  AMQ0085
                                                                                ,'RR51Y'  ,'2'
                                                                                ,'RR64Y'  ,'1'
                                                                                ,'AM77'   ,'2'
                                                                                ,'AM78'   ,'1'--,''))  AMQ0085
                                                                                ,'RR51'   ,'2'
                                                                                ,'RR64'   ,'1'
                                               ,DECODE(f.inpc_cd,'MA1','9999',''))
                                        )
                           end alc
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM65Y'  ,'0'--,'1'
                                                                      ,'AM66Y'  ,'1'--,'2'
                                                                      ,'AM67Y'  ,'2'--,'3'
                                                                      ,'AM68Y'  ,'3'--,'4'
                                                                      ,'AM69Y'  ,'4'--,'5'
                                                                      ,'AM70Y'  ,'5'--,'6'--,''))                                                 AMQ0083
                                                                      ,'RR53Y'  ,'0'--,'1'
                                                                      ,'RR54Y'  ,'1'--,'2'
                                                                      ,'RR55Y'  ,'2'--,'3'
                                                                      ,'RR56Y'  ,'3'--,'4'
                                                                      ,'RR57Y'  ,'4'--,'5'
                                                                      ,'RR58Y'  ,'5'--,'6'--,''))                                                   RRQ0601
                                                                      ,'AM65'   ,'0'--,'1'
                                                                      ,'AM66'   ,'1'--,'2'
                                                                      ,'AM67'   ,'2'--,'3'
                                                                      ,'AM68'   ,'3'--,'4'
                                                                      ,'AM69'   ,'4'--,'5'
                                                                      ,'AM70'   ,'5'--,'6'--,''))                                                 AMQ0083
                                                                      ,'RR53'   ,'0'--,'1'
                                                                      ,'RR54'   ,'1'--,'2'
                                                                      ,'RR55'   ,'2'--,'3'
                                                                      ,'RR56'   ,'3'--,'4'
                                                                      ,'RR57'   ,'4'--,'5'
                                                                      ,'RR58'   ,'5'--,'6'--,''))                                                   RRQ0601
                                                                      ,'MA127Y' ,'0'--,'1'
                                                                      ,'MA128Y' ,'1'--,'2'
                                                                      ,'MA129Y' ,'2'--,'3'
                                                                      ,'MA130Y' ,'3'--,'4'
                                                                      ,'MA131Y' ,'4'--,'5'
                                                                      ,'MA132Y' ,'5'--,'6'--,''))                                                 MA1Q0302
                                     ,'')) alc_freq
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM72Y'  ,'0'--,'1'
                                                                      ,'AM73Y'  ,'1'--,'2'
                                                                      ,'AM74Y'  ,'2'--,'3'
                                                                      ,'AM75Y'  ,'3'--,'4'--,''))                                                 AMQ0084
                                                                      ,'RR60Y'  ,'0'--,'1'
                                                                      ,'RR61Y'  ,'1'--,'2'
                                                                      ,'RR62Y'  ,'2'--,'3'
                                                                      ,'RR63Y'  ,'3'--,'4'--,''))                                                 RRQ0602
                                                                      ,'AM72'   ,'0'--,'1'
                                                                      ,'AM73'   ,'1'--,'2'
                                                                      ,'AM74'   ,'2'--,'3'
                                                                      ,'AM75'   ,'3'--,'4'--,''))                                                 AMQ0084
                                                                      ,'RR60'   ,'0'--,'1'
                                                                      ,'RR61'   ,'1'--,'2'
                                                                      ,'RR62'   ,'2'--,'3'
                                                                      ,'RR63'   ,'3'--,'4'--,''))                                                 RRQ0602
                                                                      ,'MA134Y' ,'0'--,'1'
                                                                      ,'MA135Y' ,'1'--,'2'
                                                                      ,'MA136Y' ,'2'--,'3'
                                                                      ,'MA137Y' ,'3'--,'4'--,''))                                                 MA1Q0303
                                     ,'')) alc_amount_drinks
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM62'   ,f.inqy_rspn_ctn1-- ,''))                                   AMQ0081
                                                                      ,'AM62Y'  ,f.inqy_rspn_ctn1-- ,''))                                   AMQ0081
                                     ,DECODE(f.inpc_cd,'RR' ,'9999'
                                                     ,'MA1','9999','')
                                     )) alc_start_age
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM63'   ,f.inqy_rspn_ctn1 --,''))                                   AMQ0082
                                                                      ,'AM63Y'  ,f.inqy_rspn_ctn1 --,''))                                   AMQ0082
                                                                      ,'MA125'  ,f.inqy_rspn_ctn1 --,''))                                   MA1Q0301
                                                                      ,'MA125Y' ,f.inqy_rspn_ctn1 --,''))                                   MA1Q0301
                                     ,DECODE(f.inpc_cd,'RR' ,'9999','')
                                     )) alc_duration
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM78'   ,decode(f.inqy_rspn_ctn1,'','',f.inqy_rspn_ctn1) --,''))                                   AMQ0085
                                                                      ,'AM78Y'  ,decode(f.inqy_rspn_ctn1,'','',f.inqy_rspn_ctn1) --,''))                                   AMQ0085
                                     ,DECODE(f.inpc_cd,'RR' ,'9999'
                                                      ,'MA1','9999','')
                                     )) alc_endyr
                         , round(
                           MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA134Y' ,14.4 --'0'--,'1'
                                                                      ,'MA135Y' ,28.8 --'1'--,'2'
                                                                      ,'MA136Y' ,57.6 --'2'--,'3'
                                                                      ,'MA137Y' ,115.2--'3'--,'4'--,''))                                                 MA1Q0303
                                     ,'')) -- alc_amount_drinks
                           *
                           MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA127Y' ,0.033333--'0'--,'1'
                                                                      ,'MA128Y' ,0.083333--'1'--,'2'
                                                                      ,'MA129Y' ,0.214286--'2'--,'3'
                                                                      ,'MA130Y' ,0.5     --'3'--,'4'
                                                                      ,'MA131Y' ,0.785714--'4'--,'5'
                                                                      ,'MA132Y' ,1       --'5'--,'6'--,''))                                                 MA1Q0302
                                     ,''))-- alc_freq
                                ,2)
                           alc_amount_grams
                         /* Physical activity */
                         , case
                                when /* 운동 관련 응답 내역이 있으면 1 */
                                     count(
                                           case 
                                                when f.inpc_cd = 'AM' and (f.item_sno between 31 and 49) then f.inqy_rspn_cd
                                                when f.inpc_cd = 'RR' and (f.item_sno between 14 and 43) then f.inqy_rspn_cd
                                                else ''
                                           end 
                                          ) > 0
                                then '1'
                                when /* 운동 관련 응답 내역이 없고, 운동을 하지 않으면 0 */
                                     count(
                                           case 
                                                when f.inpc_cd = 'AM' and (f.item_sno between 31 and 49) then f.inqy_rspn_cd
                                                when f.inpc_cd = 'RR' and (f.item_sno between 14 and 43) then f.inqy_rspn_cd
                                                else ''
                                           end 
                                          ) = 0
                                     and 
                                     count(
                                           case 
                                                when f.inpc_cd||f.item_sno = 'AM50' then f.inqy_rspn_cd
                                                when f.inpc_cd||f.item_sno = 'RR44' then f.inqy_rspn_cd
                                                else ''
                                           end 
                                          ) = 1
                                then '0'
                                else MAX(DECODE(f.inpc_cd,'MA1','9999',''))
                           end phy
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA149Y','1'                                                                       
                                                                      ,'MA150Y','2'                                                                       
                                                                      ,'MA151Y','3'                                                                       
                                                                      ,'MA152Y','0'--,''))                                                                  MA1Q05
                                     ,DECODE(f.inpc_cd,'RR' ,'9999'
                                                      ,'AM' ,'9999','')
                                     )) overall_physical_activity
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM43Y'  ,'0'
                                                                      ,'AM44Y'  ,'1'
                                                                      ,'AM45Y'  ,'2'
                                                                      ,'AM46Y'  ,'3'
                                                                      ,'AM47Y'  ,'4'--,''))                                AMQ0062
                                                                      ,'AM43'   ,'0'
                                                                      ,'AM44'   ,'1'
                                                                      ,'AM45'   ,'2'
                                                                      ,'AM46'   ,'3'
                                                                      ,'AM47'   ,'4'--,''))                                AMQ0062
                                                                      ,'RR26Y'  ,'0'
                                                                      ,'RR27Y'  ,'1'
                                                                      ,'RR28Y'  ,'2'
                                                                      ,'RR29Y'  ,'3'
                                                                      ,'RR30Y'  ,'4'--,''))                                         RRQ0402
                                                                      ,'RR26'   ,'0'
                                                                      ,'RR27'   ,'1'
                                                                      ,'RR28'   ,'2'
                                                                      ,'RR29'   ,'3'
                                                                      ,'RR30'   ,'4'--,''))                                         RRQ0402
                                     ,decode(f.inpc_cd,'MA1','9999','')
                                     )) phy_freq_2009
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM48'   ,decode(f.inqy_rspn_ctn1||f.inqy_rspn_ctn2,'','',f.inqy_rspn_ctn1||' 분 또는 '||f.inqy_rspn_ctn2||' 시간')--,'')) AMQ0063
                                                                      ,'AM48Y'  ,decode(f.inqy_rspn_ctn1||f.inqy_rspn_ctn2,'','',f.inqy_rspn_ctn1||' 분 또는 '||f.inqy_rspn_ctn2||' 시간')--,'')) AMQ0063
                                                                      ,'RR32Y'  ,'0'
                                                                      ,'RR33Y'  ,'1'
                                                                      ,'RR34Y'  ,'2'
                                                                      ,'RR35Y'  ,'3'
                                                                      ,'RR36Y'  ,'4'--,''))                                         RRQ0403
                                                                      ,'RR32'   ,'0'
                                                                      ,'RR33'   ,'1'
                                                                      ,'RR34'   ,'2'
                                                                      ,'RR35'   ,'3'
                                                                      ,'RR36'   ,'4'--,''))                                         RRQ0403
                                     ,decode(f.inpc_cd,'MA1','9999','')
                                     )) phy_duration_2009
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA154Y' ,'0'                                                                       
                                                                      ,'MA155Y' ,'1'                                                                       
                                                                      ,'MA156Y' ,'2'                                                                       
                                                                      ,'MA157Y' ,'3'--,''))                                                                  MA1Q0501
                                     ,decode(f.inpc_cd,'AM','9999'
                                                      ,'RR','9999','')
                                     )) phy_freq
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA159Y' ,'0'
                                                                      ,'MA160Y' ,'1'
                                                                      ,'MA161Y' ,'2'
                                                                      ,'MA162Y' ,'3'
                                                                      ,'MA163Y' ,'4'--,''))                                                                  MA1Q0502
                                     ,decode(f.inpc_cd,'AM','9999'
                                                      ,'RR','9999','')
                                     )) phy_duration
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM49'   ,f.inqy_rspn_ctn1||' 년전'--,''))                        AMQ0064
                                                                      ,'AM49Y'  ,f.inqy_rspn_ctn1||' 년전'--,''))                        AMQ0064
                                                                      ,'RR38Y'  ,'0'
                                                                      ,'RR39Y'  ,'1'
                                                                      ,'RR40Y'  ,'2'
                                                                      ,'RR41Y'  ,'3'
                                                                      ,'RR42Y'  ,'4'
                                                                      ,'RR43Y'  ,'5'--,''))                                         RRQ0404
                                                                      ,'RR38'   ,'0'
                                                                      ,'RR39'   ,'1'
                                                                      ,'RR40'   ,'2'
                                                                      ,'RR41'   ,'3'
                                                                      ,'RR42'   ,'4'
                                                                      ,'RR43'   ,'5'--,''))                                         RRQ0404
                                     ,DECODE(f.inpc_cd,'MA1' ,'9999','')
                                     )) phy_startyr
                         , case
                                when /* 운동 관련 응답 내역이 있으면 1 */
                                     MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM33Y' ,'1'--,''))                                AMQ00611
                                                                                ,'AM33'  ,'1'--,''))                                AMQ00611
                                                                                ,'RR16Y' ,'1'--,''))                                         RRQ040101
                                                                                ,'RR16'  ,'1'--,''))                                         RRQ040101
                                               ,''
                                               )) is not null
                                then '1'
                                when /* 타 운동 종류 관련 응답이 있으면 0 */
                                     count(
                                           case 
                                                when f.inpc_cd = 'AM' and (f.item_sno between 33 and 41) then f.inqy_rspn_cd
                                                when f.inpc_cd = 'RR' and (f.item_sno between 16 and 24) then f.inqy_rspn_cd
                                                else ''
                                           end 
                                          ) > 0
                                then '0'
                                else MAX(DECODE(f.inpc_cd,'MA1','9999',''))
                           end phy_walking
                         , case
                                when /* 운동 관련 응답 내역이 있으면 1 */
                                     MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM34Y' ,'1'--,''))                                AMQ00611
                                                                                ,'AM34'  ,'1'--,''))                                AMQ00611
                                                                                ,'RR17Y' ,'1'--,''))                                         RRQ040101
                                                                                ,'RR17'  ,'1'--,''))                                         RRQ040101
                                               ,''
                                               )) is not null
                                then '1'
                                when /* 타 운동 종류 관련 응답이 있으면 0 */
                                     count(
                                           case 
                                                when f.inpc_cd = 'AM' and (f.item_sno between 33 and 41) then f.inqy_rspn_cd
                                                when f.inpc_cd = 'RR' and (f.item_sno between 16 and 24) then f.inqy_rspn_cd
                                                else ''
                                           end 
                                          ) > 0
                                then '0'
                                else MAX(DECODE(f.inpc_cd,'MA1','9999',''))
                           end phy_jogging
                         , case
                                when /* 운동 관련 응답 내역이 있으면 1 */
                                     MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM35Y' ,'1'--,''))                                AMQ00611
                                                                                ,'AM35'  ,'1'--,''))                                AMQ00611
                                                                                ,'RR18Y' ,'1'--,''))                                         RRQ040101
                                                                                ,'RR18'  ,'1'--,''))                                         RRQ040101
                                               ,''
                                               )) is not null
                                then '1'
                                when /* 타 운동 종류 관련 응답이 있으면 0 */
                                     count(
                                           case 
                                                when f.inpc_cd = 'AM' and (f.item_sno between 33 and 41) then f.inqy_rspn_cd
                                                when f.inpc_cd = 'RR' and (f.item_sno between 16 and 24) then f.inqy_rspn_cd
                                                else ''
                                           end 
                                          ) > 0
                                then '0'
                                else MAX(DECODE(f.inpc_cd,'MA1','9999',''))
                           end phy_TENNIS
                         , case
                                when /* 운동 관련 응답 내역이 있으면 1 */
                                     MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM36Y' ,'1'--,''))                                AMQ00611
                                                                                ,'AM36'  ,'1'--,''))                                AMQ00611
                                                                                ,'RR19Y' ,'1'--,''))                                         RRQ040101
                                                                                ,'RR19'  ,'1'--,''))                                         RRQ040101
                                               ,''
                                               )) is not null
                                then '1'
                                when /* 타 운동 종류 관련 응답이 있으면 0 */
                                     count(
                                           case 
                                                when f.inpc_cd = 'AM' and (f.item_sno between 33 and 41) then f.inqy_rspn_cd
                                                when f.inpc_cd = 'RR' and (f.item_sno between 16 and 24) then f.inqy_rspn_cd
                                                else ''
                                           end 
                                          ) > 0
                                then '0'
                                else MAX(DECODE(f.inpc_cd,'MA1','9999',''))
                           end phy_GOLF
                         , case
                                when /* 운동 관련 응답 내역이 있으면 1 */
                                     MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM37Y' ,'1'--,''))                                AMQ00611
                                                                                ,'AM37'  ,'1'--,''))                                AMQ00611
                                                                                ,'RR20Y' ,'1'--,''))                                         RRQ040101
                                                                                ,'RR20'  ,'1'--,''))                                         RRQ040101
                                               ,''
                                               )) is not null
                                then '1'
                                when /* 타 운동 종류 관련 응답이 있으면 0 */
                                     count(
                                           case 
                                                when f.inpc_cd = 'AM' and (f.item_sno between 33 and 41) then f.inqy_rspn_cd
                                                when f.inpc_cd = 'RR' and (f.item_sno between 16 and 24) then f.inqy_rspn_cd
                                                else ''
                                           end 
                                          ) > 0
                                then '0'
                                else MAX(DECODE(f.inpc_cd,'MA1','9999',''))
                           end phy_SWIMMING
                         , case
                                when /* 운동 관련 응답 내역이 있으면 1 */
                                     MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM38Y' ,'1'--,''))                                AMQ00611
                                                                                ,'AM38'  ,'1'--,''))                                AMQ00611
                                                                                ,'RR21Y' ,'1'--,''))                                         RRQ040101
                                                                                ,'RR21'  ,'1'--,''))                                         RRQ040101
                                               ,''
                                               )) is not null
                                then '1'
                                when /* 타 운동 종류 관련 응답이 있으면 0 */
                                     count(
                                           case 
                                                when f.inpc_cd = 'AM' and (f.item_sno between 33 and 41) then f.inqy_rspn_cd
                                                when f.inpc_cd = 'RR' and (f.item_sno between 16 and 24) then f.inqy_rspn_cd
                                                else ''
                                           end 
                                          ) > 0
                                then '0'
                                else MAX(DECODE(f.inpc_cd,'MA1','9999',''))
                           end phy_CLIMBING
                         , case
                                when /* 운동 관련 응답 내역이 있으면 1 */
                                     MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM39Y' ,'1'--,''))                                AMQ00611
                                                                                ,'AM39'  ,'1'--,''))                                AMQ00611
                                                                                ,'RR22Y' ,'1'--,''))                                         RRQ040101
                                                                                ,'RR22'  ,'1'--,''))                                         RRQ040101
                                               ,''
                                               )) is not null
                                then '1'
                                when /* 타 운동 종류 관련 응답이 있으면 0 */
                                     count(
                                           case 
                                                when f.inpc_cd = 'AM' and (f.item_sno between 33 and 41) then f.inqy_rspn_cd
                                                when f.inpc_cd = 'RR' and (f.item_sno between 16 and 24) then f.inqy_rspn_cd
                                                else ''
                                           end 
                                          ) > 0
                                then '0'
                                else MAX(DECODE(f.inpc_cd,'MA1','9999',''))
                           end phy_AEROBIC
                         , case
                                when /* 운동 관련 응답 내역이 있으면 1 */
                                     MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM40Y' ,'1'--,''))                                AMQ00611
                                                                                ,'AM40'  ,'1'--,''))                                AMQ00611
                                                                                ,'RR23Y' ,'1'--,''))                                         RRQ040101
                                                                                ,'RR23'  ,'1'--,''))                                         RRQ040101
                                               ,''
                                               )) is not null
                                then '1'
                                when /* 타 운동 종류 관련 응답이 있으면 0 */
                                     count(
                                           case 
                                                when f.inpc_cd = 'AM' and (f.item_sno between 33 and 41) then f.inqy_rspn_cd
                                                when f.inpc_cd = 'RR' and (f.item_sno between 16 and 24) then f.inqy_rspn_cd
                                                else ''
                                           end 
                                          ) > 0
                                then '0'
                                else MAX(DECODE(f.inpc_cd,'MA1','9999',''))
                           end phy_FITNESS
                         , case
                                when /* 운동 관련 응답 내역이 있으면 1 */
                                     MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM41Y' ,'1'--,''))                                AMQ00611
                                                                                ,'AM41'  ,'1'--,''))                                AMQ00611
                                                                                ,'RR24Y' ,'1'--,''))                                         RRQ040101
                                                                                ,'RR24'  ,'1'--,''))                                         RRQ040101
                                               ,''
                                               )) is not null
                                then '1'
                                when /* 타 운동 종류 관련 응답이 있으면 0 */
                                     count(
                                           case 
                                                when f.inpc_cd = 'AM' and (f.item_sno between 33 and 41) then f.inqy_rspn_cd
                                                when f.inpc_cd = 'RR' and (f.item_sno between 16 and 24) then f.inqy_rspn_cd
                                                else ''
                                           end 
                                          ) > 0
                                then '0'
                                else MAX(DECODE(f.inpc_cd,'MA1','9999',''))
                           end phy_OTHER
                         , case
                                when count(
                                           case
                                                when f.inpc_cd = 'AM' and (f.item_sno between 81 and 89) then f.inqy_rspn_cd
                                                when f.inpc_cd = 'RR' and (f.item_sno between 67 and 74) then f.inqy_rspn_cd
                                                else ''
                                                end
                                          ) > 0
                                     or
                                     MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM81Y','1'
                                                                                ,'RR67Y','1'
                                                                                ,'AM81' ,'1'
                                                                                ,'RR67' ,'1','')) = '1'
                                then '1'
                                else MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                              ,'AM90Y' ,'0'
                                                                              ,'AM91Y' ,'2'
                                                                      ,'RR75Y','0'
                                                                      ,'RR76Y','2'
                                                                              ,'AM90'  ,'0'
                                                                              ,'AM91'  ,'2'
                                                                      ,'RR75' ,'0'
                                                                      ,'RR76' ,'2'
                                                                              ,decode(f.inpc_cd,'MA1','9999','')))
                           end  allergy
                         , case
                                when 
                           MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM83Y' ,'1'
                                                                      ,'RR69Y' ,'1'
                                                                      ,'AM83'  ,'1'
                                                                      ,'RR69'  ,'1','')) = '1' then '1'
                                when count(
                                           case
                                                when f.inpc_cd = 'AM' and (f.item_sno between 81 and 89) then f.inqy_rspn_cd
                                                when f.inpc_cd = 'RR' and (f.item_sno between 67 and 74) then f.inqy_rspn_cd
                                                else ''
                                                end
                                          ) > 0
                                then '0'
                                else max(decode(f.inpc_cd,'MA1','9999','')) 
                           end allergy_penicillin
                         , case
                                when 
                           MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM84Y' ,'1'
                                                                      ,'RR70Y' ,'1'
                                                                      ,'AM84'  ,'1'
                                                                      ,'RR70'  ,'1','')) = '1' then '1'
                                when count(
                                           case
                                                when f.inpc_cd = 'AM' and (f.item_sno between 81 and 89) then f.inqy_rspn_cd
                                                when f.inpc_cd = 'RR' and (f.item_sno between 67 and 74) then f.inqy_rspn_cd
                                                else ''
                                                end
                                          ) > 0
                                then '0'
                                else max(decode(f.inpc_cd,'MA1','9999','')) 
                           end allergy_sulfa
                         , case
                                when 
                           MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM85Y' ,'1'
                                                                      ,'RR71Y' ,'1'
                                                                      ,'AM85'  ,'1'
                                                                      ,'RR71'  ,'1','')) = '1' then '1'
                                when count(
                                           case
                                                when f.inpc_cd = 'AM' and (f.item_sno between 81 and 89) then f.inqy_rspn_cd
                                                when f.inpc_cd = 'RR' and (f.item_sno between 67 and 74) then f.inqy_rspn_cd
                                                else ''
                                                end
                                          ) > 0
                                then '0'
                                else max(decode(f.inpc_cd,'MA1','9999','')) 
                           end allergy_contrast_agent
                         , case
                                when 
                           MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM86Y' ,'1'
                                                                      ,'RR72Y' ,'1'
                                                                      ,'AM86'  ,'1'
                                                                      ,'RR72'  ,'1','')) = '1' then '1'
                                when count(
                                           case
                                                when f.inpc_cd = 'AM' and (f.item_sno between 81 and 89) then f.inqy_rspn_cd
                                                when f.inpc_cd = 'RR' and (f.item_sno between 67 and 74) then f.inqy_rspn_cd
                                                else ''
                                                end
                                          ) > 0
                                then '0'
                                else max(decode(f.inpc_cd,'MA1','9999','')) 
                           end allergy_local_anesthetic
                         , case
                                when 
                           MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM87Y' ,'1'
                                                                      ,'RR73Y' ,'1'
                                                                      ,'AM87'  ,'1'
                                                                      ,'RR73'  ,'1','')) = '1' then '1'
                                when count(
                                           case
                                                when f.inpc_cd = 'AM' and (f.item_sno between 81 and 89) then f.inqy_rspn_cd
                                                when f.inpc_cd = 'RR' and (f.item_sno between 67 and 74) then f.inqy_rspn_cd
                                                else ''
                                                end
                                          ) > 0
                                then '0'
                                else max(decode(f.inpc_cd,'MA1','9999','')) 
                           end allergy_aspirin
                         , case
                                when 
                           MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM88Y' ,'1'
                                                                      ,'RR74Y' ,'1'
                                                                      ,'AM88'  ,'1'
                                                                      ,'RR74'  ,'1','')) = '1' then '1'
                                when count(
                                           case
                                                when f.inpc_cd = 'AM' and (f.item_sno between 81 and 89) then f.inqy_rspn_cd
                                                when f.inpc_cd = 'RR' and (f.item_sno between 67 and 74) then f.inqy_rspn_cd
                                                else ''
                                                end
                                          ) > 0
                                then '0'
                                else max(decode(f.inpc_cd,'MA1','9999','')) 
                           end allergy_other
                         , case
                                when 
                           MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM89Y' ,'1'
                                                                      ,'AM89'  ,'1','')) = '1' then '1'
                                when count(
                                           case
                                                when f.inpc_cd = 'AM' and (f.item_sno between 81 and 89) then f.inqy_rspn_cd
                                                when f.inpc_cd = 'RR' and (f.item_sno between 67 and 74) then f.inqy_rspn_cd
                                                else ''
                                                end
                                          ) > 0
                                then '0'
                                else max(decode(f.inpc_cd,'MA1','9999','')) 
                           end allergy_unknown
                         , case
                                when count(
                                           case
                                                when f.inpc_cd = 'MA1' and (f.item_sno between 43 and 47) then f.ceck_yn
                                                else ''
                                                end
                                          ) > 0
                                     or
                           MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA139Y','1','')) = '1'
                           then '1' 
                           else 
                           MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA140Y','0'
                                                                      ,'MA141Y','2'
                                                                      ,decode(f.inpc_cd,'RR' ,'9999'
                                                                                       ,'AM' ,'9999',''))) 
                           end adverse_med
                         , case
                                when MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA144Y','1','')) = '1' then '1'
                                when count(
                                           case
                                                when f.inpc_cd = 'MA1' and (f.item_sno between 43 and 47) then f.ceck_yn
                                                else ''
                                                end
                                          ) > 0
                                     or
                           MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA139Y','1','')) = '1'
                           then '0' 
                           else max(decode(f.inpc_cd,'AM','9999'
                                                    ,'RR','9999',''))
                           end adverse_med_antibiotics
                         , case
                                when MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA145Y','1','')) = '1' then '1'
                                when count(
                                           case
                                                when f.inpc_cd = 'MA1' and (f.item_sno between 43 and 47) then f.ceck_yn
                                                else ''
                                                end
                                          ) > 0
                                     or
                           MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA139Y','1','')) = '1'
                           then '0' 
                           else max(decode(f.inpc_cd,'AM','9999'
                                                    ,'RR','9999',''))
                           end adverse_med_contrast_agent
                         , case
                                when MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA146Y','1','')) = '1' then '1'
                                when count(
                                           case
                                                when f.inpc_cd = 'MA1' and (f.item_sno between 43 and 47) then f.ceck_yn
                                                else ''
                                                end
                                          ) > 0
                                     or
                           MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA139Y','1','')) = '1'
                           then '0' 
                           else max(decode(f.inpc_cd,'AM','9999'
                                                    ,'RR','9999',''))
                           end adverse_med_local_anesthetic
                         , case
                                when MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA143Y','1','')) = '1' then '1'
                                when count(
                                           case
                                                when f.inpc_cd = 'MA1' and (f.item_sno between 43 and 47) then f.ceck_yn
                                                else ''
                                                end
                                          ) > 0
                                     or
                           MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA139Y','1','')) = '1'
                           then '0' 
                           else max(decode(f.inpc_cd,'AM','9999'
                                                    ,'RR','9999',''))
                           end adverse_med_aspirin_painkiller
                         , case
                                when MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA147Y','1','')) = '1' then '1'
                                when count(
                                           case
                                                when f.inpc_cd = 'MA1' and (f.item_sno between 43 and 47) then f.ceck_yn
                                                else ''
                                                end
                                          ) > 0
                                     or
                           MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA139Y','1','')) = '1'
                           then '0' 
                           else max(decode(f.inpc_cd,'AM','9999'
                                                    ,'RR','9999',''))
                           end adverse_med_other
                         , case
                                when MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM93Y' ,'1'
                                                                                ,'AM93'  ,'1','')) = '1' then '1'
                                when count(
                                           case
                                                when f.inpc_cd = 'AM' and (f.item_sno between 93 and 102) then f.inqy_rspn_cd
                                                else ''
                                           end     
                                          ) > 0 then '0'
                                else max(decode(f.inpc_cd,'MA1','9999'
                                                         ,'RR' ,'9999',''))
                           end surgery_stomach
                         , case
                                when MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM94Y' ,'1'
                                                                                ,'AM94'  ,'1','')) = '1' then '1'
                                when count(
                                           case
                                                when f.inpc_cd = 'AM' and (f.item_sno between 93 and 102) then f.inqy_rspn_cd
                                                else ''
                                           end     
                                          ) > 0 then '0'
                                else max(decode(f.inpc_cd,'MA1','9999'
                                                         ,'RR' ,'9999',''))
                           end surgery_gallbladder
                         , case
                                when MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM95Y' ,'1'
                                                                                ,'AM95'  ,'1','')) = '1' then '1'
                                when count(
                                           case
                                                when f.inpc_cd = 'AM' and (f.item_sno between 93 and 102) then f.inqy_rspn_cd
                                                else ''
                                           end     
                                          ) > 0 then '0'
                                else max(decode(f.inpc_cd,'MA1','9999'
                                                         ,'RR' ,'9999',''))
                           end surgery_colon
                         , case
                                when MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM96Y' ,'1'
                                                                                ,'AM96'  ,'1','')) = '1' then '1'
                                when count(
                                           case
                                                when f.inpc_cd = 'AM' and (f.item_sno between 93 and 102) then f.inqy_rspn_cd
                                                else ''
                                           end     
                                          ) > 0 then '0'
                                else max(decode(f.inpc_cd,'MA1','9999'
                                                         ,'RR' ,'9999',''))
                           end surgery_appendix
                         , case
                                when MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM97Y' ,'1'
                                                                                ,'AM97'  ,'1','')) = '1' then '1'
                                when count(
                                           case
                                                when f.inpc_cd = 'AM' and (f.item_sno between 93 and 102) then f.inqy_rspn_cd
                                                else ''
                                           end     
                                          ) > 0 then '0'
                                else max(decode(f.inpc_cd,'MA1','9999'
                                                         ,'RR' ,'9999',''))
                           end surgery_thyroid
                         , case
                                when f.inpc_cd in ('RR','MA1') then '9999'
                                when MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM98Y' ,'1'
                                                                                ,'AM98'  ,'1','')) = '1' then '1'
                                when count(
                                           case
                                                when f.inpc_cd = 'AM' and (f.item_sno between 93 and 102) then f.inqy_rspn_cd
                                                else ''
                                           end     
                                          ) > 0 then '0'
                                else ''
                           end surgery_uterus
                         , case
                                when f.inpc_cd in ('RR','MA1') then '9999'
                                when MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM99Y' ,'1'
                                                                                ,'AM99'  ,'1','')) = '1' then '1'
                                when count(
                                           case
                                                when f.inpc_cd = 'AM' and (f.item_sno between 93 and 102) then f.inqy_rspn_cd
                                                else ''
                                           end     
                                          ) > 0 then '0'
                                else ''
                           end surgery_ovary
                         , case
                                when MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM100Y' ,'1'
                                                                                ,'AM100'  ,'1','')) = '1' then '1'
                                when count(
                                           case
                                                when f.inpc_cd = 'AM' and (f.item_sno between 93 and 102) then f.inqy_rspn_cd
                                                else ''
                                           end     
                                          ) > 0 then '0'
                                else max(decode(f.inpc_cd,'MA1','9999'
                                                         ,'RR' ,'9999',''))
                           end surgery_breast
                         , case
                                when MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM101Y' ,'1'
                                                                                ,'AM101'  ,'1','')) = '1' then '1'
                                when count(
                                           case
                                                when f.inpc_cd = 'AM' and (f.item_sno between 93 and 102) then f.inqy_rspn_cd
                                                else ''
                                           end     
                                          ) > 0 then '0'
                                else max(decode(f.inpc_cd,'MA1','9999'
                                                         ,'RR' ,'9999',''))
                           end surgery_kidney
                         , case
                                when MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM102Y' ,'1'
                                                                                ,'AM102'  ,'1','')) = '1' then '1'
                                when count(
                                           case
                                                when f.inpc_cd = 'AM' and (f.item_sno between 93 and 102) then f.inqy_rspn_cd
                                                else ''
                                           end     
                                          ) > 0 then '0'
                                else max(decode(f.inpc_cd,'MA1','9999'
                                                         ,'RR' ,'9999',''))
                           end surgery_other
                      from 스키마.3E3C0E433E3C0E3E28@SMISR_스키마  a
                         , 스키마.0E5B5B285B28402857@SMISR_스키마  b
                         , 스키마.3E3C23302E333E0E28@SMISR_스키마  f
                         , 스키마.3E3C23302E333E3C28@SMISR_스키마  g
                     where 
                           a.ordr_prrn_ymd between to_date(&qfrdt,'yyyymmdd') and to_date(&qtodt,'yyyymmdd')
                       and a.ordr_ymd is not null
                       and a.cncl_dt is null
                       and b.ptno = a.ptno
                       and f.ptno = a.ptno
                       and f.ordr_prrn_ymd = a.ordr_prrn_ymd
                       and f.inpc_cd in ('AM','RR','MA1')
                       AND (-- AM, RR의 경우는 응답한 것만 저장되었으므로, 모두 범위에 포함
                                      (f.inpc_cd = 'AM'  and f.item_sno between 1 and 500)
                                   or (f.inpc_cd = 'RR'  and f.item_sno between 1 and  300)
                                   OR (f.inpc_cd = 'MA1' and f.item_sno between 1 and  64)
                           )
                       and f.rprs_apnt_no = a.rprs_apnt_no
                       and f.qstn_cd1 = g.inqy_cd(+)
                       and a.ptno not in (
                                          &not_in_ptno
                                         )
                     group by f.rprs_apnt_no
                         , F.PTNO
                         , f.ordr_prrn_ymd
                         , f.inpc_cd
                         , b.brrn 
                   ) a
                      
           )
                
            loop
            begin   -- 데이터 update
                          update /*+ append */
                                 스키마.1543294D47144D302E333E0E28 a
                             set 
                                 a.EXAM_MOTIVE                           = drh."6" 
                                 , a.EXAM                                  = drh."7" 
                                 , a.EXAM_FIRST_AGE                        = drh."8" 
                                 , a.EXAM_MOST_RECENT_YY                   = drh."9" 
                                 , a.EXAM_MOST_RECENT_MM                   = drh."10"
                                 , a.EXAM_FREQ_YR                          = drh."11"
                                 , a.EXAM_PLACE                            = drh."12"
                                 , a.MARITAL_STATUS                        = drh."13"
                                 , a.EDUCATION                             = drh."14"
                                 , a.INCOME                                = drh."15"
                                 , a.SMK_YS                                = drh."16"
                                 , a.SMK                                   = drh."17"
                                 , a.SMK_DURATION                          = drh."18"
                                 , a.SMK_CURRENT_AMOUNT                    = drh."19"
                                 , a.SMK_START_AGE                         = drh."20"
                                 , a.SMK_ENDYR                             = drh."21"
                                 , a.SMK_PACKYRS                           = drh."22"
                                 , a.ALC_YS                                = drh."23"
                                 , a.ALC                                   = drh."24"
                                 , a.ALC_FREQ                              = drh."25"
                                 , a.ALC_AMOUNT_DRINKS                     = drh."26"
                                 , a.ALC_START_AGE                         = drh."27"
                                 , a.ALC_DURATION                          = drh."28"
                                 , a.ALC_ENDYR                             = drh."29"
                                 , a.ALC_AMOUNT_GRAMS                      = drh."30"
                                 , a.PHY                                   = drh."31"
                                 , a.OVERALL_PHYSICAL_ACTIVITY             = drh."32"
                                 , a.PHY_FREQ_2009                         = drh."33"
                                 , a.PHY_DURATION_2009                     = drh."34"
                                 , a.PHY_FREQ                              = drh."35"
                                 , a.PHY_DURATION                          = drh."36"
                                 , a.PHY_STARTYR                           = drh."37"
                                 , a.PHY_WALKING                           = drh."38"
                                 , a.PHY_JOGGING                           = drh."39"
                                 , a.PHY_TENNIS                            = drh."40"
                                 , a.PHY_GOLF                              = drh."41"
                                 , a.PHY_SWIMMING                          = drh."42"
                                 , a.PHY_CLIMBING                          = drh."43"
                                 , a.PHY_AEROBIC                           = drh."44"
                                 , a.PHY_FITNESS                           = drh."45"
                                 , a.PHY_OTHER                             = drh."46"
                                 , a.ALLERGY                               = drh."47"
                                 , a.ALLERGY_PENICILLIN                    = drh."48"
                                 , a.ALLERGY_SULFA                         = drh."49"
                                 , a.ALLERGY_CONTRAST_AGENT                = drh."50"
                                 , a.ALLERGY_LOCAL_ANESTHETIC              = drh."51"
                                 , a.ALLERGY_ASPIRIN                       = drh."52"
                                 , a.ALLERGY_OTHER                         = drh."53"
                                 , a.ALLERGY_UNKNOWN                       = drh."54"
                                 , a.ADVERSE_MED                           = drh."55"
                                 , a.ADVERSE_MED_ANTIBIOTICS               = drh."56"
                                 , a.ADVERSE_MED_CONTRAST_AGENT            = drh."57"
                                 , a.ADVERSE_MED_LOCAL_ANESTHETIC          = drh."58"
                                 , a.ADVERSE_MED_ASPIRIN_PAINKILLER        = drh."59"
                                 , a.ADVERSE_MED_OTHER                     = drh."60"
                                 , a.SURGERY_STOMACH                       = drh."61"
                                 , a.SURGERY_GALLBLADDER                   = drh."62"
                                 , a.SURGERY_COLON                         = drh."63"
                                 , a.SURGERY_APPENDIX                      = drh."64"
                                 , a.SURGERY_THYROID                       = drh."65"
                                 , a.SURGERY_UTERUS                        = drh."66"
                                 , a.SURGERY_OVARY                         = drh."67"
                                 , a.SURGERY_BREAST                        = drh."68"
                                 , a.SURGERY_KIDNEY                        = drh."69"
                                 , a.SURGERY_OTHER                         = drh."70"
                               , a.last_updt_dt                     = drh.last_updt_dt
                           where a.ptno = drh.ptno
                             and a.ordr_prrn_ymd = drh.ordr_prrn_ymd
                             and a.rprs_apnt_no = drh.rprs_apnt_no
                                 ;
                  
                         commit;
                       
                       upcnt := upcnt + 1;
                  
                       exception
                       when others then
                          rollback;
                          errcnt := errcnt + 1;
            
            end;
            end loop;
       
:var_msg2  := 'update '  || to_char(upcnt)    || ' 건';
:var_msg3  := 'error '   || to_char(errcnt)   || ' 건';
   
end ;
/
print var_msg2
print var_msg3
spool off;
     
-- 문진 정보 update, 질병력
-- 변수 길이가 길다는 에러메세지 때문에 변수를 숫자정보로 치환
-- 메시지 출력기능 추가. 메시지 확인은 F5를 눌러야 가능함
variable var_msg2 char(40);
variable var_msg3 char(40);
  
declare
    upcnt     number(10) := 0;
    errcnt    number(10) := 0;
        
begin
for drh in (
            -- 데이터 select
            select h.RPRS_APNT_NO                   as RPRS_APNT_NO
                 , h.PTNO                           as ptno
                 , h.ORDR_PRRN_YMD                  as ordr_prrn_ymd
                 , h.HISTORY_COMORBIDITY            as "1"  
                 , h.HISTORY_TUBERCULOSIS           as "2"  
                 , h.TRT_TUBERCULOSIS               as "3"  
                 , h.STATUS_TUBERCULOSIS            as "4"  
                 , h.TRT_TUBERCULOSIS_OP            as "5"  
                 , h.TUBERCULOSIS_AGE_DIAG          as "6"  
                 , h.HISTORY_HYPERTENSION           as "7"  
                 , h.TRT_HYPERTENSION               as "8"  
                 , h.STATUS_HYPERTENSION            as "9"  
                 , h.HYPERTENSION_AGE_DIAG          as "10" 
                 , h.HISTORY_HYPERLIPIDEMIA         as "11" 
                 , h.TRT_HYPERLIPIDEMIA             as "12" 
                 , h.STATUS_HYPERLIPIDEMIA          as "13" 
                 , h.HYPERLIPIDEMIA_AGE_DIAG        as "14" 
                 , h.HISTORY_STROKE                 as "15" 
                 , h.TRT_STROKE                     as "16" 
                 , h.STATUS_STROKE                  as "17" 
                 , h.TRT_STROKE_OP                  as "18" 
                 , h.STROKE_AGE_DIAG                as "19" 
                 , h.HISTORY_DIABETES               as "20" 
                 , h.TRT_DIABETES                   as "21" 
                 , h.STATUS_DIABETES                as "22" 
                 , h.DIABETES_AGE_DIAG              as "23" 
                 , h.HISTORY_GA_DUODENAL_ULCER      as "24" 
                 , h.TRT_GA_DUODENAL_ULCER          as "25" 
                 , h.STATUS_GA_DUODENAL_ULCER       as "26" 
                 , h.TRT_GA_DUODENAL_ULCER_OP       as "27" 
                 , h.GA_DUODENAL_ULCER_AGE_DIAG     as "28" 
                 , h.HISTORY_COLON_POLYP            as "29" 
                 , h.TRT_COLON_POLYP                as "30" 
                 , h.STATUS_COLON_POLYP             as "31" 
                 , h.TRT_COLON_POLYP_OP             as "32" 
                 , h.COLON_POLYP_AGE_DIAG           as "33" 
                 , h.HISTORY_FATTY_LIVER            as "34" 
                 , h.TRT_FATTY_LIVER                as "35" 
                 , h.STATUS_FATTY_LIVER             as "36" 
                 , h.FATTY_LIVER_AGE_DIAG           as "37" 
                 , h.HISTORY_THYROID_NODULES        as "38" 
                 , h.TRT_THYROID_NODULES            as "39" 
                 , h.STATUS_THYROID_NODULES         as "40" 
                 , h.TRT_THYROID_NODULES_OP         as "41" 
                 , h.THYROID_NODULES_AGE_DIAG       as "42" 
                 , h.HISTORY_BBT                    as "43" 
                 , h.TRT_BBT                        as "44" 
                 , h.STATUS_BBT                     as "45" 
                 , h.TRT_BBT_OP                     as "46" 
                 , h.BBT_AGE_DIAG                   as "47" 
                 , h.TRT_BBT_BIOPSY                 as "48" 
                 , h.HISTORY_DISC                   as "49" 
                 , h.TRT_DISC                       as "50" 
                 , h.STATUS_DISC                    as "51" 
                 , h.TRT_DISC_OP                    as "52" 
                 , h.DISC_AGE_DIAG                  as "53" 
                 , h.HISTORY_GASTRITIS              as "54" 
                 , h.TRT_GASTRITIS                  as "55" 
                 , h.GASTRITIS_AGE_DIAG             as "56" 
                 , h.HISTORY_ENTERITIS              as "57" 
                 , h.TRT_ENTERITIS                  as "58" 
                 , h.ENTERITIS_AGE_DIAG             as "59" 
                 , h.HISTORY_HEMORRHOID             as "60" 
                 , h.TRT_HEMORRHOID                 as "61" 
                 , h.HEMORRHOID_AGE_DIAG            as "62" 
                 , h.HISTORY_ACUTE_HEP              as "63" 
                 , h.TRT_ACUTE_HEP                  as "64" 
                 , h.ACUTE_HEP_AGE_DIAG             as "65" 
                 , h.HISTORY_HEP_CIRRHOSIS          as "66" 
                 , h.TRT_HEP_CIRRHOSIS              as "67" 
                 , h.HEP_CIRRHOSIS_AGE_DIAG         as "68" 
                 , h.HISTORY_GALLBLADDER_DIS        as "69" 
                 , h.TRT_GALLBLADDER_DIS            as "70" 
                 , h.GALLBLADDER_DIS_AGE_DIAG       as "71" 
                 , h.HISTORY_MYOMA_UTERI            as "72" 
                 , h.TRT_MYOMA_UTERI_OP             as "73" 
                 , h.MYOMA_UTERI_AGE_DIAG           as "74" 
                 , h.HISTORY_CERVICITIS             as "75" 
                 , h.TRT_CERVICITIS_OP              as "76" 
                 , h.CERVICITIS_AGE_DIAG            as "77" 
                 , h.HISTORY_TRAUMA                 as "78" 
                 , h.TRT_TRAUMA                     as "79" 
                 , h.TRAUMA_AGE_DIAG                as "80" 
                 , h.HISTORY_HBV                    as "81" 
                 , h.TRT_HBV                        as "82" 
                 , h.STATUS_HBV                     as "83" 
                 , h.HBV_AGE_DIAG                   as "84" 
                 , h.HISTORY_HCV                    as "85" 
                 , h.TRT_HCV                        as "86" 
                 , h.STATUS_HCV                     as "87" 
                 , h.HCV_AGE_DIAG                   as "88" 
                 , h.HISTORY_CIRRHOSIS              as "89" 
                 , h.TRT_CIRRHOSIS                  as "90" 
                 , h.STATUS_CIRRHOSIS               as "91" 
                 , h.CIRRHOSIS_AGE_DIAG             as "92" 
                 , h.HISTORY_HELICO_PYLORI          as "93" 
                 , h.TRT_HELICO_PYLORI              as "94" 
                 , h.STATUS_HELICO_PYLORI           as "95" 
                 , h.HELICO_PYLORI_AGE_DIAG         as "96" 
                 , h.HISTORY_COPD                   as "97" 
                 , h.TRT_HISTORY_COPD               as "98" 
                 , h.STATUS_HISTORY_COPD            as "99" 
                 , h.COPD_AGE_DIAG                  as "100"
                 , h.HISTORY_ARTHRITIS              as "101"
                 , h.TRT_ARTHRITIS                  as "102"
                 , h.STATUS_ARTHRITIS               as "103"
                 , h.TRT_ARTHRITIS_OP               as "104"
                 , h.ARTHRITIS_AGE_DIAG             as "105"
                 , h.HISTORY_CATARACT               as "106"
                 , h.TRT_CATARACT                   as "107"
                 , h.STATUS_CATARACT                as "108"
                 , h.TRT_CATARACT_OP                as "109"
                 , h.CATARACT_AGE_DIAG              as "110"
                 , h.HISTORY_GLAUCOMA               as "111"
                 , h.TRT_GLAUCOMA                   as "112"
                 , h.STATUS_GLAUCOMA                as "113"
                 , h.TRT_GLAUCOMA_OP                as "114"
                 , h.GLAUCOMA_AGE_DIAG              as "115"
                 , h.HISTORY_ASTHMA_ALLERGY         as "116"
                 , h.TRT_ASTHMA_ALLERGY             as "117"
                 , h.ASTHMA_ALLERGY_AGE_DIAG        as "118"
                 , h.HISTORY_ASTHMA                 as "119"
                 , h.TRT_ASTHMA                     as "120"
                 , h.STATUS_ASTHMA                  as "121"
                 , h.ASTHMA_AGE_DIAG                as "122"
                 , h.HISTORY_CORONARY_DIS           as "123"
                 , h.TRT_CORONARY_DIS               as "124"
                 , h.CORONARY_DIS_AGE_DIAG          as "125"
                 , h.HISTORY_ANGINA                 as "126"
                 , h.TRT_ANGINA                     as "127"
                 , h.STATUS_ANGINA                  as "128"
                 , h.TRT_ANGINA_OP                  as "129"
                 , h.ANGINA_AGE_DIAG                as "130"
                 , h.HISTORY_MI                     as "131"
                 , h.TRT_MI                         as "132"
                 , h.STATUS_MI                      as "133"
                 , h.TRT_MI_OP                      as "134"
                 , h.MI_AGE_DIAG                    as "135"
                 , h.HISTORY_KIDNEY_URINARY_DIS     as "136"
                 , h.TRT_KIDNEY_URINARY_DIS         as "137"
                 , h.STATUS_KIDNEY_URINARY_DIS      as "138"
                 , h.TRT_KIDNEY_URINARY_DIS_OP      as "139"
                 , h.KIDNEY_URINARY_DIS_AGE_DIAG    as "140"
                 , h.HISTORY_KIDNEY_DIS             as "141"
                 , h.TRT_KIDNEY_DIS                 as "142"
                 , h.KIDNEY_DIS_AGE_DIAG            as "143"
                 , h.HISTORY_URINARY_TRACT_DIS      as "144"
                 , h.TRT_URINARY_TRACT_DIS          as "145"
                 , h.URINARY_TRACT_DIS_AGE_DIAG     as "146"
                 , h.HISTORY_THYROID_DIS1           as "147"
                 , h.TRT_THYROID_DIS1               as "148"
                 , h.THYROID_DIS1_AGE_DIAG          as "149"
                 , h.HISTORY_BPH                    as "150"
                 , h.TRT_BPH                        as "151"
                 , h.STATUS_BPH                     as "152"
                 , h.TRT_BPH_OP                     as "153"
                 , h.BPH_AGE_DIAG                   as "154"
                 , h.HISTORY_THYROID_DIS2           as "155"
                 , h.TRT_THYROID_DIS2               as "156"
                 , h.STATUS_THYROID_DIS2            as "157"
                 , h.TRT_THYROID_DIS2_OP            as "158"
                 , h.THYROID_DIS2_AGE_DIAG          as "159"
                 , h.HISTORY_OTHER                  as "160"
                 , h.TRT_OTHER                      as "161"
                 , h.STATUS_OTHER                   as "162"
                 , h.TRT_OTHER_OP                   as "163"
                 , h.OTHER_AGE_DIAG                 as "164"
                 , sysdate                          as last_updt_dt
              from (-- 질병력
                    select /*+ index(f 3E3C23302E333E0E28_pk) */
                           f.rprs_apnt_no
                         , a.PTNO
                         , a.ordr_prrn_ymd
                         , f.inpc_cd
                         , a.history_comorbidity
                    /* 결핵 */
                         , decode(a.history_comorbidity,'0','0'
                                                       ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM104Y' ,'1'
                                                                                                       ,'AM104'  ,'1'
                                                                                                       ,'RR78Y'  ,'1'
                                                                                                       ,'RR78'   ,'1'
                                                                                                       ,'MA1152Y','1'
                                                                                                       ,'MA1153Y','1'
                                                                                                       ,'MA1154Y','1'
                                                                                                       ,'MA1155Y','1'
                                                                                                       ,'MA1156Y','1'
                                                                                                       ,'MA1157' ,DECODE(f.inqy_rspn_ctn1,'','','1'),'0'))
                                                       ,''
                                 ) history_tuberculosis
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn||f.inqy_rspn_ctn1,'AM104YY','1','AM104YN','0',''))
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1152Y','0'      --,'MA1152Y','1' 치료받은적 없음.
                                                                                             ,'MA1153Y','0'      --,'MA1153Y','2' 과거치료했음.
                                                                                             ,'MA1154Y','1','')) --,'MA1154Y','3' 현재치료중.
                                 ,''
                                 ) trt_tuberculosis
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1152Y','0'      --,'MA1152Y','1' 치료받은적 없음.
                                                                                             ,'MA1153Y','1'      --,'MA1153Y','2' 과거치료했음.
                                                                                             ,'MA1154Y','2','')) --,'MA1154Y','3' 현재치료중.
                                 ,''
                                 ) status_tuberculosis
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1155Y','1'      --,'MA1155Y','1' 수술/시술: 예
                                                                                             ,'MA1152Y','0'      --,'MA1152Y','1' 치료받은적 없음.
                                                                                             ,'MA1153Y','0'      --,'MA1153Y','2' 과거치료했음.
                                                                                             ,'MA1154Y','0'      --,'MA1154Y','3' 현재치료중.
                                                                                             ,'MA1157' ,DECODE(f.inqy_rspn_ctn1,'','','0')
                                                                                             ,''))
                                 ,''
                                 ) trt_tuberculosis_op
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM104Y',f.inqy_rspn_ctn2 
                                                                                             ,'AM104' ,f.inqy_rspn_ctn2,''))
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1157',f.inqy_rspn_ctn1,''))
                                 ,''
                                 ) tuberculosis_age_diag
                    /* 고혈압 */
                         , decode(a.history_comorbidity,'0','0'
                                                       ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM106Y' ,'1'
                                                                                ,'AM106'  ,'1'
                                                                                ,'RR80Y'  ,'1'
                                                                                ,'RR80'   ,'1'
                                                                                ,'MA167Y' ,'1'
                                                                                ,'MA168Y' ,'1'
                                                                                ,'MA169Y' ,'1'
                                                                                ,'MA170'  ,DECODE(f.inqy_rspn_ctn1,'','','1'),'0'))
                                                       ,''
                                 ) history_hypertension
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn||f.inqy_rspn_ctn1,'AM106YY','1','AM106YN','0',''))
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA167Y' ,'0'      --,'MA1152Y','1' 치료받은적 없음.
                                                                                             ,'MA168Y' ,'0'      --,'MA1153Y','2' 과거치료했음.
                                                                                             ,'MA169Y' ,'1','')) --,'MA1154Y','3' 현재치료중.
                                 ,''
                                 ) trt_hypertension
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA167Y' ,'0'      --,'MA1152Y','1' 치료받은적 없음.
                                                                                             ,'MA168Y' ,'1'      --,'MA1153Y','2' 과거치료했음.
                                                                                             ,'MA169Y' ,'2','')) --,'MA1154Y','3' 현재치료중.
                                 ,''
                                 ) status_hypertension
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM106Y',f.inqy_rspn_ctn2 
                                                                                             ,'AM106' ,f.inqy_rspn_ctn2,''))
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA170' ,f.inqy_rspn_ctn1,''))
                                 ,''
                                 ) hypertension_age_diag
                    /* 고지혈증 */
                         , decode(a.history_comorbidity,'0','0'
                                                       ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM107Y' ,'1'
                                                                                ,'AM107'  ,'1'
                                                                                ,'RR81Y'  ,'1'
                                                                                ,'RR81'   ,'1'
                                                                                ,'MA177Y' ,'1'
                                                                                ,'MA178Y' ,'1'
                                                                                ,'MA179Y' ,'1'
                                                                                ,'MA180'  ,DECODE(f.inqy_rspn_ctn1,'','','1'),'0'))
                                                       ,''
                                 ) history_hyperlipidemia
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn||f.inqy_rspn_ctn1,'AM107YY','1','AM107YN','0',''))
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA177Y' ,'0'      --,'MA1152Y','1' 치료받은적 없음.
                                                                                             ,'MA178Y' ,'0'      --,'MA1153Y','2' 과거치료했음.
                                                                                             ,'MA179Y' ,'1','')) --,'MA1154Y','3' 현재치료중.
                                 ,''
                                 ) trt_hyperlipidemia
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA177Y' ,'0'      --,'MA1152Y','1' 치료받은적 없음.
                                                                                             ,'MA178Y' ,'1'      --,'MA1153Y','2' 과거치료했음.
                                                                                             ,'MA179Y' ,'2','')) --,'MA1154Y','3' 현재치료중.
                                 ,''
                                 ) status_hyperlipidemia
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM107Y',f.inqy_rspn_ctn2 
                                                                                             ,'AM107' ,f.inqy_rspn_ctn2,''))
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA180' ,f.inqy_rspn_ctn1,''))
                                 ,''
                                 ) hyperlipidemia_age_diag
                    /* 뇌졸중/중풍 */
                         , decode(a.history_comorbidity,'0','0'
                                                       ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM108Y' ,'1'
                                                                                ,'AM108'  ,'1'
                                                                                ,'RR82Y'  ,'1'
                                                                                ,'RR82'   ,'1'
                                                                                ,'MA196Y' ,'1'
                                                                                ,'MA197Y' ,'1'
                                                                                ,'MA198Y' ,'1'
                                                                                ,'MA199Y' ,'1'
                                                                                ,'MA1100Y','1'
                                                                                ,'MA1101' ,DECODE(f.inqy_rspn_ctn1,'','','1'),'0'))
                                                       ,''
                                 ) history_stroke
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn||f.inqy_rspn_ctn1,'AM108YY','1','AM108YN','0',''))
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA196Y' ,'0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA197Y' ,'0'      --,'2' 과거치료했음.
                                                                                             ,'MA198Y' ,'1','')) --,'3' 현재치료중.
                                 ,''
                                 ) trt_stroke
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA196Y' ,'0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA197Y' ,'1'      --,'2' 과거치료했음.
                                                                                             ,'MA198Y' ,'2','')) --,'3' 현재치료중.
                                 ,''
                                 ) status_stroke
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA199Y' ,'1'      --,'1' 수술/시술: 예
                                                                                             ,'MA196Y' ,'0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA197Y' ,'0'      --,'2' 과거치료했음.
                                                                                             ,'MA198Y' ,'0'      --,'3' 현재치료중.
                                                                                             ,'MA1101' ,DECODE(f.inqy_rspn_ctn1,'','','0')
                                                                                             ,''))
                                 ,''
                                 ) trt_stroke_op
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM108Y',f.inqy_rspn_ctn2 
                                                                                             ,'AM108' ,f.inqy_rspn_ctn2,''))
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1101',f.inqy_rspn_ctn1,''))
                                 ,''
                                 ) stroke_age_diag
                    /* 당뇨병 */
                         , decode(a.history_comorbidity,'0','0'
                                                       ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM109Y' ,'1'
                                                                                ,'AM109'  ,'1'
                                                                                ,'RR83Y'  ,'1'
                                                                                ,'RR83'   ,'1'
                                                                                ,'MA172Y' ,'1'
                                                                                ,'MA173Y' ,'1'
                                                                                ,'MA174Y' ,'1'
                                                                                ,'MA175'  ,DECODE(f.inqy_rspn_ctn1,'','','1'),'0'))
                                                       ,''
                                 ) history_diabetes
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn||f.inqy_rspn_ctn1,'AM109YY','1','AM109YN','0',''))
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA172Y' ,'0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA173Y' ,'0'      --,'2' 과거치료했음.
                                                                                             ,'MA174Y' ,'1','')) --,'3' 현재치료중.
                                 ,''
                                 ) trt_diabetes
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA172Y' ,'0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA173Y' ,'1'      --,'2' 과거치료했음.
                                                                                             ,'MA174Y' ,'2','')) --,'3' 현재치료중.
                                 ,''
                                 ) status_diabetes
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM109Y',f.inqy_rspn_ctn2 
                                                                                             ,'AM109' ,f.inqy_rspn_ctn2,''))
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA175' ,f.inqy_rspn_ctn1,''))
                                 ,''
                                 ) diabetes_age_diag
                    /* 위/십이지장 궤양 */
                         , decode(a.history_comorbidity,'0','0'
                                                       ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM111Y' ,'1'
                                                                                ,'AM111'  ,'1'
                                                                                ,'RR85Y'  ,'1'
                                                                                ,'RR85'   ,'1'
                                                                                ,'MA1123Y','1'
                                                                                ,'MA1124Y','1'
                                                                                ,'MA1125Y','1'
                                                                                ,'MA1126Y','1'
                                                                                ,'MA1127Y','1'
                                                                                ,'MA1128' ,DECODE(f.inqy_rspn_ctn1,'','','1'),'0'))
                                                       ,''
                                 ) history_ga_duodenal_ulcer
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn||f.inqy_rspn_ctn1,'AM111YY','1','AM111YN','0',''))
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1123Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA1124Y','0'      --,'2' 과거치료했음.
                                                                                             ,'MA1125Y','1','')) --,'3' 현재치료중.
                                 ,''
                                 ) trt_ga_duodenal_ulcer
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1123Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA1124Y','1'      --,'2' 과거치료했음.
                                                                                             ,'MA1125Y','2','')) --,'3' 현재치료중.
                                 ,''
                                 ) status_ga_duodenal_ulcer
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1126Y','1'      --,'1' 수술/시술: 예
                                                                                             ,'MA1123Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA1124Y','0'      --,'2' 과거치료했음.
                                                                                             ,'MA1125Y','0'      --,'3' 현재치료중.
                                                                                             ,'MA1128' ,DECODE(f.inqy_rspn_ctn1,'','','0'),'')) 
                                 ,''
                                 ) trt_ga_duodenal_ulcer_op
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM111Y',f.inqy_rspn_ctn2 
                                                                                             ,'AM111' ,f.inqy_rspn_ctn2,''))
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1128' ,f.inqy_rspn_ctn1,''))
                                 ,''
                                 ) ga_duodenal_ulcer_age_diag
                    /* 대장용종(폴립) */
                         , decode(a.history_comorbidity,'0','0'
                                                       ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM114Y' ,'1'
                                                                                ,'AM114'  ,'1'
                                                                                ,'RR88Y'  ,'1'
                                                                                ,'RR88'   ,'1'
                                                                                ,'MA1135Y','1'
                                                                                ,'MA1136Y','1'
                                                                                ,'MA1137Y','1'
                                                                                ,'MA1138Y','1'
                                                                                ,'MA1139Y','1'
                                                                                ,'MA1140' ,DECODE(f.inqy_rspn_ctn1,'','','1'),'0'))
                                                       ,''
                                 ) history_colon_polyp
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn||f.inqy_rspn_ctn1,'AM114YY','1','AM114YN','0',''))
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1135Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA1136Y','0'      --,'2' 과거치료했음.
                                                                                             ,'MA1137Y','1','')) --,'3' 현재치료중.
                                 ,''
                                 ) trt_colon_polyp
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1135Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA1136Y','1'      --,'2' 과거치료했음.
                                                                                             ,'MA1137Y','2','')) --,'3' 현재치료중.
                                 ,''
                                 ) status_colon_polyp
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1138Y','1'      --,'1' 수술/시술: 예
                                                                                             ,'MA1135Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA1136Y','0'      --,'2' 과거치료했음.
                                                                                             ,'MA1137Y','0'      --,'3' 현재치료중.
                                                                                             ,'MA1140' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))
                                 ,''
                                 ) trt_colon_polyp_op
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM114Y',f.inqy_rspn_ctn2 
                                                                                             ,'AM114' ,f.inqy_rspn_ctn2,''))
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1140' ,f.inqy_rspn_ctn1,''))
                                 ,''
                                 ) colon_polyp_age_diag
                    /* 지방간 */
                         , decode(a.history_comorbidity,'0','0'
                                                       ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM118Y' ,'1'
                                                                                ,'AM118'  ,'1'
                                                                                ,'RR92Y'  ,'1'
                                                                                ,'RR92'   ,'1'
                                                                                ,'MA1118Y','1'
                                                                                ,'MA1119Y','1'
                                                                                ,'MA1120Y','1'
                                                                                ,'MA1121' ,DECODE(f.inqy_rspn_ctn1,'','','1'),'0'))
                                                       ,''
                                 ) history_fatty_liver
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn||f.inqy_rspn_ctn1,'AM118YY','1','AM118YN','0',''))
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1118Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA1119Y','0'      --,'2' 과거치료했음.
                                                                                             ,'MA1120Y','1','')) --,'3' 현재치료중.
                                 ,''
                                 ) trt_fatty_liver
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1118Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA1119Y','1'      --,'2' 과거치료했음.
                                                                                             ,'MA1120Y','2','')) --,'3' 현재치료중.
                                 ,''
                                 ) status_fatty_liver
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM118Y',f.inqy_rspn_ctn2 
                                                                                             ,'AM118' ,f.inqy_rspn_ctn2,''))
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1121' ,f.inqy_rspn_ctn1,''))
                                 ,''
                                 ) fatty_liver_age_diag
                    /* 갑상선 결절 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.history_comorbidity,'0','0'
                                                                              ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1173Y','1'
                                                                                                                              ,'MA1174Y','1'
                                                                                                                              ,'MA1175Y','1'
                                                                                                                              ,'MA1176Y','1'
                                                                                                                              ,'MA1177Y','1'
                                                                                                                              ,'MA1178' ,DECODE(f.inqy_rspn_ctn1,'','','1'),'0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) history_thyroid_nodules
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1173Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA1174Y','0'      --,'2' 과거치료했음.
                                                                                             ,'MA1175Y','1','')) --,'3' 현재치료중.
                                 ,''
                                 ) trt_thyroid_nodules
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1173Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA1174Y','1'      --,'2' 과거치료했음.
                                                                                             ,'MA1175Y','2','')) --,'3' 현재치료중.
                                 ,''
                                 ) status_thyroid_nodules
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1176Y','1'      --,'1' 수술/시술: 예
                                                                                             ,'MA1173Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA1174Y','0'      --,'2' 과거치료했음.
                                                                                             ,'MA1175Y','0'      --,'3' 현재치료중.
                                                                                             ,'MA1178' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))
                                 ,''
                                 ) trt_thyroid_nodules_op
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1178' ,f.inqy_rspn_ctn1,''))
                                 ,''
                                 ) thyroid_nodules_age_diag
                    /* 유방양성종양 */
                         , decode(a.history_comorbidity,'0','0'
                                                       ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM123Y' ,'1'
                                                                                ,'AM123'  ,'1'
                                                                                ,'RR97Y'  ,'1'
                                                                                ,'RR97'   ,'1'
                                                                                ,'MA1159Y','1'
                                                                                ,'MA1160Y','1'
                                                                                ,'MA1161Y','1'
                                                                                ,'MA1162Y','1'
                                                                                ,'MA1163Y','1'
                                                                                ,'MA1164' ,DECODE(f.inqy_rspn_ctn1,'','','1'),'0'))
                                                       ,''
                                 ) history_bbt
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1159Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA1160Y','0'      --,'2' 과거치료했음.
                                                                                             ,'MA1161Y','1','')) --,'3' 현재치료중.
                                 ,''
                                 ) trt_bbt
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1159Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA1160Y','1'      --,'2' 과거치료했음.
                                                                                             ,'MA1161Y','2','')) --,'3' 현재치료중.
                                 ,''
                                 ) status_bbt
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1162Y','1'      --,'1' 수술/시술: 예
                                                                                             ,'MA1159Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA1160Y','0'      --,'2' 과거치료했음.
                                                                                             ,'MA1161Y','0'      --,'3' 현재치료중.
                                                                                             ,'MA1164' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))
                                 ,''
                                 ) trt_bbt_op
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM123Y',f.inqy_rspn_ctn2 
                                                                                             ,'AM123' ,f.inqy_rspn_ctn2,''))
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1164' ,f.inqy_rspn_ctn1,''))
                                 ,''
                                 ) bbt_age_diag
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn||f.inqy_rspn_ctn1,'AM123YY','1','AM123YN','0',''))
                                           ,'RR' ,'9999'
                                           ,'MA1','9999'
                                 ,''
                                 ) trt_bbt_biopsy
                    /* 디스크 */
                         , decode(a.history_comorbidity,'0','0'
                                                       ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM126Y' ,'1'
                                                                                ,'AM126'  ,'1'
                                                                                ,'RR100Y' ,'1'
                                                                                ,'RR100'  ,'1'
                                                                                ,'MA1215Y','1'
                                                                                ,'MA1216Y','1'
                                                                                ,'MA1217Y','1'
                                                                                ,'MA1218Y','1'
                                                                                ,'MA1219Y','1'
                                                                                ,'MA1220' ,DECODE(f.inqy_rspn_ctn1,'','','1'),'0'))
                                                       ,''
                                 ) history_disc
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn||f.inqy_rspn_ctn1,'AM126YY','1','AM126YN','0',''))
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1215Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA1216Y','0'      --,'2' 과거치료했음.
                                                                                             ,'MA1217Y','1','')) --,'3' 현재치료중.
                                 ,''
                                 ) trt_disc
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1215Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA1216Y','1'      --,'2' 과거치료했음.
                                                                                             ,'MA1217Y','2','')) --,'3' 현재치료중.
                                 ,''
                                 ) status_disc
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1218Y','1'      --,'1' 수술/시술: 예
                                                                                             ,'MA1215Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA1216Y','0'      --,'2' 과거치료했음.
                                                                                             ,'MA1217Y','0'      --,'3' 현재치료중.
                                                                                             ,'MA1220' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))
                                 ,''
                                 ) trt_disc_op
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM126Y',f.inqy_rspn_ctn2 
                                                                                             ,'AM126' ,f.inqy_rspn_ctn2,''))
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1220' ,f.inqy_rspn_ctn1,''))
                                 ,''
                                 ) disc_age_diag
                    /* 위염 */
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'AM' ,decode(a.history_comorbidity,'0','0'
                                                                        ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM112Y' ,'1'
                                                                                                       ,'AM112'  ,'1','0')),'')
                                           ,'RR' ,decode(a.history_comorbidity,'0','0'
                                                                        ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'RR86Y'  ,'1'
                                                                                                       ,'RR86'   ,'1','0')),'')
                                 ,''
                                 ) history_gastritis
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn||f.inqy_rspn_ctn1,'AM112YY','1','AM112YN','0',''))
                                           ,'RR' ,'9999'
                                           ,'MA1','9999'
                                 ,''
                                 ) trt_gastritis
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM112Y',f.inqy_rspn_ctn2 
                                                                                             ,'AM112' ,f.inqy_rspn_ctn2,''))
                                           ,'RR' ,'9999'
                                           ,'MA1','9999'
                                 ,''
                                 ) gastritis_age_diag
                    /* 장염 */
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'AM' ,decode(a.history_comorbidity,'0','0'
                                                                        ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM113Y' ,'1'
                                                                                                       ,'AM113'  ,'1','0')),'')
                                           ,'RR' ,decode(a.history_comorbidity,'0','0'
                                                                        ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'RR87Y'  ,'1'
                                                                                                       ,'RR87'   ,'1','0')),'')
                                 ,''
                                 ) history_enteritis
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn||f.inqy_rspn_ctn1,'AM113YY','1','AM113YN','0',''))
                                           ,'RR' ,'9999'
                                           ,'MA1','9999'
                                 ,''
                                 ) trt_enteritis
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM113Y',f.inqy_rspn_ctn2 
                                                                                             ,'AM113' ,f.inqy_rspn_ctn2,''))
                                           ,'RR' ,'9999'
                                           ,'MA1','9999'
                                 ,''
                                 ) enteritis_age_diag
                    /* 치질 */
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'AM' ,decode(a.history_comorbidity,'0','0'
                                                                        ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM115Y' ,'1'
                                                                                                       ,'AM115'  ,'1','0')),'')
                                           ,'RR' ,decode(a.history_comorbidity,'0','0'
                                                                        ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'RR89Y'  ,'1'
                                                                                                       ,'RR89'   ,'1','0')),'')
                                 ,''
                                 ) history_hemorrhoid
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn||f.inqy_rspn_ctn1,'AM115YY','1','AM115YN','0',''))
                                           ,'RR' ,'9999'
                                           ,'MA1','9999'
                                 ,''
                                 ) trt_hemorrhoid
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM115Y',f.inqy_rspn_ctn2 
                                                                                             ,'AM115' ,f.inqy_rspn_ctn2,''))
                                           ,'RR' ,'9999'
                                           ,'MA1','9999'
                                 ,''
                                 ) hemorrhoid_age_diag
                    /* 급성간염 */
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'AM' ,decode(a.history_comorbidity,'0','0'
                                                                        ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM116Y' ,'1'
                                                                                                       ,'AM116'  ,'1','0')),'')
                                           ,'RR' ,decode(a.history_comorbidity,'0','0'
                                                                        ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'RR90Y'  ,'1'
                                                                                                       ,'RR90'   ,'1','0')),'')
                                 ,''
                                 ) history_acute_hep
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn||f.inqy_rspn_ctn1,'AM116YY','1','AM116YN','0',''))
                                           ,'RR' ,'9999'
                                           ,'MA1','9999'
                                 ,''
                                 ) trt_acute_hep
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM116Y',f.inqy_rspn_ctn2 
                                                                                             ,'AM116' ,f.inqy_rspn_ctn2,''))
                                           ,'RR' ,'9999'
                                           ,'MA1','9999'
                                 ,''
                                 ) acute_hep_age_diag
                    /* 만성간염/ 간경화 진단 여부 */
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'AM' ,decode(a.history_comorbidity,'0','0'
                                                                        ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM117Y' ,'1'
                                                                                                       ,'AM117'  ,'1','0')),'')
                                           ,'RR' ,decode(a.history_comorbidity,'0','0'
                                                                        ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'RR91Y'  ,'1'
                                                                                                       ,'RR91'   ,'1','0')),'')
                                 ,''
                                 ) history_hep_cirrhosis
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn||f.inqy_rspn_ctn1,'AM117YY','1','AM117YN','0',''))
                                           ,'RR' ,'9999'
                                           ,'MA1','9999'
                                 ,''
                                 ) trt_hep_cirrhosis
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM117Y',f.inqy_rspn_ctn2 
                                                                                             ,'AM117' ,f.inqy_rspn_ctn2,''))
                                           ,'RR' ,'9999'
                                           ,'MA1','9999'
                                 ,''
                                 ) hep_cirrhosis_age_diag
                    /* 담석/담낭염 */
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'AM' ,decode(a.history_comorbidity,'0','0'
                                                                        ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM119Y' ,'1'
                                                                                                       ,'AM119'  ,'1','0')),'')
                                           ,'RR' ,decode(a.history_comorbidity,'0','0'
                                                                        ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'RR93Y'  ,'1'
                                                                                                       ,'RR93'   ,'1','0')),'')
                                 ,''
                                 ) history_gallbladder_dis
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn||f.inqy_rspn_ctn1,'AM119YY','1','AM119YN','0',''))
                                           ,'RR' ,'9999'
                                           ,'MA1','9999'
                                 ,''
                                 ) trt_gallbladder_dis
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM119Y',f.inqy_rspn_ctn2 
                                                                                             ,'AM119' ,f.inqy_rspn_ctn2,''))
                                           ,'RR' ,'9999'
                                           ,'MA1','9999'
                                 ,''
                                 ) gallbladder_dis_age_diag
                    /* 자궁근종 */
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,decode(a.history_comorbidity,'0','0'
                                                                        ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM124Y' ,'1'
                                                                                                       ,'AM124'  ,'1'
                                                                                                       ,'RR98Y'  ,'1'
                                                                                                       ,'RR98'   ,'1','0'))
                                                   ,''
                                                   )
                                 ) history_myoma_uteri
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn||f.inqy_rspn_ctn1,'AM124YY','1','AM124YN','0',''))
                                           ,'RR' ,'9999'
                                           ,'MA1','9999'
                                 ,''
                                 ) trt_myoma_uteri_op
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM124Y',f.inqy_rspn_ctn2 
                                                                                             ,'AM124' ,f.inqy_rspn_ctn2,''))
                                           ,'RR' ,'9999'
                                           ,'MA1','9999'
                                 ,''
                                 ) myoma_uteri_age_diag
                    /* 자궁경부염증 */
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,decode(a.history_comorbidity,'0','0'
                                                                        ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM125Y' ,'1'
                                                                                                       ,'AM125'  ,'1'
                                                                                                       ,'RR99Y'  ,'1'
                                                                                                       ,'RR99'   ,'1','0'))
                                                   ,''
                                                   )
                                 ) history_cervicitis
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn||f.inqy_rspn_ctn1,'AM125YY','1','AM125YN','0',''))
                                           ,'RR' ,'9999'
                                           ,'MA1','9999'
                                 ,''
                                 ) trt_cervicitis_op
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM125Y',f.inqy_rspn_ctn2 
                                                                                             ,'AM125' ,f.inqy_rspn_ctn2,''))
                                           ,'RR' ,'9999'
                                           ,'MA1','9999'
                                 ,''
                                 ) cervicitis_age_diag
                    /* 외상사고 */
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.history_comorbidity,'0','0'
                                                                              ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM128Y' ,'1'
                                                                                                       ,'AM128'  ,'1','0')),'')
                                           ,''
                                 ) history_trauma
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn||f.inqy_rspn_ctn1,'AM128YY','1','AM128YN','0',''))
                                           ,'RR' ,'9999'
                                           ,'MA1','9999'
                                 ,''
                                 ) trt_trauma
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM128Y',f.inqy_rspn_ctn2 
                                                                                             ,'AM128' ,f.inqy_rspn_ctn2,''))
                                           ,'RR' ,'9999'
                                           ,'MA1','9999'
                                 ,''
                                 ) trauma_age_diag
                    /* B형 간염 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.history_comorbidity,'0','0'
                                                                              ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1103Y','1'
                                                                                                       ,'MA1104Y','1'
                                                                                                       ,'MA1105Y','1'
                                                                                                       ,'MA1106' ,DECODE(f.inqy_rspn_ctn1,'','','1'),'0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) history_hbv
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1103Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA1104Y','0'      --,'2' 과거치료했음.
                                                                                             ,'MA1105Y','1','')) --,'3' 현재치료중.
                                 ,''
                                 ) trt_hbv
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1103Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA1104Y','1'      --,'2' 과거치료했음.
                                                                                             ,'MA1105Y','2','')) --,'3' 현재치료중.
                                 ,''
                                 ) status_hbv
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1106' ,f.inqy_rspn_ctn1,''))
                                 ,''
                                 ) hbv_age_diag
                    /* C형 간염 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.history_comorbidity,'0','0'
                                                                              ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1108Y','1'
                                                                                                       ,'MA1109Y','1'
                                                                                                       ,'MA1110Y','1'
                                                                                                       ,'MA1111' ,DECODE(f.inqy_rspn_ctn1,'','','1'),'0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) history_hcv
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1108Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA1109Y','0'      --,'2' 과거치료했음.
                                                                                             ,'MA1110Y','1','')) --,'3' 현재치료중.
                                 ,''
                                 ) trt_hcv
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1108Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA1109Y','1'      --,'2' 과거치료했음.
                                                                                             ,'MA1110Y','2','')) --,'3' 현재치료중.
                                 ,''
                                 ) status_hcv
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1111' ,f.inqy_rspn_ctn1,''))
                                 ,''
                                 ) hcv_age_diag
                    /* 간경변 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.history_comorbidity,'0','0'
                                                                              ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1113Y','1'
                                                                                                       ,'MA1114Y','1'
                                                                                                       ,'MA1115Y','1'
                                                                                                       ,'MA1116' ,DECODE(f.inqy_rspn_ctn1,'','','1'),'0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) history_cirrhosis
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1113Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA1114Y','0'      --,'2' 과거치료했음.
                                                                                             ,'MA1115Y','1','')) --,'3' 현재치료중.
                                 ,''
                                 ) trt_cirrhosis
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1113Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA1114Y','1'      --,'2' 과거치료했음.
                                                                                             ,'MA1115Y','2','')) --,'3' 현재치료중.
                                 ,''
                                 ) status_cirrhosis
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1116' ,f.inqy_rspn_ctn1,''))
                                 ,''
                                 ) cirrhosis_age_diag
                    /* 헬리코박터 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.history_comorbidity,'0','0'
                                                                              ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1130Y','1'
                                                                                                       ,'MA1131Y','1'
                                                                                                       ,'MA1132Y','1'
                                                                                                       ,'MA1133' ,DECODE(f.inqy_rspn_ctn1,'','','1'),'0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) history_helico_pylori
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1130Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA1131Y','0'      --,'2' 과거치료했음.
                                                                                             ,'MA1132Y','1','')) --,'3' 현재치료중.
                                 ,''
                                 ) trt_helico_pylori
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1130Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA1131Y','1'      --,'2' 과거치료했음.
                                                                                             ,'MA1132Y','2','')) --,'3' 현재치료중.
                                 ,''
                                 ) status_helico_pylori
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1133' ,f.inqy_rspn_ctn1,''))
                                 ,''
                                 ) helico_pylori_age_diag
                    /* 만성폐쇄성 폐질환 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.history_comorbidity,'0','0'
                                                                              ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1142Y','1'
                                                                                                       ,'MA1143Y','1'
                                                                                                       ,'MA1144Y','1'
                                                                                                       ,'MA1145' ,DECODE(f.inqy_rspn_ctn1,'','','1'),'0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) history_copd
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1142Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA1143Y','0'      --,'2' 과거치료했음.
                                                                                             ,'MA1144Y','1','')) --,'3' 현재치료중.
                                 ,''
                                 ) trt_history_copd
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1142Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA1143Y','1'      --,'2' 과거치료했음.
                                                                                             ,'MA1144Y','2','')) --,'3' 현재치료중.
                                 ,''
                                 ) status_history_copd
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1145' ,f.inqy_rspn_ctn1,''))
                                 ,''
                                 ) copd_age_diag
                    /* 관절염 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.history_comorbidity,'0','0'
                                                                              ,'1',max(DECODE(f.qstn_cd1||f.ceck_yn,'6-1-28-1Y','1'
                                                                                            ,'6-1-28-2Y','1'
                                                                                            ,'6-1-28-3Y','1'
                                                                                            ,'6-1-28-4Y','1'
                                                                                            ,'6-1-28-5Y','1'
                                                                                            ,'6-1-28-6' ,DECODE(f.inqy_rspn_ctn1,'','','1'),'0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) history_arthritis
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',max(DECODE(f.qstn_cd1||f.ceck_yn,'6-1-28-1Y','0'      --,'1' 치료받은적 없음.
                                                                                  ,'6-1-28-2Y','0'      --,'2' 과거치료했음.
                                                                                  ,'6-1-28-3Y','1','')) --,'3' 현재치료중.
                                 ,''
                                 ) trt_arthritis
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',max(DECODE(f.qstn_cd1||f.ceck_yn,'6-1-28-1Y','0'      --,'1' 치료받은적 없음.
                                                                                  ,'6-1-28-2Y','1'      --,'2' 과거치료했음.
                                                                                  ,'6-1-28-3Y','2','')) --,'3' 현재치료중.
                                 ,''
                                 ) status_arthritis
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',max(DECODE(f.qstn_cd1||f.ceck_yn,'6-1-28-4Y','1'      --,'1' 수술/시술: 예
                                                                                  ,'6-1-28-1Y','0'      --,'1' 치료받은적 없음.
                                                                                  ,'6-1-28-2Y','0'      --,'2' 과거치료했음.
                                                                                  ,'6-1-28-3Y','0'      --,'3' 현재치료중.
                                                                                  ,'6-1-28-6' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))
                                 ,''
                                 ) trt_arthritis_op
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',max(DECODE(f.qstn_cd1||f.ceck_yn,'6-1-28-6' ,f.inqy_rspn_ctn1,''))
                                 ,''
                                 ) arthritis_age_diag
                    /* 백내장 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.history_comorbidity,'0','0'
                                                                              ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1201Y','1'
                                                                                                       ,'MA1202Y','1'
                                                                                                       ,'MA1203Y','1'
                                                                                                       ,'MA1204Y','1'
                                                                                                       ,'MA1205Y','1'
                                                                                                       ,'MA1206' ,DECODE(f.inqy_rspn_ctn1,'','','1'),'0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) history_cataract
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1201Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA1202Y','0'      --,'2' 과거치료했음.
                                                                                             ,'MA1203Y','1','')) --,'3' 현재치료중.
                                 ,''
                                 ) trt_cataract
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1201Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA1202Y','1'      --,'2' 과거치료했음.
                                                                                             ,'MA1203Y','2','')) --,'3' 현재치료중.
                                 ,''
                                 ) status_cataract
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1204Y','1'      --,'1' 수술/시술: 예
                                                                                             ,'MA1201Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA1202Y','0'      --,'2' 과거치료했음.
                                                                                             ,'MA1203Y','0'      --,'3' 현재치료중.
                                                                                             ,'MA1206' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))
                                 ,''
                                 ) trt_cataract_op
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1206' ,f.inqy_rspn_ctn1,''))
                                 ,''
                                 ) cataract_age_diag
                    /* 녹내장 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.history_comorbidity,'0','0'
                                                                              ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1208Y','1'
                                                                                                       ,'MA1209Y','1'
                                                                                                       ,'MA1210Y','1'
                                                                                                       ,'MA1211Y','1'
                                                                                                       ,'MA1212Y','1'
                                                                                                       ,'MA1213' ,DECODE(f.inqy_rspn_ctn1,'','','1'),'0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) history_glaucoma
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1208Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA1209Y','0'      --,'2' 과거치료했음.
                                                                                             ,'MA1210Y','1','')) --,'3' 현재치료중.
                                 ,''
                                 ) trt_glaucoma
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1208Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA1209Y','1'      --,'2' 과거치료했음.
                                                                                             ,'MA1210Y','2','')) --,'3' 현재치료중.
                                 ,''
                                 ) status_glaucoma
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1211Y','1'      --,'1' 수술/시술: 예
                                                                                             ,'MA1208Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA1209Y','0'      --,'2' 과거치료했음.
                                                                                             ,'MA1210Y','0'      --,'3' 현재치료중.
                                                                                             ,'MA1213' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))
                                 ,''
                                 ) trt_glaucoma_op
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1213' ,f.inqy_rspn_ctn1,''))
                                 ,''
                                 ) glaucoma_age_diag
                    /* 천식/알러지 */
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'AM' ,decode(a.history_comorbidity,'0','0'
                                                                        ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM105Y' ,'1'
                                                                                                       ,'AM105'  ,'1','0')),'')
                                           ,'RR' ,decode(a.history_comorbidity,'0','0'
                                                                        ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'RR79Y'  ,'1'
                                                                                                       ,'RR79'   ,'1','0')),'')
                                 ,''
                                 ) history_asthma_allergy
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn||f.inqy_rspn_ctn1,'AM105YY','1','AM105YN','0',''))
                                           ,'RR' ,'9999'
                                           ,'MA1','9999'
                                 ,''
                                 ) trt_asthma_allergy
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM105Y',f.inqy_rspn_ctn2 
                                                                                             ,'AM105' ,f.inqy_rspn_ctn2,''))
                                           ,'RR' ,'9999'
                                           ,'MA1','9999'
                                 ,''
                                 ) asthma_allergy_age_diag
                    /* 천식 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.history_comorbidity,'0','0'
                                                                              ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1147Y','1'
                                                                                                       ,'MA1148Y','1'
                                                                                                       ,'MA1149Y','1'
                                                                                                       ,'MA1150' ,DECODE(f.inqy_rspn_ctn1,'','','1'),'0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) history_asthma
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1147Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA1148Y','0'      --,'2' 과거치료했음.
                                                                                             ,'MA1149Y','1','')) --,'3' 현재치료중.
                                 ,''
                                 ) trt_asthma
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1147Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA1148Y','1'      --,'2' 과거치료했음.
                                                                                             ,'MA1149Y','2','')) --,'3' 현재치료중.
                                 ,''
                                 ) status_asthma
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1150' ,f.inqy_rspn_ctn1,''))
                                 ,''
                                 ) asthma_age_diag
                    /* 협심증/심근경색 */
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'AM' ,decode(a.history_comorbidity,'0','0'
                                                                        ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM110Y' ,'1'
                                                                                                       ,'AM110'  ,'1','0')),'')
                                           ,'RR' ,decode(a.history_comorbidity,'0','0'
                                                                        ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'RR84Y'  ,'1'
                                                                                                       ,'RR84'   ,'1','0')),'')
                                 ,''
                                 ) history_coronary_dis
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn||f.inqy_rspn_ctn1,'AM110YY','1','AM110YN','0',''))
                                           ,'RR' ,'9999'
                                           ,'MA1','9999'
                                 ,''
                                 ) trt_coronary_dis
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM110Y',f.inqy_rspn_ctn2 
                                                                                             ,'AM110' ,f.inqy_rspn_ctn2,''))
                                           ,'RR' ,'9999'
                                           ,'MA1','9999'
                                 ,''
                                 ) coronary_dis_age_diag
                    /* 협심증 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.history_comorbidity,'0','0'
                                                                              ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA182Y','1'
                                                                                                       ,'MA183Y','1'
                                                                                                       ,'MA184Y','1'
                                                                                                       ,'MA185Y','1'
                                                                                                       ,'MA186Y','1'
                                                                                                       ,'MA187' ,DECODE(f.inqy_rspn_ctn1,'','','1'),'0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) history_angina
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA182Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA183Y','0'      --,'2' 과거치료했음.
                                                                                             ,'MA184Y','1','')) --,'3' 현재치료중.
                                 ,''
                                 ) trt_angina
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA182Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA183Y','1'      --,'2' 과거치료했음.
                                                                                             ,'MA184Y','2','')) --,'3' 현재치료중.
                                 ,''
                                 ) status_angina
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA185Y','1'      --,'1' 수술/시술: 예
                                                                                             ,'MA182Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA183Y','0'      --,'2' 과거치료했음.
                                                                                             ,'MA184Y','0'      --,'3' 현재치료중.
                                                                                             ,'MA187' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))
                                 ,''
                                 ) trt_angina_op
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA187' ,f.inqy_rspn_ctn1,''))
                                 ,''
                                 ) angina_age_diag
                    /* 심근경색 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.history_comorbidity,'0','0'
                                                                              ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA189Y','1'
                                                                                                       ,'MA190Y','1'
                                                                                                       ,'MA191Y','1'
                                                                                                       ,'MA192Y','1'
                                                                                                       ,'MA193Y','1'
                                                                                                       ,'MA194' ,DECODE(f.inqy_rspn_ctn1,'','','1'),'0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) history_mi
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA189Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA190Y','0'      --,'2' 과거치료했음.
                                                                                             ,'MA191Y','1','')) --,'3' 현재치료중.
                                 ,''
                                 ) trt_mi
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA189Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA190Y','1'      --,'2' 과거치료했음.
                                                                                             ,'MA191Y','2','')) --,'3' 현재치료중.
                                 ,''
                                 ) status_mi
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA192Y','1'      --,'1' 수술/시술: 예
                                                                                             ,'MA189Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA190Y','0'      --,'2' 과거치료했음.
                                                                                             ,'MA191Y','0'      --,'3' 현재치료중.
                                                                                             ,'MA194' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))
                                 ,''
                                 ) trt_mi_op
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA194' ,f.inqy_rspn_ctn1,''))
                                 ,''
                                 ) mi_age_diag
                    /* 신장 및 방광질환 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.history_comorbidity,'0','0'
                                                                              ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1180Y','1'
                                                                                                       ,'MA1181Y','1'
                                                                                                       ,'MA1182Y','1'
                                                                                                       ,'MA1183Y','1'
                                                                                                       ,'MA1184Y','1'
                                                                                                       ,'MA1185' ,DECODE(f.inqy_rspn_ctn1,'','','1'),'0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) history_kidney_urinary_dis
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1180Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA1181Y','0'      --,'2' 과거치료했음.
                                                                                             ,'MA1182Y','1','')) --,'3' 현재치료중.
                                 ,''
                                 ) trt_kidney_urinary_dis
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1180Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA1181Y','1'      --,'2' 과거치료했음.
                                                                                             ,'MA1182Y','2','')) --,'3' 현재치료중.
                                 ,''
                                 ) status_kidney_urinary_dis
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1183Y','1'      --,'1' 수술/시술: 예
                                                                                             ,'MA1180Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA1181Y','0'      --,'2' 과거치료했음.
                                                                                             ,'MA1182Y','0'      --,'3' 현재치료중.
                                                                                             ,'MA1185' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))
                                 ,''
                                 ) trt_kidney_urinary_dis_op
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1185' ,f.inqy_rspn_ctn1,''))
                                 ,''
                                 ) kidney_urinary_dis_age_diag
                    /* 신장질환 */
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'AM' ,decode(a.history_comorbidity,'0','0'
                                                                        ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM120Y' ,'1'
                                                                                                       ,'AM120'  ,'1','0')),'')
                                           ,'RR' ,decode(a.history_comorbidity,'0','0'
                                                                        ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'RR94Y'  ,'1'
                                                                                                       ,'RR94'   ,'1','0')),'')
                                 ,''
                                 ) history_kidney_dis
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn||f.inqy_rspn_ctn1,'AM120YY','1','AM120YN','0',''))
                                           ,'RR' ,'9999'
                                           ,'MA1','9999'
                                 ,''
                                 ) trt_kidney_dis
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM120Y',f.inqy_rspn_ctn2 
                                                                                             ,'AM120' ,f.inqy_rspn_ctn2,''))
                                           ,'RR' ,'9999'
                                           ,'MA1','9999'
                                 ,''
                                 ) kidney_dis_age_diag
                    /* 방광질환 */
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'AM' ,decode(a.history_comorbidity,'0','0'
                                                                        ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM121Y' ,'1'
                                                                                                       ,'AM121'  ,'1','0')),'')
                                           ,'RR' ,decode(a.history_comorbidity,'0','0'
                                                                        ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'RR95Y'  ,'1'
                                                                                                       ,'RR95'   ,'1','0')),'')
                                 ,''
                                 ) history_urinary_tract_dis
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn||f.inqy_rspn_ctn1,'AM121YY','1','AM121YN','0',''))
                                           ,'RR' ,'9999'
                                           ,'MA1','9999'
                                 ,''
                                 ) trt_urinary_tract_dis
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM121Y',f.inqy_rspn_ctn2 
                                                                                             ,'AM121' ,f.inqy_rspn_ctn2,''))
                                           ,'RR' ,'9999'
                                           ,'MA1','9999'
                                 ,''
                                 ) urinary_tract_dis_age_diag
                    /* 갑상선 질환 */
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'AM' ,decode(a.history_comorbidity,'0','0'
                                                                        ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM122Y' ,'1'
                                                                                                       ,'AM122'  ,'1','0')),'')
                                           ,'RR' ,decode(a.history_comorbidity,'0','0'
                                                                        ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'RR96Y'  ,'1'
                                                                                                       ,'RR96'   ,'1','0')),'')
                                 ,''
                                 ) history_thyroid_dis1
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn||f.inqy_rspn_ctn1,'AM122YY','1','AM122YN','0',''))
                                           ,'RR' ,'9999'
                                           ,'MA1','9999'
                                 ,''
                                 ) trt_thyroid_dis1
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM122Y',f.inqy_rspn_ctn2 
                                                                                             ,'AM122' ,f.inqy_rspn_ctn2,''))
                                           ,'RR' ,'9999'
                                           ,'MA1','9999'
                                 ,''
                                 ) thyroid_dis1_age_diag
                    /* 전립선 비대증 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.history_comorbidity,'0','0'
                                                                              ,'1',max(DECODE(f.qstn_cd1||f.ceck_yn,'6-1-27-1Y','1'
                                                                                            ,'6-1-27-2Y','1'
                                                                                            ,'6-1-27-3Y','1'
                                                                                            ,'6-1-27-4Y','1'
                                                                                            ,'6-1-27-5Y','1'
                                                                                            ,'6-1-27-6' ,DECODE(f.inqy_rspn_ctn1,'','','1'),'0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) history_bph
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',max(DECODE(f.qstn_cd1||f.ceck_yn,'6-1-27-1Y','0'      --,'1' 치료받은적 없음.
                                                                                  ,'6-1-27-2Y','0'      --,'2' 과거치료했음.
                                                                                  ,'6-1-27-3Y','1','')) --,'3' 현재치료중.
                                 ,''
                                 ) trt_bph
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',max(DECODE(f.qstn_cd1||f.ceck_yn,'6-1-27-1Y','0'      --,'1' 치료받은적 없음.
                                                                                  ,'6-1-27-2Y','1'      --,'2' 과거치료했음.
                                                                                  ,'6-1-27-3Y','2','')) --,'3' 현재치료중.
                                 ,''
                                 ) status_bph
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',max(DECODE(f.qstn_cd1||f.ceck_yn,'6-1-27-4Y','1'      --,'1' 수술/시술: 예
                                                                                  ,'6-1-27-1Y','0'      --,'1' 치료받은적 없음.
                                                                                  ,'6-1-27-2Y','0'      --,'2' 과거치료했음.
                                                                                  ,'6-1-27-3Y','0'      --,'3' 현재치료중.
                                                                                  ,'6-1-27-6' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))
                                 ,''
                                 ) trt_bph_op
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',max(DECODE(f.qstn_cd1||f.ceck_yn,'6-1-27-6' ,f.inqy_rspn_ctn1,''))
                                 ,''
                                 ) bph_age_diag
                    /* 갑상선 기능 저하증 및 항진증 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.history_comorbidity,'0','0'
                                                                              ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1166Y','1'
                                                                                                       ,'MA1167Y','1'
                                                                                                       ,'MA1168Y','1'
                                                                                                       ,'MA1169Y','1'
                                                                                                       ,'MA1170Y','1'
                                                                                                       ,'MA1171' ,DECODE(f.inqy_rspn_ctn1,'','','1'),'0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) history_thyroid_dis2
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1166Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA1167Y','0'      --,'2' 과거치료했음.
                                                                                             ,'MA1168Y','1','')) --,'3' 현재치료중.
                                 ,''
                                 ) trt_thyroid_dis2
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1166Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA1167Y','1'      --,'2' 과거치료했음.
                                                                                             ,'MA1168Y','2','')) --,'3' 현재치료중.
                                 ,''
                                 ) status_thyroid_dis2
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1169Y','1'      --,'1' 수술/시술: 예
                                                                                             ,'MA1166Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA1167Y','0'      --,'2' 과거치료했음.
                                                                                             ,'MA1168Y','0'      --,'3' 현재치료중.
                                                                                             ,'MA1171' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))
                                 ,''
                                 ) trt_thyroid_dis2_op
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1171' ,f.inqy_rspn_ctn1,''))
                                 ,''
                                 ) thyroid_dis2_age_diag
                    /* 기타질환 */
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,'AM' ,decode(a.history_comorbidity,'0','0'
                                                                        ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM129Y' ,'1'
                                                                                                       ,'AM129'  ,'1','0')),'')
                                           ,'MA1' ,decode(a.history_comorbidity,'0','0'
                                                                        ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1222Y','1'
                                                                                                       ,'MA1223Y','1'
                                                                                                       ,'MA1224Y','1'
                                                                                                       ,'MA1225Y','1'
                                                                                                       ,'MA1226Y','1'
                                                                                                       ,'MA1227' ,DECODE(f.inqy_rspn_ctn1,'','','1'),'0')),'')
                                 ,''
                                 ) history_other
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn||f.inqy_rspn_ctn1,'AM129YY','1','AM129YN','0',''))
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1222Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA1223Y','0'      --,'2' 과거치료했음.
                                                                                             ,'MA1224Y','1','')) --,'3' 현재치료중.
                                 ,''
                                 ) trt_other
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1222Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA1223Y','1'      --,'2' 과거치료했음.
                                                                                             ,'MA1224Y','2','')) --,'3' 현재치료중.
                                 ,''
                                 ) status_other
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1225Y','1'      --,'1' 수술/시술: 예
                                                                                             ,'MA1222Y','0'      --,'1' 치료받은적 없음.
                                                                                             ,'MA1223Y','0'      --,'2' 과거치료했음.
                                                                                             ,'MA1224Y','0'      --,'3' 현재치료중.
                                                                                             ,'MA1227' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))
                                 ,''
                                 ) trt_other_op
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM129Y' ,f.inqy_rspn_ctn2 
                                                                                             ,'AM129'  ,f.inqy_rspn_ctn2,''))
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1227' ,f.inqy_rspn_ctn1,''))
                                 ,''
                                 ) other_age_diag
                      from (-- 질병력 전체값 고려, MA1 문진의 '수술/시술여부: 아니오'는 고려대상에서 제외.
                            select  /*+ ordered use_nl(b a) index(b 3E3C0E433E3C0E3E28_i13) index(a 3E3C23302E333E0E28_pk) */
                                   'C02' grp
                                 , a.PTNO
                                 , a.ordr_prrn_ymd
                                 , a.inpc_cd
                            /* 질병력 */
                                 , case 
                                        when /*case1. 질병응답내역이 아무것도 없고, 질병력없다에 체크된 경우는 0 */
                                             count(
                                                   case 
                                                        when a.inpc_cd = 'AM'  and (a.item_sno between 103 and 126) then a.inqy_rspn_cd
                                                        when a.inpc_cd = 'AM'  and (a.item_sno between 128 and 129) then a.inqy_rspn_cd
                                                        when a.inpc_cd = 'RR'  and (a.item_sno between 77  and 100) then a.inqy_rspn_cd
                                                        when a.inpc_cd = 'MA1' and (a.item_sno between 66  and 227) then a.ceck_yn||a.inqy_rspn_ctn1 -- MA1 문진의 경우 CTN은 응답이 있어도 ceck_yn이 null이므로 함께 고려
                                                        when a.inpc_cd = 'MA1' and (a.item_sno between 66  and 227) then a.inqy_rspn_ctn1
                                                        else ''
                                                   end
                                                  ) = 0
                                             and
                                             count(case when a.inpc_cd||a.item_sno            = 'AM130' then a.inqy_rspn_cd
                                                        when a.inpc_cd||a.item_sno            = 'RR101' then a.inqy_rspn_cd
                                                        when a.inpc_cd||a.item_sno||a.ceck_yn = 'MA165Y' then a.ceck_yn 
                                                        else '' 
                                                   end
                                                  ) = 1
                                        then '0'
                                        when /*case2. 다른 질병응답내역이 있으면 1 */
                                             count(
                                                   case 
                                                        when a.inpc_cd = 'AM'  and (a.item_sno between 103 and 126) then a.inqy_rspn_cd
                                                        when a.inpc_cd = 'AM'  and (a.item_sno between 128 and 129) then a.inqy_rspn_cd
                                                        when a.inpc_cd = 'RR'  and (a.item_sno between 77  and 100) then a.inqy_rspn_cd
                                                        when a.inpc_cd = 'MA1' and (a.item_sno between 66  and 227) then a.ceck_yn||a.inqy_rspn_ctn1 -- MA1 문진의 경우 CTN은 응답이 있어도 ceck_yn이 null이므로 함께 고려
                                                        when a.inpc_cd = 'MA1' and (a.item_sno between 66  and 227) then a.inqy_rspn_ctn1
                                                        else ''
                                                   end
                                                  ) > 0
                                        then '1'
                                        else ''
                                   end history_comorbidity 
                              from 스키마.3E3C0E433E3C0E3E28@SMISR_스키마 b
                                 , 스키마.3E3C23302E333E0E28@SMISR_스키마 a
                             where 
                    --               b.ptno IN ('01982036' -- AM문진  응답자
                    --                         ,'00477937' -- RR문진  응답자
                    --                         ,'04032026' -- MA1문진 응답자
                    --                         )
                    --           and 
                                   b.ordr_prrn_ymd between to_date(&qfrdt,'yyyymmdd') and to_date(&qtodt,'yyyymmdd')
                               and b.ordr_ymd is not null
                               and b.cncl_dt is null
                               and a.ptno = b.ptno
                               and a.ordr_prrn_ymd = b.ordr_prrn_ymd
                               and a.inpc_cd in ('AM','RR','MA1')
                               AND (-- AM, RR의 경우는 응답한 것만 저장되었으므로, 모두 범위에 포함
                                      (a.inpc_cd = 'AM'  and a.item_sno between 1   and 500 and a.item_sno != 127)
                                   OR (a.inpc_cd = 'RR'  and a.item_sno between 1   and 300)
                                   OR (a.inpc_cd = 'MA1' and a.item_sno between 64  and 227 and a.item_sno not in (86,93,100,127,139,156,163,170,177,184,191,198,205,212,219,226)) -- MA1 문진의 '수술/시술여부: 아니오'는 고려대상에서 제외.
                                   )
                               and b.ptno not in (
                                                  &not_in_ptno
                                                 )
                               and b.rprs_apnt_no = a.rprs_apnt_no
                             group by a.PTNO
                                 , a.ordr_prrn_ymd
                                 , a.inpc_cd
                           ) a
                         , 스키마.3E3C23302E333E0E28@SMISR_스키마 f
                         , 스키마.0E5B5B285B28402857@SMISR_스키마 b
                     where f.ptno = a.ptno
                       and f.ordr_prrn_ymd = a.ordr_prrn_ymd
                       and f.inpc_cd = a.inpc_cd
                       AND (-- AM, RR의 경우는 응답한 것만 저장되었으므로, 모두 범위에 포함
                              (f.inpc_cd = 'AM'  and f.item_sno between 1   and 500 and f.item_sno != 127)
                           OR (f.inpc_cd = 'RR'  and f.item_sno between 1   and 300)
                           OR (f.inpc_cd = 'MA1' and f.item_sno between 64  and 227 and f.item_sno not in (86,93,100,127,139,156,163,170,177,184,191,198,205,212,219,226)) -- MA1 문진의 '수술/시술여부: 아니오'는 고려대상에서 제외.
                           )
                       and a.ptno = b.ptno
                     group by f.rprs_apnt_no
                         , a.PTNO
                         , a.ordr_prrn_ymd
                         , f.inpc_cd
                         , a.history_comorbidity
                         , b.gend_cd
                   ) h
                       
           )
                
            loop
            begin   -- 데이터 update
                          update /*+ append */
                                 스키마.1543294D47144D302E333E0E28 a
                             set 
                                 a.HISTORY_COMORBIDITY              = drh."1"  
                               , a.HISTORY_TUBERCULOSIS             = drh."2"  
                               , a.TRT_TUBERCULOSIS                 = drh."3"  
                               , a.STATUS_TUBERCULOSIS              = drh."4"  
                               , a.TRT_TUBERCULOSIS_OP              = drh."5"  
                               , a.TUBERCULOSIS_AGE_DIAG            = drh."6"  
                               , a.HISTORY_HYPERTENSION             = drh."7"  
                               , a.TRT_HYPERTENSION                 = drh."8"  
                               , a.STATUS_HYPERTENSION              = drh."9"  
                               , a.HYPERTENSION_AGE_DIAG            = drh."10" 
                               , a.HISTORY_HYPERLIPIDEMIA           = drh."11" 
                               , a.TRT_HYPERLIPIDEMIA               = drh."12" 
                               , a.STATUS_HYPERLIPIDEMIA            = drh."13" 
                               , a.HYPERLIPIDEMIA_AGE_DIAG          = drh."14" 
                               , a.HISTORY_STROKE                   = drh."15" 
                               , a.TRT_STROKE                       = drh."16" 
                               , a.STATUS_STROKE                    = drh."17" 
                               , a.TRT_STROKE_OP                    = drh."18" 
                               , a.STROKE_AGE_DIAG                  = drh."19" 
                               , a.HISTORY_DIABETES                 = drh."20" 
                               , a.TRT_DIABETES                     = drh."21" 
                               , a.STATUS_DIABETES                  = drh."22" 
                               , a.DIABETES_AGE_DIAG                = drh."23" 
                               , a.HISTORY_GA_DUODENAL_ULCER        = drh."24" 
                               , a.TRT_GA_DUODENAL_ULCER            = drh."25" 
                               , a.STATUS_GA_DUODENAL_ULCER         = drh."26" 
                               , a.TRT_GA_DUODENAL_ULCER_OP         = drh."27" 
                               , a.GA_DUODENAL_ULCER_AGE_DIAG       = drh."28" 
                               , a.HISTORY_COLON_POLYP              = drh."29" 
                               , a.TRT_COLON_POLYP                  = drh."30" 
                               , a.STATUS_COLON_POLYP               = drh."31" 
                               , a.TRT_COLON_POLYP_OP               = drh."32" 
                               , a.COLON_POLYP_AGE_DIAG             = drh."33" 
                               , a.HISTORY_FATTY_LIVER              = drh."34" 
                               , a.TRT_FATTY_LIVER                  = drh."35" 
                               , a.STATUS_FATTY_LIVER               = drh."36" 
                               , a.FATTY_LIVER_AGE_DIAG             = drh."37" 
                               , a.HISTORY_THYROID_NODULES          = drh."38" 
                               , a.TRT_THYROID_NODULES              = drh."39" 
                               , a.STATUS_THYROID_NODULES           = drh."40" 
                               , a.TRT_THYROID_NODULES_OP           = drh."41" 
                               , a.THYROID_NODULES_AGE_DIAG         = drh."42" 
                               , a.HISTORY_BBT                      = drh."43" 
                               , a.TRT_BBT                          = drh."44" 
                               , a.STATUS_BBT                       = drh."45" 
                               , a.TRT_BBT_OP                       = drh."46" 
                               , a.BBT_AGE_DIAG                     = drh."47" 
                               , a.TRT_BBT_BIOPSY                   = drh."48" 
                               , a.HISTORY_DISC                     = drh."49" 
                               , a.TRT_DISC                         = drh."50" 
                               , a.STATUS_DISC                      = drh."51" 
                               , a.TRT_DISC_OP                      = drh."52" 
                               , a.DISC_AGE_DIAG                    = drh."53" 
                               , a.HISTORY_GASTRITIS                = drh."54" 
                               , a.TRT_GASTRITIS                    = drh."55" 
                               , a.GASTRITIS_AGE_DIAG               = drh."56" 
                               , a.HISTORY_ENTERITIS                = drh."57" 
                               , a.TRT_ENTERITIS                    = drh."58" 
                               , a.ENTERITIS_AGE_DIAG               = drh."59" 
                               , a.HISTORY_HEMORRHOID               = drh."60" 
                               , a.TRT_HEMORRHOID                   = drh."61" 
                               , a.HEMORRHOID_AGE_DIAG              = drh."62" 
                               , a.HISTORY_ACUTE_HEP                = drh."63" 
                               , a.TRT_ACUTE_HEP                    = drh."64" 
                               , a.ACUTE_HEP_AGE_DIAG               = drh."65" 
                               , a.HISTORY_HEP_CIRRHOSIS            = drh."66" 
                               , a.TRT_HEP_CIRRHOSIS                = drh."67" 
                               , a.HEP_CIRRHOSIS_AGE_DIAG           = drh."68" 
                               , a.HISTORY_GALLBLADDER_DIS          = drh."69" 
                               , a.TRT_GALLBLADDER_DIS              = drh."70" 
                               , a.GALLBLADDER_DIS_AGE_DIAG         = drh."71" 
                               , a.HISTORY_MYOMA_UTERI              = drh."72" 
                               , a.TRT_MYOMA_UTERI_OP               = drh."73" 
                               , a.MYOMA_UTERI_AGE_DIAG             = drh."74" 
                               , a.HISTORY_CERVICITIS               = drh."75" 
                               , a.TRT_CERVICITIS_OP                = drh."76" 
                               , a.CERVICITIS_AGE_DIAG              = drh."77" 
                               , a.HISTORY_TRAUMA                   = drh."78" 
                               , a.TRT_TRAUMA                       = drh."79" 
                               , a.TRAUMA_AGE_DIAG                  = drh."80" 
                               , a.HISTORY_HBV                      = drh."81" 
                               , a.TRT_HBV                          = drh."82" 
                               , a.STATUS_HBV                       = drh."83" 
                               , a.HBV_AGE_DIAG                     = drh."84" 
                               , a.HISTORY_HCV                      = drh."85" 
                               , a.TRT_HCV                          = drh."86" 
                               , a.STATUS_HCV                       = drh."87" 
                               , a.HCV_AGE_DIAG                     = drh."88" 
                               , a.HISTORY_CIRRHOSIS                = drh."89" 
                               , a.TRT_CIRRHOSIS                    = drh."90" 
                               , a.STATUS_CIRRHOSIS                 = drh."91" 
                               , a.CIRRHOSIS_AGE_DIAG               = drh."92" 
                               , a.HISTORY_HELICO_PYLORI            = drh."93" 
                               , a.TRT_HELICO_PYLORI                = drh."94" 
                               , a.STATUS_HELICO_PYLORI             = drh."95" 
                               , a.HELICO_PYLORI_AGE_DIAG           = drh."96" 
                               , a.HISTORY_COPD                     = drh."97" 
                               , a.TRT_HISTORY_COPD                 = drh."98" 
                               , a.STATUS_HISTORY_COPD              = drh."99" 
                               , a.COPD_AGE_DIAG                    = drh."100"
                               , a.HISTORY_ARTHRITIS                = drh."101"
                               , a.TRT_ARTHRITIS                    = drh."102"
                               , a.STATUS_ARTHRITIS                 = drh."103"
                               , a.TRT_ARTHRITIS_OP                 = drh."104"
                               , a.ARTHRITIS_AGE_DIAG               = drh."105"
                               , a.HISTORY_CATARACT                 = drh."106"
                               , a.TRT_CATARACT                     = drh."107"
                               , a.STATUS_CATARACT                  = drh."108"
                               , a.TRT_CATARACT_OP                  = drh."109"
                               , a.CATARACT_AGE_DIAG                = drh."110"
                               , a.HISTORY_GLAUCOMA                 = drh."111"
                               , a.TRT_GLAUCOMA                     = drh."112"
                               , a.STATUS_GLAUCOMA                  = drh."113"
                               , a.TRT_GLAUCOMA_OP                  = drh."114"
                               , a.GLAUCOMA_AGE_DIAG                = drh."115"
                               , a.HISTORY_ASTHMA_ALLERGY           = drh."116"
                               , a.TRT_ASTHMA_ALLERGY               = drh."117"
                               , a.ASTHMA_ALLERGY_AGE_DIAG          = drh."118"
                               , a.HISTORY_ASTHMA                   = drh."119"
                               , a.TRT_ASTHMA                       = drh."120"
                               , a.STATUS_ASTHMA                    = drh."121"
                               , a.ASTHMA_AGE_DIAG                  = drh."122"
                               , a.HISTORY_CORONARY_DIS             = drh."123"
                               , a.TRT_CORONARY_DIS                 = drh."124"
                               , a.CORONARY_DIS_AGE_DIAG            = drh."125"
                               , a.HISTORY_ANGINA                   = drh."126"
                               , a.TRT_ANGINA                       = drh."127"
                               , a.STATUS_ANGINA                    = drh."128"
                               , a.TRT_ANGINA_OP                    = drh."129"
                               , a.ANGINA_AGE_DIAG                  = drh."130"
                               , a.HISTORY_MI                       = drh."131"
                               , a.TRT_MI                           = drh."132"
                               , a.STATUS_MI                        = drh."133"
                               , a.TRT_MI_OP                        = drh."134"
                               , a.MI_AGE_DIAG                      = drh."135"
                               , a.HISTORY_KIDNEY_URINARY_DIS       = drh."136"
                               , a.TRT_KIDNEY_URINARY_DIS           = drh."137"
                               , a.STATUS_KIDNEY_URINARY_DIS        = drh."138"
                               , a.TRT_KIDNEY_URINARY_DIS_OP        = drh."139"
                               , a.KIDNEY_URINARY_DIS_AGE_DIAG      = drh."140"
                               , a.HISTORY_KIDNEY_DIS               = drh."141"
                               , a.TRT_KIDNEY_DIS                   = drh."142"
                               , a.KIDNEY_DIS_AGE_DIAG              = drh."143"
                               , a.HISTORY_URINARY_TRACT_DIS        = drh."144"
                               , a.TRT_URINARY_TRACT_DIS            = drh."145"
                               , a.URINARY_TRACT_DIS_AGE_DIAG       = drh."146"
                               , a.HISTORY_THYROID_DIS1             = drh."147"
                               , a.TRT_THYROID_DIS1                 = drh."148"
                               , a.THYROID_DIS1_AGE_DIAG            = drh."149"
                               , a.HISTORY_BPH                      = drh."150"
                               , a.TRT_BPH                          = drh."151"
                               , a.STATUS_BPH                       = drh."152"
                               , a.TRT_BPH_OP                       = drh."153"
                               , a.BPH_AGE_DIAG                     = drh."154"
                               , a.HISTORY_THYROID_DIS2             = drh."155"
                               , a.TRT_THYROID_DIS2                 = drh."156"
                               , a.STATUS_THYROID_DIS2              = drh."157"
                               , a.TRT_THYROID_DIS2_OP              = drh."158"
                               , a.THYROID_DIS2_AGE_DIAG            = drh."159"
                               , a.HISTORY_OTHER                    = drh."160"
                               , a.TRT_OTHER                        = drh."161"
                               , a.STATUS_OTHER                     = drh."162"
                               , a.TRT_OTHER_OP                     = drh."163"
                               , a.OTHER_AGE_DIAG                   = drh."164"
                               , a.last_updt_dt                     = drh.last_updt_dt
                           where a.ptno = drh.ptno
                             and a.ordr_prrn_ymd = drh.ordr_prrn_ymd
                             and a.rprs_apnt_no = drh.rprs_apnt_no
                                 ;
                  
                         commit;
                       
                       upcnt := upcnt + 1;
                  
                       exception
                       when others then
                          rollback;
                          errcnt := errcnt + 1;
            
            end;
            end loop;
       
:var_msg2  := 'update '  || to_char(upcnt)    || ' 건';
:var_msg3  := 'error '   || to_char(errcnt)   || ' 건';
   
end ;
/
print var_msg2
print var_msg3
spool off;
     
-- 문진 정보 update, 암병력                                                                   
-- 변수 길이가 길다는 에러메세지 때문에 변수를 숫자정보로 치환                        
-- 메시지 출력기능 추가. 메시지 확인은 F5를 눌러야 가능함                             
variable var_msg2 char(40);                                                           
variable var_msg3 char(40);                                                           
                                                                                      
declare                                                                               
    upcnt     number(10) := 0;                                                        
    errcnt    number(10) := 0;                                                        
                                                                                      
begin                                                                                 
for drh in (-- 데이터 select
            select h.RPRS_APNT_NO                   as RPRS_APNT_NO
                 , h.PTNO                           as ptno
                 , h.ORDR_PRRN_YMD                  as ordr_prrn_ymd
                 , sysdate                          as last_updt_dt
                 , h.HISTORY_CANCER                      as "1" 
                 , h.HISTORY_CANCER_STOMACH              as "2" 
                 , h.CANCER_STOMACH_AGE_DIAG             as "3" 
                 , h.TRT_CANCER_STOMACH                  as "4" 
                 , h.TRT_CANCER_STOMACH_OP               as "5" 
                 , h.TRT_CANCER_STOMACH_CH               as "6" 
                 , h.TRT_CANCER_STOMACH_RA               as "7" 
                 , h.TRT_CANCER_STOMACH_OT               as "8" 
                 , h.HISTORY_CANCER_LUNG                 as "9" 
                 , h.CANCER_LUNG_AGE_DIAG                as "10"
                 , h.TRT_CANCER_LUNG                     as "11"
                 , h.TRT_CANCER_LUNG_OP                  as "12"
                 , h.TRT_CANCER_LUNG_CH                  as "13"
                 , h.TRT_CANCER_LUNG_RA                  as "14"
                 , h.TRT_CANCER_LUNG_OT                  as "15"
                 , h.HISTORY_CANCER_LIVER                as "16"
                 , h.CANCER_LIVER_AGE_DIAG               as "17"
                 , h.TRT_CANCER_LIVER                    as "18"
                 , h.TRT_CANCER_LIVER_OP                 as "19"
                 , h.TRT_CANCER_LIVER_CH                 as "20"
                 , h.TRT_CANCER_LIVER_RA                 as "21"
                 , h.TRT_CANCER_LIVER_OT                 as "22"
                 , h.HISTORY_CANCER_COLORECTAL           as "23"
                 , h.CANCER_COLORECTAL_AGE_DIAG          as "24"
                 , h.TRT_CANCER_COLORECTAL               as "25"
                 , h.TRT_CANCER_COLORECTAL_OP            as "26"
                 , h.TRT_CANCER_COLORECTAL_CH            as "27"
                 , h.TRT_CANCER_COLORECTAL_RA            as "28"
                 , h.TRT_CANCER_COLORECTAL_OT            as "29"
                 , h.HISTORY_CANCER_BREAST               as "30"
                 , h.CANCER_BREAST_AGE_DIAG              as "31"
                 , h.TRT_CANCER_BREAST                   as "32"
                 , h.TRT_CANCER_BREAST_OP                as "33"
                 , h.TRT_CANCER_BREAST_CH                as "34"
                 , h.TRT_CANCER_BREAST_RA                as "35"
                 , h.TRT_CANCER_BREAST_OT                as "36"
                 , h.HISTORY_CANCER_CERVIX               as "37"
                 , h.CANCER_CERVIX_AGE_DIAG              as "38"
                 , h.TRT_CANCER_CERVIX                   as "39"
                 , h.TRT_CANCER_CERVIX_OP                as "40"
                 , h.TRT_CANCER_CERVIX_CH                as "41"
                 , h.TRT_CANCER_CERVIX_RA                as "42"
                 , h.TRT_CANCER_CERVIX_OT                as "43"
                 , h.HISTORY_CANCER_THYROID              as "44"
                 , h.CANCER_THYROID_AGE_DIAG             as "45"
                 , h.TRT_CANCER_THYROID                  as "46"
                 , h.TRT_CANCER_THYROID_OP               as "47"
                 , h.TRT_CANCER_THYROID_CH               as "48"
                 , h.TRT_CANCER_THYROID_RA               as "49"
                 , h.TRT_CANCER_THYROID_OT               as "50"
                 , h.HISTORY_CANCER_BLADDER              as "51"
                 , h.CANCER_BLADDER_AGE_DIAG             as "52"
                 , h.TRT_CANCER_BLADDER                  as "53"
                 , h.TRT_CANCER_BLADDER_OP               as "54"
                 , h.TRT_CANCER_BLADDER_CH               as "55"
                 , h.TRT_CANCER_BLADDER_RA               as "56"
                 , h.TRT_CANCER_BLADDER_OT               as "57"
                 , h.HISTORY_CANCER_ESOPHAGUS            as "58"
                 , h.CANCER_ESOPHAGUS_AGE_DIAG           as "59"
                 , h.TRT_CANCER_ESOPHAGUS                as "60"
                 , h.TRT_CANCER_ESOPHAGUS_OP             as "61"
                 , h.TRT_CANCER_ESOPHAGUS_CH             as "62"
                 , h.TRT_CANCER_ESOPHAGUS_RA             as "63"
                 , h.TRT_CANCER_ESOPHAGUS_OT             as "64"
                 , h.HISTORY_CANCER_GB_BILIARY           as "65"
                 , h.CANCER_GB_BILIARY_AGE_DIAG          as "66"
                 , h.TRT_CANCER_GB_BILIARY               as "67"
                 , h.TRT_CANCER_GB_BILIARY_OP            as "68"
                 , h.TRT_CANCER_GB_BILIARY_CH            as "69"
                 , h.TRT_CANCER_GB_BILIARY_RA            as "70"
                 , h.TRT_CANCER_GB_BILIARY_OT            as "71"
                 , h.HISTORY_CANCER_OVARY                as "72"
                 , h.CANCER_OVARY_AGE_DIAG               as "73"
                 , h.TRT_CANCER_OVARY                    as "74"
                 , h.TRT_CANCER_OVARY_OP                 as "75"
                 , h.TRT_CANCER_OVARY_CH                 as "76"
                 , h.TRT_CANCER_OVARY_RA                 as "77"
                 , h.TRT_CANCER_OVARY_OT                 as "78"
                 , h.HISTORY_CANCER_PROSTATE             as "79"
                 , h.CANCER_PROSTATE_AGE_DIAG            as "80"
                 , h.TRT_CANCER_PROSTATE                 as "81"
                 , h.TRT_CANCER_PROSTATE_OP              as "82"
                 , h.TRT_CANCER_PROSTATE_CH              as "83"
                 , h.TRT_CANCER_PROSTATE_RA              as "84"
                 , h.TRT_CANCER_PROSTATE_OT              as "85"
                 , h.HISTORY_CANCER_PANCREAS             as "86"
                 , h.CANCER_PANCREAS_AGE_DIAG            as "87"
                 , h.TRT_CANCER_PANCREAS                 as "88"
                 , h.TRT_CANCER_PANCREAS_OP              as "89"
                 , h.TRT_CANCER_PANCREAS_CH              as "90"
                 , h.TRT_CANCER_PANCREAS_RA              as "91"
                 , h.TRT_CANCER_PANCREAS_OT              as "92"
                 , h.HISTORY_CANCER_OTHER                as "93"
                 , h.CANCER_OTHER_AGE_DIAG               as "94"
                 , h.TRT_CANCER_OTHER                    as "95"
                 , h.TRT_CANCER_OTHER_OP                 as "96"
                 , h.TRT_CANCER_OTHER_CH                 as "97"
                 , h.TRT_CANCER_OTHER_RA                 as "98"
                 , h.TRT_CANCER_OTHER_OT                 as "99"
              from (-- 암병력
                    select /*+ index(f 3E3C23302E333E0E28_pk) */
                           f.rprs_apnt_no
                         , a.PTNO
                         , a.ordr_prrn_ymd
                         , f.inpc_cd
                         , b.gend_cd
                         , a.history_cancer
                    /* 위암 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.history_cancer     ,'0','0'
                                                                              ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1299Y','1'
                                                                                                       ,'MA1300Y','1'
                                                                                                       ,'MA1301Y','1'
                                                                                                       ,'MA1302Y','1'
                                                                                                       ,'MA1303' ,DECODE(f.inqy_rspn_ctn1,'','','1'),'0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) history_cancer_stomach
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1303' ,f.inqy_rspn_ctn1,''))
                                 ,''
                                 ) cancer_stomach_age_diag
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1299Y','1'
                                                                                                       ,'MA1300Y','1'
                                                                                                       ,'MA1301Y','1'
                                                                                                       ,'MA1302Y','1'
                                                                                                       ,'MA1303' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))
                                           ,''
                                           ) trt_cancer_stomach
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1299Y','1'     -- 수술
                                                                                                       ,'MA1300Y','0'     -- 약물치료
                                                                                                       ,'MA1301Y','0'     -- 방사선치료
                                                                                                       ,'MA1302Y','0'
                                                                                                       ,'MA1303' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_stomach_op
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1299Y','0'     -- 수술
                                                                                                       ,'MA1300Y','1'     -- 약물치료
                                                                                                       ,'MA1301Y','0'     -- 방사선치료
                                                                                                       ,'MA1302Y','0'
                                                                                                       ,'MA1303' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_stomach_ch
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1299Y','0'     -- 수술
                                                                                                       ,'MA1300Y','0'     -- 약물치료
                                                                                                       ,'MA1301Y','1'     -- 방사선치료
                                                                                                       ,'MA1302Y','0'
                                                                                                       ,'MA1303' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_stomach_ra
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1299Y','0'     -- 수술
                                                                                                       ,'MA1300Y','0'     -- 약물치료
                                                                                                       ,'MA1301Y','0'     -- 방사선치료
                                                                                                       ,'MA1302Y','1'
                                                                                                       ,'MA1303' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_stomach_ot
                    /* 폐암 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.history_cancer     ,'0','0'
                                                                              ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1305Y','1'
                                                                                                       ,'MA1306Y','1'
                                                                                                       ,'MA1307Y','1'
                                                                                                       ,'MA1308Y','1'
                                                                                                       ,'MA1309' ,DECODE(f.inqy_rspn_ctn1,'','','1'),'0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) history_cancer_lung
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1309' ,f.inqy_rspn_ctn1,''))
                                 ,''
                                 ) cancer_lung_age_diag
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1305Y','1'
                                                                                                       ,'MA1306Y','1'
                                                                                                       ,'MA1307Y','1'
                                                                                                       ,'MA1308Y','1'
                                                                                                       ,'MA1309' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))
                                           ,''
                                           ) trt_cancer_lung
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1305Y','1'     -- 수술
                                                                                                       ,'MA1306Y','0'     -- 약물치료
                                                                                                       ,'MA1307Y','0'     -- 방사선치료
                                                                                                       ,'MA1308Y','0'
                                                                                                       ,'MA1309' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_lung_op
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1305Y','0'     -- 수술
                                                                                                       ,'MA1306Y','1'     -- 약물치료
                                                                                                       ,'MA1307Y','0'     -- 방사선치료
                                                                                                       ,'MA1308Y','0'
                                                                                                       ,'MA1309' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_lung_ch
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1305Y','0'     -- 수술
                                                                                                       ,'MA1306Y','0'     -- 약물치료
                                                                                                       ,'MA1307Y','1'     -- 방사선치료
                                                                                                       ,'MA1308Y','0'
                                                                                                       ,'MA1309' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_lung_ra
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1305Y','0'     -- 수술
                                                                                                       ,'MA1306Y','0'     -- 약물치료
                                                                                                       ,'MA1307Y','0'     -- 방사선치료
                                                                                                       ,'MA1308Y','1'     -- 기타
                                                                                                       ,'MA1309' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_lung_ot
                    /* 간암 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.history_cancer     ,'0','0'
                                                                              ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1311Y','1'
                                                                                                       ,'MA1312Y','1'
                                                                                                       ,'MA1313Y','1'
                                                                                                       ,'MA1314Y','1'
                                                                                                       ,'MA1315' ,DECODE(f.inqy_rspn_ctn1,'','','1'),'0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) history_cancer_liver
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1315' ,f.inqy_rspn_ctn1,''))
                                 ,''
                                 ) cancer_liver_age_diag
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1311Y','1'
                                                                                                       ,'MA1312Y','1'
                                                                                                       ,'MA1313Y','1'
                                                                                                       ,'MA1314Y','1'     -- 기타
                                                                                                       ,'MA1315' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))
                                           ,''
                                           ) trt_cancer_liver
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1311Y','1'     -- 수술
                                                                                                       ,'MA1312Y','0'     -- 약물치료
                                                                                                       ,'MA1313Y','0'     -- 방사선치료
                                                                                                       ,'MA1314Y','0'     -- 기타
                                                                                                       ,'MA1315' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_liver_op
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1311Y','0'     -- 수술
                                                                                                       ,'MA1312Y','1'     -- 약물치료
                                                                                                       ,'MA1313Y','0'     -- 방사선치료
                                                                                                       ,'MA1314Y','0'     -- 기타
                                                                                                       ,'MA1315' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_liver_ch
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1311Y','0'     -- 수술
                                                                                                       ,'MA1312Y','0'     -- 약물치료
                                                                                                       ,'MA1313Y','1'     -- 방사선치료
                                                                                                       ,'MA1314Y','0'     -- 기타
                                                                                                       ,'MA1315' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_liver_ra
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1311Y','0'     -- 수술
                                                                                                       ,'MA1312Y','0'     -- 약물치료
                                                                                                       ,'MA1313Y','0'     -- 방사선치료
                                                                                                       ,'MA1314Y','1'     -- 기타
                                                                                                       ,'MA1315' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_liver_ot
                    /* 대장암 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.history_cancer     ,'0','0'
                                                                              ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1317Y','1'
                                                                                                       ,'MA1318Y','1'
                                                                                                       ,'MA1319Y','1'
                                                                                                       ,'MA1320Y','1'
                                                                                                       ,'MA1321' ,DECODE(f.inqy_rspn_ctn1,'','','1'),'0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) history_cancer_colorectal
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1321' ,f.inqy_rspn_ctn1,''))
                                 ,''
                                 ) cancer_colorectal_age_diag
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1317Y','1'
                                                                                                       ,'MA1318Y','1'
                                                                                                       ,'MA1319Y','1'
                                                                                                       ,'MA1320Y','1'     -- 기타
                                                                                                       ,'MA1321' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))
                                           ,''
                                           ) trt_cancer_colorectal
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1317Y','1'     -- 수술
                                                                                                       ,'MA1318Y','0'     -- 약물치료
                                                                                                       ,'MA1319Y','0'     -- 방사선치료
                                                                                                       ,'MA1320Y','0'     -- 기타
                                                                                                       ,'MA1321' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_colorectal_op
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1317Y','0'     -- 수술
                                                                                                       ,'MA1318Y','1'     -- 약물치료
                                                                                                       ,'MA1319Y','0'     -- 방사선치료
                                                                                                       ,'MA1320Y','0'     -- 기타
                                                                                                       ,'MA1321' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_colorectal_ch
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1317Y','0'     -- 수술
                                                                                                       ,'MA1318Y','0'     -- 약물치료
                                                                                                       ,'MA1319Y','1'     -- 방사선치료
                                                                                                       ,'MA1320Y','0'     -- 기타
                                                                                                       ,'MA1321' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_colorectal_ra
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1317Y','0'     -- 수술
                                                                                                       ,'MA1318Y','0'     -- 약물치료
                                                                                                       ,'MA1319Y','0'     -- 방사선치료
                                                                                                       ,'MA1320Y','1'     -- 기타
                                                                                                       ,'MA1321' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_colorectal_ot
                    /* 유방암 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.history_cancer     ,'0','0'
                                                                              ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1323Y','1'
                                                                                                       ,'MA1324Y','1'
                                                                                                       ,'MA1325Y','1'
                                                                                                       ,'MA1326Y','1'
                                                                                                       ,'MA1327' ,DECODE(f.inqy_rspn_ctn1,'','','1'),'0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) history_cancer_breast
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1327' ,f.inqy_rspn_ctn1,''))
                                 ,''
                                 ) cancer_breast_age_diag
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1323Y','1'
                                                                                                       ,'MA1324Y','1'
                                                                                                       ,'MA1325Y','1'
                                                                                                       ,'MA1326Y','1'     -- 기타
                                                                                                       ,'MA1327' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))
                                           ,''
                                           ) trt_cancer_breast
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1323Y','1'     -- 수술
                                                                                                       ,'MA1324Y','0'     -- 약물치료
                                                                                                       ,'MA1325Y','0'     -- 방사선치료
                                                                                                       ,'MA1326Y','0'     -- 기타
                                                                                                       ,'MA1327' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_breast_op
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1323Y','0'     -- 수술
                                                                                                       ,'MA1324Y','1'     -- 약물치료
                                                                                                       ,'MA1325Y','0'     -- 방사선치료
                                                                                                       ,'MA1326Y','0'     -- 기타
                                                                                                       ,'MA1327' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_breast_ch
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1323Y','0'     -- 수술
                                                                                                       ,'MA1324Y','0'     -- 약물치료
                                                                                                       ,'MA1325Y','1'     -- 방사선치료
                                                                                                       ,'MA1326Y','0'     -- 기타
                                                                                                       ,'MA1327' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_breast_ra
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1323Y','0'     -- 수술
                                                                                                       ,'MA1324Y','0'     -- 약물치료
                                                                                                       ,'MA1325Y','0'     -- 방사선치료
                                                                                                       ,'MA1326Y','1'     -- 기타
                                                                                                       ,'MA1327' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_breast_ot
                    /* 자궁경부암 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.history_cancer,'0','0'
                                                                         ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1329Y','1'
                                                                                                       ,'MA1330Y','1'
                                                                                                       ,'MA1331Y','1'
                                                                                                       ,'MA1332Y','1'
                                                                                                       ,'MA1333' ,DECODE(f.inqy_rspn_ctn1,'','','1'),'0'))
                                                        ,''
                                                        )     
                                           ,''
                                 ) history_cancer_cervix
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1333' ,f.inqy_rspn_ctn1,''))
                                 ,''
                                 ) cancer_cervix_age_diag
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1329Y','1'
                                                                                                       ,'MA1330Y','1'
                                                                                                       ,'MA1331Y','1'
                                                                                                       ,'MA1332Y','1'     -- 기타
                                                                                                       ,'MA1333' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))
                                           ,''
                                           ) trt_cancer_cervix
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1329Y','1'     -- 수술
                                                                                                       ,'MA1330Y','0'     -- 약물치료
                                                                                                       ,'MA1331Y','0'     -- 방사선치료
                                                                                                       ,'MA1332Y','0'     -- 기타
                                                                                                       ,'MA1333' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_cervix_op
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1329Y','0'     -- 수술
                                                                                                       ,'MA1330Y','1'     -- 약물치료
                                                                                                       ,'MA1331Y','0'     -- 방사선치료
                                                                                                       ,'MA1332Y','0'     -- 기타
                                                                                                       ,'MA1333' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_cervix_ch
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1329Y','0'     -- 수술
                                                                                                       ,'MA1330Y','0'     -- 약물치료
                                                                                                       ,'MA1331Y','1'     -- 방사선치료
                                                                                                       ,'MA1332Y','0'     -- 기타
                                                                                                       ,'MA1333' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_cervix_ra
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1329Y','0'     -- 수술
                                                                                                       ,'MA1330Y','0'     -- 약물치료
                                                                                                       ,'MA1331Y','0'     -- 방사선치료
                                                                                                       ,'MA1332Y','1'     -- 기타
                                                                                                       ,'MA1333' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_cervix_ot
                    /* 갑상선암 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.history_cancer     ,'0','0'
                                                                              ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1335Y','1'
                                                                                                       ,'MA1336Y','1'
                                                                                                       ,'MA1337Y','1'
                                                                                                       ,'MA1338Y','1'
                                                                                                       ,'MA1339' ,DECODE(f.inqy_rspn_ctn1,'','','1'),'0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) history_cancer_thyroid
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1339' ,f.inqy_rspn_ctn1,''))
                                 ,''
                                 ) cancer_thyroid_age_diag
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1335Y','1'
                                                                                                       ,'MA1336Y','1'
                                                                                                       ,'MA1337Y','1'
                                                                                                       ,'MA1338Y','1'     -- 기타
                                                                                                       ,'MA1339' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))
                                           ,''
                                           ) trt_cancer_thyroid
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1335Y','1'     -- 수술
                                                                                                       ,'MA1336Y','0'     -- 약물치료
                                                                                                       ,'MA1337Y','0'     -- 방사선치료
                                                                                                       ,'MA1338Y','0'     -- 기타
                                                                                                       ,'MA1339' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_thyroid_op
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1335Y','0'     -- 수술
                                                                                                       ,'MA1336Y','1'     -- 약물치료
                                                                                                       ,'MA1337Y','0'     -- 방사선치료
                                                                                                       ,'MA1338Y','0'     -- 기타
                                                                                                       ,'MA1339' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_thyroid_ch
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1335Y','0'     -- 수술
                                                                                                       ,'MA1336Y','0'     -- 약물치료
                                                                                                       ,'MA1337Y','1'     -- 방사선치료
                                                                                                       ,'MA1338Y','0'     -- 기타
                                                                                                       ,'MA1339' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_thyroid_ra
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1335Y','0'     -- 수술
                                                                                                       ,'MA1336Y','0'     -- 약물치료
                                                                                                       ,'MA1337Y','0'     -- 방사선치료
                                                                                                       ,'MA1338Y','1'     -- 기타
                                                                                                       ,'MA1339' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_thyroid_ot
                    /* 방광암 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.history_cancer     ,'0','0'
                                                                              ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1341Y','1'
                                                                                                       ,'MA1342Y','1'
                                                                                                       ,'MA1343Y','1'
                                                                                                       ,'MA1344Y','1'
                                                                                                       ,'MA1345' ,DECODE(f.inqy_rspn_ctn1,'','','1'),'0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) history_cancer_bladder
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1345' ,f.inqy_rspn_ctn1,''))
                                 ,''
                                 ) cancer_bladder_age_diag
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1341Y','1'
                                                                                                       ,'MA1342Y','1'
                                                                                                       ,'MA1343Y','1'
                                                                                                       ,'MA1344Y','1'     -- 기타
                                                                                                       ,'MA1345' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))
                                           ,''
                                           ) trt_cancer_bladder
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1341Y','1'     -- 수술
                                                                                                       ,'MA1342Y','0'     -- 약물치료
                                                                                                       ,'MA1343Y','0'     -- 방사선치료
                                                                                                       ,'MA1344Y','0'     -- 기타
                                                                                                       ,'MA1345' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_bladder_op
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1341Y','0'     -- 수술
                                                                                                       ,'MA1342Y','1'     -- 약물치료
                                                                                                       ,'MA1343Y','0'     -- 방사선치료
                                                                                                       ,'MA1344Y','0'     -- 기타
                                                                                                       ,'MA1345' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_bladder_ch
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1341Y','0'     -- 수술
                                                                                                       ,'MA1342Y','0'     -- 약물치료
                                                                                                       ,'MA1343Y','1'     -- 방사선치료
                                                                                                       ,'MA1344Y','0'     -- 기타
                                                                                                       ,'MA1345' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_bladder_ra
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1341Y','0'     -- 수술
                                                                                                       ,'MA1342Y','0'     -- 약물치료
                                                                                                       ,'MA1343Y','0'     -- 방사선치료
                                                                                                       ,'MA1344Y','1'     -- 기타
                                                                                                       ,'MA1345' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_bladder_ot
                    /* 식도암 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.history_cancer     ,'0','0'
                                                                              ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1347Y','1'
                                                                                                       ,'MA1348Y','1'
                                                                                                       ,'MA1349Y','1'
                                                                                                       ,'MA1350Y','1'
                                                                                                       ,'MA1351' ,DECODE(f.inqy_rspn_ctn1,'','','1'),'0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) history_cancer_esophagus
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1351' ,f.inqy_rspn_ctn1,''))
                                 ,''
                                 ) cancer_esophagus_age_diag
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1347Y','1'
                                                                                                       ,'MA1348Y','1'
                                                                                                       ,'MA1349Y','1'
                                                                                                       ,'MA1350Y','1'     -- 기타
                                                                                                       ,'MA1351' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))
                                           ,''
                                           ) trt_cancer_esophagus
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1347Y','1'     -- 수술
                                                                                                       ,'MA1348Y','0'     -- 약물치료
                                                                                                       ,'MA1349Y','0'     -- 방사선치료
                                                                                                       ,'MA1350Y','0'     -- 기타
                                                                                                       ,'MA1351' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_esophagus_op
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1347Y','0'     -- 수술
                                                                                                       ,'MA1348Y','1'     -- 약물치료
                                                                                                       ,'MA1349Y','0'     -- 방사선치료
                                                                                                       ,'MA1350Y','0'     -- 기타
                                                                                                       ,'MA1351' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_esophagus_ch
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1347Y','0'     -- 수술
                                                                                                       ,'MA1348Y','0'     -- 약물치료
                                                                                                       ,'MA1349Y','1'     -- 방사선치료
                                                                                                       ,'MA1350Y','0'     -- 기타
                                                                                                       ,'MA1351' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_esophagus_ra
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1347Y','0'     -- 수술
                                                                                                       ,'MA1348Y','0'     -- 약물치료
                                                                                                       ,'MA1349Y','0'     -- 방사선치료
                                                                                                       ,'MA1350Y','1'     -- 기타
                                                                                                       ,'MA1351' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_esophagus_ot
                    /* 담도암 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.history_cancer     ,'0','0'
                                                                              ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1353Y','1'
                                                                                                       ,'MA1354Y','1'
                                                                                                       ,'MA1355Y','1'
                                                                                                       ,'MA1356Y','1'
                                                                                                       ,'MA1357' ,DECODE(f.inqy_rspn_ctn1,'','','1'),'0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) history_cancer_gb_biliary
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1357' ,f.inqy_rspn_ctn1,''))
                                 ,''
                                 ) cancer_gb_biliary_age_diag
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1353Y','1'
                                                                                                       ,'MA1354Y','1'
                                                                                                       ,'MA1355Y','1'
                                                                                                       ,'MA1356Y','1'     -- 기타
                                                                                                       ,'MA1357' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))
                                           ,''
                                           ) trt_cancer_gb_biliary
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1353Y','1'     -- 수술
                                                                                                       ,'MA1354Y','0'     -- 약물치료
                                                                                                       ,'MA1355Y','0'     -- 방사선치료
                                                                                                       ,'MA1356Y','0'     -- 기타
                                                                                                       ,'MA1357' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_gb_biliary_op
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1353Y','0'     -- 수술
                                                                                                       ,'MA1354Y','1'     -- 약물치료
                                                                                                       ,'MA1355Y','0'     -- 방사선치료
                                                                                                       ,'MA1356Y','0'     -- 기타
                                                                                                       ,'MA1357' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_gb_biliary_ch
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1353Y','0'     -- 수술
                                                                                                       ,'MA1354Y','0'     -- 약물치료
                                                                                                       ,'MA1355Y','1'     -- 방사선치료
                                                                                                       ,'MA1356Y','0'     -- 기타
                                                                                                       ,'MA1357' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_gb_biliary_ra
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1353Y','0'     -- 수술
                                                                                                       ,'MA1354Y','0'     -- 약물치료
                                                                                                       ,'MA1355Y','0'     -- 방사선치료
                                                                                                       ,'MA1356Y','1'     -- 기타
                                                                                                       ,'MA1357' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_gb_biliary_ot
                    /* 난소암 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.history_cancer,'0','0'
                                                                         ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1359Y','1'
                                                                                                       ,'MA1360Y','1'
                                                                                                       ,'MA1361Y','1'
                                                                                                       ,'MA1362Y','1'
                                                                                                       ,'MA1363' ,DECODE(f.inqy_rspn_ctn1,'','','1'),'0'))
                                                        ,''
                                                        )     
                                           ,''
                                 ) history_cancer_ovary
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1363' ,f.inqy_rspn_ctn1,''))
                                 ,''
                                 ) cancer_ovary_age_diag
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1359Y','1'
                                                                                                       ,'MA1360Y','1'
                                                                                                       ,'MA1361Y','1'
                                                                                                       ,'MA1362Y','1'     -- 기타
                                                                                                       ,'MA1363' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))
                                           ,''
                                           ) trt_cancer_ovary
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1359Y','1'     -- 수술
                                                                                                       ,'MA1360Y','0'     -- 약물치료
                                                                                                       ,'MA1361Y','0'     -- 방사선치료
                                                                                                       ,'MA1362Y','0'     -- 기타
                                                                                                       ,'MA1363' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_ovary_op
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1359Y','0'     -- 수술
                                                                                                       ,'MA1360Y','1'     -- 약물치료
                                                                                                       ,'MA1361Y','0'     -- 방사선치료
                                                                                                       ,'MA1362Y','0'     -- 기타
                                                                                                       ,'MA1363' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_ovary_ch
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1359Y','0'     -- 수술
                                                                                                       ,'MA1360Y','0'     -- 약물치료
                                                                                                       ,'MA1361Y','1'     -- 방사선치료
                                                                                                       ,'MA1362Y','0'     -- 기타
                                                                                                       ,'MA1363' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_ovary_ra
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1359Y','0'     -- 수술
                                                                                                       ,'MA1360Y','0'     -- 약물치료
                                                                                                       ,'MA1361Y','0'     -- 방사선치료
                                                                                                       ,'MA1362Y','1'     -- 기타
                                                                                                       ,'MA1363' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_ovary_ot
                    /* 전립선암 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.history_cancer,'0','0'
                                                                         ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1365Y','1'
                                                                                                       ,'MA1366Y','1'
                                                                                                       ,'MA1367Y','1'
                                                                                                       ,'MA1368Y','1'
                                                                                                       ,'MA1369' ,DECODE(f.inqy_rspn_ctn1,'','','1'),'0'))
                                                        ,''
                                                        )     
                                           ,''
                                 ) history_cancer_prostate
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1369' ,f.inqy_rspn_ctn1,''))
                                 ,''
                                 ) cancer_prostate_age_diag
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1365Y','1'
                                                                                                       ,'MA1366Y','1'
                                                                                                       ,'MA1367Y','1'
                                                                                                       ,'MA1368Y','1'     -- 기타
                                                                                                       ,'MA1369' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))
                                           ,''
                                           ) trt_cancer_prostate
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1365Y','1'     -- 수술
                                                                                                       ,'MA1366Y','0'     -- 약물치료
                                                                                                       ,'MA1367Y','0'     -- 방사선치료
                                                                                                       ,'MA1368Y','0'     -- 기타
                                                                                                       ,'MA1369' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_prostate_op
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1365Y','0'     -- 수술
                                                                                                       ,'MA1366Y','1'     -- 약물치료
                                                                                                       ,'MA1367Y','0'     -- 방사선치료
                                                                                                       ,'MA1368Y','0'     -- 기타
                                                                                                       ,'MA1369' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_prostate_ch
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1365Y','0'     -- 수술
                                                                                                       ,'MA1366Y','0'     -- 약물치료
                                                                                                       ,'MA1367Y','1'     -- 방사선치료
                                                                                                       ,'MA1368Y','0'     -- 기타
                                                                                                       ,'MA1369' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_prostate_ra
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1365Y','0'     -- 수술
                                                                                                       ,'MA1366Y','0'     -- 약물치료
                                                                                                       ,'MA1367Y','0'     -- 방사선치료
                                                                                                       ,'MA1368Y','1'     -- 기타
                                                                                                       ,'MA1369' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_prostate_ot
                    /* 췌장암 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.history_cancer,'0','0'
                                                                         ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1371Y','1'
                                                                                                       ,'MA1372Y','1'
                                                                                                       ,'MA1373Y','1'
                                                                                                       ,'MA1374Y','1'
                                                                                                       ,'MA1375' ,DECODE(f.inqy_rspn_ctn1,'','','1'),'0'))
                                                        ,''
                                                        )     
                                           ,''
                                 )  history_cancer_pancreas
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1375' ,f.inqy_rspn_ctn1,''))
                                 ,''
                                 ) cancer_pancreas_age_diag
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1371Y','1'
                                                                                                       ,'MA1372Y','1'
                                                                                                       ,'MA1373Y','1'
                                                                                                       ,'MA1374Y','1'     -- 기타
                                                                                                       ,'MA1375' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))
                                           ,''
                                 ) trt_cancer_pancreas
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1371Y','1'     -- 수술
                                                                                                       ,'MA1372Y','0'     -- 약물치료
                                                                                                       ,'MA1373Y','0'     -- 방사선치료
                                                                                                       ,'MA1374Y','0'     -- 기타
                                                                                                       ,'MA1375' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_pancreas_op
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1371Y','0'     -- 수술
                                                                                                       ,'MA1372Y','1'     -- 약물치료
                                                                                                       ,'MA1373Y','0'     -- 방사선치료
                                                                                                       ,'MA1374Y','0'     -- 기타
                                                                                                       ,'MA1375' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_pancreas_ch
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1371Y','0'     -- 수술
                                                                                                       ,'MA1372Y','0'     -- 약물치료
                                                                                                       ,'MA1373Y','1'     -- 방사선치료
                                                                                                       ,'MA1374Y','0'     -- 기타
                                                                                                       ,'MA1375' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_pancreas_ra
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1371Y','0'     -- 수술
                                                                                                       ,'MA1372Y','0'     -- 약물치료
                                                                                                       ,'MA1373Y','0'     -- 방사선치료
                                                                                                       ,'MA1374Y','1'     -- 기타
                                                                                                       ,'MA1375' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_pancreas_ot
                    /* 기타암 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.history_cancer     ,'0','0'
                                                                              ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1377Y','1'
                                                                                                       ,'MA1378Y','1'
                                                                                                       ,'MA1379Y','1'
                                                                                                       ,'MA1380Y','1'
                                                                                                       ,'MA1376' ,DECODE(f.inqy_rspn_ctn1,'','','1')
                                                                                                       ,'MA1381' ,DECODE(f.inqy_rspn_ctn1,'','','1'),'0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) history_cancer_other
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1381' ,f.inqy_rspn_ctn1,''))
                                 ,''
                                 ) cancer_other_age_diag
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1377Y','1'
                                                                                                       ,'MA1378Y','1'
                                                                                                       ,'MA1379Y','1'
                                                                                                       ,'MA1380Y','1'     -- 기타
                                                                                                       ,'MA1381' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))
                                           ,''
                                           ) trt_cancer_other
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1377Y','1'     -- 수술
                                                                                                       ,'MA1378Y','0'     -- 약물치료
                                                                                                       ,'MA1379Y','0'     -- 방사선치료
                                                                                                       ,'MA1380Y','0'     -- 기타
                                                                                                       ,'MA1381' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_other_op
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1377Y','0'     -- 수술
                                                                                                       ,'MA1378Y','1'     -- 약물치료
                                                                                                       ,'MA1379Y','0'     -- 방사선치료
                                                                                                       ,'MA1380Y','0'     -- 기타
                                                                                                       ,'MA1381' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_other_ch
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1377Y','0'     -- 수술
                                                                                                       ,'MA1378Y','0'     -- 약물치료
                                                                                                       ,'MA1379Y','1'     -- 방사선치료
                                                                                                       ,'MA1380Y','0'     -- 기타
                                                                                                       ,'MA1381' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_other_ra
                         , decode(f.inpc_cd,'AM' ,'9999'
                                                     ,'RR' ,'9999'
                                                     ,'MA1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1377Y','0'     -- 수술
                                                                                                       ,'MA1378Y','0'     -- 약물치료
                                                                                                       ,'MA1379Y','0'     -- 방사선치료
                                                                                                       ,'MA1380Y','1'     -- 기타
                                                                                                       ,'MA1381' ,DECODE(f.inqy_rspn_ctn1,'','','0'),''))-- 기타
                                           ,''
                                           ) trt_cancer_other_ot
                      from (-- 암병력 전체값 고려
                            select /*+ ordered use_nl(b a) index(b 3E3C0E433E3C0E3E28_i13) index(a 3E3C23302E333E0E28_pk) */
                                   'C04' grp
                                 , a.PTNO
                                 , a.ordr_prrn_ymd
                                 , a.inpc_cd
                            /* 암병력 */
                                 , case 
                                        when /*case3. 암관련 응답내역이 있으면 1 */
                                             count(
                                                   case 
                                                        when a.inpc_cd||a.item_sno            = 'AM127' then a.inqy_rspn_cd
                                                        when a.inpc_cd = 'MA1' and (a.item_sno between 299 and 381) then a.ceck_yn||a.inqy_rspn_ctn1 -- MA1 문진의 경우 CTN은 응답이 있어도 ceck_yn이 null이므로 함께 고려
                                                        when a.inpc_cd = 'MA1' and (a.item_sno between 299 and 381) then a.inqy_rspn_ctn1
                                                        else ''
                                                   end
                                                  ) > 0
                                        then '1'
                                        when /*case1. 암병력 응답내역이 아무것도 없고, 암병력 없다에 체크된 경우는 0 */
                                             count(
                                                   case 
                                                        when a.inpc_cd = 'MA1' and (a.item_sno between 299 and 381) then a.ceck_yn||a.inqy_rspn_ctn1 -- MA1 문진의 경우 CTN은 응답이 있어도 ceck_yn이 null이므로 함께 고려
                                                        when a.inpc_cd = 'MA1' and (a.item_sno between 299 and 381) then a.inqy_rspn_ctn1
                                                        else ''
                                                   end
                                                  ) = 0
                                             and
                                             count(case 
                                                        when a.inpc_cd||a.item_sno||a.ceck_yn = 'MA1297Y' then a.ceck_yn
                                                        else '' 
                                                   end
                                                  ) = 1
                                        then '0'
                                        when /*case2. 타/질병력 내역이 있거나, 질병력 없다에 체크된 경우는 0 */
                                             count(
                                                   case 
                                                        when a.inpc_cd = 'AM' and (a.item_sno between 103 and 126) then a.inqy_rspn_cd
                                                        when a.inpc_cd = 'AM' and (a.item_sno between 128 and 129) then a.inqy_rspn_cd
                                                        else ''
                                                   end
                                                  ) != 0
                                             or
                                             count(
                                                   case 
                                                        when a.inpc_cd||a.item_sno            = 'AM130' then a.inqy_rspn_cd
                                                        else ''
                                                   end
                                                  ) = 1
                                        then '0'
                                        else max(decode(a.inpc_cd,'RR','9999',''))
                                   end history_cancer
                              from 스키마.3E3C0E433E3C0E3E28@SMISR_스키마 b
                                 , 스키마.3E3C23302E333E0E28@SMISR_스키마 a
                             where 
                    --               b.ptno IN ('01982036' -- AM문진  응답자
                    --                         ,'00477937' -- RR문진  응답자
                    --                         ,'04032026' -- MA1문진 응답자
                    --                         )
                    --           and 
                                   b.ordr_prrn_ymd between to_date(&qfrdt,'yyyymmdd') and to_date(&qtodt,'yyyymmdd')
                               and b.ordr_ymd is not null
                               and b.cncl_dt is null
                               and a.ptno = b.ptno
                               and a.ordr_prrn_ymd = b.ordr_prrn_ymd
                               and a.inpc_cd in ('AM','RR','MA1')
                               AND (-- AM, RR의 경우는 응답한 것만 저장되었으므로, 모두 범위에 포함
                                      (a.inpc_cd = 'AM'  and a.item_sno between 1   and 500)
                                   OR (a.inpc_cd = 'RR'  and a.item_sno between 1   and 300)
                                   OR (a.inpc_cd = 'MA1' and a.item_sno between 296 and 382)
                                   )
                               and b.ptno not in (
                                                  &not_in_ptno
                                                 )
                               and b.rprs_apnt_no = a.rprs_apnt_no
                             group by a.PTNO
                                 , a.ordr_prrn_ymd
                                 , a.inpc_cd
                           ) a
                         , 스키마.3E3C23302E333E0E28@SMISR_스키마 f
                         , 스키마.0E5B5B285B28402857@SMISR_스키마 b
                     where a.ptno = f.ptno
                       and a.ordr_prrn_ymd = f.ordr_prrn_ymd
                       and a.inpc_cd = f.inpc_cd
                       AND (-- AM, RR의 경우는 응답한 것만 저장되었으므로, 모두 범위에 포함
                              (f.inpc_cd = 'AM'  and f.item_sno between 1   and 500)
                           OR (f.inpc_cd = 'RR'  and f.item_sno between 1   and 300)
                                   OR (f.inpc_cd = 'MA1' and f.item_sno between 296 and 382)
                           )
                       and a.ptno = b.ptno
                     group by f.rprs_apnt_no
                         , a.PTNO
                         , a.ordr_prrn_ymd
                         , f.inpc_cd
                         , b.gend_cd
                         , a.history_cancer
                   ) h                                                                          
                                                                                      
           )                                                                          
                                                                                      
            loop                                                                      
            begin   -- 데이터 update                                                  
                          update /*+ append */                                        
                                 스키마.1543294D47144D302E333E0E28 a                               
                             set                                                      
                                 a.HISTORY_CANCER                      = drh."1" 
                               , a.HISTORY_CANCER_STOMACH              = drh."2" 
                               , a.CANCER_STOMACH_AGE_DIAG             = drh."3" 
                               , a.TRT_CANCER_STOMACH                  = drh."4" 
                               , a.TRT_CANCER_STOMACH_OP               = drh."5" 
                               , a.TRT_CANCER_STOMACH_CH               = drh."6" 
                               , a.TRT_CANCER_STOMACH_RA               = drh."7" 
                               , a.TRT_CANCER_STOMACH_OT               = drh."8" 
                               , a.HISTORY_CANCER_LUNG                 = drh."9" 
                               , a.CANCER_LUNG_AGE_DIAG                = drh."10"
                               , a.TRT_CANCER_LUNG                     = drh."11"
                               , a.TRT_CANCER_LUNG_OP                  = drh."12"
                               , a.TRT_CANCER_LUNG_CH                  = drh."13"
                               , a.TRT_CANCER_LUNG_RA                  = drh."14"
                               , a.TRT_CANCER_LUNG_OT                  = drh."15"
                               , a.HISTORY_CANCER_LIVER                = drh."16"
                               , a.CANCER_LIVER_AGE_DIAG               = drh."17"
                               , a.TRT_CANCER_LIVER                    = drh."18"
                               , a.TRT_CANCER_LIVER_OP                 = drh."19"
                               , a.TRT_CANCER_LIVER_CH                 = drh."20"
                               , a.TRT_CANCER_LIVER_RA                 = drh."21"
                               , a.TRT_CANCER_LIVER_OT                 = drh."22"
                               , a.HISTORY_CANCER_COLORECTAL           = drh."23"
                               , a.CANCER_COLORECTAL_AGE_DIAG          = drh."24"
                               , a.TRT_CANCER_COLORECTAL               = drh."25"
                               , a.TRT_CANCER_COLORECTAL_OP            = drh."26"
                               , a.TRT_CANCER_COLORECTAL_CH            = drh."27"
                               , a.TRT_CANCER_COLORECTAL_RA            = drh."28"
                               , a.TRT_CANCER_COLORECTAL_OT            = drh."29"
                               , a.HISTORY_CANCER_BREAST               = drh."30"
                               , a.CANCER_BREAST_AGE_DIAG              = drh."31"
                               , a.TRT_CANCER_BREAST                   = drh."32"
                               , a.TRT_CANCER_BREAST_OP                = drh."33"
                               , a.TRT_CANCER_BREAST_CH                = drh."34"
                               , a.TRT_CANCER_BREAST_RA                = drh."35"
                               , a.TRT_CANCER_BREAST_OT                = drh."36"
                               , a.HISTORY_CANCER_CERVIX               = drh."37"
                               , a.CANCER_CERVIX_AGE_DIAG              = drh."38"
                               , a.TRT_CANCER_CERVIX                   = drh."39"
                               , a.TRT_CANCER_CERVIX_OP                = drh."40"
                               , a.TRT_CANCER_CERVIX_CH                = drh."41"
                               , a.TRT_CANCER_CERVIX_RA                = drh."42"
                               , a.TRT_CANCER_CERVIX_OT                = drh."43"
                               , a.HISTORY_CANCER_THYROID              = drh."44"
                               , a.CANCER_THYROID_AGE_DIAG             = drh."45"
                               , a.TRT_CANCER_THYROID                  = drh."46"
                               , a.TRT_CANCER_THYROID_OP               = drh."47"
                               , a.TRT_CANCER_THYROID_CH               = drh."48"
                               , a.TRT_CANCER_THYROID_RA               = drh."49"
                               , a.TRT_CANCER_THYROID_OT               = drh."50"
                               , a.HISTORY_CANCER_BLADDER              = drh."51"
                               , a.CANCER_BLADDER_AGE_DIAG             = drh."52"
                               , a.TRT_CANCER_BLADDER                  = drh."53"
                               , a.TRT_CANCER_BLADDER_OP               = drh."54"
                               , a.TRT_CANCER_BLADDER_CH               = drh."55"
                               , a.TRT_CANCER_BLADDER_RA               = drh."56"
                               , a.TRT_CANCER_BLADDER_OT               = drh."57"
                               , a.HISTORY_CANCER_ESOPHAGUS            = drh."58"
                               , a.CANCER_ESOPHAGUS_AGE_DIAG           = drh."59"
                               , a.TRT_CANCER_ESOPHAGUS                = drh."60"
                               , a.TRT_CANCER_ESOPHAGUS_OP             = drh."61"
                               , a.TRT_CANCER_ESOPHAGUS_CH             = drh."62"
                               , a.TRT_CANCER_ESOPHAGUS_RA             = drh."63"
                               , a.TRT_CANCER_ESOPHAGUS_OT             = drh."64"
                               , a.HISTORY_CANCER_GB_BILIARY           = drh."65"
                               , a.CANCER_GB_BILIARY_AGE_DIAG          = drh."66"
                               , a.TRT_CANCER_GB_BILIARY               = drh."67"
                               , a.TRT_CANCER_GB_BILIARY_OP            = drh."68"
                               , a.TRT_CANCER_GB_BILIARY_CH            = drh."69"
                               , a.TRT_CANCER_GB_BILIARY_RA            = drh."70"
                               , a.TRT_CANCER_GB_BILIARY_OT            = drh."71"
                               , a.HISTORY_CANCER_OVARY                = drh."72"
                               , a.CANCER_OVARY_AGE_DIAG               = drh."73"
                               , a.TRT_CANCER_OVARY                    = drh."74"
                               , a.TRT_CANCER_OVARY_OP                 = drh."75"
                               , a.TRT_CANCER_OVARY_CH                 = drh."76"
                               , a.TRT_CANCER_OVARY_RA                 = drh."77"
                               , a.TRT_CANCER_OVARY_OT                 = drh."78"
                               , a.HISTORY_CANCER_PROSTATE             = drh."79"
                               , a.CANCER_PROSTATE_AGE_DIAG            = drh."80"
                               , a.TRT_CANCER_PROSTATE                 = drh."81"
                               , a.TRT_CANCER_PROSTATE_OP              = drh."82"
                               , a.TRT_CANCER_PROSTATE_CH              = drh."83"
                               , a.TRT_CANCER_PROSTATE_RA              = drh."84"
                               , a.TRT_CANCER_PROSTATE_OT              = drh."85"
                               , a.HISTORY_CANCER_PANCREAS             = drh."86"
                               , a.CANCER_PANCREAS_AGE_DIAG            = drh."87"
                               , a.TRT_CANCER_PANCREAS                 = drh."88"
                               , a.TRT_CANCER_PANCREAS_OP              = drh."89"
                               , a.TRT_CANCER_PANCREAS_CH              = drh."90"
                               , a.TRT_CANCER_PANCREAS_RA              = drh."91"
                               , a.TRT_CANCER_PANCREAS_OT              = drh."92"
                               , a.HISTORY_CANCER_OTHER                = drh."93"
                               , a.CANCER_OTHER_AGE_DIAG               = drh."94"
                               , a.TRT_CANCER_OTHER                    = drh."95"
                               , a.TRT_CANCER_OTHER_OP                 = drh."96"
                               , a.TRT_CANCER_OTHER_CH                 = drh."97"
                               , a.TRT_CANCER_OTHER_RA                 = drh."98"
                               , a.TRT_CANCER_OTHER_OT                 = drh."99"                                                                                      
                               , a.last_updt_dt                     = drh.last_updt_dt
                           where a.ptno = drh.ptno                                    
                             and a.ordr_prrn_ymd = drh.ordr_prrn_ymd                  
                             and a.rprs_apnt_no = drh.rprs_apnt_no                    
                                 ;                                                    
                                                                                      
                         commit;                                                      
                                                                                      
                       upcnt := upcnt + 1;                                            
                                                                                      
                       exception                                                      
                       when others then                                               
                          rollback;                                                   
                          errcnt := errcnt + 1;                                       
                                                                                      
            end;                                                                      
            end loop;                                                                 
                                                                                      
:var_msg2  := 'update '  || to_char(upcnt)    || ' 건';                               
:var_msg3  := 'error '   || to_char(errcnt)   || ' 건';                               
                                                                                      
end ;                                                                                 
/                                                                                     
print var_msg2                                                                        
print var_msg3                                                                        
spool off;
      
-- 문진 정보 update, 약복용력
-- 변수 길이가 길다는 에러메세지 때문에 변수를 숫자정보로 치환
-- 메시지 출력기능 추가. 메시지 확인은 F5를 눌러야 가능함
variable var_msg2 char(40);
variable var_msg3 char(40);
  
declare
    upcnt     number(10) := 0;
    errcnt    number(10) := 0;
        
begin
for drh in (
            -- 데이터 select
            select h.RPRS_APNT_NO                        as RPRS_APNT_NO
                 , h.PTNO                                as ptno
                 , h.ORDR_PRRN_YMD                       as ordr_prrn_ymd
                 , h.MED                                 as "1" 
                 , h.MED_HYPERTENSION                    as "2" 
                 , h.TRT_MED_HYPERTENSION                as "3" 
                 , h.MED_HYPERTENSION_DURATION           as "4" 
                 , h.MED_DIABETES                        as "5" 
                 , h.TRT_MED_DIABETES                    as "6" 
                 , h.MED_DIABETES_DURATION               as "7" 
                 , h.MED_ASPIRIN                         as "8" 
                 , h.TRT_MED_ASPIRIN                     as "9" 
                 , h.MED_ASPIRIN_DURATION                as "10"
                 , h.MED_NSAIDS                          as "11"
                 , h.TRT_MED_NSAIDS                      as "12"
                 , h.MED_NSAIDS_DURATION                 as "13"
                 , h.MED_CALCIUM                         as "14"
                 , h.TRT_MED_CALCIUM                     as "15"
                 , h.MED_CALCIUM_DURATION                as "16"
                 , h.MED_IRON                            as "17"
                 , h.TRT_MED_IRON                        as "18"
                 , h.MED_IRON_DURATION                   as "19"
                 , h.MED_CAM                             as "20"
                 , h.TRT_MED_CAM                         as "21"
                 , h.MED_CAM_DURATION                    as "22"
                 , h.MED_BETA_CAROTENE                   as "23"
                 , h.MED_BETA_CAROTENE_DURATION          as "24"
                 , h.MED_MULTI_VITAMIN                   as "25"
                 , h.MED_MULTI_VITAMIN_DURATION          as "26"
                 , h.MED_VITAMIN_A                       as "27"
                 , h.MED_VITAMIN_A_DURATION              as "28"
                 , h.MED_VITAMIN_B                       as "29"
                 , h.MED_VITAMIN_B_DURATION              as "30"
                 , h.MED_VITAMIN_C                       as "31"
                 , h.MED_VITAMIN_C_DURATION              as "32"
                 , h.MED_VITAMIN_E                       as "33"
                 , h.MED_VITAMIN_E_DURATION              as "34"
                 , h.MED_OTHER_SUPPLEMENTS               as "35"
                 , h.MED_OTHER_SUPPLEMENTS_DURATION      as "36"
                 , h.MED_HYPERLIPIDEMIA                  as "37"
                 , h.TRT_MED_HYPERLIPIDEMIA              as "38"
                 , h.MED_WARFARIN                        as "39"
                 , h.TRT_MED_WARFARIN                    as "40"
                 , h.MED_ANTICOAGULANT                   as "41"
                 , h.TRT_MED_ANTICOAGULANT               as "42"
                 , h.MED_ARRHYTHMIA                      as "43"
                 , h.TRT_MED_ARRHYTHMIA                  as "44"
                 , h.MED_GI_DIGESTIVES                   as "45"
                 , h.TRT_MED_GI_DIGESTIVES               as "46"
                 , h.MED_LIVER                           as "47"
                 , h.TRT_MED_LIVER                       as "48"
                 , h.MED_CONSTIPATION                    as "49"
                 , h.TRT_MED_CONSTIPATION                as "50"
                 , h.MED_THYROID_DIS                     as "51"
                 , h.TRT_MED_THYROID_DIS                 as "52"
                 , h.MED_OSTEOPOROSIS                    as "53"
                 , h.TRT_MED_OSTEOPOROSIS                as "54"
                 , h.MED_FEMALE_HORMONES                 as "55"
                 , h.TRT_MED_FEMALE_HORMONES             as "56"
                 , h.MED_BPH                             as "57"
                 , h.TRT_MED_BPH                         as "58"
                 , h.MED_RESPIRATORY_DIS                 as "59"
                 , h.TRT_MED_RESPIRATORY_DIS             as "60"
                 , h.MED_NUTRI_SUPPLEMENTS               as "61"
                 , h.TRT_MED_NUTRI_SUPPLEMENTS           as "62"
                 , h.MED_SLEEPING_PILLS                  as "63"
                 , h.MED_SLEEPING_PILLS_DURATION         as "64"
                 , h.MED_PSYCHIATRIC                     as "65"
                 , h.TRT_MED_PSYCHIATRIC                 as "66"
                 , h.MED_OTHER                           as "67"
                 , h.TRT_MED_OTHER                       as "68"
                 , h.MED_OTHER_DURATION                  as "69"
                 , sysdate                          as last_updt_dt
              from (-- 약복용력
                    select /*+ index(f 3E3C23302E333E0E28_pk) */
                           f.rprs_apnt_no
                         , a.PTNO
                         , a.ordr_prrn_ymd
                         , f.inpc_cd
                         , b.gend_cd
                         , a.med
                    /* 혈압약 */
                         , decode(a.med                ,'0','0'
                                                       ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM134Y' ,'1'
                                                                                ,'AM134'  ,'1'
                                                                                ,'RR105Y' ,'1'
                                                                                ,'RR105'  ,'1'
                                                                                ,'MA1231Y','1'
                                                                                ,'MA1232Y','1','0'))
                                                       ,''
                                 ) med_hypertension
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1231Y','1'      --,'1' 현재 치료중.
                                                                                             ,'MA1232Y','0','')) --,'2' 과거 치료
                                 ,''
                                 ) trt_med_hypertension
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM134Y',decode(f.inqy_rspn_ctn1||f.inqy_rspn_ctn2,'','',f.inqy_rspn_ctn1||' 개월 또는 '||f.inqy_rspn_ctn2||' 년')
                                                                                             ,'AM134' ,decode(f.inqy_rspn_ctn1||f.inqy_rspn_ctn2,'','',f.inqy_rspn_ctn1||' 개월 또는 '||f.inqy_rspn_ctn2||' 년'),''))
                                           ,'RR' ,'9999'
                                           ,'MA1','9999'
                                 ,''
                                 ) med_hypertension_duration
                    /* 당뇨약 */
                         , decode(a.med                ,'0','0'
                                                       ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM135Y' ,'1'
                                                                                ,'AM135'  ,'1'
                                                                                ,'RR106Y' ,'1'
                                                                                ,'RR106'  ,'1'
                                                                                ,'MA1234Y','1'
                                                                                ,'MA1235Y','1','0'))
                                                       ,''
                                 ) med_diabetes
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1234Y','1'      --,'1' 현재 치료중.
                                                                                             ,'MA1235Y','0','')) --,'2' 과거 치료
                                 ,''
                                 ) trt_med_diabetes
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM135Y',decode(f.inqy_rspn_ctn1||f.inqy_rspn_ctn2,'','',f.inqy_rspn_ctn1||' 개월 또는 '||f.inqy_rspn_ctn2||' 년')
                                                                                             ,'AM135' ,decode(f.inqy_rspn_ctn1||f.inqy_rspn_ctn2,'','',f.inqy_rspn_ctn1||' 개월 또는 '||f.inqy_rspn_ctn2||' 년'),''))
                                           ,'RR' ,'9999'
                                           ,'MA1','9999'
                                 ,''
                                 ) med_diabetes_duration
                    /* 아스피린 */
                         , decode(a.med                ,'0','0'
                                                       ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM132Y' ,'1'
                                                                                ,'AM132'  ,'1'
                                                                                ,'RR103Y' ,'1'
                                                                                ,'RR103'  ,'1'
                                                                                ,'MA1240Y','1'
                                                                                ,'MA1241Y','1','0'))
                                                       ,''
                                 ) med_aspirin
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1240Y','1'      --,'1' 현재 치료중.
                                                                                             ,'MA1241Y','0','')) --,'2' 과거 치료
                                 ,''
                                 ) trt_med_aspirin
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM132Y',decode(f.inqy_rspn_ctn1||f.inqy_rspn_ctn2,'','',f.inqy_rspn_ctn1||' 개월 또는 '||f.inqy_rspn_ctn2||' 년')
                                                                                             ,'AM132' ,decode(f.inqy_rspn_ctn1||f.inqy_rspn_ctn2,'','',f.inqy_rspn_ctn1||' 개월 또는 '||f.inqy_rspn_ctn2||' 년'),''))
                                           ,'RR' ,'9999'
                                           ,'MA1','9999'
                                 ,''
                                 ) med_aspirin_duration
                    /* 소염진통제 */
                         , decode(a.med                ,'0','0'
                                                       ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM133Y' ,'1'
                                                                                ,'AM133'  ,'1'
                                                                                ,'RR104Y' ,'1'
                                                                                ,'RR104'  ,'1'
                                                                                ,'MA1261Y','1'
                                                                                ,'MA1262Y','1','0'))
                                                       ,''
                                 ) med_nsaids
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1261Y','1'      --,'1' 현재 치료중.
                                                                                             ,'MA1262Y','0','')) --,'2' 과거 치료
                                 ,''
                                 ) trt_med_nsaids
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM133Y',decode(f.inqy_rspn_ctn1||f.inqy_rspn_ctn2,'','',f.inqy_rspn_ctn1||' 개월 또는 '||f.inqy_rspn_ctn2||' 년')
                                                                                             ,'AM133' ,decode(f.inqy_rspn_ctn1||f.inqy_rspn_ctn2,'','',f.inqy_rspn_ctn1||' 개월 또는 '||f.inqy_rspn_ctn2||' 년'),''))
                                           ,'RR' ,'9999'
                                           ,'MA1','9999'
                                 ,''
                                 ) med_nsaids_duration
                    /* 칼슘제재 */
                         , decode(a.med                ,'0','0'
                                                       ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM142Y' ,'1'
                                                                                ,'AM142'  ,'1'
                                                                                ,'RR113Y' ,'1'
                                                                                ,'RR113'  ,'1'
                                                                                ,'MA1276Y','1'
                                                                                ,'MA1277Y','1','0'))
                                                       ,''
                                 ) med_calcium
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1276Y','1'      --,'1' 현재 치료중.
                                                                                             ,'MA1277Y','0','')) --,'2' 과거 치료
                                 ,''
                                 ) trt_med_calcium
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM142Y',decode(f.inqy_rspn_ctn1||f.inqy_rspn_ctn2,'','',f.inqy_rspn_ctn1||' 개월 또는 '||f.inqy_rspn_ctn2||' 년')
                                                                                             ,'AM142' ,decode(f.inqy_rspn_ctn1||f.inqy_rspn_ctn2,'','',f.inqy_rspn_ctn1||' 개월 또는 '||f.inqy_rspn_ctn2||' 년'),''))
                                           ,'RR' ,'9999'
                                           ,'MA1','9999'
                                 ,''
                                 ) med_calcium_duration
                    /* 철분제재 */
                         , decode(a.med                ,'0','0'
                                                       ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM143Y' ,'1'
                                                                                ,'AM143'  ,'1'
                                                                                ,'RR114Y' ,'1'
                                                                                ,'RR114'  ,'1'
                                                                                ,'MA1279Y','1'
                                                                                ,'MA1280Y','1','0'))
                                                       ,''
                                 ) med_iron
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1279Y','1'      --,'1' 현재 치료중.
                                                                                             ,'MA1280Y','0','')) --,'2' 과거 치료
                                 ,''
                                 ) trt_med_iron
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM143Y',decode(f.inqy_rspn_ctn1||f.inqy_rspn_ctn2,'','',f.inqy_rspn_ctn1||' 개월 또는 '||f.inqy_rspn_ctn2||' 년')
                                                                                             ,'AM143' ,decode(f.inqy_rspn_ctn1||f.inqy_rspn_ctn2,'','',f.inqy_rspn_ctn1||' 개월 또는 '||f.inqy_rspn_ctn2||' 년'),''))
                                           ,'RR' ,'9999'
                                           ,'MA1','9999'
                                 ,''
                                 ) med_iron_duration
                    /* 한약, 보약 */
                         , decode(a.med                ,'0','0'
                                                       ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM147Y' ,'1'
                                                                                ,'AM147'  ,'1'
                                                                                ,'RR118Y' ,'1'
                                                                                ,'RR118'  ,'1'
                                                                                ,'MA1291Y','1'
                                                                                ,'MA1292Y','1','0'))
                                                       ,''
                                 ) med_cam
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1291Y','1'      --,'1' 현재 치료중.
                                                                                             ,'MA1292Y','0','')) --,'2' 과거 치료
                                 ,''
                                 ) trt_med_cam
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM147Y',decode(f.inqy_rspn_ctn1||f.inqy_rspn_ctn2,'','',f.inqy_rspn_ctn1||' 개월 또는 '||f.inqy_rspn_ctn2||' 년')
                                                                                             ,'AM147' ,decode(f.inqy_rspn_ctn1||f.inqy_rspn_ctn2,'','',f.inqy_rspn_ctn1||' 개월 또는 '||f.inqy_rspn_ctn2||' 년'),''))
                                           ,'RR' ,'9999'
                                           ,'MA1','9999'
                                 ,''
                                 ) med_cam_duration
                    /* 베타 카로테인 */
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'AM' ,decode(a.med          ,'0','0'
                                                                        ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM141Y' ,'1'
                                                                                                       ,'AM141'  ,'1','0')),'')
                                           ,'RR' ,decode(a.med          ,'0','0'
                                                                        ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'RR112Y' ,'1'
                                                                                                       ,'RR112'  ,'1','0')),'')
                                 ,''
                                 ) med_beta_carotene
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM141Y',decode(f.inqy_rspn_ctn1||f.inqy_rspn_ctn2,'','',f.inqy_rspn_ctn1||' 개월 또는 '||f.inqy_rspn_ctn2||' 년')
                                                                                             ,'AM141' ,decode(f.inqy_rspn_ctn1||f.inqy_rspn_ctn2,'','',f.inqy_rspn_ctn1||' 개월 또는 '||f.inqy_rspn_ctn2||' 년'),''))
                                           ,'RR' ,'9999'
                                           ,'MA1','9999'
                                 ,''
                                 ) med_beta_carotene_duration
                    /* 종합비타민 */
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'AM' ,decode(a.med          ,'0','0'
                                                                        ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM136Y' ,'1'
                                                                                                       ,'AM136'  ,'1','0')),'')
                                           ,'RR' ,decode(a.med          ,'0','0'
                                                                        ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'RR107Y' ,'1'
                                                                                                       ,'RR107'  ,'1','0')),'')
                                 ,''
                                 ) med_multi_vitamin
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM136Y',decode(f.inqy_rspn_ctn1||f.inqy_rspn_ctn2,'','',f.inqy_rspn_ctn1||' 개월 또는 '||f.inqy_rspn_ctn2||' 년')
                                                                                             ,'AM136' ,decode(f.inqy_rspn_ctn1||f.inqy_rspn_ctn2,'','',f.inqy_rspn_ctn1||' 개월 또는 '||f.inqy_rspn_ctn2||' 년'),''))
                                           ,'RR' ,'9999'
                                           ,'MA1','9999'
                                 ,''
                                 ) med_multi_vitamin_duration
                    /* 비타민A */
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'AM' ,decode(a.med          ,'0','0'
                                                                        ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM137Y' ,'1'
                                                                                                       ,'AM137'  ,'1','0')),'')
                                           ,'RR' ,decode(a.med          ,'0','0'
                                                                        ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'RR108Y' ,'1'
                                                                                                       ,'RR108'  ,'1','0')),'')
                                 ,''
                                 ) med_vitamin_a
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM137Y',decode(f.inqy_rspn_ctn1||f.inqy_rspn_ctn2,'','',f.inqy_rspn_ctn1||' 개월 또는 '||f.inqy_rspn_ctn2||' 년')
                                                                                             ,'AM137' ,decode(f.inqy_rspn_ctn1||f.inqy_rspn_ctn2,'','',f.inqy_rspn_ctn1||' 개월 또는 '||f.inqy_rspn_ctn2||' 년'),''))
                                           ,'RR' ,'9999'
                                           ,'MA1','9999'
                                 ,''
                                 ) med_vitamin_a_duration
                    /* 비타민b */
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'AM' ,decode(a.med          ,'0','0'
                                                                        ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM138Y' ,'1'
                                                                                                       ,'AM138'  ,'1','0')),'')
                                           ,'RR' ,decode(a.med          ,'0','0'
                                                                        ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'RR109Y' ,'1'
                                                                                                       ,'RR109'  ,'1','0')),'')
                                 ,''
                                 ) med_vitamin_b
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM138Y',decode(f.inqy_rspn_ctn1||f.inqy_rspn_ctn2,'','',f.inqy_rspn_ctn1||' 개월 또는 '||f.inqy_rspn_ctn2||' 년')
                                                                                             ,'AM138' ,decode(f.inqy_rspn_ctn1||f.inqy_rspn_ctn2,'','',f.inqy_rspn_ctn1||' 개월 또는 '||f.inqy_rspn_ctn2||' 년'),''))
                                           ,'RR' ,'9999'
                                           ,'MA1','9999'
                                 ,''
                                 ) med_vitamin_b_duration
                    /* 비타민c */
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'AM' ,decode(a.med          ,'0','0'
                                                                        ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM139Y' ,'1'
                                                                                                       ,'AM139'  ,'1','0')),'')
                                           ,'RR' ,decode(a.med          ,'0','0'
                                                                        ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'RR110Y' ,'1'
                                                                                                       ,'RR110'  ,'1','0')),'')
                                 ,''
                                 ) med_vitamin_c
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM139Y',decode(f.inqy_rspn_ctn1||f.inqy_rspn_ctn2,'','',f.inqy_rspn_ctn1||' 개월 또는 '||f.inqy_rspn_ctn2||' 년')
                                                                                             ,'AM139' ,decode(f.inqy_rspn_ctn1||f.inqy_rspn_ctn2,'','',f.inqy_rspn_ctn1||' 개월 또는 '||f.inqy_rspn_ctn2||' 년'),''))
                                           ,'RR' ,'9999'
                                           ,'MA1','9999'
                                 ,''
                                 ) med_vitamin_c_duration
                    /* 비타민e */
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'AM' ,decode(a.med          ,'0','0'
                                                                        ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM140Y' ,'1'
                                                                                                       ,'AM140'  ,'1','0')),'')
                                           ,'RR' ,decode(a.med          ,'0','0'
                                                                        ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'RR111Y' ,'1'
                                                                                                       ,'RR111'  ,'1','0')),'')
                                 ,''
                                 ) med_vitamin_e
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM140Y',decode(f.inqy_rspn_ctn1||f.inqy_rspn_ctn2,'','',f.inqy_rspn_ctn1||' 개월 또는 '||f.inqy_rspn_ctn2||' 년')
                                                                                             ,'AM140' ,decode(f.inqy_rspn_ctn1||f.inqy_rspn_ctn2,'','',f.inqy_rspn_ctn1||' 개월 또는 '||f.inqy_rspn_ctn2||' 년'),''))
                                           ,'RR' ,'9999'
                                           ,'MA1','9999'
                                 ,''
                                 ) med_vitamin_e_duration
                    /* 기타 영양제 */
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'AM' ,decode(a.med          ,'0','0'
                                                                        ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM145Y' ,'1'
                                                                                                       ,'AM145'  ,'1','0')),'')
                                           ,'RR' ,decode(a.med          ,'0','0'
                                                                        ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'RR116Y' ,'1'
                                                                                                       ,'RR116'  ,'1','0')),'')
                                 ,''
                                 ) med_other_supplements
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM145Y',decode(f.inqy_rspn_ctn1||f.inqy_rspn_ctn2,'','',f.inqy_rspn_ctn1||' 개월 또는 '||f.inqy_rspn_ctn2||' 년')
                                                                                             ,'AM145' ,decode(f.inqy_rspn_ctn1||f.inqy_rspn_ctn2,'','',f.inqy_rspn_ctn1||' 개월 또는 '||f.inqy_rspn_ctn2||' 년'),''))
                                           ,'RR' ,'9999'
                                           ,'MA1','9999'
                                 ,''
                                 ) med_other_supplements_duration
                    /* 고지혈증약 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.med                ,'0','0'
                                                                              ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1237Y','1'
                                                                                                       ,'MA1238Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) med_hyperlipidemia
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1237Y','1'      --,'1' 현재 치료중.
                                                                                             ,'MA1238Y','0','')) --,'2' 과거 치료
                                 ,''
                                 ) trt_med_hyperlipidemia
                    /* 와파린 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.med                ,'0','0'
                                                                              ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1243Y','1'
                                                                                                       ,'MA1244Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) med_warfarin
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1243Y','1'      --,'1' 현재 치료중.
                                                                                             ,'MA1244Y','0','')) --,'2' 과거 치료
                                 ,''
                                 ) trt_med_warfarin
                    /* 기타혈전방지제 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.med                ,'0','0'
                                                                              ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1246Y','1'
                                                                                                       ,'MA1247Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) med_anticoagulant
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1246Y','1'      --,'1' 현재 치료중.
                                                                                             ,'MA1247Y','0','')) --,'2' 과거 치료
                                 ,''
                                 ) trt_med_anticoagulant
                    /* 부정맥약 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.med                ,'0','0'
                                                                              ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1249Y','1'
                                                                                                       ,'MA1250Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) med_arrhythmia
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1249Y','1'      --,'1' 현재 치료중.
                                                                                             ,'MA1250Y','0','')) --,'2' 과거 치료
                                 ,''
                                 ) trt_med_arrhythmia
                    /* 위장약 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.med                ,'0','0'
                                                                              ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1252Y','1'
                                                                                                       ,'MA1253Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) med_gi_digestives
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1252Y','1'      --,'1' 현재 치료중.
                                                                                             ,'MA1253Y','0','')) --,'2' 과거 치료
                                 ,''
                                 ) trt_med_gi_digestives
                    /* 간장약 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.med                ,'0','0'
                                                                              ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1255Y','1'
                                                                                                       ,'MA1256Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) med_liver
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1255Y','1'      --,'1' 현재 치료중.
                                                                                             ,'MA1256Y','0','')) --,'2' 과거 치료
                                 ,''
                                 ) trt_med_liver
                    /* 변비약 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.med                ,'0','0'
                                                                              ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1258Y','1'
                                                                                                       ,'MA1259Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) med_constipation
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1258Y','1'      --,'1' 현재 치료중.
                                                                                             ,'MA1259Y','0','')) --,'2' 과거 치료
                                 ,''
                                 ) trt_med_constipation
                    /* 갑상선 치료제 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.med                ,'0','0'
                                                                              ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1264Y','1'
                                                                                                       ,'MA1265Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) med_thyroid_dis
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1264Y','1'      --,'1' 현재 치료중.
                                                                                             ,'MA1265Y','0','')) --,'2' 과거 치료
                                 ,''
                                 ) trt_med_thyroid_dis
                    /* 골다공증약 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.med                ,'0','0'
                                                                              ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1267Y','1'
                                                                                                       ,'MA1268Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) med_osteoporosis
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1267Y','1'      --,'1' 현재 치료중.
                                                                                             ,'MA1268Y','0','')) --,'2' 과거 치료
                                 ,''
                                 ) trt_med_osteoporosis
                    /* 여성 호르몬제 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.med                ,'0','0'
                                                                              ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1270Y','1'
                                                                                                       ,'MA1271Y','1','0'))
                                                        ,''
                                                        )
                                 ,''
                                 ) med_female_hormones
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1270Y','1'     -- ,'1' 현재 치료중.
                                                                                             ,'MA1271Y','0',''))-- ,'2' 과거 치료
                                 ,''
                                 ) trt_med_female_hormones
                    /* 전립선 비대증약 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.med                ,'0','0'
                                                                              ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1273Y','1'
                                                                                                       ,'MA1274Y','1','0'))
                                                        ,''
                                                        )
                                 ,''
                                 ) med_bph
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1273Y','1'     -- ,'1' 현재 치료중.
                                                                                             ,'MA1274Y','0',''))-- ,'2' 과거 치료
                                 ,''
                                 ) trt_med_bph
                    /* 호흡기 약물 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.med                ,'0','0'
                                                                              ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1285Y','1'
                                                                                                       ,'MA1286Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) med_respiratory_dis
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1285Y','1'      --,'1' 현재 치료중.
                                                                                             ,'MA1286Y','0','')) --,'2' 과거 치료
                                 ,''
                                 ) trt_med_respiratory_dis
                    /* 영양제 및 보조식품 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.med                ,'0','0'
                                                                              ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1288Y','1'
                                                                                                       ,'MA1289Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) med_nutri_supplements
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1288Y','1'      --,'1' 현재 치료중.
                                                                                             ,'MA1289Y','0','')) --,'2' 과거 치료
                                 ,''
                                 ) trt_med_nutri_supplements
                    /* 진정제/수면제 */
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'AM' ,decode(a.med          ,'0','0'
                                                                        ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM144Y' ,'1'
                                                                                                       ,'AM144'  ,'1','0')),'')
                                           ,'RR' ,decode(a.med          ,'0','0'
                                                                        ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'RR115Y' ,'1'
                                                                                                       ,'RR115'  ,'1','0')),'')
                                 ,''
                                 ) med_sleeping_pills
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM144Y',decode(f.inqy_rspn_ctn1||f.inqy_rspn_ctn2,'','',f.inqy_rspn_ctn1||' 개월 또는 '||f.inqy_rspn_ctn2||' 년')
                                                                                             ,'AM144' ,decode(f.inqy_rspn_ctn1||f.inqy_rspn_ctn2,'','',f.inqy_rspn_ctn1||' 개월 또는 '||f.inqy_rspn_ctn2||' 년'),''))
                                           ,'RR' ,'9999'
                                           ,'MA1','9999'
                                 ,''
                                 ) med_sleeping_pills_duration
                    /* 수면제/항우울약/기타 신경정신과 약물 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.med                ,'0','0'
                                                                              ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1282Y','1'
                                                                                                       ,'MA1283Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) med_psychiatric 
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1282Y','1'      --,'1' 현재 치료중.
                                                                                             ,'MA1283Y','0','')) --,'2' 과거 치료
                                 ,''
                                 ) trt_med_psychiatric
                    /* 기타약제 */
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,'AM' ,decode(a.med          ,'0','0'
                                                                        ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM146Y' ,'1'
                                                                                                       ,'AM146'  ,'1','0')),'')
                                           ,'MA1' ,decode(a.med         ,'0','0'
                                                                        ,'1',max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1293' ,decode(f.inqy_rspn_ctn1,'','','1')
                                                                                                       ,'MA1294Y','1'
                                                                                                       ,'MA1295Y','1','0')),'')
                                 ,''
                                 ) med_other
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1294Y','1'      --,'1' 현재 치료중.
                                                                                             ,'MA1295Y','0','')) --,'2' 과거 치료
                                 ,''
                                 ) trt_med_other
                         , decode(f.inpc_cd,'AM' ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM146Y',decode(f.inqy_rspn_ctn1||f.inqy_rspn_ctn2,'','',f.inqy_rspn_ctn1||' 개월 또는 '||f.inqy_rspn_ctn2||' 년')
                                                                                             ,'AM146' ,decode(f.inqy_rspn_ctn1||f.inqy_rspn_ctn2,'','',f.inqy_rspn_ctn1||' 개월 또는 '||f.inqy_rspn_ctn2||' 년'),''))
                                           ,'RR' ,'9999'
                                           ,'MA1','9999'
                                 ,''
                                 ) med_other_duration
                      from (-- 약복용력 전체값 고려
                            select   /*+ ordered use_nl(b a) index(b 3E3C0E433E3C0E3E28_i13) index(a 3E3C23302E333E0E28_pk) */
                                   'C03' grp
                                 , a.PTNO
                                 , a.ordr_prrn_ymd
                                 , a.inpc_cd
                            /* 약복용력 */
                                 , case 
                                        when /*case1. 약물복용 응답내역이 아무것도 없고, 약물복용력 없다에 체크된 경우는 0 */
                                             count(
                                                   case 
                                                        when a.inpc_cd = 'AM' and (a.item_sno between 132 and 147) then a.inqy_rspn_cd
                                                        when a.inpc_cd = 'RR' and (a.item_sno between 103 and 118) then a.inqy_rspn_cd
                                                        when a.inpc_cd = 'MA1' and (a.item_sno between 231 and 295) and a.item_sno != 290 then a.ceck_yn||a.inqy_rspn_ctn1--  MA1 문진의 경우 CTN은 응답이 있어도 ceck_yn이 null이므로 함께 고려
                                                        when a.inpc_cd = 'MA1' and (a.item_sno between 231 and 295) and a.item_sno != 290 then a.inqy_rspn_ctn1
                                                        else ''
                                                   end
                                                  ) = 0
                                             and
                                             count(case when a.inpc_cd||a.item_sno            = 'AM148' then a.inqy_rspn_cd
                                                        when a.inpc_cd||a.item_sno            = 'RR119' then a.inqy_rspn_cd
                                                        when a.inpc_cd||a.item_sno||a.ceck_yn = 'MA1229Y' then a.ceck_yn 
                                                        else '' 
                                                   end
                                                  ) = 1
                                        then '0'
                                        when /*case2. 다른 약물복용 응답내역이 있으면 1 */
                                             count(
                                                   case 
                                                        when a.inpc_cd = 'AM' and (a.item_sno between 132 and 147) then a.inqy_rspn_cd
                                                        when a.inpc_cd = 'RR' and (a.item_sno between 103 and 118) then a.inqy_rspn_cd
                                                        when a.inpc_cd = 'MA1' and (a.item_sno between 231 and 295) and a.item_sno != 290 then a.ceck_yn||a.inqy_rspn_ctn1--  MA1 문진의 경우 CTN은 응답이 있어도 ceck_yn이 null이므로 함께 고려
                                                        when a.inpc_cd = 'MA1' and (a.item_sno between 231 and 295) and a.item_sno != 290 then a.inqy_rspn_ctn1
                                                        else ''
                                                   end
                                                  ) > 0
                                        then '1'
                                        else ''
                                   end med
                              from 스키마.3E3C0E433E3C0E3E28@SMISR_스키마 b
                                 , 스키마.3E3C23302E333E0E28@SMISR_스키마 a
                             where 
                    --               b.ptno IN ('01982036' -- AM문진  응답자
                    --                         ,'00477937' -- RR문진  응답자
                    --                         ,'04032026' -- MA1문진 응답자
                    --                         )
                    --           and 
                                   b.ordr_prrn_ymd between to_date(&qfrdt,'yyyymmdd') and to_date(&qtodt,'yyyymmdd')
                               and b.ordr_ymd is not null
                               and b.cncl_dt is null
                               and a.ptno = b.ptno
                               and a.ordr_prrn_ymd = b.ordr_prrn_ymd
                               and a.inpc_cd in ('AM','RR','MA1')
                               AND (-- AM, RR의 경우는 응답한 것만 저장되었으므로, 모두 범위에 포함
                                      (a.inpc_cd = 'AM'  and a.item_sno between 1   and 500)
                                   OR (a.inpc_cd = 'RR'  and a.item_sno between 1   and 300)
                                   OR (a.inpc_cd = 'MA1' and a.item_sno between 228 and 295)
                                   )
                               and b.ptno not in (
                                                  &not_in_ptno
                                                 )
                               and b.rprs_apnt_no = a.rprs_apnt_no
                             group by a.PTNO
                                 , a.ordr_prrn_ymd
                                 , a.inpc_cd
                           ) a
                         , 스키마.3E3C23302E333E0E28@SMISR_스키마 f
                         , 스키마.0E5B5B285B28402857@SMISR_스키마 b
                     where f.ptno = a.ptno
                       and f.ordr_prrn_ymd = a.ordr_prrn_ymd
                       and f.inpc_cd = a.inpc_cd
                       AND (-- AM, RR의 경우는 응답한 것만 저장되었으므로, 모두 범위에 포함
                              (f.inpc_cd = 'AM'  and f.item_sno between 1   and 500)
                           OR (f.inpc_cd = 'RR'  and f.item_sno between 1   and 300)
                           OR (f.inpc_cd = 'MA1' and f.item_sno between 228 and 295)
                           )
                       and a.ptno = b.ptno
                     group by f.rprs_apnt_no
                         , a.PTNO
                         , a.ordr_prrn_ymd
                         , f.inpc_cd
                         , b.gend_cd
                         , a.med
                   ) h           
           )
                
            loop
            begin   -- 데이터 update
                          update /*+ append */
                                 스키마.1543294D47144D302E333E0E28 a
                             set 
                                 MED                                   = drh."1" 
                               , MED_HYPERTENSION                      = drh."2" 
                               , TRT_MED_HYPERTENSION                  = drh."3" 
                               , MED_HYPERTENSION_DURATION             = drh."4" 
                               , MED_DIABETES                          = drh."5" 
                               , TRT_MED_DIABETES                      = drh."6" 
                               , MED_DIABETES_DURATION                 = drh."7" 
                               , MED_ASPIRIN                           = drh."8" 
                               , TRT_MED_ASPIRIN                       = drh."9" 
                               , MED_ASPIRIN_DURATION                  = drh."10"
                               , MED_NSAIDS                            = drh."11"
                               , TRT_MED_NSAIDS                        = drh."12"
                               , MED_NSAIDS_DURATION                   = drh."13"
                               , MED_CALCIUM                           = drh."14"
                               , TRT_MED_CALCIUM                       = drh."15"
                               , MED_CALCIUM_DURATION                  = drh."16"
                               , MED_IRON                              = drh."17"
                               , TRT_MED_IRON                          = drh."18"
                               , MED_IRON_DURATION                     = drh."19"
                               , MED_CAM                               = drh."20"
                               , TRT_MED_CAM                           = drh."21"
                               , MED_CAM_DURATION                      = drh."22"
                               , MED_BETA_CAROTENE                     = drh."23"
                               , MED_BETA_CAROTENE_DURATION            = drh."24"
                               , MED_MULTI_VITAMIN                     = drh."25"
                               , MED_MULTI_VITAMIN_DURATION            = drh."26"
                               , MED_VITAMIN_A                         = drh."27"
                               , MED_VITAMIN_A_DURATION                = drh."28"
                               , MED_VITAMIN_B                         = drh."29"
                               , MED_VITAMIN_B_DURATION                = drh."30"
                               , MED_VITAMIN_C                         = drh."31"
                               , MED_VITAMIN_C_DURATION                = drh."32"
                               , MED_VITAMIN_E                         = drh."33"
                               , MED_VITAMIN_E_DURATION                = drh."34"
                               , MED_OTHER_SUPPLEMENTS                 = drh."35"
                               , MED_OTHER_SUPPLEMENTS_DURATION        = drh."36"
                               , MED_HYPERLIPIDEMIA                    = drh."37"
                               , TRT_MED_HYPERLIPIDEMIA                = drh."38"
                               , MED_WARFARIN                          = drh."39"
                               , TRT_MED_WARFARIN                      = drh."40"
                               , MED_ANTICOAGULANT                     = drh."41"
                               , TRT_MED_ANTICOAGULANT                 = drh."42"
                               , MED_ARRHYTHMIA                        = drh."43"
                               , TRT_MED_ARRHYTHMIA                    = drh."44"
                               , MED_GI_DIGESTIVES                     = drh."45"
                               , TRT_MED_GI_DIGESTIVES                 = drh."46"
                               , MED_LIVER                             = drh."47"
                               , TRT_MED_LIVER                         = drh."48"
                               , MED_CONSTIPATION                      = drh."49"
                               , TRT_MED_CONSTIPATION                  = drh."50"
                               , MED_THYROID_DIS                       = drh."51"
                               , TRT_MED_THYROID_DIS                   = drh."52"
                               , MED_OSTEOPOROSIS                      = drh."53"
                               , TRT_MED_OSTEOPOROSIS                  = drh."54"
                               , MED_FEMALE_HORMONES                   = drh."55"
                               , TRT_MED_FEMALE_HORMONES               = drh."56"
                               , MED_BPH                               = drh."57"
                               , TRT_MED_BPH                           = drh."58"
                               , MED_RESPIRATORY_DIS                   = drh."59"
                               , TRT_MED_RESPIRATORY_DIS               = drh."60"
                               , MED_NUTRI_SUPPLEMENTS                 = drh."61"
                               , TRT_MED_NUTRI_SUPPLEMENTS             = drh."62"
                               , MED_SLEEPING_PILLS                    = drh."63"
                               , MED_SLEEPING_PILLS_DURATION           = drh."64"
                               , MED_PSYCHIATRIC                       = drh."65"
                               , TRT_MED_PSYCHIATRIC                   = drh."66"
                               , MED_OTHER                             = drh."67"
                               , TRT_MED_OTHER                         = drh."68"
                               , MED_OTHER_DURATION                    = drh."69"
                               , a.last_updt_dt                     = drh.last_updt_dt
                           where a.ptno = drh.ptno
                             and a.ordr_prrn_ymd = drh.ordr_prrn_ymd
                             and a.rprs_apnt_no = drh.rprs_apnt_no
                                 ;
                  
                         commit;
                       
                       upcnt := upcnt + 1;
                  
                       exception
                       when others then
                          rollback;
                          errcnt := errcnt + 1;
            
            end;
            end loop;
       
:var_msg2  := 'update '  || to_char(upcnt)    || ' 건';
:var_msg3  := 'error '   || to_char(errcnt)   || ' 건';
   
end ;
/
print var_msg2
print var_msg3
spool off;
     
-- 문진 정보 update, 가족력
-- 변수 길이가 길다는 에러메세지 때문에 변수를 숫자정보로 치환
-- 메시지 출력기능 추가. 메시지 확인은 F5를 눌러야 가능함
variable var_msg2 char(40);
variable var_msg3 char(40);
  
declare
    upcnt     number(10) := 0;
    errcnt    number(10) := 0;
        
begin
for drh in (-- 데이터 select
            select h.RPRS_APNT_NO                   as RPRS_APNT_NO
                 , h.PTNO                           as ptno
                 , h.ORDR_PRRN_YMD                  as ordr_prrn_ymd
                 , h.FAMILY                              as "1"   
                 , h.FH_HYPERTENSION_F                   as "2"   
                 , h.FH_HYPERTENSION_M                   as "3"   
                 , h.FH_HYPERTENSION_SIB                 as "4"   
                 , h.FH_HYPERTENSION_CH                  as "5"   
                 , h.FH_HYPERTENSION_FF                  as "6"   
                 , h.FH_HYPERTENSION_FM                  as "7"   
                 , h.FH_HYPERTENSION_MF                  as "8"   
                 , h.FH_HYPERTENSION_MM                  as "9"   
                 , h.FH_STROKE_F                         as "10"  
                 , h.FH_STROKE_M                         as "11"  
                 , h.FH_STROKE_SIB                       as "12"  
                 , h.FH_STROKE_CH                        as "13"  
                 , h.FH_STROKE_FF                        as "14"  
                 , h.FH_STROKE_FM                        as "15"  
                 , h.FH_STROKE_MF                        as "16"  
                 , h.FH_STROKE_MM                        as "17"  
                 , h.FH_DIABETES_F                       as "18"  
                 , h.FH_DIABETES_M                       as "19"  
                 , h.FH_DIABETES_SIB                     as "20"  
                 , h.FH_DIABETES_CH                      as "21"  
                 , h.FH_DIABETES_FF                      as "22"  
                 , h.FH_DIABETES_FM                      as "23"  
                 , h.FH_DIABETES_MF                      as "24"  
                 , h.FH_DIABETES_MM                      as "25"  
                 , h.FH_HEP_CIRRHOSIS_F                  as "26"  
                 , h.FH_HEP_CIRRHOSIS_M                  as "27"  
                 , h.FH_HEP_CIRRHOSIS_SIB                as "28"  
                 , h.FH_HEP_CIRRHOSIS_CH                 as "29"  
                 , h.FH_HEP_CIRRHOSIS_FF                 as "30"  
                 , h.FH_HEP_CIRRHOSIS_FM                 as "31"  
                 , h.FH_HEP_CIRRHOSIS_MF                 as "32"  
                 , h.FH_HEP_CIRRHOSIS_MM                 as "33"  
                 , h.FH_DEMENTIA_F                       as "34"  
                 , h.FH_DEMENTIA_M                       as "35"  
                 , h.FH_DEMENTIA_SIB                     as "36"  
                 , h.FH_DEMENTIA_CH                      as "37"  
                 , h.FH_DEMENTIA_FF                      as "38"  
                 , h.FH_DEMENTIA_FM                      as "39"  
                 , h.FH_DEMENTIA_MF                      as "40"  
                 , h.FH_DEMENTIA_MM                      as "41"  
                 , h.FH_TUBERCULOSIS_F                   as "42"  
                 , h.FH_TUBERCULOSIS_M                   as "43"  
                 , h.FH_TUBERCULOSIS_SIB                 as "44"  
                 , h.FH_TUBERCULOSIS_CH                  as "45"  
                 , h.FH_TUBERCULOSIS_FF                  as "46"  
                 , h.FH_TUBERCULOSIS_FM                  as "47"  
                 , h.FH_TUBERCULOSIS_MF                  as "48"  
                 , h.FH_TUBERCULOSIS_MM                  as "49"  
                 , h.FH_MI_F                             as "50"  
                 , h.FH_MI_M                             as "51"  
                 , h.FH_MI_SIB                           as "52"  
                 , h.FH_MI_CH                            as "53"  
                 , h.FH_MI_FF                            as "54"  
                 , h.FH_MI_FM                            as "55"  
                 , h.FH_MI_MF                            as "56"  
                 , h.FH_MI_MM                            as "57"  
                 , h.FH_ANGINA_F                         as "58"  
                 , h.FH_ANGINA_M                         as "59"  
                 , h.FH_ANGINA_SIB                       as "60"  
                 , h.FH_ANGINA_CH                        as "61"  
                 , h.FH_ANGINA_FF                        as "62"  
                 , h.FH_ANGINA_FM                        as "63"  
                 , h.FH_ANGINA_MF                        as "64"  
                 , h.FH_ANGINA_MM                        as "65"  
                 , h.FH_OTHER_CONGENITAL_MAL_F           as "66"  
                 , h.FH_OTHER_CONGENITAL_MAL_M           as "67"  
                 , h.FH_OTHER_CONGENITAL_MAL_SIB         as "68"  
                 , h.FH_OTHER_CONGENITAL_MAL_CH          as "69"  
                 , h.FH_OTHER_CONGENITAL_MAL_FF          as "70"  
                 , h.FH_OTHER_CONGENITAL_MAL_FM          as "71"  
                 , h.FH_OTHER_CONGENITAL_MAL_MF          as "72"  
                 , h.FH_OTHER_CONGENITAL_MAL_MM          as "73"  
                 , h.FH_CONGENITAL_HEART_DIS_F           as "74"  
                 , h.FH_CONGENITAL_HEART_DIS_M           as "75"  
                 , h.FH_CONGENITAL_HEART_DIS_SIB         as "76"  
                 , h.FH_CONGENITAL_HEART_DIS_CH          as "77"  
                 , h.FH_CONGENITAL_HEART_DIS_FF          as "78"  
                 , h.FH_CONGENITAL_HEART_DIS_FM          as "79"  
                 , h.FH_CONGENITAL_HEART_DIS_MF          as "80"  
                 , h.FH_CONGENITAL_HEART_DIS_MM          as "81"  
                 , h.FH_CLEFT_LIP_PALATE_F               as "82"  
                 , h.FH_CLEFT_LIP_PALATE_M               as "83"  
                 , h.FH_CLEFT_LIP_PALATE_SIB             as "84"  
                 , h.FH_CLEFT_LIP_PALATE_CH              as "85"  
                 , h.FH_CLEFT_LIP_PALATE_FF              as "86"  
                 , h.FH_CLEFT_LIP_PALATE_FM              as "87"  
                 , h.FH_CLEFT_LIP_PALATE_MF              as "88"  
                 , h.FH_CLEFT_LIP_PALATE_MM              as "89"  
                 , h.FH_CORONARY_DIS_F                   as "90"  
                 , h.FH_CORONARY_DIS_M                   as "91"  
                 , h.FH_CORONARY_DIS_SIB                 as "92"  
                 , h.FH_CORONARY_DIS_CH                  as "93"  
                 , h.FH_CORONARY_DIS_FF                  as "94"  
                 , h.FH_CORONARY_DIS_FM                  as "95"  
                 , h.FH_CORONARY_DIS_MF                  as "96"  
                 , h.FH_CORONARY_DIS_MM                  as "97"  
                 , h.FH_ASTHMA_COPD_F                    as "98"  
                 , h.FH_ASTHMA_COPD_M                    as "99"  
                 , h.FH_ASTHMA_COPD_SIB                  as "100" 
                 , h.FH_ASTHMA_COPD_CH                   as "101" 
                 , h.FH_ASTHMA_COPD_FF                   as "102" 
                 , h.FH_ASTHMA_COPD_FM                   as "103" 
                 , h.FH_ASTHMA_COPD_MF                   as "104" 
                 , h.FH_ASTHMA_COPD_MM                   as "105" 
                 , h.FH_CANCER_STOMACH_F                 as "106" 
                 , h.FH_CANCER_STOMACH_M                 as "107" 
                 , h.FH_CANCER_STOMACH_SIB               as "108" 
                 , h.FH_CANCER_STOMACH_CH                as "109" 
                 , h.FH_CANCER_STOMACH_FF                as "110" 
                 , h.FH_CANCER_STOMACH_FM                as "111" 
                 , h.FH_CANCER_STOMACH_MF                as "112" 
                 , h.FH_CANCER_STOMACH_MM                as "113" 
                 , h.FH_CANCER_BREAST_F                  as "114" 
                 , h.FH_CANCER_BREAST_M                  as "115" 
                 , h.FH_CANCER_BREAST_SIB                as "116" 
                 , h.FH_CANCER_BREAST_CH                 as "117" 
                 , h.FH_CANCER_BREAST_FF                 as "118" 
                 , h.FH_CANCER_BREAST_FM                 as "119" 
                 , h.FH_CANCER_BREAST_MF                 as "120" 
                 , h.FH_CANCER_BREAST_MM                 as "121" 
                 , h.FH_CANCER_COLORECTAL_F              as "122" 
                 , h.FH_CANCER_COLORECTAL_M              as "123" 
                 , h.FH_CANCER_COLORECTAL_SIB            as "124" 
                 , h.FH_CANCER_COLORECTAL_CH             as "125" 
                 , h.FH_CANCER_COLORECTAL_FF             as "126" 
                 , h.FH_CANCER_COLORECTAL_FM             as "127" 
                 , h.FH_CANCER_COLORECTAL_MF             as "128" 
                 , h.FH_CANCER_COLORECTAL_MM             as "129" 
                 , h.FH_CANCER_LUNG_F                    as "130" 
                 , h.FH_CANCER_LUNG_M                    as "131" 
                 , h.FH_CANCER_LUNG_SIB                  as "132" 
                 , h.FH_CANCER_LUNG_CH                   as "133" 
                 , h.FH_CANCER_LUNG_FF                   as "134" 
                 , h.FH_CANCER_LUNG_FM                   as "135" 
                 , h.FH_CANCER_LUNG_MF                   as "136" 
                 , h.FH_CANCER_LUNG_MM                   as "137" 
                 , h.FH_CANCER_UTERINE_F                 as "138" 
                 , h.FH_CANCER_UTERINE_M                 as "139" 
                 , h.FH_CANCER_UTERINE_SIB               as "140" 
                 , h.FH_CANCER_UTERINE_CH                as "141" 
                 , h.FH_CANCER_UTERINE_FF                as "142" 
                 , h.FH_CANCER_UTERINE_FM                as "143" 
                 , h.FH_CANCER_UTERINE_MF                as "144" 
                 , h.FH_CANCER_UTERINE_MM                as "145" 
                 , h.FH_CANCER_LIVER_F                   as "146" 
                 , h.FH_CANCER_LIVER_M                   as "147" 
                 , h.FH_CANCER_LIVER_SIB                 as "148" 
                 , h.FH_CANCER_LIVER_CH                  as "149" 
                 , h.FH_CANCER_LIVER_FF                  as "150" 
                 , h.FH_CANCER_LIVER_FM                  as "151" 
                 , h.FH_CANCER_LIVER_MF                  as "152" 
                 , h.FH_CANCER_LIVER_MM                  as "153" 
                 , h.FH_CANCER_THYROID_F                 as "154" 
                 , h.FH_CANCER_THYROID_M                 as "155" 
                 , h.FH_CANCER_THYROID_SIB               as "156" 
                 , h.FH_CANCER_THYROID_CH                as "157" 
                 , h.FH_CANCER_THYROID_FF                as "158" 
                 , h.FH_CANCER_THYROID_FM                as "159" 
                 , h.FH_CANCER_THYROID_MF                as "160" 
                 , h.FH_CANCER_THYROID_MM                as "161" 
                 , h.FH_CANCER_OVARY_F                   as "162" 
                 , h.FH_CANCER_OVARY_M                   as "163" 
                 , h.FH_CANCER_OVARY_SIB                 as "164" 
                 , h.FH_CANCER_OVARY_CH                  as "165" 
                 , h.FH_CANCER_OVARY_FF                  as "166" 
                 , h.FH_CANCER_OVARY_FM                  as "167" 
                 , h.FH_CANCER_OVARY_MF                  as "168" 
                 , h.FH_CANCER_OVARY_MM                  as "169" 
                 , h.FH_CANCER_CERVIX_F                  as "170" 
                 , h.FH_CANCER_CERVIX_M                  as "171" 
                 , h.FH_CANCER_CERVIX_SIB                as "172" 
                 , h.FH_CANCER_CERVIX_CH                 as "173" 
                 , h.FH_CANCER_CERVIX_FF                 as "174" 
                 , h.FH_CANCER_CERVIX_FM                 as "175" 
                 , h.FH_CANCER_CERVIX_MF                 as "176" 
                 , h.FH_CANCER_CERVIX_MM                 as "177" 
                 , h.FH_CANCER_GB_BILIARY_F              as "178" 
                 , h.FH_CANCER_GB_BILIARY_M              as "179" 
                 , h.FH_CANCER_GB_BILIARY_SIB            as "180" 
                 , h.FH_CANCER_GB_BILIARY_CH             as "181" 
                 , h.FH_CANCER_GB_BILIARY_FF             as "182" 
                 , h.FH_CANCER_GB_BILIARY_FM             as "183" 
                 , h.FH_CANCER_GB_BILIARY_MF             as "184" 
                 , h.FH_CANCER_GB_BILIARY_MM             as "185" 
                 , h.FH_CANCER_BLADDER_F                 as "186" 
                 , h.FH_CANCER_BLADDER_M                 as "187" 
                 , h.FH_CANCER_BLADDER_SIB               as "188" 
                 , h.FH_CANCER_BLADDER_CH                as "189" 
                 , h.FH_CANCER_BLADDER_FF                as "190" 
                 , h.FH_CANCER_BLADDER_FM                as "191" 
                 , h.FH_CANCER_BLADDER_MF                as "192" 
                 , h.FH_CANCER_BLADDER_MM                as "193" 
                 , h.FH_CANCER_ESOPHAGUS_F               as "194" 
                 , h.FH_CANCER_ESOPHAGUS_M               as "195" 
                 , h.FH_CANCER_ESOPHAGUS_SIB             as "196" 
                 , h.FH_CANCER_ESOPHAGUS_CH              as "197" 
                 , h.FH_CANCER_ESOPHAGUS_FF              as "198" 
                 , h.FH_CANCER_ESOPHAGUS_FM              as "199" 
                 , h.FH_CANCER_ESOPHAGUS_MF              as "200" 
                 , h.FH_CANCER_ESOPHAGUS_MM              as "201" 
                 , h.FH_CANCER_PROSTATE_F                as "202" 
                 , h.FH_CANCER_PROSTATE_M                as "203" 
                 , h.FH_CANCER_PROSTATE_SIB              as "204" 
                 , h.FH_CANCER_PROSTATE_CH               as "205" 
                 , h.FH_CANCER_PROSTATE_FF               as "206" 
                 , h.FH_CANCER_PROSTATE_FM               as "207" 
                 , h.FH_CANCER_PROSTATE_MF               as "208" 
                 , h.FH_CANCER_PROSTATE_MM               as "209" 
                 , h.FH_CANCER_PANCREAS_F                as "210" 
                 , h.FH_CANCER_PANCREAS_M                as "211" 
                 , h.FH_CANCER_PANCREAS_SIB              as "212" 
                 , h.FH_CANCER_PANCREAS_CH               as "213" 
                 , h.FH_CANCER_PANCREAS_FF               as "214" 
                 , h.FH_CANCER_PANCREAS_FM               as "215" 
                 , h.FH_CANCER_PANCREAS_MF               as "216" 
                 , h.FH_CANCER_PANCREAS_MM               as "217" 
                 , h.FH_CANCER_OTHER_F                   as "218" 
                 , h.FH_CANCER_OTHER_M                   as "219" 
                 , h.FH_CANCER_OTHER_SIB                 as "220" 
                 , h.FH_CANCER_OTHER_CH                  as "221" 
                 , h.FH_CANCER_OTHER_FF                  as "222" 
                 , h.FH_CANCER_OTHER_FM                  as "223" 
                 , h.FH_CANCER_OTHER_MF                  as "224" 
                 , h.FH_CANCER_OTHER_MM                  as "225" 
                 , sysdate                          as last_updt_dt
              from (-- 가족력
                    select /*+ index(f 3E3C23302E333E0E28_pk) */
                           f.rprs_apnt_no
                         , a.PTNO
                         , a.ordr_prrn_ymd
                         , f.inpc_cd
                         , b.gend_cd
                         , a.family
                    /* 가족력 - 고혈압 */
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM152Y',SUBSTR(f.inqy_rspn_ctn1,1,1)
                                                                                ,'AM152' ,SUBSTR(f.inqy_rspn_ctn1,1,1)
                                                                                ,'MA1385Y','1','0')),'')
                                 ) fh_hypertension_f
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM152Y',SUBSTR(f.inqy_rspn_ctn1,2,1)
                                                                                ,'AM152' ,SUBSTR(f.inqy_rspn_ctn1,2,1)
                                                                                ,'MA1386Y','1','0')),'')
                                 ) fh_hypertension_m
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM152Y',SUBSTR(f.inqy_rspn_ctn1,3,1)
                                                                                ,'AM152' ,SUBSTR(f.inqy_rspn_ctn1,3,1)
                                                                                ,'MA1387Y','1','0')),'')
                                 ) fh_hypertension_sib
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM152Y',SUBSTR(f.inqy_rspn_ctn1,4,1)
                                                                                ,'AM152' ,SUBSTR(f.inqy_rspn_ctn1,4,1)
                                                                                ,'MA1388Y','1','0')),'')
                                 ) fh_hypertension_ch
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM152Y',SUBSTR(f.inqy_rspn_ctn1,5,1)
                                                                                ,'AM152' ,SUBSTR(f.inqy_rspn_ctn1,5,1)
                                                                                ,'MA1389Y','1','0')),'')
                                 ) fh_hypertension_ff
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM152Y',SUBSTR(f.inqy_rspn_ctn1,6,1)
                                                                                ,'AM152' ,SUBSTR(f.inqy_rspn_ctn1,6,1)
                                                                                ,'MA1390Y','1','0')),'')
                                 ) fh_hypertension_fm
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM152Y',SUBSTR(f.inqy_rspn_ctn1,7,1)
                                                                                ,'AM152' ,SUBSTR(f.inqy_rspn_ctn1,7,1)
                                                                                ,'MA1391Y','1','0')),'')
                                 ) fh_hypertension_mf
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM152Y',SUBSTR(f.inqy_rspn_ctn1,8,1)
                                                                                ,'AM152' ,SUBSTR(f.inqy_rspn_ctn1,8,1)
                                                                                ,'MA1392Y','1','0')),'')
                                 ) fh_hypertension_mm
                    /* 가족력 - 뇌졸중 */
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM153Y',SUBSTR(f.inqy_rspn_ctn1,1,1)
                                                                                ,'AM153' ,SUBSTR(f.inqy_rspn_ctn1,1,1)
                                                                                ,'MA1412Y','1','0')),'')
                                 ) fh_stroke_f
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM153Y',SUBSTR(f.inqy_rspn_ctn1,2,1)
                                                                                ,'AM153' ,SUBSTR(f.inqy_rspn_ctn1,2,1)
                                                                                ,'MA1413Y','1','0')),'')
                                 ) fh_stroke_m
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM153Y',SUBSTR(f.inqy_rspn_ctn1,3,1)
                                                                                ,'AM153' ,SUBSTR(f.inqy_rspn_ctn1,3,1)
                                                                                ,'MA1414Y','1','0')),'')
                                 ) fh_stroke_sib
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM153Y',SUBSTR(f.inqy_rspn_ctn1,4,1)
                                                                                ,'AM153' ,SUBSTR(f.inqy_rspn_ctn1,4,1)
                                                                                ,'MA1415Y','1','0')),'')
                                 ) fh_stroke_ch
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM153Y',SUBSTR(f.inqy_rspn_ctn1,5,1)
                                                                                ,'AM153' ,SUBSTR(f.inqy_rspn_ctn1,5,1)
                                                                                ,'MA1416Y','1','0')),'')
                                 ) fh_stroke_ff
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM153Y',SUBSTR(f.inqy_rspn_ctn1,6,1)
                                                                                ,'AM153' ,SUBSTR(f.inqy_rspn_ctn1,6,1)
                                                                                ,'MA1417Y','1','0')),'')
                                 ) fh_stroke_fm
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM153Y',SUBSTR(f.inqy_rspn_ctn1,7,1)
                                                                                ,'AM153' ,SUBSTR(f.inqy_rspn_ctn1,7,1)
                                                                                ,'MA1418Y','1','0')),'')
                                 ) fh_stroke_mf
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM153Y',SUBSTR(f.inqy_rspn_ctn1,8,1)
                                                                                ,'AM153' ,SUBSTR(f.inqy_rspn_ctn1,8,1)
                                                                                ,'MA1419Y','1','0')),'')
                                 ) fh_stroke_mm
                    /* 가족력 - 당뇨병 */
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM151Y',SUBSTR(f.inqy_rspn_ctn1,1,1)
                                                                                ,'AM151' ,SUBSTR(f.inqy_rspn_ctn1,1,1)
                                                                                ,'MA1394Y','1','0')),'')
                                 ) fh_diabetes_f
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM151Y',SUBSTR(f.inqy_rspn_ctn1,2,1)
                                                                                ,'AM151' ,SUBSTR(f.inqy_rspn_ctn1,2,1)
                                                                                ,'MA1395Y','1','0')),'')
                                 ) fh_diabetes_m
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM151Y',SUBSTR(f.inqy_rspn_ctn1,3,1)
                                                                                ,'AM151' ,SUBSTR(f.inqy_rspn_ctn1,3,1)
                                                                                ,'MA1396Y','1','0')),'')
                                 ) fh_diabetes_sib
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM151Y',SUBSTR(f.inqy_rspn_ctn1,4,1)
                                                                                ,'AM151' ,SUBSTR(f.inqy_rspn_ctn1,4,1)
                                                                                ,'MA1397Y','1','0')),'')
                                 ) fh_diabetes_ch
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM151Y',SUBSTR(f.inqy_rspn_ctn1,5,1)
                                                                                ,'AM151' ,SUBSTR(f.inqy_rspn_ctn1,5,1)
                                                                                ,'MA1398Y','1','0')),'')
                                 ) fh_diabetes_ff
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM151Y',SUBSTR(f.inqy_rspn_ctn1,6,1)
                                                                                ,'AM151' ,SUBSTR(f.inqy_rspn_ctn1,6,1)
                                                                                ,'MA1399Y','1','0')),'')
                                 ) fh_diabetes_fm
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM151Y',SUBSTR(f.inqy_rspn_ctn1,7,1)
                                                                                ,'AM151' ,SUBSTR(f.inqy_rspn_ctn1,7,1)
                                                                                ,'MA1400Y','1','0')),'')
                                 ) fh_diabetes_mf
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM151Y',SUBSTR(f.inqy_rspn_ctn1,8,1)
                                                                                ,'AM151' ,SUBSTR(f.inqy_rspn_ctn1,8,1)
                                                                                ,'MA1401Y','1','0')),'')
                                 ) fh_diabetes_mm
                    /* 가족력 - 만성간염/간경변 */
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM155Y',SUBSTR(f.inqy_rspn_ctn1,1,1)
                                                                                ,'AM155' ,SUBSTR(f.inqy_rspn_ctn1,1,1)
                                                                                ,'MA1430Y','1','0')),'')
                                 ) fh_hep_cirrhosis_f
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM155Y',SUBSTR(f.inqy_rspn_ctn1,2,1)
                                                                                ,'AM155' ,SUBSTR(f.inqy_rspn_ctn1,2,1)
                                                                                ,'MA1431Y','1','0')),'')
                                 ) fh_hep_cirrhosis_m
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM155Y',SUBSTR(f.inqy_rspn_ctn1,3,1)
                                                                                ,'AM155' ,SUBSTR(f.inqy_rspn_ctn1,3,1)
                                                                                ,'MA1432Y','1','0')),'')
                                 ) fh_hep_cirrhosis_sib
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM155Y',SUBSTR(f.inqy_rspn_ctn1,4,1)
                                                                                ,'AM155' ,SUBSTR(f.inqy_rspn_ctn1,4,1)
                                                                                ,'MA1433Y','1','0')),'')
                                 ) fh_hep_cirrhosis_ch
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM155Y',SUBSTR(f.inqy_rspn_ctn1,5,1)
                                                                                ,'AM155' ,SUBSTR(f.inqy_rspn_ctn1,5,1)
                                                                                ,'MA1434Y','1','0')),'')
                                 ) fh_hep_cirrhosis_ff
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM155Y',SUBSTR(f.inqy_rspn_ctn1,6,1)
                                                                                ,'AM155' ,SUBSTR(f.inqy_rspn_ctn1,6,1)
                                                                                ,'MA1435Y','1','0')),'')
                                 ) fh_hep_cirrhosis_fm
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM155Y',SUBSTR(f.inqy_rspn_ctn1,7,1)
                                                                                ,'AM155' ,SUBSTR(f.inqy_rspn_ctn1,7,1)
                                                                                ,'MA1436Y','1','0')),'')
                                 ) fh_hep_cirrhosis_mf
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM155Y',SUBSTR(f.inqy_rspn_ctn1,8,1)
                                                                                ,'AM155' ,SUBSTR(f.inqy_rspn_ctn1,8,1)
                                                                                ,'MA1437Y','1','0')),'')
                                 ) fh_hep_cirrhosis_mm
                    /* 가족력 - 치매 */
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM154Y',SUBSTR(f.inqy_rspn_ctn1,1,1)
                                                                                ,'AM154' ,SUBSTR(f.inqy_rspn_ctn1,1,1)
                                                                                ,'MA1421Y','1','0')),'')
                                 ) fh_dementia_f
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM154Y',SUBSTR(f.inqy_rspn_ctn1,2,1)
                                                                                ,'AM154' ,SUBSTR(f.inqy_rspn_ctn1,2,1)
                                                                                ,'MA1422Y','1','0')),'')
                                 ) fh_dementia_m
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM154Y',SUBSTR(f.inqy_rspn_ctn1,3,1)
                                                                                ,'AM154' ,SUBSTR(f.inqy_rspn_ctn1,3,1)
                                                                                ,'MA1423Y','1','0')),'')
                                 ) fh_dementia_sib
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM154Y',SUBSTR(f.inqy_rspn_ctn1,4,1)
                                                                                ,'AM154' ,SUBSTR(f.inqy_rspn_ctn1,4,1)
                                                                                ,'MA1424Y','1','0')),'')
                                 ) fh_dementia_ch
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM154Y',SUBSTR(f.inqy_rspn_ctn1,5,1)
                                                                                ,'AM154' ,SUBSTR(f.inqy_rspn_ctn1,5,1)
                                                                                ,'MA1425Y','1','0')),'')
                                 ) fh_dementia_ff
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM154Y',SUBSTR(f.inqy_rspn_ctn1,6,1)
                                                                                ,'AM154' ,SUBSTR(f.inqy_rspn_ctn1,6,1)
                                                                                ,'MA1426Y','1','0')),'')
                                 ) fh_dementia_fm
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM154Y',SUBSTR(f.inqy_rspn_ctn1,7,1)
                                                                                ,'AM154' ,SUBSTR(f.inqy_rspn_ctn1,7,1)
                                                                                ,'MA1427Y','1','0')),'')
                                 ) fh_dementia_mf
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM154Y',SUBSTR(f.inqy_rspn_ctn1,8,1)
                                                                                ,'AM154' ,SUBSTR(f.inqy_rspn_ctn1,8,1)
                                                                                ,'MA1428Y','1','0')),'')
                                 ) fh_dementia_mm
                    /* 가족력 - 결핵 */
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM150Y',SUBSTR(f.inqy_rspn_ctn1,1,1)
                                                                                ,'AM150' ,SUBSTR(f.inqy_rspn_ctn1,1,1),'0')),'')
                                           ,''
                                 ) fh_tuberculosis_f
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM150Y',SUBSTR(f.inqy_rspn_ctn1,2,1)
                                                                                ,'AM150' ,SUBSTR(f.inqy_rspn_ctn1,2,1),'0')),'')
                                           ,''
                                 ) fh_tuberculosis_m
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM150Y',SUBSTR(f.inqy_rspn_ctn1,3,1)
                                                                                ,'AM150' ,SUBSTR(f.inqy_rspn_ctn1,3,1),'0')),'')
                                           ,''
                                 ) fh_tuberculosis_sib
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM150Y',SUBSTR(f.inqy_rspn_ctn1,4,1)
                                                                                ,'AM150' ,SUBSTR(f.inqy_rspn_ctn1,4,1),'0')),'')
                                           ,''
                                 ) fh_tuberculosis_ch
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM150Y',SUBSTR(f.inqy_rspn_ctn1,5,1)
                                                                                ,'AM150' ,SUBSTR(f.inqy_rspn_ctn1,5,1),'0')),'')
                                           ,''
                                 ) fh_tuberculosis_ff
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM150Y',SUBSTR(f.inqy_rspn_ctn1,6,1)
                                                                                ,'AM150' ,SUBSTR(f.inqy_rspn_ctn1,6,1),'0')),'')
                                           ,''
                                 ) fh_tuberculosis_fm
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM150Y',SUBSTR(f.inqy_rspn_ctn1,7,1)
                                                                                ,'AM150' ,SUBSTR(f.inqy_rspn_ctn1,7,1),'0')),'')
                                           ,''
                                 ) fh_tuberculosis_mf
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM150Y',SUBSTR(f.inqy_rspn_ctn1,8,1)
                                                                                ,'AM150' ,SUBSTR(f.inqy_rspn_ctn1,8,1),'0')),'')
                                           ,''
                                 ) fh_tuberculosis_mm
                    /* 가족력 - 심근경색 */
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM156Y',SUBSTR(f.inqy_rspn_ctn1,1,1)
                                                                                ,'AM156' ,SUBSTR(f.inqy_rspn_ctn1,1,1),'0')),'')
                                           ,''
                                 ) fh_mi_f
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM156Y',SUBSTR(f.inqy_rspn_ctn1,2,1)
                                                                                ,'AM156' ,SUBSTR(f.inqy_rspn_ctn1,2,1),'0')),'')
                                           ,''
                                 ) fh_mi_m
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM156Y',SUBSTR(f.inqy_rspn_ctn1,3,1)
                                                                                ,'AM156' ,SUBSTR(f.inqy_rspn_ctn1,3,1),'0')),'')
                                           ,''
                                 ) fh_mi_sib
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM156Y',SUBSTR(f.inqy_rspn_ctn1,4,1)
                                                                                ,'AM156' ,SUBSTR(f.inqy_rspn_ctn1,4,1),'0')),'')
                                           ,''
                                 ) fh_mi_ch
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM156Y',SUBSTR(f.inqy_rspn_ctn1,5,1)
                                                                                ,'AM156' ,SUBSTR(f.inqy_rspn_ctn1,5,1),'0')),'')
                                           ,''
                                 ) fh_mi_ff
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM156Y',SUBSTR(f.inqy_rspn_ctn1,6,1)
                                                                                ,'AM156' ,SUBSTR(f.inqy_rspn_ctn1,6,1),'0')),'')
                                           ,''
                                 ) fh_mi_fm
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM156Y',SUBSTR(f.inqy_rspn_ctn1,7,1)
                                                                                ,'AM156' ,SUBSTR(f.inqy_rspn_ctn1,7,1),'0')),'')
                                           ,''
                                 ) fh_mi_mf
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM156Y',SUBSTR(f.inqy_rspn_ctn1,8,1)
                                                                                ,'AM156' ,SUBSTR(f.inqy_rspn_ctn1,8,1),'0')),'')
                                           ,''
                                 ) fh_mi_mm
                    /* 가족력 - 협심증 */
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM157Y',SUBSTR(f.inqy_rspn_ctn1,1,1)
                                                                                ,'AM157' ,SUBSTR(f.inqy_rspn_ctn1,1,1),'0')),'')
                                           ,''
                                 ) fh_angina_f
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM157Y',SUBSTR(f.inqy_rspn_ctn1,2,1)
                                                                                ,'AM157' ,SUBSTR(f.inqy_rspn_ctn1,2,1),'0')),'')
                                           ,''
                                 ) fh_angina_m
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM157Y',SUBSTR(f.inqy_rspn_ctn1,3,1)
                                                                                ,'AM157' ,SUBSTR(f.inqy_rspn_ctn1,3,1),'0')),'')
                                           ,''
                                 ) fh_angina_sib
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM157Y',SUBSTR(f.inqy_rspn_ctn1,4,1)
                                                                                ,'AM157' ,SUBSTR(f.inqy_rspn_ctn1,4,1),'0')),'')
                                           ,''
                                 ) fh_angina_ch
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM157Y',SUBSTR(f.inqy_rspn_ctn1,5,1)
                                                                                ,'AM157' ,SUBSTR(f.inqy_rspn_ctn1,5,1),'0')),'')
                                           ,''
                                 ) fh_angina_ff
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM157Y',SUBSTR(f.inqy_rspn_ctn1,6,1)
                                                                                ,'AM157' ,SUBSTR(f.inqy_rspn_ctn1,6,1),'0')),'')
                                           ,''
                                 ) fh_angina_fm
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM157Y',SUBSTR(f.inqy_rspn_ctn1,7,1)
                                                                                ,'AM157' ,SUBSTR(f.inqy_rspn_ctn1,7,1),'0')),'')
                                           ,''
                                 ) fh_angina_mf
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM157Y',SUBSTR(f.inqy_rspn_ctn1,8,1)
                                                                                ,'AM157' ,SUBSTR(f.inqy_rspn_ctn1,8,1),'0')),'')
                                           ,''
                                 ) fh_angina_mm
                    /* 가족력 - 기타 선천성 기형 */
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM160Y',SUBSTR(f.inqy_rspn_ctn1,1,1)
                                                                                ,'AM160' ,SUBSTR(f.inqy_rspn_ctn1,1,1),'0')),'')
                                           ,''
                                 ) fh_other_congenital_mal_f
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM160Y',SUBSTR(f.inqy_rspn_ctn1,2,1)
                                                                                ,'AM160' ,SUBSTR(f.inqy_rspn_ctn1,2,1),'0')),'')
                                           ,''
                                 ) fh_other_congenital_mal_m
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM160Y',SUBSTR(f.inqy_rspn_ctn1,3,1)
                                                                                ,'AM160' ,SUBSTR(f.inqy_rspn_ctn1,3,1),'0')),'')
                                           ,''
                                 ) fh_other_congenital_mal_sib
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM160Y',SUBSTR(f.inqy_rspn_ctn1,4,1)
                                                                                ,'AM160' ,SUBSTR(f.inqy_rspn_ctn1,4,1),'0')),'')
                                           ,''
                                 ) fh_other_congenital_mal_ch
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM160Y',SUBSTR(f.inqy_rspn_ctn1,5,1)
                                                                                ,'AM160' ,SUBSTR(f.inqy_rspn_ctn1,5,1),'0')),'')
                                           ,''
                                 ) fh_other_congenital_mal_ff
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM160Y',SUBSTR(f.inqy_rspn_ctn1,6,1)
                                                                                ,'AM160' ,SUBSTR(f.inqy_rspn_ctn1,6,1),'0')),'')
                                           ,''
                                 ) fh_other_congenital_mal_fm
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM160Y',SUBSTR(f.inqy_rspn_ctn1,7,1)
                                                                                ,'AM160' ,SUBSTR(f.inqy_rspn_ctn1,7,1),'0')),'')
                                           ,''
                                 ) fh_other_congenital_mal_mf
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM160Y',SUBSTR(f.inqy_rspn_ctn1,8,1)
                                                                                ,'AM160' ,SUBSTR(f.inqy_rspn_ctn1,8,1),'0')),'')
                                           ,''
                                 ) fh_other_congenital_mal_mm
                    /* 가족력 - 심장기형 */
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM158Y',SUBSTR(f.inqy_rspn_ctn1,1,1)
                                                                                ,'AM158' ,SUBSTR(f.inqy_rspn_ctn1,1,1),'0')),'')
                                           ,''
                                 ) fh_congenital_heart_dis_f
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM158Y',SUBSTR(f.inqy_rspn_ctn1,2,1)
                                                                                ,'AM158' ,SUBSTR(f.inqy_rspn_ctn1,2,1),'0')),'')
                                           ,''
                                 ) fh_congenital_heart_dis_m
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM158Y',SUBSTR(f.inqy_rspn_ctn1,3,1)
                                                                                ,'AM158' ,SUBSTR(f.inqy_rspn_ctn1,3,1),'0')),'')
                                           ,''
                                 ) fh_congenital_heart_dis_sib
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM158Y',SUBSTR(f.inqy_rspn_ctn1,4,1)
                                                                                ,'AM158' ,SUBSTR(f.inqy_rspn_ctn1,4,1),'0')),'')
                                           ,''
                                 ) fh_congenital_heart_dis_ch
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM158Y',SUBSTR(f.inqy_rspn_ctn1,5,1)
                                                                                ,'AM158' ,SUBSTR(f.inqy_rspn_ctn1,5,1),'0')),'')
                                           ,''
                                 ) fh_congenital_heart_dis_ff
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM158Y',SUBSTR(f.inqy_rspn_ctn1,6,1)
                                                                                ,'AM158' ,SUBSTR(f.inqy_rspn_ctn1,6,1),'0')),'')
                                           ,''
                                 ) fh_congenital_heart_dis_fm
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM158Y',SUBSTR(f.inqy_rspn_ctn1,7,1)
                                                                                ,'AM158' ,SUBSTR(f.inqy_rspn_ctn1,7,1),'0')),'')
                                           ,''
                                 ) fh_congenital_heart_dis_mf
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM158Y',SUBSTR(f.inqy_rspn_ctn1,8,1)
                                                                                ,'AM158' ,SUBSTR(f.inqy_rspn_ctn1,8,1),'0')),'')
                                           ,''
                                 ) fh_congenital_heart_dis_mm
                    /* 가족력 - 언청이 */
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM159Y',SUBSTR(f.inqy_rspn_ctn1,1,1)
                                                                                ,'AM159' ,SUBSTR(f.inqy_rspn_ctn1,1,1),'0')),'')
                                           ,''
                                 ) fh_cleft_lip_palate_f
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM159Y',SUBSTR(f.inqy_rspn_ctn1,2,1)
                                                                                ,'AM159' ,SUBSTR(f.inqy_rspn_ctn1,2,1),'0')),'')
                                           ,''
                                 ) fh_cleft_lip_palate_m
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM159Y',SUBSTR(f.inqy_rspn_ctn1,3,1)
                                                                                ,'AM159' ,SUBSTR(f.inqy_rspn_ctn1,3,1),'0')),'')
                                           ,''
                                 ) fh_cleft_lip_palate_sib
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM159Y',SUBSTR(f.inqy_rspn_ctn1,4,1)
                                                                                ,'AM159' ,SUBSTR(f.inqy_rspn_ctn1,4,1),'0')),'')
                                           ,''
                                 ) fh_cleft_lip_palate_ch
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM159Y',SUBSTR(f.inqy_rspn_ctn1,5,1)
                                                                                ,'AM159' ,SUBSTR(f.inqy_rspn_ctn1,5,1),'0')),'')
                                           ,''
                                 ) fh_cleft_lip_palate_ff
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM159Y',SUBSTR(f.inqy_rspn_ctn1,6,1)
                                                                                ,'AM159' ,SUBSTR(f.inqy_rspn_ctn1,6,1),'0')),'')
                                           ,''
                                 ) fh_cleft_lip_palate_fm
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM159Y',SUBSTR(f.inqy_rspn_ctn1,7,1)
                                                                                ,'AM159' ,SUBSTR(f.inqy_rspn_ctn1,7,1),'0')),'')
                                           ,''
                                 ) fh_cleft_lip_palate_mf
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM159Y',SUBSTR(f.inqy_rspn_ctn1,8,1)
                                                                                ,'AM159' ,SUBSTR(f.inqy_rspn_ctn1,8,1),'0')),'')
                                           ,''
                                 ) fh_cleft_lip_palate_mm
                    /* 가족력 - 심근경색/협심증등 심장질환 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1403Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_coronary_dis_f
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1404Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_coronary_dis_m
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1405Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_coronary_dis_sib
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1406Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_coronary_dis_ch
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1407Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_coronary_dis_ff
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1408Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_coronary_dis_fm
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1409Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_coronary_dis_mf
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1410Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_coronary_dis_mm
                    /* 가족력 - 천식/COPD */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1439Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_asthma_copd_f
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1440Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_asthma_copd_m
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1441Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_asthma_copd_sib
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1442Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_asthma_copd_ch
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1443Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_asthma_copd_ff
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1444Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_asthma_copd_fm
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1445Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_asthma_copd_mf
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1446Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_asthma_copd_mm
                    /* 가족력 - 위암 */
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM161Y',SUBSTR(f.inqy_rspn_ctn1,1,1)
                                                                                ,'AM161' ,SUBSTR(f.inqy_rspn_ctn1,1,1)
                                                                                ,'MA1448Y','1','0')),'')
                                 ) fh_cancer_stomach_f
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM161Y',SUBSTR(f.inqy_rspn_ctn1,2,1)
                                                                                ,'AM161' ,SUBSTR(f.inqy_rspn_ctn1,2,1)
                                                                                ,'MA1449Y','1','0')),'')
                                 ) fh_cancer_stomach_m
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM161Y',SUBSTR(f.inqy_rspn_ctn1,3,1)
                                                                                ,'AM161' ,SUBSTR(f.inqy_rspn_ctn1,3,1)
                                                                                ,'MA1450Y','1','0')),'')
                                 ) fh_cancer_stomach_sib
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM161Y',SUBSTR(f.inqy_rspn_ctn1,4,1)
                                                                                ,'AM161' ,SUBSTR(f.inqy_rspn_ctn1,4,1)
                                                                                ,'MA1451Y','1','0')),'')
                                 ) fh_cancer_stomach_ch
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM161Y',SUBSTR(f.inqy_rspn_ctn1,5,1)
                                                                                ,'AM161' ,SUBSTR(f.inqy_rspn_ctn1,5,1)
                                                                                ,'MA1452Y','1','0')),'')
                                 ) fh_cancer_stomach_ff
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM161Y',SUBSTR(f.inqy_rspn_ctn1,6,1)
                                                                                ,'AM161' ,SUBSTR(f.inqy_rspn_ctn1,6,1)
                                                                                ,'MA1453Y','1','0')),'')
                                 ) fh_cancer_stomach_fm
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM161Y',SUBSTR(f.inqy_rspn_ctn1,7,1)
                                                                                ,'AM161' ,SUBSTR(f.inqy_rspn_ctn1,7,1)
                                                                                ,'MA1454Y','1','0')),'')
                                 ) fh_cancer_stomach_mf
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM161Y',SUBSTR(f.inqy_rspn_ctn1,8,1)
                                                                                ,'AM161' ,SUBSTR(f.inqy_rspn_ctn1,8,1)
                                                                                ,'MA1455Y','1','0')),'')
                                 ) fh_cancer_stomach_mm
                    /* 가족력 - 유방암 */
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM162Y',SUBSTR(f.inqy_rspn_ctn1,1,1)
                                                                                ,'AM162' ,SUBSTR(f.inqy_rspn_ctn1,1,1)
                                                                                ,'MA1484Y','1','0')),'')
                                 ) fh_cancer_breast_f
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM162Y',SUBSTR(f.inqy_rspn_ctn1,2,1)
                                                                                ,'AM162' ,SUBSTR(f.inqy_rspn_ctn1,2,1)
                                                                                ,'MA1485Y','1','0')),'')
                                 ) fh_cancer_breast_m
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM162Y',SUBSTR(f.inqy_rspn_ctn1,3,1)
                                                                                ,'AM162' ,SUBSTR(f.inqy_rspn_ctn1,3,1)
                                                                                ,'MA1486Y','1','0')),'')
                                 ) fh_cancer_breast_sib
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM162Y',SUBSTR(f.inqy_rspn_ctn1,4,1)
                                                                                ,'AM162' ,SUBSTR(f.inqy_rspn_ctn1,4,1)
                                                                                ,'MA1487Y','1','0')),'')
                                 ) fh_cancer_breast_ch
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM162Y',SUBSTR(f.inqy_rspn_ctn1,5,1)
                                                                                ,'AM162' ,SUBSTR(f.inqy_rspn_ctn1,5,1)
                                                                                ,'MA1488Y','1','0')),'')
                                 ) fh_cancer_breast_ff
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM162Y',SUBSTR(f.inqy_rspn_ctn1,6,1)
                                                                                ,'AM162' ,SUBSTR(f.inqy_rspn_ctn1,6,1)
                                                                                ,'MA1489Y','1','0')),'')
                                 ) fh_cancer_breast_fm
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM162Y',SUBSTR(f.inqy_rspn_ctn1,7,1)
                                                                                ,'AM162' ,SUBSTR(f.inqy_rspn_ctn1,7,1)
                                                                                ,'MA1490Y','1','0')),'')
                                 ) fh_cancer_breast_mf
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM162Y',SUBSTR(f.inqy_rspn_ctn1,8,1)
                                                                                ,'AM162' ,SUBSTR(f.inqy_rspn_ctn1,8,1)
                                                                                ,'MA1491Y','1','0')),'')
                                 ) fh_cancer_breast_mm
                    /* 가족력 - 대장암/직장암 */
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM163Y',SUBSTR(f.inqy_rspn_ctn1,1,1)
                                                                                ,'AM163' ,SUBSTR(f.inqy_rspn_ctn1,1,1)
                                                                                ,'MA1475Y','1','0')),'')
                                 ) fh_cancer_colorectal_f
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM163Y',SUBSTR(f.inqy_rspn_ctn1,2,1)
                                                                                ,'AM163' ,SUBSTR(f.inqy_rspn_ctn1,2,1)
                                                                                ,'MA1476Y','1','0')),'')
                                 ) fh_cancer_colorectal_m
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM163Y',SUBSTR(f.inqy_rspn_ctn1,3,1)
                                                                                ,'AM163' ,SUBSTR(f.inqy_rspn_ctn1,3,1)
                                                                                ,'MA1477Y','1','0')),'')
                                 ) fh_cancer_colorectal_sib
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM163Y',SUBSTR(f.inqy_rspn_ctn1,4,1)
                                                                                ,'AM163' ,SUBSTR(f.inqy_rspn_ctn1,4,1)
                                                                                ,'MA1478Y','1','0')),'')
                                 ) fh_cancer_colorectal_ch
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM163Y',SUBSTR(f.inqy_rspn_ctn1,5,1)
                                                                                ,'AM163' ,SUBSTR(f.inqy_rspn_ctn1,5,1)
                                                                                ,'MA1479Y','1','0')),'')
                                 ) fh_cancer_colorectal_ff
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM163Y',SUBSTR(f.inqy_rspn_ctn1,6,1)
                                                                                ,'AM163' ,SUBSTR(f.inqy_rspn_ctn1,6,1)
                                                                                ,'MA1480Y','1','0')),'')
                                 ) fh_cancer_colorectal_fm
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM163Y',SUBSTR(f.inqy_rspn_ctn1,7,1)
                                                                                ,'AM163' ,SUBSTR(f.inqy_rspn_ctn1,7,1)
                                                                                ,'MA1481Y','1','0')),'')
                                 ) fh_cancer_colorectal_mf
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM163Y',SUBSTR(f.inqy_rspn_ctn1,8,1)
                                                                                ,'AM163' ,SUBSTR(f.inqy_rspn_ctn1,8,1)
                                                                                ,'MA1482Y','1','0')),'')
                                 ) fh_cancer_colorectal_mm
                    /* 가족력 - 폐암 */
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM164Y',SUBSTR(f.inqy_rspn_ctn1,1,1)
                                                                                ,'AM164' ,SUBSTR(f.inqy_rspn_ctn1,1,1)
                                                                                ,'MA1457Y','1','0')),'')
                                 ) fh_cancer_lung_f
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM164Y',SUBSTR(f.inqy_rspn_ctn1,2,1)
                                                                                ,'AM164' ,SUBSTR(f.inqy_rspn_ctn1,2,1)
                                                                                ,'MA1458Y','1','0')),'')
                                 ) fh_cancer_lung_m
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM164Y',SUBSTR(f.inqy_rspn_ctn1,3,1)
                                                                                ,'AM164' ,SUBSTR(f.inqy_rspn_ctn1,3,1)
                                                                                ,'MA1459Y','1','0')),'')
                                 ) fh_cancer_lung_sib
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM164Y',SUBSTR(f.inqy_rspn_ctn1,4,1)
                                                                                ,'AM164' ,SUBSTR(f.inqy_rspn_ctn1,4,1)
                                                                                ,'MA1460Y','1','0')),'')
                                 ) fh_cancer_lung_ch
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM164Y',SUBSTR(f.inqy_rspn_ctn1,5,1)
                                                                                ,'AM164' ,SUBSTR(f.inqy_rspn_ctn1,5,1)
                                                                                ,'MA1461Y','1','0')),'')
                                 ) fh_cancer_lung_ff
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM164Y',SUBSTR(f.inqy_rspn_ctn1,6,1)
                                                                                ,'AM164' ,SUBSTR(f.inqy_rspn_ctn1,6,1)
                                                                                ,'MA1462Y','1','0')),'')
                                 ) fh_cancer_lung_fm
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM164Y',SUBSTR(f.inqy_rspn_ctn1,7,1)
                                                                                ,'AM164' ,SUBSTR(f.inqy_rspn_ctn1,7,1)
                                                                                ,'MA1463Y','1','0')),'')
                                 ) fh_cancer_lung_mf
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM164Y',SUBSTR(f.inqy_rspn_ctn1,8,1)
                                                                                ,'AM164' ,SUBSTR(f.inqy_rspn_ctn1,8,1)
                                                                                ,'MA1464Y','1','0')),'')
                                 ) fh_cancer_lung_mm
                    /* 가족력 - 자궁암 */
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM165Y',SUBSTR(f.inqy_rspn_ctn1,1,1)
                                                                                ,'AM165' ,SUBSTR(f.inqy_rspn_ctn1,1,1),'0')),'')
                                           ,''
                                 ) fh_cancer_uterine_f
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM165Y',SUBSTR(f.inqy_rspn_ctn1,2,1)
                                                                                ,'AM165' ,SUBSTR(f.inqy_rspn_ctn1,2,1),'0')),'')
                                           ,''
                                 ) fh_cancer_uterine_m
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM165Y',SUBSTR(f.inqy_rspn_ctn1,3,1)
                                                                                ,'AM165' ,SUBSTR(f.inqy_rspn_ctn1,3,1),'0')),'')
                                           ,''
                                 ) fh_cancer_uterine_sib
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM165Y',SUBSTR(f.inqy_rspn_ctn1,4,1)
                                                                                ,'AM165' ,SUBSTR(f.inqy_rspn_ctn1,4,1),'0')),'')
                                           ,''
                                 ) fh_cancer_uterine_ch
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM165Y',SUBSTR(f.inqy_rspn_ctn1,5,1)
                                                                                ,'AM165' ,SUBSTR(f.inqy_rspn_ctn1,5,1),'0')),'')
                                           ,''
                                 ) fh_cancer_uterine_ff
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM165Y',SUBSTR(f.inqy_rspn_ctn1,6,1)
                                                                                ,'AM165' ,SUBSTR(f.inqy_rspn_ctn1,6,1),'0')),'')
                                           ,''
                                 ) fh_cancer_uterine_fm
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM165Y',SUBSTR(f.inqy_rspn_ctn1,7,1)
                                                                                ,'AM165' ,SUBSTR(f.inqy_rspn_ctn1,7,1),'0')),'')
                                           ,''
                                 ) fh_cancer_uterine_mf
                         , decode(f.inpc_cd,'MA1','9999'
                                           ,'RR' ,'9999'
                                           ,'AM' ,decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM165Y',SUBSTR(f.inqy_rspn_ctn1,8,1)
                                                                                ,'AM165' ,SUBSTR(f.inqy_rspn_ctn1,8,1),'0')),'')
                                           ,''
                                 ) fh_cancer_uterine_mm
                    /* 가족력 - 간암 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1466Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_liver_f
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1467Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_liver_m
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1468Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_liver_sib
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1469Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_liver_ch
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1470Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_liver_ff
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1471Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_liver_fm
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1472Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_liver_mf
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1473Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_liver_mm
                    /* 가족력 - 갑상선암 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1502Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_thyroid_f
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1503Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_thyroid_m
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1504Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_thyroid_sib
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1505Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_thyroid_ch
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1506Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_thyroid_ff
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1507Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_thyroid_fm
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1508Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_thyroid_mf
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1509Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_thyroid_mm
                    /* 가족력 - 난소암 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1538Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_ovary_f
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1539Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_ovary_m
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1540Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_ovary_sib
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1541Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_ovary_ch
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1542Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_ovary_ff
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1543Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_ovary_fm
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1544Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_ovary_mf
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1545Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_ovary_mm
                    /* 가족력 - 자궁경부암 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1493Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_cervix_f
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1494Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_cervix_m
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1495Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_cervix_sib
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1496Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_cervix_ch
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1497Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_cervix_ff
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1498Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_cervix_fm
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1499Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_cervix_mf
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1500Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_cervix_mm
                    /* 가족력 - 담낭/담도암 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1529Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_gb_biliary_f
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1530Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_gb_biliary_m
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1531Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_gb_biliary_sib
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1532Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_gb_biliary_ch
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1533Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_gb_biliary_ff
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1534Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_gb_biliary_fm
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1535Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_gb_biliary_mf
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1536Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_gb_biliary_mm
                    /* 가족력 - 방광암 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1511Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_bladder_f
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1512Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_bladder_m
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1513Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_bladder_sib
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1514Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_bladder_ch
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1515Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_bladder_ff
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1516Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_bladder_fm
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1517Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_bladder_mf
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1518Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_bladder_mm
                    /* 가족력 - 식도암 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1520Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_esophagus_f
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1521Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_esophagus_m
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1522Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_esophagus_sib
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1523Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_esophagus_ch
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1524Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_esophagus_ff
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1525Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_esophagus_fm
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1526Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_esophagus_mf
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1527Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_esophagus_mm
                    /* 가족력 - 전립선암 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1547Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_prostate_f
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1548Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_prostate_m
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1549Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_prostate_sib
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1550Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_prostate_ch
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1551Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_prostate_ff
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1552Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_prostate_fm
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1553Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_prostate_mf
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1554Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_prostate_mm
                    /* 가족력 - 췌장암 */
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1556Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_pancreas_f
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1557Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_pancreas_m
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1558Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_pancreas_sib
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1559Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_pancreas_ch
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1560Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_pancreas_ff
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1561Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_pancreas_fm
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1562Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_pancreas_mf
                         , decode(f.inpc_cd,'AM' ,'9999'
                                           ,'RR' ,'9999'
                                           ,'MA1',decode(a.family             ,'0','0'
                                                                              ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1563Y','1','0'))
                                                        ,''
                                                        )
                                           ,''
                                 ) fh_cancer_pancreas_mm
                    /* 가족력 - 기타암, AM/MA1 문진 통합 */
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM166Y',SUBSTR(f.inqy_rspn_ctn1,1,1)
                                                                                ,'AM166' ,SUBSTR(f.inqy_rspn_ctn1,1,1)
                                                                                ,'AM167Y',SUBSTR(f.inqy_rspn_ctn1,1,1)
                                                                                ,'AM167' ,SUBSTR(f.inqy_rspn_ctn1,1,1)
                                                                                ,'MA1565Y','1','0')),'')
                                 ) fh_cancer_other_f
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM166Y',SUBSTR(f.inqy_rspn_ctn1,2,1)
                                                                                ,'AM166' ,SUBSTR(f.inqy_rspn_ctn1,2,1)
                                                                                ,'AM167Y',SUBSTR(f.inqy_rspn_ctn1,2,1)
                                                                                ,'AM167' ,SUBSTR(f.inqy_rspn_ctn1,2,1)
                                                                                ,'MA1566Y','1','0')),'')
                                 ) fh_cancer_other_m
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM166Y',SUBSTR(f.inqy_rspn_ctn1,3,1)
                                                                                ,'AM166' ,SUBSTR(f.inqy_rspn_ctn1,3,1)
                                                                                ,'AM167Y',SUBSTR(f.inqy_rspn_ctn1,3,1)
                                                                                ,'AM167' ,SUBSTR(f.inqy_rspn_ctn1,3,1)
                                                                                ,'MA1567Y','1','0')),'')
                                 ) fh_cancer_other_sib
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM166Y',SUBSTR(f.inqy_rspn_ctn1,4,1)
                                                                                ,'AM166' ,SUBSTR(f.inqy_rspn_ctn1,4,1)
                                                                                ,'AM167Y',SUBSTR(f.inqy_rspn_ctn1,4,1)
                                                                                ,'AM167' ,SUBSTR(f.inqy_rspn_ctn1,4,1)
                                                                                ,'MA1568Y','1','0')),'')
                                 ) fh_cancer_other_ch
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM166Y',SUBSTR(f.inqy_rspn_ctn1,5,1)
                                                                                ,'AM166' ,SUBSTR(f.inqy_rspn_ctn1,5,1)
                                                                                ,'AM167Y',SUBSTR(f.inqy_rspn_ctn1,5,1)
                                                                                ,'AM167' ,SUBSTR(f.inqy_rspn_ctn1,5,1)
                                                                                ,'MA1569Y','1','0')),'')
                                 ) fh_cancer_other_ff
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM166Y',SUBSTR(f.inqy_rspn_ctn1,6,1)
                                                                                ,'AM166' ,SUBSTR(f.inqy_rspn_ctn1,6,1)
                                                                                ,'AM167Y',SUBSTR(f.inqy_rspn_ctn1,6,1)
                                                                                ,'AM167' ,SUBSTR(f.inqy_rspn_ctn1,6,1)
                                                                                ,'MA1570Y','1','0')),'')
                                 ) fh_cancer_other_fm
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM166Y',SUBSTR(f.inqy_rspn_ctn1,7,1)
                                                                                ,'AM166' ,SUBSTR(f.inqy_rspn_ctn1,7,1)
                                                                                ,'AM167Y',SUBSTR(f.inqy_rspn_ctn1,7,1)
                                                                                ,'AM167' ,SUBSTR(f.inqy_rspn_ctn1,7,1)
                                                                                ,'MA1571Y','1','0')),'')
                                 ) fh_cancer_other_mf
                         , decode(f.inpc_cd,'RR' ,'9999'
                                           ,decode(a.family        ,'0','0'
                                                                   ,'1',MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM166Y',SUBSTR(f.inqy_rspn_ctn1,8,1)
                                                                                ,'AM166' ,SUBSTR(f.inqy_rspn_ctn1,8,1)
                                                                                ,'AM167Y',SUBSTR(f.inqy_rspn_ctn1,8,1)
                                                                                ,'AM167' ,SUBSTR(f.inqy_rspn_ctn1,8,1)
                                                                                ,'MA1572Y','1','0')),'')
                                 ) fh_cancer_other_mm
                      from (-- 가족력 전체값 고려
                            select /*+ ordered use_nl(b a) index(b 3E3C0E433E3C0E3E28_i13) index(a 3E3C23302E333E0E28_pk) */
                                   'C05' grp
                                 , a.PTNO
                                 , a.ordr_prrn_ymd
                                 , a.inpc_cd
                            /* 가족력 */
                                 , case
                                        when
                                             count(case /* case1. 가족력에 응답 내역이 없고, 가족력 없다에 체크된 경우 0 */
                                                        when a.inpc_cd = 'AM' and (a.item_sno between 150 and 167) then a.inqy_rspn_cd
                                                        when a.inpc_cd = 'MA1' and (a.item_sno between 385 and 572) then a.ceck_yn||a.inqy_rspn_ctn1 -- MA1 문진의 경우 CTN은 응답이 있어도 ceck_yn이 null이므로 함께 고려
                                                        when a.inpc_cd = 'MA1' and (a.item_sno between 385 and 572) then a.inqy_rspn_ctn1
                                                        else ''
                                                   end
                                                  ) = 0
                                             and
                                             count(case when a.inpc_cd||a.item_sno            = 'AM168' then a.inqy_rspn_cd
                                                        when a.inpc_cd||a.item_sno||a.ceck_yn = 'MA1383Y' then a.ceck_yn 
                                                        else '' 
                                                   end
                                                  ) = 1
                                        then '0'
                                        when
                                             count(case /* case2. 가족력에 응답 내역이 있으면 1 */
                                                        when a.inpc_cd = 'AM' and (a.item_sno between 150 and 167) then a.inqy_rspn_cd
                                                        when a.inpc_cd = 'MA1' and (a.item_sno between 385 and 572) then a.ceck_yn||a.inqy_rspn_ctn1 -- MA1 문진의 경우 CTN은 응답이 있어도 ceck_yn이 null이므로 함께 고려
                                                        when a.inpc_cd = 'MA1' and (a.item_sno between 385 and 572) then a.inqy_rspn_ctn1
                                                        else ''
                                                   end
                                                  ) > 0
                                        then '1'
                                   else max(decode(a.inpc_cd,'RR','9999',''))
                                   end family
                              from 스키마.3E3C0E433E3C0E3E28@SMISR_스키마 b
                                 , 스키마.3E3C23302E333E0E28@SMISR_스키마 a
                             where 
                    --               b.ptno IN ('01982036' -- AM문진  응답자
                    --                         ,'00477937' -- RR문진  응답자
                    --                         ,'04032026' -- MA1문진 응답자
                    --                         )
                    --           and 
                                   b.ordr_prrn_ymd between to_date(&qfrdt,'yyyymmdd') and to_date(&qtodt,'yyyymmdd')
                               and b.ordr_ymd is not null
                               and b.cncl_dt is null
                               and a.ptno = b.ptno
                               and a.ordr_prrn_ymd = b.ordr_prrn_ymd
                               and a.inpc_cd in ('AM','RR','MA1')
                               AND (-- AM, RR의 경우는 응답한 것만 저장되었으므로, 모두 범위에 포함
                                      (a.inpc_cd = 'AM'  and a.item_sno between 1   and 500)
                                   OR (a.inpc_cd = 'RR'  and a.item_sno between 1   and 300)
                                   OR (a.inpc_cd = 'MA1' and a.item_sno between 382 and 572)
                                   )
                               and b.ptno not in (
                                                  &not_in_ptno
                                                 )
                               and b.rprs_apnt_no = a.rprs_apnt_no
                             group by a.PTNO
                                 , a.ordr_prrn_ymd
                                 , a.inpc_cd
                           ) a
                         , 스키마.3E3C23302E333E0E28@SMISR_스키마 f
                         , 스키마.0E5B5B285B28402857@SMISR_스키마 b
                     where f.ptno = a.ptno
                       and f.ordr_prrn_ymd = a.ordr_prrn_ymd
                       and f.inpc_cd = a.inpc_cd
                       AND (-- AM, RR의 경우는 응답한 것만 저장되었으므로, 모두 범위에 포함
                              (f.inpc_cd = 'AM'  and f.item_sno between 1   and 500)
                           OR (f.inpc_cd = 'RR'  and f.item_sno between 1   and 300)
                           OR (f.inpc_cd = 'MA1' and f.item_sno between 382 and 572)
                           )
                       and a.ptno = b.ptno
                     group by f.rprs_apnt_no
                         , a.PTNO
                         , a.ordr_prrn_ymd
                         , f.inpc_cd
                         , b.gend_cd
                         , a.family
                   ) h
                       
           )
                
            loop
            begin   -- 데이터 update
                          update /*+ append */
                                 스키마.1543294D47144D302E333E0E28 a
                             set 
                                 a.FAMILY                              = drh."1"  
                               , a.FH_HYPERTENSION_F                   = drh."2"  
                               , a.FH_HYPERTENSION_M                   = drh."3"  
                               , a.FH_HYPERTENSION_SIB                 = drh."4"  
                               , a.FH_HYPERTENSION_CH                  = drh."5"  
                               , a.FH_HYPERTENSION_FF                  = drh."6"  
                               , a.FH_HYPERTENSION_FM                  = drh."7"  
                               , a.FH_HYPERTENSION_MF                  = drh."8"  
                               , a.FH_HYPERTENSION_MM                  = drh."9"  
                               , a.FH_STROKE_F                         = drh."10" 
                               , a.FH_STROKE_M                         = drh."11" 
                               , a.FH_STROKE_SIB                       = drh."12" 
                               , a.FH_STROKE_CH                        = drh."13" 
                               , a.FH_STROKE_FF                        = drh."14" 
                               , a.FH_STROKE_FM                        = drh."15" 
                               , a.FH_STROKE_MF                        = drh."16" 
                               , a.FH_STROKE_MM                        = drh."17" 
                               , a.FH_DIABETES_F                       = drh."18" 
                               , a.FH_DIABETES_M                       = drh."19" 
                               , a.FH_DIABETES_SIB                     = drh."20" 
                               , a.FH_DIABETES_CH                      = drh."21" 
                               , a.FH_DIABETES_FF                      = drh."22" 
                               , a.FH_DIABETES_FM                      = drh."23" 
                               , a.FH_DIABETES_MF                      = drh."24" 
                               , a.FH_DIABETES_MM                      = drh."25" 
                               , a.FH_HEP_CIRRHOSIS_F                  = drh."26" 
                               , a.FH_HEP_CIRRHOSIS_M                  = drh."27" 
                               , a.FH_HEP_CIRRHOSIS_SIB                = drh."28" 
                               , a.FH_HEP_CIRRHOSIS_CH                 = drh."29" 
                               , a.FH_HEP_CIRRHOSIS_FF                 = drh."30" 
                               , a.FH_HEP_CIRRHOSIS_FM                 = drh."31" 
                               , a.FH_HEP_CIRRHOSIS_MF                 = drh."32" 
                               , a.FH_HEP_CIRRHOSIS_MM                 = drh."33" 
                               , a.FH_DEMENTIA_F                       = drh."34" 
                               , a.FH_DEMENTIA_M                       = drh."35" 
                               , a.FH_DEMENTIA_SIB                     = drh."36" 
                               , a.FH_DEMENTIA_CH                      = drh."37" 
                               , a.FH_DEMENTIA_FF                      = drh."38" 
                               , a.FH_DEMENTIA_FM                      = drh."39" 
                               , a.FH_DEMENTIA_MF                      = drh."40" 
                               , a.FH_DEMENTIA_MM                      = drh."41" 
                               , a.FH_TUBERCULOSIS_F                   = drh."42" 
                               , a.FH_TUBERCULOSIS_M                   = drh."43" 
                               , a.FH_TUBERCULOSIS_SIB                 = drh."44" 
                               , a.FH_TUBERCULOSIS_CH                  = drh."45" 
                               , a.FH_TUBERCULOSIS_FF                  = drh."46" 
                               , a.FH_TUBERCULOSIS_FM                  = drh."47" 
                               , a.FH_TUBERCULOSIS_MF                  = drh."48" 
                               , a.FH_TUBERCULOSIS_MM                  = drh."49" 
                               , a.FH_MI_F                             = drh."50" 
                               , a.FH_MI_M                             = drh."51" 
                               , a.FH_MI_SIB                           = drh."52" 
                               , a.FH_MI_CH                            = drh."53" 
                               , a.FH_MI_FF                            = drh."54" 
                               , a.FH_MI_FM                            = drh."55" 
                               , a.FH_MI_MF                            = drh."56" 
                               , a.FH_MI_MM                            = drh."57" 
                               , a.FH_ANGINA_F                         = drh."58" 
                               , a.FH_ANGINA_M                         = drh."59" 
                               , a.FH_ANGINA_SIB                       = drh."60" 
                               , a.FH_ANGINA_CH                        = drh."61" 
                               , a.FH_ANGINA_FF                        = drh."62" 
                               , a.FH_ANGINA_FM                        = drh."63" 
                               , a.FH_ANGINA_MF                        = drh."64" 
                               , a.FH_ANGINA_MM                        = drh."65" 
                               , a.FH_OTHER_CONGENITAL_MAL_F           = drh."66" 
                               , a.FH_OTHER_CONGENITAL_MAL_M           = drh."67" 
                               , a.FH_OTHER_CONGENITAL_MAL_SIB         = drh."68" 
                               , a.FH_OTHER_CONGENITAL_MAL_CH          = drh."69" 
                               , a.FH_OTHER_CONGENITAL_MAL_FF          = drh."70" 
                               , a.FH_OTHER_CONGENITAL_MAL_FM          = drh."71" 
                               , a.FH_OTHER_CONGENITAL_MAL_MF          = drh."72" 
                               , a.FH_OTHER_CONGENITAL_MAL_MM          = drh."73" 
                               , a.FH_CONGENITAL_HEART_DIS_F           = drh."74" 
                               , a.FH_CONGENITAL_HEART_DIS_M           = drh."75" 
                               , a.FH_CONGENITAL_HEART_DIS_SIB         = drh."76" 
                               , a.FH_CONGENITAL_HEART_DIS_CH          = drh."77" 
                               , a.FH_CONGENITAL_HEART_DIS_FF          = drh."78" 
                               , a.FH_CONGENITAL_HEART_DIS_FM          = drh."79" 
                               , a.FH_CONGENITAL_HEART_DIS_MF          = drh."80" 
                               , a.FH_CONGENITAL_HEART_DIS_MM          = drh."81" 
                               , a.FH_CLEFT_LIP_PALATE_F               = drh."82" 
                               , a.FH_CLEFT_LIP_PALATE_M               = drh."83" 
                               , a.FH_CLEFT_LIP_PALATE_SIB             = drh."84" 
                               , a.FH_CLEFT_LIP_PALATE_CH              = drh."85" 
                               , a.FH_CLEFT_LIP_PALATE_FF              = drh."86" 
                               , a.FH_CLEFT_LIP_PALATE_FM              = drh."87" 
                               , a.FH_CLEFT_LIP_PALATE_MF              = drh."88" 
                               , a.FH_CLEFT_LIP_PALATE_MM              = drh."89" 
                               , a.FH_CORONARY_DIS_F                   = drh."90" 
                               , a.FH_CORONARY_DIS_M                   = drh."91" 
                               , a.FH_CORONARY_DIS_SIB                 = drh."92" 
                               , a.FH_CORONARY_DIS_CH                  = drh."93" 
                               , a.FH_CORONARY_DIS_FF                  = drh."94" 
                               , a.FH_CORONARY_DIS_FM                  = drh."95" 
                               , a.FH_CORONARY_DIS_MF                  = drh."96" 
                               , a.FH_CORONARY_DIS_MM                  = drh."97" 
                               , a.FH_ASTHMA_COPD_F                    = drh."98" 
                               , a.FH_ASTHMA_COPD_M                    = drh."99" 
                               , a.FH_ASTHMA_COPD_SIB                  = drh."100"
                               , a.FH_ASTHMA_COPD_CH                   = drh."101"
                               , a.FH_ASTHMA_COPD_FF                   = drh."102"
                               , a.FH_ASTHMA_COPD_FM                   = drh."103"
                               , a.FH_ASTHMA_COPD_MF                   = drh."104"
                               , a.FH_ASTHMA_COPD_MM                   = drh."105"
                               , a.FH_CANCER_STOMACH_F                 = drh."106"
                               , a.FH_CANCER_STOMACH_M                 = drh."107"
                               , a.FH_CANCER_STOMACH_SIB               = drh."108"
                               , a.FH_CANCER_STOMACH_CH                = drh."109"
                               , a.FH_CANCER_STOMACH_FF                = drh."110"
                               , a.FH_CANCER_STOMACH_FM                = drh."111"
                               , a.FH_CANCER_STOMACH_MF                = drh."112"
                               , a.FH_CANCER_STOMACH_MM                = drh."113"
                               , a.FH_CANCER_BREAST_F                  = drh."114"
                               , a.FH_CANCER_BREAST_M                  = drh."115"
                               , a.FH_CANCER_BREAST_SIB                = drh."116"
                               , a.FH_CANCER_BREAST_CH                 = drh."117"
                               , a.FH_CANCER_BREAST_FF                 = drh."118"
                               , a.FH_CANCER_BREAST_FM                 = drh."119"
                               , a.FH_CANCER_BREAST_MF                 = drh."120"
                               , a.FH_CANCER_BREAST_MM                 = drh."121"
                               , a.FH_CANCER_COLORECTAL_F              = drh."122"
                               , a.FH_CANCER_COLORECTAL_M              = drh."123"
                               , a.FH_CANCER_COLORECTAL_SIB            = drh."124"
                               , a.FH_CANCER_COLORECTAL_CH             = drh."125"
                               , a.FH_CANCER_COLORECTAL_FF             = drh."126"
                               , a.FH_CANCER_COLORECTAL_FM             = drh."127"
                               , a.FH_CANCER_COLORECTAL_MF             = drh."128"
                               , a.FH_CANCER_COLORECTAL_MM             = drh."129"
                               , a.FH_CANCER_LUNG_F                    = drh."130"
                               , a.FH_CANCER_LUNG_M                    = drh."131"
                               , a.FH_CANCER_LUNG_SIB                  = drh."132"
                               , a.FH_CANCER_LUNG_CH                   = drh."133"
                               , a.FH_CANCER_LUNG_FF                   = drh."134"
                               , a.FH_CANCER_LUNG_FM                   = drh."135"
                               , a.FH_CANCER_LUNG_MF                   = drh."136"
                               , a.FH_CANCER_LUNG_MM                   = drh."137"
                               , a.FH_CANCER_UTERINE_F                 = drh."138"
                               , a.FH_CANCER_UTERINE_M                 = drh."139"
                               , a.FH_CANCER_UTERINE_SIB               = drh."140"
                               , a.FH_CANCER_UTERINE_CH                = drh."141"
                               , a.FH_CANCER_UTERINE_FF                = drh."142"
                               , a.FH_CANCER_UTERINE_FM                = drh."143"
                               , a.FH_CANCER_UTERINE_MF                = drh."144"
                               , a.FH_CANCER_UTERINE_MM                = drh."145"
                               , a.FH_CANCER_LIVER_F                   = drh."146"
                               , a.FH_CANCER_LIVER_M                   = drh."147"
                               , a.FH_CANCER_LIVER_SIB                 = drh."148"
                               , a.FH_CANCER_LIVER_CH                  = drh."149"
                               , a.FH_CANCER_LIVER_FF                  = drh."150"
                               , a.FH_CANCER_LIVER_FM                  = drh."151"
                               , a.FH_CANCER_LIVER_MF                  = drh."152"
                               , a.FH_CANCER_LIVER_MM                  = drh."153"
                               , a.FH_CANCER_THYROID_F                 = drh."154"
                               , a.FH_CANCER_THYROID_M                 = drh."155"
                               , a.FH_CANCER_THYROID_SIB               = drh."156"
                               , a.FH_CANCER_THYROID_CH                = drh."157"
                               , a.FH_CANCER_THYROID_FF                = drh."158"
                               , a.FH_CANCER_THYROID_FM                = drh."159"
                               , a.FH_CANCER_THYROID_MF                = drh."160"
                               , a.FH_CANCER_THYROID_MM                = drh."161"
                               , a.FH_CANCER_OVARY_F                   = drh."162"
                               , a.FH_CANCER_OVARY_M                   = drh."163"
                               , a.FH_CANCER_OVARY_SIB                 = drh."164"
                               , a.FH_CANCER_OVARY_CH                  = drh."165"
                               , a.FH_CANCER_OVARY_FF                  = drh."166"
                               , a.FH_CANCER_OVARY_FM                  = drh."167"
                               , a.FH_CANCER_OVARY_MF                  = drh."168"
                               , a.FH_CANCER_OVARY_MM                  = drh."169"
                               , a.FH_CANCER_CERVIX_F                  = drh."170"
                               , a.FH_CANCER_CERVIX_M                  = drh."171"
                               , a.FH_CANCER_CERVIX_SIB                = drh."172"
                               , a.FH_CANCER_CERVIX_CH                 = drh."173"
                               , a.FH_CANCER_CERVIX_FF                 = drh."174"
                               , a.FH_CANCER_CERVIX_FM                 = drh."175"
                               , a.FH_CANCER_CERVIX_MF                 = drh."176"
                               , a.FH_CANCER_CERVIX_MM                 = drh."177"
                               , a.FH_CANCER_GB_BILIARY_F              = drh."178"
                               , a.FH_CANCER_GB_BILIARY_M              = drh."179"
                               , a.FH_CANCER_GB_BILIARY_SIB            = drh."180"
                               , a.FH_CANCER_GB_BILIARY_CH             = drh."181"
                               , a.FH_CANCER_GB_BILIARY_FF             = drh."182"
                               , a.FH_CANCER_GB_BILIARY_FM             = drh."183"
                               , a.FH_CANCER_GB_BILIARY_MF             = drh."184"
                               , a.FH_CANCER_GB_BILIARY_MM             = drh."185"
                               , a.FH_CANCER_BLADDER_F                 = drh."186"
                               , a.FH_CANCER_BLADDER_M                 = drh."187"
                               , a.FH_CANCER_BLADDER_SIB               = drh."188"
                               , a.FH_CANCER_BLADDER_CH                = drh."189"
                               , a.FH_CANCER_BLADDER_FF                = drh."190"
                               , a.FH_CANCER_BLADDER_FM                = drh."191"
                               , a.FH_CANCER_BLADDER_MF                = drh."192"
                               , a.FH_CANCER_BLADDER_MM                = drh."193"
                               , a.FH_CANCER_ESOPHAGUS_F               = drh."194"
                               , a.FH_CANCER_ESOPHAGUS_M               = drh."195"
                               , a.FH_CANCER_ESOPHAGUS_SIB             = drh."196"
                               , a.FH_CANCER_ESOPHAGUS_CH              = drh."197"
                               , a.FH_CANCER_ESOPHAGUS_FF              = drh."198"
                               , a.FH_CANCER_ESOPHAGUS_FM              = drh."199"
                               , a.FH_CANCER_ESOPHAGUS_MF              = drh."200"
                               , a.FH_CANCER_ESOPHAGUS_MM              = drh."201"
                               , a.FH_CANCER_PROSTATE_F                = drh."202"
                               , a.FH_CANCER_PROSTATE_M                = drh."203"
                               , a.FH_CANCER_PROSTATE_SIB              = drh."204"
                               , a.FH_CANCER_PROSTATE_CH               = drh."205"
                               , a.FH_CANCER_PROSTATE_FF               = drh."206"
                               , a.FH_CANCER_PROSTATE_FM               = drh."207"
                               , a.FH_CANCER_PROSTATE_MF               = drh."208"
                               , a.FH_CANCER_PROSTATE_MM               = drh."209"
                               , a.FH_CANCER_PANCREAS_F                = drh."210"
                               , a.FH_CANCER_PANCREAS_M                = drh."211"
                               , a.FH_CANCER_PANCREAS_SIB              = drh."212"
                               , a.FH_CANCER_PANCREAS_CH               = drh."213"
                               , a.FH_CANCER_PANCREAS_FF               = drh."214"
                               , a.FH_CANCER_PANCREAS_FM               = drh."215"
                               , a.FH_CANCER_PANCREAS_MF               = drh."216"
                               , a.FH_CANCER_PANCREAS_MM               = drh."217"
                               , a.FH_CANCER_OTHER_F                   = drh."218"
                               , a.FH_CANCER_OTHER_M                   = drh."219"
                               , a.FH_CANCER_OTHER_SIB                 = drh."220"
                               , a.FH_CANCER_OTHER_CH                  = drh."221"
                               , a.FH_CANCER_OTHER_FF                  = drh."222"
                               , a.FH_CANCER_OTHER_FM                  = drh."223"
                               , a.FH_CANCER_OTHER_MF                  = drh."224"
                               , a.FH_CANCER_OTHER_MM                  = drh."225"
                               , a.last_updt_dt                     = drh.last_updt_dt
                           where a.ptno = drh.ptno
                             and a.ordr_prrn_ymd = drh.ordr_prrn_ymd
                             and a.rprs_apnt_no = drh.rprs_apnt_no
                                 ;
                  
                         commit;
                       
                       upcnt := upcnt + 1;
                  
                       exception
                       when others then
                          rollback;
                          errcnt := errcnt + 1;
            
            end;
            end loop;
       
:var_msg2  := 'update '  || to_char(upcnt)    || ' 건';
:var_msg3  := 'error '   || to_char(errcnt)   || ' 건';
   
end ;
/
print var_msg2
print var_msg3
spool off;
     
-- 문진 정보 update, 남성, 여성, 스트레스
-- 변수 길이가 길다는 에러메세지 때문에 변수를 숫자정보로 치환
-- 메시지 출력기능 추가. 메시지 확인은 F5를 눌러야 가능함
variable var_msg2 char(40);
variable var_msg3 char(40);
  
declare
    upcnt     number(10) := 0;
    errcnt    number(10) := 0;
        
begin
for drh in (
            -- 데이터 select
            select h.RPRS_APNT_NO                   as RPRS_APNT_NO
                 , h.PTNO                           as ptno
                 , h.ORDR_PRRN_YMD                  as ordr_prrn_ymd
                 , h.ML1_1                               as "1" 
                 , h.ML2_1                               as "2" 
                 , h.ML3_1                               as "3" 
                 , h.ML4_1                               as "4" 
                 , h.ML5_1                               as "5" 
                 , h.ML6_1                               as "6" 
                 , h.ML7_1                               as "7" 
                 , h.ML8_1                               as "8" 
                 , h.ML_SCORE                            as "9" 
                 , h.MENSTRUATION_LAST_YY                as "10"
                 , h.MENSTRUATION_LAST_MM                as "11"
                 , h.MENSTRUATION_LAST_DD                as "12"
                 , h.MENARCHE_AGE                        as "13"
                 , h.NO_MENSTRUATION                     as "14"
                 , h.MENSTRUATION_AVG_DURATION           as "15"
                 , h.ABNORMAL_BLEEDING                   as "16"
                 , h.VAGINAL_DISCHARGE                   as "17"
                 , h.POSTMENOPAUSAL                      as "18"
                 , h.MENOPAUSE_AGE_CAT                   as "19"
                 , h.MENOPAUSE_AGE                       as "20"
                 , h.MENOPAUSE_CAUSE                     as "21"
                 , h.FEMALE_HORMONES                     as "22"
                 , h.TRT_FEMALE_HORMONES                 as "23"
                 , h.FEMALE_HORMONES_AGE                 as "24"
                 , h.FEMALE_HORMONES_AMOUNT              as "25"
                 , h.FEMALE_HORMONES_DURATION            as "26"
                 , h.PREGNANCY                           as "27"
                 , h.PREGNANCY_FIRST_AGE                 as "28"
                 , h.DELIVERY                            as "29"
                 , h.DELIVERY_N                          as "30"
                 , h.DELIVERY_BOY                        as "31"
                 , h.DELIVERY_GIRL                       as "32"
                 , h.NATURAL_CHILDBIRTH                  as "33"
                 , h.CAESAREAN_SECTION                   as "34"
                 , h.DELIVERY_FIRST_AGE                  as "35"
                 , h.DELIVERY_LAST_AGE                   as "36"
                 , h.PREMATURE_BIRTH                     as "37"
                 , h.PREMATURE_BIRTH_N                   as "38"
                 , h.MISCARRIAGE                         as "39"
                 , h.MISCARRIAGE_NATURAL_N               as "40"
                 , h.MISCARRIAGE_ARTIFICIAL_N            as "41"
                 , h.PAP                                 as "42"
                 , h.PAP_FIRST_AGE                       as "43"
                 , h.PAP_LAST_AGE                        as "44"
                 , h.PAP_FREQ                            as "45"
                 , h.STRESS_Q1                           as "46"
                 , h.STRESS_Q2                           as "47"
                 , h.STRESS_Q3                           as "48"
                 , h.STRESS_Q4                           as "49"
                 , h.STRESS_Q5                           as "50"
                 , h.STRESS_Q6                           as "51"
                 , h.STRESS_Q7                           as "52"
                 , h.STRESS_Q8                           as "53"
                 , h.STRESS_Q9                           as "54"
                 , h.STRESS_Q10                          as "55"
                 , h.STRESS_Q11                          as "56"
                 , h.STRESS_Q12                          as "57"
                 , h.STRESS_Q13                          as "58"
                 , h.STRESS_Q14                          as "59"
                 , h.STRESS_Q15                          as "60"
                 , h.STRESS_Q16                          as "61"
                 , h.STRESS_Q17                          as "62"
                 , h.STRESS_Q18                          as "63"
                 , h.STRESS_Q19                          as "64"
                 , h.STRESS_Q20                          as "65"
                 , h.STRESS_Q21                          as "66"
                 , h.STRESS_SCORE                        as "67"
                 , sysdate                          as last_updt_dt
              from (-- 문진 응답내역 중 남성, 여성, 스트레스
                    select /*+ ordered use_nl(A F) index(a 3E3C0E433E3C0E3E28_i13) index(f 3E3C23302E333E0E28_pk) */
                           f.rprs_apnt_no
                         , F.PTNO
                         , f.ordr_prrn_ymd
                         , f.inpc_cd
                         , b.gend_cd
                    /* 남성의학 */
                         , decode(f.inpc_cd,'AM','9999'
                                           ,'RR','9999'
                                           ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1658Y','0'
                                                                      ,'MA1659Y','1'
                                                                      ,'MA1660Y','2'
                                                                      ,'MA1661Y','3'
                                                                      ,'MA1662Y','4'
                                                                      ,'MA1663Y','5',''))
                                 )                                                                                       ml1_1
                         , decode(f.inpc_cd,'AM','9999'
                                           ,'RR','9999'
                                           ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1665Y','0'
                                                                      ,'MA1666Y','1'
                                                                      ,'MA1667Y','2'
                                                                      ,'MA1668Y','3'
                                                                      ,'MA1669Y','4'
                                                                      ,'MA1670Y','5',''))
                                 )                                                                                       ml2_1
                         , decode(f.inpc_cd,'AM','9999'
                                           ,'RR','9999'
                                           ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1672Y','0'
                                                                      ,'MA1673Y','1'
                                                                      ,'MA1674Y','2'
                                                                      ,'MA1675Y','3'
                                                                      ,'MA1676Y','4'
                                                                      ,'MA1677Y','5',''))
                                 )                                                                                       ml3_1
                         , decode(f.inpc_cd,'AM','9999'
                                           ,'RR','9999'
                                           ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1679Y','0'
                                                                      ,'MA1680Y','1'
                                                                      ,'MA1681Y','2'
                                                                      ,'MA1682Y','3'
                                                                      ,'MA1683Y','4'
                                                                      ,'MA1684Y','5',''))
                                 )                                                                                       ml4_1
                         , decode(f.inpc_cd,'AM','9999'
                                           ,'RR','9999'
                                           ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1686Y','0'
                                                                      ,'MA1687Y','1'
                                                                      ,'MA1688Y','2'
                                                                      ,'MA1689Y','3'
                                                                      ,'MA1690Y','4'
                                                                      ,'MA1691Y','5',''))
                                 )                                                                                       ml5_1
                         , decode(f.inpc_cd,'AM','9999'
                                           ,'RR','9999'
                                           ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1693Y','0'
                                                                      ,'MA1694Y','1'
                                                                      ,'MA1695Y','2'
                                                                      ,'MA1696Y','3'
                                                                      ,'MA1697Y','4'
                                                                      ,'MA1698Y','5',''))
                                 )                                                                                       ml6_1
                         , decode(f.inpc_cd,'AM','9999'
                                           ,'RR','9999'
                                           ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1700Y','0'
                                                                      ,'MA1701Y','1'
                                                                      ,'MA1702Y','2'
                                                                      ,'MA1703Y','3'
                                                                      ,'MA1704Y','4'
                                                                      ,'MA1705Y','5',''))
                                 )                                                                                       ml7_1
                         , decode(f.inpc_cd,'AM','9999'
                                           ,'RR','9999'
                                           ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1707Y','0'
                                                                      ,'MA1708Y','1'
                                                                      ,'MA1709Y','2'
                                                                      ,'MA1710Y','3'
                                                                      ,'MA1711Y','4'
                                                                      ,'MA1712Y','5'
                                                                      ,'MA1713Y','6',''))
                                 )                                                                                       ml8_1
                         , decode(f.inpc_cd,'AM','9999'
                                           ,'RR','9999'
                           -- missing 인 변수가 있다면 계산하지 않으므로 nvl처리 하지 않음.
                          ,MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1658Y',0
                                                                      ,'MA1659Y',1
                                                                      ,'MA1660Y',2
                                                                      ,'MA1661Y',3
                                                                      ,'MA1662Y',4
                                                                      ,'MA1663Y',5))--                ml1_1
                         + MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1665Y',0
                                                                      ,'MA1666Y',1
                                                                      ,'MA1667Y',2
                                                                      ,'MA1668Y',3
                                                                      ,'MA1669Y',4
                                                                      ,'MA1670Y',5))--                ml2_1
                         + MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1672Y',0
                                                                      ,'MA1673Y',1
                                                                      ,'MA1674Y',2
                                                                      ,'MA1675Y',3
                                                                      ,'MA1676Y',4
                                                                      ,'MA1677Y',5))--                ml3_1
                         + MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1679Y',0
                                                                      ,'MA1680Y',1
                                                                      ,'MA1681Y',2
                                                                      ,'MA1682Y',3
                                                                      ,'MA1683Y',4
                                                                      ,'MA1684Y',5))--                ml4_1
                         + MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1686Y',0
                                                                      ,'MA1687Y',1
                                                                      ,'MA1688Y',2
                                                                      ,'MA1689Y',3
                                                                      ,'MA1690Y',4
                                                                      ,'MA1691Y',5))--                ml5_1
                         + MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1693Y',0
                                                                      ,'MA1694Y',1
                                                                      ,'MA1695Y',2
                                                                      ,'MA1696Y',3
                                                                      ,'MA1697Y',4
                                                                      ,'MA1698Y',5))--                ml6_1
                         + MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1700Y',0
                                                                      ,'MA1701Y',1
                                                                      ,'MA1702Y',2
                                                                      ,'MA1703Y',3
                                                                      ,'MA1704Y',4
                                                                      ,'MA1705Y',5))--                ml7_1
                                ) ml_score
                    /* 여성의학 */
                         , max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM246'  ,f.inqy_rspn_ctn1
                                                                      ,'AM246Y' ,f.inqy_rspn_ctn1
                                                                      ,'RR195'  ,f.inqy_rspn_ctn1
                                                                      ,'RR195Y' ,f.inqy_rspn_ctn1
                                                                      ,decode(f.inpc_cd,'MA1','9999','')
                                      )
                              ) menstruation_last_yy
                         , max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM246'  ,f.inqy_rspn_ctn2
                                                                      ,'AM246Y' ,f.inqy_rspn_ctn2
                                                                      ,'RR195'  ,f.inqy_rspn_ctn2
                                                                      ,'RR195Y' ,f.inqy_rspn_ctn2
                                                                      ,decode(f.inpc_cd,'MA1','9999','')
                                      )
                              ) menstruation_last_mm
                         , max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM246'  ,f.inqy_rspn_ctn3
                                                                      ,'AM246Y' ,f.inqy_rspn_ctn3
                                                                      ,'RR195'  ,f.inqy_rspn_ctn3
                                                                      ,'RR195Y' ,f.inqy_rspn_ctn3
                                                                      ,decode(f.inpc_cd,'MA1','9999','')
                                      )
                              ) menstruation_last_dd
                         , max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM248'  ,f.inqy_rspn_ctn1
                                                                             ,'AM248Y' ,f.inqy_rspn_ctn1
                                                                             ,'MA1715Y','0'
                                                                             ,'MA1716Y','1'
                                                                             ,'MA1717Y','2'
                                                                             ,'MA1718Y','3'
                                                                             ,'MA1719Y','4'
                                                                             ,'MA1720Y','5'
                                                                             ,'MA1721Y','6'
                                                                             ,'MA1722Y','7'
                                                                             ,'MA1723Y','8'
                                                                             ,'MA1724Y','9'
                                            ,decode(f.inpc_cd,'RR','9999','')
                                     )
                              ) menarche_age
                         , case 
                                when MAX(f.inpc_cd) in ('MA1','RR') then '9999'
                                when COUNT(
                                           case
                                                when f.inpc_cd||f.item_sno||f.ceck_yn in ('AM248','AM248Y') and f.inqy_rspn_ctn1 is not null then f.inqy_rspn_cd
                                           else ''
                                           end
                                          ) > 0
                                then '0'
                                else
                                     max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM249Y' ,'1'
                                                                                ,'AM249'  ,'1'
                                                                                ,decode(f.inpc_cd,'MA1','9999','RR','9999','')
                                               )
                                        )
                           end  no_menstruation
                         , max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn       ,'AM254Y' ,f.inqy_rspn_ctn1
                                                                             ,'AM254'  ,f.inqy_rspn_ctn1
                                                                             ,decode(f.inpc_cd,'MA1','9999','RR','9999','')
                                     )
                              ) menstruation_avg_duration
                         , max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM256Y'  ,'1'
                                                                             ,'AM256'   ,'1'
                                                                             ,'AM257Y'  ,'0'
                                                                             ,'AM257'   ,'0'
                                                                             ,'RR203Y'  ,'1'
                                                                             ,'RR203'   ,'1'
                                                                             ,'RR204Y'  ,'0'
                                                                             ,'RR204'   ,'0'
                                            ,decode(f.inpc_cd,'MA1','9999','')
                                     )
                              ) abnormal_bleeding
                         , max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM259Y'  ,'1'
                                                                             ,'AM260Y'  ,'0'
                                                                             ,'RR206Y'  ,'1'
                                                                             ,'RR207Y'  ,'0'
                                                                             ,'AM259'   ,'1'
                                                                             ,'AM260'   ,'0'
                                                                             ,'RR206'   ,'1'
                                                                             ,'RR207'   ,'0'
                                            ,decode(f.inpc_cd,'MA1','9999','')
                                     )
                              ) vaginal_discharge
                         , case
                                when /*case2. 폐경 관련 부가 응답내역이 있으나, 해당 문진 응답이 null이면 0 */
                                     count(
                                           case 
                                                when f.inpc_cd = 'AM'  and (f.item_sno between 263 and 269) then f.inqy_rspn_cd
                                                when f.inpc_cd = 'RR'  and (f.item_sno between 211 and 225) then f.inqy_rspn_cd
                                                when f.inpc_cd = 'MA1' and f.item_sno = 730 and f.inqy_rspn_ctn1 is not null then f.inqy_rspn_cd
                                                when f.inpc_cd = 'MA1' and (f.item_sno between 732 and 736) then f.ceck_yn||f.inqy_rspn_ctn1 -- MA1 문진의 경우 CTN은 응답이 있어도 ceck_yn이 null이므로 함께 고려
                                                else ''
                                           end
                                          ) > 0
                                 and max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM262Y' ,'0'
                                                                             ,'AM280Y' ,'1'
                                                                             ,'AM281Y' ,'2'
                                                                             ,'RR209Y' ,'0'
                                                                             ,'RR232Y' ,'1'
                                                                             ,'RR233Y' ,'2'
                                                                             ,'MA1726Y','0'
                                                                             ,'MA1727Y','2'
                                                                             ,'MA1728Y','1'
                                                                             ,'MA1729Y','2'
                                                                             ,'AM262'  ,'0'
                                                                             ,'AM280'  ,'1'
                                                                             ,'AM281'  ,'2'
                                                                             ,'RR209'  ,'0'
                                                                             ,'RR232'  ,'1'
                                                                             ,'RR233'  ,'2','')) is null
                                then '0'
                                else 
                                     MIN(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM262Y' ,'0'
                                                                                       ,'AM280Y' ,'1'
                                                                                       ,'AM281Y' ,'2'
                                                                                       ,'RR209Y' ,'0'
                                                                                       ,'RR232Y' ,'1'
                                                                                       ,'RR233Y' ,'2'
                                                                                       ,'MA1726Y','0'
                                                                                       ,'MA1727Y','2'
                                                                                       ,'MA1728Y','1'
                                                                                       ,'MA1729Y','2'
                                                                                       ,'AM262'  ,'0'
                                                                                       ,'AM280'  ,'1'
                                                                                       ,'AM281'  ,'2'
                                                                                       ,'RR209'  ,'0'
                                                                                       ,'RR232'  ,'1'
                                                                                       ,'RR233'  ,'2'
                                                                                       ,decode(b.gend_cd,'M','','')
                                               )
                                        ) 
                           end postmenopausal
                         , case
                                when f.inpc_cd = 'RR' then MIN(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn       ,'RR211Y' ,'0'
                                                                                                             ,'RR212Y' ,'1'
                                                                                                             ,'RR213Y' ,'2'
                                                                                                             ,'RR214Y' ,'3'
                                                                                                             ,'RR215Y' ,'4'
                                                                                                             ,'RR216Y' ,'5'
                                                                                                             ,'RR217Y' ,'6'
                                                                                                             ,'RR218Y' ,'7'
                                                                                                             ,'RR219Y' ,'8'
                                                                                                             ,'RR211'  ,'0'
                                                                                                             ,'RR212'  ,'1'
                                                                                                             ,'RR213'  ,'2'
                                                                                                             ,'RR214'  ,'3'
                                                                                                             ,'RR215'  ,'4'
                                                                                                             ,'RR216'  ,'5'
                                                                                                             ,'RR217'  ,'6'
                                                                                                             ,'RR218'  ,'7'
                                                                                                             ,'RR219'  ,'8'
                                                                            ,''
                                                                     )
                                                              )
                           else 
                                case 
                                     when regexp_replace(MIN(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM263'  ,f.inqy_rspn_ctn1
                                                                                                    ,'AM263Y' ,f.inqy_rspn_ctn1
                                                                                                    ,'MA1730' ,f.inqy_rspn_ctn1,'')),'^-?[0-9]+((\.[0-9]+)([Ee][+-][0-9]+)?)?','') is null 
                                     then 
                                          case 
                                               when MIN(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM263'  ,f.inqy_rspn_ctn1
                                                                                       ,'AM263Y' ,f.inqy_rspn_ctn1
                                                                                       ,'MA1730' ,f.inqy_rspn_ctn1
                                                              )) < '25' then '0'
                                               when MIN(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM263'  ,f.inqy_rspn_ctn1
                                                                                       ,'AM263Y' ,f.inqy_rspn_ctn1
                                                                                       ,'MA1730' ,f.inqy_rspn_ctn1
                                                              )) < '30' then '1'
                                               when MIN(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM263'  ,f.inqy_rspn_ctn1
                                                                                       ,'AM263Y' ,f.inqy_rspn_ctn1
                                                                                       ,'MA1730' ,f.inqy_rspn_ctn1
                                                              )) < '35' then '2'
                                               when MIN(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM263'  ,f.inqy_rspn_ctn1
                                                                                       ,'AM263Y' ,f.inqy_rspn_ctn1
                                                                                       ,'MA1730' ,f.inqy_rspn_ctn1
                                                              )) < '40' then '3'
                                               when MIN(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM263'  ,f.inqy_rspn_ctn1
                                                                                       ,'AM263Y' ,f.inqy_rspn_ctn1
                                                                                       ,'MA1730' ,f.inqy_rspn_ctn1
                                                              )) < '45' then '4'
                                               when MIN(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM263'  ,f.inqy_rspn_ctn1
                                                                                       ,'AM263Y' ,f.inqy_rspn_ctn1
                                                                                       ,'MA1730' ,f.inqy_rspn_ctn1
                                                              )) < '50' then '5'
                                               when MIN(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM263'  ,f.inqy_rspn_ctn1
                                                                                       ,'AM263Y' ,f.inqy_rspn_ctn1
                                                                                       ,'MA1730' ,f.inqy_rspn_ctn1
                                                              )) < '55' then '6'
                                               when MIN(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM263'  ,f.inqy_rspn_ctn1
                                                                                       ,'AM263Y' ,f.inqy_rspn_ctn1
                                                                                       ,'MA1730' ,f.inqy_rspn_ctn1
                                                              )) < '60' then '7'
                                               when MIN(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM263'  ,f.inqy_rspn_ctn1
                                                                                       ,'AM263Y' ,f.inqy_rspn_ctn1
                                                                                       ,'MA1730' ,f.inqy_rspn_ctn1
                                                              )) > '59' then '8'
                                     else ''
                                     end 
                                else ''
                                end
                           end menopause_age_cat
                         , MIN(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM263'  ,f.inqy_rspn_ctn1
                                                                             ,'AM263Y' ,f.inqy_rspn_ctn1
                                                                             ,'MA1730' ,f.inqy_rspn_ctn1
                                            ,decode(f.inpc_cd,'RR' ,'9999','')
                                     )
                              ) menopause_age
                         ,        MAX(       DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM265Y','0' 
                                                                                    ,'AM266Y','1' 
                                                                                    ,'AM267Y','2' 
                                                                                    ,'AM268Y','3' 
                                                                                    ,'AM269Y','4'
                                                                                    ,'RR221Y','0' 
                                                                                    ,'RR222Y','1' 
                                                                                    ,'RR223Y','2' 
                                                                                    ,'RR224Y','3' 
                                                                                    ,'RR225Y','4'
                                                                                    ,'AM265' ,'0' 
                                                                                    ,'AM266' ,'1' 
                                                                                    ,'AM267' ,'2' 
                                                                                    ,'AM268' ,'3' 
                                                                                    ,'AM269' ,'4'
                                                                                    ,'RR221' ,'0' 
                                                                                    ,'RR222' ,'1' 
                                                                                    ,'RR223' ,'2' 
                                                                                    ,'RR224' ,'3' 
                                                                                    ,'RR225' ,'4'
                                                                                    ,'MA1732Y','0'
                                                                                    ,'MA1733Y','1'
                                                                                    ,'MA1734Y','1'
                                                                                    ,'MA1735Y','2'
                                                                                    ,'MA1736Y','3'
                                                   ,''
                                                   )
                                     )  menopause_cause
                         , max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM271Y','1'
                                                                             ,'AM279Y','0'
                                                                             ,'RR227Y','1'
                                                                             ,'RR231Y','0'
                                                                             ,'AM271' ,'1'
                                                                             ,'AM279' ,'0'
                                                                             ,'RR227' ,'1'
                                                                             ,'RR231' ,'0'
                                                                             ,'AM277Y' ,'1'
                                                                             ,'AM278Y' ,'1'
                                                                             ,'RR229Y' ,'1'
                                                                             ,'RR230Y' ,'1'
                                                                             ,'AM277'  ,'1'
                                                                             ,'AM278'  ,'1'
                                                                             ,'RR229'  ,'1'
                                                                             ,'RR230'  ,'1'
                                            ,decode(f.inpc_cd,'MA1','9999','')
                                     )
                              ) female_hormones
                         , max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                             ,'AM277Y' ,'1'
                                                                             ,'AM278Y' ,'0'
                                                                             ,'RR229Y' ,'1'
                                                                             ,'RR230Y' ,'0'
                                                                             ,'AM277'  ,'1'
                                                                             ,'AM278'  ,'0'
                                                                             ,'RR229'  ,'1'
                                                                             ,'RR230'  ,'0'
                                                                             ,'MA1745Y','1'
                                                                             ,'MA1746Y','0'
                                            ,''
                                     )
                              ) trt_female_hormones
                         , min(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM274' ,f.inqy_rspn_ctn1
                                                                             ,'AM274Y',f.inqy_rspn_ctn1
                                            ,decode(f.inpc_cd,'RR' ,'9999'
                                                             ,'MA1','9999','')
                                     )
                              ) female_hormones_age
                         , max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM273' ,f.inqy_rspn_ctn1
                                                                             ,'AM273Y',f.inqy_rspn_ctn1
                                            ,decode(f.inpc_cd,'RR' ,'9999'
                                                             ,'MA1','9999','')
                                     )
                              ) female_hormones_amount
                         , max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM275' ,f.inqy_rspn_ctn1||' 개월 또는 '||f.inqy_rspn_ctn2||' 년'
                                                                             ,'AM275Y',f.inqy_rspn_ctn1||' 개월 또는 '||f.inqy_rspn_ctn2||' 년'
                                                                             ,'MA1739Y','0'
                                                                             ,'MA1740Y','1'
                                                                             ,'MA1741Y','2'
                                                                             ,'MA1742Y','3'
                                                                             ,'MA1743Y','4'
                                            ,decode(f.inpc_cd,'RR' ,'9999','')
                                     )
                              ) female_hormones_duration
                         , case
                                when
                                     count(case
                                                when f.inpc_cd = 'AM' and (f.item_sno between 283 and 295) then f.inqy_rspn_cd
                                                else ''
                                           end
                                          ) > 0
                                then '1'
                                else max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM296Y','0'
                                                                          ,'AM296' ,'0'
                                                                          ,decode(f.inpc_cd,'RR' ,'9999'
                                                                                           ,'MA1','9999','')
                                               )
                                        )
                           end  pregnancy
                         , max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM293' ,f.inqy_rspn_ctn1
                                                                             ,'AM293Y',f.inqy_rspn_ctn1
                                            ,decode(f.inpc_cd,'RR' ,'9999'
                                                             ,'MA1','9999','')
                                     )
                              ) pregnancy_first_age
                         , case
                                when /* 만삭경험이 없다면 0으로 표시되어야 함. */
                                     max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM285Y','0'
                                                                                ,'AM285' ,'0',''
                                               )
                                        ) = '0'
                                then '0'
                                when /* 분만경험이 있거나, 출산관련 응답내역이 있다면 1 */
                                     count(case 
                                                -- when f.inpc_cd = 'AM' and f.item_sno = '283' then f.inqy_rspn_cd <- 임신경험만으로 만삭분만을 판단할 수 없음.
                                                when f.inpc_cd = 'AM' and f.item_sno = '286' then f.inqy_rspn_cd
                                                -- when f.inpc_cd = 'AM' and (f.item_sno between 294 and 295) then f.inqy_rspn_cd <- 분만 최초, 마지막 나이로도 만삭분만 판단이 어려움.
                                                else ''
                                           end
                                          ) > 0
                                then '1'
                                else max(DECODE(f.inpc_cd||b.gend_cd,'AMM','' -- 남성은 null
                                               ,decode(f.inpc_cd,'RR' ,'9999'
                                                                ,'MA1','9999','')
                                               )
                                        )
                           end delivery
                         , max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM286Y',f.inqy_rspn_ctn1
                                                                             ,'AM286' ,f.inqy_rspn_ctn1
                                                                             ,'MA1749Y','1'
                                                                             ,'MA1750Y','2'
                                                                             ,'MA1751Y','3'
                                                                             ,'MA1752Y','4'
                                                                             ,'MA1753Y','5'
                                                                             ,'MA1754Y','6'
                                                                             ,'MA1755Y','7'
                                                                             ,'MA1756Y','8'
                                                                             ,'MA1757Y','9'
                                                                             ,'MA1758Y','10'
                                            ,decode(f.inpc_cd,'RR' ,'9999','')
                                     )
                              ) delivery_n
                         , max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM286Y',f.inqy_rspn_ctn2
                                                                             ,'AM286' ,f.inqy_rspn_ctn2
                                            ,decode(f.inpc_cd,'RR' ,'9999'
                                                             ,'MA1','9999','')
                                     )
                              ) delivery_boy
                         , max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM286Y',f.inqy_rspn_ctn3
                                                                             ,'AM286' ,f.inqy_rspn_ctn3
                                            ,decode(f.inpc_cd,'RR' ,'9999'
                                                             ,'MA1','9999','')
                                     )
                              ) delivery_girl
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1760Y','1'
                                                                             ,'MA1761Y','2'
                                                                             ,'MA1762Y','3'
                                                                             ,'MA1763Y','4'
                                                                             ,'MA1764Y','5'
                                                                             ,'MA1765Y','6'
                                                                             ,'MA1766Y','7'
                                                                             ,'MA1767Y','8'
                                                                             ,'MA1768Y','9'
                                                                             ,'MA1769Y','10'
                                            ,decode(f.inpc_cd,'RR','9999'
                                                             ,'AM','9999','')
                                     )
                              ) natural_childbirth
                         , max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'MA1770Y','1'
                                                                             ,'MA1771Y','2'
                                                                             ,'MA1772Y','3'
                                                                             ,'MA1773Y','4'
                                                                             ,'MA1774Y','5'
                                            ,decode(f.inpc_cd,'RR','9999'
                                                             ,'AM','9999','')
                                     )
                              ) caesarean_section
                         , max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM294' ,f.inqy_rspn_ctn1
                                                                             ,'AM294Y',f.inqy_rspn_ctn1
                                            ,decode(f.inpc_cd,'RR' ,'9999'
                                                             ,'MA1','9999','')
                                     )
                              ) delivery_first_age
                         , max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM295' ,f.inqy_rspn_ctn1
                                                                             ,'AM295Y',f.inqy_rspn_ctn1
                                            ,decode(f.inpc_cd,'RR' ,'9999'
                                                             ,'MA1','9999','')
                                     )
                              ) delivery_last_age
                         , max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM288Y' ,'0'
                                                                             ,'AM289Y' ,'1'
                                                                             ,'AM288'  ,'0'
                                                                             ,'AM289'  ,'1'
                                                                             ,'MA1799Y','1'
                                                                             ,'MA1800Y','0'
                                            ,decode(f.inpc_cd,'RR' ,'9999','')
                                     )
                              ) premature_birth
                         , max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM289Y',f.inqy_rspn_ctn1
                                                                             ,'AM289' ,f.inqy_rspn_ctn1
                                                                             ,'MA1801Y','1'
                                                                             ,'MA1802Y','2'
                                                                             ,'MA1803Y','3'
                                                                             ,'MA1804Y','4'
                                                                             ,'MA1805Y','5'
                                                                             ,'MA1806Y','6'
                                                                             ,'MA1807Y','7'
                                                                             ,'MA1808Y','8'
                                                                             ,'MA1809Y','9'
                                                                             ,'MA1810Y','10'
                                            ,decode(f.inpc_cd,'RR' ,'9999','')
                                     )
                              ) premature_birth_n
                         , case
                                when /*case2. 자연/인공유산 응답내역이 있으나, 해당 문진 응답이 null이면 1 */
                                     count(
                                           case 
                                                when f.inpc_cd = 'AM'  and f.item_sno = 292 and (f.inqy_rspn_ctn1 is not null or f.inqy_rspn_ctn2 is not null) then f.inqy_rspn_cd
                                                when f.inpc_cd = 'MA1' and (f.item_sno between 778 and 797) then f.ceck_yn||f.inqy_rspn_ctn1 -- MA1 문진의 경우 CTN은 응답이 있어도 ceck_yn이 null이므로 함께 고려
                                                else ''
                                           end
                                          ) > 0
                                 and max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM291Y' ,'0'
                                                                                ,'AM292Y' ,'1'
                                                                                ,'AM291'  ,'0'
                                                                                ,'AM292'  ,'1'
                                                                                ,'MA1776Y','1'
                                                                                ,'MA1777Y','0','')) is null
                                then '1'
                                else
                                     max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM291Y' ,'0'
                                                                                ,'AM292Y' ,'1'
                                                                                ,'AM291'  ,'0'
                                                                                ,'AM292'  ,'1'
                                                                                ,'MA1776Y','1'
                                                                                ,'MA1777Y','0'
                                               ,decode(f.inpc_cd,'RR' ,'9999','')
                                               )
                                        )
                           end  miscarriage
                         , max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM292Y',f.inqy_rspn_ctn1
                                                                      ,'AM292' ,f.inqy_rspn_ctn1
                                                                      ,'MA1778Y','1'
                                                                      ,'MA1779Y','2'
                                                                      ,'MA1780Y','3'
                                                                      ,'MA1781Y','4'
                                                                      ,'MA1782Y','5'
                                                                      ,'MA1783Y','6'
                                                                      ,'MA1784Y','7'
                                                                      ,'MA1785Y','8'
                                                                      ,'MA1786Y','9'
                                                                      ,'MA1787Y','10'
                                     ,decode(f.inpc_cd,'RR' ,'9999','')
                                     )
                              ) miscarriage_natural_n
                         , max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM292Y',f.inqy_rspn_ctn2
                                                                      ,'AM292' ,f.inqy_rspn_ctn2
                                                                      ,'MA1788Y','1'
                                                                      ,'MA1789Y','2'
                                                                      ,'MA1790Y','3'
                                                                      ,'MA1791Y','4'
                                                                      ,'MA1792Y','5'
                                                                      ,'MA1793Y','6'
                                                                      ,'MA1794Y','7'
                                                                      ,'MA1795Y','8'
                                                                      ,'MA1796Y','9'
                                                                      ,'MA1797Y','10'
                                     ,decode(f.inpc_cd,'RR' ,'9999','')
                                     )
                              ) miscarriage_artificial_n
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM301Y','1'
                                                                      ,'AM305Y','0'
                                                                      ,'AM301' ,'1'
                                                                      ,'AM305' ,'0'
                                                                      ,'AM302' ,'1'
                                                                      ,'AM302Y','1'
                                                                      ,'AM303' ,'1'
                                                                      ,'AM303Y','1'
                                                                      ,'AM304' ,'1'
                                                                      ,'AM304Y','1'
                                     ,decode(f.inpc_cd,'RR' ,'9999'
                                                      ,'MA1','9999','')
                                     )
                              ) pap
                         , max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM302' ,f.inqy_rspn_ctn1
                                                                      ,'AM302Y',f.inqy_rspn_ctn1
                                     ,decode(f.inpc_cd,'RR' ,'9999'
                                                      ,'MA1','9999','')
                                     )
                              ) pap_first_age
                         , max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM303' ,f.inqy_rspn_ctn1
                                                                      ,'AM303Y',f.inqy_rspn_ctn1
                                     ,decode(f.inpc_cd,'RR' ,'9999'
                                                      ,'MA1','9999','')
                                     )
                              ) pap_last_age
                         , max(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM304' ,f.inqy_rspn_ctn1||' 년에'||f.inqy_rspn_ctn2||' 회'
                                                                      ,'AM304Y',f.inqy_rspn_ctn1||' 년에'||f.inqy_rspn_ctn2||' 회'
                                     ,decode(f.inpc_cd,'RR' ,'9999'
                                                      ,'MA1','9999','')
                                     )
                              ) pap_freq
                    /* 스트레스 */
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM307Y' ,0
                                                                      ,'AM308Y' ,1
                                                                      ,'AM309Y' ,2
                                                                      ,'AM310Y' ,3
                                                                      ,'AM307'  ,0
                                                                      ,'AM308'  ,1
                                                                      ,'AM309'  ,2
                                                                      ,'AM310'  ,3
                                                                      ,'MA1813Y',to_number(g.fod_base_qty)
                                                                      ,'MA1814Y',to_number(g.fod_base_qty)
                                                                      ,'MA1815Y',to_number(g.fod_base_qty)
                                                                      ,'MA1816Y',to_number(g.fod_base_qty)
                                                                      ,decode(f.inpc_cd,'RR','9999','')))                stress_q1
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM312Y' ,3
                                                                      ,'AM313Y' ,2
                                                                      ,'AM314Y' ,1
                                                                      ,'AM315Y' ,0
                                                                      ,'AM312'  ,3
                                                                      ,'AM313'  ,2
                                                                      ,'AM314'  ,1
                                                                      ,'AM315'  ,0
                                                                      ,'MA1818Y',to_number(g.fod_base_qty)
                                                                      ,'MA1819Y',to_number(g.fod_base_qty)
                                                                      ,'MA1820Y',to_number(g.fod_base_qty)
                                                                      ,'MA1821Y',to_number(g.fod_base_qty)
                                                                      ,decode(f.inpc_cd,'RR','9999','')))                stress_q2
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM317Y' ,3
                                                                      ,'AM318Y' ,2
                                                                      ,'AM319Y' ,1
                                                                      ,'AM320Y' ,0
                                                                      ,'AM317'  ,3
                                                                      ,'AM318'  ,2
                                                                      ,'AM319'  ,1
                                                                      ,'AM320'  ,0
                                                                      ,'MA1823Y',to_number(g.fod_base_qty)
                                                                      ,'MA1824Y',to_number(g.fod_base_qty)
                                                                      ,'MA1825Y',to_number(g.fod_base_qty)
                                                                      ,'MA1826Y',to_number(g.fod_base_qty)
                                                                      ,decode(f.inpc_cd,'RR','9999','')))                stress_q3
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM322Y' ,3
                                                                      ,'AM323Y' ,2
                                                                      ,'AM324Y' ,1
                                                                      ,'AM325Y' ,0
                                                                      ,'AM322'  ,3
                                                                      ,'AM323'  ,2
                                                                      ,'AM324'  ,1
                                                                      ,'AM325'  ,0
                                                                      ,'MA1828Y',to_number(g.fod_base_qty)
                                                                      ,'MA1829Y',to_number(g.fod_base_qty)
                                                                      ,'MA1830Y',to_number(g.fod_base_qty)
                                                                      ,'MA1831Y',to_number(g.fod_base_qty)
                                                                      ,decode(f.inpc_cd,'RR','9999','')))                stress_q4
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM327Y' ,0
                                                                      ,'AM328Y' ,1
                                                                      ,'AM329Y' ,2
                                                                      ,'AM330Y' ,3
                                                                      ,'AM327'  ,0
                                                                      ,'AM328'  ,1
                                                                      ,'AM329'  ,2
                                                                      ,'AM330'  ,3
                                                                      ,'MA1833Y',to_number(g.fod_base_qty)
                                                                      ,'MA1834Y',to_number(g.fod_base_qty)
                                                                      ,'MA1835Y',to_number(g.fod_base_qty)
                                                                      ,'MA1836Y',to_number(g.fod_base_qty)
                                                                      ,decode(f.inpc_cd,'RR','9999','')))                stress_q5
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM332Y' ,0
                                                                      ,'AM333Y' ,1
                                                                      ,'AM334Y' ,2
                                                                      ,'AM335Y' ,3
                                                                      ,'AM332'  ,0
                                                                      ,'AM333'  ,1
                                                                      ,'AM334'  ,2
                                                                      ,'AM335'  ,3
                                                                      ,'MA1838Y',to_number(g.fod_base_qty)
                                                                      ,'MA1839Y',to_number(g.fod_base_qty)
                                                                      ,'MA1840Y',to_number(g.fod_base_qty)
                                                                      ,'MA1841Y',to_number(g.fod_base_qty)
                                                                      ,decode(f.inpc_cd,'RR','9999','')))                stress_q6
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM337Y' ,3
                                                                      ,'AM338Y' ,2
                                                                      ,'AM339Y' ,1
                                                                      ,'AM340Y' ,0
                                                                      ,'AM337'  ,3
                                                                      ,'AM338'  ,2
                                                                      ,'AM339'  ,1
                                                                      ,'AM340'  ,0
                                                                      ,'MA1843Y',to_number(g.fod_base_qty)
                                                                      ,'MA1844Y',to_number(g.fod_base_qty)
                                                                      ,'MA1845Y',to_number(g.fod_base_qty)
                                                                      ,'MA1846Y',to_number(g.fod_base_qty)
                                                                      ,decode(f.inpc_cd,'RR','9999','')))                stress_q7
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM342Y' ,0
                                                                      ,'AM343Y' ,1
                                                                      ,'AM344Y' ,2
                                                                      ,'AM345Y' ,3
                                                                      ,'AM342'  ,0
                                                                      ,'AM343'  ,1
                                                                      ,'AM344'  ,2
                                                                      ,'AM345'  ,3
                                                                      ,'MA1848Y',to_number(g.fod_base_qty)
                                                                      ,'MA1849Y',to_number(g.fod_base_qty)
                                                                      ,'MA1850Y',to_number(g.fod_base_qty)
                                                                      ,'MA1851Y',to_number(g.fod_base_qty)
                                                                      ,decode(f.inpc_cd,'RR','9999','')))                stress_q8
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM347Y' ,0
                                                                      ,'AM348Y' ,1
                                                                      ,'AM349Y' ,2
                                                                      ,'AM350Y' ,3
                                                                      ,'AM347'  ,0
                                                                      ,'AM348'  ,1
                                                                      ,'AM349'  ,2
                                                                      ,'AM350'  ,3
                                                                      ,'MA1853Y',to_number(g.fod_base_qty)
                                                                      ,'MA1854Y',to_number(g.fod_base_qty)
                                                                      ,'MA1855Y',to_number(g.fod_base_qty)
                                                                      ,'MA1856Y',to_number(g.fod_base_qty)
                                                                      ,decode(f.inpc_cd,'RR','9999','')))                stress_q9
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM352Y' ,0
                                                                      ,'AM353Y' ,1
                                                                      ,'AM354Y' ,2
                                                                      ,'AM355Y' ,3
                                                                      ,'AM352'  ,0
                                                                      ,'AM353'  ,1
                                                                      ,'AM354'  ,2
                                                                      ,'AM355'  ,3
                                                                      ,'MA1858Y',to_number(g.fod_base_qty)
                                                                      ,'MA1859Y',to_number(g.fod_base_qty)
                                                                      ,'MA1860Y',to_number(g.fod_base_qty)
                                                                      ,'MA1861Y',to_number(g.fod_base_qty)
                                                                      ,decode(f.inpc_cd,'RR','9999','')))                stress_q10
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM357Y' ,0
                                                                      ,'AM358Y' ,1
                                                                      ,'AM359Y' ,2
                                                                      ,'AM360Y' ,3
                                                                      ,'AM357'  ,0
                                                                      ,'AM358'  ,1
                                                                      ,'AM359'  ,2
                                                                      ,'AM360'  ,3
                                                                      ,'MA1863Y',to_number(g.fod_base_qty)
                                                                      ,'MA1864Y',to_number(g.fod_base_qty)
                                                                      ,'MA1865Y',to_number(g.fod_base_qty)
                                                                      ,'MA1866Y',to_number(g.fod_base_qty)
                                                                      ,decode(f.inpc_cd,'RR','9999','')))                stress_q11
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM362Y' ,0
                                                                      ,'AM363Y' ,1
                                                                      ,'AM364Y' ,2
                                                                      ,'AM365Y' ,3
                                                                      ,'AM362'  ,0
                                                                      ,'AM363'  ,1
                                                                      ,'AM364'  ,2
                                                                      ,'AM365'  ,3
                                                                      ,'MA1868Y',to_number(g.fod_base_qty)
                                                                      ,'MA1869Y',to_number(g.fod_base_qty)
                                                                      ,'MA1870Y',to_number(g.fod_base_qty)
                                                                      ,'MA1871Y',to_number(g.fod_base_qty)
                                                                      ,decode(f.inpc_cd,'RR','9999','')))                stress_q12
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM367Y' ,3
                                                                      ,'AM368Y' ,2
                                                                      ,'AM369Y' ,1
                                                                      ,'AM370Y' ,0
                                                                      ,'AM367'  ,3
                                                                      ,'AM368'  ,2
                                                                      ,'AM369'  ,1
                                                                      ,'AM370'  ,0
                                                                      ,'MA1873Y',to_number(g.fod_base_qty)
                                                                      ,'MA1874Y',to_number(g.fod_base_qty)
                                                                      ,'MA1875Y',to_number(g.fod_base_qty)
                                                                      ,'MA1876Y',to_number(g.fod_base_qty)
                                                                      ,decode(f.inpc_cd,'RR','9999','')))                stress_q13
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM372Y' ,0
                                                                      ,'AM373Y' ,1
                                                                      ,'AM374Y' ,2
                                                                      ,'AM375Y' ,3
                                                                      ,'AM372'  ,0
                                                                      ,'AM373'  ,1
                                                                      ,'AM374'  ,2
                                                                      ,'AM375'  ,3
                                                                      ,'MA1878Y',to_number(g.fod_base_qty)
                                                                      ,'MA1879Y',to_number(g.fod_base_qty)
                                                                      ,'MA1880Y',to_number(g.fod_base_qty)
                                                                      ,'MA1881Y',to_number(g.fod_base_qty)
                                                                      ,decode(f.inpc_cd,'RR','9999','')))                stress_q14
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM377Y' ,3
                                                                      ,'AM378Y' ,2
                                                                      ,'AM379Y' ,1
                                                                      ,'AM380Y' ,0
                                                                      ,'AM377'  ,3
                                                                      ,'AM378'  ,2
                                                                      ,'AM379'  ,1
                                                                      ,'AM380'  ,0
                                                                      ,'MA1883Y',to_number(g.fod_base_qty)
                                                                      ,'MA1884Y',to_number(g.fod_base_qty)
                                                                      ,'MA1885Y',to_number(g.fod_base_qty)
                                                                      ,'MA1886Y',to_number(g.fod_base_qty)
                                                                      ,decode(f.inpc_cd,'RR','9999','')))                stress_q15
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM382Y' ,3
                                                                      ,'AM383Y' ,2
                                                                      ,'AM384Y' ,1
                                                                      ,'AM385Y' ,0
                                                                      ,'AM382'  ,3
                                                                      ,'AM383'  ,2
                                                                      ,'AM384'  ,1
                                                                      ,'AM385'  ,0
                                                                      ,'MA1888Y',to_number(g.fod_base_qty)
                                                                      ,'MA1889Y',to_number(g.fod_base_qty)
                                                                      ,'MA1890Y',to_number(g.fod_base_qty)
                                                                      ,'MA1891Y',to_number(g.fod_base_qty)
                                                                      ,decode(f.inpc_cd,'RR','9999','')))                stress_q16
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM387Y' ,0
                                                                      ,'AM388Y' ,1
                                                                      ,'AM389Y' ,2
                                                                      ,'AM390Y' ,3
                                                                      ,'AM387'  ,0
                                                                      ,'AM388'  ,1
                                                                      ,'AM389'  ,2
                                                                      ,'AM390'  ,3
                                                                      ,'MA1893Y',to_number(g.fod_base_qty)
                                                                      ,'MA1894Y',to_number(g.fod_base_qty)
                                                                      ,'MA1895Y',to_number(g.fod_base_qty)
                                                                      ,'MA1896Y',to_number(g.fod_base_qty)
                                                                      ,decode(f.inpc_cd,'RR','9999','')))                stress_q17
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM392Y' ,0
                                                                      ,'AM393Y' ,1
                                                                      ,'AM394Y' ,2
                                                                      ,'AM395Y' ,3
                                                                      ,'AM392'  ,0
                                                                      ,'AM393'  ,1
                                                                      ,'AM394'  ,2
                                                                      ,'AM395'  ,3
                                                                      ,'MA1898Y',to_number(g.fod_base_qty)
                                                                      ,'MA1899Y',to_number(g.fod_base_qty)
                                                                      ,'MA1900Y',to_number(g.fod_base_qty)
                                                                      ,'MA1901Y',to_number(g.fod_base_qty)
                                                                      ,decode(f.inpc_cd,'RR','9999','')))                stress_q18
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM397Y' ,0
                                                                      ,'AM398Y' ,1
                                                                      ,'AM399Y' ,2
                                                                      ,'AM400Y' ,3
                                                                      ,'AM401Y' ,4
                                                                      ,'AM397'  ,0
                                                                      ,'AM398'  ,1
                                                                      ,'AM399'  ,2
                                                                      ,'AM400'  ,3
                                                                      ,'AM401'  ,4
                                                                      ,'MA1903Y',0
                                                                      ,'MA1904Y',1
                                                                      ,'MA1905Y',2
                                                                      ,'MA1906Y',3
                                                                      ,'MA1907Y',4
                                                                      ,decode(f.inpc_cd,'RR','9999','')))                stress_q19
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM403Y' ,0
                                                                      ,'AM404Y' ,1
                                                                      ,'AM405Y' ,2
                                                                      ,'AM406Y' ,3
                                                                      ,'AM407Y' ,4
                                                                      ,'AM403'  ,0
                                                                      ,'AM404'  ,1
                                                                      ,'AM405'  ,2
                                                                      ,'AM406'  ,3
                                                                      ,'AM407'  ,4
                                                                      ,'MA1909Y',0
                                                                      ,'MA1910Y',1
                                                                      ,'MA1911Y',2
                                                                      ,'MA1912Y',3
                                                                      ,'MA1913Y',4
                                                                      ,decode(f.inpc_cd,'RR','9999','')))                stress_q20
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM409Y' ,1
                                                                      ,'AM410Y' ,0
                                                                      ,'AM409'  ,1
                                                                      ,'AM410'  ,0
                                                                      ,'MA1915Y',1
                                                                      ,'MA1916Y',0
                                                                      ,decode(f.inpc_cd,'RR','9999','')))                stress_q21
                         , case
                                when f.inpc_cd = 'RR' then '9999' --> case문의 순서 때문에 먼저 고려해야 함.
                                when (
                                      case -- factor 1 area
                                           when
                                                count(
                                                      case 
                                                           when f.inpc_cd = 'AM'  and item_sno between 342 and 345 then f.ceck_yn--               stress_q8
                                                           when f.inpc_cd = 'AM'  and item_sno between 347 and 350 then f.ceck_yn--               stress_q9
                                                           when f.inpc_cd = 'AM'  and item_sno between 352 and 355 then f.ceck_yn--               stress_q10
                                                           when f.inpc_cd = 'AM'  and item_sno between 357 and 360 then f.ceck_yn--               stress_q11
                                                           when f.inpc_cd = 'AM'  and item_sno between 362 and 365 then f.ceck_yn--               stress_q12
                                                           when f.inpc_cd = 'AM'  and item_sno between 372 and 375 then f.ceck_yn--               stress_q14
                                                           when f.inpc_cd = 'AM'  and item_sno between 387 and 390 then f.ceck_yn--               stress_q17
                                                           when f.inpc_cd = 'AM'  and item_sno between 392 and 395 then f.ceck_yn--               stress_q18
                                                           when f.inpc_cd = 'MA1' and item_sno between 848 and 851 then f.ceck_yn--               stress_q8
                                                           when f.inpc_cd = 'MA1' and item_sno between 853 and 856 then f.ceck_yn--               stress_q9
                                                           when f.inpc_cd = 'MA1' and item_sno between 858 and 861 then f.ceck_yn--               stress_q10
                                                           when f.inpc_cd = 'MA1' and item_sno between 863 and 866 then f.ceck_yn--               stress_q11
                                                           when f.inpc_cd = 'MA1' and item_sno between 868 and 871 then f.ceck_yn--               stress_q12
                                                           when f.inpc_cd = 'MA1' and item_sno between 878 and 881 then f.ceck_yn--               stress_q14
                                                           when f.inpc_cd = 'MA1' and item_sno between 893 and 896 then f.ceck_yn--               stress_q17
                                                           when f.inpc_cd = 'MA1' and item_sno between 898 and 901 then f.ceck_yn--               stress_q18
                                                           else ''
                                                      end
                                                     ) > 6 then 'Y'
                                           else 'X'
                                      end ||
                                      case -- factor 3 area
                                           when
                                                count(
                                                      case 
                                                           when f.inpc_cd = 'AM'  and item_sno between 367 and 370 then f.ceck_yn--               stress_q13
                                                           when f.inpc_cd = 'AM'  and item_sno between 377 and 380 then f.ceck_yn--               stress_q15
                                                           when f.inpc_cd = 'AM'  and item_sno between 382 and 385 then f.ceck_yn--               stress_q16
                                                           when f.inpc_cd = 'MA1' and item_sno between 873 and 876 then f.ceck_yn--               stress_q13
                                                           when f.inpc_cd = 'MA1' and item_sno between 883 and 886 then f.ceck_yn--               stress_q15
                                                           when f.inpc_cd = 'MA1' and item_sno between 888 and 891 then f.ceck_yn--               stress_q16
                                                           else ''
                                                      end
                                                     ) > 1 then 'Y'
                                           else 'X'
                                      end ||
                                      case -- factor 2 area
                                           when
                                                count(
                                                      case 
                                                           when f.inpc_cd = 'AM'  and item_sno between 307 and 310 then f.ceck_yn--               stress_q1
                                                           when f.inpc_cd = 'AM'  and item_sno between 312 and 315 then f.ceck_yn--               stress_q2
                                                           when f.inpc_cd = 'AM'  and item_sno between 317 and 320 then f.ceck_yn--               stress_q3
                                                           when f.inpc_cd = 'AM'  and item_sno between 327 and 330 then f.ceck_yn--               stress_q5
                                                           when f.inpc_cd = 'AM'  and item_sno between 332 and 335 then f.ceck_yn--               stress_q6
                                                           when f.inpc_cd = 'MA1' and item_sno between 813 and 816 then f.ceck_yn--               stress_q1
                                                           when f.inpc_cd = 'MA1' and item_sno between 818 and 821 then f.ceck_yn--               stress_q2
                                                           when f.inpc_cd = 'MA1' and item_sno between 823 and 826 then f.ceck_yn--               stress_q3
                                                           when f.inpc_cd = 'MA1' and item_sno between 833 and 836 then f.ceck_yn--               stress_q5
                                                           when f.inpc_cd = 'MA1' and item_sno between 838 and 841 then f.ceck_yn--               stress_q6
                                                           else ''
                                                      end
                                                     ) > 3 then 'Y'
                                           else 'X'
                                      end ||
                                      case -- factor 4 area
                                           when
                                                count(
                                                      case 
                                                           when f.inpc_cd = 'AM'  and item_sno between 322 and 325 then f.ceck_yn--               stress_q4
                                                           when f.inpc_cd = 'AM'  and item_sno between 337 and 340 then f.ceck_yn--               stress_q7
                                                           when f.inpc_cd = 'MA1' and item_sno between 828 and 381 then f.ceck_yn--               stress_q4
                                                           when f.inpc_cd = 'MA1' and item_sno between 843 and 846 then f.ceck_yn--               stress_q7
                                                           else ''
                                                      end
                                                     ) > 0 then 'Y'
                                           else 'X'
                                      end
                                     ) != 'YYYY'
                                then ''
                                else
                                     decode(f.inpc_cd,'RR','9999'
                                                     ,sum(
                                                          DECODE(f.inpc_cd||f.item_sno||f.ceck_yn,'AM307Y' ,0
                                                                                                 ,'AM308Y' ,1
                                                                                                 ,'AM309Y' ,2
                                                                                                 ,'AM310Y' ,3
                                                                                                 ,'AM307' ,0
                                                                                                 ,'AM308' ,1
                                                                                                 ,'AM309' ,2
                                                                                                 ,'AM310' ,3
                                                                                                 ,'MA1813Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1814Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1815Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1816Y',to_number(g.fod_base_qty)
                                                                                                 --,decode(f.inpc_cd,'RR','9999','')))                STRESS01
                                                                                                 ,'AM312Y' ,3
                                                                                                 ,'AM313Y' ,2
                                                                                                 ,'AM314Y' ,1
                                                                                                 ,'AM315Y' ,0
                                                                                                 ,'AM312' ,3
                                                                                                 ,'AM313' ,2
                                                                                                 ,'AM314' ,1
                                                                                                 ,'AM315' ,0
                                                                                                 ,'MA1818Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1819Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1820Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1821Y',to_number(g.fod_base_qty)
                                                                                                 --,decode(f.inpc_cd,'RR','9999','')))                STRESS02
                                                                                                 ,'AM317Y' ,3
                                                                                                 ,'AM318Y' ,2
                                                                                                 ,'AM319Y' ,1
                                                                                                 ,'AM320Y' ,0
                                                                                                 ,'AM317' ,3
                                                                                                 ,'AM318' ,2
                                                                                                 ,'AM319' ,1
                                                                                                 ,'AM320' ,0
                                                                                                 ,'MA1823Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1824Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1825Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1826Y',to_number(g.fod_base_qty)
                                                                                                 --,decode(f.inpc_cd,'RR','9999','')))                STRESS03
                                                                                                 ,'AM322Y' ,3
                                                                                                 ,'AM323Y' ,2
                                                                                                 ,'AM324Y' ,1
                                                                                                 ,'AM325Y' ,0
                                                                                                 ,'AM322' ,3
                                                                                                 ,'AM323' ,2
                                                                                                 ,'AM324' ,1
                                                                                                 ,'AM325' ,0
                                                                                                 ,'MA1828Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1829Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1830Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1831Y',to_number(g.fod_base_qty)
                                                                                                 --,decode(f.inpc_cd,'RR','9999','')))                STRESS04
                                                                                                 ,'AM327Y' ,0
                                                                                                 ,'AM328Y' ,1
                                                                                                 ,'AM329Y' ,2
                                                                                                 ,'AM330Y' ,3
                                                                                                 ,'AM327' ,0
                                                                                                 ,'AM328' ,1
                                                                                                 ,'AM329' ,2
                                                                                                 ,'AM330' ,3
                                                                                                 ,'MA1833Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1834Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1835Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1836Y',to_number(g.fod_base_qty)
                                                                                                 --,decode(f.inpc_cd,'RR','9999','')))                STRESS05
                                                                                                 ,'AM332Y' ,0
                                                                                                 ,'AM333Y' ,1
                                                                                                 ,'AM334Y' ,2
                                                                                                 ,'AM335Y' ,3
                                                                                                 ,'AM332' ,0
                                                                                                 ,'AM333' ,1
                                                                                                 ,'AM334' ,2
                                                                                                 ,'AM335' ,3
                                                                                                 ,'MA1838Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1839Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1840Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1841Y',to_number(g.fod_base_qty)
                                                                                                 --,decode(f.inpc_cd,'RR','9999','')))                STRESS06
                                                                                                 ,'AM337Y' ,3
                                                                                                 ,'AM338Y' ,2
                                                                                                 ,'AM339Y' ,1
                                                                                                 ,'AM340Y' ,0
                                                                                                 ,'AM337' ,3
                                                                                                 ,'AM338' ,2
                                                                                                 ,'AM339' ,1
                                                                                                 ,'AM340' ,0
                                                                                                 ,'MA1843Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1844Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1845Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1846Y',to_number(g.fod_base_qty)
                                                                                                 --,decode(f.inpc_cd,'RR','9999','')))                STRESS07
                                                                                                 ,'AM342Y' ,0
                                                                                                 ,'AM343Y' ,1
                                                                                                 ,'AM344Y' ,2
                                                                                                 ,'AM345Y' ,3
                                                                                                 ,'AM342' ,0
                                                                                                 ,'AM343' ,1
                                                                                                 ,'AM344' ,2
                                                                                                 ,'AM345' ,3
                                                                                                 ,'MA1848Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1849Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1850Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1851Y',to_number(g.fod_base_qty)
                                                                                                 --,decode(f.inpc_cd,'RR','9999','')))                STRESS08
                                                                                                 ,'AM347Y' ,0
                                                                                                 ,'AM348Y' ,1
                                                                                                 ,'AM349Y' ,2
                                                                                                 ,'AM350Y' ,3
                                                                                                 ,'AM347' ,0
                                                                                                 ,'AM348' ,1
                                                                                                 ,'AM349' ,2
                                                                                                 ,'AM350' ,3
                                                                                                 ,'MA1853Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1854Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1855Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1856Y',to_number(g.fod_base_qty)
                                                                                                 --,decode(f.inpc_cd,'RR','9999','')))                STRESS09
                                                                                                 ,'AM352Y' ,0
                                                                                                 ,'AM353Y' ,1
                                                                                                 ,'AM354Y' ,2
                                                                                                 ,'AM355Y' ,3
                                                                                                 ,'AM352' ,0
                                                                                                 ,'AM353' ,1
                                                                                                 ,'AM354' ,2
                                                                                                 ,'AM355' ,3
                                                                                                 ,'MA1858Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1859Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1860Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1861Y',to_number(g.fod_base_qty)
                                                                                                 --,decode(f.inpc_cd,'RR','9999','')))                STRESS10
                                                                                                 ,'AM357Y' ,0
                                                                                                 ,'AM358Y' ,1
                                                                                                 ,'AM359Y' ,2
                                                                                                 ,'AM360Y' ,3
                                                                                                 ,'AM357' ,0
                                                                                                 ,'AM358' ,1
                                                                                                 ,'AM359' ,2
                                                                                                 ,'AM360' ,3
                                                                                                 ,'MA1863Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1864Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1865Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1866Y',to_number(g.fod_base_qty)
                                                                                                 --,decode(f.inpc_cd,'RR','9999','')))                STRESS11
                                                                                                 ,'AM362Y' ,0
                                                                                                 ,'AM363Y' ,1
                                                                                                 ,'AM364Y' ,2
                                                                                                 ,'AM365Y' ,3
                                                                                                 ,'AM362' ,0
                                                                                                 ,'AM363' ,1
                                                                                                 ,'AM364' ,2
                                                                                                 ,'AM365' ,3
                                                                                                 ,'MA1868Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1869Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1870Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1871Y',to_number(g.fod_base_qty)
                                                                                                 --,decode(f.inpc_cd,'RR','9999','')))                STRESS12
                                                                                                 ,'AM367Y' ,3
                                                                                                 ,'AM368Y' ,2
                                                                                                 ,'AM369Y' ,1
                                                                                                 ,'AM370Y' ,0
                                                                                                 ,'AM367' ,3
                                                                                                 ,'AM368' ,2
                                                                                                 ,'AM369' ,1
                                                                                                 ,'AM370' ,0
                                                                                                 ,'MA1873Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1874Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1875Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1876Y',to_number(g.fod_base_qty)
                                                                                                 --,decode(f.inpc_cd,'RR','9999','')))                STRESS13
                                                                                                 ,'AM372Y' ,0
                                                                                                 ,'AM373Y' ,1
                                                                                                 ,'AM374Y' ,2
                                                                                                 ,'AM375Y' ,3
                                                                                                 ,'AM372' ,0
                                                                                                 ,'AM373' ,1
                                                                                                 ,'AM374' ,2
                                                                                                 ,'AM375' ,3
                                                                                                 ,'MA1878Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1879Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1880Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1881Y',to_number(g.fod_base_qty)
                                                                                                 --,decode(f.inpc_cd,'RR','9999','')))                STRESS14
                                                                                                 ,'AM377Y' ,3
                                                                                                 ,'AM378Y' ,2
                                                                                                 ,'AM379Y' ,1
                                                                                                 ,'AM380Y' ,0
                                                                                                 ,'AM377' ,3
                                                                                                 ,'AM378' ,2
                                                                                                 ,'AM379' ,1
                                                                                                 ,'AM380' ,0
                                                                                                 ,'MA1883Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1884Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1885Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1886Y',to_number(g.fod_base_qty)
                                                                                                 --,decode(f.inpc_cd,'RR','9999','')))                STRESS15
                                                                                                 ,'AM382Y' ,3
                                                                                                 ,'AM383Y' ,2
                                                                                                 ,'AM384Y' ,1
                                                                                                 ,'AM385Y' ,0
                                                                                                 ,'AM382' ,3
                                                                                                 ,'AM383' ,2
                                                                                                 ,'AM384' ,1
                                                                                                 ,'AM385' ,0
                                                                                                 ,'MA1888Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1889Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1890Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1891Y',to_number(g.fod_base_qty)
                                                                                                 --,decode(f.inpc_cd,'RR','9999','')))                STRESS16
                                                                                                 ,'AM387Y' ,0
                                                                                                 ,'AM388Y' ,1
                                                                                                 ,'AM389Y' ,2
                                                                                                 ,'AM390Y' ,3
                                                                                                 ,'AM387' ,0
                                                                                                 ,'AM388' ,1
                                                                                                 ,'AM389' ,2
                                                                                                 ,'AM390' ,3
                                                                                                 ,'MA1893Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1894Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1895Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1896Y',to_number(g.fod_base_qty)
                                                                                                 --,decode(f.inpc_cd,'RR','9999','')))                STRESS17
                                                                                                 ,'AM392Y' ,0
                                                                                                 ,'AM393Y' ,1
                                                                                                 ,'AM394Y' ,2
                                                                                                 ,'AM395Y' ,3
                                                                                                 ,'AM392' ,0
                                                                                                 ,'AM393' ,1
                                                                                                 ,'AM394' ,2
                                                                                                 ,'AM395' ,3
                                                                                                 ,'MA1898Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1899Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1900Y',to_number(g.fod_base_qty)
                                                                                                 ,'MA1901Y',to_number(g.fod_base_qty)
                                                                                                 --,decode(f.inpc_cd,'RR','9999','')))                STRESS18
                                                                )
                                                         ) 
                                           )
                           end STRESS_score
                      from 스키마.3E3C0E433E3C0E3E28@SMISR_스키마 a
                         , 스키마.0E5B5B285B28402857@SMISR_스키마 b
                         , 스키마.3E3C23302E333E0E28@SMISR_스키마 f
                         , 스키마.3E3C23302E333E3C28@SMISR_스키마 g
                     where 
                           a.ordr_prrn_ymd between to_date(&qfrdt,'yyyymmdd') and to_date(&qtodt,'yyyymmdd')
                       and a.ordr_ymd is not null
                       and a.cncl_dt is null
                       and b.ptno = a.ptno
                       and f.ptno = a.ptno
                       and f.ordr_prrn_ymd = a.ordr_prrn_ymd
                       and f.inpc_cd in ('AM','RR','MA1')
                       AND (-- AM, RR의 경우는 응답한 것만 저장되었으므로, 모두 범위에 포함
                              (f.inpc_cd = 'AM'  and f.item_sno between 1   and 500)
                           OR (f.inpc_cd = 'RR'  and f.item_sno between 1   and 300)
                           OR (f.inpc_cd = 'MA1' and f.item_sno between 657 and 917)
                           )
                       and f.rprs_apnt_no = a.rprs_apnt_no
                       and f.qstn_cd1 = g.inqy_cd(+)
                       and a.ptno not in (
                                          &not_in_ptno
                                         )
                     group by f.rprs_apnt_no
                         , F.PTNO
                         , f.ordr_prrn_ymd
                         , f.inpc_cd
                         , b.gend_cd
                   ) h                       
           )
                
            loop
            begin   -- 데이터 update
                          update /*+ append */
                                 스키마.1543294D47144D302E333E0E28 a
                             set 
                                 a.ML1_1                               = drh."1" 
                               , a.ML2_1                               = drh."2" 
                               , a.ML3_1                               = drh."3" 
                               , a.ML4_1                               = drh."4" 
                               , a.ML5_1                               = drh."5" 
                               , a.ML6_1                               = drh."6" 
                               , a.ML7_1                               = drh."7" 
                               , a.ML8_1                               = drh."8" 
                               , a.ML_SCORE                            = drh."9" 
                               , a.MENSTRUATION_LAST_YY                = drh."10"
                               , a.MENSTRUATION_LAST_MM                = drh."11"
                               , a.MENSTRUATION_LAST_DD                = drh."12"
                               , a.MENARCHE_AGE                        = drh."13"
                               , a.NO_MENSTRUATION                     = drh."14"
                               , a.MENSTRUATION_AVG_DURATION           = drh."15"
                               , a.ABNORMAL_BLEEDING                   = drh."16"
                               , a.VAGINAL_DISCHARGE                   = drh."17"
                               , a.POSTMENOPAUSAL                      = drh."18"
                               , a.MENOPAUSE_AGE_CAT                   = drh."19"
                               , a.MENOPAUSE_AGE                       = drh."20"
                               , a.MENOPAUSE_CAUSE                     = drh."21"
                               , a.FEMALE_HORMONES                     = drh."22"
                               , a.TRT_FEMALE_HORMONES                 = drh."23"
                               , a.FEMALE_HORMONES_AGE                 = drh."24"
                               , a.FEMALE_HORMONES_AMOUNT              = drh."25"
                               , a.FEMALE_HORMONES_DURATION            = drh."26"
                               , a.PREGNANCY                           = drh."27"
                               , a.PREGNANCY_FIRST_AGE                 = drh."28"
                               , a.DELIVERY                            = drh."29"
                               , a.DELIVERY_N                          = drh."30"
                               , a.DELIVERY_BOY                        = drh."31"
                               , a.DELIVERY_GIRL                       = drh."32"
                               , a.NATURAL_CHILDBIRTH                  = drh."33"
                               , a.CAESAREAN_SECTION                   = drh."34"
                               , a.DELIVERY_FIRST_AGE                  = drh."35"
                               , a.DELIVERY_LAST_AGE                   = drh."36"
                               , a.PREMATURE_BIRTH                     = drh."37"
                               , a.PREMATURE_BIRTH_N                   = drh."38"
                               , a.MISCARRIAGE                         = drh."39"
                               , a.MISCARRIAGE_NATURAL_N               = drh."40"
                               , a.MISCARRIAGE_ARTIFICIAL_N            = drh."41"
                               , a.PAP                                 = drh."42"
                               , a.PAP_FIRST_AGE                       = drh."43"
                               , a.PAP_LAST_AGE                        = drh."44"
                               , a.PAP_FREQ                            = drh."45"
                               , a.STRESS_Q1                           = drh."46"
                               , a.STRESS_Q2                           = drh."47"
                               , a.STRESS_Q3                           = drh."48"
                               , a.STRESS_Q4                           = drh."49"
                               , a.STRESS_Q5                           = drh."50"
                               , a.STRESS_Q6                           = drh."51"
                               , a.STRESS_Q7                           = drh."52"
                               , a.STRESS_Q8                           = drh."53"
                               , a.STRESS_Q9                           = drh."54"
                               , a.STRESS_Q10                          = drh."55"
                               , a.STRESS_Q11                          = drh."56"
                               , a.STRESS_Q12                          = drh."57"
                               , a.STRESS_Q13                          = drh."58"
                               , a.STRESS_Q14                          = drh."59"
                               , a.STRESS_Q15                          = drh."60"
                               , a.STRESS_Q16                          = drh."61"
                               , a.STRESS_Q17                          = drh."62"
                               , a.STRESS_Q18                          = drh."63"
                               , a.STRESS_Q19                          = drh."64"
                               , a.STRESS_Q20                          = drh."65"
                               , a.STRESS_Q21                          = drh."66"
                               , a.STRESS_SCORE                        = drh."67"
                               , a.last_updt_dt                     = drh.last_updt_dt
                           where a.ptno = drh.ptno
                             and a.ordr_prrn_ymd = drh.ordr_prrn_ymd
                             and a.rprs_apnt_no = drh.rprs_apnt_no
                                 ;
                  
                         commit;
                       
                       upcnt := upcnt + 1;
                  
                       exception
                       when others then
                          rollback;
                          errcnt := errcnt + 1;
            
            end;
            end loop;
       
:var_msg2  := 'update '  || to_char(upcnt)    || ' 건';
:var_msg3  := 'error '   || to_char(errcnt)   || ' 건';
   
end ;
/
print var_msg2
print var_msg3
spool off;
     
-- 문진 정보 update, 계통별 설문
-- 변수 길이가 길다는 에러메세지 때문에 변수를 숫자정보로 치환
-- 메시지 출력기능 추가. 메시지 확인은 F5를 눌러야 가능함
variable var_msg2 char(40);
variable var_msg3 char(40);
  
declare
    upcnt     number(10) := 0;
    errcnt    number(10) := 0;
        
begin
for drh in (
            -- 데이터 select
            select h.RPRS_APNT_NO                   as RPRS_APNT_NO
                 , h.PTNO                           as ptno
                 , h.ORDR_PRRN_YMD                  as ordr_prrn_ymd
                 , h.SY1_1                               as "1" 
                 , h.SY1_2                               as "2" 
                 , h.SY1_3                               as "3" 
                 , h.SY1_4                               as "4" 
                 , h.SY1_5                               as "5" 
                 , h.SY1_6                               as "6" 
                 , h.SY1_7                               as "7" 
                 , h.SY1_8                               as "8" 
                 , h.SY1_9                               as "9" 
                 , h.SY1_10                              as "10"
                 , h.SY1_11                              as "11"
                 , h.SY1_12                              as "12"
                 , h.SY1_13                              as "13"
                 , h.SY1_14                              as "14"
                 , h.SY1_15                              as "15"
                 , h.SY1_16                              as "16"
                 , h.SY1_17                              as "17"
                 , h.SY1_18                              as "18"
                 , h.SY1_19                              as "19"
                 , h.SY1_20                              as "20"
                 , h.SY1_21                              as "21"
                 , h.SY2_1                               as "22"
                 , h.SY2_2                               as "23"
                 , h.SY2_3                               as "24"
                 , h.SY2_4                               as "25"
                 , h.SY2_5                               as "26"
                 , h.SY2_6                               as "27"
                 , h.SY2_7                               as "28"
                 , h.SY3_1                               as "29"
                 , h.SY3_2                               as "30"
                 , h.SY3_3                               as "31"
                 , h.SY3_4                               as "32"
                 , h.SY3_5                               as "33"
                 , h.SY3_6                               as "34"
                 , h.SY3_7                               as "35"
                 , h.SY3_8                               as "36"
                 , h.SY3_9                               as "37"
                 , h.SY3_10                              as "38"
                 , h.SY4_1                               as "39"
                 , h.SY4_2                               as "40"
                 , h.SY4_3                               as "41"
                 , h.SY4_4                               as "42"
                 , h.SY4_5                               as "43"
                 , h.SY4_6                               as "44"
                 , h.SY5_1                               as "45"
                 , h.SY5_2                               as "46"
                 , h.SY5_3                               as "47"
                 , h.SY5_4                               as "48"
                 , h.SY5_5                               as "49"
                 , h.SY5_6                               as "50"
                 , h.SY5_7                               as "51"
                 , h.SY6_1                               as "52"
                 , h.SY6_2                               as "53"
                 , h.SY6_3                               as "54"
                 , h.SY6_4                               as "55"
                 , h.SY6_5                               as "56"
                 , h.SY6_6                               as "57"
                 , h.SY6_7                               as "58"
                 , h.SY6_8                               as "59"
                 , h.SY6_9                               as "60"
                 , h.SY7_1                               as "61"
                 , h.SY7_2                               as "62"
                 , h.SY7_3                               as "63"
                 , h.SY7_4                               as "64"
                 , h.SY7_5                               as "65"
                 , h.SY7_6                               as "66"
                 , h.SY7_7                               as "67"
                 , h.SY8_1                               as "68"
                 , h.SY8_2                               as "69"
                 , h.SY8_3                               as "70"
                 , h.SY8_4                               as "71"
                 , h.SY8_5                               as "72"
                 , h.SY8_6                               as "73"
                 , h.SY8_7                               as "74"
                 , h.SY8_8                               as "75"
                 , h.SY8_9                               as "76"
                 , h.SY8_10                              as "77"
                 , h.SY9_1                               as "78"
                 , h.SY9_2                               as "79"
                 , h.SY9_3                               as "80"
                 , h.SY9_4                               as "81"
                 , h.SY9_5                               as "82"
                 , h.SY9_6                               as "83"
                 , h.SY9_7                               as "84"
                 , h.SY9_8                               as "85"
                 , h.SY9_9                               as "86"
                 , h.SY9_10                              as "87"
                 , h.SY9_11                              as "88"
                 , h.SY9_12                              as "89"
                 , h.SY9_13                              as "90"
                 , h.SY9_14                              as "91"
                 , h.SY9_15                              as "92"
                 , sysdate                          as last_updt_dt
              from (-- 문진 응답내역 중 계통별설문
                    select /*+ ordered use_nl(A F) index(a 3E3C0E433E3C0E3E28_i13) index(f 3E3C23302E333E0E28_pk) */
                           f.rprs_apnt_no
                         , F.PTNO
                         , f.ordr_prrn_ymd
                         , f.inpc_cd
                         , b.gend_cd
                    /* 계통별 설문 - 소화기 */
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM179Y' ,'1'--,''))             AMQ01501     □ 음식 삼키기가 힘들다.(음식이 잘 안넘어간다)                         
                                                                      ,'RR129Y' ,'1'--,''))             RRQ1101      □ 음식 삼키기가 힘들다.(음식이 잘 안넘어간다)                    
                                                                      ,decode(f.inpc_cd,'MA1','9999',''
                                                                             )
                                                                      )) sy1_1
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM180Y' ,'1'--,''))             AMQ01502     □ 음식 삼키기가 힘들고 삼킬때 통증을 느낀다.
                                                                      ,'RR130Y' ,'1'--,''))             RRQ1102      □ 음식 삼키기가 힘들고 삼킬때 통증을 느낀다.
                                                                      ,'MA1574Y','1'--,''))             MA1Q1001     ①음식을삼키기가힘들고아프다.
                                                                      ,'')) sy1_2
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM180Y' ,'1'--,''))             AMQ01502     □ 음식 삼키기가 힘들고 삼킬때 통증을 느낀다.
                                                                      ,'RR130Y' ,'1'--,''))             RRQ1102      □ 음식 삼키기가 힘들고 삼킬때 통증을 느낀다.
                                                                      ,'MA1574Y','1'--,''))             MA1Q1001     ①음식을삼키기가힘들고아프다.
                                                                      ,'AM179Y' ,'1'--,''))             AMQ01501     □ 음식 삼키기가 힘들다.(음식이 잘 안넘어간다)                         
                                                                      ,'RR129Y' ,'1'--,''))             RRQ1101      □ 음식 삼키기가 힘들다.(음식이 잘 안넘어간다)                    
                                                                      ,''
                                                                      )) sy1_3
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM181Y' ,'1'--,''))             AMQ01503     □ 구역질이나 구토가 자주 난다.                                        
                                                                      ,'RR131Y' ,'1'--,''))             RRQ1103      □ 구역질이나 구토가 자주 난다. 
                                                                      ,'MA1576Y','1'--,''))             MA1Q1003     ③구역질이나구토가난다. 
                                                                      ,'')) sy1_4
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM182Y' ,'1'--,''))             AMQ01504     □ 토해낸 음식물이 커피와 같은 색깔이다.                               
                                                                      ,'RR132Y' ,'1'--,''))             RRQ1104      □ 토해낸 음식물이 커피와 같은 색깔이다.                          
                                                                      ,decode(f.inpc_cd,'MA1','9999',''
                                                                             )
                                                                      )) sy1_5
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM183Y' ,'1'--,''))             AMQ01505     □ 토해낸 음식물이 녹색이다.                                           
                                                                      ,'RR133Y' ,'1'--,''))             RRQ1105      □ 토해낸 음식물이 녹색이다.                                      
                                                                      ,decode(f.inpc_cd,'MA1','9999',''
                                                                             )
                                                                      )) sy1_6
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM184Y' ,'1'--,''))             AMQ01506     □ 소화가 잘 안되고, 조금만 먹어도 포만감이 있다.                      
                                                                      ,'RR134Y' ,'1'--,''))             RRQ1106      □ 소화가 잘 안되고, 조금만 먹어도 포만감이 있다.                 
                                                                      ,'MA1577Y','1'--,''))             MA1Q1004     ④소화가잘안된다.
                                                                      ,'')) sy1_7
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM185Y' ,'1'--,''))             AMQ01507     □ 위에 음식물이 남아 있는 듯한 불쾌감이 있다.                         
                                                                      ,'RR135Y' ,'1'--,''))             RRQ1107      □ 위에 음식물이 남아 있는 듯한 불쾌감이 있다.                    
                                                                      ,decode(f.inpc_cd,'MA1','9999',''
                                                                             )
                                                                      )) sy1_8
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM186Y' ,'1'--,''))             AMQ01508     □ 공복시 속이 쓰리다.
                                                                      ,'RR136Y' ,'1'--,''))             RRQ1108      □ 공복시 속이 쓰리다.
                                                                      ,decode(f.inpc_cd,'MA1','9999',''
                                                                             )
                                                                      )) sy1_9
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM187Y' ,'1'--,''))             AMQ01509     □ 식후에 속이 쓰리거나 통증이 있다.                                   
                                                                      ,'RR137Y' ,'1'--,''))             RRQ1109      □ 식후에 속이 쓰리거나 통증이 있다.                              
                                                                      ,decode(f.inpc_cd,'MA1','9999',''
                                                                             )
                                                                      )) sy1_10
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'MA1578Y','1'--,''))             MA1Q1005     ⑤속이쓰리다.
                                                                      ,decode(f.inpc_cd,'AM' ,'9999'
                                                                                       ,'RR' ,'9999',''
                                                                             )
                                                                      )) sy1_11
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'MA1578Y','1'--,''))             MA1Q1005     ⑤속이쓰리다.
                                                                      ,'AM186Y' ,'1'--,''))             AMQ01508     □ 공복시 속이 쓰리다.
                                                                      ,'RR136Y' ,'1'--,''))             RRQ1108      □ 공복시 속이 쓰리다.
                                                                      ,'AM187Y' ,'1'--,''))             AMQ01509     □ 식후에 속이 쓰리거나 통증이 있다.
                                                                      ,'RR137Y' ,'1'--,''))             RRQ1109      □ 식후에 속이 쓰리거나 통증이 있다.
                                                                      ,''
                                                                      )) sy1_12
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM188Y' ,'1'--,''))             AMQ01510     □ 헛배가 부르고 배에 가스가 찬다.                                     
                                                                      ,'RR138Y' ,'1'--,''))             RRQ1110      □ 헛배가 부르고 배에 가스가 찬다.                                
                                                                      ,decode(f.inpc_cd,'MA1','9999',''
                                                                             )
                                                                      )) sy1_13
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM190Y' ,'1'--,''))             AMQ01512     □ 대변색이 짜장면처럼 검게 나온 적이 있다.                            
                                                                      ,'RR139Y' ,'1'--,''))             RRQ1111      □ 대변색이 짜장면처럼 검게 나온 적이 있다.                       
                                                                      ,'MA1579Y','1'--,''))             MA1Q1006     ⑥대변이자장면처럼검게나온다.                                         
                                                                      ,'')) sy1_14
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM191Y' ,'1'--,''))             AMQ01513     □ 대변에 붉은 피가 섞여 나온 적이 있다.                               
                                                                      ,'RR140Y' ,'1'--,''))             RRQ1112      □ 대변에 붉은 피가 섞여 나온 적이 있다.                          
                                                                      ,'MA1580Y','1'--,''))             MA1Q1007     ⑦대변에붉은피가섞여나온다.                                           
                                                                      ,'')) sy1_15
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM192Y' ,'1'--,''))             AMQ01514     □ 최근에 설사가 자주 난다. 
                                                                      ,'RR141Y' ,'1'--,''))             RRQ1113      □ 최근에 설사가 자주 난다.                                       
                                                                      ,'MA1581Y','1'--,''))             MA1Q1008     ⑧설사가자주난다. 
                                                                      ,'')) sy1_16
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM193Y' ,'1'--,''))             AMQ01515     □ 최근에 변비로 고생한다.                                             
                                                                      ,'RR142Y' ,'1'--,''))             RRQ1114      □ 최근에 변비로 고생한다.                                        
                                                                      ,'MA1582Y','1'--,''))             MA1Q1009     ⑨변비가있다.                                                         
                                                                      ,'')) sy1_17
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM194Y' ,'1'--,''))             AMQ01516     □ 최근에 대변이 연필처럼 가늘게 나온다.                               
                                                                      ,'RR143Y' ,'1'--,''))             RRQ1115      □ 최근에 대변이 연필처럼 가늘게 나온다.                          
                                                                      ,'MA1583Y','1'--,''))             MA1Q1010     ⑩변이연필처럼가늘게나온다.                                           
                                                                      ,'')) sy1_18
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM195Y' ,'1'--,''))             AMQ01517     □ 배에 덩어리가 만져진다.                                             
                                                                      ,'RR144Y' ,'1'--,''))             RRQ1116      □ 배에 덩어리가 만져진다.                                        
                                                                      ,'MA1584Y','1'--,''))             MA1Q1011     ⑪배에덩어리가만져진다.                                               
                                                                      ,'')) sy1_19
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'MA1585Y','1'--,''))             MA1Q1012     ⑫배가 자주 아프다                                                    
                                                                      ,decode(f.inpc_cd,'AM' ,'9999'
                                                                                       ,'RR' ,'9999',''
                                                                             )
                                                                      )) sy1_20
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'MA1575Y','1'--,''))             MA1Q1002     ②신물이넘어온다.
                                                                      ,decode(f.inpc_cd,'AM' ,'9999'
                                                                                       ,'RR' ,'9999',''
                                                                             )
                                                                      )) sy1_21
                    /* 계통별 설문 - 호흡기 */
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM203Y' ,'1'--,''))             AMQ01701    □ 기침이 오래 계속 된다.                                              
                                                                      ,'RR152Y' ,'1'--,''))             RRQ1301     □ 기침이 오래 계속 된다.                                         
                                                                      ,'MA1587Y','1'--,''))             MA1Q1101     ①최근기침이잦다.                                                     
                                                                      ,'')) sy2_1
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM204Y' ,'1'--,''))             AMQ01702    □ 황색 혹은 녹색 가래가 나온다                                        
                                                                      ,'RR153Y' ,'1'--,''))             RRQ1302     □ 황색 혹은 녹색 가래가 나온다                                   
                                                                      ,'MA1588Y','1'--,''))             MA1Q1102     ②황색혹은녹색가래가나온다.                                           
                                                                      ,'')) sy2_2
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM205Y' ,'1'--,''))             AMQ01703    □ 가래에 피가 섞여 나오거나 각혈한 적이 있다.                         
                                                                      ,'RR154Y' ,'1'--,''))             RRQ1303     □ 가래에 피가 섞여 나오거나 각혈한 적이 있다.                    
                                                                      ,'MA1589Y','1'--,''))             MA1Q1103     ③객혈한적이있다.                                                     
                                                                      ,'')) sy2_3
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM206Y' ,'1'--,''))             AMQ01704    □ 잠잘때 식은 땀이 난다.                                              
                                                                      ,'RR155Y' ,'1'--,''))             RRQ1304     □ 잠잘때 식은 땀이 난다.                                         
                                                                      ,decode(f.inpc_cd,'MA1','9999','')
                                                                      )) sy2_4
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM207Y' ,'1'--,''))             AMQ01705    □ 숨쉴때 가슴에서 가랑가랑하는 소리가 난다.                           
                                                                      ,'RR156Y' ,'1'--,''))             RRQ1305     □ 숨쉴때 가슴에서 가랑가랑하는 소리가 난다.                      
                                                                      ,decode(f.inpc_cd,'MA1','9999','')
                                                                      )) sy2_5
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'MA1590Y','1'--,''))             MA1Q1104     ④숨쉴때가슴에서쌕쌕소리가난다.                                       
                                                                      ,decode(f.inpc_cd,'AM' ,'9999'
                                                                                       ,'RR' ,'9999',''
                                                                             )
                                                                      )) sy2_6
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM208Y' ,'1'--,''))             AMQ01706    □ 조금만 활동하여도 숨이 차다.                                        
                                                                      ,'RR157Y' ,'1'--,''))             RRQ1306     □ 조금만 활동하여도 숨이 차다.                                   
                                                                      ,'MA1591Y','1'--,''))             MA1Q1105     ⑤조금만활동하여도숨이차다.                                           
                                                                      ,'')) sy2_7
                    /* 계통별 설문 - 신장, 요로, 비뇨기 */
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM210Y' ,'1'--,''))             AMQ01801    □ 최근 소변량이 많아졌다.                                             
                                                                      ,'RR159Y' ,'1'--,''))             RRQ1401     □ 최근 소변량이 많아졌다.                                        
                                                                      ,'MA1593Y','1'--,''))             MA1Q1201     ①최근소변량이많아졌다.                                               
                                                                      ,'')) sy3_1
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM218Y' ,'1'--,''))             AMQ01901    □ 소변 보기가 힘들고 본 후에도 시원하지가 않다.                       
                                                                      ,'RR167Y' ,'1'--,''))             RRQ1501     □ 소변 보기가 힘들고 본 후에도 시원하지가 않다.                  
                                                                      ,'MA1594Y','1'--,''))             MA1Q1202     ②소변보기가힘들고잔뇨감이있다.                                       
                                                                      ,'')) sy3_2
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM219Y' ,'1'--,''))             AMQ01902    □ 소변을 참지 못하겠다.                                               
                                                                      ,'RR168Y' ,'1'--,''))             RRQ1502     □ 소변을 참지 못하겠다.                                          
                                                                      ,'MA1595Y','1'--,''))             MA1Q1203     ③소변을참지못하겠다.                                                 
                                                                      ,'')) sy3_3
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'MA1596Y','1'--,''))             MA1Q1204     ④소변을볼때아프다.                                                   
                                                                      ,decode(f.inpc_cd,'AM' ,'9999'
                                                                                       ,'RR' ,'9999',''
                                                                             )
                                                                      )) sy3_4
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'MA1597Y','1'--,''))             MA1Q1205     ⑤소변줄기가가늘어졌다.                                               
                                                                      ,decode(f.inpc_cd,'AM' ,'9999'
                                                                                       ,'RR' ,'9999',''
                                                                             )
                                                                      )) sy3_5
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM220Y' ,'1'--,''))             AMQ01903    □ 소변이 빨갛거나 콜라색으로 나온 적이 있다.                          
                                                                      ,'RR169Y' ,'1'--,''))             RRQ1503     □ 소변이 빨갛거나 콜라색으로 나온 적이 있다.                     
                                                                      ,'MA1598Y','1'--,''))             MA1Q1206     ⑥소변이빨갛거나콜라색으로나온다.                                     
                                                                      ,'')) sy3_6
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM221Y' ,'1'--,''))             AMQ01904    □ 옆구리나 아랫배에 심한 통증이 있다.                                 
                                                                      ,'RR170Y' ,'1'--,''))             RRQ1504     □ 옆구리나 아랫배에 심한 통증이 있다.                            
                                                                      ,'MA1599Y','1'--,''))             MA1Q1207     ⑦옆구리나아랫배에심한통증이있다.                                     
                                                                      ,'')) sy3_7
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM222Y' ,'1'--,''))             AMQ01905    □ 잠을 자는 동안 소변을 보기 위해 자주 깬다.                          
                                                                      ,'RR171Y' ,'1'--,''))             RRQ1505     □ 잠을 자는 동안 소변을 보기 위해 자주 깬다.                     
                                                                      ,'MA1600Y','1'--,''))             MA1Q1208     ⑧잠을자는동안소변을보려고자주깬다.                                   
                                                                      ,'')) sy3_8
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM223Y' ,'1'--,''))             AMQ01906    □ 자신도 모르게 소변이 흘러 나오는 일이 있다.                         
                                                                      ,'RR172Y' ,'1'--,''))             RRQ1506     □ 자신도 모르게 소변이 흘러 나오는 일이 있다.                    
                                                                      ,'MA1601Y','1'--,''))             MA1Q1209     ⑨자신도모르게소변이흘러나온다.                                       
                                                                      ,'')) sy3_9
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM216Y' ,'1'--,''))             AMQ01807    □ 성생활에 문제가 있다.                                               
                                                                      ,'RR165Y' ,'1'--,''))             RRQ1407     □ 성생활에 문제가 있다.                                          
                                                                      ,'MA1602Y','1'--,''))             MA1Q1210     ⑩성생활에문제가있다.                                                 
                                                                      ,'')) sy3_10
                    /* 계통별 설문 - 심장,혈관 */
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM197Y' ,'1'--,''))             AMQ01601    □ 가슴이 조여들며 통증이 팔이나 등으로 뻗치는 일이 있다.              
                                                                      ,'RR146Y' ,'1'--,''))             RRQ1201     □ 가슴이 조여들며 통증이 팔이나 등으로 뻗치는 일이 있다.         
                                                                      ,'MA1604Y','1'--,''))             MA1Q1301     ①가슴이조여들며통증이팔이나등으로뻗치는 일이있다..                   
                                                                      ,'')) sy4_1
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM198Y' ,'1'--,''))             AMQ01602    □ 운동할때 전과 달리 가슴이 답답해지거나 숨이 몹시 차다.              
                                                                      ,'RR147Y' ,'1'--,''))             RRQ1202     □ 운동할때 전과 달리 가슴이 답답해지거나 숨이 몹시 차다.         
                                                                      ,'MA1605Y','1'--,''))             MA1Q1302     ②운동할때전과달리가슴이답답해지거나숨이 몹시차다..                   
                                                                      ,'')) sy4_2
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM199Y' ,'1'--,''))             AMQ01603    □ 갑자기 가슴이 두근거리거나 맥박이 불규칙해질 때가 있다.             
                                                                      ,'RR148Y' ,'1'--,''))             RRQ1203     □ 갑자기 가슴이 두근거리거나 맥박이 불규칙해질 때가 있다.        
                                                                      ,'MA1606Y','1'--,''))             MA1Q1303     ③갑자기가슴이두근거리거나맥박이불규칙해질 때가있다..                 
                                                                      ,'')) sy4_3
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM200Y' ,'1'--,''))             AMQ01604    □ 얼굴이나 손발이 자주 붓는다.                                        
                                                                      ,'RR149Y' ,'1'--,''))             RRQ1204     □ 얼굴이나 손발이 자주 붓는다.                                   
                                                                      ,'MA1607Y','1'--,''))             MA1Q1304     ④얼굴이나손발이자주붓는다.                                           
                                                                      ,'')) sy4_4
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM201Y' ,'1'--,''))             AMQ01605    □ 잘때나 누울때 가슴이 답답하고 숨이 차며 앉으면 오히려 편해진다.     
                                                                      ,'RR150Y' ,'1'--,''))             RRQ1205     □ 잘때나 누울때 가슴이 답답하고 숨이 차며 앉으면 오히려 편해진다.
                                                                      ,'MA1608Y','1'--,''))             MA1Q1305     ⑤잘때나누울때가슴이답답하고숨이차며 앉으면오히려편해진다..           
                                                                      ,'')) sy4_5
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'MA1609Y','1'--,''))             MA1Q1306     ⑥걸으면종아리가아파서쉬어야한다.                                     
                                                                      ,decode(f.inpc_cd,'AM' ,'9999'
                                                                                       ,'RR' ,'9999',''
                                                                             )
                                                                      )) sy4_6
                    /* 계통별 설문 - 대사, 내분비 */
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM211Y' ,'1'--,''))             AMQ01802    □ 최근 식욕이 늘었다.                                                 
                                                                      ,'RR160Y' ,'1'--,''))             RRQ1402     □ 최근 식욕이 늘었다.                                            
                                                                      ,decode(f.inpc_cd,'MA1' ,'9999',''
                                                                             )
                                                                      )) sy5_1
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM212Y' ,'1'--,''))             AMQ01803    □ 최근 식욕이 없어졌다.                                               
                                                                      ,'RR161Y' ,'1'--,''))             RRQ1403     □ 최근 식욕이 없어졌다.                                          
                                                                      ,'MA1611Y','1'--,''))             MA1Q1401     ①최근 식욕이 없다.                                                   
                                                                      ,'')) sy5_2
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM213Y' ,'1'--,''))             AMQ01804    □ 손톱.발톱이나 머리카락이 잘 부러진다.                               
                                                                      ,'RR162Y' ,'1'--,''))             RRQ1404     □ 손톱.발톱이나 머리카락이 잘 부러진다.                          
                                                                      ,'MA1612Y','1'--,''))             MA1Q1402     ②손발톱이나머리카락이잘부러진다.                                     
                                                                      ,'')) sy5_3
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM214Y' ,'1'--,''))             AMQ01805    □ 자주 갈증이 난다.                                                   
                                                                      ,'RR163Y' ,'1'--,''))             RRQ1405     □ 자주 갈증이 난다.                                              
                                                                      ,'MA1613Y','1'--,''))             MA1Q1403     ③자주갈증이난다.                                                     
                                                                      ,'')) sy5_4
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM215Y' ,'1'--,''))             AMQ01806    □ 자주 얼굴이 화끈 달아오른다.                                        
                                                                      ,'RR164Y' ,'1'--,''))             RRQ1406     □ 자주 얼굴이 화끈 달아오른다.                                   
                                                                      ,'MA1614Y','1'--,''))             MA1Q1404     ④자주얼굴이화끈달아오른다.                                           
                                                                      ,'')) sy5_5
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'MA1615Y','1'--,''))             MA1Q1405     ⑤추위를많이탄다.                                                     
                                                                      ,decode(f.inpc_cd,'AM' ,'9999'
                                                                                       ,'RR' ,'9999',''
                                                                             )
                                                                      )) sy5_6
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'MA1616Y','1'--,''))             MA1Q1406     ⑥더위를많이탄다.                                                     
                                                                      ,decode(f.inpc_cd,'AM' ,'9999'
                                                                                       ,'RR' ,'9999',''
                                                                             )
                                                                      )) sy5_7
                    /* 계통별 설문 - 신경,정신 */
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM225Y' ,'1'--,''))             AMQ02001    □ 현기증이 자주 난다.                                                 
                                                                      ,'RR174Y' ,'1'--,''))             RRQ1601     □ 현기증이 자주 난다.                                            
                                                                      ,'MA1618Y','1'--,''))             MA1Q1501     ①현기증이자주난다.                                                   
                                                                      ,'')) sy6_1
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM226Y' ,'1'--,''))             AMQ02002    □ 졸도한 경험이 있다.                                                 
                                                                      ,'RR175Y' ,'1'--,''))             RRQ1602     □ 졸도한 경험이 있다.                                            
                                                                      ,'MA1620Y','1'--,''))             MA1Q1503     ③졸도한경험이있다.                                                   
                                                                      ,'')) sy6_2
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM227Y' ,'1'--,''))             AMQ02003    □ 신체에 마비가 온적이 있다.                                          
                                                                      ,'RR176Y' ,'1'--,''))             RRQ1603     □ 신체에 마비가 온적이 있다.                                     
                                                                      ,'MA1621Y','1'--,''))             MA1Q1504     ④신체에마비가온적이있다.                                             
                                                                      ,'')) sy6_3
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM228Y' ,'1'--,''))             AMQ02004    □ 손발이 계속 저린 일이 있다.                                         
                                                                      ,'RR177Y' ,'1'--,''))             RRQ1604     □ 손발이 계속 저린 일이 있다.                                    
                                                                      ,'MA1622Y','1'--,''))             MA1Q1505     ⑤손발이계속저리다.                                                   
                                                                      ,'')) sy6_4
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM229Y' ,'1'--,''))             AMQ02005    □ 행동이 느려지거나, 손이 떨리는 증상이 있다.                         
                                                                      ,'RR178Y' ,'1'--,''))             RRQ1605     □ 행동이 느려지거나, 손이 떨리는 증상이 있다.                    
                                                                      ,'MA1623Y','1'--,''))             MA1Q1506     ⑥행동이느려지거나손이떨린다.                                         
                                                                      ,'')) sy6_5
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM230Y' ,'1'--,''))             AMQ02006    □ 기억력이 떨어진다.                                                  
                                                                      ,'RR179Y' ,'1'--,''))             RRQ1606     □ 기억력이 떨어진다.                                             
                                                                      ,'MA1624Y','1'--,''))             MA1Q1507     ⑦집중력, 기억력이떨어진다.                                           
                                                                      ,'')) sy6_6
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'MA1625Y','1'--,''))             MA1Q1508     ⑧불안, 초조, 울적하다.                                               
                                                                      ,decode(f.inpc_cd,'AM' ,'9999'
                                                                                       ,'RR' ,'9999',''
                                                                             )
                                                                      )) sy6_7
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'MA1626Y','1'--,''))             MA1Q1509     ⑨가끔주위가빙빙돈다.                                                 
                                                                      ,decode(f.inpc_cd,'AM' ,'9999'
                                                                                       ,'RR' ,'9999',''
                                                                             )
                                                                      )) sy6_8
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM175Y' ,'1'--,''))             AMQ01405    □ 머리가 자주 아프다.                                                 
                                                                      ,'RR125Y' ,'1'--,''))             RRQ1005     □ 머리가 자주 아프다.                                            
                                                                      ,'MA1619Y','1'--,''))             MA1Q1502     ②두통이있다.                                                         
                                                                      ,'')) sy6_9
                    /* 계통별 설문 - 근골격 */
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM174Y' ,'1'--,''))             AMQ01404    □ 허리가 아프다.                                                      
                                                                      ,'RR124Y' ,'1'--,''))             RRQ1004     □ 허리가 아프다.                                                 
                                                                      ,'MA1628Y','1'--,''))             MA1Q1601     ①허리가아프다.                                                       
                                                                      ,'')) sy7_1
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'MA1629Y','1'--,''))             MA1Q1602     ②무릎이아프다.                                                       
                                                                      ,decode(f.inpc_cd,'AM' ,'9999'
                                                                                       ,'RR' ,'9999',''
                                                                             )
                                                                      )) sy7_2
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'MA1630Y','1'--,''))             MA1Q1603     ③어깨가아프다.                                                       
                                                                      ,decode(f.inpc_cd,'AM' ,'9999'
                                                                                       ,'RR' ,'9999',''
                                                                             )
                                                                      )) sy7_3
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'MA1631Y','1'--,''))             MA1Q1604     ④뒷목이뻐근하다.                                                     
                                                                      ,decode(f.inpc_cd,'AM' ,'9999'
                                                                                       ,'RR' ,'9999',''
                                                                             )
                                                                      )) sy7_4
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'MA1632Y','1'--,''))             MA1Q1605     ⑤뼈마디가쑤시고아프다.                                               
                                                                      ,decode(f.inpc_cd,'AM' ,'9999'
                                                                                       ,'RR' ,'9999',''
                                                                             )
                                                                      )) sy7_5
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM238Y' ,'1'--,''))             AMQ02107    □ 관절이 아프거나 부은적이 있다.                                      
                                                                      ,'RR187Y' ,'1'--,''))             RRQ1707     □ 관절이 아프거나 부은적이 있다.                                 
                                                                      ,'MA1633Y','1'--,''))             MA1Q1606     ⑥관절이아프거나부은적이있다.                                         
                                                                      ,'')) sy7_6
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'MA1634Y','1'--,''))             MA1Q1607     ⑦관절운동에장애가있다.                                               
                                                                      ,decode(f.inpc_cd,'AM' ,'9999'
                                                                                       ,'RR' ,'9999',''
                                                                             )
                                                                      )) sy7_7
                    /* 계통별 설문 - 치아 */
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM240Y' ,'1'--,''))             AMQ02201    □ 이를 닦을 때 피가 난다.                                             
                                                                      ,'RR189Y' ,'1'--,''))             RRQ1801     □ 이를 닦을 때 피가 난다.                                        
                                                                      ,'MA1637Y','1'--,''))             MA1Q1702     ②양치질시피가난다.                                                   
                                                                      ,'')) sy8_1
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM241Y' ,'1'--,''))             AMQ02203    □ 양치질을 하루에 두번 이상 한다.                                     
                                                                      ,'RR190Y' ,'1'--,''))             RRQ1802     □ 양치질을 하루에 두번 이상 한다.                                
                                                                      ,decode(f.inpc_cd,'MA1','9999','')
                                                                      )) sy8_2
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM242Y' ,'1'--,''))             AMQ02205    □ 구취가 많이 난다.                                                   
                                                                      ,'RR191Y' ,'1'--,''))             RRQ1803     □ 구취가 많이 난다.                                              
                                                                      ,'MA1638Y','1'--,''))             MA1Q1703     ③구취가난다.                                                         
                                                                      ,'')) sy8_3
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM243Y' ,'1'--,''))             AMQ02207    □ 입을 벌리거나 턱을 움직일때 소리가 난다.                            
                                                                      ,'RR192Y' ,'1'--,''))             RRQ1804     □ 입을 벌리거나 턱을 움직일때 소리가 난다.                       
                                                                      ,decode(f.inpc_cd,'MA1','9999','')
                                                                      )) sy8_4
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'MA1636Y','1'--,''))             MA1Q1701     ①치아나구강내에통증이있다.                                           
                                                                      ,decode(f.inpc_cd,'AM' ,'9999'
                                                                                       ,'RR' ,'9999',''
                                                                             )
                                                                      )) sy8_5
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM244Y' ,'1'--,''))             AMQ02209    □ 현재 치아 혹은 턱주위에 통증이 있다.                                
                                                                      ,'RR193Y' ,'1'--,''))             RRQ1805     □ 현재 치아 혹은 턱주위에 통증이 있다.                           
                                                                      ,decode(f.inpc_cd,'MA1','9999','')
                                                                      )) sy8_6
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'MA1641Y','1'--,''))             MA1Q1706     ⑥턱관절통증이있다.                                                   
                                                                      ,decode(f.inpc_cd,'AM' ,'9999'
                                                                                       ,'RR' ,'9999',''
                                                                             )
                                                                      )) sy8_7
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM244Y' ,'1'--,''))             AMQ02209    □ 현재 치아 혹은 턱주위에 통증이 있다.
                                                                      ,'RR193Y' ,'1'--,''))             RRQ1805     □ 현재 치아 혹은 턱주위에 통증이 있다.
                                                                      ,'AM243Y' ,'1'--,''))             AMQ02207    □ 입을 벌리거나 턱을 움직일때 소리가 난다.
                                                                      ,'RR192Y' ,'1'--,''))             RRQ1804     □ 입을 벌리거나 턱을 움직일때 소리가 난다.
                                                                      ,'MA1636Y','1'--,''))             MA1Q1701     ①치아나구강내에통증이있다.
                                                                      ,'MA1641Y','1'--,''))             MA1Q1706     ⑥턱관절통증이있다.
                                                                      ,''
                                                                      )) sy8_8
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'MA1639Y','1'--,''))             MA1Q1704     ④스케일링을 1년에 1번이상 받는다.                                    
                                                                      ,decode(f.inpc_cd,'AM' ,'9999'
                                                                                       ,'RR' ,'9999',''
                                                                             )
                                                                      )) sy8_9
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'MA1640Y','1'--,''))             MA1Q1705     ⑤임플란트치료를받았다.                                               
                                                                      ,decode(f.inpc_cd,'AM' ,'9999'
                                                                                       ,'RR' ,'9999',''
                                                                             )
                                                                      )) sy8_10
                    /* 계통별 설문 - 기타 */
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM170Y' ,'1'--,''))||                       □ 특별한 이유없이 체중이 준다.(최근    개월 사이에   ㎏에서    kg으로)
                                                                      ,'RR121Y' ,'1'--,''))             RRQ1001     □ 특별한 이유없이 체중이 준다.                                   
                                                                      ,'MA1643Y','1'--,''))             MA1Q1801     ①특별한 이유없이 체중이 준다(최근 6개월간 평상시 체중의 10%이상감소.)
                                                                      ,'')) sy9_1
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM172Y' ,'1'--,''))             AMQ01402    □ 같은 활동을 해도 1년전에 비해 훨씬 쉽게 피로해진다.                 
                                                                      ,'RR122Y' ,'1'--,''))             RRQ1002     □ 같은 활동을 해도 1년전에 비해 훨씬 쉽게 피로해진다.            
                                                                      ,'MA1644Y','1'--,''))             MA1Q1802     ②쉽게피로해진다.                                                     
                                                                      ,'')) sy9_2
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'MA1645Y','1'--,''))             MA1Q1803     ③기운이없다.                                                         
                                                                      ,decode(f.inpc_cd,'AM' ,'9999'
                                                                                       ,'RR' ,'9999',''
                                                                             )
                                                                      )) sy9_3
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'MA1646Y','1'--,''))             MA1Q1804     ④열이나오한이난다.                                                   
                                                                      ,decode(f.inpc_cd,'AM' ,'9999'
                                                                                       ,'RR' ,'9999',''
                                                                             )
                                                                      )) sy9_4
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'MA1647Y','1'--,''))             MA1Q1805     ⑤수면장애가있다.                                                     
                                                                      ,decode(f.inpc_cd,'AM' ,'9999'
                                                                                       ,'RR' ,'9999',''
                                                                             )
                                                                      )) sy9_5
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM176Y' ,'1'--,''))             AMQ01406    □ 멍이 잘 들거나 코피가 자주 난다.                                    
                                                                      ,'RR126Y' ,'1'--,''))             RRQ1006     □ 멍이 잘 들거나 코피가 자주 난다.                               
                                                                      ,'MA1648Y','1'--,''))             MA1Q1806     ⑥멍이잘들고코피가자주난다.                                           
                                                                      ,'')) sy9_6
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM232Y' ,'1'--,''))             AMQ02101    □ 피부가 몹시 가렵다.                                                 
                                                                      ,'RR181Y' ,'1'--,''))             RRQ1701     □ 피부가 몹시 가렵다.                                            
                                                                      ,'MA1649Y','1'--,''))             MA1Q1807     ⑦피부가몹시가렵다.                                                   
                                                                      ,'')) sy9_7
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'MA1650Y','1'--,''))             MA1Q1808     ⑧피부에발진이있다.                                                   
                                                                      ,decode(f.inpc_cd,'AM' ,'9999'
                                                                                       ,'RR' ,'9999',''
                                                                             )
                                                                      )) sy9_8
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM233Y' ,'1'--,''))             AMQ02102    □ 두드러기가 잘 생긴다.                                               
                                                                      ,'RR182Y' ,'1'--,''))             RRQ1702     □ 두드러기가 잘 생긴다.                                          
                                                                      ,'MA1651Y','1'--,''))             MA1Q1809     ⑨두드러기가잘생긴다.                                                 
                                                                      ,'')) sy9_9
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM234Y' ,'1'--,''))             AMQ02103    □ 최근 들어 시력이 많이 떨어졌다.                                     
                                                                      ,'RR183Y' ,'1'--,''))             RRQ1703     □ 최근 들어 시력이 많이 떨어졌다.                                
                                                                      ,'MA1652Y','1'--,''))             MA1Q1810     ⑩최근에 시력이 떨어졌다.                                             
                                                                      ,'')) sy9_10
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM235Y' ,'1'--,''))             AMQ02104    □ 물체가 갑자기 두개로 보일때가 있다.                                 
                                                                      ,'RR184Y' ,'1'--,''))             RRQ1704     □ 물체가 갑자기 두개로 보일때가 있다.                            
                                                                      ,'MA1653Y','1'--,''))             MA1Q1811     ⑪물체가갑자기두개로보인다.                                           
                                                                      ,'')) sy9_11
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM236Y' ,'1'--,''))             AMQ02105    □ 귀에서 소리가 자주 난다.                                            
                                                                      ,'RR185Y' ,'1'--,''))             RRQ1705     □ 귀에서 소리가 자주 난다.                                       
                                                                      ,'MA1654Y','1'--,''))             MA1Q1812     ⑫귀에서소리가 난다.                                                  
                                                                      ,'')) sy9_12
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM237Y' ,'1'--,''))             AMQ02106    □ 목소리가 2-3주 이상 쉬었던 적이 있다..                              
                                                                      ,'RR186Y' ,'1'--,''))             RRQ1706     □ 목소리가 2-3주 이상 쉬었던 적이 있다..                         
                                                                      ,'MA1655Y','1'--,''))             MA1Q1813     ⑬2주이상 목소리가 쉬었다.                                            
                                                                      ,'')) sy9_13
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM173Y' ,'1'--,''))             AMQ01403    □ 최근 안색이 안좋다는 소리를 듣는다.                                 
                                                                      ,'RR123Y' ,'1'--,''))             RRQ1003     □ 최근 안색이 안좋다는 소리를 듣는다.                            
                                                                      ,decode(f.inpc_cd,'MA1','9999','')
                                                                      )) sy9_14
                         , MAX(DECODE(f.inpc_cd||f.item_sno||f.ceck_yn
                                                                      ,'AM177Y' ,'1'--,''))             AMQ01407    □ 입안이 자주 헌다.                                                   
                                                                      ,'RR127Y' ,'1'--,''))             RRQ1007     □ 입안이 자주 헌다.                                              
                                                                      ,decode(f.inpc_cd,'MA1','9999','')
                                                                      )) sy9_15
                      from 스키마.3E3C0E433E3C0E3E28@SMISR_스키마 a
                         , 스키마.0E5B5B285B28402857@SMISR_스키마 b
                         , 스키마.3E3C23302E333E0E28@SMISR_스키마 f
                         , 스키마.3E3C23302E333E3C28@SMISR_스키마 g
                     where 
                           a.ordr_prrn_ymd between to_date(&qfrdt,'yyyymmdd') and to_date(&qtodt,'yyyymmdd')
                       and a.ordr_ymd is not null
                       and a.cncl_dt is null
                       and b.ptno = a.ptno
                       and f.ptno = a.ptno
                       and f.ordr_prrn_ymd = a.ordr_prrn_ymd
                       and f.inpc_cd in ('AM','RR','MA1')
                       AND (-- AM, RR의 경우는 응답한 것만 저장되었으므로, 모두 범위에 포함
                              (f.inpc_cd = 'AM'  and f.item_sno between 1   and 500)
                           OR (f.inpc_cd = 'RR'  and f.item_sno between 1   and 300)
                           OR (f.inpc_cd = 'MA1' and f.item_sno between 573 and 656)
                           )
                       and f.rprs_apnt_no = a.rprs_apnt_no
                       and f.qstn_cd1 = g.inqy_cd(+)
                       and a.ptno not in (
                                          &not_in_ptno
                                         )
                     group by f.rprs_apnt_no
                         , F.PTNO
                         , f.ordr_prrn_ymd
                         , f.inpc_cd
                         , b.gend_cd
                   ) h                      
           )
                
            loop
            begin   -- 데이터 update
                          update /*+ append */
                                 스키마.1543294D47144D302E333E0E28 a
                             set 
                                 a.SY1_1                               = drh."1" 
                               , a.SY1_2                               = drh."2" 
                               , a.SY1_3                               = drh."3" 
                               , a.SY1_4                               = drh."4" 
                               , a.SY1_5                               = drh."5" 
                               , a.SY1_6                               = drh."6" 
                               , a.SY1_7                               = drh."7" 
                               , a.SY1_8                               = drh."8" 
                               , a.SY1_9                               = drh."9" 
                               , a.SY1_10                              = drh."10"
                               , a.SY1_11                              = drh."11"
                               , a.SY1_12                              = drh."12"
                               , a.SY1_13                              = drh."13"
                               , a.SY1_14                              = drh."14"
                               , a.SY1_15                              = drh."15"
                               , a.SY1_16                              = drh."16"
                               , a.SY1_17                              = drh."17"
                               , a.SY1_18                              = drh."18"
                               , a.SY1_19                              = drh."19"
                               , a.SY1_20                              = drh."20"
                               , a.SY1_21                              = drh."21"
                               , a.SY2_1                               = drh."22"
                               , a.SY2_2                               = drh."23"
                               , a.SY2_3                               = drh."24"
                               , a.SY2_4                               = drh."25"
                               , a.SY2_5                               = drh."26"
                               , a.SY2_6                               = drh."27"
                               , a.SY2_7                               = drh."28"
                               , a.SY3_1                               = drh."29"
                               , a.SY3_2                               = drh."30"
                               , a.SY3_3                               = drh."31"
                               , a.SY3_4                               = drh."32"
                               , a.SY3_5                               = drh."33"
                               , a.SY3_6                               = drh."34"
                               , a.SY3_7                               = drh."35"
                               , a.SY3_8                               = drh."36"
                               , a.SY3_9                               = drh."37"
                               , a.SY3_10                              = drh."38"
                               , a.SY4_1                               = drh."39"
                               , a.SY4_2                               = drh."40"
                               , a.SY4_3                               = drh."41"
                               , a.SY4_4                               = drh."42"
                               , a.SY4_5                               = drh."43"
                               , a.SY4_6                               = drh."44"
                               , a.SY5_1                               = drh."45"
                               , a.SY5_2                               = drh."46"
                               , a.SY5_3                               = drh."47"
                               , a.SY5_4                               = drh."48"
                               , a.SY5_5                               = drh."49"
                               , a.SY5_6                               = drh."50"
                               , a.SY5_7                               = drh."51"
                               , a.SY6_1                               = drh."52"
                               , a.SY6_2                               = drh."53"
                               , a.SY6_3                               = drh."54"
                               , a.SY6_4                               = drh."55"
                               , a.SY6_5                               = drh."56"
                               , a.SY6_6                               = drh."57"
                               , a.SY6_7                               = drh."58"
                               , a.SY6_8                               = drh."59"
                               , a.SY6_9                               = drh."60"
                               , a.SY7_1                               = drh."61"
                               , a.SY7_2                               = drh."62"
                               , a.SY7_3                               = drh."63"
                               , a.SY7_4                               = drh."64"
                               , a.SY7_5                               = drh."65"
                               , a.SY7_6                               = drh."66"
                               , a.SY7_7                               = drh."67"
                               , a.SY8_1                               = drh."68"
                               , a.SY8_2                               = drh."69"
                               , a.SY8_3                               = drh."70"
                               , a.SY8_4                               = drh."71"
                               , a.SY8_5                               = drh."72"
                               , a.SY8_6                               = drh."73"
                               , a.SY8_7                               = drh."74"
                               , a.SY8_8                               = drh."75"
                               , a.SY8_9                               = drh."76"
                               , a.SY8_10                              = drh."77"
                               , a.SY9_1                               = drh."78"
                               , a.SY9_2                               = drh."79"
                               , a.SY9_3                               = drh."80"
                               , a.SY9_4                               = drh."81"
                               , a.SY9_5                               = drh."82"
                               , a.SY9_6                               = drh."83"
                               , a.SY9_7                               = drh."84"
                               , a.SY9_8                               = drh."85"
                               , a.SY9_9                               = drh."86"
                               , a.SY9_10                              = drh."87"
                               , a.SY9_11                              = drh."88"
                               , a.SY9_12                              = drh."89"
                               , a.SY9_13                              = drh."90"
                               , a.SY9_14                              = drh."91"
                               , a.SY9_15                              = drh."92"
                               , a.last_updt_dt                     = drh.last_updt_dt
                           where a.ptno = drh.ptno
                             and a.ordr_prrn_ymd = drh.ordr_prrn_ymd
                             and a.rprs_apnt_no = drh.rprs_apnt_no
                                 ;
                  
                         commit;
                       
                       upcnt := upcnt + 1;
                  
                       exception
                       when others then
                          rollback;
                          errcnt := errcnt + 1;
            
            end;
            end loop;
       
:var_msg2  := 'update '  || to_char(upcnt)    || ' 건';
:var_msg3  := 'error '   || to_char(errcnt)   || ' 건';
   
end ;
/
print var_msg2
print var_msg3
spool off
exit;

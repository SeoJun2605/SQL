----16P / IN 조건을 이용한 하위질의------------------------------------------------------------------------

--(1) 판매일자별로 한번에 가장 많은수량을판직원의정보를찾아SubQuery를이용하여 다음과같은항목의정보를조회하시오.
--판매일자, 직원번호, 상품코드, 상품명, 수량

SELECT    ESD.SELL_DT       AS "판매일자"
         ,ESD.SELL_EMP_NO   AS "직원번호"
         ,ESD.GODS_CD       AS "상품코드"
         ,EGB.GODS_NM       AS "상품명"
         ,ESD.SELL_QTY      AS "수량"
FROM      EDU01.EDU_SELL_DESC ESD
          LEFT OUTER JOIN EDU01.EDU_GODS_BASE EGB 
          ON ESD.GODS_CD = EGB.GODS_CD
WHERE     (ESD.SELL_DT, ESD.SELL_EMP_NO) IN (
                                          SELECT    SUB2.SELL_DT 
                                                   ,SUB2.SELL_EMP_NO 
                                          FROM      ( 
                                                     SELECT   SUB.* 
                                                             ,RANK() OVER(PARTITION BY SUB.SELL_DT 
                                                                          ORDER BY SUB.TOTAL_QTY DESC) AS RANK 
                                                     FROM     ( 
                                                                SELECT   SELL_DT                   
                                                                        ,SELL_EMP_NO               
                                                                        ,SUM(SELL_QTY) AS TOTAL_QTY
                                                                FROM EDU01.EDU_SELL_DESC 
                                                                GROUP BY 1, 2
                                                              ) SUB
                                                    ) SUB2
                                          WHERE     SUB2.RANK = 1
                                         )
ORDER BY 1
;



----20P / Dummy Select------------------------------------------------------------------------------

--(1) 현재 날짜를 YYYY-MM-DD 형식으로 나타내시오.

--현재날짜
--2020-02-24

SELECT TO_CHAR(NOW(),'YYYY-MM-DD') AS "현재 날짜";


-- (2) 1부터 30까지 출력하시오.

--순
-- 1
-- 2
-- 3
-- :
-- 30

SELECT GENERATE_SERIES(1, 30) AS NUM;



SELECT ROW_NUMBER() OVER () AS NUM
FROM   EDU01.EDU_SELL_DESC ESD 
LIMIT  30
;


----21P / INDEX-------------------------------------------------------------------------------------


--(1) 판매_내역 테이블의 다음의 2개컬럼에 대한인덱스IDX_EDU_SELL_DESC_01을 작성하십시오.

--판매사원번호, 상품코드

CREATE INDEX IDX_EDU_SELL_DESC_01
ON           EDU01.EDU_SELL_DESC(SELL_EMP_NO, GODS_CD)
;


--(2) 생성한 인덱스를 삭제하십시오.

DROP INDEX IDX_EDU_SELL_DESC_01;


----25P/ SQEQUENCE----------------------------------------------------------------------------------

--(1) 다음의 정보를 판매_내역 테이블이 추가등록하시오.

--판매일자         판매사원번호      고객번호         상품코드         판매수량          등록자사번
--2020-01-01    00900005     1011199123      000001          10           00900005


INSERT INTO   EDU01.EDU_SELL_DESC (SELL_DT, SELL_EMP_NO, CUST_NO, GODS_CD, SELL_QTY, FRST_REG_EMP_NO)
VALUES                            ('2020-01-01', '00900005', '1011199123', '000001', '10', '00900005')
;
;


SELECT  * 
FROM    EDU01.EDU_SELL_DESC 
WHERE   FRST_REG_EMP_NO = '00900005'


--(2) 시퀀스를 생성하고, 시작번호를 현재 등록된 판매내역SEQ의 마지막 번호를시작번호로 선언하여처리하십시오.

-- 시퀀스명: SEQ_SELL_1

SELECT  MAX(SELL_SEQ)
FROM    EDU01.EDU_SELL_DESC;

CREATE SEQUENCE  SEQ_SELL_1
START WITH       12845
INCREMENT BY     1
;


DROP SEQUENCE SEQ_SELL_1;


--(3) 현재 시퀀스 값을 조회하십시오.

SELECT NEXTVAL('SEQ_SELL_1');

--(4) 시퀀스를 이용하여, (1)의 판매내역 정보를 등록하십시오

INSERT INTO   EDU01.EDU_SELL_DESC (SELL_DT, SELL_SEQ, SELL_EMP_NO, CUST_NO, GODS_CD, SELL_QTY, FRST_REG_EMP_NO)
VALUES                            ('2020-01-01', NEXTVAL('SEQ_SELL_1'), '00900005', '1011199123', '000001', '10', '00900005')
;



----26P/ FUNCTION(함수)--------------------------------------------------------------------------------

-- (1) 사번을넣으면성명을리턴하는함수F_EMP_NM 을만드시오.


CREATE OR REPLACE FUNCTION F_EMP_NM (
    EMP_NO_IN VARCHAR
)
RETURNS VARCHAR AS $$
DECLARE
    EMP_NM_RESULT VARCHAR;
BEGIN
    SELECT EMP_NM 
    INTO EMP_NM_RESULT
    FROM EDU01.EDU_EMP_BASE
    WHERE EMP_NO = EMP_NO_IN;

    IF EMP_NM_RESULT IS NULL THEN
        RETURN '이름 없음';
    END IF;

    RETURN EMP_NM_RESULT;
END;
$$ LANGUAGE plpgsql;


--CREATE OR REPLACE FUNCTION F_EMP_NM
--(
--    EMP_NO_IN VARCHAR
--)
--RETURNS VARCHAR AS $$
--BEGIN
--    
--    RETURN (SELECT  EMP_NM 
--            FROM    EDU01.EDU_EMP_BASE
--            WHERE   EMP_NO = EMP_NO_IN
--           );
--END;
--$$ LANGUAGE PLPGSQL;


SELECT F_EMP_NM('000002');
 
-- (2) 고객번호를받아서13자리인경우이를주민번호로간주하고, 앞의두자리를이용하여, 나이를구하는함수를만드시오.

-- (13자리가아닌경우에는0을리턴함)

CREATE OR REPLACE FUNCTION GET_CUST_AGE(
    BIRTH_DT VARCHAR
) 
RETURNS VARCHAR AS $$
DECLARE
    BIRTH_YEAR INT;
    CURRENT_YEAR INT;
    AGE INT;
BEGIN

	IF LENGTH(TRIM(BIRTH_DT)) != 8 THEN
        RETURN '0';
    END IF;

    BIRTH_YEAR := SUBSTR(BIRTH_DT, 1, 4)::INT;
    CURRENT_YEAR := EXTRACT(YEAR FROM NOW());


    AGE := CURRENT_YEAR - BIRTH_YEAR + 1;

    RETURN AGE::VARCHAR;
END;
$$ LANGUAGE PLPGSQL;


SELECT GET_CUST_AGE(BIRTH_DT) AS "AGE"
FROM  EDU_CUST_BASE
;

----27P/ PROCEDURE(프로시저)----------------------------------------------------------------------------


--(1) 다음의 정보를 매개변수로 판매_요약테이블에 INSERT를수행하는 프로시저P_SELL_SUMM을작성하시오.

--판매일자, 판매부서, 상품코드, 판매수량

CREATE OR REPLACE PROCEDURE P_SELL_SUMM(
    P_SELL_DT VARCHAR
   ,P_DEPT_CD BPCHAR
   ,P_GODS_CD VARCHAR
   ,P_SELL_QTY NUMERIC
)
AS $$
BEGIN
    INSERT INTO EDU01.EDU_SELL_SUMM (SELL_DT, DEPT_CD, GODS_CD, SELL_QTY)
    VALUES                          (P_SELL_DT, P_DEPT_CD, P_GODS_CD, P_SELL_QTY);
END;
$$LANGUAGE PLPGSQL;
 

SELECT * FROM EDU01.EDU_SELL_SUMM;



CALL P_SELL_SUMM('2024-12-19', '000001', 'G0001', 100);

SELECT * FROM edu_sell_summ WHERE 1=1




--(2) 다음의 정보를 매개변수로 판매_요약테이블에 정보를반영하는프로시저P_SELL_SUMM을작성하십시오.

--처리구분, 판매일자, 판매부서, 상품코드, 판매수량 (처리구분:C-등록,U-수정,D-삭제)
--등록-> 수량, 금액을 누적 처리함.
--수정-> 수량, 금액을 누적 처리함.
--삭제-> 해당 수량만큼 수량및금액을기존정보에서빼나감.

--CREATE OR REPLACE PROCEDURE P_SELL_SUMM
--(
--    P_PROC_CD VARCHAR,         -- 처리구분 (C: 등록, U: 수정, D: 삭제)
--    P_SELL_DT VARCHAR,         
--    P_DEPT_CD VARCHAR,
--    P_GODS_CD VARCHAR,      
--    P_SELL_QTY INT,         
--    P_SELL_AMT NUMERIC      
--)
--LANGUAGE PLPGSQL
--AS $$
--BEGIN
--    -- 등록 (C)
--    IF P_PROC_CD = 'C' THEN
--        INSERT INTO   EDU01.EDU_SELL_SUMM (SELL_DT, DEPT_CD, GODS_CD, SELL_QTY, SELL_AMT)
--        VALUES                            (P_SELL_DT, P_DEPT_CD, P_GODS_CD, P_SELL_QTY, P_SELL_AMT)
--        ON CONFLICT   (SELL_DT, DEPT_CD, GODS_CD)
--        DO UPDATE 
--                      SET SELL_QTY = EDU_SELL_SUMM.SELL_QTY + EXCLUDED.SELL_QTY,
--                      SELL_AMT = EDU_SELL_SUMM.SELL_AMT + EXCLUDED.SELL_AMT;
--
----     수정 (U)
----    ELSIF P_PROC_CD = 'U' THEN
----        UPDATE     EDU01.EDU_SELL_SUMM
----        SET        SELL_QTY = P_SELL_QTY,
----                   SELL_AMT = P_SELL_AMT
----        WHERE      SELL_DT = P_SELL_DT 
----                   AND DEPT_CD = P_DEPT_CD
----                   AND GODS_CD = P_GODS_CD;
--
--    -- 삭제 (D)
--    ELSIF P_PROC_CD = 'D' THEN
--        UPDATE      EDU01.EDU_SELL_SUMM
--        SET         SELL_QTY = SELL_QTY - P_SELL_QTY,
--                    SELL_AMT = SELL_AMT - P_SELL_AMT
--        WHERE       SELL_DT = P_SELL_DT 
--                    AND DEPT_CD = P_DEPT_CD
--                    AND GODS_CD = P_GODS_CD;
--
--        DELETE FROM EDU01.EDU_SELL_SUMM
--        WHERE       SELL_DT = P_SELL_DT  
--                    AND DEPT_CD = P_DEPT_CD 
--                    AND GODS_CD = P_GODS_CD;
--    END IF;
--END;
--$$;

----29P/ OLAP 함수 1-----------------------------------------------------------------------------------

--(1) 2020년 1월달 판매내역을 기준으로, 다음과 같이 판매금액 순으로 부서별 판매순위를 나타내시오. 

--부서명 판매금액 판매순위
--영업1팀 10,000  1/2
--영업2팀 9,000   2/2
    

SELECT   F_DEPT_NM(A.SELL_EMP_NO)                                                            AS "부서명"
        ,SUM(COALESCE(B.SELL_PRCE, 0))                                                       AS "판매금액"
        ,RANK() OVER(ORDER BY SUM(COALESCE(B.SELL_PRCE, 0)) DESC) || '/' || COUNT(1) OVER()  AS "판매순위"
FROM     EDU01.EDU_SELL_DESC A 
         LEFT OUTER JOIN EDU01.EDU_GODS_BASE B
         ON A.GODS_CD = B.GODS_CD
WHERE    SUBSTR(A.SELL_DT,1,7) LIKE '2020-01%'
GROUP BY 1
;


-- (2) 2020년 1월달 판매내역을 기준으로, 다음과 같이 판매금액 순으로 부서내 직원별판매순위를 나타내시오.

--부서명 직원명 판매금액 부서내판매순위
--영업1팀 홍길동 10,000        1
--영업1팀 고길동 8,000         2
--영업2팀 박길동 9,000         1
--영업2팀 김길동 5,000         2
--영업2팀 최길동 1,000         3


SELECT   F_DEPT_NM(A.SELL_EMP_NO)                                                                          AS "부서명"
        ,F_EMP_NM(A.SELL_EMP_NO)                                                                           AS "직원명"
        ,SUM(COALESCE(B.SELL_PRCE, 0))                                                                     AS "판매금액"
        ,RANK() OVER(PARTITION BY F_DEPT_NM(A.SELL_EMP_NO) ORDER BY SUM(COALESCE(B.SELL_PRCE, 0)) DESC) ||
         '/' ||
         COUNT(1) OVER(PARTITION BY F_DEPT_NM(A.SELL_EMP_NO))                                              AS "판매순위"
FROM     EDU01.EDU_SELL_DESC A 
         LEFT OUTER JOIN EDU01.EDU_GODS_BASE B
         ON A.GODS_CD = B.GODS_CD
WHERE    SUBSTR(A.SELL_DT,1,7) LIKE '2020-01%'
GROUP BY 1, A.SELL_EMP_NO
;

----30P/ OLAP 함수 2------------------------------------------------------------------------------------


--(1) 2020년1월달판매내역에순번을붙여표기하시오. 

--(ROW_NUMBER()을사용)
--순번 판매일자 판매사원번호 판매수량

SELECT ROW_NUMBER() OVER(ORDER BY SELL_DT) AS "순번"
      ,SELL_DT                             AS "판매일자"
      ,SELL_EMP_NO                         AS "판매사원번호"
      ,SELL_QTY                            AS "판매수량"
FROM   EDU01.EDU_SELL_DESC
WHERE  SELL_DT LIKE '2020-01-%'
;


--(2) 위의(1)의항목에누적판매수량을추가하여보여주시오.

--(OLAP함수를사용하지않고작성한경우와PRECEDING OLAP 함수를사용한경우로작성하시오)
--순번판매일자판매사원번호판매수량누적판매수량


--*PRECEDING사용
SELECT     ROW_NUMBER() OVER (ORDER BY SELL_DT)                                                     AS "순번"                                                     
          ,SELL_DT                                                                                  AS "판매일자"                                                                                            
          ,SELL_EMP_NO                                                                              AS "판매사원번호"                                                                                       
          ,SELL_QTY                                                                                 AS "판매수량"                                                                                            
          ,SUM(SELL_QTY) OVER (ORDER BY SELL_DT ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)   AS "누적판매수량"
FROM 
          EDU01.EDU_SELL_DESC
WHERE 
          SELL_DT LIKE '2020-01-%'
;
   
--*WITH 사용
WITH TMP_TB AS (
    SELECT     ROW_NUMBER() OVER (ORDER BY SELL_DT) AS RANK_NO
              ,SELL_DT                                                     
              ,SELL_EMP_NO                                                 
              ,SELL_QTY                                                              
    FROM       EDU01.EDU_SELL_DESC
    WHERE      SELL_DT LIKE '2020-01-%'
)
SELECT
                A.RANK_NO                    AS "순번"
               ,A.SELL_DT                    AS "판매일자"
               ,A.SELL_EMP_NO                AS "판매사원번호"
               ,A.SELL_QTY                   AS "판매수량"
               ,(SELECT SUM(B.SELL_QTY)
                FROM TMP_TB B
                WHERE B.RANK_NO <= A.RANK_NO
                )                            AS "누적판매수량"
FROM TMP_TB A
ORDER BY 1
;


--------------------------------------------활용실습-----------------------------------------------------

--------------------------------------------사용함수-----------------------------------------------------
CREATE OR REPLACE FUNCTION F_DEPT_NM (
    F_SELL_EMP_NO VARCHAR
)
RETURNS VARCHAR AS $$
DECLARE
    DEPT_NM_RESULT VARCHAR;
BEGIN
    SELECT     DEPT_NM INTO  DEPT_NM_RESULT
    FROM       EDU01.EDU_SELL_DESC A`
               LEFT OUTER JOIN EDU01.EDU_EMP_BASE B
               ON A.SELL_EMP_NO = B.EMP_NO
               LEFT OUTER JOIN EDU01.EDU_ORG_BASE C
               ON B.DEPT_CD = C.DEPT_CD
    WHERE      A.SELL_EMP_NO = F_SELL_EMP_NO;

    IF DEPT_NM_RESULT IS NULL THEN
        RETURN '부서이름없음';
    END IF;

    RETURN DEPT_NM_RESULT;
END;
$$ LANGUAGE PLPGSQL;


CREATE OR REPLACE FUNCTION F_DEPT_CD (
    F_SELL_EMP_NO VARCHAR
)
RETURNS BPCHAR AS $$
DECLARE
    DEPT_CD_RESULT VARCHAR;
BEGIN
    SELECT     B.DEPT_CD INTO  DEPT_CD_RESULT
    FROM       EDU01.EDU_SELL_DESC A
               LEFT OUTER JOIN EDU01.EDU_EMP_BASE B
               ON A.SELL_EMP_NO = B.EMP_NO
    WHERE      A.SELL_EMP_NO = F_SELL_EMP_NO;

    IF DEPT_CD_RESULT IS NULL THEN
        RETURN '부서코드없음';
    END IF;

    RETURN DEPT_CD_RESULT;
END;
$$ LANGUAGE PLPGSQL;


----32P / STEP-1 기본 응용-------------------------------------------------------------------------------

--(1) 고객번호:8003182925913(한혜정)의 2020년간 구매수량을 상품구분별로 조회하시오.

--상품구분   구매수량
--TV/DMB    10
--DVD/VT    20        
--캠코더       0 
--음향기기      3 
--홈시어터      4 
--전화기       2

SELECT    C.CD_NM                                        AS "상품구분"   
         ,SUM(A.SELL_QTY) OVER (PARTITION BY C.CD_NM)    AS "구매수량"
FROM      EDU01.EDU_SELL_DESC A                 
          LEFT OUTER JOIN EDU01.EDU_GODS_BASE B 
              ON A.GODS_CD = B.GODS_CD          
          LEFT OUTER JOIN EDU01.EDU_COMM_CD C   
              ON B.GODS_DIV = C.CD              
WHERE     A.CUST_NO = 'C0181991'    
          AND A.SELL_DT LIKE '2020%'
;

-- (2) 상품을 구매한 고객의 주소가 서울인판매내역을 다음과같이조회하시오.

--부서명    판매수량 
--영업1팀    123     
--:



WITH TMP_TABLE AS (
     SELECT  A.CUST_NO
     FROM    EDU01.EDU_CUST_ADDR A
             LEFT OUTER JOIN EDU_SELL_DESC B
             ON A.CUST_NO = B.CUST_NO 
     WHERE   A.ADDR LIKE '서울%'
                  )
SELECT       F_DEPT_NM(C.SELL_EMP_NO), SUM(C.SELL_QTY)
FROM         EDU_SELL_DESC C
WHERE        EXISTS (
                               SELECT 1
                               FROM   TMP_TABLE 
                               WHERE C.cust_no = TMP_TABLE.CUST_NO
                    )
GROUP BY     1
;


-- (3) 2011년 판매실적을 고객의 지역별로 다음과 같이집계하시오.

--지역 판매수량
--서울  100
--경기  200
--인천  300
--충남  400
--:

SELECT      SPLIT_PART(A.ADDR, ' ', 1)    AS "지역"
           ,SUM(B.SELL_SEQ)               AS "판매수량"
FROM        EDU01.EDU_CUST_ADDR A
            LEFT OUTER JOIN EDU01.EDU_SELL_DESC B
            ON A.CUST_NO = B.CUST_NO
WHERE       B.SELL_DT LIKE '2021%'
GROUP BY    1
;






----33P / STEP-2 판매실적/등급----------------------------------------------------------------------------


--(1) 다음과같은기준에따라영업1팀의직원별2020년의실적정보및판매등급을나타내시오.

-- [판매등급기준]
--가. 총매출액> 5억원 판매왕
--나. 판매수량> 435개  실적왕
--다. 판매횟수> 50건 영업왕

--사원번호    사원명    총매출건수     총판매수량       총매출금액       등급
--000001    홍길동      49          393       576950000     판매왕         
--000006    이길동      52          431       377500000     영업왕         
--000011    정준형      47          385       636900000     판매왕         
--000016    이선우      52          386       562050000     판매왕         
--000022    오종한      47          396       579200000     판매왕         
--000027    주성환      52          439       436200000     실적왕         
--000031    부시맨      46          372       573100000     판매왕         



SELECT   A.SELL_EMP_NO                                         AS "사원번호"                       
        ,F_EMP_NM(A.SELL_EMP_NO)                               AS "사원명"                        
        ,COUNT(1)                                              AS "총매출건수"                      
        ,SUM(A.SELL_QTY)                                       AS "총판매수량"                      
        ,SUM(A.SELL_QTY * B.SELL_PRCE)                         AS "총매출금액"                      
        ,CASE                                                           
             WHEN SUM(A.SELL_QTY * B.SELL_PRCE) > 500000000 THEN '판매왕'  
             WHEN SUM(A.SELL_QTY) > 435 THEN '실적왕'                      
             WHEN COUNT(1) > 50 THEN '영업왕'                      
             ELSE ''                                                    
         END                                                   AS "등급"                                                    
FROM     EDU01.EDU_SELL_DESC A              
         INNER JOIN EDU01.EDU_GODS_BASE B   
         ON A.GODS_CD = B.GODS_CD           
WHERE    F_DEPT_NM(A.SELL_EMP_NO) = '영업1팀'     
         AND A.SELL_DT LIKE '2020%'            
GROUP BY 1
;





----34P / STEP-3 일괄반영 처리----------------------------------------------------------------------------



--(1) 2021년의 판매내역을 그대로 참고(복제)하여 2023년의 판매내역으로 생성하십시오.


INSERT INTO EDU01.EDU_SELL_DESC (
     SELL_DT 
    ,SELL_SEQ 
    ,SELL_EMP_NO 
    ,CUST_NO
    ,GODS_CD 
    ,SELL_QTY 
    ,RETN_DT 
    ,RETN_SEQ 
    ,FRST_REG_DT 
    ,FRST_REG_TM 
    ,FRST_REG_EMP_NO 
    ,LAST_PROC_DT 
    ,LAST_PROC_TM 
    ,LAST_PROC_EMP_NO
)
SELECT  REPLACE(SELL_DT, '2021', '2023') AS SELL_DT   
       ,SELL_SEQ                                     
       ,SELL_EMP_NO                                  
       ,CUST_NO                                      
       ,GODS_CD                                      
       ,SELL_QTY                                     
       ,RETN_DT                                      
       ,RETN_SEQ                                     
       ,FRST_REG_DT                                  
       ,FRST_REG_TM                                  
       ,FRST_REG_EMP_NO                              
       ,LAST_PROC_DT                                 
       ,LAST_PROC_TM                                 
       ,LAST_PROC_EMP_NO                              
FROM EDU01.EDU_SELL_DESC
WHERE SELL_DT LIKE '2021%';

SELECT * FROM EDU01.EDU_SELL_DESC WHERE SELL_DT LIKE '2023%';

--(2) 2020년의 판매내역을 이용하여 판매_요약(EDU_SELL_SUMM) 테이블에 정보를 생성하시오. 
--(신규건과 기등록건에 대한두가지처리가필요함, DELETE를사용하지 말것)




----35P / STEP-4 기간별 실적집계---------------------------------------------------------------------------



--(1) 아래와 같이 특정년도에 대한부서별1년치판매수량을 집계하는쿼리를작성하시오. (2020년기준으로 집계하시오)

--부서명    1월   2월   3월   4월   5월   6월   7월   8월   9월   10월   11월   12월    계



--(2) 아래와 같이 특정년도에 대한부서별1년치판매수량을 기준으로월별판매수량의증감분을표현하시오. (2021년기준집계)

--부서명    1월    2월    3월    4월    5월    6월    7월    8월    9월    10월    11월    12월    평균증감율
--영업1팀   0     +10    +2   -10    +20    +3    +2    -5     +7     +4     +1     -7      +2.25




----36P / STEP-5 직급별 현황 구하기------------------------------------------------------------------------




--(1) 다음과 같이 각 부서의 직급별로 평균수익율을구하시오.

--수익 = 판매가격–매입가격
--부서별수익율= SUM(부서별 수익)/전체수익

--부서명   부서수익   전체수익    수익율
--영업1팀   100     1000     10.0




-- (2) 위의 (1)과 동일한 조건으로 부서별 정보를가져오되, 부서간 순위와평가결과를 추가하여 보여주시오.

-- [평가결과 기준]
--가장높은수익율을낸부서  >  최우수
--가장낮은수익율을낸부서  >  최하위
--그외  >  (공백)

--부서명      부서수익     전체수익    수익율    순위    평가결과
--영업1팀      100       1000     10.0     1     최우수
--영업1팀      50        1000     5.0      2     최우수
--  .                                      
--  .                                      
--  .                                      
--영업4팀      100       1000     10.0     33    최우수


----37P / STEP-6 직원 급여 산출----------------------------------------------------------------------------



--(1) 다음의 공식 및 관련테이블을 참조하여, 직원별 2020년1월급여를 산정하시오.

--기본급 = 직급기본테이블에서해당직급에맞는월급여
--인센티브= 해당사원의매출액의5%
--
--부서명    사원번호    사원명    직급    기본급    인센티브    총급여    매출액
--영업1팀   000001   홍길동     대리    100       5      105     100




----38P /  STEP-7 확장응용(달력)---------------------------------------------------------------------------



-- (1) 특정년월을지정(입력)하면, 해당월에해당하는날짜를가져오는쿼리를작성하시오.

-- 날짜
-- 2020-01-01
-- 2020-01-02
-- :
-- 2020-01-31


SELECT generate_series(
           TO_DATE(:input_date || '-01', 'YYYY-MM-DD'),
           (TO_DATE(:input_date || '-01', 'YYYY-MM-DD') + INTERVAL '1 month' - INTERVAL '1 day')::date,
           '1 day'::interval
) AS date;






-- (2) 위의(1)의쿼리를응용하여, 다음과같이달력형식으로출력되는쿼리를작성하시오.

-- ( TO_CHAR(날짜,’d’) >날짜에해당하는요일이숫자로표현됨(1,2,3…,7)
-- TRUNC(날짜,’d’)     >날짜에해당하는요일의첫번째날짜가나옴)
--일     월  화    수    목  금    토
--                    1   2    3
-- 4    5   6    7    8   9   10
-- 11  12  13   14   15  16   17
-- 18  19  20   21   22  23   24
-- 25  26  27   28   29  30   31



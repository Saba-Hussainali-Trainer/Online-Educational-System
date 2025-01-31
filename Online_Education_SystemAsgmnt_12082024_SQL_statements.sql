Q.1.)	Top 5 schools with overall teachers’ login% > 60% 
Ans.)
/*
Table TeachersLoginInsight is created and used to solve this question.

If login_percentage > 60.00 % then login_percentage_SIXTY_YES = 1 else login_percentage_SIXTY_YES = 0
login_percentage_SIXTY_YES indicates if overall login percentage of a teacher is greater than 60 %
*/

USE Alef_Edu_Assignment;
 
 CREATE TABLE TeachersLoginInsight
 (
 school_name VARCHAR(25) NOT NULL,
 teacher_id VARCHAR(10) NOT NULL,
 actual_attendence_count INT,
 required_attendence_count INT,
 login_percentage INT
 );
 

 ALTER TABLE TeachersLoginInsight
 ALTER COLUMN login_percentage DECIMAL(18,2);

 ALTER TABLE TeachersLoginInsight
 ADD login_percentage_SIXTY_YES INT;


 WITH CTE_REQUIRED_AC AS
 (
 SELECT school_name, teacher_id, COUNT(DISTINCT record_date) AS required_attendence_count
 FROM teacher_activity
 GROUP BY school_name, teacher_id
 --ORDER BY COUNT(DISTINCT record_date) DESC
 ),

 CTE_ATTENDENCE_COUNT AS
 (
 SELECT school_name, teacher_id, COUNT(DISTINCT record_date) AS actual_attendence_count
 FROM 
 (SELECT school_name, teacher_id, record_date FROM teacher_activity WHERE is_present = 'TRUE') P
 GROUP BY teacher_id, school_name
 --ORDER BY COUNT(DISTINCT record_date) DESC
 ),

 CTE_ACTUAL_AC AS
 (
 SELECT 
 CTE_ATTENDENCE_COUNT.school_name,
 CTE_ATTENDENCE_COUNT.teacher_id, --COUNT(DISTINCT CTE_REQUIRED_AC.teacher_id),

 MAX(CTE_ATTENDENCE_COUNT.actual_attendence_count) AS actual_attendence_count
 
 FROM CTE_ATTENDENCE_COUNT
 GROUP BY CTE_ATTENDENCE_COUNT.school_name, CTE_ATTENDENCE_COUNT.teacher_id
 --ORDER BY MAX(CTE_ATTENDENCE_COUNT.actual_attendence_count) DESC
 ),

 CTE_LOGIN_PERCENT AS
 (
 SELECT
 CTERAC.school_name AS school_name,
 CTERAC.teacher_id AS teacher_id,
 ISNULL(CTEAC.actual_attendence_count,0) AS actual_attendence_count,
 CTERAC.required_attendence_count AS required_attendence_count,
 ISNULL((CAST(CAST(CTEAC.actual_attendence_count AS DECIMAL(18,5))/ CAST(CTERAC.required_attendence_count AS DECIMAL(18,5))*100 AS DECIMAL(18,2) )),0.0) AS login_percentage,
 CAST(ISNULL((CAST(CAST(CTEAC.actual_attendence_count AS DECIMAL(18,5))/ CAST(CTERAC.required_attendence_count AS DECIMAL(18,5))*100 AS DECIMAL(18,2) )),0.0) AS VARCHAR(100)) + ' %' AS login_percentage_label
 FROM CTE_REQUIRED_AC CTERAC
 FULL OUTER JOIN CTE_ATTENDENCE_COUNT CTEAC ON CTERAC.teacher_id = CTEAC.teacher_id
 --ORDER BY CTEAC.actual_attendence_count DESC
 )
 
 INSERT INTO TeachersLoginInsight
 --CTE_LOGIN_PERCENT_SIXTY_YES AS
 --(
 SELECT CTELP.school_name AS school_name,
 CTELP.teacher_id AS teacher_id,
 CTELP.actual_attendence_count AS actual_attendence_count,
 CTELP.required_attendence_count AS required_attendence_count,
 CTELP.login_percentage AS login_percentage,
 CASE
	WHEN CTELP.login_percentage > 60.00 THEN 1
	ELSE 0
 END AS login_percentage_SIXTY_YES
 FROM CTE_LOGIN_PERCENT CTELP
 
-------------------------------------------------------------
CREATE TABLE RankSchoolsAccordingToTeachersLoginPercent
 (
 school_name VARCHAR(25) NOT NULL,
 cnt_teachers_wit_gt_sixtypercent_att INT NOT NULL,
 Rank_schools INT NOT NULL
 );
 
 WITH CTE_T1 AS
 (
 SELECT TLI.school_name AS school_name, 
 --COUNT(DISTINCT TLI.teacher_id) AS teacher_id, 
 COUNT(TLI.login_percentage_SIXTY_YES) AS cnt_teachers_wit_gt_sixtypercent_att
 FROM TeachersLoginInsight TLI
 GROUP BY TLI.school_name, TLI.login_percentage_SIXTY_YES
 HAVING TLI.login_percentage_SIXTY_YES = 1
 --ORDER BY COUNT(DISTINCT TLI.teacher_id) DESC;
 )

 INSERT INTO RankSchoolsAccordingToTeachersLoginPercent
 SELECT 
 CTET1.school_name AS school_name, 
 CTET1.cnt_teachers_wit_gt_sixtypercent_att AS cnt_teachers_wit_gt_sixtypercent_att,
 DENSE_RANK() OVER (ORDER BY CTET1.cnt_teachers_wit_gt_sixtypercent_att DESC) AS Rank_schools
 FROM CTE_T1 CTET1;

 SELECT * FROM RankSchoolsAccordingToTeachersLoginPercent;

--OUTPUT also available in attached excel file
/*
school_name	    cnt_teachers_wit_gt_sixtypercent_att	 Rank_schools
ABU DHABI_1498	5	1
ABU DHABI_1706	5	1
ABU DHABI_377	4	2
AL AIN_1562	3	3
ABU DHABI_1530	2	4
ABU DHABI_1373	2	4  
ABU DHABI_1652	2	4
ABU DHABI_1642	1	5
ABU DHABI_1967	1	5
*/

/*****************************************************************************************************************************/
Q.2.)	Teachers Login day over day change in percentage across all schools
Ans.)

/* FINAL CODE for Q2 */

CREATE TABLE DODchangeLoginInsightTeacher
(
school_name VARCHAR(25) NOT NULL,
record_date DATE NOT NULL,
daily_actual_login_count INT NOT NULL,
Daily_Expected_Login_Count INT NOT NULL,
previous_day_login_count INT NOT NULL,
daily_actual_login_percentage DECIMAL(10,2) NOT NULL,
previous_day_login_percentage DECIMAL(10,2) NOT NULL,
dod_change_in_login_percentage DECIMAL(10,2) NOT NULL,
dod_change_in_login_count INT NOT NULL
);

WITH CTE_DELC AS
(
SELECT 
school_name, 
record_date,

COUNT(DISTINCT teacher_id) AS Daily_Expected_Login_Count
FROM teacher_activity
GROUP BY school_name, record_date
--ORDER BY school_name, record_date
),

CTE_DALC AS
(
SELECT 
CTEDELC.school_name, 
CTEDELC.record_date,
COUNT(DISTINCT TA.teacher_id) AS daily_actual_login_count,
--COUNT(TA.is_present) AS daily_actual_login_count,
CTEDELC.Daily_Expected_Login_Count
FROM teacher_activity TA
LEFT JOIN CTE_DELC CTEDELC ON TA.school_name = CTEDELC.school_name
AND TA.record_date = CTEDELC.record_date
GROUP BY CTEDELC.school_name, CTEDELC.record_date, CTEDELC.Daily_Expected_Login_Count, TA.is_present
HAVING TA.is_present = 'TRUE'
--ORDER BY CTEDELC.school_name, CTEDELC.record_date, CTEDELC.Daily_Expected_Login_Count
),


CTE_OverallTeachersLogin AS
(
SELECT 
CTEDELC.school_name AS school_name, 
CTEDELC.record_date AS record_date,
ISNULL(CTEDALC.daily_actual_login_count,0) AS daily_actual_login_count,
CTEDELC.Daily_Expected_Login_Count AS Daily_Expected_Login_Count

FROM CTE_DELC CTEDELC
LEFT JOIN CTE_DALC CTEDALC ON CTEDELC.school_name = CTEDALC.school_name 
AND CTEDELC.record_date = CTEDALC.record_date
--ORDER BY CTEDELC.school_name, CTEDELC.record_date, CTEDELC.Daily_Expected_Login_Count
),

CTE_previous_day_login_count AS
(
SELECT *,
ISNULL(LAG(CTEOTL.daily_actual_login_count,1) OVER 
			(PARTITION BY CTEOTL.school_name ORDER BY CTEOTL.record_date) ,0)
			AS previous_day_login_count
FROM CTE_OverallTeachersLogin CTEOTL
--ORDER BY CTEOTL.school_name, CTEOTL.record_date, CTEOTL.Daily_Expected_Login_Count
),

CTE_LoginPercentageCalculation AS
(
SELECT * ,
CAST(((CAST(CTEPDLC.daily_actual_login_count AS DECIMAL(10,2))/CAST(CTEPDLC.Daily_Expected_Login_Count AS DECIMAL(10,2)))*100) AS DECIMAL(10,2))
			AS daily_actual_login_percentage,

CAST(((CAST(CTEPDLC.previous_day_login_count AS DECIMAL(10,2))/CAST(CTEPDLC.Daily_Expected_Login_Count AS DECIMAL(10,2)))*100) AS DECIMAL(10,2))
			AS previous_day_login_percentage

			
FROM CTE_previous_day_login_count CTEPDLC
)
INSERT INTO DODchangeLoginInsightTeacher
SELECT *,
CTELPCAL.daily_actual_login_percentage - CTELPCAL.previous_day_login_percentage 
		AS dod_change_in_login_percentage, --daily_login_percentage_difference
		
CTELPCAL.daily_actual_login_count - CTELPCAL.previous_day_login_count
		AS dod_change_in_login_count --daily_login_count_difference

FROM CTE_LoginPercentageCalculation CTELPCAL
;


SELECT * FROM DODchangeLoginInsightTeacher; --Table for Q2 full data available in excel file



/*****************************************************************************************************************************/
/*****************************************************************************************************************************/
Q.3.)	If each billable student pays 500$/Month, what’s the revenue generated per school 
Ans.)
/*
Revenue is the money generated from normal business operations, calculated as the average sales price times the number of units sold.
Considering 500$/Month as the average sales price. No exact logic is understood therefore sum of that amount for two months is considered.
*/

/* LOGIC

SELECT school_name, student_id, start_date_of_month,paid_amount
FROM student_datesn_amount
GROUP BY school_name, student_id, start_date_of_month,paid_amount
HAVING MAX(paid_amount) <> 0
ORDER BY school_name, student_id, start_date_of_month,paid_amount;

*/

SELECT school_name, SUM(paid_amount) AS total_revenue
FROM student_datesn_amount
GROUP BY school_name

ORDER BY SUM(paid_amount) DESC;

/* OUTPUT
school_name	total_revenue
ABU DHABI_1642	1946000
ABU DHABI_1706	522000
ABU DHABI_377	316000
ABU DHABI_1498	308500
ABU DHABI_1373	296500
ABU DHABI_1530	290000
ABU DHABI_1652	289000
ABU DHABI_1380	287000
ABU DHABI_1967	238000
AL AIN_1775	234000
AL AIN_1562	169000
ABU DHABI_1620	141000
ABU DHABI_176	120000
ABU DHABI_1476	9000

*/

/*****************************************************************************************************************************/
/*****************************************************************************************************************************/
Q.4.)	Find the number of teachers per school who logged in 3 consecutive days 
Ans.)

CREATE TABLE ConsecutiveLoginInsight
(
school_name VARCHAR(25) NOT NULL,
teacher_id VARCHAR(10) NOT NULL,
record_date DATE NOT NULL,

actual_login_day INT NOT NULL,
required_login_day INT NOT NULL, 
is_present VARCHAR(8) NOT NULL,

cal1_days INT NOT NULL, --days_for_calculation
cal1_date DATE NOT  NULL, --date_for_calculation
cal2_date DATE NOT  NULL,
);

--Required Login Day
WITH CTE_RLD AS
(
SELECT school_name AS school_name, 
teacher_id AS teacher_id, 
record_date AS record_date, 
ROW_NUMBER() OVER (PARTITION BY teacher_id, is_present ORDER BY record_date) AS cal1_days,
ROW_NUMBER() OVER (PARTITION BY teacher_id ORDER BY record_date) AS required_login_day,
is_present AS is_present
FROM teacher_activity
),

--Actual Login Day
CTE_ALD AS
(

SELECT CTERLD.school_name,
CTERLD.teacher_id, 
CTERLD.record_date,
CTERLD.cal1_days,
CASE
	WHEN is_present = 'TRUE' THEN CTERLD.cal1_days
	ELSE 0
	END AS actual_login_day,
CTERLD.required_login_day, 
CTERLD.is_present,
CASE
	WHEN CTERLD.is_present = 'TRUE' THEN DATEADD(D,-required_login_day,record_date)
	
	ELSE '1999-01-01'
	END AS cal1_date
FROM CTE_RLD CTERLD
--ORDER BY CTERLD.school_name, CTERLD.teacher_id, CTERLD.record_date
)

INSERT INTO ConsecutiveLoginInsight
SELECT 
CTEALD.school_name, 
CTEALD.teacher_id, 
CTEALD.record_date, 

CTEALD.actual_login_day, 
CTEALD.required_login_day,  
CTEALD.is_present, 

CTEALD.cal1_days, 

CTEALD.cal1_date, 

CASE
	WHEN is_present = 'TRUE' THEN DATEADD(D,-actual_login_day,record_date)
	
	ELSE '1999-01-01'
	END AS cal2_date
FROM CTE_ALD CTEALD
;

SELECT * FROM ConsecutiveLoginInsight;

CREATE TABLE Q4Insight
(
teacher_id VARCHAR(10) NOT NULL,
logged_in_3_consecutive_days VARCHAR(5) NOT NULL
);

WITH CTE_Q4 AS
(
SELECT teacher_id, cal2_date, COUNT(cal2_date) AS cal2_consecutive_days,
CASE
	WHEN cal2_date <> '1999-01-01' AND COUNT(cal2_date) >= 3 THEN 'Yes'
	ELSE 'No'
	END AS logged_in_3_consecutive_days
FROM ConsecutiveLoginInsight
GROUP BY teacher_id, cal2_date

--ORDER BY teacher_id, cal2_date
)

INSERT INTO Q4Insight
SELECT CTEQ4.teacher_id, CTEQ4.logged_in_3_consecutive_days
FROM CTE_Q4 CTEQ4
GROUP BY CTEQ4.teacher_id, CTEQ4.logged_in_3_consecutive_days
;

/* Q4Data sheet */
SELECT * FROM ConsecutiveLoginInsight CLI
LEFT JOIN Q4Insight Q4I
ON CLI.teacher_id = Q4I.teacher_id;

/* Q4OUTPUT sheet */
SELECT
CLI.school_name, 
ISNULL(COUNT(DISTINCT CLI.teacher_id),0) AS cnt_teachers_wit_3_consecutive_login_days
FROM ConsecutiveLoginInsight CLI
LEFT JOIN Q4Insight Q4I
ON CLI.teacher_id = Q4I.teacher_id
GROUP BY CLI.school_name, Q4I.logged_in_3_consecutive_days
HAVING Q4I.logged_in_3_consecutive_days = 'Yes'
ORDER BY COUNT(DISTINCT CLI.teacher_id) DESC
;

SELECT * FROM Q4Insight Q4I
LEFT JOIN ConsecutiveLoginInsight CLI 
ON CLI.teacher_id = Q4I.teacher_id;


SELECT COUNT(DISTINCT teacher_id) FROM teacher_activity;

SELECT * FROM ConsecutiveLoginInsight;
SELECT * FROM Q4Insight;


/*
school_name	cnt_teachers_wit_3_consecutive_login_days
ABU DHABI_1498	13
ABU DHABI_1652	8
ABU DHABI_1706	7
ABU DHABI_1530	6
ABU DHABI_377	5
AL AIN_1562	5
ABU DHABI_1373	4
ABU DHABI_1642	4
ABU DHABI_1967	4
AL AIN_1775	2
ABU DHABI_176	2
ABU DHABI_1620	1
*/
/*****************************************************************************************************************************/
/*****************************************************************************************************************************/
Q.5.)	Find the weekly average for student login activity per school  
Ans.)
--Per school average number of students logging in per week logic is used
 
 /****** for students *****************************************************/

SELECT 
SA.school_name AS school_name,
COUNT(DISTINCT SA.student_id) AS count_students
FROM student_activity SA
GROUP BY SA.school_name
ORDER BY COUNT(DISTINCT SA.student_id) DESC

CREATE TABLE student_datesn_amount
(
school_name VARCHAR(25) NOT NULL,
student_id VARCHAR(10) NOT NULL,
record_date DATE NOT NULL,
is_present VARCHAR(8) NOT NULL,
daily_login INT NOT NULL,
day_of_week INT NOT NULL,
last_date_of_week DATE NOT NULL,
start_date_of_month DATE NOT NULL,
paid_amount INT NOT NULL
);


INSERT INTO student_datesn_amount
SELECT 
SA.school_name AS school_name,
SA.student_id AS student_id,
SA.record_date AS record_date,
SA.is_present AS is_present,
CASE
	WHEN SA.is_present = 'TRUE' THEN 1
	ELSE 0
	END AS daily_login,

DATEPART(weekday,SA.record_date) AS day_of_week,--1 -Sunday
DATEADD(day,7-DATEPART(weekday,SA.record_date),SA.record_date) AS last_date_of_week,

CAST(DATEADD(month, DATEDIFF(month, 0, SA.record_date), 0) AS DATE)  AS start_date_of_month,
CASE
	WHEN SA.record_date = '2020-10-25' OR SA.record_date = '2020-11-01' THEN 500
	ELSE 0
	END AS paid_amount
FROM student_activity SA;


/* CTE_WeeklyStudentLoginData file */


CREATE TABLE CTE_WeeklyStudentLoginData_Insight
(
school_name VARCHAR(25) NOT NULL,
last_date_of_week DATE NOT NULL,
student_id VARCHAR(10) NOT NULL,
login_count_in_week INT NOT NULL,
login_in_week INT NOT NULL, --status
);


DROP TABLE WeeklyAverageStudentsLoginData_Insight;

CREATE TABLE WeeklyAverageStudentsLoginData_Insight
(
school_name VARCHAR(25) NOT NULL,
last_date_of_week DATE NOT NULL,
num_students_logging_in_week INT NOT NULL,
weekly_average_of_students_logging_in INT NOT NULL 
);


/*****************************/
/* CTE_StudentData */
WITH CTE_StudentData AS
(
SELECT 
SA.school_name AS school_name,
SA.student_id AS student_id,
SA.record_date AS record_date,
SA.is_present AS is_present,
CASE
	WHEN SA.is_present = 'TRUE' THEN 1
	ELSE 0
	END AS daily_login,

DATEPART(weekday,SA.record_date) AS day_of_week,--1 -Sunday
DATEADD(day,7-DATEPART(weekday,SA.record_date),SA.record_date) AS last_date_of_week,

CAST(DATEADD(month, DATEDIFF(month, 0, SA.record_date), 0) AS DATE)  AS start_date_of_month,
CASE
	WHEN SA.record_date = '2020-10-25' OR SA.record_date = '2020-11-01' THEN 500
	ELSE 0
	END AS paid_amount
FROM student_activity SA
--WHERE SA.school_name --SUBSET OF STUDENT DATA
	--	IN ('ABU DHABI_377','ABU DHABI_1476','AL AIN_1775','AL AIN_1562','ABU DHABI_176')
--ORDER BY SA.school_name, SA.student_id, SA.record_date
),

--INSERT INTO CTE_WeeklyStudentLoginData_Insight
CTE_WeeklyStudentLoginData AS
(
SELECT 
CTESD.school_name AS school_name,
CTESD.last_date_of_week AS last_date_of_week,
CTESD.student_id AS student_id,
SUM(CTESD.daily_login) AS login_count_in_week,
ISNULL(MAX(CTESD.daily_login),0) AS login_in_week --status
FROM CTE_StudentData CTESD 
GROUP BY CTESD.school_name, CTESD.last_date_of_week, CTESD.student_id--, CTESD.is_present
--HAVING CTESD.is_present = 'TRUE'
--ORDER BY CTESD.school_name, CTESD.last_date_of_week, CTESD.student_id, SUM(CTESD.daily_login)
)
INSERT INTO WeeklyAverageStudentsLoginData_Insight
SELECT 
CTEWSLD.school_name AS school_name,
CTEWSLD.last_date_of_week AS last_date_of_week,
SUM(CTEWSLD.login_in_week) AS num_students_logging_in_week,
CAST((ISNULL(SUM(CTEWSLD.login_in_week)/7,0)) AS INT) AS weekly_average_of_students_logging_in

FROM CTE_WeeklyStudentLoginData CTEWSLD
GROUP BY CTEWSLD.school_name, CTEWSLD.last_date_of_week, CTEWSLD.login_in_week--status
HAVING CTEWSLD.login_in_week = 1
ORDER BY CTEWSLD.school_name, CTEWSLD.last_date_of_week, SUM(CTEWSLD.login_in_week)
;



SELECT * FROM WeeklyAverageStudentsLoginData_Insight
ORDER BY school_name, last_date_of_week;



/*****************************************************************************************************************************/
/* DATAWAREHOUSE QUESTION
Tables provided are flat in structure. Assume we have to deploy a model in to our DWH. 
Describe at least 3 dimensions and 1 fact table that you would consider creating for DWH based on dataset provided.
*/

-- BELOW ARE dimensions AND FACT tables that can be created


CREATE TABLE school_details_dim
(
school_id VARCHAR(40) NOT NULL PRIMARY KEY,
school_name VARCHAR(80) NOT NULL,
school_composition VARCHAR(20),
school_address TEXT,
school_contact INT,
school_registration_date DATE
)

CREATE TABLE school_city_dim
(
city_id VARCHAR(40) NOT NULL PRIMARY KEY,
city_name VARCHAR(50) NOT NULL
)

CREATE TABLE student_details_dim
(
student_id
student_name
student_age
student_address
student_contact_num
student_email
student_login_id
student_DOB
student_gender
admission_status
admission_date
present_class_id
current_standard_grade
current_division_section
)

--student_academic_record
--student_progress_record
--student_promotion_record
--student_online_portal_details_dim
--student_online_portal_login_account_details_dim
--student_online_portal_login_activity_fact
--student_curriculum_
--student_lms_portal_details_dim
--student_lms_portal_activity_fact
--Learnings Management System
--student_assigned_curriculum_to_complete_dim
--student_online_classroom_activity_fact
--STUDENT & LOGIN ACCOUNT - 1-TO-1 relationship
--STUDENT & LOGIN ACTIVITY - Many to Many relationship i.e. why student_login_activity_log_fact

CREATE TABLE teacher_details_dim
(
teacher_id
teacher_name
teacher_address
teacher_contact_num
teacher_email
teacher_login_id
teacher_DOB
teacher_gender
job_status
date_of_joining
current_designation_id
subject_id
teacher_qualification
teacher_specialization
package
)


--teacher_academic_record
--teacher_progress_record
--teacher_promotion_record
--teacher_online_portal_login_account_details_dim
--teacher_online_portal_login_activity_fact
--teacher_online_portal_details_dim
--teacher_assigned_syllabus_to_cover
--teacher_online_classroom_activity_fact
--TEACHER & LOGIN ACCOUNT - 1-TO-1 relationship
--TEACHER & LOGIN ACTIVITY - Many to Many relationship i.e. why teacher_login_activity_log_fact

CREATE TABLE academic_session_details_dim
(
session_id
session_name
)

CREATE TABLE student_course_details_dim
(
student_id
course_id
)

CREATE TABLE academic_course_details_dim
(
course_id
course_name

)


CREATE TABLE teacher_activity
(
school_name	VARCHAR(25) NOT NULL,
school_city_name VARCHAR(15) NOT NULL,
school_composition	VARCHAR(20) NOT NULL,
school_start_date	DATE NOT NULL,
teacher_id	VARCHAR(10) NOT NULL,
record_date	DATE NOT NULL,
is_present	VARCHAR(8) NOT NULL,
is_last_login	VARCHAR(8) NOT NULL,
teacher_first_login_date DATETIME
)


CREATE TABLE student_activity
(
school_name	VARCHAR(25) NOT NULL,
school_city_name VARCHAR(15) NOT NULL,
school_composition VARCHAR(20) NOT NULL,
school_start_date DATE NOT NULL,
grade INT NOT NULL,
section	VARCHAR(30) NOT NULL,
student_id VARCHAR(10) NOT NULL,
record_date	DATE NOT NULL,
is_present VARCHAR(8) NOT NULL,
is_last_login VARCHAR(8) NOT NULL,
special_needs CHAR(5) NOT NULL,
student_first_login_date DATETIME,
student_lesson_start_date DATETIME
)


 ALTER TABLE [Alef_Edu_Assignment].[dbo].[student_activity]
 ALTER COLUMN [student_lesson_start_date] DATE;
 /*
 After data is imported to the table and if the column datatypes are changed 
 then the datatype for the data in the column is also updated and no need to import 
 data again. 
 */


 SELECT TOP(20) * FROM teacher_activity;
 
 USE Alef_Edu_Assignment;
 GO

 WITH CTE_REQUIRED_AC AS
 (
 SELECT school_name, teacher_id, COUNT(DISTINCT record_date) AS required_attendence_count
 FROM teacher_activity
 GROUP BY school_name, teacher_id
 --ORDER BY COUNT(DISTINCT record_date) DESC
 ),

 CTE_ATTENDENCE_COUNT AS
 (
 SELECT school_name, teacher_id, COUNT(DISTINCT record_date) AS actual_attendence_count
 FROM 
 (SELECT school_name, teacher_id, record_date FROM teacher_activity WHERE is_present = 'TRUE') P
 GROUP BY teacher_id, school_name
 --ORDER BY COUNT(DISTINCT record_date) DESC
 ),

 CTE_ACTUAL_AC AS
 (
 SELECT 
 CTE_ATTENDENCE_COUNT.school_name,
 CTE_ATTENDENCE_COUNT.teacher_id, --COUNT(DISTINCT CTE_REQUIRED_AC.teacher_id),

 MAX(CTE_ATTENDENCE_COUNT.actual_attendence_count) AS actual_attendence_count
 
 FROM CTE_ATTENDENCE_COUNT
 GROUP BY CTE_ATTENDENCE_COUNT.school_name, CTE_ATTENDENCE_COUNT.teacher_id
 --ORDER BY MAX(CTE_ATTENDENCE_COUNT.actual_attendence_count) DESC
 ),

 CTE_LOGIN_PERCENT AS
 (
 SELECT
 CTERAC.school_name AS school_name,
 CTERAC.teacher_id AS teacher_id,
 ISNULL(CTEAC.actual_attendence_count,0) AS actual_attendence_count,
 CTERAC.required_attendence_count AS required_attendence_count,
 ISNULL((CAST(CAST(CTEAC.actual_attendence_count AS DECIMAL(18,5))/ CAST(CTERAC.required_attendence_count AS DECIMAL(18,5))*100 AS DECIMAL(18,2) )),0.0) AS login_percentage,
 CAST(ISNULL((CAST(CAST(CTEAC.actual_attendence_count AS DECIMAL(18,5))/ CAST(CTERAC.required_attendence_count AS DECIMAL(18,5))*100 AS DECIMAL(18,2) )),0.0) AS VARCHAR(100)) + ' %' AS login_percentage_label
 FROM CTE_REQUIRED_AC CTERAC
 FULL OUTER JOIN CTE_ATTENDENCE_COUNT CTEAC ON CTERAC.teacher_id = CTEAC.teacher_id
 --ORDER BY CTEAC.actual_attendence_count DESC
 ),
 
 CTE_LOGIN_PERCENT_SIXTY_YES AS
 (
 SELECT CTELP.school_name AS school_name,
 CTELP.teacher_id AS teacher_id,
 CTELP.actual_attendence_count AS actual_attendence_count,
 CTELP.required_attendence_count AS required_attendence_count,
 CTELP.login_percentage AS login_percentage,
 CASE
	WHEN CTELP.login_percentage > 60.00 THEN 1
	ELSE 0
 END AS login_percentage_SIXTY_YES
 FROM CTE_LOGIN_PERCENT CTELP
 
 )

 SELECT CTELPSIXTYYES.school_name,
 --COUNT(DISTINCT CTELPSIXTYYES.teacher_id) AS teacher_login_gt_sper,
 COUNT(CTELPSIXTYYES.login_percentage_SIXTY_YES) AS teacher_login_gt_sIXTYperCENTS
 
 FROM CTE_LOGIN_PERCENT_SIXTY_YES CTELPSIXTYYES
 GROUP BY CTELPSIXTYYES.school_name, CTELPSIXTYYES.login_percentage_SIXTY_YES
 HAVING CTELPSIXTYYES.login_percentage_SIXTY_YES = 1
 ORDER BY CTELPSIXTYYES.school_name, COUNT(CTELPSIXTYYES.login_percentage_SIXTY_YES) DESC
 
 ;

 /*CORRECT*/
-- cast( cast(round(37.0/38.0,2) AS DECIMAL(18,2)) as varchar(100)) + ' %'





/*INCORRECT*/
 --LEFT(CAST((ISNULL(CTEAC.actual_attendence_count,0) / CTERAC.required_attendence_count)*100 AS DECIMAL(18,2)),5)+' %' AS PER_ATT
 --LEFT(CAST((CTEAC.actual_attendence_count/ CTERAC.required_attendence_count) AS DECIMAL(18,5)),5)+' %' AS PER_ATT,
/*INCORRECT*/



/*
IF((ISNULL((CAST(CAST(CTEAC.actual_attendence_count AS DECIMAL(18,5))/ CAST(CTERAC.required_attendence_count AS DECIMAL(18,5))*100 AS DECIMAL(18,2) )),0.0))>60.00)
 BEGIN
 END AS ABS
 */


 /*
 SELECT CTE_LOGIN_PERCENT.school_name,
 COUNT(DISTINCT CTE_LOGIN_PERCENT.teacher_id) AS teacher_login_gt_sper,
 COUNT(CTE_LOGIN_PERCENT.login_percentage_SIXTY_YES) AS teacher_login_gt_sIXTYperCENTS
 --CTE_LOGIN_PERCENT.teacher_id,
 --CTE_LOGIN_PERCENT.login_percentage
 FROM CTE_LOGIN_PERCENT
 GROUP BY CTE_LOGIN_PERCENT.school_name, CTE_LOGIN_PERCENT.login_percentage_SIXTY_YES
 HAVING CTE_LOGIN_PERCENT.login_percentage_SIXTY_YES = 1
 ORDER BY CTE_LOGIN_PERCENT.school_name, COUNT(DISTINCT CTE_LOGIN_PERCENT.teacher_id) DESC, COUNT(CTE_LOGIN_PERCENT.login_percentage_SIXTY_YES) DESC
 */



/* TEMPORARY TABLE USED */

 DECLARE @RankSchoolsAccordingToTeachersLoginPercent TABLE
 (
 school_name VARCHAR(25) NOT NULL,
 cnt_teachers_wit_gt_sixtypercent_att INT NOT NULL,
 Rank_schools INT NOT NULL
 );
 


 WITH CTE_T1 AS
 (
 SELECT TLI.school_name AS school_name, 
 --COUNT(DISTINCT TLI.teacher_id) AS teacher_id, 
 COUNT(TLI.login_percentage_SIXTY_YES) AS cnt_teachers_wit_gt_sixtypercent_att
 FROM TeachersLoginInsight TLI
 GROUP BY TLI.school_name, TLI.login_percentage_SIXTY_YES
 HAVING TLI.login_percentage_SIXTY_YES = 1
 --ORDER BY COUNT(DISTINCT TLI.teacher_id) DESC;
 )

 INSERT INTO @RankSchoolsAccordingToTeachersLoginPercent
 SELECT 
 CTET1.school_name AS school_name, 
 CTET1.cnt_teachers_wit_gt_sixtypercent_att AS cnt_teachers_wit_gt_sixtypercent_att,
 DENSE_RANK() OVER (ORDER BY CTET1.cnt_teachers_wit_gt_sixtypercent_att DESC) AS Rank_schools
 FROM CTE_T1 CTET1;

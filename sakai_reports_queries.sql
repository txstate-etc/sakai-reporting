-- Sites enrollments info combined with course provider data to get sync with SIS

SELECT  site.SITE_ID, site.TITLE, academic.TITLE as SEMESTER,SUBSTRING(enrollset.ENTERPRISE_ID, 1,6) as SEMESTER_ID, SUBSTRING(enrollset.ENTERPRISE_ID, 1,4) as YEAR, realm.PROVIDER_ID, enroll.USER_ID as STUDENT, instructor.INSTRUCTOR_ID as INSTRUCTOR, site.PUBLISHED, site.CREATEDON,site.MODIFIEDON
FROM SAKAI_SITE site 
INNER JOIN SAKAI_REALM realm ON realm.REALM_ID = CONCAT('/site/',site.SITE_ID)
INNER JOIN SAKAI_REALM_PROVIDER provider ON realm.REALM_KEY = provider.REALM_KEY
INNER JOIN CM_ENROLLMENT_SET_T enrollset ON enrollset.ENTERPRISE_ID = provider.PROVIDER_ID
INNER JOIN CM_ENROLLMENT_T enroll ON enroll.ENROLLMENT_SET = enrollset.ENROLLMENT_SET_ID
INNER JOIN CM_OFFICIAL_INSTRUCTORS_T instructor ON instructor.ENROLLMENT_SET_ID = enrollset.ENROLLMENT_SET_ID
INNER JOIN CM_ACADEMIC_SESSION_T academic ON CONCAT('v2.',SUBSTRING(enrollset.ENTERPRISE_ID, 1,6)) = academic.ENTERPRISE_ID
WHERE site.type = 'course'  AND enroll.STATUS ='true';

-- Project sites with all the maintainer role users 

create view v_project_site_info_simple as
select site.SITE_ID, site.CREATEDON, sitetool.REGISTRATION AS TOOL_ID,  usermap.EID AS EID,  
role.role_name as SITE_ROLE, site.TYPE AS TYPE  
from SAKAI_SITE site
inner join SAKAI_SITE_TOOL sitetool   on site.SITE_ID = sitetool.SITE_ID 
inner join SAKAI_REALM realm on realm.REALM_ID = concat('/site/',site.SITE_ID) 
inner join SAKAI_REALM_RL_GR rg on rg.REALM_KEY = realm.REALM_KEY   
inner join SAKAI_REALM_ROLE role on role.ROLE_KEY = rg.ROLE_KEY   
inner join SAKAI_USER_ID_MAP usermap on rg.USER_ID = usermap.USER_ID  
where  role.ROLE_NAME = 'maintain' and site.type='project' 
and site.CREATEDON is not null;

-- Course sites with all the instructor role users

create view v_course_site_info_simple as
select site.SITE_ID, site.CREATEDON, sitetool.REGISTRATION AS TOOL_ID, 
usermap.EID AS EID,  role.role_name as SITE_ROLE, site.TYPE AS TYPE 
from SAKAI_SITE_TOOL sitetool 
inner join SAKAI_SITE site on site.SITE_ID = sitetool.SITE_ID
inner join SAKAI_REALM realm on realm.REALM_ID = concat('/site/',site.SITE_ID)
inner join SAKAI_REALM_RL_GR rg on rg.REALM_KEY = realm.REALM_KEY  
inner join SAKAI_REALM_ROLE role on role.ROLE_KEY = rg.ROLE_KEY  
inner join SAKAI_USER_ID_MAP usermap on rg.USER_ID = usermap.USER_ID 
where role.ROLE_NAME = 'instructor' and site.type='course'
and site.CREATEDON is not null;

-- Sites and Terms association based on site creation time
-- May vary if separate course sites by assiociated provider identify

create view v_site_term_info as
select site.SITE_ID, academic.title as SEMESTER, substring(academic.ENTERPRISE_ID,-6) as SEMESTER_ID
from SAKAI_SITE site
left join CM_ACADEMIC_SESSION_T academic on site.CREATEDON between academic.START_DATE and academic.END_DATE 
where site.CREATEDON is not null and  academic.ENTERPRISE_ID like 'v2.%'
and site.type in ('project','course' );

/* Instructors who have course sites in sakai for a semester, 
we have first 6 chars from front to identify semester 
*/
 
SELECT  distinct instructor.INSTRUCTOR_ID FROM SAKAI_SITE site  
INNER JOIN SAKAI_REALM realm ON realm.REALM_ID = CONCAT('/site/',site.SITE_ID) 
INNER JOIN SAKAI_REALM_PROVIDER provider ON realm.REALM_KEY = provider.REALM_KEY 
INNER JOIN CM_ENROLLMENT_SET_T enrollset ON enrollset.ENTERPRISE_ID = provider.PROVIDER_ID 
INNER JOIN CM_OFFICIAL_INSTRUCTORS_T instructor ON instructor.ENROLLMENT_SET_ID = enrollset.ENROLLMENT_SET_ID 
WHERE site.type = 'course'   
and SUBSTRING(enrollset.ENTERPRISE_ID, 1, 6)='201530'; 

-- All Sites and Site Owner info without considering academic Terms

select site.SITE_ID, site.CREATEDON, sitetool.REGISTRATION AS TOOL_ID,  
 usermap.EID AS EID,  
role.role_name as SITE_ROLE, site.TYPE AS TYPE  
from SAKAI_SITE site
inner join SAKAI_SITE_TOOL sitetool   on site.SITE_ID = sitetool.SITE_ID 
inner join SAKAI_REALM realm on realm.REALM_ID = concat('/site/',site.SITE_ID) 
inner join SAKAI_REALM_RL_GR rg on rg.REALM_KEY = realm.REALM_KEY   
inner join SAKAI_REALM_ROLE role on role.ROLE_KEY = rg.ROLE_KEY   
inner join SAKAI_USER_ID_MAP usermap on rg.USER_ID = usermap.USER_ID  
where  ((role.ROLE_NAME = 'maintain' and site.type='project' )
or (role.ROLE_NAME = 'instructor' and site.type='course' ))
and site.CREATEDON is not null; 

-- Instructors who have sites and enrollment with sites info using SAKAI_SITE_PROPERTY (may not accurate compare to 
-- using CM_* tables; but faster and very close

SELECT  site.SITE_ID, site.TITLE, property_term.VALUE SEMESTER, property_termeid.VALUE as SEMESTER_ID, YEAR(site.CREATEDON) as YEAR, realm.PROVIDER_ID as REALM_PROVIDER_ID,  instructor.INSTRUCTOR_ID as INSTRUCTOR, site.PUBLISHED, site.CREATEDON, site.MODIFIEDON FROM SAKAI_SITE site 
INNER JOIN SAKAI_SITE_PROPERTY property_term on site.SITE_ID=property_term.SITE_ID and property_term.NAME='term'
INNER JOIN SAKAI_SITE_PROPERTY property_termeid on site.SITE_ID=property_termeid.SITE_ID and property_termeid.NAME='term_eid'
INNER JOIN SAKAI_REALM realm ON realm.REALM_ID = CONCAT('/site/',site.SITE_ID)
INNER JOIN SAKAI_REALM_PROVIDER provider ON realm.REALM_KEY = provider.REALM_KEY
INNER JOIN CM_ENROLLMENT_SET_T enrollset ON enrollset.ENTERPRISE_ID = provider.PROVIDER_ID
INNER JOIN CM_OFFICIAL_INSTRUCTORS_T instructor ON instructor.ENROLLMENT_SET_ID = enrollset.ENROLLMENT_SET_ID
WHERE site.type = 'course';  

-- Term and Teaching instructors who have sites and enrollments

SELECT distinct trim(academic.TITLE) as SEMESTER, SUBSTRING(enrollset.ENTERPRISE_ID, 1, 6) as SEMESTER_ID,instructor.INSTRUCTOR_ID as INSTRUCTOR,'TRACS' as ENV 
FROM SAKAI_SITE site 
INNER JOIN SAKAI_REALM realm ON realm.REALM_ID = CONCAT('/site/',site.SITE_ID)
INNER JOIN SAKAI_REALM_PROVIDER provider ON realm.REALM_KEY = provider.REALM_KEY
INNER JOIN CM_ENROLLMENT_SET_T enrollset ON enrollset.ENTERPRISE_ID = provider.PROVIDER_ID
INNER JOIN CM_OFFICIAL_INSTRUCTORS_T instructor ON instructor.ENROLLMENT_SET_ID = enrollset.ENROLLMENT_SET_ID
INNER JOIN CM_ACADEMIC_SESSION_T academic ON CONCAT('v2.',SUBSTRING(enrollset.ENTERPRISE_ID, 1,6)) = academic.ENTERPRISE_ID
WHERE site.type = 'course';

-- Sites that have Melete tool that actually have contents

SELECT distinct mcm.`COURSE_ID` as 'Site Id', site.title as 'Site Title', site.type as 'Site Type', realm.provider_id as 'ProviderId', SUBSTRING_INDEX(realm.provider_id,'.',1) as term,  usermap.eid as 'Site Owner', site.createdon as 'Created Date', site.modifiedon as 'Modified Date', count(ms.section_id) as 'Number of Sections'  
FROM `melete_course_module` mcm
inner join melete_section ms on mcm.module_id=ms.module_id
inner join melete_section_resource msr on ms.section_id=msr.section_id
inner join SAKAI_SITE site  on  site.site_id=mcm.course_id
inner join SAKAI_REALM realm on realm.realm_id = CONCAT('/site/', mcm.course_id)
inner join SAKAI_REALM_RL_GR rg on rg.realm_key = realm.realm_key
inner join SAKAI_REALM_ROLE role on role.role_key = rg.role_key
inner join SAKAI_USER_ID_MAP usermap on rg.user_id = usermap.user_id
where mcm.delete_flag = false and (role.role_name='instructor'
or role.role_name = 'maintain')
and (site.type = 'course' or 'project') 
group by mcm.`COURSE_ID` order by usermap.eid, site.createdon;

-- Users that have melete tool with contents in their sites 

SELECT  usermap.eid as 'Site Owner', count(distinct site.site_id)  FROM `melete_course_module` mcm 
inner join melete_section ms on mcm.module_id=ms.module_id
inner join melete_section_resource msr on ms.section_id=msr.section_id
inner join SAKAI_SITE site  on  site.site_id=mcm.course_id
inner join SAKAI_REALM realm on realm.realm_id = CONCAT('/site/', mcm.course_id)
inner join SAKAI_REALM_RL_GR rg on rg.realm_key = realm.realm_key
inner join SAKAI_REALM_ROLE role on role.role_key = rg.role_key
inner join SAKAI_USER_ID_MAP usermap on rg.user_id = usermap.user_id
where (usermap.eid = '@Request.itNetID~' or  '@Request.itNetID~' = '')
and mcm.delete_flag = false and (role.role_name='instructor'
or role.role_name = 'maintain')
group by usermap.eid order by usermap.eid, site.createdon;

-- Sites that have certain tool with filter ability by selected attributes

SELECT site.SITE_ID, site.TITLE, map.EID as OWNER, site.TYPE, site.PUBLISHED, site.CREATEDON, REGISTRATION, site.MODIFIEDON, substring(REGISTRATION, INSTR(REGISTRATION,".")+1) as TOOL
from SAKAI_SITE_TOOL tool
inner join SAKAI_SITE site on site.SITE_ID=tool.SITE_ID
inner join SAKAI_USER_ID_MAP map on map.USER_ID = site.CREATEDBY
where  REGISTRATION = 'sakai.samigo'

-- This is the query that used for tool stats which gives you the ability to create crosstab tables and graphs layout data by site type, accross years or accross academic terms 
-- Those @Request.* are actually variables with user's inputs that can make the query dynamically
-- You may run the query by replacing variables with certain data

select site.SITE_ID, site.TITLE, substring(REGISTRATION,instr(REGISTRATION,".")+1) as TOOL, sitetool.REGISTRATION, academic.TITLE AS TERM, SUBSTRING(academic.ENTERPRISE_ID, -6) AS TERM_ID, 
usermap.EID AS OWNER,site.PUBLISHED,site.TYPE,site.CREATEDON,site.MODIFIEDON, CASE WHEN TYPE='course' THEN 1  ELSE 0 END as COURSE_SITE, CASE WHEN TYPE='project' THEN 1  ELSE 0 END as PROJECT_SITE 
from SAKAI_SITE_TOOL sitetool 
inner join SAKAI_SITE site on site.SITE_ID = sitetool.SITE_ID
left join CM_ACADEMIC_SESSION_T academic on site.CREATEDON between academic.START_DATE and academic.END_DATE
inner join SAKAI_USER_ID_MAP usermap on site.CREATEDBY = usermap.USER_ID
where site.CREATEDON is not null and  academic.ENTERPRISE_ID like 'v2.%'
and (REGISTRATION IN (@SingleQuote.Request.islTools~) or '@Request.islTools~' = 'all')
and (academic.TITLE IN (@SingleQuote.Request.islTerms~) or '@Request.islTerms~' = 'all')
and (usermap.EID = '@Request.itNetID~' or  '@Request.itNetID~' = '')
order by TERM_ID asc






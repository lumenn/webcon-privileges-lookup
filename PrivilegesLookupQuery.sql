USE [BPS_Content];
-- Go to the bottom, and filter out what you need.

WITH 
    Users (COS_ID, COS_DisplayName, COS_BpsID) AS (
        SELECT
            COS_ID,
            COS_DisplayName,
            COS_BpsID
        FROM
            CacheOrganizationStructure 
        WHERE
            COS_UserType IS NOT NULL
    ), 
    Groups (COS_ID, COS_DisplayName, COS_BpsID) AS (
        SELECT
            COS_ID,
            COS_DisplayName,
            COS_BpsID
        FROM
            CacheOrganizationStructure 
        WHERE
            COS_UserType IS NULL
    ),
    UsersAndUsersInGroups (COS_UserBpsID, COS_GroupBpsID, UserName, GroupName) AS (
        SELECT
            u.COS_BpsID,
            g.COS_BpsID,
            u.COS_DisplayName,
            g.COS_DisplayName
        FROM
            Users u JOIN
            CacheOrganizationStructureGroupRelations c ON u.COS_ID = c.COSGR_UserID JOIN
            Groups g ON g.COS_ID = c.COSGR_GroupID
        
        UNION ALL

        SELECT
            COS_BpsID,
            NULL,
            COS_DisplayName,
            NULL
        FROM
            Users
    ),
    UserApplications (Scope, Level, ID, UserID, UserName, GroupID, GroupName, APP_Name, DEF_Name, WF_Name, DTYPE_Name, COM_Name) AS (
        SELECT
            'Application' As Scope,
            d.Name,
            APP_ID,
            u.COS_UserBpsID,
            u.UserName,
            u.COS_GroupBpsID,
            u.GroupName,
            APP_name,
            NULL,
            NULL,
            NULL,
            NULL
        FROM
            WFApplications JOIN
            WFConfigurationSecurities c ON APP_ID = CSC_APPID JOIN
            UsersAndUsersInGroups u ON (u.COS_UserBpsID = CSC_USERGUID AND u.COS_GroupBpsID IS NULL) OR u.COS_GroupBpsID = CSC_USERGUID JOIN
            DicConfigurationSecurityLevels d ON CSC_LevelID = d.TypeID
    ),
    UserProcesses (Scope, Level, ID, UserID, UserName, GroupID, GroupName, APP_Name, DEF_Name, WF_Name, DTYPE_Name, COM_Name) AS (
        SELECT
            'Process' As Scope,
            d.Name,
            DEF_ID,
            u.COS_UserBpsID,
            u.UserName,
            u.COS_GroupBpsID,
            u.GroupName,
            APP_Name,
            DEF_Name,
            NULL As WF_Name,
            NULL As DTYPE_Name,
            COM_Name
        FROM
            WFDefinitions JOIN
            WFSecurities c ON DEF_ID = SEC_DEFID JOIN
            UsersAndUsersInGroups u ON (u.COS_UserBpsID = SEC_USERGUID AND u.COS_GroupBpsID IS NULL) OR u.COS_GroupBpsID = SEC_USERGUID JOIN
            DicSecurityLevels d ON SEC_LevelID = d.TypeID JOIN
            WFApplications ON DEF_APPID = APP_ID JOIN
            Companies ON COM_ID = SEC_COMID
    ),
    UserWorkflowsForms (Scope, Level, ID, UserID, UserName, GroupID, GroupName, APP_Name, DEF_Name, WF_Name, DTYPE_Name, COM_Name) AS (
        SELECT
            'Workflow -> Form' As Scope,
            d.Name,
            ASS_ID,
            u.COS_UserBpsID,
            u.UserName,
            u.COS_GroupBpsID,
            u.GroupName,
            APP_Name,
            DEF_Name,
            WF_Name,
            DTYPE_Name,
            COM_Name
        FROM
            WorkFlows JOIN
            DocTypeAssocciations ON WF_ID = ASS_WFID JOIN
            WFDocTypes ON DTYPE_ID = ASS_DTYPEID JOIN
            WFSecurities c ON ASS_ID = SEC_DEFID JOIN
            UsersAndUsersInGroups u ON (u.COS_UserBpsID = SEC_USERGUID AND u.COS_GroupBpsID IS NULL) OR u.COS_GroupBpsID = SEC_USERGUID JOIN
            DicSecurityLevels d ON SEC_LevelID = d.TypeID JOIN
            WFDefinitions ON DEF_ID = WF_WFDEFID JOIN
            WFApplications ON APP_ID = DEF_APPID JOIN
            Companies ON SEC_COMID = COM_ID
    ),
    GlobalPrivileges (Scope, Level, ID, UserID, UserName, GroupID, GroupName, APP_Name, DEF_Name, WF_Name, DTYPE_Name, COM_Name) AS (
        SELECT
            'Global' As Scope,
            d.Name,
            NULL,
            u.COS_UserBpsID,
            u.UserName,
            u.COS_GroupBpsID,
            u.GroupName,
            NULL As APP_Name,
            NULL As DEF_Name,
            NULL As WF_Name,
            NULL As DTYPE_Name,
            NULL As COM_Name
        FROM
            WFConfigurationSecurities JOIN
            UsersAndUsersInGroups u ON (u.COS_UserBpsID = CSC_USERGUID AND u.COS_GroupBpsID IS NULL) OR u.COS_GroupBpsID = CSC_USERGUID JOIN
            DicConfigurationSecurityLevels d ON CSC_LevelID = d.TypeID
        WHERE
            CSC_IsGlobal = 1

        UNION ALL

        SELECT
            'Global' As Scope,
            d.Name,
            NULL,
            u.COS_UserBpsID,
            u.UserName,
            u.COS_GroupBpsID,
            u.GroupName,
            NULL As APP_Name,
            NULL As DEF_Name,
            NULL As WF_Name,
            NULL As DTYPE_Name,
            NULL As COM_Name
        FROM
            WFSecurities JOIN
            UsersAndUsersInGroups u ON (u.COS_UserBpsID = SEC_USERGUID AND u.COS_GroupBpsID IS NULL) OR u.COS_GroupBpsID = SEC_USERGUID JOIN
            DicSecurityLevels d ON SEC_LevelID = d.TypeID
        WHERE
            SEC_IsGlobal = 1
    ),
    AllSecurities AS (
        SELECT * FROM UserWorkflowsForms

        UNION ALL

        SELECT * FROM UserProcesses

        UNION ALL

        SELECT * FROM UserApplications

        UNION ALL

        SELECT * FROM GlobalPrivileges
    )

SELECT 
    *
FROM
    AllSecurities
WHERE
    UserID LIKE '%' OR
    GroupID LIKE '' OR
    GroupName LIKE '' OR
    UserName LIKE '' OR
    APP_NAME LIKE '' OR
    DEF_Name LIKE '' OR
    WF_Name LIKE '' OR
    DTYPE_Name LIKE '' OR
    COM_Name LIKE '' OR
    Level LIKE '' OR
    Scope LIKE ''

